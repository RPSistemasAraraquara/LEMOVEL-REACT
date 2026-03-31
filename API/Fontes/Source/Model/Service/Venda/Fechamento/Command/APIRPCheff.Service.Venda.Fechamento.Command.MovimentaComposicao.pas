unit APIRPCheff.Service.Venda.Fechamento.Command.MovimentaComposicao;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Generics.Collections,
  System.Math,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandMovimentaComposicao = class(TAPIRPCheffServiceVendaFechamentoCommand)
  private
    FFechamento : TAPIRPCheffEntityVendaPostFechamento;
    FVendaItem  : TAPIRPCheffEntityVendaItem;
    FMaterial   : TAPIRPCheffEntityMateriaisComposicao;

    procedure InserirMovimentoEstoqueComposicao;
    procedure GravarSetorEstoqueComposicao;
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandMovimentaComposicao }

procedure TAPIRPCheffServiceVendaFechamentoCommandMovimentaComposicao.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  I: Integer;
  J: Integer;
  LMateriais: TObjectList<TAPIRPCheffEntityMateriaisComposicao>;
begin
  FFechamento := AFechamento;
  for I := 0 to Pred(FParent.VendaItens.Count) do
  begin
    FVendaItem := FParent.VendaItens[I];
    LMateriais := FParent.DAO.MateriaisComposicaoDAO.Listar(FVendaItem.idProduto);
    try
      for J := 0 to Pred(LMateriais.Count) do
      begin
        FMaterial := LMateriais[J];
        InserirMovimentoEstoqueComposicao;
        GravarSetorEstoqueComposicao;
      end;
    finally
      FreeAndNil(LMateriais);
    end;
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandMovimentaComposicao.GravarSetorEstoqueComposicao;
var
  LDAO  : TAPIRPCheffDAOSetorEstoqueComposicao;
  LSetor: TAPIRPCheffEntitySetorEstoqueComposicao;
begin
  LDAO    := FParent.DAO.SetorEstoqueComposicaoDAO;
  LDAO.ManagerTransaction(False);
  LSetor  := LDAO.Buscar(FMaterial.idComposicao, FMaterial.composicao.idSetor);
  try
    if Assigned(LSetor) then
    begin
      LSetor.quantidade := LSetor.quantidade - FVendaItem.quantidade;
      LDAO.Alterar(LSetor);
    end
    else
    begin
      LSetor                := TAPIRPCheffEntitySetorEstoqueComposicao.Create;
      LSetor.idComposicao   := FMaterial.idComposicao;
      LSetor.idSetor        := FMaterial.composicao.idSetor;
      LSetor.idEmpresa      := FFechamento.idEmpresa;
      LSetor.quantidade     := FVendaItem.quantidade;
      LDAO.Inserir(LSetor);
    end;
  finally
    FreeAndNil(LSetor);
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandMovimentaComposicao.InserirMovimentoEstoqueComposicao;
var
  LDAO        : TAPIRPCheffDAOMovimentoEstoqueComposicao;
  LMovimento  : TAPIRPCheffEntityMovimentoEstoqueComposicao;
begin
  LDAO        := FParent.DAO.MovimentoEstoqueComposicaoDAO;
  LDAO.ManagerTransaction(False);
  LMovimento  := TAPIRPCheffEntityMovimentoEstoqueComposicao.Create;
  try
    LMovimento.idEmpresa      := FFechamento.idEmpresa;
    LMovimento.idComposicao   := FMaterial.idComposicao;
    LMovimento.quantidade     := FMaterial.quantidade;
    LMovimento.idUsuario      := FFechamento.idUsuario;
    LMovimento.data           := Now;
    LMovimento.tipoMovimento  := 'C';
    LMovimento.idVenda        := FFechamento.idVenda;
    LMovimento.idVendaItem    := FVendaItem.numeroItem;
    LMovimento.idSetor        := FMaterial.composicao.idSetor;
    LDAO.Inserir(LMovimento);
  finally
    FreeAndNil(LMovimento);
  end;
end;

end.
