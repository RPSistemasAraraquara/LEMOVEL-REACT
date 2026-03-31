unit APIRPCheff.Service.Venda.Fechamento.Command.AtualizaCupom;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Math,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandAtualizaCupom =
    class(TAPIRPCheffServiceVendaFechamentoCommand)
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandAtualizaCupom }

procedure TAPIRPCheffServiceVendaFechamentoCommandAtualizaCupom.Execute(
  AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LDAO: TAPIRPCheffDAOVenda;
  LVenda: TAPIRPCheffEntityVenda;
begin
  LDAO := FParent.DAO.VendaDAO;
  LDAO.ManagerTransaction(False);
  LVenda := FParent.Venda;
  LVenda.numeroCupom := LDAO.AtualizarNumeroCupom(LVenda.idVenda);
end;

end.
