{
  This file contains the implementation of (Neo)Vi keybinds in the Delphi IDE.

  Copyright (C) 2016 Peter Ross
  Copyright (C) 2021 Kai Anter
  Copyright (C) 2024 Antoine Gaudreau Simard

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
}

unit ViEngine;

interface

uses
  Classes,
  Generics.Collections,
  Generics.Defaults,
  Windows,
  Commands.Base,
  Commands.Navigation,
  Commands.Operators,
  Commands.TextObjects,
  Commands.Editing,
  ViOperation,
  Clipboard;

type
  TP_ModeChanged = reference to procedure(AMode: String);

  TViEngine = class(TSingletonImplementation, IViEngine)
  private
    FCurrentViMode: TViMode;
    FShiftState: TShiftState;
    FCurrentOperation: TViOperation;
    FOnModeChanged: TP_ModeChanged; // called when Vi Mode is changed
    FViOperatorBindings: TDictionary<string, TViOperatorCClass>;
    FViTextObjectBindings: TDictionary<string, TViTextObjectCClass>;
    FViNavigationBindings: TDictionary<string, TViNavigationCClass>;
    FViEditBindings: TDictionary<string, TViEditCClass>;
    FClipboard: TClipboard;
    //FMarkArray: array [0 .. 255] of TOTAEditPos;

    procedure FillViBindings;
    procedure HandleChar(const AChar: Char);
    procedure ResetCurrentOperation;
    procedure ExecuteLastCommand;
    procedure SetViMode(ANewMode: TViMode);
    procedure SetOnModeChanged(ANewProc: TP_ModeChanged);
  public
    property currentViMode: TViMode read FCurrentViMode write SetViMode;
    property onModeChanged: TP_ModeChanged read FOnModeChanged write SetOnModeChanged;

    constructor Create;
    destructor Destroy; override;
    procedure EditKeyDown(AKey, AScanCode: Word; AShift: TShiftState; AMsg: TMsg; var AHandled: Boolean);
    procedure EditChar(AKey, AScanCode: Word; AShift: TShiftState; AMsg: TMsg; var AHandled: Boolean);
    procedure LButtonDown;
    procedure ConfigureCursor;
    procedure ToggleActive;

  end;

implementation

uses
  NavUtils,
  SysUtils,
  ToolsAPI;

function GetViModeString(aViMode: TViMode): string;
var
  mode: string;
begin
  case aViMode of
    mInactive: mode := 'INACTIVE';
    mNormal: mode := 'NORMAL';
    mInsert: mode := 'INSERT';
    mVisual: mode := 'VISUAL';
  end;

  result := Format('Vi: -- %s --', [mode]);
end;

{ TViBindings }

constructor TViEngine.Create;
begin
  currentViMode := mNormal;
  FViOperatorBindings := TDictionary<string, TViOperatorCClass>.Create;
  FViTextObjectBindings := TDictionary<string, TViTextObjectCClass>.Create;
  FViNavigationBindings := TDictionary<string, TViNavigationCClass>.Create;
  FViEditBindings := TDictionary<string, TViEditCClass>.Create;
  FClipboard := TClipboard.Create;
  FCurrentOperation := TViOperation.Create(self, FClipboard);
  FillViBindings;
end;

destructor TViEngine.Destroy;
begin
  FCurrentOperation.Free;
  FClipboard.Free;
  FViEditBindings.Free;
  FViNavigationBindings.Free;
  FViTextObjectBindings.Free;
  FViOperatorBindings.Free;
  inherited;
end;

procedure TViEngine.ConfigureCursor;
var
  LEditBuffer: IOTAEditBuffer;
begin
  LEditBuffer := GetEditBuffer;

  if LEditBuffer <> nil then
    LEditBuffer.EditOptions.UseBriefCursorShapes := (currentViMode = mNormal) or (currentViMode = mVisual);
end;

procedure TViEngine.EditChar(AKey, AScanCode: Word; AShift: TShiftState; AMsg: TMsg; var AHandled: Boolean);
begin
  if currentViMode in [mInactive, mInsert] then
    Exit;

  FShiftState := AShift;
  HandleChar(Chr(AKey));
  AHandled := True;
  (BorlandIDEServices as IOTAEditorServices).TopView.Paint;
end;

procedure TViEngine.EditKeyDown(AKey, AScanCode: Word; AShift: TShiftState; AMsg: TMsg; var AHandled: Boolean);
var
  LIsLetter, LIsSymbol: Boolean;

  function GetTopMostEditView: IOTAEditView;
  var
    EditBuffer: IOTAEditBuffer;
  begin
    result := nil;
    EditBuffer := GetEditBuffer;
    if EditBuffer <> nil then
      Exit(EditBuffer.GetTopView);
  end;

