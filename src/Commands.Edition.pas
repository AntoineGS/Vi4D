unit Commands.Edition;

interface

uses
  Commands.Base,
  Clipboard,
  ToolsAPI;

type
  TEdition = class(TCommand)
  public
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); virtual;
  end;

  TEditionClass = class of TEdition;

  TEditionAppend = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionAppendEOL = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionInsert = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionInsertBOL = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionNextLine = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionPreviousLine = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionDeleteCharInsert = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionDeleteLineInsert = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionDeleteTilEOL = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionChangeTilEOL = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionReplaceChar = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionReplaceMode = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionUndo = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionRedo = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionDeleteCharacter = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionDeletePreviousCharacter = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionPaste = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionPasteBefore = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionJoinLines = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionRepeatLastCommand = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionToggleCase = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionSaveFile = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

  TEditionCloseFile = class(TEdition)
    procedure Execute(aCursorPosition: IOTAEditPosition; aCount: integer); override;
  end;

implementation

uses
  SysUtils,
  NavUtils,
  Commands.Motion,
  Commands.Operators;

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

{ TEdition }

procedure TEdition.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  if aCursorPosition = nil then
    Raise Exception.Create('aCursorPosition must be set to call to TEdition.Execute');
end;

{ TEditionDeleteCharacter }

procedure TEditionDeleteCharacter.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.Delete(aCount);
end;

{ TEditionReplaceChar }

procedure TEditionReplaceChar.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aEditionDeleteCharInsert: TEditionDeleteCharInsert;
begin
  inherited;
  aEditionDeleteCharInsert := TEditionDeleteCharInsert.Create(FClipboard, FEngine);
  try
    aEditionDeleteCharInsert.Execute(aCursorPosition, aCount);
    // todo: somehow this needs to go back to normal mode after entering x characters
  finally
    aEditionDeleteCharInsert.Free;
  end;
end;

{ TEditionUndo }

procedure TEditionUndo.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  { TODO : Jump to position that is undone }
  aBuffer := GetEditBuffer;
  aBuffer.Undo;
end;

{ TEditionInsert }

procedure TEditionInsert.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  FEngine.currentViMode := mInsert;
end;

{ TEditionChangeTilEOL }

procedure TEditionChangeTilEOL.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aEditionDeleteTilEOL: TEditionDeleteTilEOL;
begin
  inherited;

  aEditionDeleteTilEOL := TEditionDeleteTilEOL.Create(FClipboard, FEngine);
  try
    aEditionDeleteTilEOL.Execute(aCursorPosition, aCount);
    FEngine.currentViMode := mInsert;
  finally
    aEditionDeleteTilEOL.Free;
  end;
end;

{ TEditionDeleteCharInsert }

procedure TEditionDeleteCharInsert.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.Delete(aCount);
  FEngine.currentViMode := mInsert;
end;

{ TEditionDeleteTilEOL }

procedure TEditionDeleteTilEOL.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  lPos: TOTAEditPos;
  aNavigationMotion: INavigationMotion;
  aMotionTrueEndOfLine: TMotionTrueEOL;
begin
  inherited;

  aMotionTrueEndOfLine := TMotionTrueEOL.Create(FClipboard, FEngine);
  try
    if not Supports(aMotionTrueEndOfLine, INavigationMotion, aNavigationMotion) then
      Exit;

    lPos := GetPositionForMove(aCursorPosition, aNavigationMotion, true, aCount);
    ApplyActionToSelection(aCursorPosition, baDelete, false, lPos);
  finally
    aMotionTrueEndOfLine.Free;
  end;
end;

{ TEditionAppend }

procedure TEditionAppend.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveRelative(0, 1);
  FEngine.currentViMode := mInsert;
end;

{ TEditionPreviousLine }

procedure TEditionPreviousLine.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveBOL;
  aCursorPosition.InsertText(#13#10);
  aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);
  aCursorPosition.MoveRelative(-1, 0);
  FEngine.currentViMode := mInsert;
