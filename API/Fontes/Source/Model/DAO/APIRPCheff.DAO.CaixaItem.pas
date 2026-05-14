unit APIRPCheff.DAO.CaixaItem;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOCaixaItem = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityCaixaItem>)
  private

  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityCaixaItem; override;
  public
    procedure Inserir(AValue: TAPIRPCheffEntityCaixaItem);
    function ProximoIdCaixaItem(AIdEmpresa, AIdCaixa: Integer): Integer;
    procedure AtualizaPagamentoAntecipado(AValue: TAPIRPCheffEntityCaixaItem);
  end;

implementation

{ TAPIRPCheffDAOCaixaItem }

procedure TAPIRPCheffDAOCaixaItem.AtualizaPagamentoAntecipado(AValue: TAPIRPCheffEntityCaixaItem);
begin
  StartTransaction;
  try
    FQuery.SQL('update caixaItem set id_encerravenda = :idEncerraVenda,')
      .SQL('  item_encerravenda = :itemEncerraVenda')
      .SQL('where id_caixa = :idCaixa')
      .SQL('and id_empresa = :idEmpresa')
      .SQL('and id_formaPgto = :idFormaPgto')
      .SQL('and id_venda = :idVenda')
      .SQL('and id_encerraVenda is null')
      .SQL('and item_encerraVenda is null')
      .ParamAsInteger('idEncerraVenda', AValue.idEncerraVenda)
      .ParamAsInteger('itemEncerraVenda', AValue.itemEncerraVenda)
      .ParamAsInteger('idCaixa', AValue.idCaixa)
      .ParamAsInteger('idEmpresa', AValue.idEmpresa)
      .ParamAsInteger('idFormaPgto', AValue.idFormaPgto)
      .ParamAsInteger('idVenda', AValue.idVenda)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOCaixaItem.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityCaixaItem;
begin
  Result := nil;
end;

procedure TAPIRPCheffDAOCaixaItem.Inserir(AValue: TAPIRPCheffEntityCaixaItem);
begin
  StartTransaction;
  try
    FQuery.SQL('insert into caixaItem (')
      .SQL('  id_caixa, id_empresa, item, tipo_movimento, valor,')
      .SQL('  data, hora, id_formaPgto, id_venda, item_encerraVenda,')
      .SQL('  id_encerraVenda, classificacao, antecipado, observacao)')
      .SQL('values (')
      .SQL('  :id_caixa, :id_empresa, :item, :tipo_movimento, :valor,')
      .SQL('  localtimestamp, localtime, :id_formaPgto, :id_venda, :item_encerraVenda,')
      .SQL('  :id_encerraVenda, :classificacao, :antecipado, :observacao)')
      .ParamAsInteger('id_caixa', AValue.idCaixa)
      .ParamAsInteger('id_empresa', AValue.idEmpresa)
      .ParamAsInteger('item', AValue.item)
      .ParamAsString('tipo_movimento', AValue.tipoMovimento)
      .ParamAsCurrency('valor', AValue.valor)
      .ParamAsInteger('id_formaPgto', AValue.idFormaPgto)
      .ParamAsInteger('id_venda', AValue.idVenda)
      .ParamAsInteger('item_encerraVenda', AValue.itemEncerraVenda, true)
      .ParamAsInteger('id_encerraVenda', AValue.idEncerraVenda, true)
      .ParamAsString('classificacao', AValue.classificacao, True)
      .ParamAsBoolean('antecipado', AValue.antecipado)
      .ParamAsString('observacao', AValue.observacao, True)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOCaixaItem.ProximoIdCaixaItem(AIdEmpresa, AIdCaixa: Integer): Integer;
var
  LDataSet: TDataSet;
begin
  LDataSet := FQuery.SQL('select coalesce(max(item), 0) + 1 as item ')
    .SQL('from caixaitem')
    .SQL('where id_empresa = :idEmpresa')
    .SQL('and id_caixa = :idCaixa')
    .ParamAsInteger('idEmpresa', AIdEmpresa)
    .ParamAsInteger('idCaixa', AIdCaixa)
    .OpenDataSet;
  try
    Result := LDataSet.FieldByName('item').AsInteger;
  finally
    FreeAndNil(LDataSet);
  end;
end;

end.
