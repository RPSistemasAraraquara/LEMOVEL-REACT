unit RPNFe.DAO.VendaItem;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOVendaItem = class(TRPNFeDAOBase<TRPNFeEntityVendaItem>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityVendaItem; override;
  public
    function Listar(AIdVenda: Integer): TObjectList<TRPNFeEntityVendaItem>;
  end;

implementation

{ TRPNFeDAOVendaItem }

function TRPNFeDAOVendaItem.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityVendaItem;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TRPNFeEntityVendaItem.Create;
    try
      Result.NumeroItem := ADataSet.FieldByName('ITE_001').AsInteger;
      Result.Quantidade := ADataSet.FieldByName('ITE_002').AsFloat;
      Result.ValorUnitario := ADataSet.FieldByName('valorUnitario').AsFloat;
      Result.ValorTotal := ADataSet.FieldByName('valorTotal').AsFloat;

      Result.Produto.Codigo := ADataSet.FieldByName('MAT_001').AsInteger;
      Result.Produto.Descricao := ADataSet.FieldByName('MAT_003').AsString;
      Result.Produto.Ean := ADataSet.FieldByName('MAT_004').AsString;
      Result.Produto.NCM := ADataSet.FieldByName('NCM').AsString;
      Result.Produto.CEST := ADataSet.FieldByName('CEST').AsString;
      Result.Produto.CFOPConsumidor := ADataSet.FieldByName('CFOP_CONSUMIDOR').AsString;
      Result.Produto.Servico := ADataSet.FieldByName('B_SERVICO').AsBoolean;
      Result.Produto.Iss := ADataSet.FieldByName('ISS').AsFloat;
      Result.Produto.IssExigibilidade := ADataSet.FieldByName('ISS_EXIGIBILIDADE').AsInteger;
      Result.Produto.IssIncentivo := ADataSet.FieldByName('ISS_INCENTIVO').AsInteger;
      Result.Produto.IssServico := ADataSet.FieldByName('ISS_SERVICO').AsString;
      Result.Produto.OrmCodigo := ADataSet.FieldByName('ORM_CODIGO').AsInteger;
      Result.Produto.CstConsumidor := ADataSet.FieldByName('CST_CONSUMIDOR').AsInteger;
      Result.Produto.CsoCodigo := ADataSet.FieldByName('CSO_CODIGO').AsInteger;
      Result.Produto.Icms := ADataSet.FieldByName('ICMS').AsFloat;
      Result.Produto.PisCodigoSaida := ADataSet.FieldByName('PIS_CODIGO_SAIDA').AsInteger;
      Result.Produto.Pis := ADataSet.FieldByName('PIS').AsFloat;
      Result.Produto.CofinsCodigoSaida := ADataSet.FieldByName('COF_CODIGO_SAIDA').AsInteger;
      Result.Produto.Cofins := ADataSet.FieldByName('COFINS').AsFloat;
      Result.Produto.ReducaoBaseCalculoIcms := ADataSet.FieldByName('REDBASECALCICMS').AsFloat;
      Result.Produto.ReducaoBaseCalculoSt := ADataSet.FieldByName('REDBASECALCST').AsFloat;
      Result.Produto.CodigoAnp := ADataSet.FieldByName('codigo_anp').AsString;
      Result.Produto.PesoPartidaAnp := ADataSet.FieldByName('peso_partida_anp').AsFloat;
      Result.Produto.Pglp := ADataSet.FieldByName('Pglp').AsFloat;
      Result.Produto.Pgnn := ADataSet.FieldByName('Pgnn').AsFloat;
      Result.Produto.Pgni := ADataSet.FieldByName('Pgni').AsFloat;
      Result.Produto.Adrem := ADataSet.FieldByName('Adrem').AsFloat;

      Result.Unidade.Codigo := ADataSet.FieldByName('UNI_001').AsInteger;
      Result.Unidade.Unidade := ADataSet.FieldByName('UNI_003').AsString;
      Result.Unidade.Descricao := ADataSet.FieldByName('UNI_002').AsString;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TRPNFeDAOVendaItem.Listar(AIdVenda: Integer): TObjectList<TRPNFeEntityVendaItem>;
begin
  Select;
  Query.SQL('where vendaItem.ven_001 = :idVenda')
    .SQL('and vendaItem.sit_001 not in (0, 1, 2, 3)')
    .SQL('order by vendaItem.ite_001')
    .ParamAsInteger('idVenda', AIdVenda);
  Result := OpenQueryToList;
end;

procedure TRPNFeDAOVendaItem.Select;
begin
  Query.SQL('select vendaItem.ite_001, vendaItem.ite_002, ')
    .SQL('  round((vendaItem.ite_005 / vendaItem.ite_002), 3) AS valorUnitario,')
    .SQL('  vendaItem.ite_005 as valorTotal,')
    .SQL('  materiais.mat_001, materiais.mat_003, materiais.mat_004, materiais.ncm,')
    .SQL('  materiais.cest, materiais.cfop_consumidor, materiais.b_servico, materiais.iss,')
    .SQL('  materiais.iss_exigibilidade, materiais.iss_incentivo, materiais.iss_servico,')
    .SQL('  materiais.orm_codigo, materiais.cst_consumidor, materiais.cso_codigo,')
    .SQL('  materiais.icms, materiais.pis_codigo_saida, materiais.pis,')
    .SQL('  materiais.cof_codigo_saida, materiais.cofins, materiais.redBaseCalcIcms,')
    .SQL('  materiais.redBaseCalcSt, materiais.codigo_anp, materiais.peso_partida_anp,')
    .SQL('  materiais.pglp, materiais.pgnn, materiais.pgni, materiais.adrem,')
    .SQL('  unidades.uni_001, unidades.uni_002, unidades.uni_003')
    .SQL('from vendaItem')
    .SQL('inner join materiais on materiais.mat_001 = vendaItem.mat_001')
    .SQL('and materiais.emp_001 = vendaItem.emp_001')
    .SQL('inner join unidades on unidades.uni_001 = materiais.uni_001')
    .SQL('and unidades.emp_001 = materiais.emp_001');
end;

end.
