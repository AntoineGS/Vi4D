unit Commands.Operators;

interface

uses
  Commands.Base,
  ToolsAPI,
  Clipboard;

type
  TCharClass = (viWhiteSpace, viWord, viSpecial);

  TOperator = class(TCommand)
  protected
    function GetBlockAction: TBlockAction; virtual;
  public
    {$MESSAGE 'review placement of lpos, and requirement after implementing other actions}
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); virtual;
    property BlockAction: TBlockAction read GetBlockAction;
  end;

  TOperatorClass = class of TOperator;

  INavigationMotion = interface
  ['{D71A2796-A08C-46E5-8396-A28034A778D5}']
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
    function DefaultCount: integer;
    // todo: should probably remove this in favor of having the two interfaces or inherit from the below
    procedure Execute(aCursorPosition: IOTAEditPosition; aViOperatorC: TOperator; aCount: integer);
  end;

  TOperatorDelete = class(TOperator)
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TOperatorYank = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TOperatorChange = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TOperatorIndentRight = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TOperatorIndentLeft = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TOperatorAutoIndent = class(TOperator)
  end;

  TOperatorUppercase = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TOperatorLowercase = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  function CharAtRelativeLocation(aCursorPosition: IOTAEditPosition; ACol: Integer): TCharClass;
  function GetPositionForMove(aCursorPosition: IOTAEditPosition; aNormalMotion: INavigationMotion; forEdition: boolean;
      ACount: Integer = 1; fullLines: boolean = false): TOTAEditPos;

implementation

uses
  SysUtils,
  NavUtils,
  Commands.Edition;

function GetPositionForMove(aCursorPosition: IOTAEditPosition; aNormalMotion: INavigationMotion; forEdition: boolean;
    ACount: Integer = 1; fullLines: boolean = false): TOTAEditPos;
var
  LPos: TOTAEditPos;
  currLine: integer;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to TViTextObjectC.GetPositionForMove');

  if aNormalMotion = nil then
    Raise Exception.Create('aNormalMotion must be set in call to TViTextObjectC.GetPositionForMove');

  currLine := aCursorPosition.Row;
  aCursorPosition.Save;
  aNormalMotion.Move(aCursorPosition, ACount, forEdition);

  if fullLines then
  begin
    aNormalMotion.Move(aCursorPosition, 1, forEdition);

    // we are lower
    if aCursorPosition.Row > currLine then
      aCursorPosition.MoveBOL
    else //higher
      aCursorPosition.MoveEOL;
  end;

  LPos.Col := aCursorPosition.Column;
  LPos.Line := aCursorPosition.Row;
  aCursorPosition.Restore;
  result := LPos;
end;

function CharAtRelativeLocation(aCursorPosition: IOTAEditPosition; ACol: Integer): TCharClass;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to CharAtRelativeLocation');

  aCursorPosition.Save;
  aCursorPosition.MoveRelative(0, ACol);

  if aCursorPosition.IsWhiteSpace or (aCursorPosition.Character = #$D) then
    result := viWhiteSpace
  else if aCursorPosition.IsWordCharacter then
    result := viWord
  else
    result := viSpecial;

  aCursorPosition.Restore;
end;

procedure TOperator.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set to call to TViOperatorC.Execute');
end;

{ TOperatorYank }

procedure TOperatorYank.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baYank, True, lPos);
end;

function TOperatorYank.GetBlockAction: TBlockAction;
begin
  result := baYank;
end;

procedure TOperatorDelete.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;

//  if not FInRepeatChange then
//    SavePreviousAction;

  ApplyActionToSelection(aCursorPosition, baDelete, True, lPos);
end;

function TOperator.GetBlockAction: TBlockAction;
begin
  result := baDelete;
end;

{ TOperatorChange }

procedure TOperatorChange.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
var
  aEditionPreviousLine: TEditionPreviousLine;
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baDelete, True, lPos);
  aEditionPreviousLine := TEditionPreviousLine.Create(FClipboard, FEngine);
  try
    aEditionPreviousLine.Execute(aCursorPosition, 1);
  finally
    aEditionPreviousLine.Free;
  end;
end;

function TOperatorChange.GetBlockAction: TBlockAction;
begin
  result := baChange;
end;

{ TOperatorIndentLeft }

procedure TOperatorIndentLeft.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ChangeIndentation(aCursorPosition, dBack);
end;

function TOperatorIndentLeft.GetBlockAction: TBlockAction;
begin
  result := baIndentLeft;
end;

{ TOperatorIndentRight }

procedure TOperatorIndentRight.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ChangeIndentation(aCursorPosition, dForward);
end;

function TOperatorIndentRight.GetBlockAction: TBlockAction;
begin
  result := baIndentRight;
end;

{ TOperatorUppercase }

procedure TOperatorUppercase.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baUppercase, True, lPos);
end;

function TOperatorUppercase.GetBlockAction: TBlockAction;
begin
  result := baUppercase;
end;

{ TOperatorLowercase }

procedure TOperatorLowercase.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baLowercase, True, lPos);
end;

function TOperatorLowercase.GetBlockAction: TBlockAction;
begin
  result := baLowercase;
end;

end.
