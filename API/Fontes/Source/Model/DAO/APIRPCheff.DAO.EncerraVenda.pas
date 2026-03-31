unit APIRPCheff.DAO.EncerraVenda;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Data.DB,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffDAOEncerraVenda = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityEncerraVenda>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityEncerraVenda; override;
  public
    function Buscar(AIdVenda: Integer): TAPIRPCheffEntityEncerraVenda;
    procedure Inserir(AValue: TAPIRPCheffEntityEncerraVenda);
  end;

implementation

{ TAPIRPCheffDAOEncerraVenda }

function TAPIRPCheffDAOEncerraVenda.Buscar(AIdVenda: Integer): TAPIRPCheffEntityEncerraVenda;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := FQuery.SQL('where emp_001 = :idEmpresa')
    .SQL('and ven_001 = :idVenda')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOEncerraVenda.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityEncerraVenda;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityEncerraVenda.Create;
    try
      Result.idEmpresa    := ADataSet.FieldByName('emp_001').AsInteger;
      Result.idVenda      := ADataSet.FieldByName('ven_001').AsInteger;
      Result.valor        := ADataSet.FieldByName('enc_003').AsCurrency;
      Result.acrescimo    := ADataSet.FieldByName('enc_006').AsCurrency;
      Result.desconto     := ADataSet.FieldByName('enc_007').AsCurrency;
      Result.idFormaPgto  := ADataSet.FieldByName('for_001').AsInteger;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOEncerraVenda.Inserir(AValue: TAPIRPCheffEntityEncerraVenda);
var
  LId: Integer;
begin
  LId := Self.ProximoId(FIdEmpresa, 'encerraVenda', 'enc_001', 'emp_001');
  StartTransaction;
  try
    FQuery.SQL('insert into encerraVenda(                                     ')
      .SQL('  enc_001, emp_001, ven_001, enc_003, enc_006,                    ')
      .SQL('  enc_007, for_001, sit_001, enc_002)                             ')
      .SQL('values (                                                          ')
      .SQL('  :enc_001, :emp_001, :ven_001, :enc_003, :enc_006,               ')
      .SQL('  :enc_007, :for_001, :sit_001, localtimestamp)                   ')
      .ParamAsInteger('enc_001', LId)
      .ParamAsInteger('emp_001', AValue.idEmpresa)
      .ParamAsInteger('ven_001', AValue.idVenda)
      .ParamAsCurrency('enc_003', AValue.valor, True)
      .ParamAsCurrency('enc_006', AValue.acrescimo)
      .ParamAsCurrency('enc_007', AValue.desconto)
      .ParamAsInteger('for_001', AValue.idFormaPgto, True)
      .ParamAsInteger('sit_001', 1)
      .ExecSQL;
    Commit;
    AValue.idEncerraVenda := LId;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOEncerraVenda.Select;
begin
  FQuery.SQL('select enc_001, emp_001, ven_001, enc_002, enc_003,')
    .SQL('  for_001, sit_001, enc_006, enc_007                   ')
    .SQL('from encerraVenda                                       ');
end;

end.
