unit APIRPCheff.Service.Venda.LancarItem.Normal;

interface

uses
  APIRPCheff.Service.Venda.LancarItem,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Generics.Collections,
  System.Math,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaLancarItemNormal = class(TAPIRPCheffServiceVendaLancarItem)
  private
    FProduto: TAPIRPCheffEntityProduto;

    procedure AtribuirDadosDoProduto;
    procedure CalcularPromocao(AProduto: TAPIRPCheffEntityProduto);
    function GravarVendaItem: Boolean;
    procedure GravarVendaItemOpcional;
    procedure AtualizarValorVenda;
    procedure AtribuirNumeroItem;
  public
    constructor Create(AProduto: TAPIRPCheffEntityProduto);
    procedure Execute; override;
  end;

implementation

{ TAPIRPCheffServiceVendaLancarItemNormal }

procedure TAPIRPCheffServiceVendaLancarItemNormal.AtribuirNumeroItem;
var
  LUltimo: Integer;
begin
  try
    LUltimo := FDAO.VendaItemDAO.UltimoNumeroItemLancado(FItem.idVenda);
    FItem.numeroItem := LUltimo + 1;
  except
    on E: Exception do
    begin
      E.Message := 'Erro ao atribuir numero do item: ' + E.Message;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItemNormal.AtualizarValorVenda;
var
  LVendaDAO: TAPIRPCheffDAOVenda;
begin
  LVendaDAO := FDAO.VendaDAO;
  LVendaDAO.ManagerTransaction(False);
  try
    LVendaDAO.AtualizarTotalVenda(FItem.idEmpresa, FItem.idVenda);
  except
    on E: Exception do
    begin
      E.Message := 'Erro ao atualizar total da venda: ' + E.Message;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItemNormal.CalcularPromocao(AProduto: TAPIRPCheffEntityProduto);
var
  LDescontoCadastro: Currency;
begin
  if not AProduto.possuiPromocao then
    Exit;

  if AProduto.UsaHappyHour then
    Exit;

  if AProduto.vendaPorTamanho then
    LDescontoCadastro := AProduto.promocao.ValorDesconto(FItem.tamanho)
  else
    LDescontoCadastro := AProduto.promocao.ValorDesconto;

  if LDescontoCadastro <= 0 then
    Exit;

  if AProduto.promocao.tipoDesconto = tdValor then
    FItem.desconto := LDescontoCadastro
  else
    FItem.desconto := SimpleRoundTo(FItem.valorUnitario * LDescontoCadastro / 100);

  FItem.desconto := FItem.desconto * FItem.quantidade;
  FItem.AtualizaValorTotal;
end;

constructor TAPIRPCheffServiceVendaLancarItemNormal.Create(AProduto: TAPIRPCheffEntityProduto);
begin
  FProduto := AProduto;
end;

procedure TAPIRPCheffServiceVendaLancarItemNormal.AtribuirDadosDoProduto;
var
  LEmpresa:TAPIRPCheffEntityEmpresa;
  LVenda: TAPIRPCheffEntityVenda;
begin
  LEmpresa := FDAO.EmpresaDAO.Busca;
  try
    LVenda := FDAO.VendaDAO.Buscar(FItem.idVenda);
    try
      FItem.impressora1           := FProduto.impressora1;
      FItem.impressora2           := FProduto.impressora2;
      FItem.produtoDescricao      := FProduto.descricao;
      FItem.produtoCodReferencia  := FProduto.codReferencia;
      FItem.produtoIdCategoria    := FProduto.idCategoria;
      FItem.vendaPorTamanho       := FProduto.vendaPorTamanho;
      FItem.valorUnitario         := FProduto.Valor;
      if (FItem.vendaPorTamanho) and (not FProduto.UsaHappyHour) then
        FItem.valorUnitario       := FProduto.ValorPorTamanho(FItem.tamanho);

      CalcularPromocao(FProduto);
    finally
      FreeAndNil(LVenda);
    end;
  finally
    FreeAndNil(LEmpresa);
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItemNormal.Execute;
const
  MAX_TENTATIVAS = 5;
var
  I: Integer;
begin
  ValidarCreditoCliente;
  AtribuirDadosDoProduto;

  for I := 1 to MAX_TENTATIVAS do
  begin
    FDAO.StartTransaction;
    try
      AtribuirNumeroItem;
      if not GravarVendaItem then
      begin
        FDAO.Commit;
        Exit;
      end;
      GravarVendaItemOpcional;
      if not FBatchMode then
        AtualizarValorVenda;
      FDAO.Commit;
      Exit;
    except
      FDAO.Rollback;
      if I = MAX_TENTATIVAS then
        raise;
    end;
  end;
end;


function TAPIRPCheffServiceVendaLancarItemNormal.GravarVendaItem: Boolean;
var
  LVendaItemDAO: TAPIRPCheffDAOVendaItem;
begin
  LVendaItemDAO             := FDAO.VendaItemDAO;
  LVendaItemDAO.ManagerTransaction(False);
  try
    FItem.acrescimo         := FItem.TotalOpcionais;
    if FItem.dataLancamento = 0 then
      FItem.dataLancamento  := Now;

    Result := LVendaItemDAO.Inserir(FItem, FPendenteImpressao);
  except
    on E: Exception do
    begin
      E.Message := 'Erro ao salvar VendaItem: ' + E.Message;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItemNormal.GravarVendaItemOpcional;
var
  LOpcional: TAPIRPCheffEntityVendaItemOpcional;
  LDAO: TAPIRPCheffDAOVendaItemOpcional;
begin
  LDAO                      := FDAO.VendaItemOpcionalDAO;
  LDAO.ManagerTransaction(False);
  for LOpcional in FItem.opcionais do
  begin
    LOpcional.idVenda       := FItem.idVenda;
    LOpcional.idEmpresa     := FItem.idEmpresa;
    LOpcional.idVendaItem   := FItem.numeroItem;
    LDAO.Inserir(LOpcional);
  end;
end;

end.
