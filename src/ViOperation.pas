unit ViOperation;

interface

uses
  Generics.Collections,
  Commands.Base,
  Commands.Operators,
  Commands.Navigation,
  Commands.Editing,
  SysUtils,
  ToolsAPI,
  Clipboard;

type
  TCommandChangedProc = reference to procedure(aCommand: String);

  TViOperation = class
  private
    FCommandToMatch: string; // to allow multi-character actions like gg, gU, etc.
    FOperator: TViOperatorC;
    FMotion: TViCommand;
    FCount: integer; // could be `i` or `a` instead
    FViEngine: IViEngine;
    FClipboard: TClipboard;
    FCountSet: boolean;
    FCommand: string;
    FLastCommand: string;
    FCommandChangedProc: TCommandChangedProc;
    procedure SetOnCommandChanged(aProc: TCommandChangedProc);
    procedure SetCommand(aCommand: string);
  public
    constructor Create(aViEngine: IViEngine; aClipboard: TClipboard);
    destructor Destroy; override;
    procedure SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aViOperatorCClass: TViOperatorCClass); overload;
    procedure SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aViNavigationCClass: TViNavigationCClass;
        searchToken: string = ''); overload;
    procedure SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aViEditCClass: TViEditCClass); overload;

    procedure AddToCommandToMatch(const aString: string);
    procedure ClearCommandToMatch;
    procedure Reset(saveLastOperation: boolean);
    procedure AddToCount(aValue: Integer);
    function TryAddToCount(const aString: string): boolean;
    function Count(default: integer = 1): integer;
    property CommandToMatch: string read FCommandToMatch;
    property LastCommand: string read FLastCommand;
    property OperatorCommand: TViOperatorC read FOperator;
    property onCommandChanged: TCommandChangedProc write SetOnCommandChanged;
  end;

implementation

function TViOperation.TryAddToCount(const aString: string): boolean;
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

procedure TViOperation.AddToCommandToMatch(const aString: string);
begin
  FCommandToMatch := FCommandToMatch + aString;
  SetCommand(FCommand + aString);
end;

procedure TViOperation.AddToCount(aValue: Integer);
begin
  if not FCountSet then
    FCount := aValue
  else
    FCount := 10 * FCount + aValue;

  FCountSet := True;
end;

procedure TViOperation.ClearCommandToMatch;
begin
  FCommandToMatch := '';
end;

function TViOperation.Count(default: integer): integer;
begin
  if FCountSet then
    result := FCount
  else
    result := default;
end;

constructor TViOperation.Create(aViEngine: IViEngine; aClipboard: TClipboard);
begin
  if aViEngine = nil then
    Raise Exception.Create('aViEngine must be set in call to TViOperation.Create');

  if aClipboard = nil then
    Raise Exception.Create('aClipboard must be set in call to TViOperation.Create');

  FViEngine := aViEngine;
  FClipboard := aClipboard;

  Reset(false);
end;

destructor TViOperation.Destroy;
begin
  Reset(false);
end;

procedure TViOperation.SetCommand(aCommand: string);
begin
  FCommand := aCommand;

  if Assigned(FCommandChangedProc) then
    FCommandChangedProc(aCommand);
end;

procedure TViOperation.SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aViOperatorCClass: TViOperatorCClass);
var
  aViOperatorC: TViOperatorC;
  aViNCDown: TViNCDown;
  lpos: TOTAEditPos;
begin
  if aViOperatorCClass = nil then
    Raise Exception.Create('aViOperatorCClass must be set in call to SetAndExecuteIfComplete');

  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to SetAndExecuteIfComplete');

  aViNCDown := nil;
  aViOperatorC := aViOperatorCClass.Create(FClipboard, FViEngine);
  try
    if FOperator = nil then
    begin
      FOperator := aViOperatorC;
      aViOperatorC := nil;
      exit;
    end;

    // line-level operation, like dd or yy
    if FOperator.ClassType = aViOperatorC.ClassType then
    begin
      // go to BOL, then select whole line using Down, then execute and pass the selection
      aCursorPosition.MoveBOL;
      aViNCDown := TViNCDown.Create(FClipboard, FViEngine);
      lpos := GetPositionForMove(aCursorPosition, aViNCDown, true, FCount);
      FOperator.Execute(aCursorPosition, lpos);
    end;
  finally
    aViOperatorC.Free;
    aViNCDown.Free;
  end;

  Reset(true);
end;

procedure TViOperation.SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aViNavigationCClass: TViNavigationCClass;
    searchToken: string = '');
var
  aNormalMotion: INavigationMotion;
  aSearchMotion: ISearchMotion;
  aEditionMotion: IEditionMotion;
begin
  if aViNavigationCClass = nil then
    Raise Exception.Create('aViNavigationCClass must be set in call to SetAndExecuteIfComplete');

  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to SetAndExecuteIfComplete');

  if FMotion = nil then
  begin
    FMotion := aViNavigationCClass.Create(FClipboard, FViEngine);

    if Supports(FMotion, ISearchMotion, aSearchMotion) then
      aSearchMotion.SearchToken := searchToken;

    if Supports(FMotion, INavigationMotion, aNormalMotion) then
      aNormalMotion.Execute(aCursorPosition, FOperator, Count(aNormalMotion.DefaultCount));

    if Supports(FMotion, IEditionMotion, aEditionMotion) then
      aEditionMotion.Execute(aCursorPosition, FOperator, 0);
  end;

  Reset(FOperator <> nil);
end;

procedure TViOperation.SetAndExecuteIfComplete(aCursorPosition: IOTAEditPosition; aViEditCClass: TViEditCClass);
var
  aEditCommand: TViEditC;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to SetAndExecuteIfComplete');

  if aViEditCClass = nil then
    Raise Exception.Create('aViEditCClass must be set in call to SetAndExecuteIfComplete');

  aEditCommand := aViEditCClass.Create(FClipboard, FViEngine);
  try
    aEditCommand.Execute(aCursorPosition, FCount);
  finally
    aEditCommand.Free;
  end;

  Reset(false);
end;

procedure TViOperation.SetOnCommandChanged(aProc: TCommandChangedProc);
begin
  FCommandChangedProc := aProc;
end;

procedure TViOperation.Reset(saveLastOperation: boolean);
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
