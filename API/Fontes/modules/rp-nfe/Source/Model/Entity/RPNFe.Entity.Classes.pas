unit RPNFe.Entity.Classes;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TRPNFeTipoDanfe = (tdPosPrinter, tdImage);

  TRPNFeEntityCertificadoDigital = class;

  TRPNFeEntityResponsavelTecnico = class;

  TRPNFeEntityVendaItem = class;

  TRPNFeEntityVendaPagamento = class;

  // Manter classes em ordem alfabetica
  TRPNFeEntityAliquota = class
  private
    FUF: string;
    FId: Integer;
    FAliquota: Double;
  public
    property Id: Integer read FId write FId;
    property UF: string read FUF write FUF;
    property Aliquota: Double read FAliquota write FAliquota;
  end;

  TRPNFeEntityCertificadoDigital = class
  private
    FArquivoPfx: string;
    FSenha: string;
    FIdToken: string;
    FCscToken: string;
    FNumeroSerie: string;
    FTipo: Integer;
  public
    procedure Assign(ASource: TRPNFeEntityCertificadoDigital);

    function SetArquivoPfx(AValue: string): TRPNFeEntityCertificadoDigital;
    function SetSenha(AValue: string): TRPNFeEntityCertificadoDigital;
    function SetIdToken(AValue: string): TRPNFeEntityCertificadoDigital;
    function SetCscToken(AValue: string): TRPNFeEntityCertificadoDigital;
    function SetNumeroSerie(AValue: string): TRPNFeEntityCertificadoDigital;
    function SetTipo(AValue: Integer): TRPNFeEntityCertificadoDigital;

    property ArquivoPfx: string read FArquivoPfx write FArquivoPfx;
    property Senha: string read FSenha write FSenha;
    property IdToken: string read FIdToken write FIdToken;
    property CscToken: string read FCscToken write FCscToken;
    property NumeroSerie: string read FNumeroSerie write FNumeroSerie;
    // Tipo do certificado: 1 = A1 (arquivo .pfx), 3 = A3 (token/cartao/WinCrypt).
    property Tipo: Integer read FTipo write FTipo;
  end;

  TRPNFeEntityCliente = class
  private
    FLogradouro: string;
    FNumero: string;
    FNome: string;
    FCpfCnpj: string;
    FComplemento: string;
    FBairro: string;
    FCodigoIBGE: string;
    FUF: string;
    FCidade: string;
    FCep: string;
  public
    property Nome: string read FNome write FNome;
    property CpfCnpj: string read FCpfCnpj write FCpfCnpj;
    property Cep: string read FCep write FCep;
    property Logradouro: string read FLogradouro write FLogradouro;
    property Numero: string read FNumero write FNumero;
    property Complemento: string read FComplemento write FComplemento;
    property Bairro: string read FBairro write FBairro;
    property CodigoIBGE: string read FCodigoIBGE write FCodigoIBGE;
    property Cidade: string read FCidade write FCidade;
    property UF: string read FUF write FUF;
  end;

  TRPNFeEntityConfiguracao = class
  private
    FProducao: Boolean;
    FPathSchemas: string;
    FPathNFe: string;
    FPathNFeContingencia: string;
    FTimeout: Integer;
    FPathLog: string;
    FResponsavelTecnico: TRPNFeEntityResponsavelTecnico;
    FModelo: Integer;
    FCertificadoDigital: TRPNFeEntityCertificadoDigital;
    FRetirarAcentos: Boolean;
    FNumeroTentativasEmissao: Integer;
    FIntervaloEntreTentativas: Integer;
    FUtilizaResponsavelTecnico: Boolean;
    FJustificativaContingencia: string;
    function GetTimeout: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Assign(ASource: TRPNFeEntityConfiguracao);

    function SetProducao(AValue: Boolean): TRPNFeEntityConfiguracao;
    function SetModelo(AValue: Integer): TRPNFeEntityConfiguracao;
    function SetTimeout(AValue: Integer): TRPNFeEntityConfiguracao;
    function SetPathSchemas(AValue: string): TRPNFeEntityConfiguracao;
    function SetPathLog(AValue: string): TRPNFeEntityConfiguracao;
    function SetPathNFe(AValue: string): TRPNFeEntityConfiguracao;
    function SetPathNFeContingencia(AValue: string): TRPNFeEntityConfiguracao;

    property Producao: Boolean read FProducao write FProducao;
    property Modelo: Integer read FModelo write FModelo;
    property Timeout: Integer read GetTimeout write FTimeout;
    property RetirarAcentos: Boolean read FRetirarAcentos write FRetirarAcentos;
    property NumeroTentativasEmissao: Integer read FNumeroTentativasEmissao write FNumeroTentativasEmissao;
    property IntervaloEntreTentativas: Integer read FIntervaloEntreTentativas write FIntervaloEntreTentativas;
    property JustificativaContingencia: string read FJustificativaContingencia write FJustificativaContingencia;
    property PathSchemas: string read FPathSchemas write FPathSchemas;
    property PathLog: string read FPathLog write FPathLog;
    property PathNFe: string read FPathNFe write FPathNFe;
    property PathNFeContingencia: string read FPathNFeContingencia write FPathNFeContingencia;
    property CertificadoDigital: TRPNFeEntityCertificadoDigital read FCertificadoDigital;
    property UtilizaResponsavelTecnico: Boolean read FUtilizaResponsavelTecnico write FUtilizaResponsavelTecnico;
    property ResponsavelTecnico: TRPNFeEntityResponsavelTecnico read FResponsavelTecnico;
  end;

  TRPNFeEntityContaAReceber = class
  private
    FDocumento: string;
    FDataVencimento: TDateTime;
    FValor: Currency;
    FIdEmpresa: Integer;
    FIdVenda: Integer;
  public
    property IdEmpresa: Integer read FIdEmpresa write FIdEmpresa;
    property IdVenda: Integer read FIdVenda write FIdVenda;
    property Documento: string read FDocumento write FDocumento;
    property DataVencimento: TDateTime read FDataVencimento write FDataVencimento;
    property Valor: Currency read FValor write FValor;
  end;

  TRPNFeEntityEmpresa = class
  private
    FId: Integer;
    FNFCeNumero: Integer;
    FCnpj: string;
    FNome: string;
    FRazaoSocial: string;
    FInscricaoEstadual: string;
    FTelefone: string;
    FCelular: string;
    FInscricaoMunicipal: string;
    FCnae: string;
    FCep: string;
    FLogradouro: string;
    FNumero: string;
    FComplemento: string;
    FBairro: string;
    FCodigoIBGE: string;
    FCidade: string;
    FUF: string;
    FNFCeTerminal: Boolean;
    FNFCeSerie: Integer;
    FAliquotaMunicipalPadrao: Double;
    FAliquotaEstadualPadrao: Double;
    FAliquotaFederalPadrao: Double;
    FCrtCodigo: Integer;
    FNFeSerie: Integer;
    FNFeNumero: Integer;
    // Reforma Tributaria (IBS/CBS): aliquotas do emitente.
    // aliq_cbs vem de empresas; aliq_ibs_uf de estados; aliq_ibs_mun de cidades.
    FAliqCbs: Double;
    FAliqIbsUf: Double;
    FAliqIbsMun: Double;
  public
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property RazaoSocial: string read FRazaoSocial write FRazaoSocial;
    property Cnpj: string read FCnpj write FCnpj;
    property CrtCodigo: Integer read FCrtCodigo write FCrtCodigo;
    property InscricaoEstadual: string read FInscricaoEstadual write FInscricaoEstadual;
    property InscricaoMunicipal: string read FInscricaoMunicipal write FInscricaoMunicipal;
    property Cnae: string read FCnae write FCnae;
    property Telefone: string read FTelefone write FTelefone;
    property Celular: string read FCelular write FCelular;
    property Cep: string read FCep write FCep;
    property Logradouro: string read FLogradouro write FLogradouro;
    property Numero: string read FNumero write FNumero;
    property Complemento: string read FComplemento write FComplemento;
    property Bairro: string read FBairro write FBairro;
    property CodigoIBGE: string read FCodigoIBGE write FCodigoIBGE;
    property Cidade: string read FCidade write FCidade;
    property UF: string read FUF write FUF;
    property NFCeSerie: Integer read FNFCeSerie write FNFCeSerie;
    property NFCeTerminal: Boolean read FNFCeTerminal write FNFCeTerminal;
    property NFCeNumero: Integer read FNFCeNumero write FNFCeNumero;
    property NFeSerie: Integer read FNFeSerie write FNFeSerie;
    property NFeNumero: Integer read FNFeNumero write FNFeNumero;
    property AliquotaMunicipalPadrao: Double read FAliquotaMunicipalPadrao write FAliquotaMunicipalPadrao;
    property AliquotaEstadualPadrao: Double read FAliquotaEstadualPadrao write FAliquotaEstadualPadrao;
    property AliquotaFederalPadrao: Double read FAliquotaFederalPadrao write FAliquotaFederalPadrao;
    property AliqCbs: Double read FAliqCbs write FAliqCbs;
    property AliqIbsUf: Double read FAliqIbsUf write FAliqIbsUf;
    property AliqIbsMun: Double read FAliqIbsMun write FAliqIbsMun;
  end;

  // Reforma Tributaria: flags da classificacao tributaria (dfe_classtrib_rt +
  // dfe_cst_rt), mesmas colunas consultadas pelo uEmissorNFCe do RPCHEFF_VCL.
  TRPNFeEntityClassTribRT = class
  private
    FClassTrib: string;
    FIndNfe: Boolean;
    FIndNfce: Boolean;
    FIndTribRegular: Boolean;
    FPRedIbs: Double;
    FPRedCbs: Double;
    FIndRedAliq: Boolean;
    FIndDif: Boolean;
    FIndIbsCbsMono: Boolean;
    FIndRedBc: Boolean;
  public
    property ClassTrib: string read FClassTrib write FClassTrib;
    property IndNfe: Boolean read FIndNfe write FIndNfe;
    property IndNfce: Boolean read FIndNfce write FIndNfce;
    property IndTribRegular: Boolean read FIndTribRegular write FIndTribRegular;
    property PRedIbs: Double read FPRedIbs write FPRedIbs;
    property PRedCbs: Double read FPRedCbs write FPRedCbs;
    property IndRedAliq: Boolean read FIndRedAliq write FIndRedAliq;
    property IndDif: Boolean read FIndDif write FIndDif;
    property IndIbsCbsMono: Boolean read FIndIbsCbsMono write FIndIbsCbsMono;
    property IndRedBc: Boolean read FIndRedBc write FIndRedBc;
  end;

  TRPNFeEntityEncerraVenda = class
  private
    FIdVenda: Integer;
    FSatStatus: Integer;
  public
    property IdVenda: Integer read FIdVenda write FIdVenda;
    property SatStatus: Integer read FSatStatus write FSatStatus;
  end;

  TRPNFeEntityEstado = class
  private
    FId: Integer;
    FNome: string;
    FSigla: string;
    FCodigoUF: Integer;
  public
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Sigla: string read FSigla write FSigla;
    property CodigoUF: Integer read FCodigoUF write FCodigoUF;
  end;

  TRPNFeEntityFormaPagamento = class
  private
    FIdFormaPagamento: Integer;
    FIdEmpresa: Integer;
    FSfiCodigo: Integer;
    FCnpjCredenciadora: string;
    FBandeiraCartao: string;
    FTipoIntegracao: Integer;
  public
    property IdFormaPagamento: Integer read FIdFormaPagamento write FIdFormaPagamento;
    property IdEmpresa: Integer read FIdEmpresa write FIdEmpresa;
    property SfiCodigo: Integer read FSfiCodigo write FSfiCodigo;
    property CnpjCredenciadora: string read FCnpjCredenciadora write FCnpjCredenciadora;
    property BandeiraCartao: string read FBandeiraCartao write FBandeiraCartao;
    property TipoIntegracao: Integer read FTipoIntegracao write FTipoIntegracao;
  end;

  TRPNFeEntityIBPT = class
  private
    FNCM: string;
    FDescricao: string;
    FIdIbpt: Integer;
    FAliquotaEstadual: Double;
    FAliquotaMunicipal: Double;
    FAliquotaFederalImportado: Double;
    FAliquotaFederalNacional: Double;
    FManual: Boolean;
  public
    property IdIbpt: Integer read FIdIbpt write FIdIbpt;
    property NCM: string read FNCM write FNCM;
    property Descricao: string read FDescricao write FDescricao;
    property AliquotaEstadual: Double read FAliquotaEstadual write FAliquotaEstadual;
    property AliquotaMunicipal: Double read FAliquotaMunicipal write FAliquotaMunicipal;
    property AliquotaFederalImportado: Double read FAliquotaFederalImportado write FAliquotaFederalImportado;
    property AliquotaFederalNacional: Double read FAliquotaFederalNacional write FAliquotaFederalNacional;
    property Manual: Boolean read FManual write FManual;
  end;

  TRPNFeEntityNFeNotaEletronica = class
  private
    FSerie: Integer;
    FDataAutorizacao: TDateTime;
    FChaveNFe: string;
    FProtocolo: string;
    FContingencia: Boolean;
    FNumeroNFe: Integer;
    FStatus: Integer;
    FMotivo: string;
    FErro: Boolean;
    FXml: string;
    FModelo: Integer;
    FXmlPath: string;
  public
    function ModeloDescription: string;
    function MensagemStatus: string;

    property Serie: Integer read FSerie write FSerie;
    property NumeroNFe: Integer read FNumeroNFe write FNumeroNFe;
    property Modelo: Integer read FModelo write FModelo;
    property DataAutorizacao: TDateTime read FDataAutorizacao write FDataAutorizacao;
    property ChaveNFe: string read FChaveNFe write FChaveNFe;
    property Protocolo: string read FProtocolo write FProtocolo;
    property Status: Integer read FStatus write FStatus;
    property Motivo: string read FMotivo write FMotivo;
    property Erro: Boolean read FErro write FErro;
    property Contingencia: Boolean read FContingencia write FContingencia;
    property Xml: string read FXml write FXml;
    property XmlPath: string read FXmlPath write FXmlPath;
  end;

  TRPNFeEntityProduto = class
  private
    FCodigo: Integer;
    FDescricao: string;
    FEan: string;
    FNCM: string;
    FCEST: string;
    FCFOPConsumidor: string;
    FServico: Boolean;
    FIssExigibilidade: Integer;
    FIss: Double;
    FIssIncentivo: Integer;
    FIssServico: string;
    FOrmCodigo: Integer;
    FCstConsumidor: Integer;
    FCsoCodigo: Integer;
    FIcms: Double;
    FPisCodigoSaida: Integer;
    FPis: Double;
    FCofinsCodigoSaida: Integer;
    FCofins: Double;
    FReducaoBaseCalculoIcms: Double;
    FReducaoBaseCalculoSt: Double;
    FCodigoAnp: string;
    FPesoPartidaAnp: Double;
    FPglp: Double;
    FPgnn: Double;
    FPgni: Double;
    FAdrem: Double;
    // Reforma Tributaria (IBS/CBS): CST/cClassTrib da NFC-e e parametros da
    // base de calculo, mesmos campos de materiais usados pelo uEmissorNFCe.
    FCstRtNfce: string;
    FCClassTribRtNfce: string;
    FRtParamBcVlProd: Boolean;
    FRtParamBcVlFrete: Boolean;
    FRtParamBcVlSeg: Boolean;
    FRtParamBcVlDesp: Boolean;
    FRtParamBcII: Boolean;
    FRtParamBcIS: Boolean;
    FRtParamBcDesconto: Boolean;
    FRtParamBcPis: Boolean;
    FRtParamBcCofins: Boolean;
    FRtParamBcIcms: Boolean;
    FRtParamBcIcmsDest: Boolean;
    FRtParamBcFcp: Boolean;
    FRtParamBcFcpDest: Boolean;
    FRtParamBcIcmsMono: Boolean;
    FRtParamBcIssqn: Boolean;
  public
    property Codigo: Integer read FCodigo write FCodigo;
    property Descricao: string read FDescricao write FDescricao;
    property Ean: string read FEan write FEan;
    property NCM: string read FNCM write FNCM;
    property CEST: string read FCEST write FCEST;
    property CFOPConsumidor: string read FCFOPConsumidor write FCFOPConsumidor;
    property Servico: Boolean read FServico write FServico;
    property Iss: Double read FIss write FIss;
    property IssExigibilidade: Integer read FIssExigibilidade write FIssExigibilidade;
    property IssIncentivo: Integer read FIssIncentivo write FIssIncentivo;
    property IssServico: string read FIssServico write FIssServico;
    property OrmCodigo: Integer read FOrmCodigo write FOrmCodigo;
    property CstConsumidor: Integer read FCstConsumidor write FCstConsumidor;
    property CsoCodigo: Integer read FCsoCodigo write FCsoCodigo;
    property Icms: Double read FIcms write FIcms;
    property PisCodigoSaida: Integer read FPisCodigoSaida write FPisCodigoSaida;
    property Pis: Double read FPis write FPis;
    property CofinsCodigoSaida: Integer read FCofinsCodigoSaida write FCofinsCodigoSaida;
    property Cofins: Double read FCofins write FCofins;
    property ReducaoBaseCalculoIcms: Double read FReducaoBaseCalculoIcms write FReducaoBaseCalculoIcms;
    property ReducaoBaseCalculoSt: Double read FReducaoBaseCalculoSt write FReducaoBaseCalculoSt;
    property CodigoAnp: string read FCodigoAnp write FCodigoAnp;
    property PesoPartidaAnp: Double read FPesoPartidaAnp write FPesoPartidaAnp;
    property Pglp: Double read FPglp write FPglp;
    property Pgnn: Double read FPgnn write FPgnn;
    property Pgni: Double read FPgni write FPgni;
    property Adrem: Double read FAdrem write FAdrem;
    property CstRtNfce: string read FCstRtNfce write FCstRtNfce;
    property CClassTribRtNfce: string read FCClassTribRtNfce write FCClassTribRtNfce;
    property RtParamBcVlProd: Boolean read FRtParamBcVlProd write FRtParamBcVlProd;
    property RtParamBcVlFrete: Boolean read FRtParamBcVlFrete write FRtParamBcVlFrete;
    property RtParamBcVlSeg: Boolean read FRtParamBcVlSeg write FRtParamBcVlSeg;
    property RtParamBcVlDesp: Boolean read FRtParamBcVlDesp write FRtParamBcVlDesp;
    property RtParamBcII: Boolean read FRtParamBcII write FRtParamBcII;
    property RtParamBcIS: Boolean read FRtParamBcIS write FRtParamBcIS;
    property RtParamBcDesconto: Boolean read FRtParamBcDesconto write FRtParamBcDesconto;
    property RtParamBcPis: Boolean read FRtParamBcPis write FRtParamBcPis;
    property RtParamBcCofins: Boolean read FRtParamBcCofins write FRtParamBcCofins;
    property RtParamBcIcms: Boolean read FRtParamBcIcms write FRtParamBcIcms;
    property RtParamBcIcmsDest: Boolean read FRtParamBcIcmsDest write FRtParamBcIcmsDest;
    property RtParamBcFcp: Boolean read FRtParamBcFcp write FRtParamBcFcp;
    property RtParamBcFcpDest: Boolean read FRtParamBcFcpDest write FRtParamBcFcpDest;
    property RtParamBcIcmsMono: Boolean read FRtParamBcIcmsMono write FRtParamBcIcmsMono;
    property RtParamBcIssqn: Boolean read FRtParamBcIssqn write FRtParamBcIssqn;
  end;

  TRPNFeEntityResponsavelTecnico = class
  private
    FContato: string;
    FCNPJ: string;
    FEmail: string;
    FFone: string;
  public
    procedure Assign(ASource: TRPNFeEntityResponsavelTecnico);

    function SetContato(AValue: string): TRPNFeEntityResponsavelTecnico;
    function SetCNPJ(AValue: string): TRPNFeEntityResponsavelTecnico;
    function SetEmail(AValue: string): TRPNFeEntityResponsavelTecnico;
    function SetFone(AValue: string): TRPNFeEntityResponsavelTecnico;

    property Contato: string read FContato write FContato;
    property CNPJ: string read FCNPJ write FCNPJ;
    property Email: string read FEmail write FEmail;
    property Fone: string read FFone write FFone;
  end;

  TRPNFeEntityUnidades = class
  private
    FCodigo: Integer;
    FUnidade: string;
    FDescricao: string;
  public
    property Codigo: Integer read FCodigo write FCodigo;
    property Unidade: string read FUnidade write FUnidade;
    property Descricao: string read FDescricao write FDescricao;
  end;

  TRPNFeEntityVenda = class
  private
    FId: Integer;
    FPagamentos: TObjectList<TRPNFeEntityVendaPagamento>;
    FItens: TObjectList<TRPNFeEntityVendaItem>;
    FContasAReceber: TObjectList<TRPNFeEntityContaAReceber>;
    FValor: Currency;
    FIdCaixaAbertura: Integer;
    FPainelSenha: string;
    FTipoVenda: string;
    FCliente: TRPNFeEntityCliente;
    FIdEmpresa: Integer;
    FData: TDateTime;
    FValorTaxaServico: Currency;
    FValorDesconto: Currency;
    FChaveEletronica: string;
    FDataEmissao: TDateTime;
    procedure SetContasAReceber(const AValue: TObjectList<TRPNFeEntityContaAReceber>);
    procedure SetItens(const AValue: TObjectList<TRPNFeEntityVendaItem>);
    procedure SetPagamentos(const AValue: TObjectList<TRPNFeEntityVendaPagamento>);
  public
    constructor Create;
    destructor Destroy; override;

    function PercentualTaxa: Currency;

    property Id: Integer read FId write FId;
    property IdEmpresa: Integer read FIdEmpresa write FIdEmpresa;
    property Data: TDateTime read FData write FData;
    property Valor: Currency read FValor write FValor;
    property ValorTaxaServico: Currency read FValorTaxaServico write FValorTaxaServico;
    property ValorDesconto: Currency read FValorDesconto write FValorDesconto;
    property IdCaixaAbertura: Integer read FIdCaixaAbertura write FIdCaixaAbertura;
    property PainelSenha: string read FPainelSenha write FPainelSenha;
    property TipoVenda: string read FTipoVenda write FTipoVenda;
    property ChaveEletronica: string read FChaveEletronica write FChaveEletronica;
    property DataEmissao: TDateTime read FDataEmissao write FDataEmissao;
    property Cliente: TRPNFeEntityCliente read FCliente write FCliente;
    property ContasAReceber: TObjectList<TRPNFeEntityContaAReceber> read FContasAReceber
      write SetContasAReceber;
    property Itens: TObjectList<TRPNFeEntityVendaItem> read FItens write SetItens;
    property Pagamentos: TObjectList<TRPNFeEntityVendaPagamento> read FPagamentos
      write SetPagamentos;
  end;

  TRPNFeEntityVendaItem = class
  private
    FNumeroItem: Integer;
    FQuantidade: Double;
    FValorUnitario: Double;
    FUnidade: TRPNFeEntityUnidades;
    FProduto: TRPNFeEntityProduto;
    FValorTotal: Double;
  public
    constructor Create;
    destructor Destroy; override;

    property NumeroItem: Integer read FNumeroItem write FNumeroItem;
    property Quantidade: Double read FQuantidade write FQuantidade;
    property ValorUnitario: Double read FValorUnitario write FValorUnitario;
    property ValorTotal: Double read FValorTotal write FValorTotal;
    property Produto: TRPNFeEntityProduto read FProduto write FProduto;
    property Unidade: TRPNFeEntityUnidades read FUnidade write FUnidade;
  end;

  TRPNFeEntityVendaPagamento = class
  private
    FIdVenda: Integer;
    FForma: TRPNFeEntityFormaPagamento;
    FValor: Currency;
    FTroco: Currency;
    FNumeroPagamento: Integer;
    FAutorizacao: string;
  public
    constructor Create;
    destructor Destroy; override;

    property IdVenda: Integer read FIdVenda write FIdVenda;
    property NumeroPagamento: Integer read FNumeroPagamento write FNumeroPagamento;
    property Forma: TRPNFeEntityFormaPagamento read FForma write FForma;
    property Valor: Currency read FValor write FValor;
    property Troco: Currency read FTroco write FTroco;
    property Autorizacao: string read FAutorizacao write FAutorizacao;
  end;

