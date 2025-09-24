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

unit Engine;

interface

uses
  Classes,
  Generics.Collections,
  Generics.Defaults,
  Windows,
  Commands.Base,
  Commands.Motion,
  Commands.Operators,
  Commands.Edition,
  Commands.Ex,
  Operation,
  Clipboard,
  AppEvnts;

type
  TCaptionChangeProc = reference to procedure(aCaption: String);

  TEngine = class(TSingletonImplementation, IEngine)
  private
    FCurrentViMode: TViMode;
    FCurrentCommandForCaption: string;
    FShiftState: TShiftState;
    FCurrentOperation: TOperation;
    FOnCaptionChanged: TCaptionChangeProc; // called when Vi Mode is changed
    FOperatorBindings: TDictionary<string, TOperatorClass>;
    FMotionBindings: TDictionary<string, TMotionClass>;
    FEditionBindings: TDictionary<string, TEditionClass>;
    FExBindings: TDictionary<string, TExClass>;
    FClipboard: TClipboard;
    FUpdateActionCaption: boolean;
    FEvents: TApplicationEvents;
    //FMarkArray: array [0 .. 255] of TOTAEditPos;

    procedure FillBindings;
    procedure HandleChar(const AChar: Char);
    procedure ResetCurrentOperation;
    procedure ExecuteLastCommand;
    function GetViMode: TViMode;
    procedure SetViMode(ANewMode: TViMode);
    procedure SetOnCaptionChanged(ANewProc: TCaptionChangeProc);
    procedure OnCommandChanged(aCommand: string);
    procedure DoApplicationIdle(Sender: TObject; var Done: Boolean);
  public
    property currentViMode: TViMode read GetViMode write SetViMode;
    property onCaptionChanged: TCaptionChangeProc write SetOnCaptionChanged;

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
  ToolsAPI,
  Dialogs;

function GetViModeString(aViMode: TViMode; aCommand: string): string;
var
  mode: string;
  command: string;
begin
  case aViMode of
    mInactive: mode := 'INACTIVE';
    mNormal: mode := 'NORMAL';
    mInsert: mode := 'INSERT';
    mVisual: mode := 'VISUAL';
  end;
  command := aCommand;
  result := Format('   %s', [mode]);

  if command <> '' then
    result := Format('%s - %s', [result, command]);
end;

procedure TEngine.OnCommandChanged(aCommand: string);
begin
  FCurrentCommandForCaption := aCommand;
  FUpdateActionCaption := True;
end;

constructor TEngine.Create;
begin
  currentViMode := mNormal;
  FOperatorBindings := TDictionary<string, TOperatorClass>.Create;
  FMotionBindings := TDictionary<string, TMotionClass>.Create;
  FEditionBindings := TDictionary<string, TEditionClass>.Create;
  FExBindings := TDictionary<string, TExClass>.Create;
  FClipboard := TClipboard.Create;
  FCurrentOperation := TOperation.Create(self, FClipboard);
  FCurrentOperation.onCommandChanged := OnCommandChanged;
  FEvents := TApplicationEvents.Create(nil);
  FEvents.OnIdle := DoApplicationIdle;
  FillBindings;
end;

destructor TEngine.Destroy;
begin
  FEvents.Free;
  FCurrentOperation.Free;
  FClipboard.Free;
  FExBindings.Free;
  FEditionBindings.Free;
  FMotionBindings.Free;
  FOperatorBindings.Free;
  inherited;
end;

procedure TEngine.ConfigureCursor;
var
  LEditBuffer: IOTAEditBuffer;
begin
  LEditBuffer := GetEditBuffer;

  if LEditBuffer <> nil then
    LEditBuffer.EditOptions.UseBriefCursorShapes := (currentViMode = mNormal) or (currentViMode = mVisual);
end;

