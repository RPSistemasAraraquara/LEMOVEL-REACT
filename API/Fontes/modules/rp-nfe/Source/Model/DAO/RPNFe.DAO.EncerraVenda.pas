unit RPNFe.DAO.EncerraVenda;

interface

uses
  System.SysUtils,
  Data.DB,
  RPNFe.Entity.Classes,
  RPNFe.DAO.Base;

type
  TRPNFeDAOEncerraVenda = class(TRPNFeDAOBase<TRPNFeEntityEncerraVenda>)
  protected
    function DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityEncerraVenda; override;
  public
    procedure AtualizarStatusSAT(AIdEmpresa, AIdVenda, AStatus: Integer);
  end;

implementation

{ TRPNFeDAOEncerraVenda }

procedure TRPNFeDAOEncerraVenda.AtualizarStatusSAT(AIdEmpresa, AIdVenda, AStatus: Integer);
begin
  StartTransaction;
  try
    Query.SQL('update encerraVenda set ven_satStatus = :status')
      .SQL('where ven_001 = :idVenda')
      .SQL('and emp_001 = :idEmpresa')
      .ParamAsInteger('status', AStatus)
      .ParamAsInteger('idVenda', AIdVenda)
      .ParamAsInteger('idEmpresa', AIdEmpresa)
      .ExecSQL;
    Commit;
  except
    Rollback;
    raise;
  end;
end;

function TRPNFeDAOEncerraVenda.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityEncerraVenda;
begin
  Result := nil;
end;

end.