begin
  case (currentViMode) of
    mInactive:
      Exit;
    mNormal:
      begin
        if (ssCtrl in AShift) or (ssAlt in AShift) then
          Exit;

        LIsLetter := ((AKey >= ord('A')) and (AKey <= ord('Z'))) or ((AKey >= ord('0')) and (AKey <= ord('9')));
        LIsSymbol := ((AKey >= 186) and (AKey <= 192)) or ((AKey >= 219) and (AKey <= 222)) or (AKey = VK_SPACE);

        if LIsLetter or LIsSymbol then
        begin
          // If the keydown is a standard keyboard press not altered with a ctrl
          // or alt key then create a WM_CHAR message so we can do all the
          // locale mapping of the keyboard and then handle the resulting key in
          // TViBindings.EditChar.
          // XXX can we switch to using ToAscii like we do for setting FInsertText
          TranslateMessage(AMsg);
          AHandled := True;
        end
        else if (AKey = VK_ESCAPE) then // cancel all current commands
        begin
          ResetCurrentOperation;
          AHandled := True;
        end;
      end;
  else // Insert or Visual mode
    begin
      if (AKey = VK_ESCAPE) then
      begin
        GetTopMostEditView.Buffer.BufferOptions.InsertMode := True;
        currentViMode := mNormal; // Go from Insert back to Normal
        AHandled := True;
        FCurrentOperation.Reset(false);
      end;
    end;
  end;
end;

procedure TViEngine.ExecuteLastCommand;
var
  aChar: Char;
begin
  FCurrentOperation.Reset(false);

  for aChar in FCurrentOperation.LastCommand do
    HandleChar(aChar);
end;

procedure TViEngine.ResetCurrentOperation;
begin
  currentViMode := mNormal;
  FCurrentOperation.Reset(false);
end;

procedure TViEngine.HandleChar(const AChar: Char);
var
  aViOperatorCClass: TViOperatorCClass;
  aViTextObjectCClass: TViTextObjectCClass;
  aViNavigationCClass: TViNavigationCClass;
  aViEditCClass: TViEditCClass;
  commandToMatch: string;
  keepChar: boolean;
  aBuffer: IOTAEditBuffer;
  aCursorPosition: IOTAEditPosition;
  len: integer;
  searchString: string;
begin
  FCurrentOperation.AddToCommandToMatch(aChar);
  commandToMatch := FCurrentOperation.CommandToMatch;
  aBuffer := GetEditBuffer;
  keepChar := False;
  aCursorPosition := GetEditPosition(aBuffer);

  // we need to somehow match f+ (could replace char by + before lookup,
  // would need to know that anything following an f should be replaced, where would knowledge come from?
  // decorator on the class? Implementing an interface for it? Though at this point we do not know the class
  // as the below is the class lookup, hmm
  if FCurrentOperation.TryAddToCount(commandToMatch) then
    //
  else if FViOperatorBindings.TryGetValue(commandToMatch, aViOperatorCClass) then
    FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aViOperatorCClass)
  else if FViTextObjectBindings.TryGetValue(commandToMatch, aViTextObjectCClass) then
    FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aViTextObjectCClass)
  else if FViNavigationBindings.TryGetValue(commandToMatch, aViNavigationCClass) then
    FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aViNavigationCClass)
  else if FViEditBindings.TryGetValue(commandToMatch, aViEditCClass) then
    FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aViEditCClass)
  else
  begin
    keepChar := True;
    // We now look for a two+ character command where the last character is a search token (+)
    len := Length(commandToMatch);
    if len >= 2 then
    begin
      // only support for these for the time being
      searchString := copy(commandToMatch, 0, len - 1) + '+';
      if FViNavigationBindings.TryGetValue(searchString, aViNavigationCClass) then
      begin
        FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aViNavigationCClass, copy(commandToMatch, len, 1));
        keepChar := False;
      end;
    end;
  end;

  if not keepChar then
    FCurrentOperation.ClearCommandToMatch;
end;

procedure TViEngine.LButtonDown;
begin
  FCurrentOperation.Reset(false);
end;

procedure TViEngine.FillViBindings;
begin
  // operators
  FViOperatorBindings.Add('d', TViOCDelete);
  FViOperatorBindings.Add('y', TViOCYank);
  FViOperatorBindings.Add('c', TViOCChange);
  FViOperatorBindings.Add('>', TViOCIndentRight);
  FViOperatorBindings.Add('<', TViOCIndentLeft);
  FViOperatorBindings.Add('=', TViOCAutoIndent);
  FViOperatorBindings.Add('gU', TViOCUppercase);
  FViOperatorBindings.Add('gu', TViOCLowercase);

  // motions
//  FViTextObjectBindings.Add('p', TViTOCParagraph); // for a/i
  FViTextObjectBindings.Add('w', TViTOCWord);
  FViTextObjectBindings.Add('W', TViTOCWordCharacter);
