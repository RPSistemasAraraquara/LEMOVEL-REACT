unit APIRPCheff.Service.Venda.Fechamento.Command.SalvarPagamentos.VendaPrePaga;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command.SalvarPagamentos,
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Math,
  System.Generics.Collections,
  System.DateUtils,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga =
    class(TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentos)
  private
    FPrePagamentos: TObjectList<TAPIRPCheffEntityVendaPrePago>;
    FFechamento: TAPIRPCheffEntityVendaPostFechamento;
    FIdFormaTroco: Integer;
    FValorPendente: Currency;
    FValorTroco: Currency;
    FNumeroItem: Integer;

    procedure CarregarPrePagamentos;
    procedure CarregarDadosPagamento;
    procedure CalcularTroco;
    procedure ValidarValores;
    procedure VerificarVendaComValorZero;

    procedure ProcessaPagamentos;

    procedure InserirEncerraVendaItem(AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento;
      const AHashTerminal, AAutorizacao, AAcquirerDocument: string);
    procedure GravarCaixaItem(AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento;
      AAntecipado: Boolean = False);
    procedure GravarControleCartao(AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento);
  public
    destructor Destroy; override;

    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga }

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.CalcularTroco;
begin
  FIdFormaTroco := 0;
  FValorTroco := FParent.Venda.totalPrePago - FParent.Venda.valorTotal;
  if FValorTroco < 0.001 then
    FValorTroco := 0;

  if FValorTroco <= 0.001 then
    Exit;

  if FPrePagamentos.Count > 0 then
    FIdFormaTroco := FPrePagamentos[0].IdFormaPagamento;

  if FIdFormaTroco = 0 then
    raise Exception.Create('N'#227'o '#233' possivel devolver troco em nenhuma forma de pagamento informada!');
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.ValidarValores;
var
  LValorPagamento: Currency;
begin
  LValorPagamento := RoundTo(FFechamento.ValorPagamento, -2);
  FValorPendente := RoundTo(FParent.Venda.valorTotal - FFechamento.valorDesconto, -2) -
    FParent.Venda.totalPrePago;
  if RoundTo(LValorPagamento - FValorPendente, -2) < -0.001 then
    raise Exception.CreateFmt('Valor Pagamento %s menor que o valor pendente %s.',
      [FormatCurr(',0.00', LValorPagamento), FormatCurr(',0.00', FValorPendente)]);
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.CarregarDadosPagamento;
var
  I: Integer;
  LForma: TAPIRPCheffEntityFormaPagamento;
  LPagamento: TAPIRPCheffEntityFormaPagamento;
begin
  for I := 0 to Pred(FFechamento.pagamentos.Count) do
  begin
    LForma := FParent.DAO.FormaPagamentoDAO.GetFormaPagamento(FFechamento.pagamentos[I].idFormaPgto);
    try
      if not Assigned(LForma) then
        raise Exception.CreateFmt('Forma Pagamento %d n'#227'o encontrada.',
          [FFechamento.pagamentos[I].idFormaPgto]);

      LPagamento := FFechamento.pagamentos[I].formaPagamento;
      LPagamento.Assign(LForma);
    finally
      FreeAndNil(LForma);
    end;
  end;

  if (FFechamento.PossuiCortesia) and (FFechamento.PossuiNaoCortesia) then
    raise Exception.Create('Forma de pagamento (Cortesia) n'#227'o pode ser utilizada com outra forma!');
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.CarregarPrePagamentos;
begin
  FreeAndNil(FPrePagamentos);
  FPrePagamentos := FParent.DAO.VendaPrePagoDAO.Listar(FParent.Venda.idVenda);
end;

destructor TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.Destroy;
begin
  FreeAndNil(FPrePagamentos);
  inherited;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.Execute(
  AFechamento: TAPIRPCheffEntityVendaPostFechamento);
begin
  FFechamento := AFechamento;
  CarregarPrePagamentos;
  CarregarDadosPagamento;
  ValidarValores;
  VerificarVendaComValorZero;
  CalcularTroco;
  ProcessaPagamentos;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.GravarCaixaItem(
  AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento;
  AAntecipado: Boolean);
var
  LCaixaItem: TAPIRPCheffEntityCaixaItem;
  LDAO: TAPIRPCheffDAOCaixaItem;
begin
  LDAO := FParent.DAO.CaixaItemDAO;
  LDAO.ManagerTransaction(False);
  LCaixaItem := TAPIRPCheffEntityCaixaItem.Create;
  try
    LCaixaItem.idEmpresa := FFechamento.idEmpresa;
    LCaixaItem.idCaixa := FParent.Venda.idCaixa;
    LCaixaItem.tipoMovimento := 'E';
    LCaixaItem.idFormaPgto := AForma.codigo;
    LCaixaItem.idVenda := FParent.Venda.idVenda;
    LCaixaItem.itemEncerraVenda := FNumeroItem;
    LCaixaItem.idEncerraVenda := FParent.IdEncerraVenda;
    LCaixaItem.classificacao := 'V';
    LCaixaItem.antecipado := AAntecipado;

    if not AForma.cortesia then
      LCaixaItem.valor := AValor;

    if AAntecipado then
      LDAO.AtualizaPagamentoAntecipado(LCaixaItem)
    else
      LDAO.Inserir(LCaixaItem);
  finally
    FreeAndNil(LCaixaItem);
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.GravarControleCartao(
  AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento);
var
  LTipoMovimento: TAPIRPCheffEntityTipoMovimento;
  LDAO: TAPIRPCheffDAOTipoMovimento;
  LValor: Currency;
begin
  LDAO := FParent.DAO.TipoMovimentoDAO;
  LDAO.ManagerTransaction(False);
  if not AForma.utilizaControleCartao then
    Exit;

  if AForma.idContaCorrente <= 0 then
    Exit;

  LTipoMovimento := TAPIRPCheffEntityTipoMovimento.Create;
  try
    LTipoMovimento.idEmpresa := FFechamento.idEmpresa;
    LTipoMovimento.tipo := '0';
    LTipoMovimento.dataEmissao := IncDay(Now, AForma.prazoCartao);
    LTipoMovimento.documento := FParent.IdEncerraVenda.ToString;
    LTipoMovimento.observacao := 'VENDA: ' + FParent.Venda.idVenda.ToString;
    LTipoMovimento.idUsuarioLancamento := FFechamento.idUsuario;
    LTipoMovimento.idContaCorrente := AForma.idContaCorrente;
    LTipoMovimento.compensado := 1;
    LTipoMovimento.situacao := sAtivo;
    LTipoMovimento.idVenda := FParent.Venda.idVenda;
    LTipoMovimento.itemEncerraVenda := FNumeroItem;
    LTipoMovimento.idEncerraVenda := FParent.IdEncerraVenda;

    if not AForma.cortesia then
    begin
      LValor := AValor;
      LValor := RoundTo(LValor - ((LValor * AForma.taxaCartao) / 100), -2);
      LTipoMovimento.valor := LValor;
    end;

    LDAO.Inserir(LTipoMovimento);
  finally
    FreeAndNil(LTipoMovimento);
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.InserirEncerraVendaItem(
  AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento;
  const AHashTerminal, AAutorizacao, AAcquirerDocument: string);
var
  LEncerraVendaItem: TAPIRPCheffEntityEncerraVendaItem;
  LDAO: TAPIRPCheffDAOEncerraVendaItem;
begin
  LDAO := FParent.DAO.EncerraVendaItemDAO;
  LDAO.ManagerTransaction(False);
  LEncerraVendaItem := TAPIRPCheffEntityEncerraVendaItem.Create;
  try
    LEncerraVendaItem.idEmpresa := FFechamento.idEmpresa;
    LEncerraVendaItem.idEncerraVenda := FParent.IdEncerraVenda;
    LEncerraVendaItem.numeroItem := FNumeroItem;
    LEncerraVendaItem.idFormaPgto := AForma.codigo;
    LEncerraVendaItem.novaVenda := False;
    LEncerraVendaItem.trocoDinheiro := 0;
    LEncerraVendaItem.hash_terminal := AHashTerminal;
    LEncerraVendaItem.autorizacao := AAutorizacao;
    LEncerraVendaItem.acquirerdocument := AAcquirerDocument;

    if not AForma.cortesia then
      LEncerraVendaItem.valor := AValor;

    if AForma.codigo = FIdFormaTroco then
    begin
      LEncerraVendaItem.trocoDinheiro := FValorTroco;
      LEncerraVendaItem.valor := LEncerraVendaItem.valor - FValorTroco;
    end;

    LDAO.Inserir(LEncerraVendaItem);
  finally
    FreeAndNil(LEncerraVendaItem);
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.ProcessaPagamentos;
var
  I: Integer;
  LValor: Currency;
  LForma: TAPIRPCheffEntityFormaPagamento;
begin
  FNumeroItem := 0;
  for I := 0 to Pred(FPrePagamentos.Count) do
  begin
    FNumeroItem := FNumeroItem + 1;
    LValor := FPrePagamentos[I].valor;
    LForma := FParent.DAO.FormaPagamentoDAO.GetFormaPagamento(FPrePagamentos[I].IdFormaPagamento);
    try
      if not Assigned(LForma) then
        raise Exception.CreateFmt('Forma pagamento %d n'#227'o encontrada.',
          [FPrePagamentos[I].IdFormaPagamento]);
      InserirEncerraVendaItem(LValor, LForma, '', '', '');
      GravarCaixaItem(LValor, LForma, False);
      GravarControleCartao(LValor, LForma);
    finally
      FreeAndNil(LForma);
    end;
  end;

  for I := 0 to Pred(FFechamento.pagamentos.Count) do
  begin
    FNumeroItem := FNumeroItem + 1;
    LValor := FFechamento.pagamentos[I].valor;
    LForma := FFechamento.pagamentos[I].formaPagamento;
    InserirEncerraVendaItem(LValor, LForma, FFechamento.pagamentos[I].hash_terminal,
      FFechamento.pagamentos[I].autorizacao, FFechamento.pagamentos[I].acquirerdocument);
    GravarCaixaItem(LValor, LForma, False);
    GravarControleCartao(LValor, LForma);
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.VerificarVendaComValorZero;
var
  LForma: TAPIRPCheffEntityFormaPagamento;
  LPagamento: TAPIRPCheffEntityFormaPagamento;
begin
  if (FValorPendente = 0) and (FParent.Venda.valorTotal = 0) then
  begin
    FFechamento.pagamentos.Clear;
    LForma := FParent.DAO.FormaPagamentoDAO.GetFormaDinheiro;
    try
      if not Assigned(LForma) then
        raise Exception.Create('Forma de pagamento dinheiro n'#227'o encontrada.');

      FFechamento.AddPagamento;
      FFechamento.pagamentos.Last.idFormaPgto := LForma.codigo;
      LPagamento := FFechamento.pagamentos.Last.formaPagamento;
      LPagamento.Assign(LForma);
    finally
      FreeAndNil(LForma);
    end;
  end;
end;

end.
