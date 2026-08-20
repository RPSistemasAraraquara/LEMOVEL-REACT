unit RPNFe.Service.Emissao;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Entity.Classes,
  RPNFe.Components,
  RPNFe.DAO.Factory;

type
  TRPNFeServiceEmissaoObserver = class;

  TRPNFeServiceEmissao = class
  protected
    FComponents: TRPNFeComponents;
    FDAO: TRPNFeDAOFactory;
    FIdVenda: Integer;
    FEmpresa: TRPNFeEntityEmpresa;
    FVenda: TRPNFeEntityVenda;
    FConfig: TRPNFeEntityConfiguracao;
    FNotaEletronica: TRPNFeEntityNFeNotaEletronica;
    FConfigucaoFileName: string;
    FPathSchemas: string;
    // Overrides fiscais informados pela API: sobrepoem o CONFIGURACAO.XML/banco.
    // Regra de "informado": string nao-vazia; inteiro > 0 (exceto FAmbiente: 0 = usa XML).
    FIdCSC: string;
    FCSC: string;
    FAmbiente: Integer;
    FSerie: Integer;
    FNumero: Integer;
    FCertTipo: Integer;
    FCertArquivo: string;
    FCertSenha: string;
    FCertSerie: string;
    FContingencia: Boolean;
    FObservers: TObjectList<TRPNFeServiceEmissaoObserver>;

    procedure CarregarVenda;
    procedure CarregarEmpresa;
    procedure ExecuteCommands;
    procedure SetNotaEletronica(AValue: TRPNFeEntityNFeNotaEletronica);

    procedure Notificar(const ANotaEletronica: TRPNFeEntityNFeNotaEletronica);
  public
    constructor Create;
    destructor Destroy; override;

    function Components(AValue: TRPNFeComponents): TRPNFeServiceEmissao; overload;
    function Components: TRPNFeComponents; overload;
    function DAO(AValue: TRPNFeDAOFactory): TRPNFeServiceEmissao; overload;
    function DAO: TRPNFeDAOFactory; overload;
    function IdVenda(AValue: Integer): TRPNFeServiceEmissao;
    function Venda: TRPNFeEntityVenda;
    function Empresa: TRPNFeEntityEmpresa;

    function Configuracao(const AFileName: string): TRPNFeServiceEmissao; overload;
    function Configuracao: TRPNFeEntityConfiguracao; overload;
    function PathSchemas(const AValue: string): TRPNFeServiceEmissao;

    // Overrides fiscais NFC-e (opcionais) informados pela API.
    function IdCSC(const AValue: string): TRPNFeServiceEmissao;
    function CSC(const AValue: string): TRPNFeServiceEmissao;
    function Ambiente(const AValue: Integer): TRPNFeServiceEmissao;
    function Serie(const AValue: Integer): TRPNFeServiceEmissao;
    function Numero(const AValue: Integer): TRPNFeServiceEmissao;
    function CertTipo(const AValue: Integer): TRPNFeServiceEmissao;
    function CertArquivo(const AValue: string): TRPNFeServiceEmissao;
    function CertSenha(const AValue: string): TRPNFeServiceEmissao;
    function CertSerie(const AValue: string): TRPNFeServiceEmissao;
    function Contingencia(AValue: Boolean): TRPNFeServiceEmissao; overload;
    function Contingencia: Boolean; overload;

    function Execute: TRPNFeEntityNFeNotaEletronica;

    function AddObserver(const AValue: TRPNFeServiceEmissaoObserver): TRPNFeServiceEmissao;
  end;

  TRPNFeServiceEmissaoObserver = class
  protected
    FParent: TRPNFeServiceEmissao;
    procedure Log(ALog: string; const AArgs: array of const); overload;
    procedure Log(ALog: string); overload;
  public
    constructor Create(AParent: TRPNFeServiceEmissao); virtual;

    procedure Execute(const ANotaEletronica: TRPNFeEntityNFeNotaEletronica); virtual; abstract;
  end;

  TRPNFeServiceEmissaoCommand = class
  protected
    FParent: TRPNFeServiceEmissao;
    procedure Log(ALog: string; const AArgs: array of const); overload;
    procedure Log(ALog: string); overload;
  public
    constructor Create(AParent: TRPNFeServiceEmissao); virtual;

    procedure Execute; virtual; abstract;
  end;

  TRPServiceEmissaoInvoker = class
  private
    FParent: TRPNFeServiceEmissao;
    FCommands: TObjectList<TRPNFeServiceEmissaoCommand>;
  public
    constructor Create(AParent: TRPNFeServiceEmissao);
    destructor Destroy; override;

    function AddCommand(AValue: TRPNFeServiceEmissaoCommand): TRPServiceEmissaoInvoker;
    procedure Execute;
  end;

