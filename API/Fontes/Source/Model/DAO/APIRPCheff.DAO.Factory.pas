unit APIRPCheff.DAO.Factory;

interface

uses
  System.SysUtils,
  ADRConn.Model.Interfaces,
  APIRPCheff.DAO.Caixa,
  APIRPCheff.DAO.CaixaItem,
  APIRPCheff.DAO.Categoria,
  APIRPCheff.DAO.CatracaMobile,
  APIRPCheff.DAO.Comanda,
  APIRPCheff.DAO.ConfiguracaoComanda,
  APIRPCheff.DAO.ConfiguracaoMesa,
  APIRPCheff.DAO.Empresa,
  APIRPCheff.DAO.EncerraVenda,
  APIRPCheff.DAO.EncerraVendaItem,
  APIRPCheff.DAO.FormaPagamento,
  APIRPCheff.DAO.MateriaisComposicao,
  APIRPCheff.DAO.Mesa,
  APIRPCheff.DAO.MovimentoEstoque,
  APIRPCheff.DAO.MovimentoEstoqueComposicao,
  APIRPCheff.DAO.Produto,
  APIRPCheff.DAO.Promocao,
  APIRPCheff.DAO.SetorEstoqueComposicao,
  APIRPCheff.DAO.SetorEstoqueMaterial,
  APIRPCheff.DAO.TipoMovimento,
  APIRPCheff.DAO.Usuario,
  APIRPCheff.DAO.Venda,
  APIRPCheff.DAO.VendaItem,
  APIRPCheff.DAO.VendaItemOpcional,
  APIRPCheff.DAO.VendaPagamentoAntecipado,
  APIRPCheff.DAO.VendaPrePago,
  APIRPCheff.DAO.ImpressaoProducao,
  APIRPCheff.DAO.CancelamentoPagamentoStone,
  APIRPCheff.DAO.PagamentoStonePOS,
  APIRPCheff.DAO.MovimentoEstoqueOpcional,
  APIRPCheff.DAO.Opcional,
  APIRPCheff.DAO.SetorEstoqueOpcional,
  APIRPCheff.DAO.Venda.PagamentoAntecipadoItens;

