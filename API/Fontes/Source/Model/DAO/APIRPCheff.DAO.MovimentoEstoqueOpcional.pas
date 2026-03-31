unit APIRPCheff.DAO.MovimentoEstoqueOpcional;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

  type
    TAPIRPCheffDAOMovimentoEstoqueOpcional = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityMovimentoEstoqueOpcional>)
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityMovimentoEstoqueOpcional; override;
  public
    procedure Inserir(AMovimento:TAPIRPCheffEntityMovimentoEstoqueOpcional);

  end;

implementation

{ TAPIRPCheffDAOMovimentoEstoqueOpcional }

function TAPIRPCheffDAOMovimentoEstoqueOpcional.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityMovimentoEstoqueOpcional;
begin
  Result:=nil;
end;

procedure TAPIRPCheffDAOMovimentoEstoqueOpcional.Inserir(AMovimento: TAPIRPCheffEntityMovimentoEstoqueOpcional);
begin
//  StartTransaction;
  try
    Query.SQL(' INSERT INTO movimento_estoque_opcional (                                    ')
    .SQL(' id_empresa, id_opcional, id_venda, quantidade, tipo_movimento, id_usuario,       ')
    .SQL(' observacao, id_vendaitem, data, valor_custo, valor_venda,                        ')
    .SQL(' id_fornecedor, id_setor, id_setor_destino, quantidade_anterior)                  ')
    .SQL(' VALUES (                                                                         ')
    .SQL(' :id_empresa, :id_opcional, :id_venda, :quantidade, :tipo_movimento, :id_usuario, ')
    .SQL(' :observacao, :id_vendaitem, :data, :valor_custo, :valor_venda,                   ')
    .SQL(' :id_fornecedor, :id_setor, :id_setor_destino, :quantidade_anterior)               ')

    .ParamAsInteger('id_empresa', AMovimento.idEmpresa)
    .ParamAsInteger('id_opcional', AMovimento.idOpcional)
    .ParamAsInteger('id_venda', AMovimento.idVenda)
    .ParamAsCurrency('quantidade', AMovimento.quantidade)
    .ParamAsString('tipo_movimento', AMovimento.tipoMovimento)
    .ParamAsInteger('id_usuario', AMovimento.idUsuario)
    .ParamAsString('observacao',AMovimento.observacao)
    .ParamAsInteger('id_vendaItem', AMovimento.idVendaItem)
    .ParamAsDateTime('data', AMovimento.data)
    .ParamAsCurrency('valor_custo', AMovimento.valorCusto)
    .ParamAsCurrency('valor_venda', AMovimento.valorVenda)
    .ParamAsInteger('id_fornecedor', AMovimento.idFornecedor, True)
    .ParamAsInteger('id_setor', AMovimento.idSetor, True)
    .ParamAsInteger('id_setor_destino', AMovimento.idSetorDestino, True)
    .ParamAsFloat('quantidade_anterior',AMovimento.QuantidadeAnterior)
    .ExecSQL;
   //  Commit;

  except
    Rollback;
    raise;
  end;

end;

end.