implementation

{ TRPNFeServiceEmissao }

uses
  RPNFe.Service.Emissao.Command.DadosIde,
  RPNFe.Service.Emissao.Command.DadosEmit,
  RPNFe.Service.Emissao.Command.DadosDest,
  RPNFe.Service.Emissao.Command.Itens,
  RPNFe.Service.Emissao.Command.ItensImpostoICMS,
  RPNFe.Service.Emissao.Command.ItensImpostoICMSUFDest,
  RPNFe.Service.Emissao.Command.ItensImpostoCOFINS,
  RPNFe.Service.Emissao.Command.ItensImpostoPIS,
  RPNFe.Service.Emissao.Command.ItensImpostoISSQN,
  RPNFe.Service.Emissao.Command.ItensANP,
  RPNFe.Service.Emissao.Command.Pagamentos,
  RPNFe.Service.Emissao.Command.Totais,
  RPNFe.Service.Emissao.Command.ItensImpostoIBSCBS,
  RPNFe.Service.Emissao.Command.ResponsavelTecnico,
  RPNFe.Service.Emissao.Command.AssinarXML,
  RPNFe.Service.Emissao.Command.EnviarNota;

function TRPNFeServiceEmissao.AddObserver(
  const AValue: TRPNFeServiceEmissaoObserver): TRPNFeServiceEmissao;
begin
  Result := Self;
  FObservers.Add(AValue);
end;

procedure TRPNFeServiceEmissao.CarregarEmpresa;
begin
  FComponents.Log.Write('Carregando empresa pelo codigo %d', [FVenda.IdEmpresa]);
  FreeAndNil(FEmpresa);
  FEmpresa := FDAO.EmpresaDAO.Buscar(FVenda.IdEmpresa);
  if not Assigned(FEmpresa) then
    raise Exception.CreateFmt('Empresa %d n�o encontrada.', [FVenda.IdEmpresa]);

  // Overrides fiscais informados pela API sobrepoem serie/numero do banco.
  // Numero informado e o "proximo a emitir"; o DadosIde soma +1, entao guardamos N-1.
  if FSerie > 0 then
    FEmpresa.NFCeSerie := FSerie;
  // O numero e um PISO (semente), nunca um valor fixo: se fosse aplicado
  // sempre, toda emissao repetiria o mesmo nNF (duplicidade na SEFAZ) porque
  // o incremento em empresas.numero_nfce seria ignorado. O piso e PERSISTIDO
  // no banco (greatest) para que a proxima emissao ja parta dele; depois
  // disso o override vira inocuo e o banco assume a numeracao.
  if (FNumero > 0) and (FNumero - 1 > FEmpresa.NFCeNumero) then
  begin
    FDAO.EmpresaDAO.SementeNumeroNFCe(FEmpresa.Id, FNumero - 1);
    FEmpresa.NFCeNumero := FNumero - 1;
  end;

  FComponents.Log.Write('Carregada empresa %s.', [FEmpresa.Nome]);
end;

