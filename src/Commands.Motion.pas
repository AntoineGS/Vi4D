unit Commands.Motion;

interface

uses
  Commands.Base,
  Commands.Operators,
  ToolsAPI,
  SysUtils,
  Generics.Collections,
  Commands.IAMotion;

type
  IExecuteMotion = interface
    ['{7E9776B7-AB0F-4F7F-BB14-6D02DAD0EBC0}']
    procedure Execute(aCursorPosition: IOTAEditPosition; aOperator: TOperator; aCount: integer);
    function DefaultCount: integer;
  end;

  ISearchMotion = interface
    ['{D8DEFB88-FBC8-4B7C-984C-6F50E27A8213}']
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TMotion = class(TCommand)
  public
    procedure Execute(aCursorPosition: IOTAEditPosition; aOperator: TOperator; aCount: integer);
    function DefaultCount: integer; virtual;
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); virtual;
  end;

  TMotionClass = class of TMotion;

  TMotionLeft = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionRight = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionBottomScreen = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionMiddleScreen = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionPreviousParagraphBreak = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionNextParagraphBreak = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionDown = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionUp = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionMoveUpScreen = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionMoveDownScreen = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionCenterScreen = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionFindForward = class(TMotion, IMoveMotion, ISearchMotion, IExecuteMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TMotionFindBackwards = class(TMotion, IMoveMotion, ISearchMotion, IExecuteMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TMotionFindTilForward = class(TMotion, IMoveMotion, ISearchMotion, IExecuteMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TMotionFindTilBackwards = class(TMotion, IMoveMotion, ISearchMotion, IExecuteMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

//  TMotionHalfPageUp = class(TMotion)
//  end;
//
//  TMotionHalfPageDown = class(TMotion)
//  end;

  TMotionBOL = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  // $
  TMotionEOL = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionTrueEOL = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  // _
  TMotionBOLAfterWhiteSpace = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionFirstLine = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionGoToLine = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
    function DefaultCount: integer; override;
  end;

  TMotionNextMatch = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionPreviousMatch = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionNextWholeWordUnderCursor = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionPreviousWholeWordUnderCursor = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

//  TMotionParagraph = class(TViNavigationC)
//  end;

  TMotionWord = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionWordCharacter = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionWordBack = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionWordCharacterBack = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionEndOfWordCharacter = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionEndOfWord = class(TMotion, IMoveMotion, IExecuteMotion)
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
  end;

  TMotionInsideAround = class(TMotion, ISearchMotion, IExecuteMotion)
  private
    FSearchToken: string;
  protected
    class var
      FIAMotionKeyBindings: TDictionary<string, TIAMotionClass>;
    class procedure FillBindings;
  public
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
    function DefaultCount: integer; override;
  end;

  // these will delegate the Move to their sub command
  TMotionInside = class(TMotionInsideAround, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TMotionAround = class(TMotionInsideAround, IIAMotion)
    function GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
  end;

  TMotionGoToMarkLine = class(TMotion, IMoveMotion, ISearchMotion, IExecuteMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

  TMotionGoToMarkExact = class(TMotion, IMoveMotion, ISearchMotion, IExecuteMotion)
  private
    FSearchToken: string;
  public
    procedure Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean); override;
    function GetSearchToken: string;
    procedure SetSearchToken(const aValue: string);
    property SearchToken: string read GetSearchToken write SetSearchToken;
  end;

implementation

uses
  NavUtils,
  Math,
  Clipboard;

{ TMotionLeft }

procedure TMotionLeft.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;
  aCursorPosition.MoveRelative(0, -aCount);
end;

{ TMotionUp }

procedure TMotionUp.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;
  aCursorPosition.MoveRelative(-aCount, 0);
end;

{ TMotionDown }

procedure TMotionDown.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;
  aCursorPosition.MoveRelative(aCount, 0);
end;

{ TMotionRight }

procedure TMotionRight.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  aBuffer := GetEditBuffer;

//  if FEngine.CurrentViMode = mVisual then
//    aBuffer.EditBlock.ExtendRelative(0, aCount)
//  else
    aCursorPosition.MoveRelative(0, aCount);
end;

{ TMotionStartOfLine }

procedure TMotionBOL.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  inherited;

  // count of 1 is considered the same line
  for i := 2 to aCount do
    aCursorPosition.MoveRelative(1, 0);

  aCursorPosition.MoveBOL;
end;

{ TMotionEndOfLine }

procedure TMotionEOL.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  aMotionTrueEOL: TMotionTrueEOL;
begin
  inherited;

  aMotionTrueEOL := TMotionTrueEOL.Create(FClipboard, FEngine);
  try
    aMotionTrueEOL.Move(aCursorPosition, aCount, forEdition);
  finally
    aMotionTrueEOL.Free;
  end;

  if not forEdition then
    aCursorPosition.MoveRelative(0, -1);
end;

{ TMotionStartOfLineAfterWhiteSpace }

procedure TMotionBOLAfterWhiteSpace.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  aMotionBOL: TMotionBOL;
begin
  inherited;

  aMotionBOL := TMotionBOL.Create(FClipboard, FEngine);
  try
    aMotionBOL.Move(aCursorPosition, aCount, forEdition);
  finally
    aMotionBOL.Free;
  end;

  if aCursorPosition.IsWhiteSpace then
    aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);
end;

function TMotion.DefaultCount: integer;
begin
  result := 1;
end;

procedure TMotion.Execute(aCursorPosition: IOTAEditPosition; aOperator: TOperator; aCount: integer);
var
  lPos: TOTAEditPos;
  aNormalMotion: IMoveMotion;
  fullLines: boolean;
  aIAMotion: IIAMotion;
  LSelection: IOTAEditBlock;
  isVisualMode: boolean;
  aBuffer: IOTAEditBuffer;
begin
  inherited;

  isVisualMode := FEngine.CurrentViMode in [mVisual, mVisualLine, mVisualBlock];

  if Supports(self, IMoveMotion, aNormalMotion) then
  begin
    if aOperator = nil then
    begin
      lPos := GetPositionForMove(aCursorPosition, aNormalMotion, false, aCount);

      if isVisualMode then
      begin
        aBuffer := GetEditBuffer;
        LSelection := aBuffer.EditBlock;

        if FEngine.CurrentViMode = mVisualLine then
        begin
          // Visual Line mode: extend to target line (style already set to btLine)
          LSelection.Extend(lPos.Line, lPos.Col);
        end
        else if FEngine.CurrentViMode = mVisualBlock then
        begin
          // Visual Block mode: extend to target position (style already set to btColumn)
          LSelection.Extend(lPos.Line, lPos.Col);
        end
        else
        begin
          // Regular visual mode
          LSelection.Extend(lPos.Line, lPos.Col);
        end;
      end
      else
        aCursorPosition.Move(lPos.Line, lPos.Col);
    end
    else
    begin
      fullLines := (not isVisualMode) and ((self.ClassType = TMotionDown) or (self.ClassType = TMotionUp));

      // Visual Line mode operations are always full line
      if FEngine.CurrentViMode = mVisualLine then
        fullLines := True;

      // if full lines we need to ensure to grab the full line on which we are + the x number in the direction given
      if fullLines then
      begin
        if self.ClassType = TMotionDown then
          aCursorPosition.MoveBOL
        else
          aCursorPosition.MoveEOL;
      end;

      lPos := GetPositionForMove(aCursorPosition, aNormalMotion, not isVisualMode, aCount, fullLines);
      ApplyActionToSelection(aCursorPosition, aOperator.BlockAction, fullLines, lPos);
    end;
  end
  else if Supports(self, IIAMotion, aIAMotion) then
  begin
    LSelection := aIAMotion.GetSelection(aCursorPosition);
    ApplyActionToSelection(aCursorPosition, aOperator.BlockAction, false, LSelection);
    aCursorPosition.SearchOptions.SearchText := '';
    aCursorPosition.SearchAgain;
  end;
end;

procedure TMotion.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to Move');
end;

{ TMotionTrueEndOfLine }

procedure TMotionTrueEOL.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  inherited;

  // count of 1 is considered the same line
  for i := 2 to aCount do
    aCursorPosition.MoveRelative(1, 0);

  aCursorPosition.MoveEOL;
end;

{ TMotionGoToLine }

function TMotionGoToLine.DefaultCount: integer;
begin
  result := 0;
end;

procedure TMotionGoToLine.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;

  if aCount = 0 then
    aCursorPosition.MoveEOF
  else
    aCursorPosition.GotoLine(aCount);
end;

{ TMotionFirstLine }

procedure TMotionFirstLine.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;
  aCursorPosition.GotoLine(1);
end;

{ TMotionFindForward }

procedure FindForward(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean; aClipboard: TClipboard;
  aEngine: IEngine; const searchToken: string; offsetFromResult: integer = 1);
var
  aBuffer: IOTAEditBuffer;
  LSelection: IOTAEditBlock;
  aText: string;
  aMotionTrueEOL: TMotionTrueEOL;
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

  if aEngine = nil then
    Raise Exception.Create('aEngine must be set in call to FindForward');

  aMotionTrueEOL := TMotionTrueEOL.Create(aClipboard, aEngine);
  try
    lPos := GetPositionForMove(aCursorPosition, aMotionTrueEOL, false);
  finally
    aMotionTrueEOL.Free;
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

function TMotionFindForward.GetSearchToken: string;
begin
  result := FSearchToken;
end;

procedure TMotionFindForward.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;

  FindForward(aCursorPosition, aCount, forEdition, FClipboard, FEngine, FSearchToken);
end;

procedure TMotionFindForward.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

{ TMotionFindTilForward }

function TMotionFindTilForward.GetSearchToken: string;
begin
  result := FSearchToken;
end;

procedure TMotionFindTilForward.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;
  FindForward(aCursorPosition, aCount, forEdition, FClipboard, FEngine, FSearchToken, 2);
end;

procedure TMotionFindTilForward.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

{ TMotionFindBackwards }

procedure FindBackwards(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean;
  aClipboard: TClipboard; aEngine: IEngine; const searchToken: string; offsetFromResult: integer = 1);
var
  aBuffer: IOTAEditBuffer;
  LSelection: IOTAEditBlock;
  aText: string;
  lPos: TOTAEditPos;
  i: integer;
  foundCount: integer;
  aMotionBOL: TMotionBOL;
  relativePos: integer;
  col: Integer;
begin
  // only supporting a 1 character for now
  if Length(searchToken) > 1 then
    Exit;

  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set in call to FindForward');

  if aClipboard = nil then
    Raise Exception.Create('aClipboard must be set in call to FindForward');

  if aEngine = nil then
    Raise Exception.Create('aEngine must be set in call to FindForward');

  // handle case where the cursor is past the EOL, as is common in IDE
  col := aCursorPosition.Column;
  aCursorPosition.MoveEOL;

  if col < aCursorPosition.Column then
    aCursorPosition.Move(0, col);

  aMotionBOL := TMotionBOL.Create(aClipboard, aEngine);
  try
    lPos := GetPositionForMove(aCursorPosition, aMotionBOL, false);
  finally
    aMotionBOL.Free;
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

function TMotionFindBackwards.GetSearchToken: string;
begin
  result := FSearchToken;
end;

procedure TMotionFindBackwards.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;
  FindBackwards(aCursorPosition, aCount, forEdition, FClipboard, FEngine, FSearchToken);
end;

procedure TMotionFindBackwards.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

{ TMotionFindTilBackwards }

function TMotionFindTilBackwards.GetSearchToken: string;
begin
  result := FSearchToken;
end;

procedure TMotionFindTilBackwards.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;
  FindBackwards(aCursorPosition, aCount, forEdition, FClipboard, FEngine, FSearchToken, 0);
end;

procedure TMotionFindTilBackwards.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

{ TMotionBottomScreen }

procedure TMotionBottomScreen.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  aBuffer := GetEditBuffer;
  aCursorPosition.Move(aBuffer.TopView.BottomRow - aCount, 0);
end;

{ TMotionMiddleScreen }

procedure TMotionMiddleScreen.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  aBuffer: IOTAEditBuffer;
  TopView: IOTAEditView;
begin
  inherited;
  aBuffer := GetEditBuffer;
  TopView := aBuffer.TopView;
  aCursorPosition.Move(TopView.TopRow + Trunc(((TopView.BottomRow - 1) - TopView.TopRow) / 2), 0);
end;

{ TMotionNextWholeWordUnderCursor }

procedure TMotionNextWholeWordUnderCursor.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  LSelection: IOTAEditBlock;
  lPos: TOTAEditPos;
  i: integer;
  aBuffer: IOTAEditBuffer;
  aMotionEndOfWord: TMotionEndOfWord;
begin
  inherited;
  aBuffer := GetEditBuffer;

  if aCursorPosition.IsWordCharacter then
    aCursorPosition.MoveCursor(mmSkipWord or mmSkipLeft)
  else
    aCursorPosition.MoveCursor(mmSkipNonWord or mmSkipRight);

  aMotionEndOfWord := TMotionEndOfWord.Create(FClipboard, FEngine);
  try
    lPos := GetPositionForMove(aCursorPosition, aMotionEndOfWord, false);
  finally
    aMotionEndOfWord.Free;
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

{ TMotionNextMatch }

procedure TMotionNextMatch.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  LSelection: IOTAEditBlock;
  i: integer;
  aBuffer: IOTAEditBuffer;
begin
  inherited;
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
  begin
    if not aCursorPosition.SearchAgain then
    begin
      // Wrap to beginning of file and try again
      aCursorPosition.Move(1, 1);
      aCursorPosition.SearchAgain;
    end;
  end;

  aCursorPosition.MoveRelative(0, -Length(aCursorPosition.SearchOptions.SearchText));
end;

{ TMotionPreviousMatch }

procedure TMotionPreviousMatch.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  LSelection: IOTAEditBlock;
  i: integer;
  aBuffer: IOTAEditBuffer;
begin
  inherited;
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
  begin
    if not aCursorPosition.SearchAgain then
    begin
      // Wrap to end of file and try again
      aCursorPosition.MoveEOF;
      aCursorPosition.SearchAgain;
    end;
  end;
end;

{ TMotionPreviousParagraphBreak }

procedure TMotionPreviousParagraphBreak.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: integer;
  row: integer;
begin
  inherited;

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

{ TMotionNextParagraphBreak }

procedure TMotionNextParagraphBreak.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: integer;
  row: integer;
begin
  inherited;

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

{ TMotionWord }

procedure TMotionWord.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  inherited;

  for i := 1 to ACount do
  begin
    if aCursorPosition.IsWordCharacter then
      aCursorPosition.MoveCursor(mmSkipWord or mmSkipRight) // Skip to first non word character.
    else if aCursorPosition.IsSpecialCharacter then
      aCursorPosition.MoveCursor(mmSkipSpecial or mmSkipRight or mmSkipStream)
    else if aCursorPosition.IsWhiteSpace then
    aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);
    // Skip to the first non special character
    // If the character is whitespace or EOL then skip that whitespace
    if (not forEdition) and (aCursorPosition.IsWhiteSpace or (aCursorPosition.Character = #$D)) then
      aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight or mmSkipStream);
  end;
end;

{ TMotionWordBack }

procedure TMotionWordBack.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
  LNextChar: TCharClass;
begin
  inherited;

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

{ TMotionWordCharacter }

procedure TMotionWordCharacter.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  inherited;

  for i := 1 to ACount do
  begin
    // Goto first white space after the end of the word.
    aCursorPosition.MoveCursor(mmSkipNonWhite or mmSkipRight);
    // Now skip all the white space until we're at the start of a word again.
    aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight or mmSkipStream);
  end;
end;

{ TMotionWordCharacterBack }

procedure TMotionWordCharacterBack.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  inherited;

  for i := 1 to ACount do
  begin
    aCursorPosition.MoveCursor(mmSkipWhite or mmSkipLeft or mmSkipStream);
    aCursorPosition.MoveCursor(mmSkipNonWhite or mmSkipLeft);
  end;
end;

{ TMotionEndOfWordCharacter }

procedure TMotionEndOfWordCharacter.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  inherited;

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

{ TMotionEndOfWord }

procedure TMotionEndOfWord.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  i: Integer;
begin
  inherited;

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

{ TMotionInsideAround }

function TMotionInsideAround.GetSearchToken: string;
begin
  result := FSearchToken;
end;

procedure TMotionInsideAround.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

{ TMotionInside }

function TMotionInside.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock; // these can AV if nothing is found, gotta fix that   dd
var
  aIAMotionClass: TIAMotionClass;
  aIAMotion: TIAMotion;
  aBuffer: IOTAEditBuffer;
  aIIAMotion: IIAMotion;
begin
  aBuffer := GetEditBuffer;

  if FIAMotionKeyBindings.TryGetValue(FSearchToken, aIAMotionClass) then
  begin
    aIAMotion := aIAMotionClass.Create(FClipboard, FEngine, itInside);

    if Supports(aIAMotion, IIAMotion, aIIAMotion) then
    begin
      result := aIIAMotion.GetSelection(aCursorPosition);
      aBuffer.TopView.MoveViewToCursor;
    end;
  end;
end;

{ TMotionAround }

function TMotionAround.GetSelection(aCursorPosition: IOTAEditPosition): IOTAEditBlock;
var
  aIAMotionClass: TIAMotionClass;
  aIAMotion: TIAMotion;
  aBuffer: IOTAEditBuffer;
  aIIAMotion: IIAMotion;
begin
  aBuffer := GetEditBuffer;

  if FIAMotionKeyBindings.TryGetValue(FSearchToken, aIAMotionClass) then
  begin
    aIAMotion := aIAMotionClass.Create(FClipboard, FEngine, itAround);

    if Supports(aIAMotion, IIAMotion, aIIAMotion) then
    begin
      result := aIIAMotion.GetSelection(aCursorPosition);
      aBuffer.TopView.MoveViewToCursor;
    end;
  end;
end;

{ TMotionInsideAround }

function TMotionInsideAround.DefaultCount: integer;
begin
  result := 0;
end;

class procedure TMotionInsideAround.FillBindings;
begin
  FIAMotionKeyBindings.Add('(', TIAMotionParenthesis);
  FIAMotionKeyBindings.Add(')', TIAMotionParenthesis);
  FIAMotionKeyBindings.Add('p', TIAMotionParagraph);
  FIAMotionKeyBindings.Add('[', TIAMotionSquareBracket);
  FIAMotionKeyBindings.Add(']', TIAMotionSquareBracket);
  FIAMotionKeyBindings.Add('{', TIAMotionBraces);
  FIAMotionKeyBindings.Add('}', TIAMotionBraces);
  FIAMotionKeyBindings.Add('<', TIAMotionAngleBracket);
  FIAMotionKeyBindings.Add('>', TIAMotionAngleBracket);
  FIAMotionKeyBindings.Add('''', TIAMotionSingleQuote);
  FIAMotionKeyBindings.Add('"', TIAMotionDoubleQuote);
  FIAMotionKeyBindings.Add('`', TIAMotionTick);
  FIAMotionKeyBindings.Add('B', TIAMotionBlocks); // [{]}
//  FViIAKeyBindings.Add('b', TIAMotionBlocks); // [(])
  FIAMotionKeyBindings.Add('t', TIAMotionTag);
  FIAMotionKeyBindings.Add('w', TIAMotionWord);
//  FViIAKeyBindings.Add('W', TIAWord);
// missing s (sentence)
end;

{ TMotionPreviousWholeWordUnderCursor }

procedure TMotionPreviousWholeWordUnderCursor.Move(aCursorPosition: IOTAEditPosition; aCount: integer;
  forEdition: boolean);
 var
  LSelection: IOTAEditBlock;
  lPos: TOTAEditPos;
  i: integer;
  aBuffer: IOTAEditBuffer;
  aMotionEndOfWord: TMotionEndOfWord;
begin
  inherited;
  aBuffer := GetEditBuffer;

  if not aCursorPosition.IsWordCharacter then
    aCursorPosition.MoveCursor(mmSkipNonWord or mmSkipLeft);

  aCursorPosition.MoveCursor(mmSkipWord or mmSkipLeft);

  aMotionEndOfWord := TMotionEndOfWord.Create(FClipboard, FEngine);
  try
    lPos := GetPositionForMove(aCursorPosition, aMotionEndOfWord, false);
  finally
    aMotionEndOfWord.Free;
  end;

  LSelection := aBuffer.EditBlock;
  LSelection.Reset;
  LSelection.BeginBlock;
  LSelection.Extend(lPos.Line, lPos.Col + 1);
  aCursorPosition.SearchOptions.SearchText := LSelection.Text;
  LSelection.EndBlock;

  aCursorPosition.Move(lPos.Line, lPos.Col);

  aCursorPosition.SearchOptions.CaseSensitive := false;
  aCursorPosition.SearchOptions.Direction := sdBackward;
  aCursorPosition.SearchOptions.FromCursor := true;
  aCursorPosition.SearchOptions.RegularExpression := false;
  aCursorPosition.SearchOptions.WholeFile := true;
  aCursorPosition.SearchOptions.WordBoundary := true;

  for i := 1 to aCount do
    aCursorPosition.SearchAgain;

  aBuffer.TopView.MoveViewToCursor;
end;

procedure MoveScreen(aCursorPosition: IOTAEditPosition; aCount: integer; isDown: boolean);
var
  aBuffer: IOTAEditBuffer;
  halfScreen: integer;
  lEditPos: TOTAEditPos;
begin
  aBuffer := GetEditBuffer;

  if aCount <> 1 then
    halfScreen := -aCount
  else
  begin
    if aBuffer.TopView = nil then
      Exit;

    halfScreen := Round((aBuffer.TopView.TopRow - aBuffer.TopView.BottomRow) / 2);
  end;

  if isDown then
    halfScreen := -halfScreen;

  lEditPos.Line := aCursorPosition.Row + halfScreen;
  lEditPos.Col := aCursorPosition.Column;
  aBuffer.TopView.SetCursorPos(lEditPos);
  aBuffer.TopView.Center(aCursorPosition.Row, aCursorPosition.Column);
end;

{ TMotionMoveDownScreen }

procedure TMotionMoveDownScreen.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;
  MoveScreen(aCursorPosition, aCount, True);
end;

{ TMotionMoveUpScreen }

procedure TMotionMoveUpScreen.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
begin
  inherited;
  MoveScreen(aCursorPosition, aCount, False);
end;

{ TMotionCenterScreen }

procedure TMotionCenterScreen.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  aBuffer: IOTAEditBuffer;
begin
  aBuffer := GetEditBuffer;

  if aBuffer.TopView = nil then
    Exit;

  aBuffer.TopView.Center(aCursorPosition.Row, aCursorPosition.Column);
end;

{ TMotionGoToMarkLine }

function TMotionGoToMarkLine.GetSearchToken: string;
begin
  Result := FSearchToken;
end;

procedure TMotionGoToMarkLine.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

procedure TMotionGoToMarkLine.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  mark: TMark;
  markIndex: Integer;
  aBuffer: IOTAEditBuffer;
  moduleServices: IOTAModuleServices;
begin
  inherited;

  if Length(FSearchToken) = 0 then
    Exit;

  markIndex := Ord(FSearchToken[1]);
  mark := FEngine.GetMark(markIndex);

  if not mark.IsSet then
    Exit;

  aBuffer := GetEditBuffer;
  if aBuffer = nil then
    Exit;

  // Open file if different
  if not SameFileName(aBuffer.FileName, mark.FileName) then
  begin
    QuerySvcs(BorlandIDEServices, IOTAModuleServices, moduleServices);
    if moduleServices <> nil then
      moduleServices.OpenModule(mark.FileName);
    aBuffer := GetEditBuffer;
    if aBuffer = nil then
      Exit;
    aCursorPosition := GetEditPosition(aBuffer);
    if aCursorPosition = nil then
      Exit;
  end;

  // Move to line, first non-blank
  aCursorPosition.GotoLine(mark.Line);
  aCursorPosition.MoveBOL;
  if aCursorPosition.IsWhiteSpace then
    aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);
end;

{ TMotionGoToMarkExact }

function TMotionGoToMarkExact.GetSearchToken: string;
begin
  Result := FSearchToken;
end;

procedure TMotionGoToMarkExact.SetSearchToken(const aValue: string);
begin
  FSearchToken := aValue;
end;

procedure TMotionGoToMarkExact.Move(aCursorPosition: IOTAEditPosition; aCount: integer; forEdition: boolean);
var
  mark: TMark;
  markIndex: Integer;
  aBuffer: IOTAEditBuffer;
  moduleServices: IOTAModuleServices;
begin
  inherited;

  if Length(FSearchToken) = 0 then
    Exit;

  markIndex := Ord(FSearchToken[1]);
  mark := FEngine.GetMark(markIndex);

  if not mark.IsSet then
    Exit;

  aBuffer := GetEditBuffer;
  if aBuffer = nil then
    Exit;

  // Open file if different
  if not SameFileName(aBuffer.FileName, mark.FileName) then
  begin
    QuerySvcs(BorlandIDEServices, IOTAModuleServices, moduleServices);
    if moduleServices <> nil then
      moduleServices.OpenModule(mark.FileName);
    aBuffer := GetEditBuffer;
    if aBuffer = nil then
      Exit;
    aCursorPosition := GetEditPosition(aBuffer);
    if aCursorPosition = nil then
      Exit;
  end;

  // Move to exact position
  aCursorPosition.Move(mark.Line, mark.Col);
end;

initialization
  TMotionInsideAround.FIAMotionKeyBindings := TDictionary<string, TIAMotionClass>.Create;
  TMotionInsideAround.FillBindings;

finalization
  TMotionInsideAround.FIAMotionKeyBindings.Free;

end.
