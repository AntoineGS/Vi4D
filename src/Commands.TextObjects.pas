unit Commands.TextObjects;

interface

uses
  Commands.Base,
  Commands.Operators,
  Commands.Navigation,
  ToolsAPI;

type
  TViTextObjectC = class(TViCommand)
  public
    procedure Execute(aCursorPosition: IOTAEditPosition; aViOperatorC: TViOperatorC; aCount: integer);
    function DefaultCount: integer; virtual;
  end;

  TViTextObjectCClass = class of TViTextObjectC;

  TViTOCParagraph = class(TViTextObjectC)
  end;

  TViTOCWord = class(TViTextObjectC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViTOCWordCharacter = class(TViTextObjectC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViTOCWordBack = class(TViTextObjectC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViTOCWordCharacterBack = class(TViTextObjectC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViTOCEndOfWordCharacter = class(TViTextObjectC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViTOCEndOfWord = class(TViTextObjectC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViTOCParenthesisOpen = class(TViTextObjectC)
  end;

  TViTOCParenthesisClose = class(TViTextObjectC)
  end;

  TViTOCSquareBracketOpen = class(TViTextObjectC)
  end;

  TViTOCSquareBracketClose = class(TViTextObjectC)
  end;

  TViTOCBracesOpen = class(TViTextObjectC)
  end;

  TViTOCBracesClose = class(TViTextObjectC)
  end;

  TViTOCAngleBracketOpen = class(TViTextObjectC)
  end;

  TViTOCAngleBracketClose = class(TViTextObjectC)
  end;

  TViTOCSingleQuote = class(TViTextObjectC)
  end;

  TViTOCDoubleQuote = class(TViTextObjectC)
  end;

  TViTOCTick = class(TViTextObjectC)
  end;

  // b in vim
  TViTOCBlock = class(TViTextObjectC)
  end;

  // t
  TViTOCTag = class(TViTextObjectC)
  end;

implementation

uses
  SysUtils;

{ TViTOCWord }

procedure TViTOCWord.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  for i := 1 to ACount do
  begin
    if aCursorPosition.IsWordCharacter then
      aCursorPosition.MoveCursor(mmSkipWord or mmSkipRight) // Skip to first non word character.
    else if aCursorPosition.IsSpecialCharacter then
      aCursorPosition.MoveCursor(mmSkipSpecial or mmSkipRight or mmSkipStream);
    // Skip to the first non special character
    // If the character is whitespace or EOL then skip that whitespace
    if (not forEdition) and (aCursorPosition.IsWhiteSpace or (aCursorPosition.Character = #$D)) then
      aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight or mmSkipStream);
  end;
end;

function TViTextObjectC.DefaultCount: integer;
begin
  result := 1;
end;

procedure TViTextObjectC.Execute(aCursorPosition: IOTAEditPosition; aViOperatorC: TViOperatorC; aCount: integer);
var
  lPos: TOTAEditPos;
  aNormalMotion: INavigationMotion;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Execute');

  if not Supports(self, INavigationMotion, aNormalMotion) then
    Exit;

  if aViOperatorC = nil then
  begin
    lPos := GetPositionForMove(aCursorPosition, aNormalMotion, false, aCount);
    aCursorPosition.Move(lPos.Line, lPos.Col);
  end
  else
  begin
    lPos := GetPositionForMove(aCursorPosition, aNormalMotion, true, aCount);
    ApplyActionToSelection(aCursorPosition, aViOperatorC.BlockAction, false, lPos);
  end;
end;

{ TViTOCWordBack }

procedure TViTOCWordBack.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
  LNextChar: TViCharClass;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  for i := 1 to ACount do
  begin
    LNextChar := CharAtRelativeLocation(aCursorPosition, -1);
    if aCursorPosition.IsWordCharacter and ((LNextChar = viSpecial) or (LNextChar = viWhiteSpace)) then
      aCursorPosition.MoveRelative(0, -1);

    if aCursorPosition.IsSpecialCharacter and ((LNextChar = viWord) or (LNextChar = viWhiteSpace)) then
      aCursorPosition.MoveRelative(0, -1);

    if aCursorPosition.IsWhiteSpace then
    begin
      aCursorPosition.MoveCursor(mmSkipWhite or mmSkipLeft or mmSkipStream);
      aCursorPosition.MoveRelative(0, -1);
    end;

    if aCursorPosition.IsWordCharacter then
      aCursorPosition.MoveCursor(mmSkipWord or mmSkipLeft) // Skip to first non word character.
    else if aCursorPosition.IsSpecialCharacter then
      aCursorPosition.MoveCursor(mmSkipSpecial or mmSkipLeft);
    // Skip to the first non special character
  end;
end;

{ TViTOCWordCharacter }

procedure TViTOCWordCharacter.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  for i := 1 to ACount do
  begin
    // Goto first white space after the end of the word.
    aCursorPosition.MoveCursor(mmSkipNonWhite or mmSkipRight);
    // Now skip all the white space until we're at the start of a word again.
    aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight or mmSkipStream);
  end;
end;

{ TViTOCWordCharacterBack }

procedure TViTOCWordCharacterBack.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  for i := 1 to ACount do
  begin
    aCursorPosition.MoveCursor(mmSkipWhite or mmSkipLeft or mmSkipStream);
    aCursorPosition.MoveCursor(mmSkipNonWhite or mmSkipLeft);
  end;
end;

{ TViTOCEndOfWordCharacter }

procedure TViTOCEndOfWordCharacter.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  for i := 1 to ACount do
  begin
    if (aCursorPosition.IsWordCharacter or aCursorPosition.IsSpecialCharacter) and
      (CharAtRelativeLocation(aCursorPosition, 1) = viWhiteSpace) then
      aCursorPosition.MoveRelative(0, 1);

    if aCursorPosition.IsWhiteSpace then
      aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight or mmSkipStream);

    aCursorPosition.MoveCursor(mmSkipNonWhite or mmSkipRight);
    aCursorPosition.MoveRelative(0, -1);
  end;
end;

{ TViTOCEndOfWord }

procedure TViTOCEndOfWord.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  for i := 1 to ACount do
  begin
    aCursorPosition.MoveRelative(0, 1);
    aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);

    if aCursorPosition.IsWordCharacter then
      aCursorPosition.MoveCursor(mmSkipWord or mmSkipRight)
    else if aCursorPosition.IsSpecialCharacter then
      aCursorPosition.MoveCursor(mmSkipSpecial or mmSkipRight)
    else
      aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);

    aCursorPosition.MoveRelative(0, -1);
  end;
end;

end.