//  FViTextObjectBindings.Add('[', TViTOCSquareBracketOpen); // for a/i
//  FViTextObjectBindings.Add(']', TViTOCSquareBracketClose); // for a/i
//  FViTextObjectBindings.Add('(', TViTOCParenthesisOpen); // for a/i
//  FViTextObjectBindings.Add(')', TViTOCParenthesisClose); // for a/i
//  FViTextObjectBindings.Add('{', TViTOCBracesOpen); // for a/i
//  FViTextObjectBindings.Add('}', TViTOCBracesClose); // for a/i
//  FViTextObjectBindings.Add('<', TViTOCAngleBracketOpen); // for a/i
//  FViTextObjectBindings.Add('>', TViTOCAngleBracketClose); // for a/i
//  FViTextObjectBindings.Add('''', TViTOCSingleQuote); // for a/i
//  FViTextObjectBindings.Add('"', TViTOCDoubleQuote); // for a/i
//  FViTextObjectBindings.Add('`', TViTOCTick); // for a/i
  FViTextObjectBindings.Add('b', TViTOCWordBack);
  FViTextObjectBindings.Add('B', TViTOCWordCharacterBack);
  FViTextObjectBindings.Add('e', TViTOCEndOfWord);
  FViTextObjectBindings.Add('E', TViTOCEndOfWordCharacter);
//  FViTextObjectBindings.Add('B', TViTOCBlocks); // for a/i
//  FViTextObjectBindings.Add('t', TViTOCTag); // for a/i

  // here '+' denotes that another character is needed to run/match the command
  FViNavigationBindings.add('h', TViNCLeft);
  FViNavigationBindings.add('l', TViNCRight);
  FViNavigationBindings.add('j', TViNCDown);
  FViNavigationBindings.add('k', TViNCUp);
  FViNavigationBindings.add('f+', TViNCFindForward);
  FViNavigationBindings.add('F+', TViNCFindBackwards);
  FViNavigationBindings.add('t+', TViNCFindTilForward);
  FViNavigationBindings.add('T+', TViNCFindTilBackwards);
//  FViNavigationBindings.add('', TViNCHalfPageUp);
//  FViNavigationBindings.add('', TViNCHalfPageDown);
  FViNavigationBindings.add('0', TViNCStartOfLine);
  FViNavigationBindings.add('$', TViNCEndOfLine);
  FViNavigationBindings.add('_', TViNCStartOfLineAfterWhiteSpace);
  FViNavigationBindings.add('gg', TViNCFirstLine);
  FViNavigationBindings.add('G', TViNCGoToLine);
  FViNavigationBindings.add('n', TViNCNextMatch);
  FViNavigationBindings.add('N', TViNCPreviousMatch);
  FViNavigationBindings.add('*', TViNCNextWholeWordUnderCursor);
  FViNavigationBindings.add('#', TViNCPreviousWholeWordUnderCursor);
  FViNavigationBindings.add(' ', TViNCRight);
  FViNavigationBindings.add('L', TViNCBottomScreen);
  FViNavigationBindings.add('M', TViNCMiddleScreen);
  FViNavigationBindings.add('{', TViNCPreviousParagraphBreak);
  FViNavigationBindings.add('}', TViNCNextParagraphBreak);
//  FViTextObjectBindings.Add('''', TViNCGoToMark); // takes in the mark char

  FViEditBindings.Add('a', TViECAppend);
  FViEditBindings.Add('A', TViECAppendEOL);
  FViEditBindings.Add('i', TViECInsert);
  FViEditBindings.Add('I', TViECInsertBOL);
  FViEditBindings.Add('o', TViECNextLine);
  FViEditBindings.Add('O', TViECPreviousLine);
  FViEditBindings.Add('s', TViECDeleteCharInsert);
  FViEditBindings.Add('S', TViECDeleteLineInsert);
  FViEditBindings.Add('D', TViECDeleteTilEOL);
  FViEditBindings.Add('C', TViECChangeTilEOL);
  FViEditBindings.Add('r', TViECReplaceChar);
  FViEditBindings.Add('R', TViECReplaceMode);
  FViEditBindings.Add('u', TViECUndo);
//  FViEditBindings.Add('<C-R>', TViECDeleteCharacter);
  FViEditBindings.Add('x', TViECDeleteCharacter);
  FViEditBindings.Add('X', TViECDeletePreviousCharacter);
  FViEditBindings.Add('p', TViECPaste);
  FViEditBindings.Add('P', TViECPasteBefore);
  FViEditBindings.Add('J', TViECJoinLines);
  FViEditBindings.Add('.', TViECRepeatLastCommand);
  FViEditBindings.Add('~', TViECToggleCase);

//To Migrate
//  FViKeybinds.Add('m', ActionSetMark);  // takes in the mark char
//  FViKeybinds.Add('/', ActionSearch);
end;

procedure TViEngine.SetViMode(ANewMode: TViMode);
var
  LText: String;
begin
  FCurrentViMode := ANewMode;
  ConfigureCursor;
  if assigned(FOnModeChanged) then
  begin
    LText := GetViModeString(ANewMode);
    FOnModeChanged(LText);
  end;
end;

procedure TViEngine.SetOnModeChanged(ANewProc: TP_ModeChanged);
begin
  FOnModeChanged := ANewProc;
  FOnModeChanged(GetViModeString(currentViMode)); // call new procedure immediately
end;

procedure TViEngine.ToggleActive;
begin
  if currentViMode = mInactive then
    currentViMode := mNormal
  else
    currentViMode := mInactive;
end;

end.
