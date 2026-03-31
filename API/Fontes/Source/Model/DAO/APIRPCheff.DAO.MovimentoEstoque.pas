unit APIRPCheff.DAO.MovimentoEstoque;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOMovimentoEstoque = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityMovimentoEstoque>)
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityMovimentoEstoque; override;
  public
    procedure Inserir(AMovimento: TAPIRPCheffEntityMovimentoEstoque);
  end;

implementation

{ TAPIRPCheffDAOMovimentoEstoque }

function TAPIRPCheffDAOMovimentoEstoque.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityMovimentoEstoque;
begin
  Result := nil;
end;

procedure TAPIRPCheffDAOMovimentoEstoque.Inserir(AMovimento: TAPIRPCheffEntityMovimentoEstoque);
begin
  StartTransaction;
  try
    Query.SQL('insert into movimentoestoque (')
      .SQL('  id_empresa, id_material, quantidade, id_usuario,')
      .SQL('  tipo_movimento, data, id_fornecedor, valor_venda, valor_custo,')
      .SQL('  id_venda, id_vendaItem, id_setor, id_setor_destino)')
      .SQL('values (')
      .SQL('  :id_empresa, :id_material, :quantidade, :id_usuario,')
      .SQL('  :tipo_movimento, :data, :id_fornecedor, :valor_venda, :valor_custo,')
      .SQL('  :id_venda, :id_vendaItem, :id_setor, :id_setor_destino)')
      .ParamAsInteger('id_empresa', AMovimento.idEmpresa)
      .ParamAsInteger('id_material', AMovimento.idMaterial)
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
