unit Engine.Common;

interface

uses
  Commands.Base;

type
  TCommandChangedProc = reference to procedure(aCommand: string);
  TModeChangedProc = reference to procedure(aMode: TViMode);
  TResetOperationProc = reference to procedure;

implementation

end.
