unit Commands.Editing;

interface

uses
  Commands.Base,
  Clipboard,
  ToolsAPI;

type
  TViEditC = class(TViCommand)
  public
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); virtual;
  end;

  TViEditCClass = class of TViEditC;

  TViECAppend = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECAppendEOL = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECInsert = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECInsertBOL = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECNextLine = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECPreviousLine = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECDeleteCharInsert = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECDeleteLineInsert = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECDeleteTilEOL = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECChangeTilEOL = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECReplaceChar = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECReplaceMode = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECUndo = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECRedo = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECDeleteCharacter = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECDeletePreviousCharacter = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECPaste = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECPasteBefore = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECJoinLines = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECRepeatLastCommand = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECToggleCase = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECSaveFile = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TViECCloseFile = class(TViEditC)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

implementation

uses
  SysUtils,
  NavUtils,
  Commands.Navigation,
  Commands.Operators,
  Commands.TextObjects;

procedure Paste(aClipboard: TClipboard; const AEditPosition: IOTAEditPosition; ADirection: TDirection);
var
  LAutoIndent, LPastingInSelection: Boolean;
  LSelection: IOTAEditBlock;
  LRow, LCol: Integer;
  aBuffer: IOTAEditBuffer;

  function FixCursorPosition: Boolean;
  begin
    result := (not LPastingInSelection) and (ADirection = dForward);
  end;

begin
  LPastingInSelection := False;
  aBuffer := GetEditBuffer;
  LAutoIndent := ABuffer.BufferOptions.AutoIndent;

  LSelection := ABuffer.EditBlock;
  if LSelection.Size > 0 then
  begin
    LPastingInSelection := True;
    LRow := LSelection.StartingRow;
    LCol := LSelection.StartingColumn;
    LSelection.Delete;
    AEditPosition.Move(LRow, LCol);
  end;

  if (aClipboard.CurrentRegister.IsLine) then
  begin
    ABuffer.BufferOptions.AutoIndent := False;
    AEditPosition.MoveBOL;

    if FixCursorPosition then
      AEditPosition.MoveRelative(1, 0);

    AEditPosition.Save;
    AEditPosition.InsertText(aClipboard.CurrentRegister.Text);
    AEditPosition.Restore;
    ABuffer.BufferOptions.AutoIndent := LAutoIndent;
  end
  else
  begin
    if FixCursorPosition then
      AEditPosition.MoveRelative(0, 1);

    AEditPosition.InsertText(aClipboard.CurrentRegister.Text);
  end;
end;

{ TViEditC }

procedure TViEditC.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set to call to TViEditC.Execute');
end;

{ TViECDeleteCharacter }

procedure TViECDeleteCharacter.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.Delete(aCount);
end;

{ TViECReplaceChar }

procedure TViECReplaceChar.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aViECDeleteCharInsert: TViECDeleteCharInsert;
begin
  inherited;
  aViECDeleteCharInsert := TViECDeleteCharInsert.Create(FClipboard, FViEngine);
  try
    aViECDeleteCharInsert.Execute(aCursorPosition, aCount);
    // todo: somehow this needs to go back to normal mode after entering x characters
  finally
    aViECDeleteCharInsert.Free;
  end;
end;

{ TViECUndo }

procedure TViECUndo.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  { TODO : Jump to position that is undone }
  aBuffer := GetEditBuffer;
  aBuffer.Undo;
end;

{ TViECInsert }

procedure TViECInsert.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  FViEngine.currentViMode := mInsert;
end;

{ TViECChangeTilEOL }

procedure TViECChangeTilEOL.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aViECDeleteTilEOL: TViECDeleteTilEOL;
begin
  inherited;

  aViECDeleteTilEOL := TViECDeleteTilEOL.Create(FClipboard, FViEngine);
  try
    aViECDeleteTilEOL.Execute(aCursorPosition, aCount);
    FViEngine.currentViMode := mInsert;
  finally
    aViECDeleteTilEOL.Free;
  end;
end;

{ TViECDeleteCharInsert }

procedure TViECDeleteCharInsert.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.Delete(aCount);
  FViEngine.currentViMode := mInsert;
end;

{ TViECDeleteTilEOL }

procedure TViECDeleteTilEOL.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  lPos: TOTAEditPos;
  aNavigationMotion: INavigationMotion;
  aViNCTrueEndOfLine: TViNCTrueEndOfLine;
begin
  inherited;

  aViNCTrueEndOfLine := TViNCTrueEndOfLine.Create(FClipboard, FViEngine);
  try
    if not Supports(aViNCTrueEndOfLine, INavigationMotion, aNavigationMotion) then
      Exit;

    lPos := GetPositionForMove(aCursorPosition, aNavigationMotion, true, aCount);
    ApplyActionToSelection(aCursorPosition, baDelete, false, lPos);
  finally
    aViNCTrueEndOfLine.Free;
  end;
