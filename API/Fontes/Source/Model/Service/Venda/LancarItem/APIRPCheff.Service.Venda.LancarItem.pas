unit APIRPCheff.Service.Venda.LancarItem;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Generics.Collections,
  System.Math,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaLancarItem = class
  private
    FProduto: TAPIRPCheffEntityProduto;
    procedure CarregarProduto;
    procedure ValidarRestricaoProduto(AProduto: TAPIRPCheffEntityProduto);
    procedure ValidarRestricaoVendaProdutos;
  protected
    FDAO  : TAPIRPCheffDAOFactory;
    FItem : TAPIRPCheffEntityVendaItem;
    FPendenteImpressao: Boolean;
    FBatchMode: Boolean;

    procedure ValidarCreditoCliente;
    procedure ValidarVenda;
  public
    constructor Create;
    destructor Destroy; override;

    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaLancarItem;
    function Item(AValue: TAPIRPCheffEntityVendaItem): TAPIRPCheffServiceVendaLancarItem;
    function PendenteImpressao(AValue: Boolean): TAPIRPCheffServiceVendaLancarItem;
    function BatchMode(AValue: Boolean): TAPIRPCheffServiceVendaLancarItem;
    procedure Execute; virtual;
    procedure ExecuteLote(AItens: TObjectList<TAPIRPCheffEntityVendaItem>);
  end;

implementation

uses
  APIRPCheff.Service.Venda.LancarItem.Normal,
  APIRPCheff.Service.Venda.LancarItem.Fracionado,
  APIRPCheff.Service.Venda.LancarItem.ControleGratis;

{ TAPIRPCheffServiceVendaLancarItem }

