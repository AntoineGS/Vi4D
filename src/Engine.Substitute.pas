unit Engine.Substitute;

interface

uses
  Windows,
  ToolsAPI,
  Commands.Base,
  Engine.Common;

type
  TSubstitutePhase = (spSearchPattern, spReplacePattern, spFlags);

  TSubstituteHandler = class
  private
    FSubstitutePhase: TSubstitutePhase;
    FSubstituteSearch: string;
    FSubstituteReplace: string;
    FSubstituteFlags: string;
    FSubstituteStartPos: TOTAEditPos;
    FSubstituteFullCommand: string;
    FOnCommandChanged: TCommandChangedProc;
    FOnModeChanged: TModeChangedProc;
    FOnResetOperation: TResetOperationProc;

    procedure DoSubstituteHighlight;
    procedure ExecuteSubstitute;
  public
    constructor Create(aOnCommandChanged: TCommandChangedProc;
      aOnModeChanged: TModeChangedProc; aOnResetOperation: TResetOperationProc);

    procedure StartSubstituteMode;
    procedure HandleSubstituteChar(const AChar: Char);
    procedure HandleSubstituteKeyDown(AKey: Word; AMsg: TMsg; var AHandled: Boolean);
    procedure CancelSubstitute;
  end;

implementation

uses
  SysUtils,
  NavUtils;

constructor TSubstituteHandler.Create(aOnCommandChanged: TCommandChangedProc;
  aOnModeChanged: TModeChangedProc; aOnResetOperation: TResetOperationProc);
begin
  FOnCommandChanged := aOnCommandChanged;
  FOnModeChanged := aOnModeChanged;
  FOnResetOperation := aOnResetOperation;
end;

procedure TSubstituteHandler.StartSubstituteMode;
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
  FOnModeChanged(mSubstitute);
  FOnCommandChanged(FSubstituteFullCommand);
end;

procedure TSubstituteHandler.HandleSubstituteChar(const AChar: Char);
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

  FOnCommandChanged(FSubstituteFullCommand);
end;

procedure TSubstituteHandler.HandleSubstituteKeyDown(AKey: Word; AMsg: TMsg; var AHandled: Boolean);
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
        FOnCommandChanged(FSubstituteFullCommand);
        AHandled := True;
      end;
  else
    // Let other keys through to generate WM_CHAR
    TranslateMessage(AMsg);
    AHandled := True;
  end;
end;

procedure TSubstituteHandler.DoSubstituteHighlight;
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

procedure TSubstituteHandler.ExecuteSubstitute;
var
  aCursorPosition: IOTAEditPosition;
  aBuffer: IOTAEditBuffer;
  aWriter: IOTAEditWriter;
  globalReplace: Boolean;
  lastReplacedLine: Integer;
  matchLen: Integer;
  currentLine: Integer;
  matches: array of Integer;
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
    charPos.CharIndex := aCursorPosition.Column - 1;
    linearPos := aBuffer.TopView.CharPosToPos(charPos);
    aCursorPosition.MoveRelative(0, matchLen);

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
      for i := 0 to matchCount - 1 do
      begin
        aWriter.CopyTo(matches[i]);
        aWriter.DeleteTo(matches[i] + matchLen);
        aWriter.Insert(PAnsiChar(replaceAnsi));
      end;
      aWriter.CopyTo(MaxInt);
    finally
      aWriter := nil;
    end;
  end;

  // Clear search highlighting
  aCursorPosition.SearchOptions.SearchText := '';
  aCursorPosition.SearchAgain;

  // Return to normal mode
  FOnCommandChanged('');
  FOnModeChanged(mNormal);
  FOnResetOperation();
end;

procedure TSubstituteHandler.CancelSubstitute;
var
  aCursorPosition: IOTAEditPosition;
  aBuffer: IOTAEditBuffer;
begin
  aBuffer := GetEditBuffer;
  if aBuffer <> nil then
  begin
    aCursorPosition := GetEditPosition(aBuffer);
    if aCursorPosition <> nil then
    begin
      aCursorPosition.Move(FSubstituteStartPos.Line, FSubstituteStartPos.Col);
      aCursorPosition.SearchOptions.SearchText := '';
      aCursorPosition.SearchAgain;
    end;
  end;

  FOnCommandChanged('');
  FOnModeChanged(mNormal);
  FOnResetOperation();
end;

end.
