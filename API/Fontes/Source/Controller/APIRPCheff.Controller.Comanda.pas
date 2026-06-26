unit APIRPCheff.Controller.Comanda;

interface

uses
  APIRPCheff.Controller.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Horse.GBSwagger.Registry,
  GBSwagger.Path.Attributes,
  GBSwagger.Validator.Interfaces,
  System.Generics.Collections,
  System.SysUtils;

type
  [SwagPath('empresa/{idEmpresa}/comanda', 'Comanda')]
  [SwagParamPath('idEmpresa', 'Id da empresa')]
  TAPIRPCheffControllerComanda = class(TAPIRPCheffControllerBase)
  public
    [SwagGET('Listar Comandas')]
    [SwagParamQuery('situacaoVenda', 'SituacaoVenda', SituacaoVendaNames)]
    [SwagParamHeader('prePago', 'Informar true se estiver buscando os pr'#233' pagos')]
    [SwagResponse(200, TAPIRPCheffEntityComanda, True)]
    procedure Listar;

    [SwagGET('{idComanda}', 'Buscar Comanda')]
    [SwagParamPath('idComanda', 'identifica'#231#227'o da comanda')]
    [SwagResponse(200, TAPIRPCheffEntityComanda)]
    procedure BuscarComanda;

    [SwagPOST('{idComanda}/abertura', 'Abrir Comanda')]
    [SwagParamPath('idComanda', 'identifica'#231#227'o da comanda')]
    [SwagParamHeader('usaCatraca', 'Determina se usa catraca', False)]
    [SwagParamBody('abertura', TAPIRPCheffEntityVendaPostAbertura)]
    [SwagResponse(201, TAPIRPCheffEntityComanda)]
    [SwagResponse(400)]
    procedure AbrirComanda;

    [SwagPOST('{idComanda}/transferencia/{idComandaDestino}', 'Transferir Comanda')]
    [SwagParamPath('idComanda', 'identifica'#231#227'o da comanda origem')]
    [SwagParamPath('idComandaDestino', 'identifica'#231#227'o da comanda destino')]
    [SwagResponse(204)]
    [SwagResponse(400)]
    [SwagResponse(403)]
    procedure Transferir;
  end;

implementation

{ TAPIRPCheffControllerComanda }

procedure TAPIRPCheffControllerComanda.AbrirComanda;
var
  LAbertura: TAPIRPCheffEntityVendaPostAbertura;
  LComanda: TAPIRPCheffEntityComanda;
  LUsaCatraca: Boolean;
begin
  LAbertura := Self.FromJSONObject<TAPIRPCheffEntityVendaPostAbertura>;
  try
    LAbertura.idEmpresa := IdEmpresa;
    LAbertura.idMesaComanda := FRequest.Params.Field('idComanda').AsInteger;
    LUsaCatraca := FRequest.Headers.Field('usaCatraca').AsBoolean;
    LComanda := Controller.Service.ComandaAberturaService
      .IdUsuario(IdUsuario)
      .Abertura(LAbertura)
      .UsaCatraca(LUsaCatraca)
      .Execute;
    try
      Self.Response(LComanda);
    finally
      FreeAndNil(LComanda);
    end;
  finally
    FreeAndNil(LAbertura);
  end;
end;

procedure TAPIRPCheffControllerComanda.BuscarComanda;
var
  LIdComanda: Integer;
  LComanda: TAPIRPCheffEntityComanda;
begin
  LIdComanda := FRequest.Params.Field('idComanda').AsInteger;
  LComanda := Controller.Service.ComandaConsultaService.Consultar(LIdComanda);
  try
    Response(LComanda, Format('Comanda %d N'#227'o encontrada.', [LIdComanda]));
  finally
    FreeAndNil(LComanda);
  end;
end;

procedure TAPIRPCheffControllerComanda.Listar;
var
  LComandas: TObjectList<TAPIRPCheffEntityComanda>;
  LSituacao: TRPCheffSituacaoVenda;
  LPrePago: Boolean;
begin
  if FRequest.Query.ContainsKey('situacaoVenda') then
  begin
    LSituacao := TRPCheffSituacaoVenda(TEnumUtils<TRPCheffSituacaoVenda>
      .EnumValue(FRequest.Query.Field('situacaoVenda').AsString));
    LComandas := Controller.Service
      .ComandaConsultaService.ListarPorSituacao(LSituacao);
  end
  else
  begin
    LPrePago := FRequest.Headers.Field('prePago').AsBoolean;
    if LPrePago then
      LComandas := Controller.Service.ComandaConsultaService.ListarPrePago
    else
      LComandas := Controller.Service.ComandaConsultaService.Listar;
  end;
  try
    Self.Response<TAPIRPCheffEntityComanda>(LComandas);
  finally
    FreeAndNil(LComandas);
  end;
end;

procedure TAPIRPCheffControllerComanda.Transferir;
var
  LIdComandaOrigem: Integer;
  LIdComandaDestino: Integer;
begin
  LIdComandaOrigem := FRequest.Params.Field('idComanda').AsInteger;
  LIdComandaDestino := FRequest.Params.Field('idComandaDestino').AsInteger;
  ValidarPermissaoTransferenciaMesa;
  Controller.Service.ComandaTransferenciaService
    .IdComandaOrigem(LIdComandaOrigem)
    .IdComandaDestino(LIdComandaDestino)
    .Execute;
  FResponse.Status(204);
end;

initialization
  THorseGBSwaggerRegistry.RegisterPath(TAPIRPCheffControllerComanda);

end.
