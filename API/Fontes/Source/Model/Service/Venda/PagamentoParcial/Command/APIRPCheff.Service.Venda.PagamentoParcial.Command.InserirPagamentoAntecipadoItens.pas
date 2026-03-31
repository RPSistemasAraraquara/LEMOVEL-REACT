unit APIRPCheff.Service.Venda.PagamentoParcial.Command.InserirPagamentoAntecipadoItens;

interface

uses
  System.Math,
  APIRPCheff.Service.Venda.PagamentoParcial.Command,
  APIRPCheff.Context.Venda.PagamentoParcial,
  APIRPCheff.Entity.Classes;

type
  TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipadoItens = class(TAPIRPCheffServiceVendaPagamentoParcialCommand)
  private
    FValorRestante     : Currency;
    FValorRestanteItem : Currency;
    FValorPagoItem     : Currency;

    function QuantidadeRestante(const AItem: TAPIRPCheffEntityVendaItem): Currency;
  public
    procedure Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial); override;
  end;

implementation

uses
  System.SysUtils;

{ TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipadoItens }

function TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipadoItens.QuantidadeRestante(const AItem: TAPIRPCheffEntityVendaItem): Currency;
begin
  Result := AItem.Quantidade - AItem.QuantidadePagaAntecipado;
  if Result < 0 then
    Result := 0;
end;

procedure TAPIRPCheffServiceVendaPagamentoParcialCommandInserirPagamentoAntecipadoItens.Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial);
var
  LPagamentoItem               : TAPIRPCheffEntityVendaPagamentoAntecipadoItens;
  LValorRestante               : Currency;
  LValorProdutoPag             : Currency;
  LValorProdutoItem            : Currency;
  LQtdPagaItem                 : Currency;
  LItem                        : TAPIRPCheffEntityVendaItem;
  LProporcaoVenda              : Currency;
  LIdUltimoPagamentoAntecipado :Integer;
begin
  inherited;

  LValorRestante := AContext.PagamentoAntecipado.Valor;

  if AContext.Venda.ValorTotal > 0 then
    LProporcaoVenda := AContext.Venda.Valor / AContext.Venda.ValorTotal
  else
    Exit;

  LValorProdutoPag := LValorRestante * LProporcaoVenda;

  for LItem in AContext.Venda.Itens do
  begin
    if (LValorProdutoPag <= 0) or (LItem.ValorTotal <= LItem.ValorPagoAntecipado) then
      Continue;

    LValorProdutoItem := Min(LItem.ValorTotal - LItem.ValorPagoAntecipado,LValorProdutoPag);


    if LItem.Quantidade > 0 then    // quantidade proporcional paga
      LQtdPagaItem := RoundTo(LItem.Quantidade * (LValorProdutoItem / LItem.ValorTotal),-2)
    else
      LQtdPagaItem := 0;

    LPagamentoItem := TAPIRPCheffEntityVendaPagamentoAntecipadoItens.Create;
    try
      LIdUltimoPagamentoAntecipado:=FParent.DAO.VendaPagamentoAntecipadoDAO.BuscarUltimoIdVenda(AContext.Venda.idVenda);
      LPagamentoItem.IdEmpresa      := AContext.PagamentoAntecipado.IdEmpresa;
      LPagamentoItem.NumeroItem     := LItem.NumeroItem;
      LPagamentoItem.IdMaterial     := LItem.IdProduto;
      LPagamentoItem.QuantidadePaga := LQtdPagaItem;
      LPagamentoItem.ValorPago      := LValorProdutoItem;
      LPagamentoItem.Unitario       := LItem.ValorUnitario;
      LPagamentoItem.Id             :=LIdUltimoPagamentoAntecipado;

      FParent.DAO.VendaPagamentoAntecipadoItensDAO.Inserir(LPagamentoItem);

      FParent.DAO.VendaItemDAO.AtualizarQuantidadePago(
      AContext.Venda.IdVenda,
      LItem.NumeroItem,
      LItem.QuantidadePagaAntecipado + LQtdPagaItem,
      LItem.ValorPagoAntecipado + LValorProdutoItem
      );

      // atualiza saldo
      LValorProdutoPag := LValorProdutoPag - LValorProdutoItem;
      LValorRestante   := LValorRestante - (LValorProdutoItem / LProporcaoVenda);

      if LValorProdutoPag <= 0 then
        Break;
    finally
      LPagamentoItem.Free;
    end;
  end;
end;


end.

