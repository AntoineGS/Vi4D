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
  ToolsAPI,
  Commands.Base,
  Commands.Motion,
  Commands.Operators,
  Commands.Edition,
  Commands.Ex,
  Operation,
  Clipboard,
  AppEvnts,
  RegisterPopup,
  Engine.Search,
  Engine.Substitute;

type
  TCaptionChangeProc = reference to procedure(aCaption: String);

  TEngine = class(TSingletonImplementation, IEngine)
  private
    FCurrentViMode: TViMode;
    FCurrentCommandForCaption: string;
    FShiftState: TShiftState;
    FCurrentOperation: TOperation;
    FOnCaptionChanged: TCaptionChangeProc;
    FOperatorBindings: TDictionary<string, TOperatorClass>;
    FMotionBindings: TDictionary<string, TMotionClass>;
    FEditionBindings: TDictionary<string, TEditionClass>;
    FExBindings: TDictionary<string, TExClass>;
    FClipboard: TClipboard;
    FUpdateActionCaption: boolean;
    FEvents: TApplicationEvents;
    FMarkArray: array [0 .. 255] of TMark;
    FPopupManager: TPopupManager;
    FSearchHandler: TSearchHandler;
    FSubstituteHandler: TSubstituteHandler;

    procedure FillBindings;
    procedure HandleChar(const AChar: Char);
    procedure ResetCurrentOperation;
    procedure ExecuteLastCommand;
    function GetViMode: TViMode;
    procedure SetViMode(ANewMode: TViMode);
    procedure SetOnCaptionChanged(ANewProc: TCaptionChangeProc);
    procedure OnCommandChanged(aCommand: string);
    procedure DoApplicationIdle(Sender: TObject; var Done: Boolean);
    procedure ResetOperationCallback;
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
    procedure StartSearchMode;
    procedure SetMark(aIndex: Integer; const aFileName: string; aLine, aCol: Integer);
    function GetMark(aIndex: Integer): TMark;
  end;

implementation

uses
  NavUtils,
  SysUtils,
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
    mVisualLine: mode := 'V-LINE';
    mVisualBlock: mode := 'V-BLOCK';
    mSearch: mode := '/';
    mSubstitute: mode := 'SUBSTITUTE';
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

procedure TEngine.ResetOperationCallback;
begin
  FCurrentOperation.Reset(False);
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
  FPopupManager := TPopupManager.Create(FClipboard, GetMark);

  // Create handlers with callbacks
  FSearchHandler := TSearchHandler.Create(OnCommandChanged, SetViMode, ResetOperationCallback);
  FSubstituteHandler := TSubstituteHandler.Create(OnCommandChanged, SetViMode, ResetOperationCallback);

  FillBindings;
end;

destructor TEngine.Destroy;
begin
  FSubstituteHandler.Free;
  FSearchHandler.Free;
  FPopupManager.Free;
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
    LEditBuffer.EditOptions.UseBriefCursorShapes := currentViMode in [mNormal, mVisual, mVisualLine, mVisualBlock];
end;

procedure TEngine.EditChar(AKey, AScanCode: Word; AShift: TShiftState; AMsg: TMsg; var AHandled: Boolean);
begin
  if currentViMode in [mInactive, mInsert] then
    Exit;

  if currentViMode = mSearch then
  begin
    FSearchHandler.HandleSearchChar(Chr(AKey));
    AHandled := True;
    (BorlandIDEServices as IOTAEditorServices).TopView.Paint;
    Exit;
  end;

  if currentViMode = mSubstitute then
  begin
    FSubstituteHandler.HandleSubstituteChar(Chr(AKey));
    AHandled := True;
    (BorlandIDEServices as IOTAEditorServices).TopView.Paint;
    Exit;
  end;

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
    else if AKey = ord('V') then
      AKey := ord('v')
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

    mNormal, mVisual, mVisualLine, mVisualBlock:
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
            or (AKey = VK_RETURN) or (AKey = 8) or (AKey = VK_TAB);

        if LIsLetter or LIsSymbol then
        begin
          TranslateMessage(AMsg);
          AHandled := True;
        end
        else if (AKey = VK_ESCAPE) then
        begin
          ResetCurrentOperation;
          AHandled := True;
        end;
      end;
    mInsert:
      begin
        if (AKey = VK_ESCAPE) then
        begin
          GetTopMostEditView.Buffer.BufferOptions.InsertMode := True;
          currentViMode := mNormal;
          AHandled := True;
          FCurrentOperation.Reset(false);
        end;
      end;

    mSearch:
      begin
        FSearchHandler.HandleSearchKeyDown(AKey, AMsg, AHandled);
      end;

    mSubstitute:
      begin
        FSubstituteHandler.HandleSubstituteKeyDown(AKey, AMsg, AHandled);
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
var
  aBuffer: IOTAEditBuffer;
  aCursorPosition: IOTAEditPosition;
  aSelection: IOTAEditBlock;
  wasInVisualMode: boolean;
