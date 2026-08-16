unit RPNFe.Components.Emissor.ACBr;

interface

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  System.SyncObjs,
  ACBrNFe,
  ACBrDFeSSL,
  ACBrDFeException,
  ACBrNFeNotasFiscais,
  ACBrNFe.Classes,
  pcnConversao,
  pcnConversaoNFe,
  blcksock,
  ACBrDFe,
  RPNFe.Entity.Classes;

type
  NotaFiscal = ACBrNFeNotasFiscais.NotaFiscal;
  TACBrNFe = ACBrNFe.TACBrNFe;
  TNFe = ACBrNFe.Classes.TNFe;
  TpcnModeloDF = pcnConversaoNFe.TpcnModeloDF;
  TpcnTipoNFe = pcnConversao.TpcnTipoNFe;
  TpcnDestinoOperacao = pcnConversaoNFe.TpcnDestinoOperacao;
  TpcnindIEDest = pcnConversao.TpcnindIEDest;
  TpcnTpEvento = pcnConversao.TpcnTpEvento;
  EACBrNFeException = ACBrNFe.EACBrNFeException;
  EACBrDFeException = ACBrDFeException.EACBrDFeException;

  TRPNFeComponentsEmissorACBr = class
  private
    FACBr: TACBrNFe;

    procedure CriarComponenteACBr;
    procedure ConfiguracaoGeral;
    procedure ConfiguracaoArquivosEDiretorios;
    procedure ConfiguracaoWebServices;
    procedure ConfigurarCertificado(AConfig: TRPNFeEntityConfiguracao);
  public
    constructor Create;
    destructor Destroy; override;

    function FormatXmlContent(AXmlContent: string): string;

    function Configuracao(AConfig: TRPNFeEntityConfiguracao): TRPNFeComponentsEmissorACBr;
    function Empresa(AValue: TRPNFeEntityEmpresa): TRPNFeComponentsEmissorACBr;

    function ACBr: TACBrNFe;
  end;

// O TACBrNFe e o FastReport do emissor sao UM UNICO componente compartilhado
// por todas as threads da API. Emissao e impressao simultaneas colidem
// (EAbort do FastReport / travamentos). Todo uso do emissor deve ser
// serializado por este lock (reentrante na mesma thread).
function EmissorLock: TCriticalSection;

implementation

var
  GEmissorLock: TCriticalSection;

function EmissorLock: TCriticalSection;
begin
  Result := GEmissorLock;
end;

{ TRPNFeComponentsEmissorACBr }

function TRPNFeComponentsEmissorACBr.ACBr: TACBrNFe;
begin
  if not Assigned(FACBr) then
    CriarComponenteACBr;
  Result := FACBr;
end;

procedure TRPNFeComponentsEmissorACBr.ConfiguracaoArquivosEDiretorios;
begin
  FACBr.Configuracoes.Arquivos.SepararPorCNPJ := False;
  FACBr.Configuracoes.Arquivos.SepararPorModelo := False;
  FACBr.Configuracoes.Arquivos.SepararPorIE := False;
  FACBr.Configuracoes.Arquivos.SepararPorAno := False;
  FACBr.Configuracoes.Arquivos.SepararPorMes := False;
  FACBr.Configuracoes.Arquivos.SepararPorDia := False;
  FACBr.Configuracoes.Arquivos.Salvar := False;
  FACBr.Configuracoes.Arquivos.SalvarEvento := False;
end;

procedure TRPNFeComponentsEmissorACBr.ConfiguracaoGeral;
begin
  FACBr.Configuracoes.Geral.Salvar := False;
  FACBr.Configuracoes.Geral.ExibirErroSchema := True;
  FACBr.Configuracoes.Geral.RetirarAcentos := True;
  FACBr.Configuracoes.Geral.FormaEmissao := TpcnTipoEmissao.teNormal;
  FACBr.Configuracoes.Geral.VersaoDF := TpcnVersaoDF.ve400;
  FACBr.Configuracoes.Geral.ModeloDF := TPcnModeloDF.moNFCe;

  FACBr.Configuracoes.Geral.SSLLib := TSSLLib.libOpenSSL;
  FACBr.Configuracoes.Geral.SSLCryptLib := TSSLCryptLib.cryOpenSSL;
  FACBr.Configuracoes.Geral.SSLHttpLib := TSSLHttpLib.httpOpenSSL;
  FACBr.Configuracoes.Geral.SSLXmlSignLib := TSSLXmlSignLib.xsLibXml2;

  FACBr.SSL.SSLType := LT_all;
end;

procedure TRPNFeComponentsEmissorACBr.ConfiguracaoWebServices;
begin
  FACBr.Configuracoes.WebServices.Visualizar := False;
  FACBr.Configuracoes.WebServices.Salvar := False;
  FACBr.Configuracoes.WebServices.AjustaAguardaConsultaRet := False;

  FACBr.Configuracoes.WebServices.Ambiente := TpcnTipoAmbiente.taHomologacao;
end;

