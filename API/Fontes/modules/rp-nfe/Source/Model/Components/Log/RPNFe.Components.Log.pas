unit RPNFe.Components.Log;

interface

uses
  System.SysUtils;

type
  TRPNFeComponentsLog = class
  private
    FOnLog: TProc<string>;
  public
    function OnLog(AValue: TProc<string>): TRPNFeComponentsLog;
    function Write(ALog: string): TRPNFeComponentsLog; overload;
    function Write(ALog: string; const AArgs: array of const): TRPNFeComponentsLog; overload;
    function Write(AError: Exception): TRPNFeComponentsLog; overload;
  end;

implementation

{ TRPNFeComponentsLog }

function TRPNFeComponentsLog.Write(ALog: string): TRPNFeComponentsLog;
var
  LLog: string;
begin
  Result := Self;
  if Assigned(FOnLog) then
  begin
    LLog := Format('%s: %s', [FormatDateTime('yyyyMMdd hh:mm:ss:zzz', Now), ALog]);
    FOnLog(LLog);
  end;
end;

function TRPNFeComponentsLog.Write(ALog: string; const AArgs: array of const): TRPNFeComponentsLog;
begin
  Result := Self;
  Write(Format(ALog, AArgs));
end;

function TRPNFeComponentsLog.OnLog(AValue: TProc<string>): TRPNFeComponentsLog;
begin
  Result := Self;
  FOnLog := AValue;
end;

function TRPNFeComponentsLog.Write(AError: Exception): TRPNFeComponentsLog;
begin
  Result := Self;
  Write('ERROR: ' + AError.Message);
end;

end.