procedure TEngine.EditChar(AKey, AScanCode: Word; AShift: TShiftState; AMsg: TMsg; var AHandled: Boolean);
begin
  if currentViMode in [mInactive, mInsert] then
    Exit;

  FShiftState := AShift;
  HandleChar(Chr(AKey));
  AHandled := True;
  (BorlandIDEServices as IOTAEditorServices).TopView.Paint;
end;

procedure TEngine.EditKeyDown(AKey, AScanCode: Word; AShift: TShiftState; AMsg: TMsg; var AHandled: Boolean);
var
  LIsLetter, LIsSymbol: Boolean;

  function IsValidControlKey: boolean;
  begin
    if ssShift in AShift then
      Exit(False);

    if not (ssCtrl in AShift) then
      Exit(False);

    if AKey = ord('D') then
      AKey := ord('d')
    else if AKey = ord('U') then
      AKey := ord('u')
    else if AKey = ord('R') then
      AKey := ord('r')
    else
      Exit(False);

    result := True;
  end;

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

    mNormal, mVisual:
      begin
        if IsValidControlKey then
        begin
          EditChar(AKey, AScanCode, AShift, AMsg, AHandled);
          Exit;
        end;

        if (ssCtrl in AShift) or (ssAlt in AShift) then
          Exit;

        LIsLetter := ((AKey >= ord('A')) and (AKey <= ord('Z'))) or ((AKey >= ord('0')) and (AKey <= ord('9')));
        LIsSymbol := ((AKey >= 186) and (AKey <= 192)) or ((AKey >= 219) and (AKey <= 222)) or (AKey = VK_SPACE)
            or (AKey = VK_RETURN) or (AKey = 8 {backspace}) or (AKey = VK_TAB);

        if LIsLetter or LIsSymbol then
        begin
          // If the keydown is a standard keyboard press not altered with a ctrl
          // or alt key then create a WM_CHAR message so we can do all the
          // locale mapping of the keyboard and then handle the resulting key in
          // EditChar.
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
  else // Insert
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

procedure TEngine.ExecuteLastCommand;
var
  aChar: Char;
begin
  FCurrentOperation.Reset(false);

  for aChar in FCurrentOperation.LastCommand do
    HandleChar(aChar);
end;

procedure TEngine.ResetCurrentOperation;
begin
  // if we are in visual mode and we have an outstanding command to match (like the wrong key), we clear it and stay in visual
  if not ((currentViMode = mVisual) and (FCurrentOperation.CommandToMatch <> '')) then
    currentViMode := mNormal;

  FCurrentOperation.Reset(false);
end;

procedure TEngine.DoApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  if FUpdateActionCaption then
  begin
    FUpdateActionCaption := False;
    SetViMode(FCurrentViMode);
  end;
end;

procedure TEngine.HandleChar(const AChar: Char);
var
  aOperatorClass: TOperatorClass;
  aMotionClass: TMotionClass;
  aEditionClass: TEditionClass;
  aExClass: TExClass;
  commandToMatch: string;
  keepChar: boolean;
  aBuffer: IOTAEditBuffer;
  aCursorPosition: IOTAEditPosition;
  len: integer;
  searchString: string;
