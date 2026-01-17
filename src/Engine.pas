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
  RegisterPopup;

type
  TSubstitutePhase = (spSearchPattern, spReplacePattern, spFlags);

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
    FSearchString: string;
    FSearchStartPos: TOTAEditPos;
    FMarkArray: array [0 .. 255] of TMark;
    FPopupManager: TPopupManager;
    // Substitute mode state
    FSubstitutePhase: TSubstitutePhase;
    FSubstituteSearch: string;
    FSubstituteReplace: string;
    FSubstituteFlags: string;
    FSubstituteStartPos: TOTAEditPos;
    FSubstituteFullCommand: string;

    procedure FillBindings;
    procedure HandleChar(const AChar: Char);
    procedure ResetCurrentOperation;
    procedure ExecuteLastCommand;
    function GetViMode: TViMode;
    procedure SetViMode(ANewMode: TViMode);
    procedure SetOnCaptionChanged(ANewProc: TCaptionChangeProc);
    procedure OnCommandChanged(aCommand: string);
    procedure DoApplicationIdle(Sender: TObject; var Done: Boolean);
    procedure HandleSearchChar(const AChar: Char);
    procedure HandleSearchKeyDown(AKey: Word; AMsg: TMsg; var AHandled: Boolean);
    procedure DoIncrementalSearch;
    procedure FinalizeSearch;
    procedure CancelSearch;
    // Substitute mode methods
    procedure StartSubstituteMode;
    procedure HandleSubstituteChar(const AChar: Char);
    procedure HandleSubstituteKeyDown(AKey: Word; AMsg: TMsg; var AHandled: Boolean);
    procedure DoSubstituteHighlight;
    procedure ExecuteSubstitute;
    procedure CancelSubstitute;
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
  FillBindings;
end;

