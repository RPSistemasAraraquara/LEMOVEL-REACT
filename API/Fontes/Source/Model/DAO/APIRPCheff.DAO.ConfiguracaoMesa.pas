unit APIRPCheff.DAO.ConfiguracaoMesa;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOConfiguracaoMesa = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityConfiguracaoMesa>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityConfiguracaoMesa; override;
  public
    function Buscar(AIdEmpresa: Integer): TAPIRPCheffEntityConfiguracaoMesa;
  end;

implementation

{ TAPIRPCheffDAOConfiguracaoMesa }

function TAPIRPCheffDAOConfiguracaoMesa.Buscar(AIdEmpresa: Integer): TAPIRPCheffEntityConfiguracaoMesa;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where emp_001 = :idEmpresa')
    .ParamAsInteger('idEmpresa', AIdEmpresa)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOConfiguracaoMesa.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityConfiguracaoMesa;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityConfiguracaoMesa.Create;
    try
      Result.idEmpresa := ADataSet.FieldByName('emp_001').AsInteger;
      Result.tempoConsumo := ADataSet.FieldByName('tempo_consumo_mesa').AsInteger;
      Result.utilizaTaxaServico := ADataSet.FieldByName('taxa_adicional_mesa').AsBoolean;
      Result.percentualTaxaServico := ADataSet.FieldByName('taxa_servico_mesa').AsCurrency;
      Result.utilizaCouvert := ADataSet.FieldByName('couvert_mesa').AsBoolean;
      Result.couvertObrigatorio := ADataSet.FieldByName('couvert_obrig_mesa').AsBoolean;
      Result.valorCouvertMasculino := ADataSet.FieldByName('valor_couvert_masc_mesa').AsCurrency;
      Result.valorCouvertFeminino := ADataSet.FieldByName('valor_couvert_fem_mesa').AsCurrency;
      Result.utilizaConsumacaoMinima := ADataSet.FieldByName('consumacao_mesa').AsBoolean;
      Result.consumacaoMinima := ADataSet.FieldByName('consumacao_minima_mesa').AsCurrency;
      Result.permiteTrocoTodasAsFormas := ADataSet.FieldByName('b_permite_troco_todas_formas').AsBoolean;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOConfiguracaoMesa.Select;
begin
  Query.SQL('select emp_001, tempo_consumo_mesa, taxa_adicional_mesa, taxa_servico_mesa,')
    .SQL('  couvert_mesa, couvert_obrig_mesa, valor_couvert_masc_mesa, valor_couvert_fem_mesa,')
    .SQL('  consumacao_mesa, consumacao_minima_mesa, b_permite_troco_todas_formas')
    .SQL('from empresas');
end;

end.
