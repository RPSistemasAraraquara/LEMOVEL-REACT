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
    procedure AtualizarStatusSAT(AIdVenda, AStatus: Integer);
  end;

implementation

{ TRPNFeDAOEncerraVenda }

procedure TRPNFeDAOEncerraVenda.AtualizarStatusSAT(AIdVenda, AStatus: Integer);
begin
  Query.SQL('update encerraVenda set ven_satStatus = :status')
    .SQL('where ven_001 = :idVenda')
    .ParamAsInteger('status', AStatus)
    .ParamAsInteger('idVenda', AIdVenda)
    .ExecSQL;
end;

function TRPNFeDAOEncerraVenda.DataSetToEntity(ADataSet: TDataSet): TRPNFeEntityEncerraVenda;
begin
  Result := nil;
end;

end.
