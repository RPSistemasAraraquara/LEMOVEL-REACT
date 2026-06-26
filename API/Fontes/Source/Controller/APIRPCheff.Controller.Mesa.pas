unit APIRPCheff.Controller.Mesa;

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
  [SwagPath('empresa/{idEmpresa}/mesa', 'Mesa')]
  [SwagParamPath('idEmpresa', 'Id da empresa')]
  TAPIRPCheffControllerMesa = class(TAPIRPCheffControllerBase)
  public
    //[SwagGET('Listar Mesas')]
    [SwagGET('', 'Listar Mesas')]
    [SwagParamQuery('situacaoVenda', 'SituacaoVenda', SituacaoVendaNames)]
    [SwagResponse(200, TAPIRPCheffEntityMesa, True)]
    procedure Listar;

    [SwagGET('{idMesa}', 'Buscar Mesa')]
    [SwagParamPath('idMesa', 'identifica'#231#227'o da mesa')]
    [SwagResponse(200, TAPIRPCheffEntityMesa)]
    procedure BuscarMesa;

    [SwagPOST('{idMesa}/abertura', 'Abrir Mesa')]
    [SwagParamPath('idMesa', 'identifica'#231#227'o da mesa')]
    [SwagParamBody('abertura', TAPIRPCheffEntityVendaPostAbertura)]
    [SwagResponse(201, TAPIRPCheffEntityMesa)]
    [SwagResponse(400)]
    procedure AbrirMesa;

    [SwagPOST('{idMesa}/transferencia/{idMesaDestino}', 'Transferir Mesa')]
    [SwagParamPath('idMesa', 'identifica'#231#227'o da mesa origem')]
    [SwagParamPath('idMesaDestino', 'identifica'#231#227'o da mesa destino')]
    [SwagResponse(204)]
    [SwagResponse(400)]
    [SwagResponse(403)]
    procedure Transferir;
  end;

implementation

{ TAPIRPCheffControllerMesa }

procedure TAPIRPCheffControllerMesa.AbrirMesa;
var
  LAbertura: TAPIRPCheffEntityVendaPostAbertura;
  LMesa: TAPIRPCheffEntityMesa;
begin
  LAbertura := Self.FromJSONObject<TAPIRPCheffEntityVendaPostAbertura>;
  try
    LAbertura.idEmpresa := IdEmpresa;
    LAbertura.idMesaComanda := FRequest.Params.Field('idMesa').AsInteger;
    LMesa := Controller.Service.MesaAberturaService
      .IdUsuario(IdUsuario)
      .Abertura(LAbertura)
      .Execute;
    try
      Self.Response(LMesa);
    finally
      FreeAndNil(LMesa);
    end;
  finally
    FreeAndNil(LAbertura);
  end;
end;

procedure TAPIRPCheffControllerMesa.BuscarMesa;
var
  LIdMesa: Integer;
  LMesa: TAPIRPCheffEntityMesa;
begin
  LIdMesa := FRequest.Params.Field('idMesa').AsInteger;
  LMesa := Controller.Service.MesaConsultaService.Consultar(LIdMesa);
  try
    Response(LMesa, Format('Mesa %d N'#227'o encontrada.', [LIdMesa]));
  finally
    FreeAndNil(LMesa);
  end;
end;

procedure TAPIRPCheffControllerMesa.Listar;
var
  LMesas: TObjectList<TAPIRPCheffEntityMesa>;
  LSituacao: TRPCheffSituacaoVenda;
begin
  if FRequest.Query.ContainsKey('situacaoVenda') then
  begin
    LSituacao := TRPCheffSituacaoVenda(TEnumUtils<TRPCheffSituacaoVenda>
      .EnumValue(FRequest.Query.Field('situacaoVenda').AsString));
    LMesas := Controller.Service
      .MesaConsultaService.ListarPorSituacao(LSituacao);
  end
  else
    LMesas := Controller.Service
      .MesaConsultaService.Listar;
  try
    Self.Response<TAPIRPCheffEntityMesa>(LMesas);
  finally
    FreeAndNil(LMesas);
  end;
end;

procedure TAPIRPCheffControllerMesa.Transferir;
var
  LIdMesaOrigem: Integer;
  LIdMesaDestino: Integer;
begin
  LIdMesaOrigem := FRequest.Params.Field('idMesa').AsInteger;
  LIdMesaDestino := FRequest.Params.Field('idMesaDestino').AsInteger;
  ValidarPermissaoTransferenciaMesa;
  Controller.Service.MesaTransferenciaService
    .IdMesaOrigem(LIdMesaOrigem)
    .IdMesaDestino(LIdMesaDestino)
    .Execute;
  FResponse.Status(204);
end;

initialization
  THorseGBSwaggerRegistry.RegisterPath(TAPIRPCheffControllerMesa);

end.
