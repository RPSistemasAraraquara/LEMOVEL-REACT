unit APIRPCheff.Service.Venda.Fechamento.Command.SalvarPagamentos.VendaNormal;

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
  TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal = class(TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentos)
  private
    FFechamento: TAPIRPCheffEntityVendaPostFechamento;
    FAntecipados: TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
    FIdFormaTroco: Integer;
    FValorPendente: Currency;
    FValorPago: Currency;
    FValorTroco: Currency;
    FNumeroItem: Integer;

    procedure CarregarAntecipados;
    procedure CarregarDadosPagamento;
    procedure CalcularTroco;
    procedure ValidarValores;
    procedure VerificarVendaComValorZero;

    procedure ProcessaPagamentos;

    procedure InserirEncerraVendaItem(AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento;
      const AHashTerminal, AAutorizacao, AAcquirerDocument: string);
    procedure GravarCaixaItem(AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento; Item: Integer; AAntecipado: Boolean = False);
    procedure GravarControleCartao(AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento);
  public
    destructor Destroy; override;

    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal }

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.CalcularTroco;
var
  I: Integer;
   LValor: Double;
begin
  FIdFormaTroco := 0;
  LValor := FFechamento.ValorPagamento - FValorPendente - FFechamento.ValorTaxaServico;
  FValorTroco := Trunc(LValor * 100) / 100;

  if FValorTroco < 0.001 then
    FValorTroco := 0;

  if FValorTroco <= 0.001 then
    Exit;

  if (not FFechamento.PossuiPagamentoDinheiro) and
    (not FParent.ConfiguracaoMesa.permiteTrocoTodasAsFormas) then
    raise Exception.CreateFmt('O valor recebido %s '#233' superior ao valor da venda %s!',
      [FormatFloat(',0.00', FFechamento.ValorPagamento), FormatFloat(',0.00', FValorPendente)]);

  if (FFechamento.PossuiPagamentoDinheiro) and
    (FFechamento.ValorPagoEmDinheiro < FValorTroco) and
    (not FParent.ConfiguracaoMesa.permiteTrocoTodasAsFormas) then
    raise Exception.Create('N'#227'o '#233' possivel devolver troco pois o valor recebido em dinheiro '#233' insuficiente!');

  for I := 0 to Pred(FFechamento.pagamentos.Count) do
    if FFechamento.pagamentos[I].formaPagamento.Dinheiro then
      FIdFormaTroco := FFechamento.pagamentos[I].idFormaPgto;

  if FIdFormaTroco = 0 then
    for I := 0 to Pred(FFechamento.pagamentos.Count) do
      if FFechamento.pagamentos[I].valor > FValorTroco then
        FIdFormaTroco := FFechamento.pagamentos[I].idFormaPgto;

  if FIdFormaTroco = 0 then
    raise Exception.Create('N'#227'o '#233' possivel devolver troco em nenhuma forma de pagamento informada!');
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.CarregarAntecipados;
var
  I: Integer;
begin
  FreeAndNil(FAntecipados);
  FValorPago := 0;
  FAntecipados := FParent.DAO.VendaPagamentoAntecipadoDAO.Listar(FParent.Venda.idVenda);

  for I := 0 to Pred(FAntecipados.Count) do
    if FAntecipados[I].situacao = sAtivo then
      FValorPago := FValorPago + FAntecipados[I].valor;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.ValidarValores;
var
  LValorPagamento: Currency;
begin
  FValorPago       := RoundTo(FValorPago, -2);
  LValorPagamento  := RoundTo(FFechamento.ValorPagamento, -2);
  FValorPendente   := RoundTo(FParent.Venda.valorTotal - FFechamento.valorDesconto, -2) - FValorPago;
  if RoundTo(LValorPagamento - FValorPendente, -2) < -0.001 then
    raise Exception.CreateFmt('Valor Pagamento %s menor que o valor pendente %s.',
      [FormatCurr(',0.00', LValorPagamento), FormatCurr(',0.00', FValorPendente)]);
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.CarregarDadosPagamento;
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

destructor TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.Destroy;
begin
  FreeAndNil(FAntecipados);
  inherited;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.Execute(
  AFechamento: TAPIRPCheffEntityVendaPostFechamento);
begin
  FFechamento := AFechamento;
  CarregarAntecipados;
  CarregarDadosPagamento;
  ValidarValores;
  VerificarVendaComValorZero;
  CalcularTroco;
  ProcessaPagamentos;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.GravarCaixaItem(
  AValor: Currency; AForma: TAPIRPCheffEntityFormaPagamento; Item: Integer;
  AAntecipado: Boolean);
var
  LCaixaItem: TAPIRPCheffEntityCaixaItem;
  LDAO: TAPIRPCheffDAOCaixaItem;
begin
  LDAO := FParent.DAO.CaixaItemDAO;
  LDAO.ManagerTransaction(False);
  LCaixaItem := TAPIRPCheffEntityCaixaItem.Create;
  try
    LCaixaItem.item := Item;
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

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.GravarControleCartao(
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

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.InserirEncerraVendaItem(
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

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.ProcessaPagamentos;
var
  I: Integer;
  LValor: Currency;
  LForma: TAPIRPCheffEntityFormaPagamento;
begin
  FNumeroItem := 0;
  for I := 0 to Pred(FAntecipados.Count) do
  begin
    if FAntecipados[I].situacao = sAtivo then
    begin
      FNumeroItem := FNumeroItem + 1;
      LValor := FAntecipados[I].valor;
      LForma := FAntecipados[I].formaPagamento;
      InserirEncerraVendaItem(LValor, LForma, FAntecipados[I].hash_terminal,
        FAntecipados[I].autorizacao, FAntecipados[I].acquirerdocument);
      GravarCaixaItem(LValor, LForma, FContext^.ProximoIdCaixaItem, True);
      GravarControleCartao(LValor, LForma);
    end;
  end;

  for I := 0 to Pred(FFechamento.pagamentos.Count) do
  begin
    FNumeroItem := FNumeroItem + 1;
    LValor := FFechamento.pagamentos[I].valor;
    LForma := FFechamento.pagamentos[I].formaPagamento;
    InserirEncerraVendaItem(LValor, LForma, FFechamento.pagamentos[I].hash_terminal,
      FFechamento.pagamentos[I].autorizacao, FFechamento.pagamentos[I].acquirerdocument);
    GravarCaixaItem(LValor, LForma, FContext^.ProximoIdCaixaItem, False);
    Inc(FContext^.ProximoIdCaixaItem);
    GravarControleCartao(LValor, LForma);
  end;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.VerificarVendaComValorZero;
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
