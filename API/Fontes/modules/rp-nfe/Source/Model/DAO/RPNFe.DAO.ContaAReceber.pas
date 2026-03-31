unit RPNFe.DAO.ContaAReceber;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOContaAReceber = class(TRPNFeDAOBase<TRPNFeEntityContaAReceber>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityContaAReceber; override;
  public
    function Listar(AIdVenda: Integer): TObjectList<TRPNFeEntityContaAReceber>;
  end;

implementation

{ TRPNFeDAOContaAReceber }

function TRPNFeDAOContaAReceber.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityContaAReceber;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TRPNFeEntityContaAReceber.Create;
    try
      Result.IdVenda := ADataSet.FieldByName('id_venda').AsInteger;
      Result.IdEmpresa := ADataSet.FieldByName('id_empresa').AsInteger;
      Result.Documento := ADataSet.FieldByName('documento').AsString;
      Result.DataVencimento := ADataSet.FieldByName('data_vencimento').AsDateTime;
      Result.Valor := ADataSet.FieldByName('valor').AsCurrency;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TRPNFeDAOContaAReceber.Listar(AIdVenda: Integer): TObjectList<TRPNFeEntityContaAReceber>;
begin
  Select;
  Query.SQL('where id_venda = :idVenda')
    .ParamAsInteger('idVenda', AIdVenda);
  Result := OpenQueryToList;
end;

procedure TRPNFeDAOContaAReceber.Select;
begin
  Query.SQL('select id_empresa, id_venda, documento, data_vencimento, valor')
    .SQL('from creceber');
end;

end.
