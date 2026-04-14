unit APIRPCheff.Service.Venda.PreFechamento;

interface

uses
  System.SysUtils,
  System.Math,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.Components,
  APIRPCheff.DAO.Factory;

type
  TAPIRPCheffServiceVendaPreFechamento = class
  private
    FComponents   : TAPIRPCheffComponents;
    FDAO          : TAPIRPCheffDAOFactory;
    FPatch        : TAPIRPCheffEntityVendaPatchPreFechamento;
    FVenda        : TAPIRPCheffEntityVenda;
    FConfiguracao : TAPIRPCheffEntityConfiguracaoMesaComanda;

    procedure CarregarConfiguracao;
    procedure CarregarVenda;
    procedure CalcularTaxaServico;
  public
    destructor Destroy; override;

    function Components(const AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaPreFechamento;
    function DAO(const AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaPreFechamento;
    function Patch(const AValue: TAPIRPCheffEntityVendaPatchPreFechamento): TAPIRPCheffServiceVendaPreFechamento;
    procedure Execute;
  end;

implementation

{ TAPIRPCheffServiceVendaPreFechamento }

destructor TAPIRPCheffServiceVendaPreFechamento.Destroy;
begin
  FreeAndNil(FConfiguracao);
  FreeAndNil(FVenda);
  inherited;
end;

procedure TAPIRPCheffServiceVendaPreFechamento.CalcularTaxaServico;
var
  LValorVenda: Currency;
  LValorVendaSomenteProdutosTaxa:Currency;
  LValorTaxa: Currency;
  LPercentual: Currency;
begin
  FreeAndNil(FVenda.itens);
  FVenda.itens := FDAO.VendaItemDAO.Listar(FVenda.idVenda);
  LValorVenda := FVenda.TotalItens;

  if (not FPatch.CobrarTaxaGarcom) or (FPatch.valorTaxaServico <= 0) then
  begin
    FDAO.VendaDAO.AtualizarTotalVenda(FVenda.idEmpresa, FVenda.idVenda, LValorVenda, 0, 0);
    Exit;
  end;

  if Assigned(FConfiguracao) and FConfiguracao.utilizaTaxaServico then
  begin
    LValorVendaSomenteProdutosTaxa  := FDAO.VendaItemDAO.ListarProdutosSomenteTaxaGarcom(FVenda.idVenda);
    LPercentual                     := FConfiguracao.percentualTaxaServico;
    LValorTaxa                      := SimpleRoundTo(LValorVendaSomenteProdutosTaxa * (LPercentual / 100), -2);
    FDAO.VendaDAO.AtualizarTotalVenda(FVenda.idEmpresa, FVenda.idVenda, LValorVenda, LValorTaxa, LPercentual);
    Exit;
  end;

  FDAO.VendaDAO.AtualizarTotalVenda(FVenda.idEmpresa, FVenda.idVenda, LValorVenda, 0, 0);
end;

procedure TAPIRPCheffServiceVendaPreFechamento.CarregarConfiguracao;
begin
  FreeAndNil(FConfiguracao);
  if FVenda.tipoVenda = tvMesa then
    FConfiguracao := FDAO.ConfiguracaoMesaDAO.Buscar(FVenda.idEmpresa)
  else
  if FVenda.tipoVenda = tvComanda then
    FConfiguracao := FDAO.ConfiguracaoComandaDAO.Buscar(FVenda.idEmpresa);
end;

procedure TAPIRPCheffServiceVendaPreFechamento.CarregarVenda;
begin
  FreeAndNil(FVenda);
  FVenda := FDAO.IdEmpresa(FPatch.idEmpresa).VendaDAO.Buscar(FPatch.idVenda);
end;

function TAPIRPCheffServiceVendaPreFechamento.Components(const AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaPreFechamento;
begin
  Result      := Self;
  FComponents := AValue;
end;

function TAPIRPCheffServiceVendaPreFechamento.DAO(const AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaPreFechamento;
begin
  Result  := Self;
  FDAO    := AValue;
end;

procedure TAPIRPCheffServiceVendaPreFechamento.Execute;
begin
  CarregarVenda;
  CarregarConfiguracao;
  FDAO.VendaDAO.PreFechamento(FPatch);
  CalcularTaxaServico;
end;

function TAPIRPCheffServiceVendaPreFechamento.Patch(const AValue: TAPIRPCheffEntityVendaPatchPreFechamento): TAPIRPCheffServiceVendaPreFechamento;
begin
  Result := Self;
  FPatch := AValue;
end;

end.