begin
  // Backspace
  if aChar = #8 then
  begin
    FCurrentOperation.RemoveLastCharFromCommandToMatch;
    Exit;
  end;

  // Return
  if aChar <> #13 then
  begin
    if ssCtrl in FShiftState then
      FCurrentOperation.AddToCommandToMatch('<C-' + AChar + '>')
    else if (ssShift in FShiftState) and (aChar = #9) then
      FCurrentOperation.AddToCommandToMatch('<S-' + AChar + '>')
    else
      FCurrentOperation.AddToCommandToMatch(AChar);
  end;

  commandToMatch := FCurrentOperation.CommandToMatch;
  aBuffer := GetEditBuffer;
  keepChar := False;
  aCursorPosition := GetEditPosition(aBuffer);

  if FCurrentOperation.TryAddToCount(commandToMatch) then
    // we dont act on this, we just store if as a modifier for other commands
  else if FOperatorBindings.TryGetValue(commandToMatch, aOperatorClass) then
    FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aOperatorClass)
  else if FMotionBindings.TryGetValue(commandToMatch, aMotionClass) then
    FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aMotionClass)
  else if (FCurrentOperation.OperatorCommand = nil) and FEditionBindings.TryGetValue(commandToMatch, aEditionClass) then
    FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aEditionClass)
  else if (aChar = #13) and (FExBindings.TryGetValue(commandToMatch, aExClass)) then
    FCurrentOperation.SetAndExecuteIfComplete(aExClass)
  else
  begin
    keepChar := True;
    // We now look for a two+ character command where the last character is a search token (+)
    len := Length(commandToMatch);
    if len >= 2 then
    begin
      // only support for these for the time being
      searchString := copy(commandToMatch, 0, len - 1) + '+';
      if FMotionBindings.TryGetValue(searchString, aMotionClass) then
      begin
        FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aMotionClass, copy(commandToMatch, len, 1));
        keepChar := False;
      end;
    end;
  end;

  if not keepChar then
    FCurrentOperation.ClearCommandToMatch;
end;

procedure TEngine.LButtonDown;
begin
  FCurrentOperation.Reset(false);
end;

procedure TEngine.FillBindings;
begin
  // operators
  FOperatorBindings.Add('d', TOperatorDelete);
  FOperatorBindings.Add('y', TOperatorYank);
  FOperatorBindings.Add('c', TOperatorChange);
  FOperatorBindings.Add('>', TOperatorIndentRight);
  FOperatorBindings.Add('<', TOperatorIndentLeft);
  FOperatorBindings.Add('=', TOperatorAutoIndent);
  FOperatorBindings.Add('gU', TOperatorUppercase);
  // gUU for line, guu for line
  FOperatorBindings.Add('gu', TOperatorLowercase);
  FOperatorBindings.Add('v', TOperatorVisualMode);

  // motions
  FMotionBindings.Add('w', TMotionWord);
  FMotionBindings.Add('W', TMotionWordCharacter);
  FMotionBindings.Add('b', TMotionWordBack);
  FMotionBindings.Add('B', TMotionWordCharacterBack);
  FMotionBindings.Add('e', TMotionEndOfWord);
  FMotionBindings.Add('E', TMotionEndOfWordCharacter);
  FMotionBindings.Add('i+', TMotionInside);
  FMotionBindings.Add('a+', TMotionAround);

  // here '+' denotes that another character is needed to run/match the command
  FMotionBindings.add('h', TMotionLeft);
  FMotionBindings.add('l', TMotionRight);
  FMotionBindings.add('j', TMotionDown);
  FMotionBindings.add('k', TMotionUp);
  FMotionBindings.add('f+', TMotionFindForward);
  FMotionBindings.add('F+', TMotionFindBackwards);
  FMotionBindings.add('t+', TMotionFindTilForward);
  FMotionBindings.add('T+', TMotionFindTilBackwards);
