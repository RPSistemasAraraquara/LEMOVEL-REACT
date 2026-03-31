unit APIRPCheff.Service.Venda.LancarItem.Fracionado;

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
  TAPIRPCheffServiceVendaLancarItemFracionado = class(TAPIRPCheffServiceVendaLancarItem)
  private
    FProduto: TAPIRPCheffEntityProduto;

    procedure CarregarDadosDoProduto(AItem: TAPIRPCheffEntityVendaItem);
    procedure CalcularPromocao(AProduto: TAPIRPCheffEntityProduto; AItem: TAPIRPCheffEntityVendaItem);
    procedure SalvarOpcionais(AItem: TAPIRPCheffEntityVendaItem); overload;
    procedure SalvarOpcionais(AItem: TAPIRPCheffEntityVendaItem; AFracao: TAPIRPCheffEntityVendaItemFracao); overload;
    procedure SalvarOutrasFracoes(AItem: TAPIRPCheffEntityVendaItem);
    procedure AtualizarValorVenda;
  public
    constructor Create(AProduto: TAPIRPCheffEntityProduto);
    procedure Execute; override;
  end;

implementation

{ TAPIRPCheffServiceVendaLancarItemFracionado }

procedure TAPIRPCheffServiceVendaLancarItemFracionado.AtualizarValorVenda;
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
      E.Message := 'Erro ao salvar atualizar total da venda: ' + E.Message;
      raise;
    end;
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItemFracionado.CalcularPromocao(AProduto: TAPIRPCheffEntityProduto; AItem: TAPIRPCheffEntityVendaItem);
var
  LDescontoCadastro: Currency;
begin
  if not AProduto.possuiPromocao then
    Exit;

  if AProduto.UsaHappyHour then
    Exit;

  if AProduto.vendaPorTamanho then
    LDescontoCadastro := AProduto.promocao.ValorDesconto(AItem.tamanho)
  else
    LDescontoCadastro := AProduto.promocao.ValorDesconto;

  if LDescontoCadastro <= 0 then
    Exit;

  if AProduto.promocao.tipoDesconto = tdValor then
    AItem.desconto := LDescontoCadastro
  else
    AItem.desconto := SimpleRoundTo(AItem.valorUnitario * LDescontoCadastro / 100);

  AItem.desconto := AItem.desconto * AItem.quantidade;
  AItem.AtualizaValorTotal;
end;

procedure TAPIRPCheffServiceVendaLancarItemFracionado.CarregarDadosDoProduto(AItem: TAPIRPCheffEntityVendaItem);
begin
  AItem.impressora1                 := FProduto.impressora1;
  AItem.impressora2                 := FProduto.impressora2;
  AItem.produtoDescricao            := FProduto.descricao;
  AItem.produtoCodReferencia        := FProduto.codReferencia;
  AItem.produtoIdCategoria          := FProduto.idCategoria;
  AItem.vendaPorTamanho             := FProduto.vendaPorTamanho;
  CalcularPromocao(FProduto, AItem);
end;

constructor TAPIRPCheffServiceVendaLancarItemFracionado.Create(AProduto: TAPIRPCheffEntityProduto);
begin
  FProduto := AProduto;
end;

procedure TAPIRPCheffServiceVendaLancarItemFracionado.Execute;
const
  MAX_TENTATIVAS = 3;
var
  LItemVenda: TAPIRPCheffEntityVendaItem;
  LDAO: TAPIRPCheffDAOVendaItem;
  I: Integer;
