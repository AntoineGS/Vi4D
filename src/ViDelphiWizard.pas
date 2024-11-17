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

unit ViDelphiWizard;

interface

uses
  ViEngine,
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
    FViEngine: TViEngine;
    FAction: TAction;
    procedure DoApplicationMessage(var Msg: TMsg; var Handled: Boolean);
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

uses Dialogs;

Var
  iWizard: Integer = 0;

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

// http://docwiki.embarcadero.com/RADStudio/Sydney/en/Adding_an_Action_to_the_Action_List
procedure TVi4DWizard.AddAction;
var
  LService: INTAServices;
begin
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
  FEvents.Free;
  FViEngine.Free;
end;

constructor TVi4DWizard.Create;
begin
  AddAction;
  FEvents := TApplicationEvents.Create(nil);
  FEvents.OnMessage := DoApplicationMessage;
  FViEngine := TViEngine.Create;
  FViEngine.onModeChanged := SetActionCaption;
end;

destructor TVi4DWizard.Destroy;
begin
  RemoveActionFromAllToolbars;
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
      FViEngine.EditChar(Key, ScanCode, Shift, Msg, Handled)
    else
    begin
      if Key = VK_PROCESSKEY then
        Key := MapVirtualKey(ScanCode, 1);

      if Msg.message = WM_KEYDOWN then
        FViEngine.EditKeyDown(Key, ScanCode, Shift, Msg, Handled);
    end;
  end
  else if (Msg.message = WM_LBUTTONDOWN) then
    FViEngine.LButtonDown;
end;

procedure TVi4DWizard.Execute;
begin
  FViEngine.ConfigureCursor;
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
  FViEngine.ToggleActive;
end;

// http://docwiki.embarcadero.com/RADStudio/Sydney/en/Deleting_Toolbar_Buttons
procedure TVi4DWizard.RemoveActionFromAllToolbars;
var
  LService: INTAServices;
begin
  if Supports(BorlandIDEServices, INTAServices, LService) then
  begin
    RemoveActionFromToolbar(FAction, LService.ToolBar[sCustomToolBar]);
    RemoveActionFromToolbar(FAction, LService.ToolBar[sDesktopToolBar]);
    RemoveActionFromToolbar(FAction, LService.ToolBar[sStandardToolBar]);
    RemoveActionFromToolbar(FAction, LService.ToolBar[sDebugToolBar]);
    RemoveActionFromToolbar(FAction, LService.ToolBar[sViewToolBar]);
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
    if LButton.Action = FAction then
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
