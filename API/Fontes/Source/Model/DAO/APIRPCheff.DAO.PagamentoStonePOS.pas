unit APIRPCheff.DAO.PagamentoStonePOS;

interface

uses

  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Base,
  Data.DB,
  System.Generics.Collections,
  System.StrUtils,
  System.SysUtils;

  type
    TAPIRPCheffDAOPagamentoStonePOS = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityPagamentoStonePOS>)
    private
     procedure Select;
    protected
      function DataSetToEntity(ADataSet:TDataSet):TAPIRPCheffEntityPagamentoStonePOS;override;
    public
    procedure Inserir(APagamento:TAPIRPCheffEntityPagamentoStonePOS);

    end;

implementation

{ TAPIRPCheffDAOPagamentoStonePOS }

function TAPIRPCheffDAOPagamentoStonePOS.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityPagamentoStonePOS;
begin
  Result:=nil;

  if ADataSet.RecordCount>0 then
  begin
    Result:=  TAPIRPCheffEntityPagamentoStonePOS.Create;
    try
      Result.Id                  := ADataSet.FieldByName('id').AsInteger;
      Result.IdEmpresa           := ADataSet.FieldByName('idempresa').AsInteger;
      Result.IdVenda             := ADataSet.FieldByName('idvenda').AsInteger;
      Result.ValorPago           := ADataSet.FieldByName('valorpago').AsCurrency;
      Result.CodigoAutotizacao   := ADataSet.FieldByName('codigoautorizacao').AsString;
      Result.DataHoraVenda       := ADataSet.FieldByName('datahora').AsDateTime;
      Result.Bandeira            := ADataSet.FieldByName('terminal').AsString;
      Result.Parcelas            := ADataSet.FieldByName('parcelas').AsInteger;
      Result.Terminal            := ADataSet.FieldByName('terminal').AsString;
    except
      Result.Free;
      raise
    end;
  end;

end;

procedure TAPIRPCheffDAOPagamentoStonePOS.Inserir(APagamento: TAPIRPCheffEntityPagamentoStonePOS);
begin
  StartTransaction;
  try
    Query.SQL(' INSERT INTO pagamentos_stone_pos(                                    ')
    .SQL(' idempresa, idvenda, valorpago, codigoautorizacao, datahora, bandeira, parcelas, terminal)')
    .SQL('values')
    .SQL(' :idempresa, :idvenda, :valorpago, :codigoautorizacao, :datahora, :bandeira, :parcelas, :parcelas) ')

     .ParamAsInteger('idempresa', APagamento.IdEmpresa)
     .ParamAsInteger('idvenda', APagamento.IdVenda)
     .ParamAsCurrency('valorpago', APagamento.ValorPago)
      .ParamAsString('codigoautorizacao',APagamento.CodigoAutotizacao)
     .ParamAsDateTime('datahora', APagamento.DataHoraVenda)
     .ParamAsString('bandeira',APagamento.Bandeira)
     .ParamAsString('parcelas',APagamento.Terminal)
     .ParamAsInteger('parcelas',APagamento.Parcelas)
     .ExecSQL;
     Commit;
  except
    Rollback;
     raise
  end;
end;

procedure TAPIRPCheffDAOPagamentoStonePOS.Select;
begin
  Query.SQL('SELECT id, idempresa, idvenda, valorpago, codigoautorizacao, datahora, bandeira, parcelas, terminal  ')
	 .SQL('  FROM pagamentos_stone_pos');
end;

end.
