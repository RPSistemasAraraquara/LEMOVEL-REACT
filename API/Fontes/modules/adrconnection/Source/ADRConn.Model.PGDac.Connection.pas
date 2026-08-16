unit ADRConn.Model.PgDAC.Connection;

interface

uses
  ADRConn.Model.Interfaces,
  ADRConn.Model.Events,
  ADRConn.Model.Params,
  System.Classes,
  System.SysUtils,
  Data.DB,
  MemDS,
  DBAccess,
  PgAccess;

type
  TADRConnModelPgDACConnection = class(TInterfacedObject, IADRConnection)
  private
    FOwner: Boolean;
    FConnection: TPgConnection;
    FEvents: IADRConnectionEvents;
    FParams: IADRConnectionParams;

    procedure Setup;
    function TryHandleException(AException: Exception): Boolean;
  protected
    function Events: IADRConnectionEvents;
    function Connection: TCustomConnection;
    function Component: TComponent;

    function Params: IADRConnectionParams;

    function Connected: Boolean;
    function Connect: IADRConnection;
    function Disconnect: IADRConnection;
    function StartTransaction: IADRConnection;
    function Commit: IADRConnection;
    function Rollback: IADRConnection;
    function InTransaction: Boolean;
  public
    constructor Create; overload;
    class function New: IADRConnection; overload;
    constructor Create(AComponent: TComponent); overload;
    class function New(AComponent: TComponent): IADRConnection; overload;
    destructor Destroy; override;
  end;

// Diagnostico de travamentos: registra transacoes e SQLs em Bin\adrconn.log
// (timestamp + thread). Falha de log nunca interrompe o fluxo.
procedure ADRConnLog(const AMensagem: string);

implementation

uses
  System.IOUtils,
  System.SyncObjs;

var
  GADRConnLogLock: TCriticalSection;
  GADRConnLogAtivo: Boolean;

procedure ADRConnLog(const AMensagem: string);
begin
  // Diagnostico sob demanda: ligar com a variavel de ambiente ADRCONN_LOG=1.
  // Desligado por padrao - o append serializado por lock em todo SQL custa
  // latencia e o adrconn.log crescia sem limite em producao.
  if not GADRConnLogAtivo then
    Exit;
  try
    GADRConnLogLock.Enter;
    try
      TFile.AppendAllText(ExtractFilePath(ParamStr(0)) + 'adrconn.log',
        FormatDateTime('hh:nn:ss.zzz', Now) + ' [' +
        IntToStr(TThread.Current.ThreadID) + '] ' + AMensagem + sLineBreak,
        TEncoding.ANSI);
    finally
      GADRConnLogLock.Leave;
    end;
  except
  end;
end;

{ TADRConnModelPgDACConnection }

function TADRConnModelPgDACConnection.Commit: IADRConnection;
begin
  Result := Self;
  ADRConnLog('Commit inicio');
  FConnection.Commit;
  ADRConnLog('Commit fim');
end;

function TADRConnModelPgDACConnection.Component: TComponent;
begin
  Result := FConnection;
end;

function TADRConnModelPgDACConnection.Connect: IADRConnection;
begin
  Result := Self;
  try
    if not FConnection.Connected then
    begin
      if FOwner then
        Setup;
      FConnection.Connected := True;
    end;
  except
    on E: Exception do
    begin
      if not TryHandleException(E) then
        raise;
    end;
  end;
end;

function TADRConnModelPgDACConnection.Connected: Boolean;
begin
  Result := (Assigned(FConnection)) and (FConnection.Connected);
end;

function TADRConnModelPgDACConnection.Connection: TCustomConnection;
begin
  Result := FConnection;
end;

constructor TADRConnModelPgDACConnection.Create(AComponent: TComponent);
begin
  FOwner := False;
  FConnection := TPgConnection(AComponent);
  FParams := TADRConnModelParams.New(Self);
end;

constructor TADRConnModelPgDACConnection.Create;
begin
  FOwner := True;
  FConnection := TPgConnection.Create(nil);
  FParams := TADRConnModelParams.New(Self);
end;

destructor TADRConnModelPgDACConnection.Destroy;
begin
  if FOwner then
    FConnection.Free;
  inherited;
end;

function TADRConnModelPgDACConnection.Disconnect: IADRConnection;
begin
  Result := Self;
  FConnection.Connected := False;
end;

function TADRConnModelPgDACConnection.Events: IADRConnectionEvents;
begin
  if not Assigned(FEvents) then
    FEvents := TADRConnConnectionModelEvents.New;
  Result := FEvents;
end;

function TADRConnModelPgDACConnection.InTransaction: Boolean;
begin
  Result := FConnection.InTransaction;
end;

class function TADRConnModelPgDACConnection.New(AComponent: TComponent): IADRConnection;
begin
  Result := Self.Create(AComponent);
end;

class function TADRConnModelPgDACConnection.New: IADRConnection;
begin
  Result := Self.Create;
end;

function TADRConnModelPgDACConnection.Params: IADRConnectionParams;
begin
  Result := FParams;
end;

function TADRConnModelPgDACConnection.Rollback: IADRConnection;
begin
  Result := Self;
  ADRConnLog('Rollback inicio');
  FConnection.Rollback;
  ADRConnLog('Rollback fim');
end;

procedure TADRConnModelPgDACConnection.Setup;
var
  LParams: TArray<string>;
  LName: string;
  LValue: string;
begin
  FConnection.Database := FParams.Database;
  FConnection.Username := FParams.UserName;
  FConnection.Password := FParams.Password;
  FConnection.Server := FParams.Server;
  FConnection.Port := FParams.Port;
  FConnection.Schema := FParams.Schema;

  LParams := FParams.ParamNames;
  for LName in LParams do
  begin
    LValue := FParams.ParamByName(LName);
    FConnection.ParamByName(LName).Value := LValue;
  end;
end;

function TADRConnModelPgDACConnection.StartTransaction: IADRConnection;
begin
  Result := Self;
  ADRConnLog('StartTransaction inicio');
  FConnection.StartTransaction;
  ADRConnLog('StartTransaction fim');
end;

function TADRConnModelPgDACConnection.TryHandleException(AException: Exception): Boolean;
begin
  Result := Events.HandleException(AException);
end;

initialization
  GADRConnLogLock := TCriticalSection.Create;
  GADRConnLogAtivo := GetEnvironmentVariable('ADRCONN_LOG') = '1';

// RP fix: a critical section NAO e liberada de proposito. Threads do Horse
// podem chamar ADRConnLog durante o shutdown, depois da finalization desta
// unit - Enter numa section destruida e ponteiro solto (trava/corrompe o
// encerramento). O "leak" de 1 objeto no exit e inocuo: o SO recolhe tudo.

end.
