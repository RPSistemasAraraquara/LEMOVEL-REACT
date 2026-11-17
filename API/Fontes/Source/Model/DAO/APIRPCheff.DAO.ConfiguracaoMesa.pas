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
    function Buscar(AIdEmpresa: Integer; const ATerminal: string = ''): TAPIRPCheffEntityConfiguracaoMesa;
  end;

implementation

{ TAPIRPCheffDAOConfiguracaoMesa }

function TAPIRPCheffDAOConfiguracaoMesa.Buscar(AIdEmpresa: Integer; const ATerminal: string): TAPIRPCheffEntityConfiguracaoMesa;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where empresas.emp_001 = :idEmpresa')
    .ParamAsString('terminal', Trim(ATerminal))
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
      Result.idEmpresa                 := ADataSet.FieldByName('emp_001').AsInteger;
      Result.tempoConsumo              := ADataSet.FieldByName('tempo_consumo_mesa').AsInteger;
      Result.utilizaTaxaServico        := ADataSet.FieldByName('utiliza_taxa_servico_garcom').AsBoolean;
      Result.percentualTaxaServico     := ADataSet.FieldByName('taxa_servico_garcom_percentual').AsCurrency;
      Result.utilizaCouvert            := ADataSet.FieldByName('couvert_mesa').AsBoolean;
      Result.couvertObrigatorio        := ADataSet.FieldByName('couvert_obrig_mesa').AsBoolean;
      Result.valorCouvertMasculino     := ADataSet.FieldByName('valor_couvert_masc_mesa').AsCurrency;
      Result.valorCouvertFeminino      := ADataSet.FieldByName('valor_couvert_fem_mesa').AsCurrency;
      Result.utilizaConsumacaoMinima   := ADataSet.FieldByName('consumacao_mesa').AsBoolean;
      Result.consumacaoMinima          := ADataSet.FieldByName('consumacao_minima_mesa').AsCurrency;
      Result.permiteTrocoTodasAsFormas := ADataSet.FieldByName('b_permite_troco_todas_formas').AsBoolean;
      Result.integracaoNfce            := ADataSet.FieldByName('integracao_nfce').AsBoolean;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOConfiguracaoMesa.Select;
begin
  Query.SQL('select empresas.emp_001, tempo_consumo_mesa,')
    .SQL('  couvert_mesa, couvert_obrig_mesa, valor_couvert_masc_mesa, valor_couvert_fem_mesa,')
    .SQL('  consumacao_mesa, consumacao_minima_mesa, b_permite_troco_todas_formas,')
    .SQL('  integracao_nfce')
    .SQL(', coalesce(c.utiliza_taxa_servico_garcom, false) as utiliza_taxa_servico_garcom,')
    .SQL('  coalesce(c.taxa_servico_garcom_percentual, 0) as taxa_servico_garcom_percentual')
    .SQL('from empresas')
    .SQL('left join public.terminal t on t.id_empresa = empresas.emp_001')
    .SQL('  and t.terminal = nullif(:terminal, '''')')
    .SQL('left join public.configuracao_mesa c on c.id_empresa = t.id_empresa and c.id_terminal = t.id_terminal');
end;

end.
