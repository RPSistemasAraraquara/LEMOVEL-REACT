unit APIRPCheff.Service.Venda.PagamentoParcial.Command.InserirPagamentoAntecipadoItens;

interface

uses
  System.Math,
  APIRPCheff.Service.Venda.PagamentoParcial.Command,
  APIRPCheff.Context.Venda.PagamentoParcial,
  APIRPCheff.Entity.Classes;

type
  TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipadoItens = class(TAPIRPCheffServiceVendaPagamentoParcialCommand)
  public
    procedure Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial); override;
  end;

implementation

uses
  System.SysUtils;

{ TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipadoItens }

procedure TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipadoItens.Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial);
var
  LPagamentoItem               : TAPIRPCheffEntityVendaPagamentoAntecipadoItens;
  LValorRestante               : Currency;
  LValorTotalItem              : Currency;
  LValorPagoItem               : Currency;
  LQtdPagaItem                 : Currency;
  LItem                        : TAPIRPCheffEntityVendaItem;
  LIdUltimoPagamentoAntecipado :Integer;
begin
  inherited;

  LValorRestante := AContext.PagamentoAntecipado.Valor;

  for LItem in AContext.Venda.Itens do
  begin
    LValorTotalItem := LItem.ValorTotal + LItem.ValorTaxaServico;

    if (LValorRestante <= 0) or (LValorTotalItem <= LItem.ValorPagoAntecipado) then
      Continue;

    // valor_pago deve guardar o valor efetivamente pago, incluindo taxa de servico.
    LValorPagoItem := Min(LValorTotalItem - LItem.ValorPagoAntecipado, LValorRestante);


    if (LItem.Quantidade > 0) and (LValorTotalItem > 0) then    // quantidade proporcional paga
      LQtdPagaItem := RoundTo(LItem.Quantidade * (LValorPagoItem / LValorTotalItem),-2)
    else
      LQtdPagaItem := 0;

    LPagamentoItem := TAPIRPCheffEntityVendaPagamentoAntecipadoItens.Create;
    try
      LIdUltimoPagamentoAntecipado:=FParent.DAO.VendaPagamentoAntecipadoDAO.BuscarUltimoIdVenda(AContext.Venda.idVenda);
      LPagamentoItem.IdEmpresa      := AContext.PagamentoAntecipado.IdEmpresa;
      LPagamentoItem.NumeroItem     := LItem.NumeroItem;
      LPagamentoItem.IdMaterial     := LItem.IdProduto;
      LPagamentoItem.QuantidadePaga := LQtdPagaItem;
      LPagamentoItem.ValorPago      := LValorPagoItem;
      LPagamentoItem.Unitario       := LItem.ValorUnitario;
      LPagamentoItem.Id             :=LIdUltimoPagamentoAntecipado;

      FParent.DAO.VendaPagamentoAntecipadoItensDAO.Inserir(LPagamentoItem);

      FParent.DAO.VendaItemDAO.AtualizarQuantidadePago(
      AContext.Venda.IdVenda,
      LItem.NumeroItem,
      LItem.QuantidadePagaAntecipado + LQtdPagaItem,
      LItem.ValorPagoAntecipado + LValorPagoItem
      );

      // atualiza saldo
      LValorRestante := LValorRestante - LValorPagoItem;

      if LValorRestante <= 0 then
        Break;
    finally
      LPagamentoItem.Free;
    end;
  end;
end;


end.
