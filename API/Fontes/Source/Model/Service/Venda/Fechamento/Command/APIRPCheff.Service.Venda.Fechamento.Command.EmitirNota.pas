unit APIRPCheff.Service.Venda.Fechamento.Command.EmitirNota;

interface

uses
  System.Generics.Collections,
  System.Math,
  System.SysUtils,
  RPNFe.Entity.Classes,
  RPNFe.Components.Impressora.DanfeEscPos,
  APIRPCheff.Resources,
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory;

type
  TAPIRPCheffServiceVendaFechamentoCommandEmitirNota =
    class(TAPIRPCheffServiceVendaFechamentoCommand)
  private
    function DeveEmitirNota(const AFechamento: TAPIRPCheffEntityVendaPostFechamento): Boolean;
    function DeveImprimirNaImpressoraWindows(const AFechamento: TAPIRPCheffEntityVendaPostFechamento): Boolean;
    procedure Imprimir(const ANota: TRPNFeEntityNFeNotaEletronica);
  public
    // Publica (class function) para a reemissao usar a MESMA traducao de
    // erros da emissao do fechamento.
    class function TraduzirErroEmissao(const AMensagem: string): string;
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandEmitirNota }

function TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.DeveEmitirNota(const AFechamento: TAPIRPCheffEntityVendaPostFechamento): Boolean;
var
  LPagamentos: TObjectList<TAPIRPCheffEntityFormaPagamento>;
begin
  // Escolha do operador no app tem prioridade: 2 = Fiscal, 1 = Nao Fiscal.
  if AFechamento.opcaoFiscal = 2 then
    Exit(True);
  if AFechamento.opcaoFiscal = 1 then
    Exit(False);

  // Sem escolha (0): mantem o comportamento antigo (forma de pagamento fiscal).
  Result := False;
  LPagamentos := FParent.DAO.FormaPagamentoDAO.ListarPagamentosDaVenda(AFechamento.idVenda);
  try
    for var LPagamento in LPagamentos do
    begin
      if LPagamento.emiteFiscal then
        Exit(True);
    end;
  finally
    LPagamentos.Free;
  end;
end;

function TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.DeveImprimirNaImpressoraWindows(
  const AFechamento: TAPIRPCheffEntityVendaPostFechamento): Boolean;
begin
  Result := not (AFechamento.tipoMaquina in [tmpStone, tmpPlugPag, tmpCielo]);
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LNotaEletronica: TRPNFeEntityNFeNotaEletronica;
begin
  inherited;
  if not DeveEmitirNota(AFechamento) then
    Exit;

  // A emissao NAO pode derrubar o fechamento: se a SEFAZ rejeitar ou faltar
  // certificado/rede, a venda fecha mesmo assim e retorna aviso para o app.
  // O botao "Emitir depois" grava a NFC-e em contingencia para envio posterior.
  try
    FParent.Components.RPNFe.Service.EmissaoService
      .Configuracao(APP_RESOURCES.NFE_XML_CONFIGURACAO)
      .PathSchemas(APP_RESOURCES.NFE_SCHEMAS_PATH)
      .IdCSC(APP_RESOURCES.NFCE_IDCSC)
      .CSC(APP_RESOURCES.NFCE_CSC)
      .Ambiente(APP_RESOURCES.NFCE_AMBIENTE)
      .Serie(APP_RESOURCES.NFCE_SERIE)
      .Numero(APP_RESOURCES.NFCE_NUMERO)
      .CertTipo(APP_RESOURCES.NFCE_CERT_TIPO)
      .CertArquivo(APP_RESOURCES.NFCE_CERT_ARQUIVO)
      .CertSenha(APP_RESOURCES.NFCE_CERT_SENHA)
      .CertSerie(APP_RESOURCES.NFCE_CERT_SERIE)
      .Contingencia(False)
      .IdVenda(FParent.Venda.idVenda);

    LNotaEletronica := FParent.Components.RPNFe.Service.EmissaoService.Execute;
    try
      try
        if DeveImprimirNaImpressoraWindows(AFechamento) then
          Imprimir(LNotaEletronica);
      except
      end;
    finally
      LNotaEletronica.Free;
    end;
  except
    on E: Exception do
    begin
      FParent.NotaFiscalAviso := TraduzirErroEmissao(E.Message);
    end;
  end;
end;

// Converte o erro tecnico da emissao (ACBr/SEFAZ) em uma orientacao clara
// para o operador, mantendo o detalhe original no final para o suporte.
class function TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.TraduzirErroEmissao(const AMensagem: string): string;
var
  LMensagem: string;
  LOrientacao: string;