end;

{ TEditionReplaceMode }

procedure TEditionReplaceMode.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  aBuffer := GetEditBuffer;
  aBuffer.BufferOptions.InsertMode := False;
  FEngine.currentViMode := mInsert;
end;

{ TEditionAppendEOL }

procedure TEditionAppendEOL.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveEOL;
  FEngine.currentViMode := mInsert;
end;

{ TEditionNextLine }

procedure TEditionNextLine.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveEOL;
  aCursorPosition.InsertText(#13#10);
  aCursorPosition.MoveCursor(mmSkipWhite or mmSkipRight);
  FEngine.currentViMode := mInsert;
end;

{ TEditionPaste }

procedure TEditionPaste.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  Paste(FClipboard, aCursorPosition, dForward);
end;

{ TEditionDeleteLineInsert }

procedure TEditionDeleteLineInsert.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aEditionChangeTilEOL: TEditionChangeTilEOL;
begin
  inherited;
  aCursorPosition.MoveBOL;

  aEditionChangeTilEOL := TEditionChangeTilEOL.Create(FClipboard, FEngine);
  try
    aEditionChangeTilEOL.Execute(aCursorPosition, aCount);
  finally
    aEditionChangeTilEOL.Free;
  end;
end;

{ TEditionPasteBefore }

procedure TEditionPasteBefore.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  Paste(FClipboard, aCursorPosition, dBack);
end;

{ TEditionInsertBOL }

procedure TEditionInsertBOL.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aMotionStartOfLineAfterWhiteSpace: TMotionBOLAfterWhiteSpace;
begin
  inherited;

  aMotionStartOfLineAfterWhiteSpace := TMotionBOLAfterWhiteSpace.Create(FClipboard, FEngine);
  try
    aMotionStartOfLineAfterWhiteSpace.Move(aCursorPosition, aCount, true);
    FEngine.currentViMode := mInsert;
  finally
    aMotionStartOfLineAfterWhiteSpace.Free;
  end;
end;

{ TEditionJoinLines }

procedure TEditionJoinLines.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  i: Integer;
  lPos: TOTAEditPos;
  aMotionWord: TMotionWord;
begin
  inherited;

  for i := 1 to aCount do
  begin
    aCursorPosition.MoveEOL;
    aCursorPosition.Delete(1);

    if aCursorPosition.IsWhiteSpace and (CharAtRelativeLocation(aCursorPosition, 1) = viWhiteSpace) then
    begin
      aMotionWord := TMotionWord.Create(FClipboard, FEngine);
      try
        lPos := GetPositionForMove(aCursorPosition, aMotionWord, true, 1);
        ApplyActionToSelection(aCursorPosition, baDelete, false, lPos);
      finally
        aMotionWord.Free;
      end;
    end;

    if not aCursorPosition.IsWhiteSpace then
      aCursorPosition.InsertCharacter(' ');
  end;
end;

{ TEditionDeletePreviousCharacter }

procedure TEditionDeletePreviousCharacter.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  aCursorPosition.MoveRelative(0, -aCount);
  aCursorPosition.Delete(aCount);
end;

{ TEditionRepeatLastCommand }

procedure TEditionRepeatLastCommand.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
begin
  inherited;
  FEngine.ExecuteLastCommand;
end;

{ TEditionToggleCase }

procedure TEditionToggleCase.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
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

{ TEditionSaveFile }

procedure TEditionSaveFile.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  aBuffer := GetEditBuffer;

  if aBuffer.IsModified then
    aBuffer.Module.Save(False, True);
end;

{ TEditionCloseFile }

procedure TEditionCloseFile.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
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

{ TEditionRedo }

procedure TEditionRedo.Execute(aCursorPosition: IOTAEditPosition; aCount: integer);
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  { TODO : Jump to position that is redone }
  aBuffer := GetEditBuffer;
  aBuffer.Redo;
end;

end.
