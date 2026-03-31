unit APIRPCheff.DAO.TipoMovimento;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOTipoMovimento = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityTipoMovimento>)
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityTipoMovimento; override;
  public
    procedure Inserir(AValue: TAPIRPCheffEntityTipoMovimento);
  end;

implementation

{ TAPIRPCheffDAOTipoMovimento }

function TAPIRPCheffDAOTipoMovimento.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityTipoMovimento;
begin
  Result := nil;
end;

procedure TAPIRPCheffDAOTipoMovimento.Inserir(AValue: TAPIRPCheffEntityTipoMovimento);
begin
  StartTransaction;
  try
    FQuery.SQL('insert into tipo_movimento (')
      .SQL('  id_empresa, tipo, data_emissao, valor, documento, observacao,')
      .SQL('  compensado, id_usuario_lancamento, id_contaCorrente,')
      .SQL('  id_situacao, enc_001, ite_001, ven_001)')
      .SQL('values (')
      .SQL('  :id_empresa, :tipo, :data_emissao, :valor, :documento, :observacao,')
      .SQL('  :compensado, :id_usuario_lancamento, :id_contaCorrente,')
      .SQL('  :id_situacao, :enc_001, :ite_001, :ven_001)')
      .ParamAsInteger('id_empresa', AValue.idEmpresa)
      .ParamAsString('tipo', AValue.tipo)
      .ParamAsDateTime('data_emissao', AValue.dataEmissao)
      .ParamAsCurrency('valor', AValue.valor)
      .ParamAsString('documento', AValue.documento, True)
      .ParamAsString('observacao', AValue.observacao, True)
      .ParamAsInteger('compensado', AValue.compensado, True)
      .ParamAsInteger('id_usuario_lancamento', AValue.idUsuarioLancamento, True)
      .ParamAsInteger('id_contaCorrente', AValue.idContaCorrente, True)
      .ParamAsInteger('id_situacao', AValue.situacao.DBValue)
      .ParamAsInteger('enc_001', AValue.idEncerraVenda, True)
      .ParamAsInteger('ite_001', AValue.itemEncerraVenda, True)
      .ParamAsInteger('ven_001', AValue.idVenda)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

end.
