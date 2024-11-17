unit Commands.Operators;

interface

uses
  Commands.Base,
  ToolsAPI,
  Clipboard;

type
  TViCharClass = (viWhiteSpace, viWord, viSpecial);

  TViOperatorC = class(TViCommand)
  protected
    function GetBlockAction: TBlockAction; virtual;
  public
    {$MESSAGE 'review placement of lpos, and requirement after implementing other actions}
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); virtual;
    property BlockAction: TBlockAction read GetBlockAction;
  end;

  TViOperatorCClass = class of TViOperatorC;

  INavigationMotion = interface
  ['{D71A2796-A08C-46E5-8396-A28034A778D5}']
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
    function DefaultCount: integer;
    // todo: should probably remove this in favor of having the two interfaces or inherit from the below
    procedure Execute(aCursorPosition: IOTAEditPosition; aViOperatorC: TViOperatorC; aCount: integer);
  end;

  TViOCDelete = class(TViOperatorC)
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TViOCYank = class(TViOperatorC)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TViOCChange = class(TViOperatorC)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TViOCIndentRight = class(TViOperatorC)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TViOCIndentLeft = class(TViOperatorC)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TViOCAutoIndent = class(TViOperatorC)
  end;

  TViOCUppercase = class(TViOperatorC)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  TViOCLowercase = class(TViOperatorC)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos); override;
  end;

  function CharAtRelativeLocation(aCursorPosition: IOTAEditPosition; ACol: Integer): TViCharClass;
  function GetPositionForMove(aCursorPosition: IOTAEditPosition; aNormalMotion: INavigationMotion; forEdition: boolean;
      ACount: Integer = 1; fullLines: boolean = false): TOTAEditPos;

implementation

uses
  SysUtils,
  NavUtils,
  Commands.Editing;

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

function CharAtRelativeLocation(aCursorPosition: IOTAEditPosition; ACol: Integer): TViCharClass;
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

procedure TViOperatorC.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set to call to TViOperatorC.Execute');
end;

{ TViOCYank }

procedure TViOCYank.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baYank, True, lPos);
end;

function TViOCYank.GetBlockAction: TBlockAction;
begin
  result := baYank;
end;

procedure TViOCDelete.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;

//  if not FInRepeatChange then
//    SavePreviousAction;

  ApplyActionToSelection(aCursorPosition, baDelete, True, lPos);
end;

function TViOperatorC.GetBlockAction: TBlockAction;
begin
  result := baDelete;
end;

{ TViOCChange }

procedure TViOCChange.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
var
  aViECPreviousLine: TViECPreviousLine;
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baDelete, True, lPos);
  aViECPreviousLine := TViECPreviousLine.Create(FClipboard, FViEngine);
  try
    aViECPreviousLine.Execute(aCursorPosition, 1);
  finally
    aViECPreviousLine.Free;
  end;
end;

function TViOCChange.GetBlockAction: TBlockAction;
begin
  result := baChange;
end;

{ TViOCIndentLeft }

procedure TViOCIndentLeft.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ChangeIndentation(aCursorPosition, dBack);
end;

function TViOCIndentLeft.GetBlockAction: TBlockAction;
begin
  result := baIndentLeft;
end;

{ TViOCIndentRight }

procedure TViOCIndentRight.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ChangeIndentation(aCursorPosition, dForward);
end;

function TViOCIndentRight.GetBlockAction: TBlockAction;
begin
  result := baIndentRight;
end;

{ TViOCUppercase }

procedure TViOCUppercase.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baUppercase, True, lPos);
end;

function TViOCUppercase.GetBlockAction: TBlockAction;
begin
  result := baUppercase;
end;

{ TViOCLowercase }

procedure TViOCLowercase.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baLowercase, True, lPos);
end;

function TViOCLowercase.GetBlockAction: TBlockAction;
begin
  result := baLowercase;
end;

end.