begin
  LMensagem := UpperCase(AMensagem);
  LOrientacao := '';

  if (Pos('IBS/CBS NAO INFORMADO', LMensagem) > 0) or
     (Pos('IBS/CBS N', LMensagem) > 0) and (Pos('INFORMADO', LMensagem) > 0) then
    LOrientacao := 'Imposto IBS/CBS (Reforma Tributaria) nao configurado no produto. ' +
      'Abra o cadastro do produto na retaguarda e informe o CST e a Classificacao Tributaria da NFC-e.'
  else if Pos('CST E CCLASSTRIB', LMensagem) > 0 then
    LOrientacao := 'Produto sem imposto configurado. ' +
      'Abra o cadastro do produto na retaguarda e informe o CST e a Classificacao Tributaria da NFC-e.'
  else if Pos('CST/CSOSN DO PRODUTO', LMensagem) > 0 then
    LOrientacao := 'Produto sem CST/CSOSN de ICMS valido. ' +
      'Corrija a tributacao de ICMS no cadastro do produto.'
  else if (Pos('CLASSIFICACAO', LMensagem) > 0) and (Pos('NAO CADASTRADA', LMensagem) > 0) then
    LOrientacao := 'Classificacao tributaria do produto nao existe na tabela da Reforma Tributaria. ' +
      'Confira o codigo cClassTrib no cadastro do produto.'
  else if Pos('ORIGEM DO PRODUTO', LMensagem) > 0 then
    LOrientacao := 'Produto sem origem da mercadoria configurada. ' +
      'Informe a origem (nacional/importado) no cadastro do produto.'
  else if Pos('DUPLICIDADE', LMensagem) > 0 then
    LOrientacao := 'A numeracao desta NFC-e ja foi usada na SEFAZ. ' +
      'Ajuste o proximo numero da NFC-e na configuracao fiscal e tente de novo.'
  else if (Pos('CERTIFICADO', LMensagem) > 0) or (Pos('PFX', LMensagem) > 0) then
    LOrientacao := 'Problema com o certificado digital (arquivo, senha ou validade). ' +
      'Confira a configuracao do certificado.'
  else if (Pos('CSC', LMensagem) > 0) or (Pos('TOKEN', LMensagem) > 0) then
    LOrientacao := 'CSC/Token da NFC-e invalido ou nao configurado. ' +
      'Confira o Id do CSC e o codigo CSC na configuracao fiscal.'
  else if (Pos('TIMEOUT', LMensagem) > 0) or (Pos('TIME-OUT', LMensagem) > 0) or
    (Pos('TIMED OUT', LMensagem) > 0) or (Pos('CONEX', LMensagem) > 0) or
    (Pos('SOCKET', LMensagem) > 0) or (Pos('HOST', LMensagem) > 0) or
    (Pos('WINHTTP', LMensagem) > 0) or (Pos('SSL', LMensagem) > 0) then
    LOrientacao := 'Sem comunicacao com a SEFAZ (internet ou servico fora do ar). ' +
      'A venda foi fechada e fica com pendencia fiscal - reemita a nota quando a conexao voltar.'
  else if Pos('SCHEMA', LMensagem) > 0 then
    LOrientacao := 'O XML da nota foi recusado na validacao (schema). ' +
      'Confira os dados fiscais dos produtos vendidos.'
  else if (Pos('TOTAL DA BC', LMensagem) > 0) or (Pos('TOTAL DO ICMS', LMensagem) > 0) or
    (Pos('SOMATORIO', LMensagem) > 0) then
    LOrientacao := 'Divergencia nos totais de impostos da nota. ' +
      'Confira a tributacao (ICMS/PIS/COFINS) dos produtos vendidos.'
  else if Pos('NCM', LMensagem) > 0 then
    LOrientacao := 'NCM de produto invalido ou inexistente. ' +
      'Corrija o NCM no cadastro do produto.'
  else if Pos('CFOP', LMensagem) > 0 then
    LOrientacao := 'CFOP de produto invalido para NFC-e. ' +
      'Corrija o CFOP de consumidor no cadastro do produto.';

  if LOrientacao <> '' then
    Result := 'NFC-e nao emitida: ' + LOrientacao + ' [Detalhe: ' + AMensagem + ']'
  else
    Result := 'NFC-e nao emitida no fechamento: ' + AMensagem;
end;

procedure TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.Imprimir(const ANota: TRPNFeEntityNFeNotaEletronica);
begin
  try
    FParent.Components.RPNFe.Components.ImpressoraDanfeEscPos
      .Modelo(TACBrPosPrinterModelo(APP_RESOURCES.IMPRESSORA_MODELO))
      .PaginaDeCodigo(TACBrPosPaginaCodigo(APP_RESOURCES.IMPRESSORA_PAGINA_CODE))
      .Porta(APP_RESOURCES.IMPRESSORA_PORTA)
      .Colunas(APP_RESOURCES.IMPRESSORA_COLUNAS)
      .Espacos(APP_RESOURCES.IMPRESSORA_ESPACOS)
      .LinhasEntreCupons(APP_RESOURCES.IMPRESSORA_LINHAS_PULO);

    FParent.Components.RPNFe.Service.ImpressaoService
      .TipoDanfe(tdPosPrinter)
      .IdVenda(FParent.Venda.idVenda)
      .Xml(ANota.Xml)
      .Execute;
  except
    on E: Exception do
      raise EImpressaoException.Create(E.Message);
  end;
end;

end.
