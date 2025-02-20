unit Commands.Ex;

interface

uses
  Commands.Base;

type
  TEx = class(TCommand)
  public
    procedure Execute; virtual;
  end;

  TExClass = class of TEx;

  TExSaveFile = class(TEx)
    procedure Execute; override;
  end;

  TExSaveAllFiles = class(TEx)
    procedure Execute; override;
  end;

  TExSaveAndCloseFile = class(TEx)
    procedure Execute; override;
  end;

  TExSaveAndCloseAllFiles = class(TEx)
    procedure Execute; override;
  end;

  TExCloseFile = class(TEx)
    procedure Execute; override;
  end;

  TExCloseAllFiles = class(TEx)
    procedure Execute; override;
  end;

  TExForceCloseFile = class(TEx)
    procedure Execute; override;
  end;

  TExForceCloseAllFiles = class(TEx)
    procedure Execute; override;
  end;

implementation

uses
  NavUtils, ToolsAPI, SysUtils, classes;

{ TEditionSaveFile }

procedure TExSaveFile.Execute;
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  aBuffer := GetEditBuffer;

  if aBuffer.IsModified then
    aBuffer.Module.Save(False, True);
end;

{ TEditionCloseFile }

procedure TExCloseFile.Execute;
var
  aBuffer: IOTAEditBuffer;
begin
  inherited;
  aBuffer := GetEditBuffer;

  if aBuffer.IsModified then
    raise Exception.Create('File has pending changes, use :w to save changes or :q! to close without saving');

  ClosePage(aBuffer.TopView);
end;

{ TExCommand }

procedure TEx.Execute;
begin
  // does nothing for now
end;

{ TExForceCloseFile }

procedure TExForceCloseFile.Execute;
begin
  inherited;
  CloseEditView(GetCurrentModule, True);
end;

{ TExSaveAndCloseFile }

procedure TExSaveAndCloseFile.Execute;
var
  aExCloseFile: TExCloseFile;
  aExSaveFile: TExSaveFile;
begin
  inherited;

  aExCloseFile := nil;
  aExSaveFile := TExSaveFile.Create(FClipboard, FEngine);
  try
    aExCloseFile := TExCloseFile.Create(FClipboard, FEngine);
    aExSaveFile.Execute;
    aExCloseFile.Execute;
  finally
    aExSaveFile.Free;
    aExCloseFile.Free;
  end;
end;

{ TExSaveAllFiles }

procedure TExSaveAllFiles.Execute;
var
  LEditorServices: IOTAEditorServices;
  aEditBufferIterator: IOTAEditBufferIterator;
  aBuffer: IOTAEditBuffer;
  i: Integer;
begin
  QuerySvcs(BorlandIDEServices, IOTAEditorServices, LEditorServices);

  if LEditorServices = nil then
    Exit;

  if not LEditorServices.GetEditBufferIterator(aEditBufferIterator) then
    exit;

  for i := 0 to aEditBufferIterator.Count - 1 do
  begin
    aBuffer := aEditBufferIterator.EditBuffers[i];

    if aBuffer.IsModified then
      aBuffer.Module.Save(False, True);
  end;
end;

{ TExSaveAndCloseAllFiles }

procedure TExSaveAndCloseAllFiles.Execute;
var
  aExSaveAllFiles: TExSaveAllFiles;
  aExCloseAllFiles: TExCloseAllFiles;
begin
  inherited;

  aExCloseAllFiles := nil;
  aExSaveAllFiles := TExSaveAllFiles.Create(FClipboard, FEngine);
  try
    aExCloseAllFiles := TExCloseAllFiles.Create(FClipboard, FEngine);
    aExSaveAllFiles.Execute;
    aExCloseAllFiles.Execute;
  finally
    aExSaveAllFiles.Free;
    aExCloseAllFiles.Free;
  end;
end;

procedure CloseAllFiles(forceClose: boolean);
var
  moduleSvcs: IOTAModuleServices;
  i: Integer;
  module: IOTAModule;
  project: IOTAProject;
  group: IOTAProjectGroup;
  list: TList;
  projectList: TList;
  currModule: IOTAModule;
begin
  QuerySvcs(BorlandIDEServices, IOTAModuleServices, moduleSvcs);

  if moduleSvcs = nil then
    Exit;

  list := nil;
  projectList := TList.Create;
  try
    list := TList.Create;
    currModule := GetCurrentModule;

    for i := moduleSvcs.ModuleCount - 1 downto 0 do
    begin
      module := moduleSvcs.Modules[i];

      if Supports(module, IOTAProject, project) then
        projectList.Add(Pointer(module))
      else if Supports(module, IOTAProjectGroup, group) or (module = currModule) then
        projectList.Add(Pointer(module))
      else if module.FileName <> 'default.htm' then
        list.Add(Pointer(module));
    end;

    module := nil;

    for i := 0 to list.Count - 1 do
      IOTAModule(list[i]).CloseModule(forceClose);

    for i := 0 to projectList.Count - 1 do
    begin
      module := IOTAModule(projectList[i]);
      CloseEditView(module, forceClose);
    end;
  finally
    list.Free;
    projectList.Free;
  end;
end;

{ TExCloseAllFiles }

procedure TExCloseAllFiles.Execute;
begin
  CloseAllFiles(False);
end;

{ TExForceCloseAllFiles }

procedure TExForceCloseAllFiles.Execute;
begin
  CloseAllFiles(True);
end;

end.
