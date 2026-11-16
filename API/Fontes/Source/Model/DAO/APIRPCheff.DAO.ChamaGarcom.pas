unit APIRPCheff.DAO.ChamaGarcom;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOChamaGarcom = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityChamaGarcom>)
  private
    procedure GarantirTabela;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityChamaGarcom; override;
  public
    procedure Inserir(const ANumeroMesa: string);
  end;

implementation

var
  GChamaGarcomSchemaChecked: Boolean = False;
  GChamaGarcomSchemaLock: TObject;

function TAPIRPCheffDAOChamaGarcom.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityChamaGarcom;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityChamaGarcom.Create;
    try
      Result.id := ADataSet.FieldByName('id').AsInteger;
      Result.idEmpresa := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.numeroMesa := ADataSet.FieldByName('numero_mesa').AsString;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOChamaGarcom.GarantirTabela;
begin
  if GChamaGarcomSchemaChecked then
    Exit;

  TMonitor.Enter(GChamaGarcomSchemaLock);
  try
    if GChamaGarcomSchemaChecked then
      Exit;

    Query.SQL('create table if not exists chama_garcom (')
      .SQL('  id integer generated always as identity,')
      .SQL('  id_empresa integer not null,')
      .SQL('  numero_mesa varchar(20),')
      .SQL('  constraint pk_chama_garcom primary key (id)')
      .SQL(')')
      .ExecSQL;

    GChamaGarcomSchemaChecked := True;
  finally
    TMonitor.Exit(GChamaGarcomSchemaLock);
  end;
end;

procedure TAPIRPCheffDAOChamaGarcom.Inserir(const ANumeroMesa: string);
begin
  GarantirTabela;
  StartTransaction;
  try
    Query.SQL('insert into chama_garcom (id_empresa, numero_mesa)')
      .SQL('values (:id_empresa, :numero_mesa)')
      .ParamAsInteger('id_empresa', FIdEmpresa)
      .ParamAsString('numero_mesa', Copy(Trim(ANumeroMesa), 1, 20))
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

initialization
  GChamaGarcomSchemaLock := TObject.Create;

finalization
  FreeAndNil(GChamaGarcomSchemaLock);

end.
