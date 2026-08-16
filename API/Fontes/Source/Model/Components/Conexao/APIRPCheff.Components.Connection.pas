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
  // Sanitiza antes de devolver ao pool: transacao aberta/abortada deixada por
  // um fluxo com erro NAO pode vazar para o proximo dono da conexao.
  if Assigned(FConnection) then
  try
    if FConnection.Connected and FConnection.InTransaction then
      FConnection.Rollback;
  except
  end;

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

    // O item ja vem ADQUIRIDO do pool (TryGetItem incrementa o RefCount de
    // forma atomica); Instance apenas le, sem incrementar de novo.
    LPoolConnection := FPoolItem.Instance;
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

    // Defesa em profundidade: se um dono anterior vazou transacao, encerra
    // antes de entregar a conexao a esta requisicao.
    try
      if FConnection.Connected and FConnection.InTransaction then
        FConnection.Rollback;
    except
    end;
  end;
  Result := FConnection;
end;

initialization
  // MaxIdleSeconds ENORME de proposito: a thread de limpeza do PoolManager
  // destruia conexoes ociosas ha 30s+ na janela entre GetPoolItem (que escolhe
  // um item com RefCount=0) e o Acquire (que incrementa o RefCount) - o worker
  // ficava com uma conexao morta e congelava no primeiro SQL ("idle in
  // transaction" no Postgres), esgotando o pool e derrubando a API inteira.
  // Com o Postgres local, manter as conexoes abertas nao custa nada.
  TADRConnectionPoolBuilder.New
    .MaxIdleSeconds(31536000)
    .MinPoolCount(3)
    .OnGetConnection(CreateConnection)
    .Build;

end.