type
  TAPIRPCheffDAOCaixaItem                     = APIRPCheff.DAO.CaixaItem.TAPIRPCheffDAOCaixaItem;
  TAPIRPCheffDAOCatracaMobile                 = APIRPCheff.DAO.CatracaMobile.TAPIRPCheffDAOCatracaMobile;
  TAPIRPCheffDAOEncerraVenda                  = APIRPCheff.DAO.EncerraVenda.TAPIRPCheffDAOEncerraVenda;
  TAPIRPCheffDAOMovimentoEstoque              = APIRPCheff.DAO.MovimentoEstoque.TAPIRPCheffDAOMovimentoEstoque;
  TAPIRPCheffDAOMovimentoEstoqueComposicao    = APIRPCheff.DAO.MovimentoEstoqueComposicao.TAPIRPCheffDAOMovimentoEstoqueComposicao;
  TAPIRPCheffDAOEncerraVendaItem              = APIRPCheff.DAO.EncerraVendaItem.TAPIRPCheffDAOEncerraVendaItem;
  TAPIRPCheffDAOSetorEstoqueComposicao        = APIRPCheff.DAO.SetorEstoqueComposicao.TAPIRPCheffDAOSetorEstoqueComposicao;
  TAPIRPCheffDAOSetorEstoqueMaterial          = APIRPCheff.DAO.SetorEstoqueMaterial.TAPIRPCheffDAOSetorEstoqueMaterial;
  TAPIRPCheffDAOTipoMovimento                 = APIRPCheff.DAO.TipoMovimento.TAPIRPCheffDAOTipoMovimento;
  TAPIRPCheffDAOVenda                         = APIRPCheff.DAO.Venda.TAPIRPCheffDAOVenda;
  TAPIRPCheffDAOVendaItem                     = APIRPCheff.DAO.VendaItem.TAPIRPCheffDAOVendaItem;
  TAPIRPCheffDAOVendaItemOpcional             = APIRPCheff.DAO.VendaItemOpcional.TAPIRPCheffDAOVendaItemOpcional;
  TAPIRPCheffDAOImpressaoProducao             = APIRPCheff.DAO.ImpressaoProducao.TAPIRPCheffDAOImpressaoProducao;
  TAPIRPCheffDAOMovimentoEstoqueOpcional      = APIRPCheff.DAO.MovimentoEstoqueOpcional.TAPIRPCheffDAOMovimentoEstoqueOpcional;
  TAPIRPCheffDAOOpcional                      = APIRPCheff.DAO.Opcional.TAPIRPCheffDAOOpcional;
  TAPIRPCheffDAOSetorEstoqueOpcional          = APIRPCheff.DAO.SetorEstoqueOpcional.TAPIRPCheffDAOSetorEstoqueOpcional;
  TAPIRPCheffDAOVendaPagamentoAntecipadoItens = APIRPCheff.DAO.Venda.PagamentoAntecipadoItens.TAPIRPCheffDAOVendaPagamentoAntecipadoItens;
  TTAPIRPCheffDAOVendaPagamentoAntecipado     = APIRPCheff.DAO.VendaPagamentoAntecipado.TAPIRPCheffDAOVendaPagamentoAntecipado;

  TAPIRPCheffDAOFactory = class
  private
    FConnection                         : IADRConnection;
    FIdEmpresa                          : Integer;
    FCaixaDAO                           : TAPIRPCheffDAOCaixa;
    FCaixaItemDAO                       : TAPIRPCheffDAOCaixaItem;
    FCategoriaDAO                       : TAPIRPCheffDAOCategoria;
    FCatracaMobileDAO                   : TAPIRPCheffDAOCatracaMobile;
    FComandaDAO                         : TAPIRPCheffDAOComanda;
    FConfiguracaoComandaDAO             : TAPIRPCheffDAOConfiguracaoComanda;
    FConfiguracaoMesaDAO                : TAPIRPCheffDAOConfiguracaoMesa;
    FEmpresaDAO                         : TAPIRPCheffDAOEmpresa;
    FEncerraVendaDAO                    : TAPIRPCheffDAOEncerraVenda;
    FEncerraVendaItemDAO                : TAPIRPCheffDAOEncerraVendaItem;
    FFormaPagamentoDAO                  : TAPIRPCheffDAOFormaPagamento;
    FMateriaisComposicaoDAO             : TAPIRPCheffDAOMateriaisComposicao;
    FMesaDAO                            : TAPIRPCheffDAOMesa;
    FMovimentoEstoqueDAO                : TAPIRPCheffDAOMovimentoEstoque;
    FMovimentoEstoqueComposicaoDAO      : TAPIRPCheffDAOMovimentoEstoqueComposicao;
    FOpcionalDAO                        : TAPIRPCheffDAOOpcional;
    FProdutoDAO                         : TAPIRPCheffDAOProduto;
    FPromocaoDAO                        : TAPIRPCheffDAOPromocao;
    FSetorEstoqueComposicaoDAO          : TAPIRPCheffDAOSetorEstoqueComposicao;
    FSetorEstoqueMaterialDAO            : TAPIRPCheffDAOSetorEstoqueMaterial;
    FTipoMovimentoDAO                   : TAPIRPCheffDAOTipoMovimento;
    FUsuarioDAO                         : TAPIRPCheffDAOUsuario;
    FVendaDAO                           : TAPIRPCheffDAOVenda;
    FVendaItemDAO                       : TAPIRPCheffDAOVendaItem;
    FVendaItemOpcionalDAO               : TAPIRPCheffDAOVendaItemOpcional;
    FVendaPagamentoAntecipadoDAO        : TAPIRPCheffDAOVendaPagamentoAntecipado;
    FVendaPrePagoDAO                    : TAPIRPCheffDAOVendaPrePago;
    FImpressaoProducaoDAO               : TAPIRPCheffDAOImpressaoProducao;
    FCancelamentoPagamentoStone         : TAPIRPCheffDAOCancelamentoPagamentoStone;
    FPagamentoStonePOSDAO               : TAPIRPCheffDAOPagamentoStonePOS;
    FMovimentoEstoqueOpcionalDAO        : TAPIRPCheffDAOMovimentoEstoqueOpcional;
    FSetorEstoqueOpcionalDAO            : TAPIRPCheffDAOSetorEstoqueOpcional;
    FVendaPagamentoAntecipadoItensDAO   : TAPIRPCheffDAOVendaPagamentoAntecipadoItens;

  public
    constructor Create(AConnection: IADRConnection);
    destructor Destroy; override;

    function IdEmpresa(AValue: Integer): TAPIRPCheffDAOFactory; overload;
    function IdEmpresa: Integer; overload;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;

    function CaixaDAO                         : TAPIRPCheffDAOCaixa;
    function CaixaItemDAO                     : TAPIRPCheffDAOCaixaItem;
    function CategoriaDAO                     : TAPIRPCheffDAOCategoria;
    function CatracaMobileDAO                 : TAPIRPCheffDAOCatracaMobile;
    function ComandaDAO                       : TAPIRPCheffDAOComanda;
    function ConfiguracaoComandaDAO           : TAPIRPCheffDAOConfiguracaoComanda;
    function ConfiguracaoMesaDAO              : TAPIRPCheffDAOConfiguracaoMesa;
    function EmpresaDAO                       : TAPIRPCheffDAOEmpresa;
    function EncerraVendaDAO                  : TAPIRPCheffDAOEncerraVenda;
    function EncerraVendaItemDAO              : TAPIRPCheffDAOEncerraVendaItem;
    function FormaPagamentoDAO                : TAPIRPCheffDAOFormaPagamento;
    function MateriaisComposicaoDAO           : TAPIRPCheffDAOMateriaisComposicao;
    function MesaDAO                          : TAPIRPCheffDAOMesa;
    function MovimentoEstoqueDAO              : TAPIRPCheffDAOMovimentoEstoque;
    function MovimentoEstoqueComposicaoDAO    : TAPIRPCheffDAOMovimentoEstoqueComposicao;
    function OpcionalDAO                      : TAPIRPCheffDAOOpcional;
    function ProdutoDAO                       : TAPIRPCheffDAOProduto;
    function PromocaoDAO                      : TAPIRPCheffDAOPromocao;
    function SetorEstoqueComposicaoDAO        : TAPIRPCheffDAOSetorEstoqueComposicao;
    function SetorEstoqueMaterialDAO          : TAPIRPCheffDAOSetorEstoqueMaterial;
    function TipoMovimentoDAO                 : TAPIRPCheffDAOTipoMovimento;
    function UsuarioDAO                       : TAPIRPCheffDAOUsuario;
    function VendaDAO                         : TAPIRPCheffDAOVenda;
    function VendaItemDAO                     : TAPIRPCheffDAOVendaItem;
    function VendaItemOpcionalDAO             : TAPIRPCheffDAOVendaItemOpcional;
    function VendaPagamentoAntecipadoDAO      : TAPIRPCheffDAOVendaPagamentoAntecipado;
    function VendaPrePagoDAO                  : TAPIRPCheffDAOVendaPrePago;
    function ImpressaoProducaoDAO             : TAPIRPCheffDAOImpressaoProducao;
    function CancelamentoPagamentoStoneDAO    : TAPIRPCheffDAOCancelamentoPagamentoStone;
    function PagamentoStonePOSDAO             : TAPIRPCheffDAOPagamentoStonePOS;
    function MovimentoEstoqueOpcionalDAO      : TAPIRPCheffDAOMovimentoEstoqueOpcional;
    function SetorEstoqueOpcionalDAO          : TAPIRPCheffDAOSetorEstoqueOpcional;
    function VendaPagamentoAntecipadoItensDAO : TAPIRPCheffDAOVendaPagamentoAntecipadoItens;
  end;

