unit APIRPCheff.Service.Venda.Fechamento.Command.AtualizarItens;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Math,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandAtualizarItens =  class(TAPIRPCheffServiceVendaFechamentoCommand)

  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandAtualizarItens }

procedure TAPIRPCheffServiceVendaFechamentoCommandAtualizarItens.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LItemDAO      : TAPIRPCheffDAOVendaItem;
  LItem         : TAPIRPCheffEntityVendaItem;
  LTotalDesconto: Currency;
begin
  LItemDAO := FParent.DAO.VendaItemDAO;
  LItemDAO.ManagerTransaction(False);


  LTotalDesconto := AFechamento.valorDesconto;
  if LTotalDesconto > 0 then
   LItemDAO.AplicarDescontoProporcional(FParent.Venda.idVenda,LTotalDesconto);

  LItemDAO.RatearTaxaGarcomPorItens(FParent.Venda.idVenda);
  LItemDAO.CalcularMargemLucro(FParent.Venda.idVenda);

  for LItem in FParent.VendaItens do
  begin
    if not LItem.pendenteImpressao then
      Continue;
    LItemDAO.AtualizarItemImpresso(FParent.Venda.idVenda, LItem.numeroItem, True);
  end;
end;




end.