implementation

uses
  System.Math;

{ TRPNFeEntityVendaPagamento }

constructor TRPNFeEntityVendaPagamento.Create;
begin
  FForma := TRPNFeEntityFormaPagamento.Create;
end;

destructor TRPNFeEntityVendaPagamento.Destroy;
begin
  FForma.Free;
  inherited;
end;

{ TRPNFeEntityVenda }

constructor TRPNFeEntityVenda.Create;
begin
  FCliente := TRPNFeEntityCliente.Create;
  FContasAReceber := TObjectList<TRPNFeEntityContaAReceber>.Create;
  FItens := TObjectList<TRPNFeEntityVendaItem>.Create;
  FPagamentos := TObjectList<TRPNFeEntityVendaPagamento>.Create;
end;

destructor TRPNFeEntityVenda.Destroy;
begin
  FCliente.Free;
  FContasAReceber.Free;
  FItens.Free;
  FPagamentos.Free;
  inherited;
end;

function TRPNFeEntityVenda.PercentualTaxa: Currency;
begin
  Result := 0;
  if FValorTaxaServico > 0 then
    Result := SimpleRoundTo(FValorTaxaServico / (FValor - FValorTaxaServico), -2) * 100;
end;

procedure TRPNFeEntityVenda.SetContasAReceber(const AValue: TObjectList<TRPNFeEntityContaAReceber>);
begin
  FContasAReceber.Free;
  FContasAReceber := AValue;
