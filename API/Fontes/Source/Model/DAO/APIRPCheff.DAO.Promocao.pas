unit APIRPCheff.DAO.Promocao;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  Data.DB,
  System.SysUtils;

type
  TAPIRPCheffDAOPromocao = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityPromocao>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityPromocao; override;
  public
    function Buscar(AIdProduto: Integer): TAPIRPCheffEntityPromocao;
  end;

implementation

{ TAPIRPCheffDAOPromocao }

function TAPIRPCheffDAOPromocao.Buscar(AIdProduto: Integer): TAPIRPCheffEntityPromocao;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := Query.SQL('where id_empresa = :idEmpresa')
    .SQL('and id_material = :idProduto')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idProduto', AIdProduto)
    .OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    FreeAndNil(LDataSet);
  end;
end;

function TAPIRPCheffDAOPromocao.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityPromocao;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityPromocao.Create;
    try
      Result.idPromocao := ADataSet.FieldByName('id_promocao').AsInteger;
      Result.idEmpresa := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.idProduto := ADataSet.FieldByName('id_material').AsInteger;
      Result.tipoDesconto.FromDBValue(ADataSet.FieldByName('tipo_desconto').AsInteger);
      Result.segundaFeira := ADataSet.FieldByName('dia_seg').AsBoolean;
      Result.tercaFeira := ADataSet.FieldByName('dia_ter').AsBoolean;
      Result.quartaFeira := ADataSet.FieldByName('dia_qua').AsBoolean;
      Result.quintaFeira := ADataSet.FieldByName('dia_qui').AsBoolean;
      Result.sextaFeira := ADataSet.FieldByName('dia_sex').AsBoolean;
      Result.sabado := ADataSet.FieldByName('dia_sab').AsBoolean;
      Result.domingo := ADataSet.FieldByName('dia_dom').AsBoolean;
      Result.tipoMesa := ADataSet.FieldByName('tipo_mesa').AsBoolean;
      Result.tipoComanda := ADataSet.FieldByName('tipo_comanda').AsBoolean;
      Result.descontoSegundaPadrao := ADataSet.FieldByName('desconto_seg_padrao').AsCurrency;
      Result.descontoSegundaTamanhoP := ADataSet.FieldByName('desconto_seg_tam_p').AsCurrency;
      Result.descontoSegundaTamanhoM := ADataSet.FieldByName('desconto_seg_tam_m').AsCurrency;
      Result.descontoSegundaTamanhoG := ADataSet.FieldByName('desconto_seg_tam_g').AsCurrency;
      Result.descontoSegundaTamanhoGG := ADataSet.FieldByName('desconto_seg_tam_gg').AsCurrency;
      Result.descontoSegundaTamanhoExtra := ADataSet.FieldByName('desconto_seg_tam_extra').AsCurrency;
      Result.descontoTercaPadrao := ADataSet.FieldByName('desconto_ter_padrao').AsCurrency;
      Result.descontoTercaTamanhoP := ADataSet.FieldByName('desconto_ter_tam_p').AsCurrency;
      Result.descontoTercaTamanhoM := ADataSet.FieldByName('desconto_ter_tam_m').AsCurrency;
      Result.descontoTercaTamanhoG := ADataSet.FieldByName('desconto_ter_tam_g').AsCurrency;
      Result.descontoTercaTamanhoGG := ADataSet.FieldByName('desconto_ter_tam_gg').AsCurrency;
      Result.descontoTercaTamanhoExtra := ADataSet.FieldByName('desconto_ter_tam_extra').AsCurrency;
      Result.descontoQuartaPadrao := ADataSet.FieldByName('desconto_qua_padrao').AsCurrency;
      Result.descontoQuartaTamanhoP := ADataSet.FieldByName('desconto_qua_tam_p').AsCurrency;
      Result.descontoQuartaTamanhoM := ADataSet.FieldByName('desconto_qua_tam_m').AsCurrency;
      Result.descontoQuartaTamanhoG := ADataSet.FieldByName('desconto_qua_tam_g').AsCurrency;
      Result.descontoQuartaTamanhoGG := ADataSet.FieldByName('desconto_qua_tam_gg').AsCurrency;
      Result.descontoQuartaTamanhoExtra := ADataSet.FieldByName('desconto_qua_tam_extra').AsCurrency;
      Result.descontoQuintaPadrao := ADataSet.FieldByName('desconto_qui_padrao').AsCurrency;
      Result.descontoQuintaTamanhoP := ADataSet.FieldByName('desconto_qui_tam_p').AsCurrency;
      Result.descontoQuintaTamanhoM := ADataSet.FieldByName('desconto_qui_tam_m').AsCurrency;
      Result.descontoQuintaTamanhoG := ADataSet.FieldByName('desconto_qui_tam_g').AsCurrency;
      Result.descontoQuintaTamanhoGG := ADataSet.FieldByName('desconto_qui_tam_gg').AsCurrency;
      Result.descontoQuintaTamanhoExtra := ADataSet.FieldByName('desconto_qui_tam_extra').AsCurrency;
      Result.descontoSextaPadrao := ADataSet.FieldByName('desconto_sex_padrao').AsCurrency;
      Result.descontoSextaTamanhoP := ADataSet.FieldByName('desconto_sex_tam_p').AsCurrency;
      Result.descontoSextaTamanhoM := ADataSet.FieldByName('desconto_sex_tam_m').AsCurrency;
      Result.descontoSextaTamanhoG := ADataSet.FieldByName('desconto_sex_tam_g').AsCurrency;
      Result.descontoSextaTamanhoGG := ADataSet.FieldByName('desconto_sex_tam_gg').AsCurrency;
      Result.descontoSextaTamanhoExtra := ADataSet.FieldByName('desconto_sex_tam_extra').AsCurrency;
      Result.descontoSabadoPadrao := ADataSet.FieldByName('desconto_sab_padrao').AsCurrency;
      Result.descontoSabadoTamanhoP := ADataSet.FieldByName('desconto_sab_tam_p').AsCurrency;
      Result.descontoSabadoTamanhoM := ADataSet.FieldByName('desconto_sab_tam_m').AsCurrency;
      Result.descontoSabadoTamanhoG := ADataSet.FieldByName('desconto_sab_tam_g').AsCurrency;
      Result.descontoSabadoTamanhoGG := ADataSet.FieldByName('desconto_sab_tam_gg').AsCurrency;
      Result.descontoSabadoTamanhoExtra := ADataSet.FieldByName('desconto_sab_tam_extra').AsCurrency;
      Result.descontoDomingoPadrao := ADataSet.FieldByName('desconto_dom_padrao').AsCurrency;
      Result.descontoDomingoTamanhoP := ADataSet.FieldByName('desconto_dom_tam_p').AsCurrency;
      Result.descontoDomingoTamanhoM := ADataSet.FieldByName('desconto_dom_tam_m').AsCurrency;
      Result.descontoDomingoTamanhoG := ADataSet.FieldByName('desconto_dom_tam_g').AsCurrency;
      Result.descontoDomingoTamanhoGG := ADataSet.FieldByName('desconto_dom_tam_gg').AsCurrency;
      Result.descontoDomingoTamanhoExtra := ADataSet.FieldByName('desconto_dom_tam_extra').AsCurrency;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffDAOPromocao.Select;
