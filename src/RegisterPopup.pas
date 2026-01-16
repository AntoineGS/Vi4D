unit RegisterPopup;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls,
  Clipboard,
  Commands.Base;

type
  TPopupMode = (pmRegisters, pmMarks);
  TGetMarkFunc = function(aIndex: Integer): TMark of object;

  TRegisterPopupForm = class(TForm)
  private
    FListBox: TListBox;
    FMode: TPopupMode;
    FClipboard: TClipboard;
    FGetMark: TGetMarkFunc;
    FKeyToIndexMap: TStringList;
    procedure PopulateRegisters;
    procedure PopulateMarks;
    procedure AdjustHeight;
  public
    constructor CreatePopup(AOwner: TComponent; AMode: TPopupMode;
      AClipboard: TClipboard; AGetMark: TGetMarkFunc);
    destructor Destroy; override;
    procedure UpdateSelection(const AKey: string);
    procedure CenterOnEditor;
  end;

  TPopupManager = class
  private
    FPopupForm: TRegisterPopupForm;
    FClipboard: TClipboard;
    FGetMark: TGetMarkFunc;
  public
    constructor Create(AClipboard: TClipboard; AGetMark: TGetMarkFunc);
    destructor Destroy; override;
    procedure ShowRegisterPopup;
    procedure ShowMarkPopup;
    procedure UpdateSelection(const AKey: string);
    procedure HidePopup;
    function IsVisible: Boolean;
  end;

implementation

uses
  StrUtils,
  ToolsAPI,
  NavUtils;

const
  MAX_TEXT_PREVIEW = 90;
  MAX_LINE_PREVIEW = 100;

function GetLineFromFile(const AFileName: string; ALine: Integer): string;
var
  lines: TStringList;
begin
  Result := '';
  if (AFileName = '') or (ALine <= 0) then
    Exit;

  if not FileExists(AFileName) then
    Exit;

  lines := TStringList.Create;
  try
    try
      lines.LoadFromFile(AFileName);
      if (ALine >= 1) and (ALine <= lines.Count) then
        Result := Trim(lines[ALine - 1]);
    except
      Result := '';
    end;
  finally
    lines.Free;
  end;
end;

function TruncateText(const AText: string; AMaxLen: Integer): string;
var
  cleanText: string;