end;

procedure TRPNFeEntityVenda.SetItens(const AValue: TObjectList<TRPNFeEntityVendaItem>);
begin
  FItens.Free;
  FItens := AValue;
end;

procedure TRPNFeEntityVenda.SetPagamentos(const AValue: TObjectList<TRPNFeEntityVendaPagamento>);
begin
  FPagamentos.Free;
  FPagamentos := AValue;
end;

{ TRPNFeEntityVendaItem }

constructor TRPNFeEntityVendaItem.Create;
begin
  FProduto := TRPNFeEntityProduto.Create;
  FUnidade := TRPNFeEntityUnidades.Create;
end;

destructor TRPNFeEntityVendaItem.Destroy;
begin
  FProduto.Free;
  FUnidade.Free;
  inherited;
end;

{ TRPNFeEntityConfiguracao }

procedure TRPNFeEntityConfiguracao.Assign(ASource: TRPNFeEntityConfiguracao);
begin
  FProducao := ASource.Producao;
  FRetirarAcentos := ASource.RetirarAcentos;
  FNumeroTentativasEmissao := ASource.NumeroTentativasEmissao;
  FIntervaloEntreTentativas := ASource.IntervaloEntreTentativas;
  FJustificativaContingencia := ASource.JustificativaContingencia;
  FTimeout := ASource.Timeout;
  FModelo := ASource.Modelo;
  FPathNFe := ASource.PathNFe;
  FPathSchemas := ASource.PathSchemas;
  FPathNFeContingencia := ASource.PathNFeContingencia;
  FPathLog := ASource.PathLog;
  FCertificadoDigital.Assign(ASource.CertificadoDigital);
  FResponsavelTecnico.Assign(ASource.ResponsavelTecnico);
