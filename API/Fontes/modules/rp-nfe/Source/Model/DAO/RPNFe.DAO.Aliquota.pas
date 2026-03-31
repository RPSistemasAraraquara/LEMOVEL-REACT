unit RPNFe.DAO.Aliquota;

interface

uses
  System.SysUtils,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOAliquota = class(TRPNFeDAOBase<TRPNFeEntityAliquota>)
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityAliquota; override;
  public
    function Buscar(AUF: string): TRPNFeEntityAliquota;
    function AliquotaInterna(AUF: string): Double;
  end;

implementation

{ TRPNFeDAOAliquota }

function TRPNFeDAOAliquota.AliquotaInterna(AUF: string): Double;
var
  LAliquota: TRPNFeEntityAliquota;
begin
  Result := 0;
  LAliquota := Buscar(AUF);
  try
    if Assigned(LAliquota) then
      Result := LAliquota.Aliquota;
  finally
    LAliquota.Free;
  end;
end;

function TRPNFeDAOAliquota.Buscar(AUF: string): TRPNFeEntityAliquota;
var
  LSql: string;
  LDataSet: TDataSet;
begin
  LSql := Format('select id, uf, c_%s as interna from aliquotas where uf = :uf', [AUF.ToLower]);
  LDataSet := Query.SQL(LSql).OpenDataSet;
  try
    Result := DataSetToEntity(LDataSet);
  finally
    LDataSet.Free;
  end;
end;

function TRPNFeDAOAliquota.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityAliquota;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TRPNFeEntityAliquota.Create;
    try
      Result.Id := ADataSet.FieldByName('id').AsInteger;
      Result.UF := ADataSet.FieldByName('uf').AsString;
      Result.Aliquota := ADataSet.FieldByName('interna').AsFloat;    
    except
      Result.Free;
      raise;
    end;
  end;
end;

end.