begin
  ValidarCreditoCliente;
  for I := 1 to MAX_TENTATIVAS do
  begin
    FDAO.StartTransaction;
    try
      LDAO := FDAO.VendaItemDAO;
      LDAO.ManagerTransaction(False);
      LItemVenda := TAPIRPCheffEntityVendaItem.Create;
      try
        if FItem.dataLancamento = 0 then
          FItem.dataLancamento := Now;

        FItem.itemFracionado := LDAO.UltimoItemFracionado(FItem.idVenda) + 1;
        LItemVenda.Assign(FItem);
        LItemVenda.numeroItem := LDAO.UltimoNumeroItemLancado(FItem.idVenda) + 1;
        LItemVenda.itemFracionado := FItem.itemFracionado;

        LItemVenda.quantidade := SimpleRoundTo(1 / (FItem.fracoes.Count), -3);
        LItemVenda.valorTotal := SimpleRoundTo(LItemVenda.quantidade * LItemVenda.valorUnitario, -2);

        CarregarDadosDoProduto(LItemVenda);
        if LItemVenda.tamanho = EmptyStr then
          LItemVenda.tamanho := 'M';

        SalvarOutrasFracoes(LItemVenda);
        if not FBatchMode then
          AtualizarValorVenda;
      finally
        FreeAndNil(LItemVenda);
      end;
      FDAO.Commit;
      Exit;
    except
      FDAO.Rollback;
      if I = MAX_TENTATIVAS then
        raise;
    end;
  end;
end;


procedure TAPIRPCheffServiceVendaLancarItemFracionado.SalvarOutrasFracoes(AItem: TAPIRPCheffEntityVendaItem);
var
  I: Integer;
  LItem: TAPIRPCheffEntityVendaItem;
  LDAO: TAPIRPCheffDAOVendaItem;
begin
  LDAO := FDAO.VendaItemDAO;
  LDAO.ManagerTransaction(False);
  for I := 0 to Pred(AItem.fracoes.Count) do
  begin
    LItem := TAPIRPCheffEntityVendaItem.Create;
    try
      LItem.Assign(AItem);
      LItem.desconto              := 0;
      LItem.idProduto             := AItem.fracoes[I].idProduto;
      LItem.produtoDescricao      := AItem.fracoes[I].produtoDescricao;
      LItem.valorUnitario         := AItem.fracoes[I].valorUnitario;
      LItem.quantidade            := AItem.quantidade;
      LItem.numeroItem            := LDAO.UltimoNumeroItemLancado(AItem.idVenda) + 1;
      LItem.itemFracionado        := FItem.itemFracionado;
      LItem.acrescimo             := AItem.fracoes[I].acrescimo;
      LItem.tamanho               := AItem.tamanho;
      LItem.observacao            := AItem.fracoes[I].observacao;

      CarregarDadosDoProduto(LItem);
      LItem.valorTotal := SimpleRoundTo(LItem.quantidade * LItem.valorUnitario, -3);

      LDAO.Inserir(LItem, FPendenteImpressao);
      SalvarOpcionais(LItem, AItem.fracoes[I]);
    finally
      FreeAndNil(LItem);
     end;
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItemFracionado.SalvarOpcionais(AItem: TAPIRPCheffEntityVendaItem);
var
  LOpcional: TAPIRPCheffEntityVendaItemOpcional;
  LDAO: TAPIRPCheffDAOVendaItemOpcional;
begin
  LDAO := FDAO.VendaItemOpcionalDAO;
  LDAO.ManagerTransaction(False);
  for LOpcional in AItem.opcionais do
  begin
    LOpcional.idVenda := AItem.idVenda;
    LOpcional.idEmpresa := AItem.idEmpresa;
    LOpcional.idVendaItem := AItem.numeroItem;
    LDAO.Inserir(LOpcional);
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItemFracionado.SalvarOpcionais(AItem: TAPIRPCheffEntityVendaItem;
  AFracao: TAPIRPCheffEntityVendaItemFracao);
var
  LOpcional: TAPIRPCheffEntityVendaItemOpcional;
  LDAO: TAPIRPCheffDAOVendaItemOpcional;
begin
  LDAO := FDAO.VendaItemOpcionalDAO;
  LDAO.ManagerTransaction(False);
  for LOpcional in AFracao.opcionais do
  begin
    LOpcional.idVenda := AItem.idVenda;
    LOpcional.idEmpresa := AItem.idEmpresa;
    LOpcional.idVendaItem := AItem.numeroItem;
    LDAO.Inserir(LOpcional);
  end;
end;


end.