destructor TEngine.Destroy;
begin
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
    HandleSearchChar(Chr(AKey));
    AHandled := True;
    (BorlandIDEServices as IOTAEditorServices).TopView.Paint;
    Exit;
  end;

  if currentViMode = mSubstitute then
  begin
    HandleSubstituteChar(Chr(AKey));
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
      AKey := ord('v')  // Ctrl+V for visual block mode
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
    mInsert:
      begin
        if (AKey = VK_ESCAPE) then
        begin
          GetTopMostEditView.Buffer.BufferOptions.InsertMode := True;
          currentViMode := mNormal; // Go from Insert back to Normal
          AHandled := True;
          FCurrentOperation.Reset(false);
        end;
      end;

    mSearch:
      begin
        HandleSearchKeyDown(AKey, AMsg, AHandled);
      end;

    mSubstitute:
      begin
        HandleSubstituteKeyDown(AKey, AMsg, AHandled);
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
  // Hide popup when operation is reset/cancelled
  FPopupManager.HidePopup;

  wasInVisualMode := currentViMode in [mVisual, mVisualLine, mVisualBlock];

  // if we are in visual mode and we have an outstanding command to match (like the wrong key), we clear it and stay in visual
  if not (wasInVisualMode and (FCurrentOperation.CommandToMatch <> '')) then
  begin
    // Clear selection when exiting visual mode
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
    
    // If we're in register/mark selection mode, update or hide the popup
    if FPopupManager.IsVisible then
    begin
      if (Length(commandToMatch) = 1) and ((commandToMatch[1] = '"') or (commandToMatch[1] = '''') or (commandToMatch[1] = '`')) then
      begin
        // Just the prefix remains, clear selection in popup
        FPopupManager.UpdateSelection('');
      end
      else if (Length(commandToMatch) = 0) then
      begin
        // No prefix left, hide the popup
        FPopupManager.HidePopup;
      end;
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

  // Show popup for register selection when " is pressed (non-modal)
  if (commandToMatch = '"') then
  begin
    FPopupManager.ShowRegisterPopup;
    Exit;
  end;

  // Handle register selection with " prefix (e.g., "a for register a, "1 for register 1)
  if (Length(commandToMatch) = 2) and (commandToMatch[1] = '"') then
  begin
    // Update popup selection as user types (use Copy to convert Char to string)
    FPopupManager.UpdateSelection(Copy(commandToMatch, 2, 1));
    // For numbered registers 0-9, use actual number as index
    if CharInSet(commandToMatch[2], ['0'..'9']) then
      FClipboard.SetSelectedRegister(Ord(commandToMatch[2]) - Ord('0'))
    else
      // For named registers a-z, use ASCII value as index
      FClipboard.SetSelectedRegister(Ord(commandToMatch[2]));
    // Keep the command for backspace support, but don't process further
    Exit;
  end;

  // If we have 3+ chars and starts with ", strip the register prefix
  if (Length(commandToMatch) >= 3) and (commandToMatch[1] = '"') then
  begin
    FPopupManager.HidePopup;
    // Remove the register prefix from the command and continue processing
    FCurrentOperation.ClearCommandToMatch;
    FCurrentOperation.AddToCommandToMatch(commandToMatch[3]);
    commandToMatch := FCurrentOperation.CommandToMatch;
  end;

  // Show popup for mark selection when ' or ` is pressed (non-modal)
  if (commandToMatch = '''') or (commandToMatch = '`') then
  begin
    FPopupManager.ShowMarkPopup;
    Exit;
  end;

  // Handle mark selection with ' or ` prefix
  if (Length(commandToMatch) = 2) and ((commandToMatch[1] = '''') or (commandToMatch[1] = '`')) then
  begin
    // Update popup selection as user types (use Copy to convert Char to string)
    FPopupManager.UpdateSelection(Copy(commandToMatch, 2, 1));
    // Don't exit - let normal motion processing handle it
  end;

  // Check for substitute command trigger
  if commandToMatch = ':%s/' then
  begin
    StartSubstituteMode;
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
    // We now look for a two+ character command where the last character is a search token (+)
    len := Length(commandToMatch);
    if len >= 2 then
    begin
      // Support for two+ character commands where the last character is a search token (+)
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
    // Hide popup when command is completed
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
  FMotionBindings.Add('zz', TMotionCenterScreen);

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

procedure TEngine.StartSearchMode;
var
  aCursorPosition: IOTAEditPosition;
  aBuffer: IOTAEditBuffer;
begin
  aBuffer := GetEditBuffer;
  if aBuffer = nil then
    Exit;

  aCursorPosition := GetEditPosition(aBuffer);
  if aCursorPosition = nil then
    Exit;

  // Save current position for cancel
  FSearchStartPos.Line := aCursorPosition.Row;
  FSearchStartPos.Col := aCursorPosition.Column;

  // Initialize search state
  FSearchString := '';

  // Enter search mode
  currentViMode := mSearch;
end;

procedure TEngine.HandleSearchChar(const AChar: Char);
begin
  FSearchString := FSearchString + AChar;
  OnCommandChanged(FSearchString);
  DoIncrementalSearch;
end;

procedure TEngine.HandleSearchKeyDown(AKey: Word; AMsg: TMsg; var AHandled: Boolean);
begin
  case AKey of
    VK_RETURN:
      begin
        FinalizeSearch;
        AHandled := True;
      end;
    VK_ESCAPE:
      begin
        CancelSearch;
        AHandled := True;
      end;
    8: // Backspace
      begin
        if Length(FSearchString) > 0 then
        begin
          SetLength(FSearchString, Length(FSearchString) - 1);
          OnCommandChanged(FSearchString);
          DoIncrementalSearch;
        end
        else
        begin
          // Empty search string, cancel search
          CancelSearch;
        end;
        AHandled := True;
      end;
  else
    // Let other keys through to generate WM_CHAR
    TranslateMessage(AMsg);
    AHandled := True;
  end;
end;

procedure TEngine.DoIncrementalSearch;
var
  aCursorPosition: IOTAEditPosition;
  aBuffer: IOTAEditBuffer;
begin
  if FSearchString = '' then
    Exit;

  aBuffer := GetEditBuffer;
  if aBuffer = nil then
    Exit;

  aCursorPosition := GetEditPosition(aBuffer);
  if aCursorPosition = nil then
    Exit;

  // Restore to start position before searching
  aCursorPosition.Move(FSearchStartPos.Line, FSearchStartPos.Col);

  // Set up search
  aCursorPosition.SearchOptions.SearchText := FSearchString;
  aCursorPosition.SearchOptions.CaseSensitive := False;
  aCursorPosition.SearchOptions.Direction := sdForward;
  aCursorPosition.SearchOptions.FromCursor := True;
  aCursorPosition.SearchOptions.RegularExpression := True;
  aCursorPosition.SearchOptions.WholeFile := True;
  aCursorPosition.SearchOptions.WordBoundary := False;

  // Do the search
  if not aCursorPosition.SearchAgain then
  begin
    // Search failed from current position, try from the beginning
    aCursorPosition.Move(1, 1);
    aCursorPosition.SearchAgain;
  end;

  aBuffer.TopView.MoveViewToCursor;
end;

procedure TEngine.FinalizeSearch;
begin
  // Search is already set up from incremental search
  // Clear the command display and switch back to normal mode
  OnCommandChanged('');
  currentViMode := mNormal;
  FCurrentOperation.Reset(False);
end;

procedure TEngine.CancelSearch;
var
  aCursorPosition: IOTAEditPosition;
  aBuffer: IOTAEditBuffer;
begin
  // Restore cursor to original position
  aBuffer := GetEditBuffer;
  if aBuffer <> nil then
  begin
    aCursorPosition := GetEditPosition(aBuffer);
    if aCursorPosition <> nil then
      aCursorPosition.Move(FSearchStartPos.Line, FSearchStartPos.Col);
  end;

  FSearchString := '';
  currentViMode := mNormal;
  FCurrentOperation.Reset(False);
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

procedure TEngine.StartSubstituteMode;
var
  aCursorPosition: IOTAEditPosition;
  aBuffer: IOTAEditBuffer;
begin
  aBuffer := GetEditBuffer;
  if aBuffer = nil then
    Exit;

  aCursorPosition := GetEditPosition(aBuffer);
  if aCursorPosition = nil then
    Exit;

  // Save current position for cancel
  FSubstituteStartPos.Line := aCursorPosition.Row;
  FSubstituteStartPos.Col := aCursorPosition.Column;

  // Initialize substitute state
  FSubstitutePhase := spSearchPattern;
  FSubstituteSearch := '';
  FSubstituteReplace := '';
  FSubstituteFlags := '';
  FSubstituteFullCommand := ':%s/';

  // Enter substitute mode
  currentViMode := mSubstitute;
  OnCommandChanged(FSubstituteFullCommand);
end;

procedure TEngine.HandleSubstituteChar(const AChar: Char);
begin
  if AChar = '/' then
  begin
    // Transition between phases
    case FSubstitutePhase of
      spSearchPattern:
        begin
          FSubstitutePhase := spReplacePattern;
          FSubstituteFullCommand := FSubstituteFullCommand + '/';
        end;
      spReplacePattern:
        begin
          FSubstitutePhase := spFlags;
          FSubstituteFullCommand := FSubstituteFullCommand + '/';
        end;
      spFlags:
        begin
          // Extra / in flags phase - just append
          FSubstituteFlags := FSubstituteFlags + AChar;
          FSubstituteFullCommand := FSubstituteFullCommand + AChar;
        end;
    end;
  end
  else
  begin
    // Append character to current phase
    case FSubstitutePhase of
      spSearchPattern:
        begin
          FSubstituteSearch := FSubstituteSearch + AChar;
          FSubstituteFullCommand := FSubstituteFullCommand + AChar;
          DoSubstituteHighlight;
        end;
      spReplacePattern:
        begin
          FSubstituteReplace := FSubstituteReplace + AChar;
          FSubstituteFullCommand := FSubstituteFullCommand + AChar;
        end;
      spFlags:
        begin
          FSubstituteFlags := FSubstituteFlags + AChar;
          FSubstituteFullCommand := FSubstituteFullCommand + AChar;
        end;
    end;
  end;

  OnCommandChanged(FSubstituteFullCommand);
end;

procedure TEngine.HandleSubstituteKeyDown(AKey: Word; AMsg: TMsg; var AHandled: Boolean);
begin
  case AKey of
    VK_RETURN:
      begin
        ExecuteSubstitute;
        AHandled := True;
      end;
    VK_ESCAPE:
      begin
        CancelSubstitute;
        AHandled := True;
      end;
    8: // Backspace
      begin
        case FSubstitutePhase of
          spSearchPattern:
            begin
              if Length(FSubstituteSearch) > 0 then
              begin
                SetLength(FSubstituteSearch, Length(FSubstituteSearch) - 1);
                SetLength(FSubstituteFullCommand, Length(FSubstituteFullCommand) - 1);
                DoSubstituteHighlight;
              end
              else
              begin
                // At the start of search pattern, cancel
                CancelSubstitute;
              end;
            end;
          spReplacePattern:
            begin
              if Length(FSubstituteReplace) > 0 then
              begin
                SetLength(FSubstituteReplace, Length(FSubstituteReplace) - 1);
                SetLength(FSubstituteFullCommand, Length(FSubstituteFullCommand) - 1);
              end
              else
              begin
                // Go back to search phase (remove the '/')
                FSubstitutePhase := spSearchPattern;
                SetLength(FSubstituteFullCommand, Length(FSubstituteFullCommand) - 1);
              end;
            end;
          spFlags:
            begin
              if Length(FSubstituteFlags) > 0 then
              begin
                SetLength(FSubstituteFlags, Length(FSubstituteFlags) - 1);
                SetLength(FSubstituteFullCommand, Length(FSubstituteFullCommand) - 1);
              end
              else
              begin
                // Go back to replace phase (remove the '/')
                FSubstitutePhase := spReplacePattern;
                SetLength(FSubstituteFullCommand, Length(FSubstituteFullCommand) - 1);
              end;
            end;
        end;
        OnCommandChanged(FSubstituteFullCommand);
        AHandled := True;
      end;
  else
    // Let other keys through to generate WM_CHAR
    TranslateMessage(AMsg);
    AHandled := True;
  end;
end;

procedure TEngine.DoSubstituteHighlight;
var
  aCursorPosition: IOTAEditPosition;
  aBuffer: IOTAEditBuffer;
begin
  aBuffer := GetEditBuffer;
  if aBuffer = nil then
    Exit;

  aCursorPosition := GetEditPosition(aBuffer);
  if aCursorPosition = nil then
    Exit;

  if FSubstituteSearch = '' then
  begin
    // Clear highlighting when search is empty
    aCursorPosition.SearchOptions.SearchText := '';
    aCursorPosition.SearchAgain;
    Exit;
  end;

  // Set up search to highlight all matches
  aCursorPosition.SearchOptions.SearchText := FSubstituteSearch;
  aCursorPosition.SearchOptions.CaseSensitive := False;
  aCursorPosition.SearchOptions.Direction := sdForward;
  aCursorPosition.SearchOptions.FromCursor := False;
  aCursorPosition.SearchOptions.RegularExpression := False;
  aCursorPosition.SearchOptions.WholeFile := True;
  aCursorPosition.SearchOptions.WordBoundary := False;

  // Move to beginning and search to trigger highlighting
  aCursorPosition.Move(1, 1);
  aCursorPosition.SearchAgain;

  // Restore cursor position
  aCursorPosition.Move(FSubstituteStartPos.Line, FSubstituteStartPos.Col);
end;

procedure TEngine.ExecuteSubstitute;
var
  aCursorPosition: IOTAEditPosition;
  aBuffer: IOTAEditBuffer;
  aWriter: IOTAEditWriter;
  globalReplace: Boolean;
  lastReplacedLine: Integer;
  matchLen: Integer;
  currentLine: Integer;
  matches: array of Integer;  // Linear character positions
  matchCount: Integer;
  i: Integer;
  charPos: TOTACharPos;
  linearPos: Integer;
  replaceAnsi: AnsiString;
begin
  if FSubstituteSearch = '' then
  begin
    CancelSubstitute;
    Exit;
  end;

  aBuffer := GetEditBuffer;
  if aBuffer = nil then
  begin
    CancelSubstitute;
    Exit;
  end;

  aCursorPosition := GetEditPosition(aBuffer);
  if aCursorPosition = nil then
  begin
    CancelSubstitute;
    Exit;
  end;

  // Check for 'g' flag
  globalReplace := Pos('g', FSubstituteFlags) > 0;
  lastReplacedLine := -1;
  matchLen := Length(FSubstituteSearch);
  matchCount := 0;
  SetLength(matches, 0);

  // Set up search
  aCursorPosition.SearchOptions.SearchText := FSubstituteSearch;
  aCursorPosition.SearchOptions.CaseSensitive := False;
  aCursorPosition.SearchOptions.Direction := sdForward;
  aCursorPosition.SearchOptions.FromCursor := True;
  aCursorPosition.SearchOptions.RegularExpression := False;
  aCursorPosition.SearchOptions.WholeFile := True;
  aCursorPosition.SearchOptions.WordBoundary := False;

  // Start from beginning of file
  aCursorPosition.Move(1, 1);

  // First pass: collect all match positions (linear character positions)
  while aCursorPosition.SearchAgain do
  begin
    currentLine := aCursorPosition.Row;

    // For non-global replace, only replace first occurrence per line
    if (not globalReplace) and (currentLine = lastReplacedLine) then
      Continue;

    // Get linear position of match start (cursor is at end of match)
    aCursorPosition.MoveRelative(0, -matchLen);
    charPos.Line := aCursorPosition.Row;
    charPos.CharIndex := aCursorPosition.Column - 1;  // CharIndex is 0-based
    linearPos := aBuffer.TopView.CharPosToPos(charPos);
    aCursorPosition.MoveRelative(0, matchLen); // Move back for next search

    SetLength(matches, matchCount + 1);
    matches[matchCount] := linearPos;
    Inc(matchCount);

    lastReplacedLine := currentLine;
  end;

  // Second pass: apply replacements using undoable writer
  if matchCount > 0 then
  begin
    replaceAnsi := AnsiString(FSubstituteReplace);
    aWriter := aBuffer.CreateUndoableWriter;
    try
      // Process matches in order - CopyTo, DeleteTo, Insert pattern
      for i := 0 to matchCount - 1 do
      begin
        // Copy everything up to this match
        aWriter.CopyTo(matches[i]);
        // Skip over the matched text
        aWriter.DeleteTo(matches[i] + matchLen);
        // Insert replacement
        aWriter.Insert(PAnsiChar(replaceAnsi));
      end;
      // Copy remaining content to end of file
      aWriter.CopyTo(MaxInt);
    finally
      aWriter := nil;
    end;
  end;

  // Clear search highlighting
  aCursorPosition.SearchOptions.SearchText := '';
  aCursorPosition.SearchAgain;

  // Return to normal mode
  OnCommandChanged('');
  currentViMode := mNormal;
  FCurrentOperation.Reset(False);
end;

procedure TEngine.CancelSubstitute;
var
  aCursorPosition: IOTAEditPosition;
  aBuffer: IOTAEditBuffer;
begin
  // Restore cursor to original position
  aBuffer := GetEditBuffer;
  if aBuffer <> nil then
  begin
    aCursorPosition := GetEditPosition(aBuffer);
    if aCursorPosition <> nil then
    begin
      aCursorPosition.Move(FSubstituteStartPos.Line, FSubstituteStartPos.Col);
      // Clear search highlighting
      aCursorPosition.SearchOptions.SearchText := '';
      aCursorPosition.SearchAgain;
    end;
  end;

  OnCommandChanged('');
  currentViMode := mNormal;
  FCurrentOperation.Reset(False);
end;

end.
