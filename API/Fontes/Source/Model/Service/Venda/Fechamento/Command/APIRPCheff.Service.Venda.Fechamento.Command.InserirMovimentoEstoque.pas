unit APIRPCheff.Service.Venda.Fechamento.Command.InserirMovimentoEstoque;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Generics.Collections,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoque = class(TAPIRPCheffServiceVendaFechamentoCommand)
  private
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoque }

procedure TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoque.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LMovimentoDAO : TAPIRPCheffDAOMovimentoEstoque;
  LMovimento    : TAPIRPCheffEntityMovimentoEstoque;
  LVendaItem    : TAPIRPCheffEntityVendaItem;
begin
  LMovimentoDAO := FParent.DAO.MovimentoEstoqueDAO;
  LMovimentoDAO.ManagerTransaction(False);
  for LVendaItem in FParent.VendaItens do
  begin
    if not LVendaItem.produtoUtilizaCombo then
    begin
      LMovimento := TAPIRPCheffEntityMovimentoEstoque.Create;
      try
        LMovimento.idEmpresa    := LVendaItem.idEmpresa;
        LMovimento.idMaterial   := LVendaItem.idProduto;
        LMovimento.quantidade   := LVendaItem.quantidade;
        LMovimento.idUsuario    := AFechamento.idUsuario;
        LMovimento.idVenda      := LVendaItem.idVenda;
        LMovimento.data         := Now;
        LMovimento.idVendaItem  := LVendaItem.numeroItem;
        LMovimento.idSetor      := LVendaItem.produtoIdSetor;
        LMovimento.tipoMovimento := 'S';

        LMovimentoDAO.Inserir(LMovimento);
      finally
        FreeAndNil(LMovimento);
      end;
    end;
  end;
end;

end.
