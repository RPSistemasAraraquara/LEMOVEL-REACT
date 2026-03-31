unit APIRPCheff.Service.Venda.PagamentoParcial.Command.InserirPagamentoAntecipados;

interface

uses
  APIRPCheff.Service.Venda.PagamentoParcial.Command,
  APIRPCheff.Context.Venda.PagamentoParcial;

type
  TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipados = class(TAPIRPCheffServiceVendaPagamentoParcialCommand)
  public
    procedure Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial); override;
  end;

implementation

uses
  System.SysUtils,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types;

{ TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipados }

procedure TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipados.Execute(
  const AContext: PAPIRPCheffContextVendaPagamentoParcial);
var
  LPagamentoAntecipado: TAPIRPCheffEntityVendaPagamentoAntecipado;
begin
  inherited;

  if (FParent = nil) or (FParent.DAO = nil) then
    Exit;

  if (AContext.PagamentoAntecipado = nil) or (AContext.Venda = nil) then
    Exit;

  LPagamentoAntecipado := TAPIRPCheffEntityVendaPagamentoAntecipado.Create;
  try
    LPagamentoAntecipado.IdVenda             := AContext.PagamentoAntecipado.IdVenda;
    LPagamentoAntecipado.IdEmpresa           := AContext.PagamentoAntecipado.IdEmpresa;
    if AContext.PagamentoAntecipado.IdUsuarioLancamento > 0 then
      LPagamentoAntecipado.IdUsuarioLancamento := AContext.PagamentoAntecipado.IdUsuarioLancamento
    else
      LPagamentoAntecipado.IdUsuarioLancamento := AContext.Venda.IdUsuario;
    LPagamentoAntecipado.DataHora            := Now;
    LPagamentoAntecipado.Valor               := AContext.PagamentoAntecipado.Valor;
    LPagamentoAntecipado.Situacao            := sAtivo;
    LPagamentoAntecipado.IdFormaPagamento    := AContext.PagamentoAntecipado.IdFormaPagamento;
    LPagamentoAntecipado.IdCaixa             := AContext.PagamentoAntecipado.IdCaixa;
    LPagamentoAntecipado.IdCaixaItem         := AContext.PagamentoAntecipado.IdCaixaItem;
    LPagamentoAntecipado.Observacao          := 'Pagamento Antecipado: ' + ' ' + AContext.Venda.DescricaoMesaComanda;
    LPagamentoAntecipado.TaxaServico         := AContext.PagamentoAntecipado.TaxaServico;
    LPagamentoAntecipado.ValorProduto        := AContext.PagamentoAntecipado.valor * (AContext.Venda.valor / AContext.Venda.valorTotal);
    LPagamentoAntecipado.ValorTaxaServico    := AContext.PagamentoAntecipado.valor - LPagamentoAntecipado.ValorProduto;

    FParent.DAO.VendaPagamentoAntecipadoDAO.Inserir(LPagamentoAntecipado);
  finally
    LPagamentoAntecipado.Free;
  end;
end;
                                               
end.
