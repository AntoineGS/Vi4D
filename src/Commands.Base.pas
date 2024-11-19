unit Commands.Base;

interface

uses
  Generics.Defaults,
  ToolsAPI,
  SysUtils,
  Clipboard;

type
  TBlockAction = (baDelete, baChange, baYank, baIndentLeft, baIndentRight, baUppercase, baLowercase);
  TViMode = (mInactive, mNormal, mInsert, mVisual);
  TDirection = (dForward, dBack);

  IViEngine = interface
  ['{F2D38261-228B-4CC2-9D86-EC9D39CA63A8}']
    procedure SetViMode(ANewMode: TViMode);
    property CurrentViMode: TViMode write SetViMode;
    procedure ExecuteLastCommand;
  end;

  TViCommand = class(TSingletonImplementation)
  protected
    FViEngine: IViEngine;
    FClipboard: TClipboard;
    procedure ApplyActionToSelection(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
        LPOS: TOTAEditPos); overload;
    procedure ApplyActionToSelection(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
        LSelection: IOTAEditBlock); overload;
  public
    {$MESSAGE 'MAKE SURE TO REMOVE IViEngine!'}
    constructor Create(aClipboard: TClipboard; viEngineToRemove: IViEngine); reintroduce; virtual;
  end;

  TViCommandClass = class of TViCommand;
  procedure ChangeIndentation(aCursorPosition: IOTAEditPosition; ADirection: TDirection);

implementation

uses
  NavUtils;

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

procedure TViCommand.ApplyActionToSelection(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
    LPOS: TOTAEditPos);
var
  LSelection: IOTAEditBlock;
  LTemp: String;
  aBuffer: IOTAEditBuffer;
  restoreCustorPosition: Boolean;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to ChangeIndentation');

  restoreCustorPosition := AAction in [baYank, baIndentLeft, baIndentRight, baUppercase, baLowercase];

  if restoreCustorPosition then
    aCursorPosition.Save;
  try
    aBuffer := GetEditBuffer;
    LSelection := aBuffer.EditBlock;
    LSelection.Reset;
    LSelection.BeginBlock;
    LSelection.Extend(LPos.Line, LPos.Col);
    FClipboard.SetCurrentRegisterIsLine(AIsLine);
    LTemp := LSelection.Text;
    FClipboard.SetCurrentRegisterText(LTemp);

    case AAction of
      baDelete, baChange:
        LSelection.Delete;
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
    end;

    if AAction = baChange then
      FViEngine.currentViMode := mInsert;

    LSelection.EndBlock;
  finally
    if restoreCustorPosition then
      aCursorPosition.Restore;
  end;
end;

// todo: currently a duplicate
procedure TViCommand.ApplyActionToSelection(aCursorPosition: IOTAEditPosition; AAction: TBlockAction; AIsLine: Boolean;
    LSelection: IOTAEditBlock);
var
  LTemp: String;
  restoreCustorPosition: Boolean;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to ChangeIndentation');

  restoreCustorPosition := AAction in [baYank, baIndentLeft, baIndentRight, baUppercase, baLowercase];

  if restoreCustorPosition then
    aCursorPosition.Save;
  try
    FClipboard.SetCurrentRegisterIsLine(AIsLine);
    LTemp := LSelection.Text;
    FClipboard.SetCurrentRegisterText(LTemp);

    case AAction of
      baDelete, baChange:
        LSelection.Delete;
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
    end;

    if AAction = baChange then
      FViEngine.currentViMode := mInsert;

  finally
    if restoreCustorPosition then
      aCursorPosition.Restore;
  end;
end;

constructor TViCommand.Create(aClipboard: TClipboard; viEngineToRemove: IViEngine);
begin
  if aClipboard = nil then
    Raise Exception.Create('aClipboard must be set in call to TViCommand.Create');

  FViEngine := viEngineToRemove;
  FClipboard := aClipboard;
end;

end.
