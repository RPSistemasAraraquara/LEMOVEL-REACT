unit APIRPCheff.Service.Venda.PagamentoParcial.Command.InserirCaixaItem;

interface

uses
  APIRPCheff.Service.Venda.PagamentoParcial.Command,
  APIRPCheff.Context.Venda.PagamentoParcial;

type
  TAPIRPCheffServiceVendaPagamentoParcialCommandInserirCaixaItem = class(TAPIRPCheffServiceVendaPagamentoParcialCommand)
  public
    procedure Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial); override;
  end;

implementation

uses
  System.SysUtils,
  APIRPCheff.Entity.Classes;

{ TAPIRPCheffServiceVendaPagamentoParcialCommandInserirCaixaItem }

procedure TAPIRPCheffServiceVendaPagamentoParcialCommandInserirCaixaItem.Execute(
  const AContext: PAPIRPCheffContextVendaPagamentoParcial);
var
  LCaixaItem: TAPIRPCheffEntityCaixaItem;
begin
  inherited;

  if (AContext.PagamentoAntecipado = nil) or (AContext.Venda = nil) then
    Exit;

  LCaixaItem := TAPIRPCheffEntityCaixaItem.Create;
  try
    LCaixaItem.Item             := AContext.PagamentoAntecipado.IdCaixaItem;
    LCaixaItem.IdEmpresa        := AContext.PagamentoAntecipado.IdEmpresa;
    LCaixaItem.IdCaixa          := AContext.Venda.IdCaixa;
    LCaixaItem.TipoMovimento    := 'E';
    LCaixaItem.IdFormaPgto      := AContext.PagamentoAntecipado.IdFormaPagamento;
    LCaixaItem.IdVenda          := AContext.Venda.IdVenda;
    LCaixaItem.ItemEncerraVenda := 0;
    LCaixaItem.IdEncerraVenda   := 0;
    LCaixaItem.Classificacao    := 'V';
    LCaixaItem.Valor            := AContext.PagamentoAntecipado.Valor;
    LCaixaItem.Antecipado       := True;
    if AContext.Venda.NumeroMesa > 0 then
      LCaixaItem.Observacao := Format('Pagamento antecipado MESA %d', [AContext.Venda.NumeroMesa])
    else
      LCaixaItem.Observacao := 'Pagamento antecipado ' + UpperCase(AContext.Venda.DescricaoMesaComanda);

    FParent.DAO.CaixaItemDAO.Inserir(LCaixaItem);
  finally
    LCaixaItem.Free;
  end;
end;

end.