procedure TAPIRPCheffServiceVendaLancarItem.CarregarProduto;
begin
  FreeAndNil(FProduto);
  FProduto := FDAO.ProdutoDAO.Buscar(FItem.idProduto);

  if not Assigned(FProduto) then
    raise Exception.CreateFmt('Produto %d n'#227'o encontrado.', [FItem.idProduto]);
end;

procedure TAPIRPCheffServiceVendaLancarItem.ValidarRestricaoProduto(AProduto: TAPIRPCheffEntityProduto);
begin
  if (not Assigned(AProduto)) or (not AProduto.VendaRestritaHoje) then
    Exit;

  raise EConflictError.CreateFmt(
    'Produto "%s" nao pode ser lancado hoje (%s) por restricao de venda.',
    [AProduto.descricao, AProduto.DiaRestricaoAtualDescricao]
  );
end;

procedure TAPIRPCheffServiceVendaLancarItem.ValidarRestricaoVendaProdutos;
var
  I: Integer;
  LProdutoFracao: TAPIRPCheffEntityProduto;
  LIdProdutoFracao: Integer;
begin
  ValidarRestricaoProduto(FProduto);

  if (not Assigned(FItem)) or (not Assigned(FItem.fracoes)) then
    Exit;

  for I := 0 to Pred(FItem.fracoes.Count) do
  begin
    LIdProdutoFracao := FItem.fracoes[I].idProduto;
    if (LIdProdutoFracao <= 0) or (LIdProdutoFracao = FProduto.idProduto) then
      Continue;

    LProdutoFracao := FDAO.ProdutoDAO.Buscar(LIdProdutoFracao);
    try
      if not Assigned(LProdutoFracao) then
        raise Exception.CreateFmt('Produto %d n'#227'o encontrado.', [LIdProdutoFracao]);

      ValidarRestricaoProduto(LProdutoFracao);
    finally
      FreeAndNil(LProdutoFracao);
    end;
  end;
end;

function TAPIRPCheffServiceVendaLancarItem.BatchMode(AValue: Boolean): TAPIRPCheffServiceVendaLancarItem;
begin
  Result := Self;
  FBatchMode := AValue;
end;

constructor TAPIRPCheffServiceVendaLancarItem.Create;
begin
  inherited;
  FPendenteImpressao := True;
  FBatchMode := False;
end;

function TAPIRPCheffServiceVendaLancarItem.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaLancarItem;
begin
  Result := Self;
  FDAO := AValue;
end;

destructor TAPIRPCheffServiceVendaLancarItem.Destroy;
begin
  FreeAndNil(FProduto);
  inherited;
end;

procedure TAPIRPCheffServiceVendaLancarItem.Execute;
var
  LStrategy: TAPIRPCheffServiceVendaLancarItem;
begin
  if not FBatchMode then
    ValidarVenda;
  CarregarProduto;
  ValidarRestricaoVendaProdutos;
  FDAO.VendaItemDAO.GarantirPrecisaoQuantidadeDecimal;

  if FItem.fracoes.Count > 0 then
    LStrategy := TAPIRPCheffServiceVendaLancarItemFracionado.Create(FProduto)
  else
  if FProduto.proximoGratis then
    LStrategy := TAPIRPCheffServiceVendaLancarItemControleGratis.Create(FProduto)
  else
    LStrategy := TAPIRPCheffServiceVendaLancarItemNormal.Create(FProduto);
  try
    LStrategy.DAO(FDAO).Item(FItem).PendenteImpressao(FPendenteImpressao).BatchMode(FBatchMode);
    LStrategy.Execute;
  finally
    FreeAndNil(LStrategy)
  end;
end;

procedure TAPIRPCheffServiceVendaLancarItem.ExecuteLote(AItens: TObjectList<TAPIRPCheffEntityVendaItem>);
var
  LItem: TAPIRPCheffEntityVendaItem;
begin
  if (not Assigned(AItens)) or (AItens.Count = 0) then
    Exit;

  FItem := AItens[0];
  ValidarVenda;

  FBatchMode := True;
  for LItem in AItens do
  begin
    Item(LItem);
    Execute;
  end;

  FDAO.VendaDAO.AtualizarTotalVenda(AItens[0].idEmpresa, AItens[0].idVenda);
end;

function TAPIRPCheffServiceVendaLancarItem.PendenteImpressao(AValue: Boolean): TAPIRPCheffServiceVendaLancarItem;
begin
  Result := Self;
  FPendenteImpressao := AValue;
end;

function TAPIRPCheffServiceVendaLancarItem.Item(AValue: TAPIRPCheffEntityVendaItem): TAPIRPCheffServiceVendaLancarItem;
begin
  if not Assigned(AValue) then
    Exit(Self);

  Result := Self;
  FItem := AValue;
end;

procedure TAPIRPCheffServiceVendaLancarItem.ValidarCreditoCliente;
var
  LVenda: TAPIRPCheffEntityVenda;
  LEmpresa: TAPIRPCheffEntityEmpresa;
begin
  if not Assigned(FItem) or (FItem.idVenda <= 0) then
    Exit;

  LEmpresa := FDAO.EmpresaDAO.Busca;
  if not Assigned(LEmpresa) then
    Exit;

  try
    if (LEmpresa.casaNoturna) and (LEmpresa.casaControle = tccPosPago) then
      Exit;

    LVenda := FDAO.VendaDAO.Buscar(FItem.idVenda);
    if not Assigned(LVenda) then
      Exit;

    try
      if LVenda.idCliente > 0 then
      begin
        FItem.AtualizaValorTotal;
        if LVenda.totalCredito < FItem.valorTotal then
          Exit;
      end;
    finally
      LVenda.Free;
    end;
  finally
    FreeAndNil(LEmpresa);
  end;
end;


procedure TAPIRPCheffServiceVendaLancarItem.ValidarVenda;
var
  LVenda: TAPIRPCheffEntityVenda;
begin
  LVenda := FDAO.VendaDAO.Buscar(FItem.idVenda);
  try
    if not Assigned(LVenda) then
      raise Exception.CreateFmt('Venda %d n'#227'o encontrada.', [FItem.idVenda]);

    if LVenda.situacao <> TRPCheffSituacaoVenda.svPendente then
      raise EConflictError.CreateFmt('N'#227'o '#233' permitido lan'#231'ar item na venda com situa'#231#227'o %s.',
        [LVenda.situacao.Description]);
  finally
    FreeAndNil(LVenda);
  end;
end;

end.
