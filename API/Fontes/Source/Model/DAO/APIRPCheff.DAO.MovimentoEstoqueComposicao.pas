unit APIRPCheff.DAO.MovimentoEstoqueComposicao;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOMovimentoEstoqueComposicao = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityMovimentoEstoqueComposicao>)
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityMovimentoEstoqueComposicao; override;
  public
    procedure Inserir(AMovimento: TAPIRPCheffEntityMovimentoEstoqueComposicao);
  end;

implementation

{ TAPIRPCheffDAOMovimentoEstoqueComposicao }

function TAPIRPCheffDAOMovimentoEstoqueComposicao.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityMovimentoEstoqueComposicao;
begin
  Result := nil;
end;

procedure TAPIRPCheffDAOMovimentoEstoqueComposicao.Inserir(AMovimento: TAPIRPCheffEntityMovimentoEstoqueComposicao);
begin
  StartTransaction;
  try
    Query.SQL('insert into movimento_estoque_composicao (')
      .SQL('  id_empresa, id_composicao, quantidade, id_usuario,')
      .SQL('  tipo_movimento, data, id_fornecedor, valor_venda, valor_custo,')
      .SQL('  id_venda, id_vendaItem, id_setor, id_setor_destino)')
      .SQL('values (')
      .SQL('  :id_empresa, :id_composicao, :quantidade, :id_usuario,')
      .SQL('  :tipo_movimento, :data, :id_fornecedor, :valor_venda, :valor_custo,')
      .SQL('  :id_venda, :id_vendaItem, :id_setor, :id_setor_destino)')
      .ParamAsInteger('id_empresa', AMovimento.idEmpresa)
      .ParamAsInteger('id_composicao', AMovimento.idComposicao)
      .ParamAsCurrency('quantidade', AMovimento.quantidade)
      .ParamAsInteger('id_usuario', AMovimento.idUsuario)
      .ParamAsString('tipo_movimento', AMovimento.tipoMovimento)
      .ParamAsDateTime('data', AMovimento.data)
      .ParamAsInteger('id_fornecedor', AMovimento.idFornecedor, True)
      .ParamAsCurrency('valor_venda', AMovimento.valorVenda)
      .ParamAsCurrency('valor_custo', AMovimento.valorCusto)
      .ParamAsInteger('id_venda', AMovimento.idVenda)
      .ParamAsInteger('id_vendaItem', AMovimento.idVendaItem)
      .ParamAsInteger('id_setor', AMovimento.idSetor, True)
      .ParamAsInteger('id_setor_destino', AMovimento.idSetorDestino, True)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

end.
