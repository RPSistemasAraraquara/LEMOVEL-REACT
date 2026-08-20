unit APIRPCheff.Service.Venda.ReemitirNota;

interface

uses
  System.SysUtils,
  RPNFe.Entity.Classes,
  RPNFe.Components.Impressora.DanfeEscPos,
  APIRPCheff.Resources,
  APIRPCheff.Components,
  APIRPCheff.Entity.Types,
  APIRPCheff.Entity.Classes,
  APIRPCheff.DAO.Factory;

type
  // Reemissao de NFC-e para venda FECHADA que ficou sem nota (rejeicao da
  // SEFAZ, queda de rede, etc.). Acao explicita do operador: emite com a
  // proxima numeracao (alocacao atomica) usando a MESMA configuracao fiscal
  // do fechamento. Falha vira excecao com a mensagem ja traduzida.
  TAPIRPCheffServiceVendaReemitirNota = class
  private
    FDAO         : TAPIRPCheffDAOFactory;
    FComponents  : TAPIRPCheffComponents;
    FIdVenda     : Integer;
    FCpfCnpjNota : string;
    FTipoMaquina : TRPTipoMaquinaPagamento;
    FChave       : string;
    FNumero      : Integer;

    procedure ValidarVenda;
    procedure AtualizarCpfNota;
    procedure Imprimir(const ANota: TRPNFeEntityNFeNotaEletronica);
    function DeveImprimirNaImpressoraWindows: Boolean;
    function SoDigitosValidos(const AValor: string): string;
  public
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaReemitirNota;
    function Components(AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaReemitirNota;
    function IdVenda(AValue: Integer): TAPIRPCheffServiceVendaReemitirNota;
    function TipoMaquina(AValue: TRPTipoMaquinaPagamento): TAPIRPCheffServiceVendaReemitirNota;
    function CpfCnpjNota(const AValue: string): TAPIRPCheffServiceVendaReemitirNota;

    procedure Execute;

    property Chave: string read FChave;
    property Numero: Integer read FNumero;
  end;

  TAPIRPCheffServiceVendaEmitirNotaContingencia = class
  private
    FDAO         : TAPIRPCheffDAOFactory;
    FComponents  : TAPIRPCheffComponents;
    FIdVenda     : Integer;
    FIdUsuario   : Integer;
    FCpfCnpjNota : string;
    FMensagemErroOriginal: string;
    FChave       : string;
    FNumero      : Integer;

    procedure ValidarVenda;
    procedure AtualizarCpfNota;
    procedure RegistrarErroOriginal(const ANota: TRPNFeEntityNFeNotaEletronica);
    function TipoErroFiscal(const AErro: string): string;
    function SoDigitosValidos(const AValor: string): string;
  public
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaEmitirNotaContingencia;
    function Components(AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaEmitirNotaContingencia;
    function IdVenda(AValue: Integer): TAPIRPCheffServiceVendaEmitirNotaContingencia;
    function IdUsuario(AValue: Integer): TAPIRPCheffServiceVendaEmitirNotaContingencia;
    function CpfCnpjNota(const AValue: string): TAPIRPCheffServiceVendaEmitirNotaContingencia;
    function MensagemErroOriginal(const AValue: string): TAPIRPCheffServiceVendaEmitirNotaContingencia;

    procedure Execute;

    property Chave: string read FChave;
    property Numero: Integer read FNumero;
  end;

implementation

uses
  APIRPCheff.Service.Venda.Fechamento.Command.EmitirNota;

{ TAPIRPCheffServiceVendaReemitirNota }

function TAPIRPCheffServiceVendaReemitirNota.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaReemitirNota;
begin
  Result := Self;
  FDAO := AValue;
end;

function TAPIRPCheffServiceVendaReemitirNota.Components(AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaReemitirNota;
begin
  Result := Self;
  FComponents := AValue;
end;

function TAPIRPCheffServiceVendaReemitirNota.IdVenda(AValue: Integer): TAPIRPCheffServiceVendaReemitirNota;
begin
  Result := Self;
  FIdVenda := AValue;
end;

function TAPIRPCheffServiceVendaReemitirNota.TipoMaquina(
  AValue: TRPTipoMaquinaPagamento): TAPIRPCheffServiceVendaReemitirNota;
begin
  Result := Self;
  FTipoMaquina := AValue;
end;

function TAPIRPCheffServiceVendaReemitirNota.CpfCnpjNota(const AValue: string): TAPIRPCheffServiceVendaReemitirNota;
begin
  Result := Self;
  FCpfCnpjNota := AValue;
end;

function TAPIRPCheffServiceVendaReemitirNota.SoDigitosValidos(const AValor: string): string;
var
  C: Char;
begin
  Result := '';
  for C in AValor do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;

  if (Length(Result) <> 11) and (Length(Result) <> 14) then
    Result := '';
end;

procedure TAPIRPCheffServiceVendaReemitirNota.ValidarVenda;
var
  LEncerraVenda: TAPIRPCheffEntityEncerraVenda;
  LVenda: TAPIRPCheffEntityVenda;
begin
  LEncerraVenda := FDAO.EncerraVendaDAO.Buscar(FIdVenda);
  try
    if not Assigned(LEncerraVenda) then
      raise Exception.CreateFmt(
        'A venda %d não está fechada. Feche a venda antes de reemitir a NFC-e.', [FIdVenda]);
  finally
    FreeAndNil(LEncerraVenda);
  end;

  LVenda := FDAO.VendaDAO.Buscar(FIdVenda);
  try
    if not Assigned(LVenda) then
      raise Exception.CreateFmt('Venda %d não encontrada.', [FIdVenda]);

    // Chave preenchida significa NFC-e ja registrada para a venda (autorizada
    // ou contingencia offline); reemitir duplicaria a operacao fiscal.
    if LVenda.chaveEletronica <> '' then
      raise Exception.CreateFmt(
        'A NFC-e desta venda já foi emitida/registrada (chave %s). Use a reimpressão ou o envio de contingência.',
        [LVenda.chaveEletronica]);
  finally
    FreeAndNil(LVenda);
  end;
end;

procedure TAPIRPCheffServiceVendaReemitirNota.AtualizarCpfNota;
var
  LEncerraVenda: TAPIRPCheffEntityEncerraVenda;
  LCpfCnpj: string;
begin
  LCpfCnpj := SoDigitosValidos(FCpfCnpjNota);
  if LCpfCnpj = '' then
    Exit;

  LEncerraVenda := FDAO.EncerraVendaDAO.Buscar(FIdVenda);
  try
    if Assigned(LEncerraVenda) then
      FDAO.EncerraVendaDAO.AtualizarCpfConsumidor(LEncerraVenda.idEncerraVenda, LCpfCnpj);
  finally
    FreeAndNil(LEncerraVenda);
  end;
end;

procedure TAPIRPCheffServiceVendaReemitirNota.Imprimir(const ANota: TRPNFeEntityNFeNotaEletronica);
begin
  // Mesma impressao do fechamento (impressora ESC/POS do servidor, quando
  // configurada). Falha de impressao NAO derruba a reemissao - a nota ja
  // esta autorizada; o app tambem imprime o DANFCe na maquininha.
  try
    FComponents.RPNFe.Components.ImpressoraDanfeEscPos
      .Modelo(TACBrPosPrinterModelo(APP_RESOURCES.IMPRESSORA_MODELO))
      .PaginaDeCodigo(TACBrPosPaginaCodigo(APP_RESOURCES.IMPRESSORA_PAGINA_CODE))
      .Porta(APP_RESOURCES.IMPRESSORA_PORTA)
      .Colunas(APP_RESOURCES.IMPRESSORA_COLUNAS)
      .Espacos(APP_RESOURCES.IMPRESSORA_ESPACOS)
      .LinhasEntreCupons(APP_RESOURCES.IMPRESSORA_LINHAS_PULO);

    FComponents.RPNFe.Service.ImpressaoService
      .TipoDanfe(tdPosPrinter)
      .IdVenda(FIdVenda)
      .Xml(ANota.Xml)
      .Execute;
  except
    // inocuo: reemissao concluida; impressao pode ser refeita pelo app
  end;
end;

function TAPIRPCheffServiceVendaReemitirNota.DeveImprimirNaImpressoraWindows: Boolean;
begin
  Result := not (FTipoMaquina in [tmpStone, tmpPlugPag, tmpCielo]);
end;

procedure TAPIRPCheffServiceVendaReemitirNota.Execute;
var
  LNotaEletronica: TRPNFeEntityNFeNotaEletronica;
begin
  ValidarVenda;
  AtualizarCpfNota;

  try
    FComponents.RPNFe.Service.EmissaoService
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
      .IdVenda(FIdVenda);

    LNotaEletronica := FComponents.RPNFe.Service.EmissaoService.Execute;
    try
      FChave := LNotaEletronica.ChaveNFe;
      FNumero := LNotaEletronica.NumeroNFe;
      if DeveImprimirNaImpressoraWindows then
        Imprimir(LNotaEletronica);
    finally
      LNotaEletronica.Free;
    end;
  except
    on E: Exception do
      raise Exception.Create(
        TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.TraduzirErroEmissao(E.Message));
  end;
end;

{ TAPIRPCheffServiceVendaEmitirNotaContingencia }

function TAPIRPCheffServiceVendaEmitirNotaContingencia.DAO(
  AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaEmitirNotaContingencia;
begin
  Result := Self;
  FDAO := AValue;
end;

function TAPIRPCheffServiceVendaEmitirNotaContingencia.Components(
  AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaEmitirNotaContingencia;
begin
  Result := Self;
  FComponents := AValue;
end;

function TAPIRPCheffServiceVendaEmitirNotaContingencia.IdVenda(
  AValue: Integer): TAPIRPCheffServiceVendaEmitirNotaContingencia;
begin
  Result := Self;
  FIdVenda := AValue;
end;

function TAPIRPCheffServiceVendaEmitirNotaContingencia.CpfCnpjNota(
  const AValue: string): TAPIRPCheffServiceVendaEmitirNotaContingencia;
begin
  Result := Self;
  FCpfCnpjNota := AValue;
end;

function TAPIRPCheffServiceVendaEmitirNotaContingencia.IdUsuario(
  AValue: Integer): TAPIRPCheffServiceVendaEmitirNotaContingencia;
begin
  Result := Self;
  FIdUsuario := AValue;
end;

function TAPIRPCheffServiceVendaEmitirNotaContingencia.MensagemErroOriginal(
  const AValue: string): TAPIRPCheffServiceVendaEmitirNotaContingencia;
begin
  Result := Self;
  FMensagemErroOriginal := AValue;
end;

function TAPIRPCheffServiceVendaEmitirNotaContingencia.SoDigitosValidos(
  const AValor: string): string;
var
  C: Char;
begin
  Result := '';
  for C in AValor do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;

  if (Length(Result) <> 11) and (Length(Result) <> 14) then
    Result := '';
end;

function TAPIRPCheffServiceVendaEmitirNotaContingencia.TipoErroFiscal(
  const AErro: string): string;
var
  LErro: string;
begin
  Result := '';
  LErro := UpperCase(AErro);

  if Pos('NCM', LErro) > 0 then
    Result := 'NCM'
  else if Pos('CFOP', LErro) > 0 then
    Result := 'CFOP'
  else if (Pos('GTIN', LErro) > 0) or (Pos('CEAN', LErro) > 0) then
    Result := 'GTIN'
  else if (Pos('CST', LErro) > 0) or (Pos('CSOSN', LErro) > 0) then
    Result := 'CST_CSOSN';
end;

procedure TAPIRPCheffServiceVendaEmitirNotaContingencia.RegistrarErroOriginal(
  const ANota: TRPNFeEntityNFeNotaEletronica);
var
  LTipoErro: string;
  LIdUsuario: Integer;
begin
  LTipoErro := TipoErroFiscal(FMensagemErroOriginal);
  if LTipoErro = '' then
    Exit;

  LIdUsuario := FIdUsuario;
  if LIdUsuario <= 0 then
    LIdUsuario := 1;

  FDAO.VendaDAO.RegistrarErroNFCeContingencia(FIdVenda, ANota.NumeroNFe,
    ANota.Serie, LIdUsuario, LTipoErro, FMensagemErroOriginal);
end;

procedure TAPIRPCheffServiceVendaEmitirNotaContingencia.ValidarVenda;
var
  LEncerraVenda: TAPIRPCheffEntityEncerraVenda;
  LVenda: TAPIRPCheffEntityVenda;
begin
  LEncerraVenda := FDAO.EncerraVendaDAO.Buscar(FIdVenda);
  try
    if not Assigned(LEncerraVenda) then
      raise Exception.CreateFmt(
        'A venda %d não está fechada. Feche a venda antes de emitir a NFC-e em contingência.',
        [FIdVenda]);
  finally
    FreeAndNil(LEncerraVenda);
  end;

  LVenda := FDAO.VendaDAO.Buscar(FIdVenda);
  try
    if not Assigned(LVenda) then
      raise Exception.CreateFmt('Venda %d não encontrada.', [FIdVenda]);

    if LVenda.chaveEletronica <> '' then
      raise Exception.CreateFmt(
        'A NFC-e desta venda já foi emitida/registrada (chave %s).',
        [LVenda.chaveEletronica]);
  finally
    FreeAndNil(LVenda);
  end;
end;

procedure TAPIRPCheffServiceVendaEmitirNotaContingencia.AtualizarCpfNota;
var
  LEncerraVenda: TAPIRPCheffEntityEncerraVenda;
  LCpfCnpj: string;
begin
  LCpfCnpj := SoDigitosValidos(FCpfCnpjNota);
  if LCpfCnpj = '' then
    Exit;

  LEncerraVenda := FDAO.EncerraVendaDAO.Buscar(FIdVenda);
  try
    if Assigned(LEncerraVenda) then
      FDAO.EncerraVendaDAO.AtualizarCpfConsumidor(LEncerraVenda.idEncerraVenda, LCpfCnpj);
  finally
    FreeAndNil(LEncerraVenda);
  end;
end;

procedure TAPIRPCheffServiceVendaEmitirNotaContingencia.Execute;
var
  LNotaEletronica: TRPNFeEntityNFeNotaEletronica;
begin
  ValidarVenda;
  AtualizarCpfNota;

  try
    FComponents.RPNFe.Service.EmissaoService
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
      .Contingencia(True)
      .IdVenda(FIdVenda);

    LNotaEletronica := FComponents.RPNFe.Service.EmissaoService.Execute;
    try
      FChave := LNotaEletronica.ChaveNFe;
      FNumero := LNotaEletronica.NumeroNFe;
      RegistrarErroOriginal(LNotaEletronica);
    finally
      LNotaEletronica.Free;
    end;
  except
    on E: Exception do
      raise Exception.Create(
        TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.TraduzirErroEmissao(E.Message));
  end;
end;

end.
