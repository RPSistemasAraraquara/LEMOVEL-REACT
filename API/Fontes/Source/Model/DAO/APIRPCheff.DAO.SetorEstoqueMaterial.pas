unit APIRPCheff.DAO.SetorEstoqueMaterial;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOSetorEstoqueMaterial = class(TAPIRPCheffDAOBase<TAPIRPCheffEntitySetorEstoqueMaterial>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntitySetorEstoqueMaterial; override;
  public
    function Buscar(AIdMaterial, AIdSetor: Integer): TAPIRPCheffEntitySetorEstoqueMaterial;
    procedure Inserir(AValue: TAPIRPCheffEntitySetorEstoqueMaterial);
    procedure Atualizar(AValue: TAPIRPCheffEntitySetorEstoqueMaterial);
  end;

implementation

{ TAPIRPCheffDAOSetorEstoqueMaterial }

procedure TAPIRPCheffDAOSetorEstoqueMaterial.Atualizar(AValue: TAPIRPCheffEntitySetorEstoqueMaterial);
begin
  StartTransaction;
  try
    Query.SQL('update setor_estoque_material set')
      .SQL('  quantidade = :quantidade')
      .SQL('where id_empresa = :idEmpresa')
      .SQL('and id_material = :idMaterial')
      .SQL('and id_setor = :idSetor')
      .ParamAsInteger('idEmpresa', AValue.idEmpresa)
      .ParamAsInteger('idMaterial', AValue.idMaterial)
      .ParamAsInteger('idSetor', AValue.idSetor)
      .ParamAsCurrency('quantidade', AValue.quantidade)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TAPIRPCheffDAOSetorEstoqueMaterial.Buscar(AIdMaterial, AIdSetor: Integer): TAPIRPCheffEntitySetorEstoqueMaterial;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where id_empresa = :idEmpresa')
    .SQL('and id_material = :idMaterial')
    .SQL('and id_setor = :idSetor')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idMaterial', AIdMaterial)
    .ParamAsInteger('idSetor', AIdSetor)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOSetorEstoqueMaterial.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntitySetorEstoqueMaterial;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntitySetorEstoqueMaterial.Create;
    try
      Result.idEmpresa := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.idMaterial := ADataSet.FieldByName('id_material').AsInteger;
      Result.idSetor := ADataSet.FieldByName('id_setor').AsInteger;
      Result.quantidade := ADataSet.FieldByName('quantidade').AsCurrency;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOSetorEstoqueMaterial.Inserir(
  AValue: TAPIRPCheffEntitySetorEstoqueMaterial);
begin
  StartTransaction;
  try
    Query.SQL('insert into setor_estoque_material (')
      .SQL('  id_material, id_setor, id_empresa, quantidade)')
      .SQL('values (')
      .SQL('  :id_material, :id_setor, :id_empresa, :quantidade)')
      .ParamAsInteger('id_material', AValue.idMaterial)
      .ParamAsInteger('id_setor', AValue.idSetor)
      .ParamAsInteger('id_empresa', AValue.idEmpresa)
      .ParamAsCurrency('quantidade', AValue.quantidade)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOSetorEstoqueMaterial.Select;
begin
  Query.SQL('select id_material, id_setor, id_empresa, quantidade')
    .SQL('from setor_estoque_material');
end;

end.
