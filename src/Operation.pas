unit Operation;

interface

uses
  Generics.Collections,
  Commands.Base,
  Commands.Operators,
  Commands.Motion,
  Commands.Edition,
  Commands.Ex,
  SysUtils,
  ToolsAPI,
  Clipboard;

type
  TCommandChangedProc = reference to procedure(aCommand: String);

  TOperation = class
  private
    FCommandToMatch: string; // to allow multi-character actions like gg, gU, etc.
    FOperator: TOperator;
    FMotion: TCommand;
    FCount: integer;
    FEngine: IEngine;
    FClipboard: TClipboard;
    FCountSet: boolean;
    FCommand: string;
    FLastCommand: string;
    FCommandChangedProc: TCommandChangedProc;
    procedure SetOnCommandChanged(aProc: TCommandChangedProc);
    procedure SetCommand(aCommand: string);
  public
    constructor Create(aEngine: IEngine; aClipboard: TClipboard);
    destructor Destroy; override;
    procedure SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aOperatorClass: TOperatorClass); overload;
    procedure SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aMotionClass: TMotionClass;
        searchToken: string = ''); overload;
    procedure SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aEditionClass: TEditionClass); overload;
    procedure SetAndExecuteIfComplete(aExClass: TExClass); overload;

    procedure AddToCommandToMatch(const aString: string);
    procedure RemoveLastCharFromCommandToMatch;
    procedure ClearCommandToMatch;
    procedure Reset(saveLastOperation: boolean);
    procedure AddToCount(aValue: Integer);
    function TryAddToCount(const aString: string): boolean;
    function Count(default: integer = 1): integer;
    property CommandToMatch: string read FCommandToMatch;
    property LastCommand: string read FLastCommand;
    property OperatorCommand: TOperator read FOperator;
    property onCommandChanged: TCommandChangedProc write SetOnCommandChanged;
  end;

implementation

uses
  NavUtils;

function TOperation.TryAddToCount(const aString: string): boolean;
var
  aChar: Char;
begin
  if Length(aString) <> 1 then
    Exit(False);

  aChar := aString[1];

  if not CharInSet(AChar, ['0' .. '9']) then
    Exit(False);

  if (AChar = '0') and not FCountSet then
    Exit(False);

  AddToCount(ord(AChar) - ord('0')); // trust me
  result := True;
end;

procedure TOperation.AddToCommandToMatch(const aString: string);
begin
  FCommandToMatch := FCommandToMatch + aString;
  SetCommand(FCommand + aString);
end;

procedure TOperation.AddToCount(aValue: Integer);
begin
  if not FCountSet then
    FCount := aValue
  else
    FCount := 10 * FCount + aValue;

  FCountSet := True;
end;

procedure TOperation.ClearCommandToMatch;
begin
  FCommandToMatch := '';
end;

function TOperation.Count(default: integer): integer;
begin
  if FCountSet then
    result := FCount
  else
    result := default;
end;

constructor TOperation.Create(aEngine: IEngine; aClipboard: TClipboard);
begin
  if aEngine = nil then
    Raise Exception.Create('aEngine must be set in call to TOperation.Create');

  if aClipboard = nil then
    Raise Exception.Create('aClipboard must be set in call to TOperation.Create');

  FEngine := aEngine;
  FClipboard := aClipboard;

  Reset(false);
end;

destructor TOperation.Destroy;
begin
  Reset(false);
end;

procedure TOperation.SetCommand(aCommand: string);
begin
  FCommand := aCommand;

  if Assigned(FCommandChangedProc) then
    FCommandChangedProc(aCommand);
end;

procedure TOperation.SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aOperatorClass: TOperatorClass);
var
  aOperator: TOperator;
  aMotionDown: TMotionDown;
  lpos: TOTAEditPos;
  aSelection: IOTAEditBlock;