procedure TRPNFeServiceEmissao.CarregarVenda;
begin
  FComponents.Log.Write('Carregando venda pelo id %d', [FIdVenda]);
  FreeAndNil(FVenda);
  FVenda := FDAO.VendaDAO.Buscar(FIdVenda);
  if not Assigned(FVenda) then
    raise Exception.CreateFmt('Venda %d n�o encontrada ou n�o encerrada.', [FIdVenda]);

  FComponents.Log.Write('Carregando itens da venda');
  FVenda.Itens := FDAO.VendaItemDAO.Listar(FIdVenda);
  FComponents.Log.Write('%d itens encontrados.', [FVenda.Itens.Count]);

  FComponents.Log.Write('Carregando pagamentos.');
  FVenda.Pagamentos := FDAO.VendaPagamentoDAO.Listar(FVenda.IdEmpresa, FVenda.Id);
  FComponents.Log.Write('%d pagamentos encontrados.', [FVenda.Pagamentos.Count]);
end;

function TRPNFeServiceEmissao.Components(AValue: TRPNFeComponents): TRPNFeServiceEmissao;
begin
  Result := Self;
  FComponents := AValue;
end;

function TRPNFeServiceEmissao.Components: TRPNFeComponents;
begin
  Result := FComponents;
end;

function TRPNFeServiceEmissao.Configuracao(const AFileName: string): TRPNFeServiceEmissao;
begin
  Result := Self;
  FConfigucaoFileName := AFileName;
end;

function TRPNFeServiceEmissao.Configuracao: TRPNFeEntityConfiguracao;
begin
  if not Assigned(FConfig) then
  begin
    FConfig := FDAO.ConfiguracaoDAO.Carregar(FConfigucaoFileName);
    // Diretorio de schemas configurado na API tem prioridade sobre o default do exe.
    if (FPathSchemas <> '') and Assigned(FConfig) then
      FConfig.PathSchemas := IncludeTrailingPathDelimiter(FPathSchemas);

    // Os XMLs sao gravados nas pastas IRMAS do diretorio de Schemas, no mesmo
    // layout do desktop RPCHEFF_VCL (uEmissorNFCe): <pai do Schemas>\NFCeVenda
    // (autorizadas), \NFCeLogs (envio/retorno) e \NFCeContingencia. Assim o
    // desktop encontra as notas do mobile para cancelar/reimprimir.
    if Assigned(FConfig) then
    begin
      FConfig.PathNFe := ExtractFilePath(ExcludeTrailingPathDelimiter(FConfig.PathSchemas)) + 'NFCeVenda\';
      FConfig.PathLog := ExtractFilePath(ExcludeTrailingPathDelimiter(FConfig.PathSchemas)) + 'NFCeLogs\';
      FConfig.PathNFeContingencia := ExtractFilePath(ExcludeTrailingPathDelimiter(FConfig.PathSchemas)) + 'NFCeContingencia\';
    end;

    // Overrides fiscais informados pela API sobrepoem o CONFIGURACAO.XML.
    // Nao informado (vazio/0) mantem o valor lido do XML.
    if Assigned(FConfig) then
    begin
      if FIdCSC <> '' then
        FConfig.CertificadoDigital.IdToken := FIdCSC;
      if FCSC <> '' then
        FConfig.CertificadoDigital.CscToken := FCSC;

      case FAmbiente of
        1: FConfig.Producao := False; // homologacao
        2: FConfig.Producao := True;  // producao
      end;                            // 0 = nao informado: nao mexe

      if FCertTipo > 0 then
      begin
        FConfig.CertificadoDigital.Tipo := FCertTipo;
        if FCertTipo = 3 then
        begin
          if FCertSerie <> '' then
            FConfig.CertificadoDigital.NumeroSerie := FCertSerie;
        end
        else
        begin
          if FCertArquivo <> '' then
            FConfig.CertificadoDigital.ArquivoPfx := FCertArquivo;
          if FCertSenha <> '' then
            FConfig.CertificadoDigital.Senha := FCertSenha;
        end;
      end;
    end;
  end;
  Result := FConfig;
end;

function TRPNFeServiceEmissao.PathSchemas(const AValue: string): TRPNFeServiceEmissao;
begin
  Result := Self;
  FPathSchemas := AValue;
end;

function TRPNFeServiceEmissao.IdCSC(const AValue: string): TRPNFeServiceEmissao;
begin
  Result := Self;
  FIdCSC := AValue;