implementation

{ TAPIRPCheffDAOFactory }

function TAPIRPCheffDAOFactory.CaixaDAO: TAPIRPCheffDAOCaixa;
begin
  if not Assigned(FCaixaDAO) then
  begin
    FCaixaDAO := TAPIRPCheffDAOCaixa.Create(FConnection);
    FCaixaDAO.IdEmpresa(FIdEmpresa);
  end;
  FCaixaDAO.ManagerTransaction(True);
  Result := FCaixaDAO;
end;

function TAPIRPCheffDAOFactory.CaixaItemDAO: TAPIRPCheffDAOCaixaItem;
begin
  if not Assigned(FCaixaItemDAO) then
  begin
    FCaixaItemDAO := TAPIRPCheffDAOCaixaItem.Create(FConnection);
    FCaixaItemDAO.IdEmpresa(FIdEmpresa);
  end;
  FCaixaItemDAO.ManagerTransaction(True);
  Result := FCaixaItemDAO;
end;

function TAPIRPCheffDAOFactory.CancelamentoPagamentoStoneDAO: TAPIRPCheffDAOCancelamentoPagamentoStone;
begin
  if not Assigned(FCancelamentoPagamentoStone) then
  begin
    FCancelamentoPagamentoStone:=TAPIRPCheffDAOCancelamentoPagamentoStone.Create(FConnection);
    FCancelamentoPagamentoStone.IdEmpresa(FIdEmpresa);
  end;
  FCancelamentoPagamentoStone.ManagerTransaction(True);
  Result:=FCancelamentoPagamentoStone;
