unit APIRPCheff.DAO.SetorEstoqueComposicao;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOSetorEstoqueComposicao = class(TAPIRPCheffDAOBase<TAPIRPCheffEntitySetorEstoqueComposicao>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntitySetorEstoqueComposicao; override;
  public
    procedure Inserir(AValue: TAPIRPCheffEntitySetorEstoqueComposicao);
    procedure Alterar(AValue: TAPIRPCheffEntitySetorEstoqueComposicao);
    function Buscar(AIdComposicao, AIdSetor: Integer): TAPIRPCheffEntitySetorEstoqueComposicao;
  end;

implementation

{ TAPIRPCheffDAOSetorEstoqueComposicao }

procedure TAPIRPCheffDAOSetorEstoqueComposicao.Alterar(AValue: TAPIRPCheffEntitySetorEstoqueComposicao);
begin
  StartTransaction;
  try
    Query.SQL('update setor_estoque_composicao set quantidade = :quantidade')
      .SQL('where id_composicao = :idComposicao')
      .SQL('and id_setor = :idSetor')
      .SQL('and id_empresa = :idEmpresa')
      .ParamAsCurrency('quantidade', AValue.quantidade)
      .ParamAsInteger('idComposicao', AValue.idComposicao)
      .ParamAsInteger('idSetor', AValue.idSetor)
      .ParamAsInteger('idEmpresa', AValue.idEmpresa)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOSetorEstoqueComposicao.Buscar(AIdComposicao,  AIdSetor: Integer): TAPIRPCheffEntitySetorEstoqueComposicao;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where id_empresa = :idEmpresa')
    .SQL('and id_composicao = :idComposicao')
    .SQL('and id_setor = :idSetor')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idComposicao', AIdComposicao)
    .ParamAsInteger('idSetor', AIdSetor)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOSetorEstoqueComposicao.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntitySetorEstoqueComposicao;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntitySetorEstoqueComposicao.Create;
    try
      Result.idComposicao       := ADataSet.FieldByName('id_composicao').AsInteger;
      Result.idSetor            := ADataSet.FieldByName('id_setor').AsInteger;
      Result.idEmpresa          := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.quantidade         := ADataSet.FieldByName('quantidade').AsCurrency;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOSetorEstoqueComposicao.Inserir(AValue: TAPIRPCheffEntitySetorEstoqueComposicao);
begin
  StartTransaction;
  try
    Query.SQL('insert into setor_estoque_composicao (')
      .SQL('  id_empresa, id_composicao, id_setor, quantidade)')
      .SQL('values (')
      .SQL('  :id_empresa, :id_composicao, :id_setor, :quantidade)')
      .ParamAsCurrency('quantidade', AValue.quantidade)
      .ParamAsInteger('id_composicao', AValue.idComposicao)
      .ParamAsInteger('id_setor', AValue.idSetor)
      .ParamAsInteger('id_empresa', AValue.idEmpresa)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOSetorEstoqueComposicao.Select;
begin
  Query.SQL('select id_empresa, id_setor, id_composicao, quantidade')
    .SQL('from setor_estoque_composicao');
end;

end.
