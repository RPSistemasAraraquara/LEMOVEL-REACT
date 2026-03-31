unit APIRPCheff.DAO.CancelamentoPagamentoStone;

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
    TAPIRPCheffDAOCancelamentoPagamentoStone = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityCancelamentoPagamentoStone>)
    private
     procedure Select;
    protected
      function DataSetToEntity(ADataSet:TDataSet):TAPIRPCheffEntityCancelamentoPagamentoStone;override;
    public
    procedure Inserir(ACancelamento:TAPIRPCheffEntityCancelamentoPagamentoStone);

    end;

implementation

{ TAPIRPCheffDAOCancelamentoPagamentoStone }

function TAPIRPCheffDAOCancelamentoPagamentoStone.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityCancelamentoPagamentoStone;
begin
  Result:=nil;

  if ADataSet.RecordCount>0 then
  begin
    Result:=  TAPIRPCheffEntityCancelamentoPagamentoStone.Create;
    try
      Result.Id                      := ADataSet.FieldByName('id').AsInteger;
      Result.IdEmpresa               := ADataSet.FieldByName('idempresa').AsInteger;
      Result.IdVenda                 := ADataSet.FieldByName('idvenda').AsInteger;
      Result.ValorCancelamento       := ADataSet.FieldByName('valorcancelamento').AsCurrency;
      Result.DataHoraCancelamento    := ADataSet.FieldByName('datahora').AsDateTime;
      Result.CodigoAutorizacao       := ADataSet.FieldByName('codigoautorizacao').AsString;
      Result.Terminal                := ADataSet.FieldByName('terminal').AsString;
    except
      Result.Free;
      raise
    end;
  end;

end;

procedure TAPIRPCheffDAOCancelamentoPagamentoStone.Inserir(ACancelamento: TAPIRPCheffEntityCancelamentoPagamentoStone);
begin
  StartTransaction;
  try
    Query.SQL(' INSERT INTO cancelamento_pagamentos_stonepos(          ')
    .SQL('  idempresa, idvenda, valorcancelamento, datahora, codigoautorizacao, terminal)    ')
    .SQL(' VALUES ( idempresa, idvenda, valorcancelamento, datahora, codigoautorizacao, terminal)')
     .ParamAsInteger('idempresa', ACancelamento.IdEmpresa)
     .ParamAsInteger('idvenda', ACancelamento.IdVenda)
     .ParamAsCurrency('valorcancelamento', ACancelamento.ValorCancelamento)
     .ParamAsDateTime('datahora', ACancelamento.DataHoraCancelamento)
     .ParamAsString('codigoautorizacao',ACancelamento.CodigoAutorizacao)
     .ParamAsString('terminal',ACancelamento.Terminal)
     .ExecSQL;
     Commit;
  except
    Rollback;
     raise
  end;
end;

procedure TAPIRPCheffDAOCancelamentoPagamentoStone.Select;
begin
  Query.SQL('SELECT id, idempresa, idvenda, valorcancelamento, datahora, codigoautorizacao, terminal  ')
	 .SQL(' FROM cancelamento_pagamentos_stonepos');
end;

end.
