unit APIRPCheff.Service.Venda.PagamentoParcial.Command.ProximoIdCaixaItem;

interface

uses
  APIRPCheff.Service.Venda.PagamentoParcial.Command,
  APIRPCheff.Context.Venda.PagamentoParcial;

type
  TAPIRPCheffServiceVendaPagamentoParcialCommandProximoIdCaixaItem = class(TAPIRPCheffServiceVendaPagamentoParcialCommand)
  public
    procedure Execute(const AContext: PAPIRPCheffContextVendaPagamentoParcial); override;
  end;

implementation

{ TAPIRPCheffServiceVendaPagamentoParcialCommandProximoIdCaixaItem }

procedure TAPIRPCheffServiceVendaPagamentoParcialCommandProximoIdCaixaItem.Execute(
  const AContext: PAPIRPCheffContextVendaPagamentoParcial);
begin
  inherited;

  if (AContext.PagamentoAntecipado = nil) or (AContext.Venda = nil) then
    Exit;

  AContext.PagamentoAntecipado.IdCaixaItem :=
    FParent.DAO.CaixaItemDAO.ProximoIdCaixaItem(
      AContext.Venda.IdEmpresa,
      AContext.Venda.IdCaixa
    );
end;

end.

