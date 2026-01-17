unit Commands.Base;

interface

uses
  Generics.Defaults,
  ToolsAPI,
  SysUtils,
  Clipboard;

type
  TBlockAction = (baDelete, baChange, baYank, baIndentLeft, baIndentRight, baUppercase, baLowercase, baComment,
      baVisual, baVisualLine, baVisualBlock);
  TViMode = (mInactive, mNormal, mInsert, mVisual, mVisualLine, mVisualBlock, mSearch, mSubstitute);
  TDirection = (dForward, dBack);

  TMark = record
    FileName: string;
    Line: Integer;
    Col: Integer;
    IsSet: Boolean;
  end;

  IEngine = interface
  ['{F2D38261-228B-4CC2-9D86-EC9D39CA63A8}']
    function GetViMode: TViMode;
    procedure SetViMode(ANewMode: TViMode);
    property CurrentViMode: TViMode read GetViMode write SetViMode;
    procedure ExecuteLastCommand;
    procedure StartSearchMode;
    procedure SetMark(aIndex: Integer; const aFileName: string; aLine, aCol: Integer);
    function GetMark(aIndex: Integer): TMark;
  end;

  ISearchMotion = interface
  ['{D8DEFB88-FBC8-4B7C-984C-6F50E27A8213}']
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TCommand = class(TSingletonImplementation)
  protected
    FEngine: IEngine;
    FClipboard: TClipboard;
    procedure ApplyActionToSelection(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
        LPOS: TOTAEditPos); overload;
    procedure ApplyActionToSelection(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
        LSelection: IOTAEditBlock); overload;
    procedure ApplyActionToSelectionInt(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
      aSelectionFunc: TFunc<IOTAEditBlock>);
  public
    constructor Create(aClipboard: TClipboard; aEngine: IEngine); reintroduce; virtual;
  end;

  TCommandClass = class of TCommand;
  procedure ChangeIndentation(aCursorPosition: IOTAEditPosition; ADirection: TDirection);

implementation

uses
  NavUtils,
  StrUtils,
  Commands.Edition; // not great design to have circular deps

procedure ChangeIndentation(aCursorPosition: IOTAEditPosition; ADirection: TDirection);
var
  LSelection: IOTAEditBlock;
  LStartedSelection: Boolean;
  aBuffer: IOTAEditBuffer;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to ChangeIndentation');

  LStartedSelection := False;
  aBuffer := GetEditBuffer;
  LSelection := aBuffer.EditBlock;
  LSelection.Save;
  aCursorPosition.Save;

  if LSelection.Size = 0 then
  begin
    LStartedSelection := True;
    aCursorPosition.MoveBOL;
    LSelection.Reset;
    LSelection.BeginBlock;
    LSelection.Extend(aCursorPosition.Row, aCursorPosition.Column + 1);
  end
  else
  begin
    // When selecting multiple lines, if the cursor is in the first column the last line doesn't get into the block
    // and the indent seems buggy, as the cursor is on the last line but it isn't indented, so we force
    // the selection of at least one char to correct this behavior
    LSelection.ExtendRelative(0, 1);
  end;

  case ADirection of
    dForward:
      LSelection.Indent(aBuffer.EditOptions.BlockIndent);
    dBack:
      LSelection.Indent(-aBuffer.EditOptions.BlockIndent);
  end;

  // If we don't call EndBlock, the selection gets buggy.
  if LStartedSelection then
    LSelection.EndBlock;

  aCursorPosition.Restore;
  LSelection.Restore;
end;

procedure ChangeCase(aCursorPosition: IOTAEditPosition; uppercase: boolean);
var
  LSelection: IOTAEditBlock;
  LStartedSelection: Boolean;
  aBuffer: IOTAEditBuffer;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to ChangeCase');

  LStartedSelection := False;
  aBuffer := GetEditBuffer;
  LSelection := aBuffer.EditBlock;
  LSelection.Save;
  aCursorPosition.Save;

  if LSelection.Size = 0 then
  begin
    LStartedSelection := True;
    aCursorPosition.MoveBOL;
    LSelection.Reset;
    LSelection.BeginBlock;
    LSelection.Extend(aCursorPosition.Row, aCursorPosition.Column + 1);
  end
  else
  begin
    // When selecting multiple lines, if the cursor is in the first column the last line doesn't get into the block
    // and the indent seems buggy, as the cursor is on the last line but it isn't indented, so we force
    // the selection of at least one char to correct this behavior
    LSelection.ExtendRelative(0, 1);
  end;

  if uppercase then
    LSelection.UpperCase
  else
    LSelection.LowerCase;

  // If we don't call EndBlock, the selection gets buggy.
  if LStartedSelection then
    LSelection.EndBlock;

  aCursorPosition.Restore;
  LSelection.Restore;
end;

procedure ToggleComment(aCursorPosition: IOTAEditPosition; AIsLine: boolean);
type
  TRunMode = (rmUnknown, rmCommenting, rmUncommenting);