end;

constructor TRPNFeEntityConfiguracao.Create;
var
  LPathNFe: string;
begin
  FProducao := False;
  FTimeout := 0;
  FModelo := 65;
  FJustificativaContingencia := 'Problemas com a conexao de internet';
  LPathNFe := ExtractFilePath(GetModuleName(HInstance)) + 'NFe\';
  FPathSchemas := LPathNFe + 'Schemas\';
  FPathNFe := LPathNFe + 'Xml\NFe\';
  FPathNFeContingencia := LPathNFe + '\Xml\NFe\Contingencia\';
  FPathLog := LPathNFe + 'Xml\Log\';
  FCertificadoDigital := TRPNFeEntityCertificadoDigital.Create;
  FResponsavelTecnico := TRPNFeEntityResponsavelTecnico.Create;
end;

destructor TRPNFeEntityConfiguracao.Destroy;
begin
  FResponsavelTecnico.Free;
  FCertificadoDigital.Free;
  inherited;
end;

function TRPNFeEntityConfiguracao.GetTimeout: Integer;
begin
  Result := FTimeout;
  if Result = 0 then
    Result := 60;
end;

function TRPNFeEntityConfiguracao.SetModelo(AValue: Integer): TRPNFeEntityConfiguracao;
begin
  Result := Self;
  FModelo := AValue;
