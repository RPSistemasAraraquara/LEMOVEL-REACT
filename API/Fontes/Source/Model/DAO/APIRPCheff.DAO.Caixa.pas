unit APIRPCheff.DAO.Caixa;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOCaixa = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityCaixa>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityCaixa; override;
  public
    function ProximoCaixaAberto: TAPIRPCheffEntityCaixa;
  end;

implementation

{ TAPIRPCheffDAOCaixa }

function TAPIRPCheffDAOCaixa.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityCaixa;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityCaixa.Create;
    try
      Result.idCaixa := ADataSet.FieldByName('id_caixa').AsInteger;
      Result.idEmpresa := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.dataAbertura := ADataSet.FieldByName('data_abertura').AsDateTime;
      Result.valorInicial := ADataSet.FieldByName('valor_inicial').AsCurrency;
      Result.situacao.FromDBValue(ADataSet.FieldByName('id_situacao').AsInteger);
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOCaixa.ProximoCaixaAberto: TAPIRPCheffEntityCaixa;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where caixa.id_situacao = 4')
    .SQL('and caixa.id_empresa = :idEmpresa')
    .SQL('order by caixa.data_abertura desc, caixa.hora_abertura desc limit 1')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

procedure TAPIRPCheffDAOCaixa.Select;
begin
  Query.SQL('select caixa.id_caixa, caixa.id_empresa, caixa.id_situacao,')
    .SQL('caixa.data_abertura, caixa.valor_inicial')
    .SQL('from caixa');
end;

end.
