unit Commands.TextObjects.InnerAround;

interface

uses
  Commands.Base,
  ToolsAPI,
  Clipboard;

type
  TInnerAroundType = (itInner, itAround);

  TInnerAroundC = class(TViCommand)
  protected
    FIAType: TInnerAroundType;
    function InnerGetSelection(aCursorPosition: IOTAEditPosition; const aOpenCharacter, aCloseCharacter: Char): IOTAEditBlock;
  public
    constructor Create(aClipboard: TClipboard; viEngineToRemove: IViEngine; aIAType: TInnerAroundType); reintroduce; virtual;
  end;

  TInnerAroundCClass = class of TInnerAroundC;

  IInnerAroundMotion = interface
  ['{134E4567-CB25-40F2-8067-8C83CBA6F55C}']
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // Clever enough to find the next pair if outside
  TIAParenthesis = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIASquareBracket = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIABraces = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIAAngleBracket = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // Has to be in between open and close chars
  TIASingleQuote = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIADoubleQuote = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TIATick = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // use regular motion
  TIAParagraph = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // use regular motion
  TIAWord = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // ?
  TIABlocks = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  // ?
  TIATag = class(TInnerAroundC, IInnerAroundMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;


implementation

uses
  NavUtils,
  SysUtils,
  StrUtils,
  Math;

{ TInnerAroundC }

constructor TInnerAroundC.Create(aClipboard: TClipboard; viEngineToRemove: IViEngine; aIAType: TInnerAroundType);
begin
  inherited Create(aClipboard, viEngineToRemove);
  FIAType := aIAType;
end;

function TInnerAroundC.InnerGetSelection(aCursorPosition: IOTAEditPosition; const aOpenCharacter,
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
    // todo: the following shows a flag in the logic with ( x() ), if at X, it will match the inner brackets instead of outer
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

    // will vary if inner or outer, but needs to be added back only after the search is done
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
  result := InnerGetSelection(aCursorPosition, '(', ')');
end;

{ TIASquareBracket }

function TIASquareBracket.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InnerGetSelection(aCursorPosition, '[', ']');
end;

{ TIABraces }

function TIABraces.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InnerGetSelection(aCursorPosition, '{', '}');
end;

{ TIAAngleBracket }

function TIAAngleBracket.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InnerGetSelection(aCursorPosition, '<', '>');
end;

{ TIAParagraph }

function TIAParagraph.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin

end;

{ TIASingleQuote }

function TIASingleQuote.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InnerGetSelection(aCursorPosition, '''', '''');
end;

{ TIADoubleQuote }

function TIADoubleQuote.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InnerGetSelection(aCursorPosition, '"', '"');
end;

{ TIATick }

function TIATick.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
  result := InnerGetSelection(aCursorPosition, '`', '`');
end;

{ TIABlocks }

function TIABlocks.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin

end;

{ TIATag }

function TIATag.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin
//  result := InnerGetSelection(aCursorPosition, '>', '<');
end;

{ TIAWord }

function TIAWord.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
begin

end;

end.