end;

function TRPNFeEntityConfiguracao.SetPathLog(AValue: string): TRPNFeEntityConfiguracao;
begin
  Result := Self;
  FPathLog := AValue;
end;

function TRPNFeEntityConfiguracao.SetPathNFe(AValue: string): TRPNFeEntityConfiguracao;
begin
  Result := Self;
  FPathNFe := AValue;
end;

function TRPNFeEntityConfiguracao.SetPathNFeContingencia(AValue: string): TRPNFeEntityConfiguracao;
begin
  Result := Self;
  FPathNFeContingencia := AValue;
end;

function TRPNFeEntityConfiguracao.SetPathSchemas(AValue: string): TRPNFeEntityConfiguracao;
begin
  Result := Self;
  FPathSchemas := AValue;
end;

function TRPNFeEntityConfiguracao.SetProducao(AValue: Boolean): TRPNFeEntityConfiguracao;
begin
  Result := Self;
  FProducao := AValue;
end;

function TRPNFeEntityConfiguracao.SetTimeout(AValue: Integer): TRPNFeEntityConfiguracao;
begin
  Result := Self;
  FTimeout := AValue;
end;

{ TRPNFeEntityResponsavelTecnico }

procedure TRPNFeEntityResponsavelTecnico.Assign(ASource: TRPNFeEntityResponsavelTecnico);
begin
  FContato := ASource.Contato;
  FCNPJ := ASource.CNPJ;
  FEmail := ASource.Email;
  FFone := ASource.Fone;
