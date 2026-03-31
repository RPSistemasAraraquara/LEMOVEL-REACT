unit APIRPCheff.DAO.Comanda;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Data.DB,
  System.DateUtils,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffDAOComanda = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityComanda>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityComanda; override;
  public
    function Busca(AIdComanda: Integer): TAPIRPCheffEntityComanda; overload;
    function Busca(ANumeroComanda: string): TAPIRPCheffEntityComanda; overload;
    function List: TObjectList<TAPIRPCheffEntityComanda>;
    function ListarPorSituacaoVenda(ASituacao: TRPCheffSituacaoVenda): TObjectList<TAPIRPCheffEntityComanda>;
    function ListarPrePago: TObjectList<TAPIRPCheffEntityComanda>;
  end;

implementation

{ TAPIRPCheffDAOComanda }

uses
  APIRPCheff.DAO.Factory;

function TAPIRPCheffDAOComanda.Busca(AIdComanda: Integer): TAPIRPCheffEntityComanda;
begin
  Select;
  FQuery.SQL('and comanda.emp_001 = :idEmpresa')
    .SQL('and comanda.com_001 = :idComanda')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idComanda', AIdComanda)
    .Open;
  Result := DataSetToEntity(FQuery.DataSet);
end;

function TAPIRPCheffDAOComanda.Busca(ANumeroComanda: string): TAPIRPCheffEntityComanda;
begin
  Select;
  FQuery.SQL('and comanda.emp_001 = :idEmpresa')
    .SQL('and comanda.com_003 = :numeroComanda')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsString('numeroComanda', ANumeroComanda)
    .Open;
  Result := DataSetToEntity(FQuery.DataSet);
end;

function TAPIRPCheffDAOComanda.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityComanda;
var
  LHoraReserva: TTime;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityComanda.Create;
    try
      Result.idEmpresa := ADataSet.FieldByName('emp_001').AsInteger;
      Result.idComanda := ADataSet.FieldByName('com_001').AsInteger;
      Result.descricao := ADataSet.FieldByName('com_002').AsString;
      Result.numero := ADataSet.FieldByName('com_003').AsString;
      Result.idVenda := ADataSet.FieldByName('ven_001').AsInteger;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOComanda.List: TObjectList<TAPIRPCheffEntityComanda>;
var
  LDataSet: TDataSet;
begin
  Select;
  FQuery.SQL('and comanda.emp_001 = :idEmpresa')
    .SQL('and comanda.sit_001 = 4')
    .SQL('order by comanda.com_003, comanda.com_001, comanda.com_002')
    .ParamAsInteger('idEmpresa', FIdEmpresa);
  LDataSet := FQuery.OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOComanda.ListarPorSituacaoVenda(ASituacao: TRPCheffSituacaoVenda): TObjectList<TAPIRPCheffEntityComanda>;
var
  LDataSet: TDataSet;
begin
  Select;
  FQuery.SQL('and comanda.emp_001 = :idEmpresa')
    .SQL('and comanda.sit_001 in (4)')
    .SQL('and coalesce(venda.sit_001, 0) = :situacao')
    .SQL('order by comanda.com_003, comanda.com_001, comanda.com_002')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('situacao', ASituacao.DBValue);
  LDataSet := FQuery.OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOComanda.ListarPrePago: TObjectList<TAPIRPCheffEntityComanda>;
var
  LDataSet: TDataSet;
begin
  Select;
  FQuery.SQL('and comanda.emp_001 = :idEmpresa')
    .SQL('and comanda.sit_001 in (4)')
    .SQL('and coalesce(venda.sit_001, 0) = 8')
    .SQL('and venda.cli_001 > 0')
    .SQL('order by comanda.com_003, comanda.com_001, comanda.com_002')
    .ParamAsInteger('idEmpresa', FIdEmpresa);
  LDataSet := FQuery.OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOComanda.Select;
begin
  FQuery.SQL('select comanda.com_001, comanda.com_002, comanda.com_003,')
    .SQL(' comanda.emp_001, comanda.sit_001,')
    .SQL(' venda.ven_001')
    .SQL('from comanda')
    .SQL('left join venda on comanda.emp_001 = venda.emp_001')
    .SQL('  and comanda.com_003 = venda.ven_026')
    .SQL('  and venda.sit_001  in (8, 15, 19, 21)')
    .SQL('where')
    .SQL(' coalesce(venda.ven_024, ''C'') = ''C'' ');
end;

end.
