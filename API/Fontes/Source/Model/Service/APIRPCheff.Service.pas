unit APIRPCheff.Service;

interface

uses
  APIRPCheff.Components,
  APIRPCheff.DAO.Factory,
  APIRPCheff.Service.Comanda.Abertura,
  APIRPCheff.Service.Comanda.Consulta,
  APIRPCheff.Service.Comanda.Transferencia,
  APIRPCheff.Service.Mesa.Abertura,
  APIRPCheff.Service.Mesa.Consulta,
  APIRPCheff.Service.Mesa.Transferencia,
  APIRPCheff.Service.Mesa.Juncao,
  APIRPCheff.Service.Venda.CancelarItem,
  APIRPCheff.Service.Venda.Consulta,
  APIRPCheff.Service.Venda.Fechamento,
  APIRPCheff.Service.Venda.Impressao,
  APIRPCheff.Service.Venda.LancarItem,
  APIRPCheff.Service.Venda.PreFechamento,
  APIRPCheff.Service.Venda.PagamentoParcial,
  System.SysUtils;

type
  TAPIRPCheffService = class
  private
    FComponents                  : TAPIRPCheffComponents;
    FDAO                         : TAPIRPCheffDAOFactory;
    FComandaAberturaService      : TAPIRPCheffServiceComandaAbertura;
    FComandaConsultaService      : TAPIRPCheffServiceComandaConsulta;
    FComandaTransferenciaService : TAPIRPCheffServiceComandaTransferencia;
    FMesaAberturaService         : TAPIRPCheffServiceMesaAbertura;
    FMesaConsultaService         : TAPIRPCheffServiceMesaConsulta;
    FMesaTransferenciaService    : TAPIRPCheffServiceMesaTransferencia;
    FMesaJuncaoService           : TAPIRPCheffServiceMesaJuncao;
    FVendaCancelarItemService    : TAPIRPCheffServiceVendaCancelarItem;
    FVendaConsultaService        : TAPIRPCheffServiceVendaConsulta;
    FVendaFechamentoService      : TAPIRPCheffServiceVendaFechamento;
    FVendaImpressaoService       : TAPIRPCheffServiceVendaImpressao;
    FVendaLancarItemService      : TAPIRPCheffServiceVendaLancarItem;
    FVendaPreFechamentoService   : TAPIRPCheffServiceVendaPreFechamento;
    FVendaPagamentoParcialService: TAPIRPCheffServiceVendaPagamentoParcial;
  public
    destructor Destroy; override;

    function Components(AValue: TAPIRPCheffComponents): TAPIRPCheffService;
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffService;

    function ComandaAberturaService      : TAPIRPCheffServiceComandaAbertura;
    function ComandaConsultaService      : TAPIRPCheffServiceComandaConsulta;
    function ComandaTransferenciaService : TAPIRPCheffServiceComandaTransferencia;
    function MesaAberturaService         : TAPIRPCheffServiceMesaAbertura;
    function MesaConsultaService         : TAPIRPCheffServiceMesaConsulta;
    function MesaTransferenciaService    : TAPIRPCheffServiceMesaTransferencia;
    function MesaJuncaoService           : TAPIRPCheffServiceMesaJuncao;
    function VendaCancelarItemService    : TAPIRPCheffServiceVendaCancelarItem;
    function VendaConsultaService        : TAPIRPCheffServiceVendaConsulta;
    function VendaFechamentoService      : TAPIRPCheffServiceVendaFechamento;
    function VendaImpressaoService       : TAPIRPCheffServiceVendaImpressao;
    function VendaLancarItemService      : TAPIRPCheffServiceVendaLancarItem;
    function VendaPreFechamentoService   : TAPIRPCheffServiceVendaPreFechamento;
    function VendaPagamentoParcialService: TAPIRPCheffServiceVendaPagamentoParcial;
  end;

implementation

{ TAPIRPCheffService }

function TAPIRPCheffService.ComandaAberturaService: TAPIRPCheffServiceComandaAbertura;
begin
  if not Assigned(FComandaAberturaService) then
  begin
    FComandaAberturaService := TAPIRPCheffServiceComandaAbertura.Create;
    FComandaAberturaService.DAO(FDAO);
  end;
  Result := FComandaAberturaService;
end;

function TAPIRPCheffService.ComandaConsultaService: TAPIRPCheffServiceComandaConsulta;
begin
  if not Assigned(FComandaConsultaService) then
  begin
    FComandaConsultaService := TAPIRPCheffServiceComandaConsulta.Create;
    FComandaConsultaService.DAO(FDAO);
  end;
  Result := FComandaConsultaService;
end;

function TAPIRPCheffService.ComandaTransferenciaService: TAPIRPCheffServiceComandaTransferencia;
begin
  if not Assigned(FComandaTransferenciaService) then
  begin
    FComandaTransferenciaService := TAPIRPCheffServiceComandaTransferencia.Create;
    FComandaTransferenciaService.DAO(FDAO);
  end;
  Result := FComandaTransferenciaService;
end;

function TAPIRPCheffService.Components(AValue: TAPIRPCheffComponents): TAPIRPCheffService;
begin
  Result := Self;
  FComponents := AValue;
end;

function TAPIRPCheffService.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffService;
begin
  Result := Self;
  FDAO := AValue;
