unit APIRPCheff.Service.Venda.Fechamento.Command.FinalizarVenda;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Math,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandFinalizarVenda =
    class(TAPIRPCheffServiceVendaFechamentoCommand)
  private
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandFinalizarVenda }

procedure TAPIRPCheffServiceVendaFechamentoCommandFinalizarVenda.Execute( AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LDAO: TAPIRPCheffDAOVenda;
  LValorVenda: Currency;
  LValorPagoAntecipado: Currency;
  LValorTaxa: Currency;
  LPercentualTaxa: Currency;
begin
  LDAO := FParent.DAO.VendaDAO;
  LDAO.ManagerTransaction(False);
  LDAO.FinalizarVenda(AFechamento);

  LValorPagoAntecipado := LDAO.GetValorPago(FParent.Venda.idVenda);
  LValorVenda := RoundTo(AFechamento.ValorPagamento + LValorPagoAntecipado, -2);
  if FParent.Venda.tipoVenda in [tvMesa, tvComanda] then
  begin
    LValorTaxa := FParent.Venda.valorTaxaServico;
    LPercentualTaxa := FParent.Venda.percentualTaxaServico;
    LDAO.AtualizarTotalVenda(FParent.Venda.idEmpresa, FParent.Venda.idVenda,
      LValorVenda, LValorTaxa, LPercentualTaxa, not AFechamento.CobrarTaxaGarcom);
    Exit;
  end;

  LValorTaxa := AFechamento.valorTaxaServico;
  LPercentualTaxa := 0;
  if LValorVenda > 0 then
    LPercentualTaxa := SimpleRoundTo((LValorTaxa / LValorVenda) * 100, -2);
  LDAO.AtualizarTotalVenda(FParent.Venda.idEmpresa, FParent.Venda.idVenda,
    LValorVenda, LValorTaxa, LPercentualTaxa, LPercentualTaxa <= 0);
end;

end.
