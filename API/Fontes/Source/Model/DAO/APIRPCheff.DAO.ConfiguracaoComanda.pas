unit APIRPCheff.DAO.ConfiguracaoComanda;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOConfiguracaoComanda = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityConfiguracaoComanda>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityConfiguracaoComanda; override;
  public
    function Buscar(AIdEmpresa: Integer): TAPIRPCheffEntityConfiguracaoComanda;
  end;

implementation

{ TAPIRPCheffDAOConfiguracaoComanda }

function TAPIRPCheffDAOConfiguracaoComanda.Buscar(AIdEmpresa: Integer): TAPIRPCheffEntityConfiguracaoComanda;
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

function TAPIRPCheffDAOConfiguracaoComanda.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityConfiguracaoComanda;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityConfiguracaoComanda.Create;
    try
      Result.idEmpresa := ADataSet.FieldByName('emp_001').AsInteger;
      Result.tempoConsumo := ADataSet.FieldByName('tempo_consumo_comanda').AsInteger;
      Result.utilizaTaxaServico := ADataSet.FieldByName('taxa_adicional_comanda').AsBoolean;
      Result.percentualTaxaServico := ADataSet.FieldByName('taxa_servico_comanda').AsCurrency;
      Result.utilizaCouvert := ADataSet.FieldByName('couvert_comanda').AsBoolean;
      Result.couvertObrigatorio := ADataSet.FieldByName('couvert_obrig_comanda').AsBoolean;
      Result.valorCouvertMasculino := ADataSet.FieldByName('valor_couvert_masc_comanda').AsCurrency;
      Result.valorCouvertFeminino := ADataSet.FieldByName('valor_couvert_fem_comanda').AsCurrency;
      Result.utilizaConsumacaoMinima := ADataSet.FieldByName('consumacao_comanda').AsBoolean;
      Result.consumacaoMinima := ADataSet.FieldByName('consumacao_minima_comanda').AsCurrency;
      Result.permiteTrocoTodasAsFormas := ADataSet.FieldByName('b_permite_troco_todas_formas').AsBoolean;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOConfiguracaoComanda.Select;
begin
  Query.SQL('select emp_001, tempo_consumo_comanda, taxa_adicional_comanda,')
    .SQL('  taxa_servico_comanda, couvert_comanda, couvert_obrig_comanda, valor_couvert_masc_comanda,')
    .SQL('  valor_couvert_fem_comanda, consumacao_comanda, consumacao_minima_comanda,')
    .SQL('  b_permite_troco_todas_formas')
    .SQL('from empresas');
end;

end.