end;

destructor TAPIRPCheffService.Destroy;
begin
  FreeAndNil(FComandaAberturaService);
  FreeAndNil(FComandaConsultaService);
  FreeAndNil(FComandaTransferenciaService);
  FreeAndNil(FMesaAberturaService);
  FreeAndNil(FMesaConsultaService);
  FreeAndNil(FMesaTransferenciaService);
  FreeAndNil(FMesaJuncaoService);
  FreeAndNil(FVendaCancelarItemService);
  FreeAndNil(FVendaConsultaService);
  FreeAndNil(FVendaFechamentoService);
  FreeAndNil(FVendaLancarItemService);
  FreeAndNil(FVendaImpressaoService);
  FreeAndNil(FVendaPreFechamentoService);
  FreeAndNil(FVendaPagamentoParcialService);
  inherited;
end;

function TAPIRPCheffService.MesaAberturaService: TAPIRPCheffServiceMesaAbertura;
begin
  if not Assigned(FMesaAberturaService) then
  begin
    FMesaAberturaService := TAPIRPCheffServiceMesaAbertura.Create;
    FMesaAberturaService.DAO(FDAO);
  end;
  Result := FMesaAberturaService;
end;

function TAPIRPCheffService.MesaConsultaService: TAPIRPCheffServiceMesaConsulta;
begin
  if not Assigned(FMesaConsultaService) then
  begin
    FMesaConsultaService := TAPIRPCheffServiceMesaConsulta.Create;
    FMesaConsultaService.DAO(FDAO);
  end;
  Result := FMesaConsultaService;
end;

function TAPIRPCheffService.VendaCancelarItemService: TAPIRPCheffServiceVendaCancelarItem;
begin
  if not Assigned(FVendaCancelarItemService) then
  begin
    FVendaCancelarItemService := TAPIRPCheffServiceVendaCancelarItem.Create;
    FVendaCancelarItemService.DAO(FDAO);
  end;
  Result := FVendaCancelarItemService;
end;

function TAPIRPCheffService.VendaConsultaService: TAPIRPCheffServiceVendaConsulta;
begin
  if not Assigned(FVendaConsultaService) then
  begin
    FVendaConsultaService := TAPIRPCheffServiceVendaConsulta.Create;
    FVendaConsultaService.DAO(FDAO);
  end;
  Result := FVendaConsultaService;
end;

function TAPIRPCheffService.VendaFechamentoService: TAPIRPCheffServiceVendaFechamento;
begin
  if not Assigned(FVendaFechamentoService) then
  begin
    FVendaFechamentoService := TAPIRPCheffServiceVendaFechamento.Create;
    FVendaFechamentoService.DAO(FDAO)
      .Components(FComponents);
  end;
  Result := FVendaFechamentoService;
end;

function TAPIRPCheffService.VendaImpressaoService: TAPIRPCheffServiceVendaImpressao;
begin
  if not Assigned(FVendaImpressaoService) then
  begin
    FVendaImpressaoService := TAPIRPCheffServiceVendaImpressao.Create;
    FVendaImpressaoService.DAO(FDAO)
      .Components(FComponents);
  end;
  Result := FVendaImpressaoService;
end;

function TAPIRPCheffService.VendaLancarItemService: TAPIRPCheffServiceVendaLancarItem;
begin
  if not Assigned(FVendaLancarItemService) then
  begin
    FVendaLancarItemService := TAPIRPCheffServiceVendaLancarItem.Create;
    FVendaLancarItemService.DAO(FDAO);
  end;
  Result := FVendaLancarItemService;
end;

function TAPIRPCheffService.VendaPagamentoParcialService: TAPIRPCheffServiceVendaPagamentoParcial;
begin
  if not Assigned(FVendaPagamentoParcialService) then
  begin
    FVendaPagamentoParcialService := TAPIRPCheffServiceVendaPagamentoParcial.Create;
    FVendaPagamentoParcialService.DAO(FDAO);
  end;
  Result := FVendaPagamentoParcialService;
end;

function TAPIRPCheffService.VendaPreFechamentoService: TAPIRPCheffServiceVendaPreFechamento;
begin
  if not Assigned(FVendaPreFechamentoService) then
  begin
    FVendaPreFechamentoService := TAPIRPCheffServiceVendaPreFechamento.Create;
    FVendaPreFechamentoService.DAO(FDAO)
      .Components(FComponents);
  end;
  Result := FVendaPreFechamentoService;
end;

function TAPIRPCheffService.MesaTransferenciaService: TAPIRPCheffServiceMesaTransferencia;
begin
  if not Assigned(FMesaTransferenciaService) then
  begin
    FMesaTransferenciaService := TAPIRPCheffServiceMesaTransferencia.Create;
    FMesaTransferenciaService.DAO(FDAO);
  end;
  Result := FMesaTransferenciaService;
end;

function TAPIRPCheffService.MesaJuncaoService: TAPIRPCheffServiceMesaJuncao;
begin
  if not Assigned(FMesaJuncaoService) then
  begin
    FMesaJuncaoService := TAPIRPCheffServiceMesaJuncao.Create;
    FMesaJuncaoService.DAO(FDAO);
  end;
  Result := FMesaJuncaoService;
end;

end.
