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
    raise Exception.CreateFmt('Empresa %d não encontrada.', [FVenda.IdEmpresa]);

  FComponents.Log.Write('Carregada empresa %s.', [FEmpresa.Nome]);
end;

procedure TRPNFeServiceEmissao.CarregarVenda;
begin
  FComponents.Log.Write('Carregando venda pelo id %d', [FIdVenda]);
  FreeAndNil(FVenda);
  FVenda := FDAO.VendaDAO.Buscar(FIdVenda);
  if not Assigned(FVenda) then
    raise Exception.CreateFmt('Venda %d não encontrada ou não encerrada.', [FIdVenda]);

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
    FConfig := FDAO.ConfiguracaoDAO.Carregar(FConfigucaoFileName);
  Result := FConfig;
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
  try
    CarregarVenda;
    CarregarEmpresa;
    FComponents.Emissor.Configuracao(Configuracao)
      .Empresa(FEmpresa);
    ExecuteCommands;
    Result := FNotaEletronica;
  except
    on E: Exception do
    begin
      FComponents.Log.Write(E);
      raise;
    end;
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