procedure TRPNFeComponentsEmissorACBr.ConfigurarCertificado(AConfig: TRPNFeEntityConfiguracao);
begin
  // CSC/IdCSC valem para A1 e A3: sem eles a NFC-e sai sem QR Code valido.
  ACBr.Configuracoes.Geral.IdCSC := AConfig.CertificadoDigital.IdToken;
  ACBr.Configuracoes.Geral.CSC := AConfig.CertificadoDigital.CscToken;

  if AConfig.CertificadoDigital.Tipo = 3 then
  begin
    // A3: certificado em token/cartao pelo repositorio do Windows (WinCrypt).
    // ConfiguracaoGeral inicializa SSL como OpenSSL; para A3 e preciso sobrescrever.
    if Trim(AConfig.CertificadoDigital.NumeroSerie) = EmptyStr then
      raise EACBrDFeException.Create(
        'Certificado digital A3 sem numero de serie informado.');

    ACBr.Configuracoes.Geral.SSLLib := TSSLLib.libWinCrypt;
    ACBr.Configuracoes.Geral.SSLCryptLib := TSSLCryptLib.cryWinCrypt;
    ACBr.Configuracoes.Geral.SSLHttpLib := TSSLHttpLib.httpWinHttp;

    ACBr.Configuracoes.Certificados.ArquivoPFX := EmptyStr;
    ACBr.Configuracoes.Certificados.DadosPFX := EmptyStr;
    ACBr.Configuracoes.Certificados.Senha := AConfig.CertificadoDigital.Senha;
    ACBr.Configuracoes.Certificados.NumeroSerie := AConfig.CertificadoDigital.NumeroSerie;
  end
  else
  begin
    // A1: certificado em arquivo .pfx assinado via OpenSSL (comportamento atual).
    // Sem ele o ACBr nao assina nem carrega o CSC. Falha explicita em vez de silenciosa.
    if not FileExists(AConfig.CertificadoDigital.ArquivoPfx) then
      raise EACBrDFeException.CreateFmt(
        'Certificado digital A1 nao encontrado: %s',
        [AConfig.CertificadoDigital.ArquivoPfx]);

    ACBr.Configuracoes.Geral.SSLLib := TSSLLib.libOpenSSL;
    ACBr.Configuracoes.Geral.SSLCryptLib := TSSLCryptLib.cryOpenSSL;
    ACBr.Configuracoes.Geral.SSLHttpLib := TSSLHttpLib.httpOpenSSL;

    ACBr.Configuracoes.Certificados.NumeroSerie := EmptyStr;
    ACBr.Configuracoes.Certificados.ArquivoPFX := AConfig.CertificadoDigital.ArquivoPfx;
    ACBr.Configuracoes.Certificados.DadosPFX := EmptyStr;
    ACBr.Configuracoes.Certificados.Senha := AConfig.CertificadoDigital.Senha;
  end;

  ACBr.SSL.DescarregarCertificado;
  if (StartOfTheDay(ACBr.SSL.CertDataVenc) < StartOfTheDay(Now)) then
    raise EACBrDFeException.CreateFmt('Certificado vencido em %s', [ACBr.SSL.CertDataVenc.Format('dd/MM/yyyy')]);
end;

function TRPNFeComponentsEmissorACBr.Configuracao(AConfig: TRPNFeEntityConfiguracao): TRPNFeComponentsEmissorACBr;
begin
  Result := Self;
  FACBr.Configuracoes.WebServices.Ambiente := TpcnTipoAmbiente.taHomologacao;
  if AConfig.Producao then
    FACBr.Configuracoes.WebServices.Ambiente := TpcnTipoAmbiente.taProducao;

  FACBr.Configuracoes.WebServices.TimeOut := AConfig.Timeout * 1000;
  FACBr.Configuracoes.WebServices.Tentativas := AConfig.NumeroTentativasEmissao;
  FACBr.Configuracoes.WebServices.IntervaloTentativas := AConfig.IntervaloEntreTentativas;
  FACBr.Configuracoes.Geral.RetirarAcentos := AConfig.RetirarAcentos;
  FACBr.Configuracoes.Arquivos.PathSchemas := AConfig.PathSchemas;
  FACBr.Configuracoes.Arquivos.PathNFe := AConfig.PathNFe;
  FACBr.Configuracoes.Arquivos.PathSalvar := AConfig.PathLog;
  FACBr.Configuracoes.Arquivos.Salvar := False;
  FACBr.Configuracoes.Geral.ModeloDF := TPcnModeloDF.moNFCe;
  if AConfig.Modelo = 55 then
    FACBr.Configuracoes.Geral.ModeloDF := TPcnModeloDF.moNFe;

  ForceDirectories(AConfig.PathSchemas);
  ForceDirectories(AConfig.PathNFe);
  ForceDirectories(AConfig.PathLog);
  ConfigurarCertificado(AConfig);
end;

constructor TRPNFeComponentsEmissorACBr.Create;
begin
  CriarComponenteACBr;
end;

procedure TRPNFeComponentsEmissorACBr.CriarComponenteACBr;
begin
  if not Assigned(FACBr) then
    FACBr := TACBrNFe.Create(nil);
  ConfiguracaoGeral;
  ConfiguracaoArquivosEDiretorios;
  ConfiguracaoWebServices;
end;

destructor TRPNFeComponentsEmissorACBr.Destroy;
begin
  FACBr.Free;
  inherited;
end;

function TRPNFeComponentsEmissorACBr.Empresa(
  AValue: TRPNFeEntityEmpresa): TRPNFeComponentsEmissorACBr;
begin
  Result := Self;
  FACBr.Configuracoes.WebServices.UF := AValue.UF;
end;

function TRPNFeComponentsEmissorACBr.FormatXmlContent(AXmlContent: string): string;
begin
  Result := AXmlContent
    .Replace('Id=' + '''', 'Id="')
    .Replace('versao=' + '''', 'versao="')
    .Replace('''' + '>', '">');
end;

initialization
  GEmissorLock := TCriticalSection.Create;

finalization
  GEmissorLock.Free;

end.
