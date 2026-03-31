unit RPNFe.DAO.Estado;

interface

uses
  System.SysUtils,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOEstado = class(TRPNFeDAOBase<TRPNFeEntityEstado>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityEstado; override;
  public
    function Buscar(AUF: string): TRPNFeEntityEstado;
    function CodigoUF(AUF: string): Integer;
  end;

implementation

{ TRPNFeDAOEstado }

function TRPNFeDAOEstado.Buscar(AUF: string): TRPNFeEntityEstado;
begin
  Select;
  Query.SQL('where est_003 = :uf')
    .ParamAsString('uf', AUF);
  Result := OpenQueryToEntity;
end;

function TRPNFeDAOEstado.CodigoUF(AUF: string): Integer;
var
  LEstado: TRPNFeEntityEstado;
begin
  LEstado := Buscar(AUF);
  try
    Result := LEstado.CodigoUF;
  finally
    LEstado.Free;
  end;
end;

function TRPNFeDAOEstado.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityEstado;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TRPNFeEntityEstado.Create;
    try
      Result.Id := ADataSet.FieldByName('est_001').AsInteger;
      Result.Nome := ADataSet.FieldByName('est_002').AsString;
      Result.Sigla := ADataSet.FieldByName('est_003').AsString;
      Result.CodigoUF := ADataSet.FieldByName('codigo_ibge').AsInteger;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TRPNFeDAOEstado.Select;
begin
  Query.SQL('select est_001, est_002, est_003, codigo_ibge from estados');
end;

end.
