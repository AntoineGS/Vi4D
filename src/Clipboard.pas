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
  public
    function CurrentRegister: TRegister;
    procedure SetCurrentRegisterIsLine(aValue: boolean);
    procedure SetCurrentRegisterText(aValue: string);
  end;

implementation

{ TClipboard }

function TClipboard.CurrentRegister: TRegister;
begin
  //todo: this could yield an out of bounds
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

end.
