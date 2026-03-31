unit APIRPCheff.DAO.Empresa;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Data.DB,
  System.Generics.Collections,
  System.SysUtils;

type
  TAPIRPCheffDAOEmpresa = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityEmpresa>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityEmpresa; override;
  public
    function List: TObjectList<TAPIRPCheffEntityEmpresa>;
    function Busca: TAPIRPCheffEntityEmpresa;
  end;

implementation

{ TAPIRPCheffDAOEmpresa }

function TAPIRPCheffDAOEmpresa.Busca: TAPIRPCheffEntityEmpresa;
begin
  Select;
  Query.SQL('where emp_001 = :idEmpresa')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .Open;
  Result := DataSetToEntity(Query.DataSet);
end;

function TAPIRPCheffDAOEmpresa.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityEmpresa;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityEmpresa.Create;
    try
      Result.idEmpresa                    := ADataSet.FieldByName('emp_001').AsInteger;
      Result.nome                         := ADataSet.FieldByName('emp_003').AsString;
      Result.numero                       := ADataSet.FieldByName('emp_007').AsString;
      Result.endereco                     := ADataSet.FieldByName('cep_004').AsString;
      Result.telefonePrincipal            := ADataSet.FieldByName('tel_princ').AsInteger;
      Result.telefone                     := ADataSet.FieldByName('emp_013').AsString;
      Result.celular                      := ADataSet.FieldByName('celular').AsString;
      Result.casaNoturna                  := ADataSet.FieldByName('b_casa_noturna').AsBoolean;
      Result.casaControle                 := TRPCheffTipoCasaControle(ADataSet.FieldByName('casa_controle').AsInteger);
      Result.taxaAdicionalMesa            := ADataSet.FieldByName('taxa_adicional_mesa').AsBoolean;
      Result.couvertMesa                  := ADataSet.FieldByName('couvert_mesa').AsBoolean;
      Result.couvertObrigatorioMesa       := ADataSet.FieldByName('couvert_obrig_mesa').AsBoolean;
      Result.valorCouvertMasculinoMesa    := ADataSet.FieldByName('valor_couvert_masc_mesa').AsCurrency;
      Result.valorCouvertFemininoMesa     := ADataSet.FieldByName('valor_couvert_fem_mesa').AsCurrency;
      Result.consumacaoMesa               := ADataSet.FieldByName('consumacao_mesa').AsBoolean;
      Result.consumacaoMinimaMesa         := ADataSet.FieldByName('consumacao_minima_mesa').AsCurrency;
      Result.taxaAdicionalComanda         := ADataSet.FieldByName('taxa_adicional_comanda').AsBoolean;
      Result.couvertComanda               := ADataSet.FieldByName('couvert_comanda').AsBoolean;
      Result.couvertObrigatorioComanda    := ADataSet.FieldByName('couvert_obrig_comanda').AsBoolean;
      Result.valorCouvertMasculinoComanda := ADataSet.FieldByName('valor_couvert_masc_comanda').AsCurrency;
      Result.valorCouvertFemininoComanda  := ADataSet.FieldByName('valor_couvert_fem_comanda').AsCurrency;
      Result.consumacaoComanda            := ADataSet.FieldByName('consumacao_comanda').AsBoolean;
      Result.consumacaoMinimaComanda      := ADataSet.FieldByName('consumacao_minima_comanda').AsCurrency;
      Result.permiteTrocoTodasAsFormas    := ADataSet.FieldByName('b_permite_troco_todas_formas').AsBoolean;
      Result.utilizaRPMovel               := ADataSet.FieldByName('utiliza_rp_movel').AsBoolean;
      Result.utilizaIntegracaoStone       := ADataSet.FieldByName('rp_movel_integracao_stone').AsBoolean;
      Result.UtilizaFichaIndividualMesa   :=ADataSet.FieldByName('imprime_ficha_individual_mesa').AsBoolean;
      Result.UtilizaFichaIndividualComanda:=ADataSet.FieldByName('imprime_ficha_individual_comanda').AsBoolean;
      Result.utilizaIntegracaoCielo       := ADataSet.FieldByName('rp_movel_integracao_cielo').AsBoolean;
      Result.utilizaIntegracaoPagBank     := ADataSet.FieldByName('rp_movel_integracao_pagbank').AsBoolean;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOEmpresa.List: TObjectList<TAPIRPCheffEntityEmpresa>;
begin
  Select;
  Query.SQL('where utiliza_rp_movel = :utiliza')
    .ParamAsBoolean('utiliza', True)
    .Open;
  Result := DataSetToList(Query.DataSet);
end;

procedure TAPIRPCheffDAOEmpresa.Select;
begin
  Query.SQL('select emp_001, emp_007, cep_004, emp_003, emp_013, tel_princ, celular, ')
    .SQL('  b_controle_opc, b_casa_noturna, casa_controle, utiliza_rp_movel,')
    .SQL('  taxa_adicional_mesa, couvert_mesa, couvert_obrig_mesa, valor_couvert_masc_mesa,')
    .SQL('  valor_couvert_fem_mesa, consumacao_mesa, consumacao_minima_mesa,')
    .SQL('  taxa_adicional_comanda, couvert_comanda, couvert_obrig_comanda,')
    .SQL('  b_atualiza_custo_material_composicao, b_considera_rendimento_entrada_composicao,')
    .SQL('  valor_couvert_masc_comanda, valor_couvert_fem_comanda, consumacao_comanda,')
    .SQL('  consumacao_minima_comanda, (coalesce(taxa_servico_mesa, 0)/100) as tx_servico_m,')
    .SQL('  (coalesce(taxa_servico_comanda, 0)/100) as tx_servico_c, b_permite_troco_todas_formas,')
    .SQL('  rp_movel_integracao_stone,imprime_ficha_individual_mesa,imprime_ficha_individual_comanda,')
    .SQL('rp_movel_integracao_cielo,rp_movel_integracao_pagbank')
    .SQL('from empresas');
end;

end.
