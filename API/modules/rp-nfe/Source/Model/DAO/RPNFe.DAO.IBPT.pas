unit RPNFe.DAO.IBPT;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOIBPT = class(TRPNFeDAOBase<TRPNFeEntityIBPT>)
  private
    procedure Select;
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityIBPT; override;
  public
    function Buscar(ANCM: string): TRPNFeEntityIBPT;
  end;

implementation

{ TRPNFeDAOIBPT }

function TRPNFeDAOIBPT.Buscar(ANCM: string): TRPNFeEntityIBPT;
begin
  Select;
  Query.SQL('where ncm = :ncm')
    .ParamAsString('ncm', ANCM);
  Result := OpenQueryToEntity;
end;

function TRPNFeDAOIBPT.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityIBPT;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TRPNFeEntityIBPT.Create;
    try
      Result.IdIbpt := ADataSet.FieldByName('ibpt_001').AsInteger;
      Result.NCM := ADataSet.FieldByName('ncm').AsString;
      Result.Descricao := ADataSet.FieldByName('descricao').AsString;
      Result.AliquotaEstadual := ADataSet.FieldByName('aliqEstadual').AsFloat;
      Result.AliquotaMunicipal := ADataSet.FieldByName('aliqMunicipal').AsFloat;
      Result.AliquotaFederalImportado := ADataSet.FieldByName('aliqFedImportado').AsFloat;
      Result.AliquotaFederalNacional := ADataSet.FieldByName('aliqFedNacional').AsFloat;
      Result.Manual := ADataSet.FieldByName('b_manual').AsBoolean;
    except
      Result.Free;
      raise;
    end;
  end;
end;

procedure TRPNFeDAOIBPT.Select;
begin
  Query.SQL('select ibpt_001, ncm, descricao, aliqFedNacional, aliqFedImportado, aliqEstadual,')
    .SQL('  aliqMunicipal, b_manual')
    .SQL('from ibpt');
end;

end.