//  FViNavigationBindings.add('', TMotionHalfPageUp);
//  FViNavigationBindings.add('', TMotionHalfPageDown);
  FMotionBindings.add('0', TMotionBOL);
  FMotionBindings.add('$', TMotionEOL);
  FMotionBindings.add('_', TMotionBOLAfterWhiteSpace);
  FMotionBindings.add('gg', TMotionFirstLine);
  FMotionBindings.add('G', TMotionGoToLine);
  FMotionBindings.add('n', TMotionNextMatch);
  FMotionBindings.add('N', TMotionPreviousMatch);
  FMotionBindings.add('*', TMotionNextWholeWordUnderCursor);
  FMotionBindings.add('#', TMotionPreviousWholeWordUnderCursor);
  FMotionBindings.add(' ', TMotionRight);
  FMotionBindings.add('L', TMotionBottomScreen);
  FMotionBindings.add('M', TMotionMiddleScreen);
  FMotionBindings.add('{', TMotionPreviousParagraphBreak);
  FMotionBindings.add('}', TMotionNextParagraphBreak);
  FMotionBindings.Add('<C-u>', TMotionMoveUpScreen);
  FMotionBindings.Add('<C-d>', TMotionMoveDownScreen);

  //FMotionBindings.Add('<C-o>', TMotionMoveToLastPosition); cant find find a way to support this
  // FViTextObjectBindings.Add('''', TMotionGoToMark); // takes in the mark char

  // one-shots with number modifiers
  FEditionBindings.Add('a', TEditionAppend);
  FEditionBindings.Add('A', TEditionAppendEOL);
  FEditionBindings.Add('i', TEditionInsert);
  FEditionBindings.Add('I', TEditionInsertBOL);
  FEditionBindings.Add('o', TEditionNextLine);
  FEditionBindings.Add('O', TEditionPreviousLine);
  FEditionBindings.Add('s', TEditionDeleteCharInsert);
  FEditionBindings.Add('S', TEditionDeleteLineInsert);
  FEditionBindings.Add('D', TEditionDeleteTilEOL);
  FEditionBindings.Add('C', TEditionChangeTilEOL);
  FEditionBindings.Add('Y', TEditionYankTilEOL);
  FEditionBindings.Add('r', TEditionReplaceChar);
  FEditionBindings.Add('R', TEditionReplaceMode);
  FEditionBindings.Add('u', TEditionUndo);
  FEditionBindings.Add('<C-r>', TEditionRedo);
  FEditionBindings.Add('x', TEditionDeleteCharacter);
  FEditionBindings.Add('X', TEditionDeletePreviousCharacter);
  FEditionBindings.Add('p', TEditionPaste);
  FEditionBindings.Add('P', TEditionPasteBefore);
  FEditionBindings.Add('J', TEditionJoinLines);
  FEditionBindings.Add('.', TEditionRepeatLastCommand);
  FEditionBindings.Add('~', TEditionToggleCase);
  FEditionBindings.Add(#9, TEditionNextBuffer);
  FEditionBindings.Add('<S-'#9'>', TEditionPrevBuffer);

  // todo: this can probably get refactored to be more generic, eg a is all and can be added to most commands
  // add :w* to take in a filename
  FExBindings.Add(':w', TExSaveFile);
  FExBindings.Add(':wa', TExSaveAllFiles);
  FExBindings.Add(':wq', TExSaveAndCloseFile);
  FExBindings.Add(':xa', TExSaveAndCloseAllFiles);
  FExBindings.Add(':wqa', TExSaveAndCloseAllFiles);
  FExBindings.Add(':q', TExCloseFile);
  FExBindings.Add(':qa', TExCloseAllFiles);
  FExBindings.Add(':q!', TExForceCloseFile);
  FExBindings.Add(':qa!', TExForceCloseAllFiles);
//  FExBindings.Add('/', TExSearch);

//To Migrate
//  FViKeybinds.Add('m', ActionSetMark);  // takes in the mark char
//  FViKeybinds.Add('/', ActionSearch);
end;

function TEngine.GetViMode: TViMode;
begin
  result := FCurrentViMode;
end;

procedure TEngine.SetViMode(ANewMode: TViMode);
var
  LText: String;
begin
  FCurrentViMode := ANewMode;
  ConfigureCursor;
  if assigned(FOnCaptionChanged) then
  begin
    LText := GetViModeString(ANewMode, FCurrentCommandForCaption);
    FOnCaptionChanged(LText);
  end;
end;

procedure TEngine.SetOnCaptionChanged(ANewProc: TCaptionChangeProc);
begin
  FOnCaptionChanged := ANewProc;
  FOnCaptionChanged(GetViModeString(currentViMode, FCurrentCommandForCaption)); // call new procedure immediately
end;

procedure TEngine.ToggleActive;
begin
  if currentViMode = mInactive then
    currentViMode := mNormal
  else
    currentViMode := mInactive;
end;

end.