begin
  if aOperatorClass = nil then
    Raise Exception.Create('aOperatorCClass must be set in call to SetAndExecuteIfComplete');

  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to SetAndExecuteIfComplete');

  aMotionDown := nil;
  aOperator := aOperatorClass.Create(FClipboard, FEngine);
  try
    // special cases for Visual mode
    if aOperatorClass = TOperatorVisualMode then
      if FEngine.CurrentViMode = mVisual then
        FEngine.CurrentViMode := mNormal
      else
        FEngine.CurrentViMode := mVisual;

    if FOperator = nil then
    begin
      FOperator := aOperator;
      // dont free it in the finally
      aOperator := nil;
      aSelection := GetEditBuffer.EditBlock;

      if (aSelection.Size <> 0) then
      begin
        FOperator.Execute(aCursorPosition, lpos, false);
        Reset(true);
      end;

      exit;
    end;

    // line-level operation, like dd or yy
    if FOperator.ClassType = aOperator.ClassType then
    begin
      // go to BOL, then select whole line using Down, then execute and pass the selection
      aCursorPosition.MoveBOL;
      aMotionDown := TMotionDown.Create(FClipboard, FEngine);
      // I would probably need to pass the motion and count to the operator here
      lpos := GetPositionForMove(aCursorPosition, aMotionDown, true, FCount);
      FOperator.Execute(aCursorPosition, lpos, true);
    end;
  finally
    aOperator.Free;
    aMotionDown.Free;
  end;

  Reset(true);
end;

procedure TOperation.SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aMotionClass: TMotionClass;
    searchToken: string = '');
var
  aSearchMotion: ISearchMotion;
  aExecuteMotion: IExecuteMotion;
begin
  if aMotionClass = nil then
    Raise Exception.Create('aMotionClass must be set in call to SetAndExecuteIfComplete');

  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to SetAndExecuteIfComplete');

  if FMotion = nil then
  begin
    FMotion := aMotionClass.Create(FClipboard, FEngine);

    if Supports(FMotion, ISearchMotion, aSearchMotion) then
      aSearchMotion.SearchToken := searchToken;

    if Supports(FMotion, IExecuteMotion, aExecuteMotion) then
      aExecuteMotion.Execute(aCursorPosition, FOperator, Count(aExecuteMotion.DefaultCount));
  end;

  Reset(FOperator <> nil);
end;

procedure TOperation.SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aEditionClass: TEditionClass);
var
  aEdition: TEdition;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to SetAndExecuteIfComplete');

  if aEditionClass = nil then
    Raise Exception.Create('aEditCClass must be set in call to SetAndExecuteIfComplete');

  aEdition := aEditionClass.Create(FClipboard, FEngine);
  try
    aEdition.Execute(aCursorPosition, FCount);
  finally
    aEdition.Free;
  end;

  Reset(false);
end;

procedure TOperation.SetAndExecuteIfComplete(aExClass: TExClass);
var
  aEx: TEx;
begin
  if aExClass = nil then
    Raise Exception.Create('aExClass must be set in call to SetAndExecuteIfComplete');

  aEx := aExClass.Create(FClipboard, FEngine);
  try
    aEx.Execute;
  finally
    aEx.Free;
  end;

  Reset(false);
end;

procedure TOperation.SetOnCommandChanged(aProc: TCommandChangedProc);
begin
  FCommandChangedProc := aProc;
end;

procedure TOperation.RemoveLastCharFromCommandToMatch;
var
  newCommand: string;
begin
  if Length(FCommandToMatch) > 0 then
    SetLength(FCommandToMatch, Length(FCommandToMatch) - 1);

  if Length(FCommand) > 0 then
  begin
    newCommand := FCommand;
    SetLength(newCommand, Length(newCommand) - 1);
    SetCommand(newCommand);
  end;
end;

procedure TOperation.Reset(saveLastOperation: boolean);
begin
  if saveLastOperation and (FCommand <> '.') and (FCommand <> '') then
    FLastCommand := FCommand;

  FreeAndNil(FOperator);
  FreeAndNil(FMotion);
  SetCommand('');
  FCommandToMatch := '';
  FCount := 1;
  FCountSet := False;
end;

end.
