unit APIRPCheff.DAO.Venda.PagamentoParcial;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type

  TAPIRPCheffDAOVendaPagamentoParcial = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityVendaPagamentoParcial>)
  private
    function ProximoIdCaixaItem(AIdEmpresa, AIdCaixa: Integer): Integer;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaPostPagamentoParcial; override;
  public
    procedure Inserir(AValue: TAPIRPCheffEntityVendaPagamentoAntecipado);
    procedure AtualizaPagamentoAntecipado(AValue: TAPIRPCheffEntityVendaPostPagamentoParcial);
  end;

implementation

{ TAPIRPCheffDAOCaixaItem }

procedure TAPIRPCheffDAOVendaPagamentoParcial.AtualizaPagamentoAntecipado(AValue: TAPIRPCheffEntityVendaPostPagamentoParcial);
begin
//  StartTransaction;
//  try
//    FQuery.SQL('update caixaItem set id_encerravenda = :idEncerraVenda,')
//      .SQL('  item_encerravenda = :itemEncerraVenda')
//      .SQL('where id_caixa = :idCaixa')
//      .SQL('and id_empresa = :idEmpresa')
//      .SQL('and id_formaPgto = :idFormaPgto')
//      .SQL('and id_venda = :idVenda')
//      .SQL('and id_encerraVenda is null')
//      .SQL('and item_encerraVenda is null')
//      .ParamAsInteger('idEncerraVenda', AValue.idEncerraVenda)
//      .ParamAsInteger('itemEncerraVenda', AValue.itemEncerraVenda)
//      .ParamAsInteger('idCaixa', AValue.idCaixa)
//      .ParamAsInteger('idEmpresa', AValue.idEmpresa)
//      .ParamAsInteger('idFormaPgto', AValue.idFormaPgto)
//      .ParamAsInteger('idVenda', AValue.idVenda)
//      .ExecSQL;
//    Commit;
//  except
//    Rollback;
//    raise;
//  end;
end;

function TAPIRPCheffDAOVendaPagamentoParcial.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaPostPagamentoParcial;
begin
  Result := nil;
end;

procedure TAPIRPCheffDAOVendaPagamentoParcial.Inserir(AValue: TAPIRPCheffEntityVendaPagamentoAntecipado);
var
  LId: Integer;
begin
  StartTransaction;
  try
    FQuery
      .SQL(' INSERT INTO venda_pag_antecipado ')
      .SQL(' (id_venda, id_empresa, id_formapgto, valor, observacao, id_caixa, ')
      .SQL('  id_caixaitem, id_usuario, b_taxa, valor_taxa, valor_prod, ')
      .SQL('  nro_couvert_m, nro_couvert_f, valor_couvert_m, valor_couvert_f, ')
      .SQL('  autorizacao, valor_juros) ')
      .SQL(' VALUES ')
      .SQL(' (:id_venda, :id_empresa, :id_formapgto, :valor, :observacao, :id_caixa, ')
      .SQL('  :id_caixaitem, :id_usuario, :b_taxa, :valor_taxa, :valor_prod, ')
      .SQL('  :nro_couvert_m, :nro_couvert_f, :valor_couvert_m, :valor_couvert_f, ')
      .SQL('  :autorizacao, :valor_juros)')
      .ParamAsInteger ('id_venda',        AValue.idVenda)
      .ParamAsInteger ('id_empresa',      AValue.idEmpresa)
      .ParamAsInteger ('id_formapgto',    AValue.idFormaPagamento)
      .ParamAsCurrency('valor',           AValue.valorPago)
      .ParamAsString  ('observacao',      AValue.observacao)
      .ParamAsInteger ('id_caixa',        AValue.idCaixa)
      .ParamAsInteger ('id_caixaitem',    AValue.idCaixaItem)
      .ParamAsInteger ('id_usuario',      AValue.idUsuario)
      .ParamAsBoolean ('b_taxa',          AValue.bTaxa)
      .ParamAsCurrency('valor_taxa',      AValue.valorTaxa)
      .ParamAsCurrency('valor_prod',      AValue.valorProd)
      .ParamAsInteger ('nro_couvert_m',   AValue.nroCouvertM)
      .ParamAsInteger ('nro_couvert_f',   AValue.nroCouvertF)
      .ParamAsCurrency('valor_couvert_m', AValue.valorCouvertM)
      .ParamAsCurrency('valor_couvert_f', AValue.valorCouvertF)
      .ParamAsString  ('autorizacao',     AValue.autorizacao)
      .ParamAsCurrency('valor_juros',     AValue.valorJuros)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOVendaPagamentoParcial.ProximoIdCaixaItem(AIdEmpresa, AIdCaixa: Integer): Integer;
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
