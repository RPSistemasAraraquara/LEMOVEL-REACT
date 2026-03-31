unit APIRPCheff.DAO.VendaPrePago;

interface

uses
  APIRPCheff.DAO.Base,
  APIRPCheff.Entity.Classes,
  Data.DB,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffDAOVendaPrePago = class(TAPIRPCheffDAOBase<TAPIRPCheffEntityVendaPrePago>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaPrePago; override;
  public
    function Listar(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityVendaPrePago>;
  end;

implementation

{ TAPIRPCheffDAOVendaPrePago }

function TAPIRPCheffDAOVendaPrePago.DataSetToEntity(ADataSet: TDataSet): TAPIRPCheffEntityVendaPrePago;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TAPIRPCheffEntityVendaPrePago.Create;
    try
      Result.Id := ADataSet.FieldByName('id_pre').AsInteger;
      Result.IdVenda := ADataSet.FieldByName('id_venda').AsInteger;
      Result.IdEmpresa := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.IdFormaPagamento := ADataSet.FieldByName('id_formapgto').AsInteger;
      Result.Valor := ADataSet.FieldByName('valor').AsCurrency;
      Result.Data := ADataSet.FieldByName('data').AsDateTime;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TAPIRPCheffDAOVendaPrePago.Listar(AIdVenda: Integer): TObjectList<TAPIRPCheffEntityVendaPrePago>;
var
  LDataSet: TDataSet;
begin
  Select;
  LDataSet := FQuery.SQL('where id_empresa = :idEmpresa')
    .SQL('and id_venda = :idVenda')
    .ParamAsInteger('idEmpresa', FIdEmpresa)
    .ParamAsInteger('idVenda', AIdVenda)
    .OpenDataSet;
  try
    Result := DataSetToList(LDataSet);
  finally
    FreeAndNil(LDataSet);

  end;
end;

procedure TAPIRPCheffDAOVendaPrePago.Select;
begin
  FQuery.SQL('select id_pre, id_venda, id_empresa, id_formapgto, valor, data')
    .SQL('from venda_pre_pago');
end;

end.
