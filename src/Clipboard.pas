unit Clipboard;

interface

type
  TRegister = record
  public
    IsLine: Boolean;
    Text: String;
  end;

  TClipboard = class
  private
    FRegisterArray: array [0 .. 255] of TRegister;
    FSelectedRegister: Integer;
    FUserSelectedRegister: Boolean;
  public
    function CurrentRegister: TRegister;
    function GetRegister(aIndex: Integer): TRegister;
    procedure SetCurrentRegisterIsLine(aValue: boolean);
    procedure SetCurrentRegisterText(aValue: string);
    procedure SetSelectedRegister(aIndex: Integer);
    procedure ResetSelectedRegister;
    procedure StoreYank(const aText: string; aIsLine: Boolean);
    procedure StoreDelete(const aText: string; aIsLine: Boolean);
  end;

implementation

{ TClipboard }

function TClipboard.CurrentRegister: TRegister;
begin
  //this could yield an out of bounds once better register logic is implement, need to take into account at that point
  result := FRegisterArray[FSelectedRegister];
end;

procedure TClipboard.SetCurrentRegisterIsLine(aValue: boolean);
begin
  FRegisterArray[FSelectedRegister].IsLine := aValue;
end;

procedure TClipboard.SetCurrentRegisterText(aValue: string);
begin
  FRegisterArray[FSelectedRegister].Text := aValue;
end;

procedure TClipboard.SetSelectedRegister(aIndex: Integer);
begin
  if (aIndex >= 0) and (aIndex <= 255) then
  begin
    FSelectedRegister := aIndex;
    FUserSelectedRegister := True;
  end;
end;

procedure TClipboard.ResetSelectedRegister;
begin
  FSelectedRegister := 0;
  FUserSelectedRegister := False;
end;

function TClipboard.GetRegister(aIndex: Integer): TRegister;
begin
  if (aIndex >= 0) and (aIndex <= 255) then
    Result := FRegisterArray[aIndex]
  else
  begin
    Result.Text := '';
    Result.IsLine := False;
  end;
end;

procedure TClipboard.StoreYank(const aText: string; aIsLine: Boolean);
begin
  // Always store to register 0 (yank register)
  FRegisterArray[0].Text := aText;
  FRegisterArray[0].IsLine := aIsLine;

  // If user specified a register, also store there
  if FUserSelectedRegister then
  begin
    FRegisterArray[FSelectedRegister].Text := aText;
    FRegisterArray[FSelectedRegister].IsLine := aIsLine;
  end;
end;

procedure TClipboard.StoreDelete(const aText: string; aIsLine: Boolean);
var
  i: Integer;
begin
  // If user specified a register, store there only
  if FUserSelectedRegister then
  begin
    FRegisterArray[FSelectedRegister].Text := aText;
    FRegisterArray[FSelectedRegister].IsLine := aIsLine;
  end
  else
  begin
    // Shift registers 1-8 down to 2-9
    for i := 9 downto 2 do
      FRegisterArray[i] := FRegisterArray[i - 1];

    // Store new delete in register 1
    FRegisterArray[1].Text := aText;
    FRegisterArray[1].IsLine := aIsLine;
  end;

  // Also store to unnamed register (0) for immediate paste
  FRegisterArray[0].Text := aText;
  FRegisterArray[0].IsLine := aIsLine;
end;

end.
