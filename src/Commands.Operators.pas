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
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean); virtual;
    property BlockAction: TBlockAction read GetBlockAction;
  end;

  TOperatorClass = class of TOperator;

  IMoveMotion = interface
  ['{D71A2796-A08C-46E5-8396-A28034A778D5}']
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
    function DefaultCount: integer;
  end;

  TOperatorDelete = class(TOperator)
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean); override;
  end;

  TOperatorYank = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean); override;
  end;

  TOperatorChange = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean); override;
  end;

  TOperatorIndentRight = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean); override;
  end;

  TOperatorIndentLeft = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean); override;
  end;

  TOperatorAutoIndent = class(TOperator)
  end;

  TOperatorUppercase = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean); override;
  end;

  TOperatorLowercase = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean); override;
  end;

  TOperatorVisualMode = class(TOperator)
    function GetBlockAction: TBlockAction; override;
    procedure Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean); override;
  end;

  function CharAtRelativeLocation(aCursorPosition: IOTAEditPosition; ACol: Integer): TCharClass;
  function GetPositionForMove(aCursorPosition: IOTAEditPosition; aNormalMotion: IMoveMotion; forEdition: boolean;
      ACount: Integer = 1; fullLines: boolean = false): TOTAEditPos;

implementation

uses
  SysUtils,
  NavUtils,
  Commands.Edition;

function GetPositionForMove(aCursorPosition: IOTAEditPosition; aNormalMotion: IMoveMotion; forEdition: boolean;
    ACount: Integer = 1; fullLines: boolean = false): TOTAEditPos;
var
  LPos: TOTAEditPos;
  currLine: integer;
  aSelection: IOTAEditBlock;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to TViTextObjectC.GetPositionForMove');

  if aNormalMotion = nil then
    Raise Exception.Create('aNormalMotion must be set in call to TViTextObjectC.GetPositionForMove');

  aSelection := GetEditBuffer.EditBlock;
  aSelection.Save;
  aCursorPosition.Save;
  try
    currLine := aCursorPosition.Row;
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
  finally
    aCursorPosition.Restore;
    aSelection.Restore;
  end;
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

procedure TOperator.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set to call to TViOperatorC.Execute');
end;

{ TOperatorYank }

procedure TOperatorYank.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baYank, fullLine, lPos);
end;

function TOperatorYank.GetBlockAction: TBlockAction;
begin
  result := baYank;
end;

procedure TOperatorDelete.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean);
begin
  inherited;

//  if not FInRepeatChange then
//    SavePreviousAction;

  ApplyActionToSelection(aCursorPosition, baDelete, fullLine, lPos);
end;

function TOperator.GetBlockAction: TBlockAction;
begin
  result := baDelete;
end;

{ TOperatorChange }

procedure TOperatorChange.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baChange, fullLine, lPos);
end;

function TOperatorChange.GetBlockAction: TBlockAction;
begin
  result := baChange;
end;

{ TOperatorIndentLeft }

procedure TOperatorIndentLeft.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean);
begin
  inherited;
  ChangeIndentation(aCursorPosition, dBack);
end;

function TOperatorIndentLeft.GetBlockAction: TBlockAction;
begin
  result := baIndentLeft;
end;

{ TOperatorIndentRight }

procedure TOperatorIndentRight.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean);
begin
  inherited;
  ChangeIndentation(aCursorPosition, dForward);
end;

function TOperatorIndentRight.GetBlockAction: TBlockAction;
begin
  result := baIndentRight;
end;

{ TOperatorUppercase }

procedure TOperatorUppercase.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baUppercase, fullLine, lpos);
end;

function TOperatorUppercase.GetBlockAction: TBlockAction;
begin
  result := baUppercase;
end;

{ TOperatorLowercase }

procedure TOperatorLowercase.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean);
begin
  inherited;
  ApplyActionToSelection(aCursorPosition, baLowercase, fullLine, lPos);
end;

function TOperatorLowercase.GetBlockAction: TBlockAction;
begin
  result := baLowercase;
end;

{ TOperatorVisualMode }

procedure TOperatorVisualMode.Execute(aCursorPosition: IOTAEditPosition; lpos: TOTAEditPos; fullLine: boolean);
begin
  inherited;
  FEngine.CurrentViMode := mNormal;
end;

function TOperatorVisualMode.GetBlockAction: TBlockAction;
begin
  result := baVisual;
end;

end.