end;

function TAPIRPCheffDAOFactory.CategoriaDAO: TAPIRPCheffDAOCategoria;
begin
  if not Assigned(FCategoriaDAO) then
  begin
    FCategoriaDAO := TAPIRPCheffDAOCategoria.Create(FConnection);
    FCategoriaDAO.IdEmpresa(FIdEmpresa);
  end;
  FCategoriaDAO.ManagerTransaction(True);
  Result := FCategoriaDAO;
end;

function TAPIRPCheffDAOFactory.CatracaMobileDAO: TAPIRPCheffDAOCatracaMobile;
begin
  if not Assigned(FCatracaMobileDAO) then
  begin
    FCatracaMobileDAO := TAPIRPCheffDAOCatracaMobile.Create(FConnection);
    FCatracaMobileDAO.IdEmpresa(FIdEmpresa);
  end;
  FCatracaMobileDAO.ManagerTransaction(True);
  Result := FCatracaMobileDAO;
end;

function TAPIRPCheffDAOFactory.ComandaDAO: TAPIRPCheffDAOComanda;
begin
  if not Assigned(FComandaDAO) then
  begin
    FComandaDAO := TAPIRPCheffDAOComanda.Create(FConnection);
    FComandaDAO.IdEmpresa(FIdEmpresa);
  end;
  FComandaDAO.ManagerTransaction(True);
  Result := FComandaDAO;
end;

procedure TAPIRPCheffDAOFactory.Commit;
begin
  FConnection.Commit;
end;

function TAPIRPCheffDAOFactory.ConfiguracaoComandaDAO: TAPIRPCheffDAOConfiguracaoComanda;
begin
  if not Assigned(FConfiguracaoComandaDAO) then
  begin
    FConfiguracaoComandaDAO := TAPIRPCheffDAOConfiguracaoComanda.Create(FConnection);
    FConfiguracaoComandaDAO.IdEmpresa(FIdEmpresa);
  end;
  FConfiguracaoComandaDAO.ManagerTransaction(True);
  Result := FConfiguracaoComandaDAO;
end;

function TAPIRPCheffDAOFactory.ConfiguracaoMesaDAO: TAPIRPCheffDAOConfiguracaoMesa;
begin
  if not Assigned(FConfiguracaoMesaDAO) then
  begin
    FConfiguracaoMesaDAO := TAPIRPCheffDAOConfiguracaoMesa.Create(FConnection);
    FConfiguracaoMesaDAO.IdEmpresa(FIdEmpresa);
  end;
  FConfiguracaoMesaDAO.ManagerTransaction(True);
  Result := FConfiguracaoMesaDAO;
end;

