unit Commands.Base;

interface

uses
  Generics.Defaults,
  ToolsAPI,
  SysUtils,
  Clipboard;

type
  TBlockAction = (baDelete, baChange, baYank, baIndentLeft, baIndentRight, baUppercase, baLowercase, baVisual);
  TViMode = (mInactive, mNormal, mInsert, mVisual);
  TDirection = (dForward, dBack);

  IEngine = interface
  ['{F2D38261-228B-4CC2-9D86-EC9D39CA63A8}']
    function GetViMode: TViMode;
    procedure SetViMode(ANewMode: TViMode);
    property CurrentViMode: TViMode read GetViMode write SetViMode;
    procedure ExecuteLastCommand;
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
    Raise Exception.Create('aCursorPosition must be set in call to ApplyActionToSelection');

  if not Assigned(aSelectionFunc) then
    Raise Exception.Create('aSelectionFunc must be set in call to ApplyActionToSelection');

  restoreCustorPosition := AAction in [baYank, baIndentLeft, baIndentRight, baUppercase, baLowercase];

  if restoreCustorPosition then
    aCursorPosition.Save;
  try
    LSelection := aSelectionFunc();
    LTemp := LSelection.Text;
    FClipboard.SetCurrentRegisterIsLine(AIsLine);
    FClipboard.SetCurrentRegisterText(LTemp);

    case AAction of
      baDelete:
        LSelection.Delete;
      baChange:
        begin
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
        LSelection.Reset;
      baIndentLeft:
        ChangeIndentation(aCursorPosition, dBack);
      baIndentRight:
        ChangeIndentation(aCursorPosition, dForward);
      baUppercase:
        ChangeCase(aCursorPosition, true);
      baLowercase:
        ChangeCase(aCursorPosition, false);
      baVisual:
        FEngine.currentViMode := mVisual;
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
