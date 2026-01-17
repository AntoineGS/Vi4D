{
  This file registers the Vi4D Wizard in the Delphi IDE.

  Copyright (C) 2016 Peter Ross
  Copyright (C) 2021 Kai Anter
  Copyright (C) 2024 Antoine G Simard

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
}

unit Vi4DWizard;

interface

uses
  Engine,
  Classes,
  SysUtils,
  ToolsAPI,
  AppEvnts,
  ActnList,
  ComCtrls,
  Controls,
  Forms,
  Windows,
  Messages;

type
  TVi4DWizard = class(TNotifierObject, IOTAWizard)
  private
    FEvents: TApplicationEvents;
    FEngine: TEngine;
    FAction: TAction;
    FButton: TToolButton;
    procedure DoApplicationMessage(var Msg: TMsg; var Handled: Boolean);
    procedure AddToolButton;
    procedure OnCustomDrawButton(Sender: TToolBar; Button: TToolButton; State: TCustomDrawState;
      var DefaultDraw: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    procedure BeforeDestruction; override;
    procedure AddAction;
    procedure RemoveActionFromAllToolbars();
    procedure RemoveActionFromToolbar(AAction: TAction; AToolbar: TToolbar);
    procedure OnActionClick(Sender: TObject);
    procedure SetActionCaption(ACaption: String);
  end;

  // See https://www.davidghoyle.co.uk/WordPress/?page_id=1110 for combined Wizard
  // and DLL .pas file
procedure Register;
Function InitWizard(Const BorlandIDEServices: IBorlandIDEServices; RegisterProc: TWizardRegisterProc;
  var Terminate: TWizardTerminateProc): Boolean; StdCall;

exports InitWizard Name WizardEntryPoint;

implementation

uses
  Dialogs,
  Graphics,
  Commands.Base;

Var
  iWizard: Integer = 0;

const
  BUTTON_HINT = 'Vi4D Status bar, click to Disable Vi4D';

Function InitialiseWizard(BIDES: IBorlandIDEServices): TVi4DWizard;
Begin
  Result := TVi4DWizard.Create;
  Application.Handle := (BIDES As IOTAServices).GetParentHandle;
End;

Function InitWizard(Const BorlandIDEServices: IBorlandIDEServices; RegisterProc: TWizardRegisterProc;
  var Terminate: TWizardTerminateProc): Boolean; StdCall;
Begin
  Result := BorlandIDEServices <> Nil;
  RegisterProc(InitialiseWizard(BorlandIDEServices));
End;

procedure Register;
begin
{$IFDEF CODESITE}CodeSite.TraceMethod('Register', tmoTiming); {$ENDIF}
  RegisterPackageWizard(TVi4DWizard.Create);
end;

function IsEditControl(AControl: TComponent): Boolean;
begin
  Result := (AControl <> nil) and AControl.ClassNameIs('TEditControl') and SameText(AControl.Name, 'Editor');
end;

function WebColorStrToColor(WebColor: string): TColor;
begin
  if (Length(WebColor) <> 7) or (WebColor[1] <> '#') then
    Raise Exception.Create('Invalid web color string');

  Result :=
    RGB(
      StrToInt('$' + Copy(WebColor, 2, 2)),
      StrToInt('$' + Copy(WebColor, 4, 2)),
      StrToInt('$' + Copy(WebColor, 6, 2)));
end;

procedure TVi4DWizard.OnCustomDrawButton(Sender: TToolBar; Button: TToolButton; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  aColor: TColor;
begin
  if not (Button = FButton) then
  begin
    DefaultDraw := True;
    Exit;
  end;

  aColor := clNone;

  // todo make this configurable somehow
  case FEngine.currentViMode of
    mNormal: aColor := WebColorStrToColor('#61afef');
    mInsert: aColor := WebColorStrToColor('#c678dd');
    mVisual: aColor := WebColorStrToColor('#d19a66');
    mVisualLine, mVisualBlock: aColor := WebColorStrToColor('#f0c89a');
    mSubstitute: aColor := WebColorStrToColor('#e06c75');
  end;

  if aColor = clNone then
    Exit;

  Sender.Canvas.Brush.Color := aColor;
  Sender.Canvas.Rectangle(Button.BoundsRect);
  Sender.Canvas.FrameRect(Button.BoundsRect);
//  Sender.Canvas.Font.Style := [fsBold]; // I would like bolding but then the button does not draw wider so it breaks
end;

procedure TVi4DWizard.AddToolButton;
var
  LService: INTAServices;
  lastbtnidx: integer;
  aToolBar: TToolBar;
begin
  if FButton <> nil then
    Exit;

  RemoveActionFromAllToolbars;
  // workaround for an annoying issue where there is always an empty button added after each IDE restart

  if Supports(BorlandIDEServices, INTAServices, LService) then
  begin
    aToolBar := LService.ToolBar[sCustomToolBar];
    aToolBar.OnCustomDrawButton := OnCustomDrawButton;
    FButton := TToolButton.Create(nil);
    FButton.AutoSize := True;
    FButton.Name := 'Vi4DBtn';
    FButton.Action := FAction;
    FButton.Hint := BUTTON_HINT;
    FButton.ShowHint := True;
    FButton.Style := tbsTextButton;
    lastbtnidx := aToolBar.ButtonCount - 1;

    if lastbtnidx > -1 then
      FButton.Left := aToolBar.Buttons[lastbtnidx].Left + aToolBar.Buttons[lastbtnidx].Width
    else
      FButton.Left := 0;

    FButton.Parent := aToolBar;
  end;
end;

// http://docwiki.embarcadero.com/RADStudio/Sydney/en/Adding_an_Action_to_the_Action_List
procedure TVi4DWizard.AddAction;
var
  LService: INTAServices;
begin
  if FAction <> nil then
    Exit;

  if Supports(BorlandIDEServices, INTAServices, LService) then
  begin
    FAction := TAction.Create(nil);
    FAction.Name := 'Vi4D';
    FAction.Caption := 'Vi4D';
    FAction.Category := 'Tools';
    FAction.OnExecute := OnActionClick;
    LService.AddActionMenu('', FAction, nil);
  end;
end;

procedure TVi4DWizard.BeforeDestruction;
begin
  inherited;
  FEvents.OnMessage := nil;
  FEngine.Free;
  FEvents.Free;
end;

constructor TVi4DWizard.Create;
begin
  AddAction;
  FEvents := TApplicationEvents.Create(nil);
  FEvents.OnMessage := DoApplicationMessage;
  FEngine := TEngine.Create;
  FEngine.onCaptionChanged := SetActionCaption;
end;

destructor TVi4DWizard.Destroy;
begin
  FreeAndNil(FAction);
  inherited;
end;

procedure TVi4DWizard.DoApplicationMessage(var Msg: TMsg; var Handled: Boolean);
var
  Key: Word;
  ScanCode: Word;
  Shift: TShiftState;
begin
  if ((Msg.message = WM_KEYDOWN) or (Msg.message = WM_KEYUP) or (Msg.message = WM_CHAR)) and
    IsEditControl(Screen.ActiveControl) then
  begin
    Key := Msg.wParam;
    ScanCode := (Msg.lParam and $00FF0000) shr 16;
    Shift := KeyDataToShiftState(Msg.lParam);

    if Msg.message = WM_CHAR then
      FEngine.EditChar(Key, ScanCode, Shift, Msg, Handled)
    else
    begin
      if Key = VK_PROCESSKEY then
        Key := MapVirtualKey(ScanCode, 1);

      if Msg.message = WM_KEYDOWN then
        FEngine.EditKeyDown(Key, ScanCode, Shift, Msg, Handled);
    end;
  end
  else if (Msg.message = WM_LBUTTONUP) then
    FEngine.LButtonDown;

  // Has to happen after UI is displayed
  if FButton = nil then
    AddToolButton;
end;

procedure TVi4DWizard.Execute;
begin
  FEngine.ConfigureCursor;
end;

function TVi4DWizard.GetIDString: string;
begin
  Result := 'Vi4D.Vi4DWizard';
end;

function TVi4DWizard.GetName: string;
begin
  Result := 'Vi4D Wizard';
end;

function TVi4DWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TVi4DWizard.OnActionClick(Sender: TObject);
begin
  FEngine.ToggleActive;
end;

// http://docwiki.embarcadero.com/RADStudio/Sydney/en/Deleting_Toolbar_Buttons
procedure TVi4DWizard.RemoveActionFromAllToolbars;
var
  LService: INTAServices;
  aToolbar: TToolBar;
begin
  if Supports(BorlandIDEServices, INTAServices, LService) then
  begin
    aToolbar := LService.ToolBar[sCustomToolBar];
    aToolbar.OnCustomDrawButton := nil; // or we get invalid pointer operations during destroy
    RemoveActionFromToolbar(FAction, LService.ToolBar[sCustomToolBar]);
    RemoveActionFromToolbar(FAction, LService.ToolBar[sDesktopToolBar]);
    RemoveActionFromToolbar(FAction, LService.ToolBar[sStandardToolBar]);
    RemoveActionFromToolbar(FAction, LService.ToolBar[sDebugToolBar]);
    RemoveActionFromToolbar(FAction, LService.ToolBar[sViewToolBar]);
    RemoveActionFromToolbar(FAction, LService.ToolBar[sBrowserToolbar]);
  end;
end;

procedure TVi4DWizard.RemoveActionFromToolbar(AAction: TAction; AToolbar: TToolbar);
var
  i: Integer;
  LButton: TToolButton;
begin
  for i := AToolbar.ButtonCount - 1 downto 0 do
  begin
    LButton := AToolbar.Buttons[i];
    // the buttons that show up after a restart still have the hint (not the name) for some reason
    if (LButton.Action = FAction) or (LButton.Name = 'Vi4DBtn') or (LButton = FButton) or (LButton.Hint = BUTTON_HINT) then
    begin
      AToolbar.Perform(CM_CONTROLCHANGE, wParam(LButton), 0);
      FreeAndNil(LButton);
    end;
  end;
end;

procedure TVi4DWizard.SetActionCaption(ACaption: String);
begin
  FAction.Caption := ACaption;
end;

end.
