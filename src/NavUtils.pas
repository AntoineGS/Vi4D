unit NavUtils;

interface

uses
  ToolsAPI;

function QuerySvcs(const AInstance: IUnknown; const AIntf: TGUID; out AInst): Boolean;
function GetEditBuffer: IOTAEditBuffer;
function GetEditPosition(ABuffer: IOTAEditBuffer): IOTAEditPosition;

implementation

uses
  SysUtils;

function QuerySvcs(const AInstance: IUnknown; const AIntf: TGUID; out AInst): Boolean;
begin
  result := (AInstance <> nil) and Supports(AInstance, AIntf, AInst);
end;

function GetEditBuffer: IOTAEditBuffer;
var
  LEditorServices: IOTAEditorServices;
begin
  QuerySvcs(BorlandIDEServices, IOTAEditorServices, LEditorServices);
  if LEditorServices <> nil then
  begin
    result := LEditorServices.GetTopBuffer;
    Exit;
  end;
  result := nil;
end;

function GetEditPosition(ABuffer: IOTAEditBuffer): IOTAEditPosition;
begin
  result := nil;
  if ABuffer <> nil then
    result := ABuffer.GetEditPosition;
end;

end.
