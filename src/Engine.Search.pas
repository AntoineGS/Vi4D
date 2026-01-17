unit Engine.Search;

interface

uses
  Windows,
  ToolsAPI,
  Commands.Base,
  Engine.Common;

type
  TSearchHandler = class
  private
    FSearchString: string;
    FSearchStartPos: TOTAEditPos;
    FOnCommandChanged: TCommandChangedProc;
    FOnModeChanged: TModeChangedProc;
    FOnResetOperation: TResetOperationProc;

    procedure DoIncrementalSearch;
  public
    constructor Create(aOnCommandChanged: TCommandChangedProc;
      aOnModeChanged: TModeChangedProc; aOnResetOperation: TResetOperationProc);

    procedure StartSearchMode;
    procedure HandleSearchChar(const AChar: Char);
    procedure HandleSearchKeyDown(AKey: Word; AMsg: TMsg; var AHandled: Boolean);
    procedure FinalizeSearch;
    procedure CancelSearch;
  end;

implementation

uses
  NavUtils;

constructor TSearchHandler.Create(aOnCommandChanged: TCommandChangedProc;
  aOnModeChanged: TModeChangedProc; aOnResetOperation: TResetOperationProc);
begin
  FOnCommandChanged := aOnCommandChanged;
  FOnModeChanged := aOnModeChanged;
  FOnResetOperation := aOnResetOperation;
end;

procedure TSearchHandler.StartSearchMode;
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
  FOnModeChanged(mSearch);
end;

procedure TSearchHandler.HandleSearchChar(const AChar: Char);
begin
  FSearchString := FSearchString + AChar;
  FOnCommandChanged(FSearchString);
  DoIncrementalSearch;
end;

procedure TSearchHandler.HandleSearchKeyDown(AKey: Word; AMsg: TMsg; var AHandled: Boolean);
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
          FOnCommandChanged(FSearchString);
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

procedure TSearchHandler.DoIncrementalSearch;
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

procedure TSearchHandler.FinalizeSearch;
begin
  // Search is already set up from incremental search
  // Clear the command display and switch back to normal mode
  FOnCommandChanged('');
  FOnModeChanged(mNormal);
  FOnResetOperation();
end;

procedure TSearchHandler.CancelSearch;
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
  FOnModeChanged(mNormal);
  FOnResetOperation();
end;

end.