end;

function TRPNFeEntityResponsavelTecnico.SetCNPJ(AValue: string): TRPNFeEntityResponsavelTecnico;
begin
  Result := Self;
  FCNPJ := AValue;
end;

function TRPNFeEntityResponsavelTecnico.SetContato(AValue: string): TRPNFeEntityResponsavelTecnico;
begin
  Result := Self;
  FContato := AValue;
end;

function TRPNFeEntityResponsavelTecnico.SetEmail(AValue: string): TRPNFeEntityResponsavelTecnico;
begin
  Result := Self;
  FEmail := AValue;
end;

function TRPNFeEntityResponsavelTecnico.SetFone(AValue: string): TRPNFeEntityResponsavelTecnico;
begin
  Result := Self;
  FFone := AValue;
end;

{ TRPNFeEntityCertificadoDigital }

procedure TRPNFeEntityCertificadoDigital.Assign(ASource: TRPNFeEntityCertificadoDigital);
begin
  FArquivoPfx := ASource.ArquivoPfx;
  FSenha := ASource.Senha;
  FIdToken := ASource.IdToken;
  FCscToken := ASource.CscToken;
  FNumeroSerie := ASource.NumeroSerie;
  FTipo := ASource.Tipo;
end;

function TRPNFeEntityCertificadoDigital.SetArquivoPfx(
  AValue: string): TRPNFeEntityCertificadoDigital;