constructor TAPIRPCheffDAOFactory.Create(AConnection: IADRConnection);
begin
  FConnection := AConnection;
  FIdEmpresa  := 1;
end;

destructor TAPIRPCheffDAOFactory.Destroy;
begin
  FreeAndNil(FCaixaDAO);
  FreeAndNil(FCaixaItemDAO);
  FreeAndNil(FCategoriaDAO);
  FreeAndNil(FCatracaMobileDAO);
  FreeAndNil(FComandaDAO);
  FreeAndNil(FConfiguracaoComandaDAO);
  FreeAndNil(FConfiguracaoMesaDAO);
  FreeAndNil(FEmpresaDAO);
  FreeAndNil(FEncerraVendaDAO);
  FreeAndNil(FEncerraVendaItemDAO);
  FreeAndNil(FFormaPagamentoDAO);
  FreeAndNil(FMateriaisComposicaoDAO);
  FreeAndNil(FMesaDAO);
  FreeAndNil(FMovimentoEstoqueDAO);
  FreeAndNil(FMovimentoEstoqueComposicaoDAO);
  FreeAndNil(FOpcionalDAO);
  FreeAndNil(FProdutoDAO);
  FreeAndNil(FPromocaoDAO);
  FreeAndNil(FSetorEstoqueComposicaoDAO);
  FreeAndNil(FSetorEstoqueMaterialDAO);
  FreeAndNil(FTipoMovimentoDAO);
  FreeAndNil(FUsuarioDAO);
  FreeAndNil(FVendaDAO);
  FreeAndNil(FVendaItemDAO);
  FreeAndNil(FVendaItemOpcionalDAO);
  FreeAndNil(FVendaPagamentoAntecipadoDAO);
  FreeAndNil(FVendaPrePagoDAO);
  FreeAndNil(FImpressaoProducaoDAO);
  FreeAndNil(FCancelamentoPagamentoStone);
  FreeAndNil(FPagamentoStonePOSDAO);
  FreeAndNil(FMovimentoEstoqueOpcionalDAO);
  FreeAndNil(FSetorEstoqueOpcionalDAO);
  FreeAndNil(FVendaPagamentoAntecipadoItensDAO);
  inherited;
end;

function TAPIRPCheffDAOFactory.EmpresaDAO: TAPIRPCheffDAOEmpresa;
begin
  if not Assigned(FEmpresaDAO) then
  begin
    FEmpresaDAO := TAPIRPCheffDAOEmpresa.Create(FConnection);
    FEmpresaDAO.IdEmpresa(FIdEmpresa);
  end;
  FEmpresaDAO.ManagerTransaction(True);
  Result := FEmpresaDAO;
end;

function TAPIRPCheffDAOFactory.EncerraVendaDAO: TAPIRPCheffDAOEncerraVenda;
begin
  if not Assigned(FEncerraVendaDAO) then
  begin
    FEncerraVendaDAO := TAPIRPCheffDAOEncerraVenda.Create(FConnection);
    FEncerraVendaDAO.IdEmpresa(FIdEmpresa);
  end;
  FEncerraVendaDAO.ManagerTransaction(True);
  Result := FEncerraVendaDAO;
end;

function TAPIRPCheffDAOFactory.EncerraVendaItemDAO: TAPIRPCheffDAOEncerraVendaItem;
begin
  if not Assigned(FEncerraVendaItemDAO) then
  begin
    FEncerraVendaItemDAO := TAPIRPCheffDAOEncerraVendaItem.Create(FConnection);
    FEncerraVendaItemDAO.IdEmpresa(FIdEmpresa);
  end;
  FEncerraVendaItemDAO.ManagerTransaction(True);
  Result := FEncerraVendaItemDAO;
end;

function TAPIRPCheffDAOFactory.FormaPagamentoDAO: TAPIRPCheffDAOFormaPagamento;
begin
  if not Assigned(FFormaPagamentoDAO) then
  begin
    FFormaPagamentoDAO := TAPIRPCheffDAOFormaPagamento.Create(FConnection);
    FFormaPagamentoDAO.IdEmpresa(FIdEmpresa);
  end;
  FFormaPagamentoDAO.ManagerTransaction(True);
  Result := FFormaPagamentoDAO;