begin
  cleanText := StringReplace(AText, #13#10, ' ', [rfReplaceAll]);
  cleanText := StringReplace(cleanText, #13, ' ', [rfReplaceAll]);
  cleanText := StringReplace(cleanText, #10, ' ', [rfReplaceAll]);

  if Length(cleanText) > AMaxLen then
    Result := Copy(cleanText, 1, AMaxLen - 3) + '...'
  else
    Result := cleanText;
end;

{ TRegisterPopupForm }

constructor TRegisterPopupForm.CreatePopup(AOwner: TComponent; AMode: TPopupMode;
  AClipboard: TClipboard; AGetMark: TGetMarkFunc);
begin
  inherited CreateNew(AOwner);

  FMode := AMode;
  FClipboard := AClipboard;
  FGetMark := AGetMark;
  FKeyToIndexMap := TStringList.Create;

  BorderStyle := bsToolWindow;
  FormStyle := fsStayOnTop;
  Width := 700;

  if AMode = pmRegisters then
    Caption := 'Registers'
  else
    Caption := 'Marks';

  FListBox := TListBox.Create(Self);
  FListBox.Parent := Self;
  FListBox.Align := alClient;
  FListBox.Font.Name := 'Consolas';
  FListBox.Font.Size := 10;

  if AMode = pmRegisters then
    PopulateRegisters
  else
    PopulateMarks;

  // Adjust height based on item count
  AdjustHeight;
end;

destructor TRegisterPopupForm.Destroy;
begin
  FKeyToIndexMap.Free;
  inherited;
end;

procedure TRegisterPopupForm.PopulateRegisters;
var
  i: Integer;
  reg: TRegister;
  displayText: string;
  prefix: string;
  key: string;
begin
  FListBox.Items.Clear;
  FKeyToIndexMap.Clear;

  // Show numbered registers 0-9
  for i := 0 to 9 do
  begin
    reg := FClipboard.GetRegister(i);
    if reg.Text <> '' then
    begin
      prefix := IfThen(reg.IsLine, 'L', ' ');
      key := IntToStr(i);
      displayText := Format('"%s  %s  %s', [key, prefix, TruncateText(reg.Text, MAX_TEXT_PREVIEW)]);
      FKeyToIndexMap.AddObject(key, TObject(FListBox.Items.Count));
      FListBox.Items.Add(displayText);
    end;
  end;

  // Show named registers a-z
  for i := Ord('a') to Ord('z') do
  begin
    reg := FClipboard.GetRegister(i);
    if reg.Text <> '' then
    begin
      prefix := IfThen(reg.IsLine, 'L', ' ');
      key := Chr(i);
      displayText := Format('"%s  %s  %s', [key, prefix, TruncateText(reg.Text, MAX_TEXT_PREVIEW)]);
      FKeyToIndexMap.AddObject(key, TObject(FListBox.Items.Count));
      FListBox.Items.Add(displayText);
    end;
  end;

  // Show named registers A-Z
  for i := Ord('A') to Ord('Z') do
  begin
    reg := FClipboard.GetRegister(i);
    if reg.Text <> '' then
    begin
      prefix := IfThen(reg.IsLine, 'L', ' ');
      key := Chr(i);
      displayText := Format('"%s  %s  %s', [key, prefix, TruncateText(reg.Text, MAX_TEXT_PREVIEW)]);
      FKeyToIndexMap.AddObject(key, TObject(FListBox.Items.Count));
      FListBox.Items.Add(displayText);
    end;
  end;

  if FListBox.Items.Count = 0 then
    FListBox.Items.Add('(no registers with content)');
end;

procedure TRegisterPopupForm.PopulateMarks;
var
  i: Integer;
  mark: TMark;
  displayText: string;
  fileName: string;
  key: string;
  linePreview: string;
begin
  FListBox.Items.Clear;
  FKeyToIndexMap.Clear;

  if not Assigned(FGetMark) then
  begin
    FListBox.Items.Add('(marks not available)');
    Exit;
  end;

  // Show marks a-z
  for i := Ord('a') to Ord('z') do
  begin
    mark := FGetMark(i);
    if mark.IsSet then
    begin
      fileName := ExtractFileName(mark.FileName);
      key := Chr(i);
      linePreview := TruncateText(GetLineFromFile(mark.FileName, mark.Line), MAX_LINE_PREVIEW);
      if linePreview <> '' then
        displayText := Format('''%s  %s:%d  %s', [key, fileName, mark.Line, linePreview])
      else
        displayText := Format('''%s  %s:%d', [key, fileName, mark.Line]);
      FKeyToIndexMap.AddObject(key, TObject(FListBox.Items.Count));
      FListBox.Items.Add(displayText);
    end;
  end;

  // Show marks A-Z
  for i := Ord('A') to Ord('Z') do
  begin
    mark := FGetMark(i);
    if mark.IsSet then
    begin
      fileName := ExtractFileName(mark.FileName);
      key := Chr(i);
      linePreview := TruncateText(GetLineFromFile(mark.FileName, mark.Line), MAX_LINE_PREVIEW);
      if linePreview <> '' then
        displayText := Format('''%s  %s:%d  %s', [key, fileName, mark.Line, linePreview])
      else
        displayText := Format('''%s  %s:%d', [key, fileName, mark.Line]);
      FKeyToIndexMap.AddObject(key, TObject(FListBox.Items.Count));
      FListBox.Items.Add(displayText);
    end;
  end;

  if FListBox.Items.Count = 0 then
    FListBox.Items.Add('(no marks set)');
end;

procedure TRegisterPopupForm.UpdateSelection(const AKey: string);
var
  idx: Integer;
begin
  idx := FKeyToIndexMap.IndexOf(AKey);
  if idx >= 0 then
    FListBox.ItemIndex := Integer(FKeyToIndexMap.Objects[idx])
  else
    FListBox.ItemIndex := -1;
end;

procedure TRegisterPopupForm.AdjustHeight;
const
  ITEM_HEIGHT = 18;  // Approximate height per item
  MIN_HEIGHT = 60;
  MAX_HEIGHT = 400;
  PADDING = 30;      // For title bar and borders
var
  itemCount: Integer;
  newHeight: Integer;
begin
  itemCount := FListBox.Items.Count;
  if itemCount = 0 then
    itemCount := 1;

  newHeight := (itemCount * ITEM_HEIGHT) + PADDING;

  if newHeight < MIN_HEIGHT then
    newHeight := MIN_HEIGHT
  else if newHeight > MAX_HEIGHT then
    newHeight := MAX_HEIGHT;

  Height := newHeight;
end;

procedure TRegisterPopupForm.CenterOnEditor;
var
  aBuffer: IOTAEditBuffer;
  editView: IOTAEditView;
  editorForm: TCustomForm;
  editorRect: TRect;
  centerX, centerY: Integer;
begin
  aBuffer := GetEditBuffer;
  if aBuffer = nil then
  begin
    Position := poScreenCenter;
    Exit;
  end;

  editView := aBuffer.TopView;
  if (editView = nil) or (editView.GetEditWindow = nil) or (editView.GetEditWindow.Form = nil) then
  begin
    Position := poScreenCenter;
    Exit;
  end;

  editorForm := editView.GetEditWindow.Form;

  // Get editor window bounds in screen coordinates
  editorRect.TopLeft := editorForm.ClientToScreen(Point(0, 0));
  editorRect.BottomRight := editorForm.ClientToScreen(Point(editorForm.ClientWidth, editorForm.ClientHeight));

  // Calculate center position
  centerX := editorRect.Left + (editorRect.Right - editorRect.Left - Width) div 2;
  centerY := editorRect.Top + (editorRect.Bottom - editorRect.Top - Height) div 2;

  // Ensure popup stays on screen
  if centerX < 0 then
    centerX := 0;
  if centerY < 0 then
    centerY := 0;
  if centerX + Width > Screen.Width then
    centerX := Screen.Width - Width;
  if centerY + Height > Screen.Height then
    centerY := Screen.Height - Height;

  Left := centerX;
  Top := centerY;
end;

{ TPopupManager }

constructor TPopupManager.Create(AClipboard: TClipboard; AGetMark: TGetMarkFunc);
begin
  inherited Create;
  FClipboard := AClipboard;
  FGetMark := AGetMark;
  FPopupForm := nil;
end;

destructor TPopupManager.Destroy;
begin
  HidePopup;
  inherited;
end;

procedure TPopupManager.ShowRegisterPopup;
begin
  HidePopup;
  FPopupForm := TRegisterPopupForm.CreatePopup(nil, pmRegisters, FClipboard, FGetMark);
  FPopupForm.CenterOnEditor;
  // Show without stealing focus from the editor
  ShowWindow(FPopupForm.Handle, SW_SHOWNOACTIVATE);
  FPopupForm.Visible := True;
end;

procedure TPopupManager.ShowMarkPopup;
begin
  HidePopup;
  FPopupForm := TRegisterPopupForm.CreatePopup(nil, pmMarks, FClipboard, FGetMark);
  FPopupForm.CenterOnEditor;
  // Show without stealing focus from the editor
  ShowWindow(FPopupForm.Handle, SW_SHOWNOACTIVATE);
  FPopupForm.Visible := True;
end;

procedure TPopupManager.UpdateSelection(const AKey: string);
begin
  if FPopupForm <> nil then
    FPopupForm.UpdateSelection(AKey);
end;

procedure TPopupManager.HidePopup;
begin
  if FPopupForm <> nil then
  begin
    FPopupForm.Close;
    FreeAndNil(FPopupForm);
  end;
end;

function TPopupManager.IsVisible: Boolean;
begin
  Result := (FPopupForm <> nil) and FPopupForm.Visible;
end;

end.
