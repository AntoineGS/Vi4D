unit Operation;

interface

uses
  Generics.Collections,
  Commands.Base,
  Commands.Operators,
  Commands.Motion,
  Commands.Edition,
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
    FCount: integer; // could be `i` or `a` instead
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

    procedure AddToCommandToMatch(const aString: string);
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
begin
  if aOperatorClass = nil then
    Raise Exception.Create('aOperatorCClass must be set in call to SetAndExecuteIfComplete');

  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to SetAndExecuteIfComplete');

  aMotionDown := nil;
  aOperator := aOperatorClass.Create(FClipboard, FEngine);
  try
    if FOperator = nil then
    begin
      FOperator := aOperator;
      aOperator := nil;
      exit;
    end;

    // line-level operation, like dd or yy
    if FOperator.ClassType = aOperator.ClassType then
    begin
      // go to BOL, then select whole line using Down, then execute and pass the selection
      aCursorPosition.MoveBOL;
      aMotionDown := TMotionDown.Create(FClipboard, FEngine);
      lpos := GetPositionForMove(aCursorPosition, aMotionDown, true, FCount);
      FOperator.Execute(aCursorPosition, lpos);
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
  aNavigationMotion: INavigationMotion;
  aSearchMotion: ISearchMotion;
  aEditionMotion: IEditionMotion;
begin
  if aMotionClass = nil then
    Raise Exception.Create('aNavigationCClass must be set in call to SetAndExecuteIfComplete');

  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to SetAndExecuteIfComplete');

  if FMotion = nil then
  begin
    FMotion := aMotionClass.Create(FClipboard, FEngine);

    if Supports(FMotion, ISearchMotion, aSearchMotion) then
      aSearchMotion.SearchToken := searchToken;

    if Supports(FMotion, INavigationMotion, aNavigationMotion) then
      aNavigationMotion.Execute(aCursorPosition, FOperator, Count(aNavigationMotion.DefaultCount));

    if Supports(FMotion, IEditionMotion, aEditionMotion) then
      aEditionMotion.Execute(aCursorPosition, FOperator, 0);
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

procedure TOperation.SetOnCommandChanged(aProc: TCommandChangedProc);
begin
  FCommandChangedProc := aProc;
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