end;

function TRPNFeServiceEmissao.CSC(const AValue: string): TRPNFeServiceEmissao;
begin
  Result := Self;
  FCSC := AValue;
end;

function TRPNFeServiceEmissao.Ambiente(const AValue: Integer): TRPNFeServiceEmissao;
begin
  Result := Self;
  FAmbiente := AValue;
end;

function TRPNFeServiceEmissao.Serie(const AValue: Integer): TRPNFeServiceEmissao;
begin
  Result := Self;
  FSerie := AValue;
end;

function TRPNFeServiceEmissao.Numero(const AValue: Integer): TRPNFeServiceEmissao;
begin
  Result := Self;
  FNumero := AValue;
end;

function TRPNFeServiceEmissao.CertTipo(const AValue: Integer): TRPNFeServiceEmissao;
begin
  Result := Self;
  FCertTipo := AValue;
end;

function TRPNFeServiceEmissao.CertArquivo(const AValue: string): TRPNFeServiceEmissao;
begin
  Result := Self;
  FCertArquivo := AValue;
end;

function TRPNFeServiceEmissao.CertSenha(const AValue: string): TRPNFeServiceEmissao;
begin
  Result := Self;
  FCertSenha := AValue;
end;

function TRPNFeServiceEmissao.CertSerie(const AValue: string): TRPNFeServiceEmissao;
begin
  Result := Self;
  FCertSerie := AValue;
end;

function TRPNFeServiceEmissao.Contingencia(AValue: Boolean): TRPNFeServiceEmissao;
begin
  Result := Self;
  FContingencia := AValue;
end;

function TRPNFeServiceEmissao.Contingencia: Boolean;
begin
  Result := FContingencia;
end;

constructor TRPNFeServiceEmissao.Create;
begin
  FObservers := TObjectList<TRPNFeServiceEmissaoObserver>.Create;
end;

function TRPNFeServiceEmissao.DAO(AValue: TRPNFeDAOFactory): TRPNFeServiceEmissao;
begin
  Result := Self;
  FDAO := AValue;
end;

function TRPNFeServiceEmissao.DAO: TRPNFeDAOFactory;
begin
  Result := FDAO;
end;

destructor TRPNFeServiceEmissao.Destroy;
begin
  FEmpresa.Free;
  FVenda.Free;
  FConfig.Free;
  FObservers.Free;
  inherited;
end;

function TRPNFeServiceEmissao.Empresa: TRPNFeEntityEmpresa;
begin
  Result := FEmpresa;
end;

function TRPNFeServiceEmissao.Execute: TRPNFeEntityNFeNotaEletronica;
begin
  // Carrega venda e configuracao (CONFIGURACAO.XML + certificado) FORA do
  // lock para encurtar o tempo com o emissor bloqueado.
  CarregarVenda;
  Configuracao;

  // O emissor (ACBr/FastReport) e compartilhado por todas as threads:
  // serializa emissao e impressao para nao colidirem (Abort/travamento).
  // CarregarEmpresa fica DENTRO do lock: a leitura de numero_nfce + o
  // incremento (DadosIde) precisam ser atomicos entre emissoes.
  EmissorLock.Enter;
  try
    try
      CarregarEmpresa;
      FComponents.Emissor.Configuracao(Configuracao)
        .Empresa(FEmpresa);
      ExecuteCommands;
      // Nota autorizada: dispara os observers (gravam chave/protocolo na venda
      // e VEN_SATSTATUS=23 no encerravenda). Em rejeicao o EnviarNota levanta
      // excecao e nem chega aqui.
      if Assigned(FNotaEletronica) and (not FNotaEletronica.Erro) then
        Notificar(FNotaEletronica);
      Result := FNotaEletronica;
      // A posse da entidade passa ao caller (que a libera): limpa a referencia
      // para nao ficar dangling em reuso do service.
      FNotaEletronica := nil;
    except
      on E: Exception do
      begin
        FComponents.Log.Write(E);
        raise;
      end;
    end;
  finally
    EmissorLock.Leave;
  end;
end;

