unit APIRPCheff.Service.Venda.ImpressaoSTONE;

interface

uses
  APIRPCheff.Service.Venda.Impressao,
  APIRPCheff.Service.Venda.Consulta,
  APIRPCheff.Resources,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  APIRPCheff.Utils,
  System.JSON,
  System.Generics.Collections,
  System.SysUtils,
  System.Math,
  System.Classes,
  System.StrUtils;

  type
  TAPIRPCheffServiceVendaImpressaoSTONE = class(TAPIRPCheffServiceVendaImpressao)
  private
    FData                    : TDateTime;
    FEmpresa                 : TAPIRPCheffEntityEmpresa;
    FVenda                   : TAPIRPCheffEntityVenda;
    FVendaItens              : TObjectList<TAPIRPCheffEntityVendaItem>;
    FValorPendente           : Currency;
    FJsonArray               : TJSONArray;
    procedure AddText(const AContent, AAlign, ASize: string; const AStyle: string = 'bold');
    procedure AddBlankLine;
    procedure AddSeparator;
    procedure AddDash;
    function GetCabecalhoVendaCupom: string;
    function GetTituloConferencia: string;
    function GetTamanhoTituloConferencia: string;
    procedure CarregarVenda;
    procedure CarregarEmpresa;
    procedure CarregarItens;
    procedure CarregarItemNormal(AItem: TAPIRPCheffEntityVendaItem);
    procedure CarregarItemFracionado;
    procedure CarregarOpcionais(AItem: TAPIRPCheffEntityVendaItem);
    procedure CarregarTotal;
    procedure CarregarPagamentosAntecipados;
    procedure CarregarPagamentos;
    procedure CarregarGarcons;
    procedure CarregarRodape;
    procedure ImprimirFichaIndividualVerificada;
    procedure CarregarOperadorPreFechamento;
  public
    destructor Destroy; override;

    function Execute: TStream; override;
  end;


implementation

{ TAPIRPCheffServiceVendaImpressaoSTONE }

procedure TAPIRPCheffServiceVendaImpressaoSTONE.AddText(const AContent, AAlign, ASize: string;
  const AStyle: string);
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.Create;
  LObj.AddPair('type', 'text');
  LObj.AddPair('content', AContent);
  LObj.AddPair('align', AAlign);
  LObj.AddPair('size', ASize);
  if not AStyle.Trim.IsEmpty then
    LObj.AddPair('style', AStyle);
  FJsonArray.Add(LObj);
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.AddBlankLine;
begin
  AddText(' ', 'center', 'small');
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.AddSeparator;
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.Create;
  LObj.AddPair('type', 'line');
  LObj.AddPair('content', '================================');
  FJsonArray.Add(LObj);
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.AddDash;
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.Create;
  LObj.AddPair('type', 'line');
  LObj.AddPair('content', '--------------------------------');
  FJsonArray.Add(LObj);
end;

function TAPIRPCheffServiceVendaImpressaoSTONE.GetCabecalhoVendaCupom: string;
var
  LDescricaoVenda: string;
begin
  if FVenda.numeroMesa > 0 then
    LDescricaoVenda := 'MESA ' + FVenda.numeroMesa.ToString
  else if FVenda.numeroComanda > 0 then
    LDescricaoVenda := 'COMANDA ' + FVenda.numeroComanda.ToString
  else
    LDescricaoVenda := FVenda.DescricaoMesaComanda.ToUpper;

  Result := Trim(LDescricaoVenda + ' CUP. ' + FVenda.numeroCupom.ToString);
end;

function TAPIRPCheffServiceVendaImpressaoSTONE.GetTituloConferencia: string;
begin
  Result := 'CONF. SIMPLES';
end;

