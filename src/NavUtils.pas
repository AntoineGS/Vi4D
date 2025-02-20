unit NavUtils;

interface

uses
  ToolsAPI;

function QuerySvcs(const AInstance: IUnknown; const AIntf: TGUID; out AInst): Boolean;
function GetEditBuffer: IOTAEditBuffer;
function GetHistoryServices: IOTAHistoryServices;
function GetEditActions: IOTAEditActions60;
function GetEditPosition(ABuffer: IOTAEditBuffer): IOTAEditPosition;
function GetSourceEditorFromModule(aModule: IOTAModule; const fileName: string = ''): IOTASourceEditor;
function GetFileEditorForModule(aModule: IOTAModule; index: Integer): IOTAEditor;
procedure CloseEditView(aModule: IOTAModule; forceClose: boolean);
function GetTopMostEditView(sourceEditor: IOTASourceEditor): IOTAEditView;
function GetCurrentSourceEditor: IOTASourceEditor;
function GetCurrentModule: IOTAModule;
procedure ClosePage(editView: IOTAEditView);
function IsModuleModified(aModule: IOTAModule): Boolean;

implementation

uses
  SysUtils, Dialogs;

function QuerySvcs(const AInstance: IUnknown; const AIntf: TGUID; out AInst): Boolean;
begin
  result := (AInstance <> nil) and Supports(AInstance, AIntf, AInst);
end;

function GetEditBuffer: IOTAEditBuffer;
var
  LEditorServices: IOTAEditorServices;
begin
  QuerySvcs(BorlandIDEServices, IOTAEditorServices, LEditorServices);

  if LEditorServices = nil then
    Exit(nil);

  result := LEditorServices.GetTopBuffer;
end;

function GetHistoryServices: IOTAHistoryServices;
begin
  QuerySvcs(BorlandIDEServices, IOTAHistoryServices, result);
end;

function GetEditActions: IOTAEditActions60;
var
  LEditorServices: IOTAEditorServices;
  topView: IOTAEditView;
begin
  QuerySvcs(BorlandIDEServices, IOTAEditorServices, LEditorServices);

  if LEditorServices = nil then
    Exit(nil);

  topView := LEditorServices.TopView;

  if topView = nil then
    Exit(nil);

  result := topView as IOTAEditActions60;
end;

function GetEditPosition(ABuffer: IOTAEditBuffer): IOTAEditPosition;
begin
  result := nil;

  if ABuffer <> nil then
    result := ABuffer.GetEditPosition;
end;

function GetSourceEditorFromModule(aModule: IOTAModule; const fileName: string): IOTASourceEditor;
var
  i: Integer;
  aEditor: IOTAEditor;
  aSourceEditor: IOTASourceEditor;
begin
  if not Assigned(aModule) then
    Exit(nil);

  for i := 0 to aModule.GetModuleFileCount - 1 do
  begin
    aEditor := GetFileEditorForModule(aModule, i);

    if not Supports(aEditor, IOTASourceEditor, aSourceEditor) then
      Continue;

    if not Assigned(aSourceEditor) then
      Continue;

    if (fileName = '') or SameFileName(aSourceEditor.FileName, fileName) then
      Exit(aSourceEditor);
  end;

  result := nil;
end;

function GetFileEditorForModule(aModule: IOTAModule; index: Integer): IOTAEditor;
begin
  result := nil;

  if not Assigned(aModule) then
    Exit;

  try
    Result := aModule.GetModuleFileEditor(index);
  except
    Result := nil;
  end;
end;

// I have not been able to find a force close that works for the currently opened file, it always raises an exception
procedure CloseEditView(aModule: IOTAModule; forceClose: boolean);
var
  sourceEditor: IOTASourceEditor;
  editView: IOTAEditView;
begin
  sourceEditor := GetSourceEditorFromModule(aModule);

  if sourceEditor = nil then
    Exit;

  editView := GetTopMostEditView(sourceEditor);

  if editView = nil then
    Exit;

  sourceEditor.Show;
  ClosePage(editView);
end;

function GetTopMostEditView(sourceEditor: IOTASourceEditor): IOTAEditView;
var
  editBuffer: IOTAEditBuffer;
begin
  if sourceEditor = nil then
    sourceEditor := GetCurrentSourceEditor;

  if sourceEditor = nil then
    Exit(nil);

  QuerySvcs(sourceEditor, IOTAEditBuffer, editBuffer);

  if editBuffer <> nil then
    Exit(editBuffer.TopView)
  else if sourceEditor.EditViewCount > 0 then
    Exit(sourceEditor.EditViews[0]);
end;

function GetCurrentSourceEditor: IOTASourceEditor;
var
  editBuffer: IOTAEditBuffer;
begin
  editBuffer := GetEditBuffer;

  if Assigned(editBuffer) and (editBuffer.FileName <> '') then
    Result := GetSourceEditorFromModule(GetCurrentModule, editBuffer.FileName);

  if Result = nil then
    Result := GetSourceEditorFromModule(GetCurrentModule);
end;

function GetCurrentModule: IOTAModule;
var
  iModuleServices: IOTAModuleServices;
begin
  QuerySvcs(BorlandIDEServices, IOTAModuleServices, iModuleServices);

  if iModuleServices = nil then
    Exit(nil);

  Result := iModuleServices.CurrentModule;
end;

procedure ClosePage(editView: IOTAEditView);
var
  editActions: IOTAEditActions;
begin
  if not Assigned(editView) then
    Exit;

  QuerySvcs(editView, IOTAEditActions, editActions);

  if Assigned(editActions) then
    editActions.ClosePage;
end;

function IsModuleModified(aModule: IOTAModule): Boolean;
var
  i: Integer;
begin
  Result := False;

  for i := 0 to aModule.GetModuleFileCount - 1 do
  begin
    if aModule.GetModuleFileEditor(i).Modified then
      Exit(True);
  end;
end;

end.