procedure TRPNFeServiceEmissao.ExecuteCommands;
var
  LInvoker: TRPServiceEmissaoInvoker;
begin
  LInvoker := TRPServiceEmissaoInvoker.Create(Self);
  try
    LInvoker.AddCommand(TRPNFeServiceEmissaoCommandDadosIde.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandDadosEmit.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandDadosDest.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandItens.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandItensImpostoICMS.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandItensImpostoICMSUFDest.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandItensImpostoCOFINS.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandItensImpostoPIS.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandItensImpostoISSQN.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandItensANP.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandPagamentos.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandTotais.Create(Self))
      // Reforma Tributaria: IBS/CBS por item + totais, apos os totais de ICMS
      // (o vNFTot depende do ICMSTot.vNF ja consolidado).
      .AddCommand(TRPNFeServiceEmissaoCommandItensImpostoIBSCBS.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandResponsavelTecnico.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandAssinarXML.Create(Self))
      .AddCommand(TRPNFeServiceEmissaoCommandEnviarNota.Create(Self, Self.SetNotaEletronica));
    LInvoker.Execute;
  finally
    LInvoker.Free;
  end;
end;

function TRPNFeServiceEmissao.IdVenda(AValue: Integer): TRPNFeServiceEmissao;
begin
  Result := Self;
  FIdVenda := AValue;
end;

procedure TRPNFeServiceEmissao.Notificar(const ANotaEletronica: TRPNFeEntityNFeNotaEletronica);
var
  LObserver: TRPNFeServiceEmissaoObserver;
begin
  for LObserver in FObservers do
  begin
    Self.FComponents.Log.Write('Executando observer %s', [TObject(LObserver).ClassName]);
    LObserver.Execute(ANotaEletronica);
  end;
end;

procedure TRPNFeServiceEmissao.SetNotaEletronica(AValue: TRPNFeEntityNFeNotaEletronica);
begin
  FNotaEletronica := AValue;
end;

function TRPNFeServiceEmissao.Venda: TRPNFeEntityVenda;
begin
  Result := FVenda;
end;

{ TRPServiceEmissaoInvoker }

function TRPServiceEmissaoInvoker.AddCommand(
  AValue: TRPNFeServiceEmissaoCommand): TRPServiceEmissaoInvoker;
begin
  Result := Self;
  FCommands.Add(AValue);
end;

constructor TRPServiceEmissaoInvoker.Create(AParent: TRPNFeServiceEmissao);
begin
  FParent := AParent;
  FCommands := TObjectList<TRPNFeServiceEmissaoCommand>.Create;
end;

destructor TRPServiceEmissaoInvoker.Destroy;
begin
  FCommands.Free;
  inherited;
end;

procedure TRPServiceEmissaoInvoker.Execute;
var
  LCommand: TRPNFeServiceEmissaoCommand;
begin
  for LCommand in FCommands do
  begin
    FParent.Components.Log.Write('Executando command %s.', [LCommand.ClassName]);
    LCommand.Execute;
  end;
end;

{ TRPNFeServiceEmissaoCommand }

constructor TRPNFeServiceEmissaoCommand.Create(AParent: TRPNFeServiceEmissao);
begin
  FParent := AParent;
end;

procedure TRPNFeServiceEmissaoCommand.Log(ALog: string);
begin
  FParent.Components.Log.Write(ALog);
end;

procedure TRPNFeServiceEmissaoCommand.Log(ALog: string; const AArgs: array of const);
begin
  FParent.Components.Log.Write(ALog, AArgs);
end;

{ TRPNFeServiceEmissaoObserver }

constructor TRPNFeServiceEmissaoObserver.Create(AParent: TRPNFeServiceEmissao);
begin
  FParent := AParent;
end;

procedure TRPNFeServiceEmissaoObserver.Log(ALog: string; const AArgs: array of const);
begin
  FParent.Components.Log.Write(ALog, AArgs);
end;

procedure TRPNFeServiceEmissaoObserver.Log(ALog: string);
begin
  FParent.Components.Log.Write(ALog);
end;

end.