function TAPIRPCheffServiceVendaImpressaoSTONE.GetTamanhoTituloConferencia: string;
begin
  Result := 'medium';
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarEmpresa;
begin
  FreeAndNil(FEmpresa);
  FDAO.EmpresaDAO.IdEmpresa(FIdEmpresa);
  FEmpresa := FDAO.EmpresaDAO.Busca;
  if not Assigned(FEmpresa) then
    raise Exception.CreateFmt('Empresa %d n'#227'o encontrada.', [FIdEmpresa]);

  AddSeparator;
  AddBlankLine;
  AddText(FEmpresa.nome, 'center', 'big', 'bold');
  AddBlankLine;
  AddText(FEmpresa.endereco + ', ' + FEmpresa.numero, 'center', 'medium');

  if FEmpresa.telefonePrincipal = 0 then
    AddText('Fone: ' + FEmpresa.telefone, 'center', 'medium')
  else
    AddText('Fone: ' + FEmpresa.celular, 'center', 'medium');

  AddBlankLine;
  AddSeparator;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarGarcons;
var
  LGarcons: TList<Integer>;
  LTextoGarcom: string;
begin
  LGarcons := TList<Integer>.Create;
  try
    LTextoGarcom := EmptyStr;

    for var LItem in FVendaItens do
    begin
      if LItem.idGarcom <= 0 then
        Continue;

      if LGarcons.Contains(LItem.idGarcom) then
        Continue;

      var LGarcom := FDAO.UsuarioDAO.Busca(LItem.idGarcom);
      try
        if not Assigned(LGarcom) then
          Continue;

        if Trim(LGarcom.nome) = EmptyStr then
          Continue;

        if LTextoGarcom <> EmptyStr then
          LTextoGarcom := LTextoGarcom + ', ';
        LTextoGarcom := LTextoGarcom + LGarcom.nome;
        LGarcons.Add(LItem.idGarcom);
      finally
        LGarcom.Free;
      end;
    end;

    if LTextoGarcom <> EmptyStr then
    begin
      AddDash;
      AddText('GAR'#199'ONS', 'center', 'medium', 'bold');
      AddText(LTextoGarcom, 'center', 'medium');
    end;
  finally
    LGarcons.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarItemFracionado;
var
  LPossuiFracionado: Boolean;
begin
  LPossuiFracionado := False;
  for var LItem in FVendaItens do
  begin
    LPossuiFracionado := LItem.Fracionado;
    if LPossuiFracionado then
      Break;
  end;

  if not LPossuiFracionado then
    Exit;

  for var LItem in FVendaItens do
  begin
    if not LItem.Fracionado then
      Continue;

    AddDash;
    AddText('ITEM FRACIONADO', 'center', 'medium', 'bold');

    for var LFracao in LItem.fracoes do
    begin
      var LDescricao := LFracao.produtoDescricao;
      if LFracao.DescricaoTamanho <> EmptyStr then
        LDescricao := LDescricao + ' (' + LFracao.descricaoTamanho + ')';

      AddText(LDescricao, 'left', 'medium', 'bold');
      AddText(
        Format('%.0f', [LFracao.quantidade]) + ' x ' +
        Format('R$ %.2f', [LFracao.valorUnitario]) + ' = ' +
        Format('R$ %.2f', [LFracao.valorTotal]),
        'left', 'medium');
    end;

    if not FImprimirOpcionais then
      Continue;

    for var LOpcional in LItem.opcionais do
      AddText('  + ' + LOpcional.descricao, 'left', 'small');
  end;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarItemNormal(AItem: TAPIRPCheffEntityVendaItem);
var
  LFormatoQuantidade: string;
  LDescricao: string;
begin
  LFormatoQuantidade := '%.3f';
  if (not FImprimirDecimais) and (AItem.quantidade - Trunc(AItem.quantidade) = 0) then
    LFormatoQuantidade := '%.0f';

  LDescricao := AItem.produtoDescricao;
  if AItem.descricaoTamanho <> EmptyStr then
    LDescricao := LDescricao + ' (' + AItem.descricaoTamanho + ')';

  AddText(LDescricao, 'left', 'medium', 'bold');
  AddText(
    Format(LFormatoQuantidade, [AItem.quantidade]) + ' x ' +
    Format('R$ %.2f', [AItem.valorUnitario]) + ' = ' +
    Format('R$ %.2f', [AItem.valorTotal]),
    'left', 'medium');

  if FImprimirOpcionais then
    CarregarOpcionais(AItem);
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarItens;
begin
  FreeAndNil(FVendaItens);
  FVendaItens := FDAO.VendaItemDAO.ListarVendasAgrupadosProdutos(FIdVenda);

  for var LItem in FVendaItens do
    if not LItem.Fracionado then
      CarregarItemNormal(LItem);

  CarregarItemFracionado;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarOpcionais(AItem: TAPIRPCheffEntityVendaItem);
begin
  if not FImprimirOpcionais then
    Exit;

  for var LOpcional in AItem.opcionais do
    AddText('  + ' + LOpcional.descricao, 'left', 'small');
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarPagamentos;
var
  LEncerramentos: TObjectList<TAPIRPCheffEntityEncerraVendaItem>;
  LTotalTroco: Currency;
begin
  LTotalTroco := 0;
  LEncerramentos := FDAO.EncerraVendaItemDAO.Listar(FVenda.idVenda);
  try
    if LEncerramentos.Count > 0 then
    begin
      AddBlankLine;
      AddText('PAGAMENTOS', 'center', 'medium', 'bold');
      AddDash;
    end;

    for var LEncerramento in LEncerramentos do
    begin
      LTotalTroco := LTotalTroco + LEncerramento.trocoDinheiro;
      FValorPendente := FValorPendente - LEncerramento.valor;
      AddText(
        LEncerramento.formaPagamento.descricao + ': ' +
        Format('R$ %.2f', [LEncerramento.ValorPago]),
        'left', 'medium');
    end;

    if LTotalTroco > 0 then
      AddText('Troco: ' + Format('R$ %.2f', [LTotalTroco]), 'left', 'medium', 'bold');

    if FValorPendente > 0 then
    begin
      AddBlankLine;
      AddSeparator;
      AddText('VALOR PENDENTE: ' + Format('R$ %.2f', [FValorPendente]), 'center', 'big', 'bold');
      AddSeparator;
    end;
  finally
    LEncerramentos.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarPagamentosAntecipados;
var
  LPagamentos: TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
  LPossuiPagamento: Boolean;
begin
  LPagamentos := FDAO.VendaPagamentoAntecipadoDAO.Listar(FIdVenda);
  try
    LPossuiPagamento := LPagamentos.Count > 0;
    if LPossuiPagamento then
    begin
      AddBlankLine;
      AddText('PAGAMENTOS ANTECIPADOS', 'center', 'medium', 'bold');
      AddDash;
    end;

    for var LPagamento in LPagamentos do
    begin
      FValorPendente := FValorPendente - LPagamento.valor;
      AddText(
        LPagamento.formaPagamento.descricao + ': ' +
        Format('R$ %.2f', [LPagamento.valor]),
        'left', 'medium');
    end;
  finally
    LPagamentos.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarRodape;
begin
  AddBlankLine;
  AddSeparator;
  AddBlankLine;
  AddText('RP Cheff', 'center', 'big', 'bold');
  AddText('www.sistemalechef.com.br', 'center', 'small');
  AddBlankLine;
  AddSeparator;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarTotal;
var
  LTotalItens: Currency;
  LDesconto: Currency;
  LQuantidadeItens: Integer;
begin
  LTotalItens      := 0;
  LDesconto        := 0;
  LQuantidadeItens := 0;
  for var LItem in FVendaItens do
  begin
    if LItem.TotalFracoes > 0 then
      LTotalItens := LTotalItens + LItem.TotalFracoes
    else
      LTotalItens := LTotalItens + LItem.valorTotal;

    LDesconto := LDesconto + LItem.desconto;
    LQuantidadeItens := LQuantidadeItens + 1 + LItem.fracoes.Count;
  end;

  AddBlankLine;
  AddDash;
  AddText('Sub total: ' + Format('R$ %.2f', [LTotalItens + LDesconto]), 'left', 'medium', 'bold');

  if LDesconto > 0 then
    AddText('Desc itens: -' + Format('R$ %.2f', [LDesconto]), 'left', 'medium');

  if FEmpresa.casaNoturna then
  begin
    AddText('Taxa Entrada: ' + Format('R$ %.2f', [FVenda.valorEntrada]), 'left', 'medium');
    AddText('Taxa Cart'#227'o: ' + Format('R$ %.2f', [FVenda.taxaCartao]), 'left', 'medium');
    AddText('Taxa Servi'#231'o: ' + Format('R$ %.2f', [FVenda.valorTaxaServico]), 'left', 'medium');
    AddSeparator;
    AddText('TOTAL ' + Format('R$ %.2f', [FVenda.valorTotal]), 'center', 'big', 'bold');
    AddSeparator;
    AddText('Qtde itens: ' + LQuantidadeItens.ToString, 'left', 'medium');
    AddDash;
  end
  else
  begin
    if FVenda.valorTaxaServico > 0 then
      AddText('Taxa Servi'#231'o: ' + Format('R$ %.2f', [FVenda.valorTaxaServico]), 'left', 'medium');

    if FVenda.ValorCouvert > 0 then
      AddText(FMensagemCouvert + ': ' + Format('R$ %.2f', [FVenda.ValorCouvert]), 'left', 'medium');

    AddSeparator;
    AddText('TOTAL ' + Format('R$ %.2f', [FVenda.valorTotal]), 'center', 'big', 'bold');
    AddSeparator;
    AddText('Qtde itens: ' + LQuantidadeItens.ToString, 'left', 'medium');
    AddText('Qtde pessoas: ' + FVenda.numeroPessoas.ToString, 'left', 'medium');
    AddText('Total/pessoa: ' + Format('R$ %.2f', [FVenda.ValorPorPessoa]), 'left', 'medium');
    AddDash;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarVenda;
var
  LServiceConsulta: TAPIRPCheffServiceVendaConsulta;
begin
  FreeAndNil(FVenda);
  LServiceConsulta := TAPIRPCheffServiceVendaConsulta.Create;
  try
    LServiceConsulta.DAO(FDAO);
    FVenda := LServiceConsulta.Buscar(FIdVenda, False);
    if not Assigned(FVenda) then
      raise Exception.CreateFmt('Venda %d n'#227'o encontrada.', [FIdVenda]);

    FValorPendente := FVenda.valorTotal;
    AddBlankLine;
    AddText(GetCabecalhoVendaCupom, 'center', 'medium', 'bold');
    AddText(GetTituloConferencia, 'center', GetTamanhoTituloConferencia, 'bold');
    AddDash;
    AddText('Abertura:   ' + FormatDateTime('dd/mm/yyyy hh:nn', FVenda.dataAbertura), 'left', 'medium', 'bold');
    AddText('Fechamento: ' + FormatDateTime('dd/mm/yyyy hh:nn', FData), 'left', 'medium', 'bold');
    AddDash;
    AddText('ITENS', 'center', 'medium', 'bold');
    AddDash;
  finally
    FreeAndNil(LServiceConsulta);
  end;
end;

destructor TAPIRPCheffServiceVendaImpressaoSTONE.Destroy;
begin
  FreeAndNil(FVenda);
  FreeAndNil(FEmpresa);
  FreeAndNil(FVendaItens);
  inherited;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.CarregarOperadorPreFechamento;
var
  LOperadorFechamento: TAPIRPCheffEntityUsuario;
begin
  LOperadorFechamento := FDAO.UsuarioDAO.Busca(FVenda.idUsuarioPreFechamento);
  try
    if Assigned(LOperadorFechamento) then
    begin
      AddBlankLine;
      AddDash;
      AddText('Solicitado por: ' + LOperadorFechamento.nome, 'center', 'medium', 'bold');
    end;
  finally
    FreeAndNil(LOperadorFechamento);
  end;
end;

function TAPIRPCheffServiceVendaImpressaoSTONE.Execute: TStream;
begin
  FData := Now;
  FJsonArray := TJSONArray.Create;
  try
    CarregarEmpresa;
    CarregarVenda;
    CarregarItens;
    CarregarTotal;
    CarregarPagamentosAntecipados;
    CarregarPagamentos;
    CarregarGarcons;
    CarregarOperadorPreFechamento;
    CarregarRodape;
    ImprimirFichaIndividualVerificada;
    Result := TStringStream.Create(FJsonArray.ToString, TEncoding.UTF8);
  finally
    FJsonArray.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressaoSTONE.ImprimirFichaIndividualVerificada;
var
  LItem: TAPIRPCheffEntityVendaItem;
  LImpressoras: TObjectList<TAPIRPCheffEntityImpressaoProducao>;
begin
  for LItem in FVendaItens do
  begin
    if not LItem.ImprimirFichaIndividual then
      Continue;

    if not Assigned(FEmpresa) then
    begin
      FDAO.EmpresaDAO.IdEmpresa(FIdEmpresa);
      FEmpresa := FDAO.EmpresaDAO.Busca;
      if not Assigned(FEmpresa) then
        raise Exception.CreateFmt('Empresa %d n'#227'o encontrada.', [FIdEmpresa]);
    end;

    LImpressoras := FDAO.ImpressaoProducaoDAO.Listar(LItem.idProduto, LItem.idVenda);
    try
      for var LImpressora in LImpressoras do
      begin
        AddSeparator;
        AddBlankLine;
        AddText(FEmpresa.nome, 'center', 'big', 'bold');
        AddBlankLine;
        AddText(FEmpresa.endereco + ', ' + FEmpresa.numero, 'center', 'medium');

        if FEmpresa.telefonePrincipal = 0 then
          AddText('Fone: ' + FEmpresa.telefone, 'center', 'medium')
        else
          AddText('Fone: ' + FEmpresa.celular, 'center', 'medium');

        AddBlankLine;
        AddSeparator;
        AddText('Venda: ' + LItem.idVenda.ToString, 'left', 'medium', 'bold');
        AddText('Data: ' + FormatDateTime('dd/mm/yyyy hh:nn', LItem.dataLancamento), 'left', 'medium');
        AddText('Impressora: ' + LImpressora.TipoVenda, 'left', 'medium');
        AddSeparator;
        AddBlankLine;
        AddText('P A G O', 'center', 'big', 'bold');
        AddBlankLine;

        var LDescricao := LItem.produtoDescricao;
        if LItem.descricaoTamanho <> EmptyStr then
          LDescricao := LDescricao + ' (' + LItem.descricaoTamanho + ')';
        AddText(LDescricao, 'center', 'medium', 'bold');
        AddBlankLine;
        AddSeparator;
      end;
    finally
      FreeAndNil(LImpressoras);
    end;
  end;
end;

end.
