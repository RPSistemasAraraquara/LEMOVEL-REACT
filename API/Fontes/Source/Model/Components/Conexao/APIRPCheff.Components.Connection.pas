unit APIRPCheff.Components.Connection;

interface

uses
  ADRConn.Model.Interfaces,
  ADRConnection.Pool,
  System.SysUtils,
  PoolManager,
  APIRPCheff.Resources;

type
  TAPIRPCheffComponentConnection = class
  private
    FConnection: IADRConnection;
    FPoolItem: TPoolItem<TADRConnectionPoolItem>;
  public
    destructor Destroy; override;
    function GetConnection: IADRConnection;
  end;

function CreateConnection: IADRConnection;

implementation

function CreateConnection: IADRConnection;
begin
  try
    Result := ADRConn.Model.Interfaces.CreateConnection;
    Result.Params
      .Driver(adrPostgres)
      .Server(APP_RESOURCES.DATABASE_HOST)
      .Database(APP_RESOURCES.DATABASE_ALIAS)
      .UserName(APP_RESOURCES.DATABASE_USERNAME)
      .Password(APP_RESOURCES.DATABASE_PASSWORD)
      .Schema(APP_RESOURCES.DATABASE_SCHEMA)
      .Port(APP_RESOURCES.DATABASE_PORT);

    Result.Connect;
  except
    on E: Exception do
    begin
      E.Message := 'Erro ao tentar conectar na base de dados. Verifique as configura'#231#245'es no servidor: ' +
        E.Message;
      raise;
    end;
  end;
end;

{ TAPIRPCheffComponentConnection }

destructor TAPIRPCheffComponentConnection.Destroy;
begin
  if Assigned(FPoolItem) then
    FPoolItem.Release;
  inherited;
end;

function TAPIRPCheffComponentConnection.GetConnection: IADRConnection;
var
  LPoolConnection: TADRConnectionPoolItem;
begin
  if not Assigned(FConnection) then
  begin
    if not Assigned(FPoolItem) then
      FPoolItem := GetPoolItem;

    LPoolConnection := FPoolItem.Acquire;
    FConnection := LPoolConnection.Connection;
    if not FConnection.Connected then
    try
      FConnection.Connect;
    except
      on E: Exception do
      begin
        E.Message := 'Erro ao tentar conectar na base de dados. Verifique as configura'#231#245'es no servidor: ' +
          E.Message;
        raise;
      end;
    end;
  end;
  Result := FConnection;
end;

initialization
  TADRConnectionPoolBuilder.New
    .MaxIdleSeconds(30)
    .MinPoolCount(3)
    .OnGetConnection(CreateConnection)
    .Build;

end.