begin
  FPopupManager.HidePopup;

  wasInVisualMode := currentViMode in [mVisual, mVisualLine, mVisualBlock];

  if not (wasInVisualMode and (FCurrentOperation.CommandToMatch <> '')) then
  begin
    if wasInVisualMode then
    begin
      aBuffer := GetEditBuffer;
      if aBuffer <> nil then
      begin
        aSelection := aBuffer.EditBlock;
        aSelection.Reset;
      end;
    end;
    currentViMode := mNormal;
  end;

  FCurrentOperation.Reset(false);

  // Clear search highlighting (like :noh in Vim)
  aBuffer := GetEditBuffer;
  if aBuffer <> nil then
  begin
    aCursorPosition := GetEditPosition(aBuffer);
    if aCursorPosition <> nil then
    begin
      aCursorPosition.SearchOptions.SearchText := '';
      aCursorPosition.SearchAgain;
    end;
  end;
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
  aOperatorClass := nil;

  // Backspace
  if aChar = #8 then
  begin
    FCurrentOperation.RemoveLastCharFromCommandToMatch;
    commandToMatch := FCurrentOperation.CommandToMatch;

    if FPopupManager.IsVisible then
    begin
      if (Length(commandToMatch) = 1) and ((commandToMatch[1] = '"') or (commandToMatch[1] = '''') or (commandToMatch[1] = '`')) then
        FPopupManager.UpdateSelection('')
      else if (Length(commandToMatch) = 0) then
        FPopupManager.HidePopup;
    end;
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

  // Show popup for register selection when " is pressed
  if (commandToMatch = '"') then
  begin
    FPopupManager.ShowRegisterPopup;
    Exit;
  end;

  // Handle register selection with " prefix
  if (Length(commandToMatch) = 2) and (commandToMatch[1] = '"') then
  begin
    FPopupManager.UpdateSelection(Copy(commandToMatch, 2, 1));
    if CharInSet(commandToMatch[2], ['0'..'9']) then
      FClipboard.SetSelectedRegister(Ord(commandToMatch[2]) - Ord('0'))
    else
      FClipboard.SetSelectedRegister(Ord(commandToMatch[2]));
    Exit;
  end;

  // If we have 3+ chars and starts with ", strip the register prefix
  if (Length(commandToMatch) >= 3) and (commandToMatch[1] = '"') then
  begin
    FPopupManager.HidePopup;
    FCurrentOperation.ClearCommandToMatch;
    FCurrentOperation.AddToCommandToMatch(commandToMatch[3]);
    commandToMatch := FCurrentOperation.CommandToMatch;
  end;

  // Show popup for mark selection when ' or ` is pressed
  if (commandToMatch = '''') or (commandToMatch = '`') then
  begin
    FPopupManager.ShowMarkPopup;
    Exit;
  end;

  // Handle mark selection with ' or ` prefix
  if (Length(commandToMatch) = 2) and ((commandToMatch[1] = '''') or (commandToMatch[1] = '`')) then
    FPopupManager.UpdateSelection(Copy(commandToMatch, 2, 1));

  // Check for substitute command trigger
  if commandToMatch = ':%s/' then
  begin
    FSubstituteHandler.StartSubstituteMode;
    FCurrentOperation.ClearCommandToMatch;
    Exit;
  end;

  if FCurrentOperation.IsAFullLineOperation then
    aOperatorClass := TOperatorClass(FCurrentOperation.OperatorCommand.ClassType);

  if FCurrentOperation.TryAddToCount(commandToMatch) then
    // we dont act on this, we just store if as a modifier for other commands
  else if (aOperatorClass <> nil) or FOperatorBindings.TryGetValue(commandToMatch, aOperatorClass) then
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
    len := Length(commandToMatch);
    if len >= 2 then
    begin
      searchString := copy(commandToMatch, 0, len - 1) + '+';
      if FMotionBindings.TryGetValue(searchString, aMotionClass) then
      begin
        FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aMotionClass, copy(commandToMatch, len, 1));
        keepChar := False;
      end
      else if (FCurrentOperation.OperatorCommand = nil) and FEditionBindings.TryGetValue(searchString, aEditionClass) then
      begin
        FCurrentOperation.SetAndExecuteIfComplete(aCursorPosition, aEditionClass, copy(commandToMatch, len, 1));
        keepChar := False;
      end;
    end;
  end;

  if not keepChar then
  begin
    FCurrentOperation.ClearCommandToMatch;
    FPopupManager.HidePopup;
  end;
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
  FOperatorBindings.Add('gu', TOperatorLowercase);
  FOperatorBindings.Add('gc', TOperatorComment);
  FOperatorBindings.Add('v', TOperatorVisualMode);
  FOperatorBindings.Add('V', TOperatorVisualLineMode);
  FOperatorBindings.Add('<C-v>', TOperatorVisualBlockMode);

  // motions
  FMotionBindings.Add('w', TMotionWord);
  FMotionBindings.Add('W', TMotionWordCharacter);
  FMotionBindings.Add('b', TMotionWordBack);
  FMotionBindings.Add('B', TMotionWordCharacterBack);
  FMotionBindings.Add('e', TMotionEndOfWord);
  FMotionBindings.Add('E', TMotionEndOfWordCharacter);
  FMotionBindings.Add('i+', TMotionInside);
  FMotionBindings.Add('a+', TMotionAround);

  FMotionBindings.add('h', TMotionLeft);
  FMotionBindings.add('l', TMotionRight);
  FMotionBindings.add('j', TMotionDown);
  FMotionBindings.add('k', TMotionUp);
  FMotionBindings.add('f+', TMotionFindForward);
  FMotionBindings.add('F+', TMotionFindBackwards);
  FMotionBindings.add('t+', TMotionFindTilForward);
  FMotionBindings.add('T+', TMotionFindTilBackwards);
  FMotionBindings.add('0', TMotionBOL);
  FMotionBindings.add('$', TMotionEOL);
  FMotionBindings.add('_', TMotionBOLAfterWhiteSpace);
  FMotionBindings.add('gg', TMotionFirstLine);
  FMotionBindings.add('G', TMotionGoToLastLine);
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
  FMotionBindings.Add('zz', TMotionCenterScreen);

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
  FEditionBindings.Add('r+', TEditionReplaceChar);
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
  FEditionBindings.Add('/', TEditionSearch);
  FEditionBindings.Add('m+', TEditionSetMark);

  // Mark motions
  FMotionBindings.Add('''+', TMotionGoToMarkLine);
  FMotionBindings.Add('`+', TMotionGoToMarkExact);

  // Ex commands
  FExBindings.Add(':w', TExSaveFile);
  FExBindings.Add(':wa', TExSaveAllFiles);
  FExBindings.Add(':wq', TExSaveAndCloseFile);
  FExBindings.Add(':xa', TExSaveAndCloseAllFiles);
  FExBindings.Add(':wqa', TExSaveAndCloseAllFiles);
  FExBindings.Add(':q', TExCloseFile);
  FExBindings.Add(':qa', TExCloseAllFiles);
  FExBindings.Add(':q!', TExForceCloseFile);
  FExBindings.Add(':qa!', TExForceCloseAllFiles);
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
  FOnCaptionChanged(GetViModeString(currentViMode, FCurrentCommandForCaption));
end;

procedure TEngine.ToggleActive;
begin
  if currentViMode = mInactive then
    currentViMode := mNormal
  else
    currentViMode := mInactive;
end;

procedure TEngine.StartSearchMode;
begin
  FSearchHandler.StartSearchMode;
end;

procedure TEngine.SetMark(aIndex: Integer; const aFileName: string; aLine, aCol: Integer);
begin
  if (aIndex >= 0) and (aIndex <= 255) then
  begin
    FMarkArray[aIndex].FileName := aFileName;
    FMarkArray[aIndex].Line := aLine;
    FMarkArray[aIndex].Col := aCol;
    FMarkArray[aIndex].IsSet := True;
  end;
end;

function TEngine.GetMark(aIndex: Integer): TMark;
begin
  if (aIndex >= 0) and (aIndex <= 255) then
    Result := FMarkArray[aIndex]
  else
  begin
    Result.IsSet := False;
    Result.FileName := '';
    Result.Line := 0;
    Result.Col := 0;
  end;
end;

end.