end;

{ TViECAppend }

procedure TViECAppend.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveRelative(0, 1);
  FViEngine.currentViMode := mInsert;
end;

{ TViECPreviousLine }

procedure TViECPreviousLine.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveBOL;
  aCursorPosition.InsertText(#13#10);
  aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);
  aCursorPosition.MoveRelative(-1, 0);
  FViEngine.currentViMode := mInsert;
end;

{ TViECReplaceMode }

procedure TViECReplaceMode.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  aBuffer := GetEditBuffer;
  aBuffer.BufferOptions.InsertMode := False;
  FViEngine.currentViMode := mInsert;
end;

{ TViECAppendEOL }

procedure TViECAppendEOL.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveEOL;
  FViEngine.currentViMode := mInsert;
end;

{ TViECNextLine }

procedure TViECNextLine.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveEOL;
  aCursorPosition.InsertText(#13#10);
  aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);
  FViEngine.currentViMode := mInsert;
end;

{ TViECPaste }

procedure TViECPaste.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  Paste(FClipboard, aCursorPosition, dForward);
end;

{ TViECDeleteLineInsert }

procedure TViECDeleteLineInsert.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aViECDeleteTilEOLInsert: TViECChangeTilEOL;
begin
  inherited;
  aCursorPosition.MoveBOL;

  aViECDeleteTilEOLInsert := TViECChangeTilEOL.Create(FClipboard, FViEngine);
  try
    aViECDeleteTilEOLInsert.Execute(aCursorPosition, aCount);
  finally
    aViECDeleteTilEOLInsert.Free;
  end;
end;

{ TViECPasteBefore }

procedure TViECPasteBefore.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  Paste(FClipboard, aCursorPosition, dBack);
end;

{ TViECInsertBOL }

procedure TViECInsertBOL.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aViNCStartOfLineAfterWhiteSpace: TViNCStartOfLineAfterWhiteSpace;
begin
  inherited;

  aViNCStartOfLineAfterWhiteSpace := TViNCStartOfLineAfterWhiteSpace.Create(FClipboard, FViEngine);
  try
    aViNCStartOfLineAfterWhiteSpace.Move(aCursorPosition, aCount, true);
    FViEngine.currentViMode := mInsert;
  finally
    aViNCStartOfLineAfterWhiteSpace.Free;
  end;
end;

{ TViECJoinLines }

procedure TViECJoinLines.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  i: Integer;
  lPos: TOTAEditPos;
  aViTOCWord: TViTOCWord;
begin
  inherited;

  for i := 1 to aCount do
  begin
    aCursorPosition.MoveEOL;
    aCursorPosition.Delete(1);

    if aCursorPosition.IsWhiteSpace and (CharAtRelativeLocation(aCursorPosition, 1) = viWhiteSpace) then
    begin
      aViTOCWord := TViTOCWord.Create(FClipboard, FViEngine);
      try
        lPos := GetPositionForMove(aCursorPosition, aViTOCWord, true, 1);
        ApplyActionToSelection(aCursorPosition, baDelete, false, lPos);
      finally
        aViTOCWord.Free;
      end;
    end;

    if not aCursorPosition.IsWhiteSpace then
      aCursorPosition.InsertCharacter(' ');
  end;
end;

{ TViECDeletePreviousCharacter }

procedure TViECDeletePreviousCharacter.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveRelative(0, -aCount);
  aCursorPosition.Delete(aCount);
end;

{ TViECRepeatLastCommand }

procedure TViECRepeatLastCommand.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  FViEngine.ExecuteLastCommand;
end;

{ TViOCToggleCase }

procedure TViECToggleCase.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
  LSelection: IOTAEditBlock;
begin
  inherited;
  aBuffer := GetEditBuffer;
  LSelection := aBuffer.EditBlock;
  LSelection.Reset;
  LSelection.BeginBlock;
  LSelection.Extend(aCursorPosition.Row, aCursorPosition.Column + aCount);
  LSelection.ToggleCase;
  LSelection.EndBlock;
end;

{ TViECSaveFile }

procedure TViECSaveFile.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  aBuffer := GetEditBuffer;

  if aBuffer.IsModified then
    aBuffer.Module.Save(False, True);
end;

{ TViECCloseFile }

procedure TViECCloseFile.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  aBuffer := GetEditBuffer;

//  todo: add modifiers to :X commands too, ie :q! before activating the below, for now itll prompt if not saved
//  if aBuffer.IsModified then
//    raise Exception.Create('File has pending changes, use :w to save changes');

  aBuffer.Module.CloseModule(False);
end;

{ TViECRedo }

procedure TViECRedo.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  { TODO : Jump to position that is redone }
  aBuffer := GetEditBuffer;
  aBuffer.Redo;
end;

end.
