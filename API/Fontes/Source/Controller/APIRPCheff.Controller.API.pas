unit APIRPCheff.Controller.API;

interface

uses
  APIRPCheff.Resources,
  APIRPCheff.Entity.Classes,
  Horse,
  Horse.CORS,
  Horse.Jhonson,
  Horse.BasicAuthentication,
  Horse.Compression,
  Horse.HandleException,
  Horse.OctetStream,
  Horse.GBSwagger,
  Horse.Etag,
  System.SysUtils,
  System.SyncObjs;

procedure CreateServer;
procedure StartServer;
procedure StopServer;
function ServiceRunning: Boolean;

implementation

var
  ServerLock: TObject;

function ServiceRunning: Boolean;
begin
  Result := THorse.IsRunning;
end;

function Prefix: string;
begin
  Result := '/rpCheff/v1/';
end;

procedure CreateServer;
begin
  THorse.MaxConnections := 5000;
  THorseOctetStreamConfig.GetInstance.AcceptContentType.Add('application/json');
  THorseOctetStreamConfig.GetInstance.AcceptContentType.Add('text/plain');

  THorse.Use(CORS)
    .Use(ETag)
    .Use(HorseSwagger)
    .Use(Compression())
    .Use(OctetStream)
    .Use(Jhonson)
    .Use(HandleException);

  THorse.Get(Prefix + 'ping',
    procedure(ARes: THorseResponse)
    begin
      ARes.Send('Online');
    end);
end;

procedure StartServer;
begin
  TMonitor.Enter(ServerLock);
  try
    if THorse.IsRunning then
      Exit;

    THorse.Listen(APP_RESOURCES.API_PORT);
  finally
    TMonitor.Exit(ServerLock);
  end;
end;

procedure StopServer;
begin
  TMonitor.Enter(ServerLock);
  try
    if THorse.IsRunning then
    begin
      try
        THorse.StopListen;
      except
        on E: Exception do
          raise Exception.Create('Erro ao parar o servidor:' + E.Message);
      end;
    end;
  finally
    TMonitor.Exit(ServerLock);
  end;
end;

initialization
  ServerLock := TObject.Create;

  Swagger.Version('2.0')
    .AddProtocol(TGBSwaggerProtocol.gbHttp)
    .BasePath(Prefix)
    .Info.Title('RP Cheff')
      .Description('API RPCheff - RP Sistemas');

  Swagger.Config
      .ClassPrefixes('TAPIRPCheffEntity')
    .&End
    .&Register
      .SchemaOnError(TAPIRPCheffEntityError);

  Swagger.AddBasicSecurity
    .AddCallback(HorseBasicAuthentication(
      function(const AUsername, APassword: string): Boolean
      begin
        Result := AUsername.Equals(APP_RESOURCES.AUTH_USERNAME) and
          APassword.Equals(APP_RESOURCES.AUTH_PASSWORD);
      end, THorseBasicAuthenticationConfig.New.SkipRoutes([Prefix + 'ping'])));

finalization
  FreeAndNil(ServerLock);
end.