end;

function TAPIRPCheffDAOFactory.IdEmpresa: Integer;
begin
  Result := FIdEmpresa;
end;

function TAPIRPCheffDAOFactory.ImpressaoProducaoDAO: TAPIRPCheffDAOImpressaoProducao;
begin
 if not Assigned(FImpressaoProducaoDAO) then
  begin
    FImpressaoProducaoDAO := TAPIRPCheffDAOImpressaoProducao.Create(FConnection);
    FImpressaoProducaoDAO.IdEmpresa(FIdEmpresa);
  end;
  FImpressaoProducaoDAO.ManagerTransaction(True);
  Result := FImpressaoProducaoDAO;
end;

function TAPIRPCheffDAOFactory.IdEmpresa(AValue: Integer): TAPIRPCheffDAOFactory;
begin
  Result := Self;
  FIdEmpresa := AValue;
end;

function TAPIRPCheffDAOFactory.MateriaisComposicaoDAO: TAPIRPCheffDAOMateriaisComposicao;
begin
  if not Assigned(FMateriaisComposicaoDAO) then
  begin
    FMateriaisComposicaoDAO := TAPIRPCheffDAOMateriaisComposicao.Create(FConnection);
    FMateriaisComposicaoDAO.IdEmpresa(FIdEmpresa);
  end;
  FMateriaisComposicaoDAO.ManagerTransaction(True);
  Result := FMateriaisComposicaoDAO;
end;

function TAPIRPCheffDAOFactory.MesaDAO: TAPIRPCheffDAOMesa;
begin
  if not Assigned(FMesaDAO) then
  begin
    FMesaDAO := TAPIRPCheffDAOMesa.Create(FConnection);
    FMesaDAO.IdEmpresa(FIdEmpresa);
  end;
  FMesaDAO.ManagerTransaction(True);
  Result := FMesaDAO;
end;

function TAPIRPCheffDAOFactory.MovimentoEstoqueComposicaoDAO: TAPIRPCheffDAOMovimentoEstoqueComposicao;
begin
  if not Assigned(FMovimentoEstoqueComposicaoDAO) then
  begin
    FMovimentoEstoqueComposicaoDAO := TAPIRPCheffDAOMovimentoEstoqueComposicao.Create(FConnection);
    FMovimentoEstoqueComposicaoDAO.IdEmpresa(FIdEmpresa);
  end;
  FMovimentoEstoqueComposicaoDAO.ManagerTransaction(True);
  Result := FMovimentoEstoqueComposicaoDAO;
end;

function TAPIRPCheffDAOFactory.MovimentoEstoqueDAO: TAPIRPCheffDAOMovimentoEstoque;
begin
  if not Assigned(FMovimentoEstoqueDAO) then
  begin
    FMovimentoEstoqueDAO := TAPIRPCheffDAOMovimentoEstoque.Create(FConnection);
    FMovimentoEstoqueDAO.IdEmpresa(FIdEmpresa);
  end;
  FMovimentoEstoqueDAO.ManagerTransaction(True);
  Result := FMovimentoEstoqueDAO;
end;

function TAPIRPCheffDAOFactory.MovimentoEstoqueOpcionalDAO: TAPIRPCheffDAOMovimentoEstoqueOpcional;
begin
  if not Assigned(FMovimentoEstoqueOpcionalDAO) then
  begin
    FMovimentoEstoqueOpcionalDAO:=TAPIRPCheffDAOMovimentoEstoqueOpcional.Create(FConnection);
     FMovimentoEstoqueOpcionalDAO.IdEmpresa(FIdEmpresa);
  end;
  FMovimentoEstoqueOpcionalDAO.ManagerTransaction(True);
  Result:=FMovimentoEstoqueOpcionalDAO;
end;