var
  aSelection: IOTAEditBlock;
  aBuffer: IOTAEditBuffer;
  i: Integer;
  endingRow: Integer;
  runMode: TRunMode;
  startingRow: Integer;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to ToggleComment');

  runMode := rmUnknown;
  aBuffer := GetEditBuffer;
  aSelection := aBuffer.EditBlock;
  aSelection.Save;
  aCursorPosition.Save;
  endingRow := aSelection.EndingRow;
  startingRow := aSelection.StartingRow;

  if aSelection.Size <> 0 then
  begin
    // When selecting multiple lines, if the cursor is in the first column the last line doesn't get into the block
    // and the indent seems buggy, as the cursor is on the last line but it isn't indented, so we force
    // the selection of at least one char to correct this behavior
    aSelection.ExtendRelative(0, 1);
  end;

  // this is done to remove an adjustment done in GetPositionForMove for full lines, which is meant to grab the
  // new line character
  if AIsLine then
  begin
    if aCursorPosition.Row = endingRow then
      dec(endingRow)
    else
      inc(startingRow);
  end;

  for i := startingRow to endingRow do
  begin
    aCursorPosition.MoveReal(i, 0);
    aCursorPosition.MoveBOL;

    if aCursorPosition.IsWhiteSpace then
      aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);

    if runMode = rmUnknown then
    begin
      if aCursorPosition.Read(2) = '//' then
        runMode := rmUncommenting
      else
        runMode := rmCommenting;
    end;

    if aCursorPosition.IsWordCharacter and (runMode = rmCommenting) then
      aCursorPosition.InsertText('// ')
    else if runMode = rmUncommenting then
    begin
      if aCursorPosition.Read(3) = '// ' then
        aCursorPosition.Delete(3)
      else if aCursorPosition.Read(2) = '//' then
        aCursorPosition.Delete(2);
    end;
  end;

  aCursorPosition.Restore;
  aSelection.Restore;
end;

procedure TCommand.ApplyActionToSelection(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
    LPOS: TOTAEditPos);
begin
  ApplyActionToSelectionInt(aCursorPosition, AAction, AIsLine,
      function: IOTAEditBlock
      var
        aBuffer: IOTAEditBuffer;
      begin
        aBuffer := GetEditBuffer;
        result := aBuffer.EditBlock;

        // not ideal to ninja it here for selection but for now it holds up, TBD if a better approach will be needed
        // we already have something selected
        if result.Size <> 0 then
          Exit;

        result.Reset;
        result.BeginBlock;
        result.Extend(LPos.Line, LPos.Col);
      end);
end;

procedure TCommand.ApplyActionToSelection(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
    LSelection: IOTAEditBlock);
begin
  ApplyActionToSelectionInt(aCursorPosition, AAction, AIsLine,
      function: IOTAEditBlock
      begin
        result := LSelection;
      end);
end;

procedure TCommand.ApplyActionToSelectionInt(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
    aSelectionFunc: TFunc<IOTAEditBlock>);
var
  LTemp: String;
  restoreCustorPosition: Boolean;
  LSelection: IOTAEditBlock;
  aEditionPreviousLine: TEditionPreviousLine;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to ApplyActionToSelectionInt');

  if not Assigned(aSelectionFunc) then
    Raise Exception.Create('aSelectionFunc must be set in call to ApplyActionToSelectionInt');

  restoreCustorPosition := AAction in [baYank, baIndentLeft, baIndentRight, baUppercase, baLowercase, baComment];

  if restoreCustorPosition then
    aCursorPosition.Save;
  try
    LSelection := aSelectionFunc();
    LTemp := LSelection.Text;

    // Normalize line endings: convert LF to CRLF (but don't convert CRLF to CRCRLF)
    if AIsLine and (Length(LTemp) > 0) then
    begin
      LTemp := StringReplace(LTemp, #13#10, #10, [rfReplaceAll]);
      LTemp := StringReplace(LTemp, #10, #13#10, [rfReplaceAll]);
      
      // Ensure text ends with line ending
      if (LTemp[Length(LTemp)] <> #10) then
        LTemp := LTemp + #13#10;
    end;

    case AAction of
      baDelete:
        begin
          FClipboard.StoreDelete(LTemp, AIsLine);
          LSelection.Delete;
        end;
      baChange:
        begin
          FClipboard.StoreDelete(LTemp, AIsLine);
          LSelection.Delete;

          if AIsLine then
          begin
            // will call 'O' to add a new line
            aEditionPreviousLine := TEditionPreviousLine.Create(FClipboard, FEngine);
            try
              aEditionPreviousLine.Execute(aCursorPosition, 1);
            finally
              aEditionPreviousLine.Free;
            end;
          end;

          FEngine.currentViMode := mInsert;
        end;
      baYank:
        begin
          FClipboard.StoreYank(LTemp, AIsLine);
          LSelection.Reset;
        end;
      baIndentLeft:
        ChangeIndentation(aCursorPosition, dBack);
      baIndentRight:
        ChangeIndentation(aCursorPosition, dForward);
      baUppercase:
        ChangeCase(aCursorPosition, true);
      baLowercase:
        ChangeCase(aCursorPosition, false);
      baComment:
        ToggleComment(aCursorPosition, AIsLine);
      baVisual:
        FEngine.currentViMode := mVisual;
      baVisualLine:
        FEngine.currentViMode := mVisualLine;
      baVisualBlock:
        FEngine.currentViMode := mVisualBlock;
    end;
  finally
    if restoreCustorPosition then
      aCursorPosition.Restore;
  end;
end;

constructor TCommand.Create(aClipboard: TClipboard; aEngine: IEngine);
begin
  if aClipboard = nil then
    Raise Exception.Create('aClipboard must be set in call to TCommand.Create');

  FEngine := aEngine;
  FClipboard := aClipboard;
end;

end.
