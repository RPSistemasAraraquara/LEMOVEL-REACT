unit APIRPCheff.DAO.Mesa;

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
  TAPIRPCheffDAOMesa = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityMesa>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityMesa; override;
  public
    function Busca(AIdMesa: Integer): TAPIRPCheffEntityMesa; overload;
    function Busca(ANumeroMesa: string): TAPIRPCheffEntityMesa; overload;
    function List: TObjectList<TAPIRPCheffEntityMesa>;
    function ListarPorSituacaoVenda(ASituacao: TRPCheffSituacaoVenda): TObjectList<TAPIRPCheffEntityMesa>;
  end;

implementation

{ TAPIRPCheffDAOMesa }

uses
  APIRPCheff.DAO.Factory;

function TAPIRPCheffDAOMesa.Busca(AIdMesa: Integer): TAPIRPCheffEntityMesa;
begin
  Select;
  FQuery.SQL('and mesa.emp_001 = :idEmpresa')
    .SQL('and mesa.mes_001 = :idMesa')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idMesa', AIdMesa)
    .Open;
  Result := DataSetToEntity(FQuery.DataSet);
end;

function TAPIRPCheffDAOMesa.Busca(ANumeroMesa: string): TAPIRPCheffEntityMesa;
begin
  Select;
  FQuery.SQL('and mesa.emp_001 = :idEmpresa')
    .SQL('and mesa.mes_003 = :numeroMesa')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsString('numeroMesa', ANumeroMesa)
    .Open;
  Result := DataSetToEntity(FQuery.DataSet);
end;

function TAPIRPCheffDAOMesa.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityMesa;
var
  LHoraReserva: TTime;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityMesa.Create;
    try
      Result.idEmpresa          := ADataSet.FieldByName('emp_001').AsInteger;
      Result.idMesa             := ADataSet.FieldByName('mes_001').AsInteger;
      Result.descricao          := ADataSet.FieldByName('mes_002').AsString;
      Result.numero             := ADataSet.FieldByName('mes_003').AsString;
      Result.situacao.FromDBValue(ADataSet.FieldByName('statusMesa').AsInteger);
      Result.idVenda            := ADataSet.FieldByName('ven_001').AsInteger;
      Result.nomeReserva        := ADataSet.FieldByName('nome_reserva').AsString;
      Result.telefoneReserva    := ADataSet.FieldByName('telefone_reserva').AsString;
      if Result.situacao = smReservada then
      begin
        Result.dataReserva      := ADataSet.FieldByName('data_reserva').AsDateTime;
        LHoraReserva            := ADataSet.FieldByName('hora_reserva').AsDateTime;
        Result.dataReserva      := RecodeTime(Result.dataReserva, HourOf(LHoraReserva),
          MinuteOf(LHoraReserva), SecondOf(LHoraReserva), MilliSecondOf(LHoraReserva));
      end;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOMesa.List: TObjectList<TAPIRPCheffEntityMesa>;
var
  LDataSet: TDataSet;
begin
  Select;
  FQuery.SQL('and mesa.emp_001 = :idEmpresa')
    .SQL('and mesa.sit_001 in (4, 19)')
    .SQL('order by mesa.mes_003, mesa.mes_001, mesa.mes_002')
    .ParamAsInteger('idEmpresa', FIdEmpresa);
  LDataSet := FQuery.OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOMesa.ListarPorSituacaoVenda(ASituacao: TRPCheffSituacaoVenda): TObjectList<TAPIRPCheffEntityMesa>;
var
  LDataSet: TDataSet;
begin
  Select;
  FQuery.SQL('and mesa.emp_001 = :idEmpresa')
    .SQL('and mesa.sit_001 in (4, 19)')
    .SQL('and coalesce(venda.sit_001, 0) = :situacao')
    .SQL('order by mesa.mes_003, mesa.mes_001, mesa.mes_002')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('situacao', ASituacao.DBValue);
  LDataSet := FQuery.OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOMesa.Select;
begin
  FQuery.SQL('select mesa.mes_001, mesa.mes_002, mesa.mes_003,')
    .SQL(' mesa.emp_001, mesa.sit_001 as statusMesa,')
    .SQL(' mesa.nome_reserva, mesa.telefone_reserva, mesa.data_reserva, mesa.hora_reserva,')
    .SQL(' venda.ven_001')
    .SQL('from mesa')
    .SQL('left join venda on mesa.emp_001 = venda.emp_001')
    .SQL('  and mesa.mes_003 = venda.ven_025')
    .SQL('  and venda.sit_001  in (8, 15, 19, 21)')
    .SQL('where')
    .SQL(' coalesce(venda.ven_024, ''M'') = ''M'' ');
end;

end.