begin
  Result := Self;
  FArquivoPfx := AValue;
end;

function TRPNFeEntityCertificadoDigital.SetCscToken(AValue: string): TRPNFeEntityCertificadoDigital;
begin
  Result := Self;
  FCscToken := AValue;
end;

function TRPNFeEntityCertificadoDigital.SetIdToken(
  AValue: string): TRPNFeEntityCertificadoDigital;
begin
  Result := Self;
  FIdToken := AValue;
end;

function TRPNFeEntityCertificadoDigital.SetSenha(AValue: string): TRPNFeEntityCertificadoDigital;
begin
  Result := Self;
  FSenha := AValue;
end;

function TRPNFeEntityCertificadoDigital.SetNumeroSerie(
  AValue: string): TRPNFeEntityCertificadoDigital;
begin
  Result := Self;
  FNumeroSerie := AValue;
end;

function TRPNFeEntityCertificadoDigital.SetTipo(AValue: Integer): TRPNFeEntityCertificadoDigital;
begin
  Result := Self;
  FTipo := AValue;
end;

{ TRPNFeEntityNFeNotaEletronica }

function TRPNFeEntityNFeNotaEletronica.MensagemStatus: string;
begin
  Result := Format('%d - %s', [FStatus, FMotivo]);
end;

function TRPNFeEntityNFeNotaEletronica.ModeloDescription: string;
begin
  Result := 'NFCE';
  if FModelo = 55 then
    Result := 'NFE';
end;

end.
