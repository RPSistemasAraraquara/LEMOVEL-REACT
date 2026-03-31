unit APIRPCheff.Controller.VendaItem;

interface

uses
  APIRPCheff.Controller.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Service.Venda.LancarItem,
  Horse.GBSwagger.Registry,
  GBSwagger.Path.Attributes,
  GBSwagger.Validator.Interfaces,
  System.Generics.Collections,
  System.SysUtils;

type
  [SwagPath('empresa/{idEmpresa}/venda/{idVenda}/item', 'Venda Item')]
  [SwagParamPath('idEmpresa', 'Id da empresa')]
  [SwagParamPath('idVenda', 'Id da Venda')]
  TAPIRPCheffControllerVendaItem = class(TAPIRPCheffControllerBase)
  public
    [SwagGET('Listar itens da venda')]
    [SwagParamPath('idVenda', 'Id da Venda')]
    [SwagResponse(200, TAPIRPCheffEntityVendaItem, True)]
    procedure ListarItens;

    [SwagPOST('lan'#231'ar Item')]
    [SwagParamBody('item', TAPIRPCheffEntityVendaItem)]
    [SwagResponse(201, TAPIRPCheffEntityVendaItem)]
    [SwagResponse(400)]
    [SwagResponse(409)]
    procedure LancarItem;

    [SwagPOST('lote', 'Lan'#231'ar Itens em Lote')]
    [SwagParamBody('itens', TAPIRPCheffEntityVendaItem, True)]
    [SwagResponse(201)]
    [SwagResponse(400)]
    [SwagResponse(409)]
    procedure LancarItens;

    [SwagDELETE('{numeroItem}', 'Cancelar Item da Venda')]
    [SwagParamPath('numeroItem', 'Numero do item')]
    [SwagParamBody('cancelamento', TAPIRPCheffEntityVendaItemCancelamento)]
    [SwagResponse(204)]
    procedure CancelarItem;

    [SwagGET('taxa-garcom-total', 'Total dos itens sujeitos '#224' taxa do Gar'#231'om')]
    [SwagResponse(200)]
    procedure TotalTaxaGarcom;

  end;

implementation

{ TAPIRPCheffControllerVendaItem }

procedure TAPIRPCheffControllerVendaItem.CancelarItem;
var
  LCancelamento: TAPIRPCheffEntityVendaItemCancelamento;
begin
  LCancelamento                 := Self.FromJSONObject<TAPIRPCheffEntityVendaItemCancelamento>;
  try
    LCancelamento.idEmpresa     := IdEmpresa;
    LCancelamento.idVenda       := FRequest.Params.Field('idVenda').AsInteger;
    LCancelamento.numeroItem    := FRequest.Params.Field('numeroItem').AsInteger;
    Controller.Service.VendaCancelarItemService.Cancelamento(LCancelamento).Execute;
    FResponse.Status(204);
  finally
    FreeAndNil(LCancelamento);
  end;
end;

procedure TAPIRPCheffControllerVendaItem.LancarItem;
var
  LItem: TAPIRPCheffEntityVendaItem;
  LIdUsuarioHeader: Integer;
begin
  if not FRequest.Params.ContainsKey('idVenda') then
    Exit;

  LItem := Self.FromJSONObject<TAPIRPCheffEntityVendaItem>;
  try
    LItem.idEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
    LItem.idVenda   := FRequest.Params.Field('idVenda').AsInteger;
    LIdUsuarioHeader := Self.IdUsuario;
    if LIdUsuarioHeader > 0 then
      LItem.idGarcom := LIdUsuarioHeader;

    try
      Controller.Service.VendaLancarItemService.Item(LItem).Execute;
    except
      on E: EConflictError do
      begin
        FResponse.Status(409);
        raise;
      end;
    end;
    Response(LItem);
    FResponse.Status(201);
  finally
    FreeAndNil(LItem);
  end;
end;

procedure TAPIRPCheffControllerVendaItem.LancarItens;
var
  LItens: TObjectList<TAPIRPCheffEntityVendaItem>;
  LItem: TAPIRPCheffEntityVendaItem;
  LIdEmpresa, LIdVenda: Integer;
  LIdUsuarioHeader: Integer;
  LService: TAPIRPCheffServiceVendaLancarItem;
begin
  if not FRequest.Params.ContainsKey('idVenda') then
    Exit;

  LIdEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
  LIdVenda   := FRequest.Params.Field('idVenda').AsInteger;
  LIdUsuarioHeader := Self.IdUsuario;

  LItens := Self.FromJSONArray<TAPIRPCheffEntityVendaItem>;
  try
    for LItem in LItens do
    begin
      LItem.idEmpresa := LIdEmpresa;
      LItem.idVenda   := LIdVenda;
      if LIdUsuarioHeader > 0 then
        LItem.idGarcom := LIdUsuarioHeader;
    end;

    LService := TAPIRPCheffServiceVendaLancarItem.Create;
    try
      LService.DAO(Controller.DAO).PendenteImpressao(False);
      try
        LService.ExecuteLote(LItens);
      except
        on E: EConflictError do
        begin
          Controller.DAO.VendaItemDAO.LiberarImpressao(LIdEmpresa, LIdVenda);
          FResponse.Status(409);
          raise;
        end;
        on E: Exception do
        begin
          Controller.DAO.VendaItemDAO.LiberarImpressao(LIdEmpresa, LIdVenda);
          raise;
        end;
      end;
      Controller.DAO.VendaItemDAO.LiberarImpressao(LIdEmpresa, LIdVenda);
    finally
      FreeAndNil(LService);
    end;
    FResponse.Status(201);
  finally
    FreeAndNil(LItens);
  end;
end;

procedure TAPIRPCheffControllerVendaItem.ListarItens;
var
  LItens  : TObjectList<TAPIRPCheffEntityVendaItem>;
  LIdVenda: Integer;
begin
  LIdVenda := FRequest.Params.Field('idVenda').AsInteger;
  LItens   := Controller.DAO.VendaItemDAO.Listar(LIdVenda);
  try
    Self.Response<TAPIRPCheffEntityVendaItem>(LItens);
  finally
    FreeAndNil(LItens);
  end;
end;

procedure TAPIRPCheffControllerVendaItem.TotalTaxaGarcom;
var
  LIdVenda : Integer;
  LValor   : Currency;
  SJson    : string;
  FS       : TFormatSettings;
begin
  if not FRequest.Params.ContainsKey('idVenda') then
    Exit;

  LIdVenda := FRequest.Params.Field('idVenda').AsInteger;
  LValor   := Controller.DAO.VendaItemDAO.ListarProdutosSomenteTaxaGarcom(LIdVenda);

  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  SJson := Format('{"valor":%s}', [FloatToStr(Double(LValor), FS)]);

  FResponse
    .Send(SJson)
    .ContentType('application/json; charset="UTF-8"')
    .Status(200);
end;

initialization
  THorseGBSwaggerRegistry.RegisterPath(TAPIRPCheffControllerVendaItem);

end.
