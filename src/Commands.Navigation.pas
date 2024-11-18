unit Commands.Navigation;

interface

uses
  Commands.Base,
  Commands.Operators,
  ToolsAPI,
  SysUtils;

type
  IEditionMotion = interface
    ['{7E9776B7-AB0F-4F7F-BB14-6D02DAD0EBC0}']
    procedure Execute(aCursorPosition: IOTAEditPosition; aViOperatorC: TViOperatorC; aCount: integer);
  end;

  ISearchMotion = interface
    ['{D8DEFB88-FBC8-4B7C-984C-6F50E27A8213}']
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TViNavigationC = class(TViCommand)
  public
    procedure Execute(aCursorPosition: IOTAEditPosition; aViOperatorC: TViOperatorC; aCount: integer);
    function DefaultCount: integer; virtual;
  end;

  TViNavigationCClass = class of TViNavigationC;

  TViNCLeft = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCRight = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCBottomScreen = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCMiddleScreen = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCPreviousParagraphBreak = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCNextParagraphBreak = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCDown = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCUp = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCFindForward = class(TViNavigationC, INavigationMotion, ISearchMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TViNCFindBackwards = class(TViNavigationC, INavigationMotion, ISearchMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TViNCFindTilForward = class(TViNavigationC, INavigationMotion, ISearchMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TViNCFindTilBackwards = class(TViNavigationC, INavigationMotion, ISearchMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TViNCHalfPageUp = class(TViNavigationC)
  end;

  TViNCHalfPageDown = class(TViNavigationC)
  end;

  TViNCStartOfLine = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  // $
  TViNCEndOfLine = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCTrueEndOfLine = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  // _
  TViNCStartOfLineAfterWhiteSpace = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCFirstLine = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCGoToLine = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
    function DefaultCount: integer; override;
  end;

  TViNCNextMatch = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCPreviousMatch = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCNextWholeWordUnderCursor = class(TViNavigationC, INavigationMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
  end;

  TViNCPreviousWholeWordUnderCursor = class(TViNavigationC)
  end;

implementation

uses
  NavUtils,
  Commands.TextObjects,
  Math,
  Clipboard;

{ TViNCLeft }

procedure TViNCLeft.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  aCursorPosition.MoveRelative(0, -aCount);
end;

{ TViNCUp }

procedure TViNCUp.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  aCursorPosition.MoveRelative(-aCount, 0);
end;

{ TViNCDown }

procedure TViNCDown.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  aCursorPosition.MoveRelative(aCount, 0);
end;

{ TViNCRight }

procedure TViNCRight.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  aCursorPosition.MoveRelative(0, aCount);
end;

{ TViNCStartOfLine }

procedure TViNCStartOfLine.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  aCursorPosition.MoveBOL;
end;

{ TViNCEndOfLine }

procedure TViNCEndOfLine.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  aCursorPosition.MoveEOL;

  if not forEdition then
    aCursorPosition.MoveRelative(0, -1);
end;

{ TViNCStartOfLineAfterWhiteSpace }

procedure TViNCStartOfLineAfterWhiteSpace.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  aCursorPosition.MoveBOL;

  if aCursorPosition.IsWhiteSpace then
    aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight or mmSkipStream);
end;

function TViNavigationC.DefaultCount: integer;
begin
  result := 1;
end;

procedure TViNavigationC.Execute(aCursorPosition: IOTAEditPosition; aViOperatorC: TViOperatorC; aCount: integer);
var
  lPos: TOTAEditPos;
  aNormalMotion: INavigationMotion;
  fullLines: boolean;
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
    fullLines := (self.ClassType = TViNCDown) or (self.ClassType = TViNCUp);

    // if full lines we need to ensure to grab the full line on which we are + the x number in the direction given
    if fullLines then
    begin
      if self.ClassType = TViNCDown then
        aCursorPosition.MoveBOL
      else
        aCursorPosition.MoveEOL;
    end;

    lPos := GetPositionForMove(aCursorPosition, aNormalMotion, true, aCount, fullLines);
    ApplyActionToSelection(aCursorPosition, aViOperatorC.BlockAction, fullLines, lPos);
  end;
end;

{ TViNCTrueEndOfLine }

procedure TViNCTrueEndOfLine.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  aCursorPosition.MoveEOL;
end;

{ TViNCGoToLine }

function TViNCGoToLine.DefaultCount: integer;
begin
  result := 0;
end;

procedure TViNCGoToLine.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  if aCount = 0 then
    aCursorPosition.MoveEOF
  else
    aCursorPosition.GotoLine(aCount);
end;

{ TViNCFirstLine }

procedure TViNCFirstLine.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  aCursorPosition.GotoLine(1);
end;

{ TViNCFindForward }

procedure FindForward(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean; aClipboard: TClipboard;
  aViEngine: IViEngine; const searchToken: string; offsetFromResult: integer = 1);
var
  aBuffer: IOTAEditBuffer;
  LSelection: IOTAEditBlock;
  aText: string;
  aViNCTrueEndOfLine: TViNCTrueEndOfLine;
  lPos: TOTAEditPos;
  i: integer;
  foundCount: integer;
begin
  //only supporting 1 char for initial implementation
  if Length(searchToken) > 1 then
    exit;

  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to FindForward');

  if aClipboard = nil then
    Raise Exception.Create('aClipboard must be set in call to FindForward');

  if aViEngine = nil then
    Raise Exception.Create('aViEngine must be set in call to FindForward');

  aViNCTrueEndOfLine := TViNCTrueEndOfLine.Create(aClipboard, aViEngine);
  try
    lPos := GetPositionForMove(aCursorPosition, aViNCTrueEndOfLine, false);
  finally
    aViNCTrueEndOfLine.Free;
  end;

  aCursorPosition.Save;
  try
    aBuffer := GetEditBuffer;
    LSelection := aBuffer.EditBlock;
    LSelection.Reset;
    LSelection.BeginBlock;
    LSelection.Extend(lPos.Line, lPos.Col);
    aText := LSelection.Text;
    LSelection.EndBlock;
  finally
    aCursorPosition.Restore;
  end;

  foundCount := 0;

  // on my neovim version when there is a count it is multiple line, but for now this is only single line
  // skip the current character
  for i := 2 to Length(aText) do
  begin
    if aText[i] = searchToken then
    begin
      foundCount := foundCount + 1;

      if foundCount = aCount then
      begin
        aCursorPosition.MoveRelative(0, i - offsetFromResult);

        if forEdition then
          aCursorPosition.MoveRelative(0, 1);
        break;
      end;
    end;
  end;
end;

function TViNCFindForward.GetSearchToken: string;
begin
  result := FSearchToken;
end;

procedure TViNCFindForward.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  FindForward(aCursorPosition, aCount, forEdition, FClipboard, FViEngine, FSearchToken);
end;

procedure TViNCFindForward.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

{ TViNCFindTilForward }

function TViNCFindTilForward.GetSearchToken: string;
begin
  result := FSearchToken;
end;

procedure TViNCFindTilForward.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  FindForward(aCursorPosition, aCount, forEdition, FClipboard, FViEngine, FSearchToken, 2);
end;

procedure TViNCFindTilForward.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

{ TViNCFindBackwards }

procedure FindBackwards(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean;
  aClipboard: TClipboard; aViEngine: IViEngine; const searchToken: string; offsetFromResult: integer = 1);
var
  aBuffer: IOTAEditBuffer;
  LSelection: IOTAEditBlock;
  aText: string;
  lPos: TOTAEditPos;
  i: integer;
  foundCount: integer;
  aViNCStartOfLine: TViNCStartOfLine;
  relativePos: integer;
begin
  // only supporting a 1 character for now
  if Length(searchToken) > 1 then
    Exit;

  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to FindForward');

  if aClipboard = nil then
    Raise Exception.Create('aClipboard must be set in call to FindForward');

  if aViEngine = nil then
    Raise Exception.Create('aViEngine must be set in call to FindForward');

  aViNCStartOfLine := TViNCStartOfLine.Create(aClipboard, aViEngine);
  try
    lPos := GetPositionForMove(aCursorPosition, aViNCStartOfLine, false);
  finally
    aViNCStartOfLine.Free;
  end;

  aCursorPosition.Save;
  try
    aBuffer := GetEditBuffer;
    LSelection := aBuffer.EditBlock;
    LSelection.Reset;
    LSelection.BeginBlock;
    LSelection.Extend(lPos.Line, lPos.Col);
    aText := LSelection.Text;
    LSelection.EndBlock;
  finally
    aCursorPosition.Restore;
  end;

  foundCount := 0;
  relativePos := 1 - offsetFromResult;
  // on my neovim version when there is a count it is multiple line, but for now this is only single line
  for i := Length(aText) - (1 - offsetFromResult) downto 1 do
  begin
    if aText[i] = searchToken then
    begin
      foundCount := foundCount +  1;

      if foundCount = aCount then
      begin
        aCursorPosition.MoveRelative(0, -relativePos - offsetFromResult);
        break;
      end;
    end;

    relativePos := relativePos + 1;
  end;
end;

function TViNCFindBackwards.GetSearchToken: string;
begin
  result := FSearchToken;
end;

procedure TViNCFindBackwards.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  FindBackwards(aCursorPosition, aCount, forEdition, FClipboard, FViEngine, FSearchToken);
end;

procedure TViNCFindBackwards.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

{ TViNCFindTilBackwards }

function TViNCFindTilBackwards.GetSearchToken: string;
begin
  result := FSearchToken;
end;

procedure TViNCFindTilBackwards.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');

  FindBackwards(aCursorPosition, aCount, forEdition, FClipboard, FViEngine, FSearchToken, 0);
end;

procedure TViNCFindTilBackwards.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

{ TViNCBottomScreen }

procedure TViNCBottomScreen.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  aBuffer: IOTAEditBuffer;
begin
  aBuffer := GetEditBuffer;
  aCursorPosition.Move(aBuffer.TopView.BottomRow - aCount, 0);
end;

{ TViNCMiddleScreen }

procedure TViNCMiddleScreen.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  aBuffer: IOTAEditBuffer;
  TopView: IOTAEditView;
begin
  aBuffer := GetEditBuffer;
  TopView := aBuffer.TopView;
  aCursorPosition.Move(TopView.TopRow + Trunc(((TopView.BottomRow - 1) - TopView.TopRow) / 2), 0);
end;

{ TViNCNextWholeWordUnderCursor }

procedure TViNCNextWholeWordUnderCursor.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  LSelection: IOTAEditBlock;
  lPos: TOTAEditPos;
  i: integer;
  aBuffer: IOTAEditBuffer;
  aViTOCEndOfWord: TViTOCEndOfWord;
begin
  aBuffer := GetEditBuffer;

  if aCursorPosition.IsWordCharacter then
    aCursorPosition.MoveCursor(mmSkipWord or mmSkipLeft)
  else
    aCursorPosition.MoveCursor(mmSkipNonWord or mmSkipRight or mmSkipStream);

  aViTOCEndOfWord := TViTOCEndOfWord.Create(FClipboard, FViEngine);
  try
    lPos := GetPositionForMove(aCursorPosition, aViTOCEndOfWord, false);
  finally
    aViTOCEndOfWord.Free;
  end;

  LSelection := aBuffer.EditBlock;
  LSelection.Reset;
  LSelection.BeginBlock;
  LSelection.Extend(lPos.Line, lPos.Col + 1);
  aCursorPosition.SearchOptions.SearchText := LSelection.Text;
  LSelection.EndBlock;

  // Move to one position after what we're searching for.
  aCursorPosition.Move(lPos.Line, lPos.Col + 1);

  aCursorPosition.SearchOptions.CaseSensitive := false;
  aCursorPosition.SearchOptions.Direction := sdForward;
  aCursorPosition.SearchOptions.FromCursor := true;
  aCursorPosition.SearchOptions.RegularExpression := false;
  aCursorPosition.SearchOptions.WholeFile := true;
  aCursorPosition.SearchOptions.WordBoundary := true;

  for i := 1 to aCount do
    aCursorPosition.SearchAgain;

  // Move back to the start of the text we searched for.
  aCursorPosition.MoveRelative(0, -Length(aCursorPosition.SearchOptions.SearchText));

  aBuffer.TopView.MoveViewToCursor;
{$MESSAGE 'Find defaults and finally them back for the Search Options'}
end;

{ TViNCNextMatch }

procedure TViNCNextMatch.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  LSelection: IOTAEditBlock;
  i: integer;
  aBuffer: IOTAEditBuffer;
begin
  aBuffer := GetEditBuffer;
  LSelection := aBuffer.EditBlock;
  LSelection.Reset;
  LSelection.BeginBlock;
  LSelection.ExtendRelative(0, Length(aCursorPosition.SearchOptions.SearchText));

  if AnsiSameText(aCursorPosition.SearchOptions.SearchText, LSelection.Text) then
    aCursorPosition.MoveRelative(0, 1);

  LSelection.EndBlock;

  aCursorPosition.SearchOptions.Direction := sdForward;

  for i := 1 to aCount do
    aCursorPosition.SearchAgain;

  aCursorPosition.MoveRelative(0, -Length(aCursorPosition.SearchOptions.SearchText));
end;

{ TViNCPreviousMatch }

procedure TViNCPreviousMatch.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  LSelection: IOTAEditBlock;
  i: integer;
  aBuffer: IOTAEditBuffer;
begin
  aBuffer := GetEditBuffer;
  LSelection := aBuffer.EditBlock;
  LSelection.Reset;
  LSelection.BeginBlock;
  LSelection.ExtendRelative(0, Length(aCursorPosition.SearchOptions.SearchText));

  if AnsiSameText(aCursorPosition.SearchOptions.SearchText, LSelection.Text) then
    aCursorPosition.MoveRelative(0, -1);

  LSelection.EndBlock;

  aCursorPosition.SearchOptions.Direction := sdBackward;

  for i := 1 to aCount do
    aCursorPosition.SearchAgain;
end;

{ TViNCPreviousParagraphBreak }

procedure TViNCPreviousParagraphBreak.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: integer;
  row: integer;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to MoveToParagraphBreak');

  try
    aCursorPosition.SearchOptions.RegularExpression := true;
    aCursorPosition.SearchOptions.SearchText := '/(^(\r\n|\n|\r)$)|(^(\r\n|\n|\r))|^\s*$';
    aCursorPosition.SearchOptions.Direction := sdBackward;
    row := aCursorPosition.row;

    for i := 1 to aCount do
    begin
      if i > 1 then
        aCursorPosition.MoveRelative(-1, 0);

      aCursorPosition.SearchAgain;

      // this handles the case where we start on a paragraph break
      if (i = 1) and (row = aCursorPosition.row) then
      begin
        aCursorPosition.MoveRelative(-1, 0);
        aCursorPosition.SearchAgain;
      end
    end;
  finally
    aCursorPosition.SearchOptions.RegularExpression := false;
  end;
end;

{ TViNCNextParagraphBreak }

procedure TViNCNextParagraphBreak.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: integer;
  row: integer;
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to MoveToParagraphBreak');

  try
    aCursorPosition.SearchOptions.RegularExpression := true;
    aCursorPosition.SearchOptions.SearchText := '/(^(\r\n|\n|\r)$)|(^(\r\n|\n|\r))|^\s*$';
    aCursorPosition.SearchOptions.Direction := sdForward;
    row := aCursorPosition.row;

    for i := 1 to aCount do
    begin
      if i > 1 then
        aCursorPosition.MoveRelative(1, 0);

      aCursorPosition.SearchAgain;

      // this handles the case where we start on a paragraph break
      if (i = 1) and (row = aCursorPosition.row - 1) then
      begin
        aCursorPosition.MoveRelative(1, 0);
        aCursorPosition.SearchAgain;
      end
    end;

    aCursorPosition.MoveRelative(-1, 0);
  finally
    aCursorPosition.SearchOptions.RegularExpression := false;
  end;
end;

end.