function TAPIRPCheffDAOFactory.OpcionalDAO: TAPIRPCheffDAOOpcional;
begin
  if not Assigned(FOpcionalDAO) then
  begin
    FOpcionalDAO := TAPIRPCheffDAOOpcional.Create(FConnection);
    FOpcionalDAO.IdEmpresa(FIdEmpresa);
  end;
  FOpcionalDAO.ManagerTransaction(True);
  Result := FOpcionalDAO;
end;

function TAPIRPCheffDAOFactory.PagamentoStonePOSDAO: TAPIRPCheffDAOPagamentoStonePOS;
begin
  if not Assigned(FPagamentoStonePOSDAO) then
  begin
    FPagamentoStonePOSDAO:=TAPIRPCheffDAOPagamentoStonePOS.Create(FConnection);
    FPagamentoStonePOSDAO.IdEmpresa(FIdEmpresa);
  end;
  FPagamentoStonePOSDAO.ManagerTransaction(True);
  Result:=FPagamentoStonePOSDAO;
end;

function TAPIRPCheffDAOFactory.ProdutoDAO: TAPIRPCheffDAOProduto;
begin
  if not Assigned(FProdutoDAO) then
  begin
    FProdutoDAO := TAPIRPCheffDAOProduto.Create(FConnection);
    FProdutoDAO.IdEmpresa(FIdEmpresa);
  end;
  FProdutoDAO.ManagerTransaction(True);
  Result := FProdutoDAO;
end;

function TAPIRPCheffDAOFactory.PromocaoDAO: TAPIRPCheffDAOPromocao;
begin
  if not Assigned(FPromocaoDAO) then
  begin
    FPromocaoDAO := TAPIRPCheffDAOPromocao.Create(FConnection);
    FPromocaoDAO.IdEmpresa(FIdEmpresa);
  end;
  FPromocaoDAO.ManagerTransaction(True);
  Result := FPromocaoDAO;
end;

procedure TAPIRPCheffDAOFactory.Rollback;
begin
  FConnection.Rollback;
end;

function TAPIRPCheffDAOFactory.SetorEstoqueComposicaoDAO: TAPIRPCheffDAOSetorEstoqueComposicao;
begin
  if not Assigned(FSetorEstoqueComposicaoDAO) then
  begin
    FSetorEstoqueComposicaoDAO := TAPIRPCheffDAOSetorEstoqueComposicao.Create(FConnection);
    FSetorEstoqueComposicaoDAO.IdEmpresa(FIdEmpresa);
  end;
  FSetorEstoqueComposicaoDAO.ManagerTransaction(True);
  Result := FSetorEstoqueComposicaoDAO;
end;

function TAPIRPCheffDAOFactory.SetorEstoqueMaterialDAO: TAPIRPCheffDAOSetorEstoqueMaterial;
begin
  if not Assigned(FSetorEstoqueMaterialDAO) then
  begin
    FSetorEstoqueMaterialDAO := TAPIRPCheffDAOSetorEstoqueMaterial.Create(FConnection);
    FSetorEstoqueMaterialDAO.IdEmpresa(FIdEmpresa);
  end;
  FSetorEstoqueMaterialDAO.ManagerTransaction(True);
  Result := FSetorEstoqueMaterialDAO;
end;

function TAPIRPCheffDAOFactory.SetorEstoqueOpcionalDAO: TAPIRPCheffDAOSetorEstoqueOpcional;
begin
  if not Assigned(FSetorEstoqueOpcionalDAO) then
  begin
    FSetorEstoqueOpcionalDAO:=TAPIRPCheffDAOSetorEstoqueOpcional.Create(FConnection);
    FSetorEstoqueOpcionalDAO.IdEmpresa(FIdEmpresa);
  end;
  FSetorEstoqueOpcionalDAO.ManagerTransaction(True);
  Result:=FSetorEstoqueOpcionalDAO;
end;

procedure TAPIRPCheffDAOFactory.StartTransaction;
begin
  FConnection.StartTransaction;
end;

