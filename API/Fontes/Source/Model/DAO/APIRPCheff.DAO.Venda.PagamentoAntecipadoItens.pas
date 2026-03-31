unit APIRPCheff.DAO.Venda.PagamentoAntecipadoItens;

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
    TAPIRPCheffDAOVendaPagamentoAntecipadoItens = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityVendaPagamentoAntecipadoItens>)
  private
    procedure Select;
  protected
     function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaPagamentoAntecipadoItens; override;
  public
    procedure Inserir(AValue:TAPIRPCheffEntityVendaPagamentoAntecipadoItens);

  end;

implementation

{ TAPIRPCheffDAOVendaPagamentoAntecipadoItens }

function TAPIRPCheffDAOVendaPagamentoAntecipadoItens.DataSetToEntity(ADataSet: TDataSet):TAPIRPCheffEntityVendaPagamentoAntecipadoItens;
begin
  Result:=nil;
  if ADataSet.RecordCount>0 then
  begin
    Result:=TAPIRPCheffEntityVendaPagamentoAntecipadoItens.Create;
    try
      Result.Id                  := ADataSet.FieldByName('id_mestre').AsInteger;
      Result.IdEmpresa           := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.NumeroItem          := ADataSet.FieldByName('ite_001').AsInteger;
      Result.IdMaterial          := ADataSet.FieldByName('mat_001').AsInteger;
      Result.QuantidadePaga      := ADataSet.FieldByName('qtd_paga').AsCurrency;
      Result.ValorPago           := ADataSet.FieldByName('valor_pago').AsCurrency;
      Result.Unitario            := ADataSet.FieldByName('unitario').AsCurrency;

    except
      Result.Free;
      raise
    end;
  end;

end;

procedure TAPIRPCheffDAOVendaPagamentoAntecipadoItens.Inserir(AValue: TAPIRPCheffEntityVendaPagamentoAntecipadoItens);
begin
  StartTransaction;
  try
    FQuery.SQL(' INSERT INTO venda_pag_antecipado_itens( ')
    .SQL('id_mestre,       ')
    .SQL('id_empresa,      ')
    .SQL('ite_001,         ')
    .SQL('mat_001,         ')
    .SQL('qtd_paga,        ')
    .SQL('valor_pago,      ')
    .SQL('unitario)        ')
    .SQL('VALUES(          ')
    .SQL(':id_mestre,      ')
    .SQL(':id_empresa,     ')
    .SQL(':ite_001,        ')
    .SQL(':mat_001,        ')
    .SQL(':qtd_paga,       ')
    .SQL(':valor_pago,     ')
    .SQL(':unitario)       ')

    .ParamAsInteger ('id_mestre', AValue.Id)
    .ParamAsInteger ('id_empresa', FIdEmpresa)
    .ParamAsInteger ('ite_001', AValue.NumeroItem)
    .ParamAsInteger ('mat_001', AValue.IdMaterial)
    .ParamAsCurrency('qtd_paga', AValue.QuantidadePaga)
    .ParamAsCurrency('valor_pago', AValue.ValorPago)
    .ParamAsCurrency('unitario', AValue.Unitario)
    .ExecSQL;
     Commit;
  except
    Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffDAOVendaPagamentoAntecipadoItens.Select;
begin
  FQuery.SQL('SELECT id_mestre, id_empresa, ite_001, mat_001,     ')
    .SQL(' qtd_paga, valor_pago, unitario                         ')
    .SQL(' FROM venda_pag_antecipado_itens                        ')

end;

end.
