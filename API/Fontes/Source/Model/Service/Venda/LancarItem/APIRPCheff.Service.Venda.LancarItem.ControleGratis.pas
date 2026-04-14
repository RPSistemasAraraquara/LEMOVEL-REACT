unit APIRPCheff.Service.Venda.LancarItem.ControleGratis;

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
  TAPIRPCheffServiceVendaLancarItemControleGratis = class(TAPIRPCheffServiceVendaLancarItem)
  private
    FProduto           : TAPIRPCheffEntityProduto;
    FQuantidadeVendido : Integer;
    FQuantidadeGratis  : Integer;

    procedure CarregarQuantidadeVendido;
    procedure CalcularQuantidadeGratis;
    procedure AtribuirDadosDoProduto;
    procedure CalcularPromocao(AProduto: TAPIRPCheffEntityProduto);
    procedure GravarVendaItem;
    procedure GravarVendaItemOpcional;
    procedure GravarItensGratis;
    procedure AtualizarValorVenda;
    procedure AtribuirNumeroItem;
  public
    constructor Create(AProduto: TAPIRPCheffEntityProduto);
    procedure Execute; override;

  end;

implementation

const
  OBSERVACAO_ITEM_GRATIS = 'GR' + #193 + 'TIS';

{ TAPIRPCheffServiceVendaLancarItemControleGratis }

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.AtribuirNumeroItem;
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

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.AtualizarValorVenda;
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

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.CalcularPromocao(AProduto: TAPIRPCheffEntityProduto);
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

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.CalcularQuantidadeGratis;
var
  I: Integer;
  LQuantidadeBase: Integer;
begin
  FQuantidadeGratis := 0;
  LQuantidadeBase := FQuantidadeVendido;
  for I := 1 to Trunc(FItem.quantidade) do
  begin
    if LQuantidadeBase = FProduto.quantidadeProximoGratis then
    begin
      LQuantidadeBase := 0;
      Inc(FQuantidadeGratis);
    end
    else
      Inc(LQuantidadeBase);
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.CarregarQuantidadeVendido;
var
  LItens: TObjectList<TAPIRPCheffEntityVendaItem>;
  LTotalGratis: Integer;
  LQuantidadeItens: Integer;
begin
  LTotalGratis := 0;
  LQuantidadeItens := 0;
  LItens := FDAO.VendaItemDAO.Listar(FItem.idVenda, FItem.idProduto);
  try
    for var LItem in LItens do
    begin
      LQuantidadeItens := LQuantidadeItens + Trunc(LItem.quantidade);
      if LItem.valorTotal = 0 then
        Inc(LTotalGratis);
    end;
    FQuantidadeVendido := LQuantidadeItens - (FProduto.quantidadeProximoGratis * LTotalGratis) -
      LTotalGratis;
  finally
    FreeAndNil(LItens);
   end;
end;

constructor TAPIRPCheffServiceVendaLancarItemControleGratis.Create(AProduto: TAPIRPCheffEntityProduto);
begin
  FProduto := AProduto;
  FQuantidadeVendido := 0;
  FQuantidadeGratis := 0;
end;

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.AtribuirDadosDoProduto;
begin
  FItem.impressora1 := FProduto.impressora1;
  FItem.impressora2 := FProduto.impressora2;
  FItem.produtoDescricao := FProduto.descricao;
  FItem.produtoCodReferencia := FProduto.codReferencia;
  FItem.produtoIdCategoria := FProduto.idCategoria;
  FItem.vendaPorTamanho := FProduto.vendaPorTamanho;
  FItem.valorUnitario := FProduto.Valor;
  if FItem.vendaPorTamanho then
    FItem.valorUnitario := FProduto.ValorPorTamanho(FItem.tamanho);
  FItem.AtualizaValorTotal;
end;

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.Execute;
const
  MAX_TENTATIVAS = 3;
var
  I: Integer;
begin
  ValidarCreditoCliente;
  CarregarQuantidadeVendido;
  CalcularQuantidadeGratis;
  for I := 1 to MAX_TENTATIVAS do
  begin
    FDAO.StartTransaction;
    try
      FItem.quantidade := FItem.quantidade - FQuantidadeGratis;
      if FItem.quantidade > 0 then
      begin
        AtribuirNumeroItem;
        AtribuirDadosDoProduto;
        CalcularPromocao(FProduto);
        GravarVendaItem;
        GravarVendaItemOpcional;
      end;
      GravarItensGratis;
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

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.GravarItensGratis;
var
  I: Integer;
  LObservacaoOriginal: string;
begin
  LObservacaoOriginal := FItem.observacao;
  for I := 1 to FQuantidadeGratis do
  begin
    FItem.quantidade := 1;
    AtribuirNumeroItem;
    AtribuirDadosDoProduto;
    FItem.valorUnitario := 0;
    FItem.acrescimo := 0;
    FItem.desconto := 0;
    FItem.gratis := True;
    FItem.observacao := OBSERVACAO_ITEM_GRATIS;
    FItem.AtualizaValorTotal;

    GravarVendaItem;
    GravarVendaItemOpcional;
  end;
  FItem.gratis := False;
  FItem.observacao := LObservacaoOriginal;
end;

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.GravarVendaItem;
var
  LVendaItemDAO: TAPIRPCheffDAOVendaItem;
begin
  LVendaItemDAO := FDAO.VendaItemDAO;
  LVendaItemDAO.ManagerTransaction(False);
  try
    if FItem.valorTotal > 0 then
      FItem.gratis := False;
    FItem.acrescimo := FItem.TotalOpcionais;
    if FItem.dataLancamento = 0 then
      FItem.dataLancamento := Now;

    LVendaItemDAO.Inserir(FItem, FPendenteImpressao);
  except
    on E: Exception do
    begin
      E.Message := 'Erro ao salvar VendaItem: ' + E.Message;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItemControleGratis.GravarVendaItemOpcional;
var
  LOpcional: TAPIRPCheffEntityVendaItemOpcional;
  LDAO: TAPIRPCheffDAOVendaItemOpcional;
begin
  LDAO := FDAO.VendaItemOpcionalDAO;
  LDAO.ManagerTransaction(False);
  for LOpcional in FItem.opcionais do
  begin
    LOpcional.idVenda := FItem.idVenda;
    LOpcional.idEmpresa := FItem.idEmpresa;
    LOpcional.idVendaItem := FItem.numeroItem;
    LDAO.Inserir(LOpcional);
  end;
end;

end.
