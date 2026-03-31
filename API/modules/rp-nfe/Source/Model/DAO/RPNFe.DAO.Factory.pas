unit RPNFe.DAO.Factory;

interface

uses
  RPNFe.Components,
  RPNFe.DAO.Aliquota,
  RPNFe.DAO.Configuracao,
  RPNFe.DAO.ContaAReceber,
  RPNFe.DAO.Empresa,
  RPNFe.DAO.EncerraVenda,
  RPNFe.DAO.Estado,
  RPNFe.DAO.IBPT,
  RPNFe.DAO.Venda,
  RPNFe.DAO.VendaItem,
  RPNFe.DAO.VendaPagamento;

type
  TRPNFeDAOFactory = class
  private
    FComponents: TRPNFeComponents;
    FAliquotaDAO: TRPNFeDAOAliquota;
    FConfiguracaoDAO: TRPNFeDAOConfiguracao;
    FContaAReceberDAO: TRPNFeDAOContaAReceber;
    FEmpresaDAO: TRPNFeDAOEmpresa;
    FEncerraVendaDAO: TRPNFeDAOEncerraVenda;
    FEstadoDAO: TRPNFeDAOEstado;
    FIBPTDAO: TRPNFeDAOIBPT;
    FVendaDAO: TRPNFeDAOVenda;
    FVendaItemDAO: TRPNFeDAOVendaItem;
    FVendaPagamentoDAO: TRPNFeDAOVendaPagamento;
  public
    constructor Create(AComponents: TRPNFeComponents);
    destructor Destroy; override;

    function AliquotaDAO: TRPNFeDAOAliquota;
    function ConfiguracaoDAO: TRPNFeDAOConfiguracao;
    function ContaAReceberDAO: TRPNFeDAOContaAReceber;
    function EmpresaDAO: TRPNFeDAOEmpresa;
    function EncerraVendaDAO: TRPNFeDAOEncerraVenda;
    function EstadoDAO: TRPNFeDAOEstado;
    function IBPTDAO: TRPNFeDAOIBPT;
    function VendaDAO: TRPNFeDAOVenda;
    function VendaItemDAO: TRPNFeDAOVendaItem;
    function VendaPagamentoDAO: TRPNFeDAOVendaPagamento;
  end;

implementation

{ TRPNFeDAOFactory }

function TRPNFeDAOFactory.AliquotaDAO: TRPNFeDAOAliquota;
begin
  if not Assigned(FAliquotaDAO) then
    FAliquotaDAO := TRPNFeDAOAliquota.Create(FComponents);
  Result := FAliquotaDAO;
  Result.ManagerTransaction(True);
end;

function TRPNFeDAOFactory.ConfiguracaoDAO: TRPNFeDAOConfiguracao;
begin
  if not Assigned(FConfiguracaoDAO) then
    FConfiguracaoDAO := TRPNFeDAOConfiguracao.Create;
  Result := FConfiguracaoDAO;
end;

function TRPNFeDAOFactory.ContaAReceberDAO: TRPNFeDAOContaAReceber;
begin
  if not Assigned(FContaAReceberDAO) then
    FContaAReceberDAO := TRPNFeDAOContaAReceber.Create(FComponents);
  Result := FContaAReceberDAO;
  Result.ManagerTransaction(True);
end;

constructor TRPNFeDAOFactory.Create(AComponents: TRPNFeComponents);
begin
  FComponents := AComponents;
end;

destructor TRPNFeDAOFactory.Destroy;
begin
  FAliquotaDAO.Free;
  FConfiguracaoDAO.Free;
  FContaAReceberDAO.Free;
  FEmpresaDAO.Free;
  FEncerraVendaDAO.Free;
  FEstadoDAO.Free;
  FIBPTDAO.Free;
  FVendaDAO.Free;
  FVendaItemDAO.Free;
  FVendaPagamentoDAO.Free;
  inherited;
end;

function TRPNFeDAOFactory.EmpresaDAO: TRPNFeDAOEmpresa;
begin
  if not Assigned(FEmpresaDAO) then
    FEmpresaDAO := TRPNFeDAOEmpresa.Create(FComponents);
  Result := FEmpresaDAO;
  Result.ManagerTransaction(True);
end;

function TRPNFeDAOFactory.EncerraVendaDAO: TRPNFeDAOEncerraVenda;
begin
  if not Assigned(FEncerraVendaDAO) then
    FEncerraVendaDAO := TRPNFeDAOEncerraVenda.Create(FComponents);
  Result := FEncerraVendaDAO;
  Result.ManagerTransaction(True);
end;

function TRPNFeDAOFactory.EstadoDAO: TRPNFeDAOEstado;
begin
  if not Assigned(FEstadoDAO) then
    FEstadoDAO := TRPNFeDAOEstado.Create(FComponents);
  Result := FEstadoDAO;
  Result.ManagerTransaction(True);
end;

function TRPNFeDAOFactory.IBPTDAO: TRPNFeDAOIBPT;
begin
  if not Assigned(FIBPTDAO) then
    FIBPTDAO := TRPNFeDAOIBPT.Create(FComponents);
  Result := FIBPTDAO;
  Result.ManagerTransaction(True);
end;

function TRPNFeDAOFactory.VendaDAO: TRPNFeDAOVenda;
begin
  if not Assigned(FVendaDAO) then
    FVendaDAO := TRPNFeDAOVenda.Create(FComponents);
  Result := FVendaDAO;
  Result.ManagerTransaction(True);
end;

function TRPNFeDAOFactory.VendaItemDAO: TRPNFeDAOVendaItem;
begin
  if not Assigned(FVendaItemDAO) then
    FVendaItemDAO := TRPNFeDAOVendaItem.Create(FComponents);
  Result := FVendaItemDAO;
  Result.ManagerTransaction(True);
end;

function TRPNFeDAOFactory.VendaPagamentoDAO: TRPNFeDAOVendaPagamento;
begin
  if not Assigned(FVendaPagamentoDAO) then
    FVendaPagamentoDAO := TRPNFeDAOVendaPagamento.Create(FComponents);
  Result := FVendaPagamentoDAO;
  Result.ManagerTransaction(True);
end;

end.
