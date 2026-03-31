unit APIRPCheff.Service.Venda.Fechamento.Command.AtualizarSetorEstoque;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Generics.Collections,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandAtualizarSetorEstoque =
    class(TAPIRPCheffServiceVendaFechamentoCommand)
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandAtualizarSetorEstoque }

procedure TAPIRPCheffServiceVendaFechamentoCommandAtualizarSetorEstoque.Execute( AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LEstoque: TAPIRPCheffEntitySetorEstoqueMaterial;
  LEstoqueDAO: TAPIRPCheffDAOSetorEstoqueMaterial;
  LVendaItem: TAPIRPCheffEntityVendaItem;
begin
  LEstoqueDAO := FParent.DAO.SetorEstoqueMaterialDAO;
  LEstoqueDAO.ManagerTransaction(False);
  for LVendaItem in FParent.VendaItens do
  begin
    if LVendaItem.produtoIdSetor = 0 then
      Continue;

    if LVendaItem.produtoUtilizaCombo then
      Continue;

    LEstoque := LEstoqueDAO.Buscar(LVendaItem.idProduto, LVendaItem.produtoIdSetor);
    try
      if Assigned(LEstoque) then
      begin
        LEstoque.quantidade := LEstoque.quantidade - LVendaItem.quantidade;
        LEstoqueDAO.Atualizar(LEstoque);
      end
      else
      begin
        LEstoque            := TAPIRPCheffEntitySetorEstoqueMaterial.Create;
        LEstoque.idEmpresa  := LVendaItem.idEmpresa;
        LEstoque.idMaterial := LVendaItem.idProduto;
        LEstoque.idSetor    := LVendaItem.produtoIdSetor;
        LEstoque.quantidade := LVendaItem.quantidade * -1;
        LEstoqueDAO.Inserir(LEstoque);
      end;
    finally
      FreeAndNil(LEstoque);
    end;
  end;
end;

end.