begin
  Query.SQL('select id_promocao, id_empresa, id_material, tipo_desconto,')
    .SQL('  dia_seg, dia_ter, dia_qua, dia_qui, dia_sex, dia_sab, dia_dom,')
    .SQL('  tipo_mesa, tipo_comanda, desconto_seg_padrao, desconto_seg_tam_p,')
    .SQL('  desconto_seg_tam_m, desconto_seg_tam_g, desconto_seg_tam_gg,')
    .SQL('  desconto_seg_tam_extra, desconto_ter_padrao, desconto_ter_tam_p,')
    .SQL('  desconto_ter_tam_m, desconto_ter_tam_g, desconto_ter_tam_gg,')
    .SQL('  desconto_ter_tam_extra, desconto_qua_padrao, desconto_qua_tam_p,')
    .SQL('  desconto_qua_tam_m, desconto_qua_tam_g, desconto_qua_tam_gg,')
    .SQL('  desconto_qua_tam_extra, desconto_qui_padrao, desconto_qui_tam_p,')
    .SQL('  desconto_qui_tam_m, desconto_qui_tam_g, desconto_qui_tam_gg,')
    .SQL('  desconto_qui_tam_extra, desconto_sex_padrao, desconto_sex_tam_p,')
    .SQL('  desconto_sex_tam_m, desconto_sex_tam_g, desconto_sex_tam_gg,')
    .SQL('  desconto_sex_tam_extra, desconto_sab_padrao, desconto_sab_tam_p,')
    .SQL('  desconto_sab_tam_m, desconto_sab_tam_g, desconto_sab_tam_gg,')
    .SQL('  desconto_sab_tam_extra, desconto_dom_padrao, desconto_dom_tam_p,')
    .SQL('  desconto_dom_tam_m, desconto_dom_tam_g, desconto_dom_tam_gg,')
    .SQL('  desconto_dom_tam_extra')
    .SQL('from promocao');
end;

end.