function TAPIRPCheffDAOFactory.TipoMovimentoDAO: TAPIRPCheffDAOTipoMovimento;
begin
  if not Assigned(FTipoMovimentoDAO) then
  begin
    FTipoMovimentoDAO := TAPIRPCheffDAOTipoMovimento.Create(FConnection);
    FTipoMovimentoDAO.IdEmpresa(FIdEmpresa);
  end;
  FTipoMovimentoDAO.ManagerTransaction(True);
  Result := FTipoMovimentoDAO;
end;

function TAPIRPCheffDAOFactory.UsuarioDAO: TAPIRPCheffDAOUsuario;
begin
  if not Assigned(FUsuarioDAO) then
  begin
    FUsuarioDAO := TAPIRPCheffDAOUsuario.Create(FConnection);
    FUsuarioDAO.IdEmpresa(FIdEmpresa);
  end;
  FUsuarioDAO.ManagerTransaction(True);
  Result := FUsuarioDAO;
end;

function TAPIRPCheffDAOFactory.VendaDAO: TAPIRPCheffDAOVenda;
begin
  if not Assigned(FVendaDAO) then
  begin
    FVendaDAO := TAPIRPCheffDAOVenda.Create(FConnection);
    FVendaDAO.IdEmpresa(FIdEmpresa);
  end;
  FVendaDAO.ManagerTransaction(True);
  Result := FVendaDAO;
end;

function TAPIRPCheffDAOFactory.VendaItemDAO: TAPIRPCheffDAOVendaItem;
begin
  if not Assigned(FVendaItemDAO) then
  begin
    FVendaItemDAO := TAPIRPCheffDAOVendaItem.Create(FConnection);
    FVendaItemDAO.IdEmpresa(FIdEmpresa);
  end;
  FVendaItemDAO.ManagerTransaction(True);
  Result := FVendaItemDAO;
end;

function TAPIRPCheffDAOFactory.VendaItemOpcionalDAO: TAPIRPCheffDAOVendaItemOpcional;
begin
  if not Assigned(FVendaItemOpcionalDAO) then
  begin
    FVendaItemOpcionalDAO := TAPIRPCheffDAOVendaItemOpcional.Create(FConnection);
    FVendaItemOpcionalDAO.IdEmpresa(FIdEmpresa);
  end;
  FVendaItemOpcionalDAO.ManagerTransaction(True);
  Result := FVendaItemOpcionalDAO;
end;

function TAPIRPCheffDAOFactory.VendaPagamentoAntecipadoDAO: TAPIRPCheffDAOVendaPagamentoAntecipado;
begin
  if not Assigned(FVendaPagamentoAntecipadoDAO) then
  begin
    FVendaPagamentoAntecipadoDAO := TAPIRPCheffDAOVendaPagamentoAntecipado.Create(FConnection);
    FVendaPagamentoAntecipadoDAO.IdEmpresa(FIdEmpresa);
  end;
  FVendaPagamentoAntecipadoDAO.ManagerTransaction(True);
  Result := FVendaPagamentoAntecipadoDAO;
end;

function TAPIRPCheffDAOFactory.VendaPagamentoAntecipadoItensDAO: TAPIRPCheffDAOVendaPagamentoAntecipadoItens;
begin
  if not Assigned(FVendaPagamentoAntecipadoItensDAO) then
  begin
    FVendaPagamentoAntecipadoItensDAO :=TAPIRPCheffDAOVendaPagamentoAntecipadoItens.Create(FConnection);
    FVendaPagamentoAntecipadoItensDAO.IdEmpresa(FIdEmpresa);
  end;
  FVendaPagamentoAntecipadoItensDAO.ManagerTransaction(True);
  Result:=FVendaPagamentoAntecipadoItensDAO;
end;

function TAPIRPCheffDAOFactory.VendaPrePagoDAO: TAPIRPCheffDAOVendaPrePago;
begin
  if not Assigned(FVendaPrePagoDAO) then
  begin
    FVendaPrePagoDAO := TAPIRPCheffDAOVendaPrePago.Create(FConnection);
    FVendaPrePagoDAO.IdEmpresa(FIdEmpresa);
  end;
  FVendaPrePagoDAO.ManagerTransaction(True);
  Result := FVendaPrePagoDAO;
end;

end.


