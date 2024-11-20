unit Commands.IAMotion;

interface

uses
  Commands.Base,
  ToolsAPI,
  Clipboard;

type
  TInsideAroundType = (itInside, itAround);

  TIAMotion = class(TCommand)
  protected
    FIAType: TInsideAroundType;
    function InsideGetSelection(aCursorPosition: IOTAEditPosition; const aOpenCharacter, aCloseCharacter: Char): IOTAEditBlock;
  public
    constructor Create(aClipboard: TClipboard; aEngine: IEngine; aIAType: TInsideAroundType); reintroduce; virtual;
  end;

  TIAMotionClass = class of TIAMotion;

  IIAMotion = interface
  ['{134E4567-CB25-40F2-8067-8C83CBA6F55C}']
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // Clever enough to find the next pair if outside
  TIAMotionParenthesis = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIAMotionSquareBracket = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIAMotionBraces = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIAMotionAngleBracket = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // Has to be in between open and close chars
  TIAMotionSingleQuote = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIAMotionDoubleQuote = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIAMotionTick = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // use regular motion
  TIAMotionParagraph = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // use regular motion
  TIAMotionWord = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // ?
  TIAMotionBlocks = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // ?
  TIAMotionTag = class(TIAMotion, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;


implementation

uses
  NavUtils,
  SysUtils,
  StrUtils,
  Math;

{ TInsideAroundC }

constructor TIAMotion.Create(aClipboard: TClipboard; aEngine: IEngine; aIAType: TInsideAroundType);
begin
  inherited Create(aClipboard, aEngine);
  FIAType := aIAType;
end;

function TIAMotion.InsideGetSelection(aCursorPosition: IOTAEditPosition; const aOpenCharacter,
  aCloseCharacter: Char): IOTAEditBlock;
var
  aBuffer: IOTAEditBuffer;
  fromPos,
  toPos: TOTAEditPos;
  openEscapeChar,
  closeEscapeChar: String;
  openBracketCount: integer;
  firstCompleteSetEncountered: boolean;
  firstOpenCharaterEncountered: boolean;
begin
  try
    // todo: maybe a clear highlight would resolve the sticky characters
    openEscapeChar := IfThen(CharInSet(aOpenCharacter, ['.', '^', '$', '*', '+', '?', '(', ')', '[', '{', '\', '|']), '\');
    closeEscapeChar := IfThen(CharInSet(aOpenCharacter, ['.', '^', '$', '*', '+', '?', '(', ')', '[', '{', '\', '|']), '\');
    aBuffer := GetEditBuffer;

    aCursorPosition.Save;
    // first we figure out if we are within a bracket, by looking for an unmatched backet before the cursor
    aCursorPosition.SearchOptions.SearchText :=
        Format('%s%s|%s%s', [openEscapeChar, aOpenCharacter, closeEscapeChar, aCloseCharacter]);
    aCursorPosition.SearchOptions.CaseSensitive := false;
    aCursorPosition.SearchOptions.Direction := sdForward;
    aCursorPosition.SearchOptions.FromCursor := true;
    aCursorPosition.SearchOptions.RegularExpression := True;
    aCursorPosition.SearchOptions.WholeFile := true;
    aCursorPosition.SearchOptions.WordBoundary := false;
    openBracketCount := 0; // if this ever goes negative we have our bracket
    firstCompleteSetEncountered := false;
    firstOpenCharaterEncountered := false;

    while (openBracketCount >= 0) and aCursorPosition.SearchAgain do
    begin
      aCursorPosition.MoveRelative(0, -1);

      if aCursorPosition.Character = aOpenCharacter then
      begin
        if not firstOpenCharaterEncountered then
        begin
          fromPos.Col := aCursorPosition.Column + 1;
          fromPos.Line := aCursorPosition.Row;
          firstOpenCharaterEncountered := true;
        end;

        inc(openBracketCount);
      end
      else
        dec(openBracketCount);

      if (openBracketCount = 0) and (not firstCompleteSetEncountered) then
      begin
        toPos.Col := aCursorPosition.Column;
        toPos.Line := aCursorPosition.Row;
        firstCompleteSetEncountered := true;
      end;

      aCursorPosition.MoveRelative(0, 1);

      if aOpenCharacter = aCloseCharacter then
        break;
    end;

    // we have an open bracket
    if (openBracketCount < 0) or (aOpenCharacter = aCloseCharacter) then
    begin
      toPos.Col := aCursorPosition.Column - 1;
      toPos.Line := aCursorPosition.Row;

      aCursorPosition.Restore;
      aCursorPosition.Save;
      aCursorPosition.SearchOptions.Direction := sdBackward;
      openBracketCount := 0;

      while (openBracketCount >= 0) and aCursorPosition.SearchAgain do
      begin
        if aCursorPosition.Character = aCloseCharacter then
          inc(openBracketCount)
        else
          dec(openBracketCount);

        if (openBracketCount < 0) or (aOpenCharacter = aCloseCharacter) then
        begin
          fromPos.Col := aCursorPosition.Column + 1;
          fromPos.Line := aCursorPosition.Row;
        end;

        if aOpenCharacter = aCloseCharacter then
          break;
      end;
    end;

    aCursorPosition.Move(fromPos.Line, fromPos.Col - IfThen(FIaType = itAround, 1, 0));
    result := aBuffer.EditBlock;
    result.Reset;
    result.BeginBlock;
    result.Extend(toPos.Line, toPos.Col + IfThen(FIaType = itAround, 1, 0));
    result.EndBlock;
    aBuffer.TopView.MoveViewToCursor;
  finally
    aCursorPosition.SearchOptions.RegularExpression := False;
  end;
end;

{ TIAMotionParenthesis }

// change name to TryGetSelection, so we can abort if no result
function TIAMotionParenthesis.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '(', ')');
end;

{ TIAMotionSquareBracket }

function TIAMotionSquareBracket.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '[', ']');
end;

{ TIAMotionBraces }

function TIAMotionBraces.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '{', '}');
end;

{ TIAMotionAngleBracket }

function TIAMotionAngleBracket.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '<', '>');
end;

{ TIAMotionParagraph }

function TIAMotionParagraph.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin

end;

{ TIAMotionSingleQuote }

function TIAMotionSingleQuote.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '''', '''');
end;

{ TIAMotionDoubleQuote }

function TIAMotionDoubleQuote.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '"', '"');
end;

{ TIAMotionTick }

function TIAMotionTick.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '`', '`');
end;

{ TIAMotionBlocks }

function TIAMotionBlocks.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin

end;

{ TIAMotionTag }

function TIAMotionTag.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
//  result := InsideGetSelection(aCursorPosition, '>', '<');
end;

{ TIAMotionWord }

function TIAMotionWord.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin

end;

end.
