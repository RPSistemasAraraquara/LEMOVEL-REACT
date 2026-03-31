unit APIRPCheff.Service.Venda.Fechamento.Command.ProximoIdCaixaItem;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
    APIRPCheff.Entity.Classes;

type


  TAPIRPCheffServiceVendaFechamentoCommandProximoIdCaixaItem = class(TAPIRPCheffServiceVendaFechamentoCommand)
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandProximoIdCaixaItem }

procedure TAPIRPCheffServiceVendaFechamentoCommandProximoIdCaixaItem.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LId: Integer;
begin
  inherited;
  LId := FParent.DAO.CaixaItemDAO.ProximoIdCaixaItem(FParent.Venda.idEmpresa, FParent.Venda.idCaixa);
  FContext^.ProximoIdCaixaItem := LId;
end;

end.
