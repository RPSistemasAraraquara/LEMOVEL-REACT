unit RPNFe.DAO.ClassTribRT;

interface

uses
  System.SysUtils,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  // Reforma Tributaria: consulta das flags da classificacao tributaria,
  // mesma consulta (DFE_CLASSTRIB_RT + DFE_CST_RT) do uEmissorNFCe do RPCHEFF_VCL.
  TRPNFeDAOClassTribRT = class(TRPNFeDAOBase<TRPNFeEntityClassTribRT>)
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityClassTribRT; override;
  public
    function Buscar(const AClassTrib: string): TRPNFeEntityClassTribRT;
  end;

implementation

{ TRPNFeDAOClassTribRT }

function TRPNFeDAOClassTribRT.Buscar(const AClassTrib: string): TRPNFeEntityClassTribRT;
begin
  Query.SQL('select t.classtrib, t.indnfe, t.indnfce, t.indtribregular,')
    .SQL('  t.predibs, t.predcbs,')
    .SQL('  c.indredaliq, c.inddif, c.indibscbsmono, c.indredbc')
    .SQL('from dfe_classtrib_rt t')
    .SQL('left join dfe_cst_rt c on c.cst_ibs_cbs = t.cst')
    .SQL('where t.classtrib = :classTrib')
    .ParamAsString('classTrib', AClassTrib);
  Result := OpenQueryToEntity;
end;

function TRPNFeDAOClassTribRT.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityClassTribRT;
begin
  Result := nil;
  if ADataSet.RecordCount > 0 then
  begin
    Result := TRPNFeEntityClassTribRT.Create;
    try
      Result.ClassTrib := ADataSet.FieldByName('classtrib').AsString;
      Result.IndNfe := ADataSet.FieldByName('indnfe').AsBoolean;
      Result.IndNfce := ADataSet.FieldByName('indnfce').AsBoolean;
      Result.IndTribRegular := ADataSet.FieldByName('indtribregular').AsBoolean;
      Result.PRedIbs := ADataSet.FieldByName('predibs').AsFloat;
      Result.PRedCbs := ADataSet.FieldByName('predcbs').AsFloat;
      Result.IndRedAliq := ADataSet.FieldByName('indredaliq').AsBoolean;
      Result.IndDif := ADataSet.FieldByName('inddif').AsBoolean;
      Result.IndIbsCbsMono := ADataSet.FieldByName('indibscbsmono').AsBoolean;
      Result.IndRedBc := ADataSet.FieldByName('indredbc').AsBoolean;
    except
      Result.Free;
      raise;
    end;
  end;
end;

end.
