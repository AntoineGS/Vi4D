unit Commands.TextObjects.InsideAround;

interface

uses
  Commands.Base,
  ToolsAPI,
  Clipboard;

type
  TInsideAroundType = (itInside, itAround);

  TInsideAroundC = class(TViCommand)
  protected
    FIAType: TInsideAroundType;
    function InsideGetSelection(aCursorPosition: IOTAEditPosition; const aOpenCharacter, aCloseCharacter: Char): IOTAEditBlock;
  public
    constructor Create(aClipboard: TClipboard; viEngineToRemove: IViEngine; aIAType: TInsideAroundType); reintroduce; virtual;
  end;

  TInsideAroundCClass = class of TInsideAroundC;

  IInsideAroundMotion = interface
  ['{134E4567-CB25-40F2-8067-8C83CBA6F55C}']
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // Clever enough to find the next pair if outside
  TIAParenthesis = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIASquareBracket = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIABraces = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIAAngleBracket = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // Has to be in between open and close chars
  TIASingleQuote = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIADoubleQuote = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIATick = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // use regular motion
  TIAParagraph = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // use regular motion
  TIAWord = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // ?
  TIABlocks = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // ?
  TIATag = class(TInsideAroundC, IInsideAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;


implementation

uses
  NavUtils,
  SysUtils,
  StrUtils,
  Math;

{ TInsideAroundC }

constructor TInsideAroundC.Create(aClipboard: TClipboard; viEngineToRemove: IViEngine; aIAType: TInsideAroundType);
begin
  inherited Create(aClipboard, viEngineToRemove);
  FIAType := aIAType;
end;

function TInsideAroundC.InsideGetSelection(aCursorPosition: IOTAEditPosition; const aOpenCharacter,
  aCloseCharacter: Char): IOTAEditBlock;
var
  aBuffer: IOTAEditBuffer;
  fromPos,
  toPos: TOTAEditPos;
  openEscapeChar,
  closeEscapeChar: String;
begin
  try
  // todo: maybe a clear highlight would resolve the sticky characters
    // todo: the following shows a flag in the logic with ( x() ), if at X, it will match the Inside brackets instead of outer
    openEscapeChar := IfThen(CharInSet(aOpenCharacter, ['.', '^', '$', '*', '+', '?', '(', ')', '[', '{', '\', '|']), '\');
    closeEscapeChar := IfThen(CharInSet(aOpenCharacter, ['.', '^', '$', '*', '+', '?', '(', ')', '[', '{', '\', '|']), '\');
    aBuffer := GetEditBuffer;

    aCursorPosition.SearchOptions.SearchText :=
        Format('%s%s|%s%s', [openEscapeChar, aOpenCharacter, closeEscapeChar, aCloseCharacter]);
    aCursorPosition.SearchOptions.CaseSensitive := false;
    aCursorPosition.SearchOptions.Direction := sdForward;
    aCursorPosition.SearchOptions.FromCursor := true;
    aCursorPosition.SearchOptions.RegularExpression := True;
    aCursorPosition.SearchOptions.WholeFile := true;
    aCursorPosition.SearchOptions.WordBoundary := false;
    aCursorPosition.SearchAgain;
//    if not aCursorPosition.SearchAgain then
//      Exit(False);

    // will vary if Inside or outer, but needs to be added back only after the search is done
    aCursorPosition.MoveRelative(0, -1);

    // todo: handle character not found
    if aCursorPosition.Character = aCloseCharacter then
    begin
      toPos.Col := aCursorPosition.Column;
      toPos.Line := aCursorPosition.Row;
      aCursorPosition.SearchOptions.Direction := sdBackward;
      aCursorPosition.SearchOptions.SearchText := Format('%s%s', [openEscapeChar, aOpenCharacter]);
      aCursorPosition.SearchAgain;
      aCursorPosition.MoveRelative(0, 1);
      fromPos.Col := aCursorPosition.Column;
      fromPos.Line := aCursorPosition.Row;
    end
    else
    begin
      fromPos.Col := aCursorPosition.Column + 1;
      fromPos.Line := aCursorPosition.Row;
      aCursorPosition.SearchOptions.SearchText := Format('%s%s', [closeEscapeChar, aCloseCharacter]);
      aCursorPosition.SearchAgain;
      toPos.Col := aCursorPosition.Column - 1;
      toPos.Line := aCursorPosition.Row;
    end;

    aCursorPosition.Move(fromPos.Line, fromPos.Col - IfThen(FIaType = itAround, 1, 0));
    result := aBuffer.EditBlock;
    result.Reset;
    result.BeginBlock;
    result.Extend(toPos.Line, toPos.Col + IfThen(FIaType = itAround, 1, 0));
    result.EndBlock;
  finally
    aCursorPosition.SearchOptions.RegularExpression := False;
  end;
end;

{ TIAParenthesis }

// change name to TryGetSelection, so we can abort if no result
function TIAParenthesis.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '(', ')');
end;

{ TIASquareBracket }

function TIASquareBracket.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '[', ']');
end;

{ TIABraces }

function TIABraces.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '{', '}');
end;

{ TIAAngleBracket }

function TIAAngleBracket.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '<', '>');
end;

{ TIAParagraph }

function TIAParagraph.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin

end;

{ TIASingleQuote }

function TIASingleQuote.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '''', '''');
end;

{ TIADoubleQuote }

function TIADoubleQuote.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '"', '"');
end;

{ TIATick }

function TIATick.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InsideGetSelection(aCursorPosition, '`', '`');
end;

{ TIABlocks }

function TIABlocks.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin

end;

{ TIATag }

function TIATag.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
//  result := InsideGetSelection(aCursorPosition, '>', '<');
end;

{ TIAWord }

function TIAWord.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin

end;

end.
