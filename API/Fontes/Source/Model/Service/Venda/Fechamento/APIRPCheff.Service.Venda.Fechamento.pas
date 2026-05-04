unit APIRPCheff.Service.Venda.Fechamento;

interface

uses
  APIRPCheff.Service.Venda.Consulta,
  APIRPCheff.Components,
  APIRPCheff.DAO.Factory,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  System.Math,
  System.Generics.Collections,
  System.DateUtils,
  System.SysUtils;

type

  TAPIRPCheffServiceVendaFechamento = class
  private
    FEmpresa              : TAPIRPCheffEntityEmpresa;
    FIdEncerraVenda       : Integer;
    FFechamento           : TAPIRPCheffEntityVendaPostFechamento;
    FVenda                : TAPIRPCheffEntityVenda;
    FVendaItens           : TObjectList<TAPIRPCheffEntityVendaItem>;
    FConfiguracao         : TAPIRPCheffEntityConfiguracaoMesa;
    FComponents           : TAPIRPCheffComponents;
    FDAO                  : TAPIRPCheffDAOFactory;

    procedure InicializarValores;
    procedure CarregarVenda;
    procedure ValidarTotalDeItens;

    procedure ExecuteCommands;
  public
    destructor Destroy; override;

    function Components(AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaFechamento; overload;
    function Components: TAPIRPCheffComponents; overload;
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaFechamento; overload;
    function DAO: TAPIRPCheffDAOFactory; overload;

    function Empresa: TAPIRPCheffEntityEmpresa;
    function Venda: TAPIRPCheffEntityVenda;
    function VendaItens: TObjectList<TAPIRPCheffEntityVendaItem>;
    function ConfiguracaoMesa: TAPIRPCheffEntityConfiguracaoMesa;

    function IdEncerraVenda(AValue: Integer): TAPIRPCheffServiceVendaFechamento; overload;
    function IdEncerraVenda: Integer; overload;

    function Fechamento(AValue: TAPIRPCheffEntityVendaPostFechamento): TAPIRPCheffServiceVendaFechamento; overload;
    function Fechamento: TAPIRPCheffEntityVendaPostFechamento; overload;
    procedure Execute;
  end;

implementation

uses
  APIRPCheff.Context.Venda.Fechamento,
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Service.Venda.Fechamento.Command.ProximoIdCaixaItem,
  APIRPCheff.Service.Venda.Fechamento.Command.GravarImpressao,
  APIRPCheff.Service.Venda.Fechamento.Command.SalvarPagamentos,
  APIRPCheff.Service.Venda.Fechamento.Command.ValidarFechamento,
  APIRPCheff.Service.Venda.Fechamento.Command.AtualizarCouvert,
  APIRPCheff.Service.Venda.Fechamento.Command.InserirEncerraVenda,
  APIRPCheff.Service.Venda.Fechamento.Command.AtualizaCupom,
  APIRPCheff.Service.Venda.Fechamento.Command.AtualizarItens,
  APIRPCheff.Service.Venda.Fechamento.Command.InserirMovimentoEstoque,
  APIRPCheff.Service.Venda.Fechamento.Command.InserirMovimentoEstoqueOpcional,
  APIRPCheff.Service.Venda.Fechamento.Command.AtualizarSetorEstoque,
  APIRPCheff.Service.Venda.Fechamento.Command.MovimentaComposicao,
  APIRPCheff.Service.Venda.Fechamento.Command.FinalizarVenda,
  APIRPCheff.Service.Venda.Fechamento.Command.EmitirNota;

{ TAPIRPCheffServiceVendaFechamento }

procedure TAPIRPCheffServiceVendaFechamento.CarregarVenda;
var
  LServiceConsultaVenda: TAPIRPCheffServiceVendaConsulta;
begin
  FreeAndNil(FVenda);
  LServiceConsultaVenda := TAPIRPCheffServiceVendaConsulta.Create;
  try
    LServiceConsultaVenda.DAO(FDAO).AplicarTaxaServico(False);
    FVenda     := LServiceConsultaVenda.Buscar(FFechamento.idVenda, False);
    if not Assigned(FVenda) then
      raise Exception.CreateFmt('Venda %d n'#227'o encontrada.', [FFechamento.idVenda]);

    if FVenda.situacao = svFinalizada then
      raise Exception.CreateFmt('Venda %d j'#225' est'#225' finalizada.', [FFechamento.idVenda]);

    FreeAndNil(FVendaItens);

    FVenda.valorTaxaServico := 0;
    if FFechamento.CobrarTaxaGarcom then
      FVenda.valorTaxaServico := FFechamento.valorTaxaServico;

    FreeAndNil(FVenda.itens);
    FVenda.itens              := FDAO.VendaItemDAO.Listar(FFechamento.idVenda, siOK);
    FVendaItens             := FDAO.VendaItemDAO.ListarVendasAgrupadosProdutos(FFechamento.idVenda);
    ValidarTotalDeItens;
  finally
    FreeAndNil(LServiceConsultaVenda);
  end;
end;

function TAPIRPCheffServiceVendaFechamento.Components: TAPIRPCheffComponents;
begin
  Result := FComponents;
end;

function TAPIRPCheffServiceVendaFechamento.Components(AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaFechamento;
begin
  Result      := Self;
  FComponents := AValue;
end;

function TAPIRPCheffServiceVendaFechamento.ConfiguracaoMesa: TAPIRPCheffEntityConfiguracaoMesa;
begin
  if not Assigned(FConfiguracao) then
    FConfiguracao := FDAO.ConfiguracaoMesaDAO.Buscar(FFechamento.idEmpresa);
  Result := FConfiguracao;
  if not Assigned(FConfiguracao) then
    raise Exception.Create('Configura'#231#227'o mesa n'#227'o encontrada.');
end;

function TAPIRPCheffServiceVendaFechamento.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaFechamento;
begin
  Result := Self;
  FDAO := AValue;
end;

function TAPIRPCheffServiceVendaFechamento.DAO: TAPIRPCheffDAOFactory;
begin
  Result := FDAO;
end;

destructor TAPIRPCheffServiceVendaFechamento.Destroy;
begin
  FreeAndNil(FConfiguracao);
  FreeAndNil(FEmpresa);
  FreeAndNil(FVenda);
  FreeAndNil(FVendaItens);
  inherited;
end;

function TAPIRPCheffServiceVendaFechamento.Empresa: TAPIRPCheffEntityEmpresa;
begin
  if (not Assigned(FEmpresa)) or (FEmpresa.idEmpresa <> FFechamento.idEmpresa) then
  begin
    FreeAndNil(FEmpresa);
    FEmpresa := FDAO.EmpresaDAO.Busca;
  end;
  Result := FEmpresa;
end;

procedure TAPIRPCheffServiceVendaFechamento.Execute;
begin
  InicializarValores;
  CarregarVenda;
  FDAO.StartTransaction;
  try
    ExecuteCommands;
    FDAO.Commit;
  except
    FDAO.Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffServiceVendaFechamento.ExecuteCommands;
var
  LInvoker: TAPIRPCheffServiceVendaFechamentoInvoker;
  FContext: TAPIRPCheffContextVendaFechamento;
begin
  LInvoker := TAPIRPCheffServiceVendaFechamentoInvoker.Create;
  try
    LInvoker
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandProximoIdCaixaItem.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandGravarImpressao.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandAtualizarCouvert.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandValidarFechamento.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandInserirEncerraVenda.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentos.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandAtualizaCupom.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoqueOpcional.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandInserirMovimentoEstoque.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandAtualizarSetorEstoque.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandMovimentaComposicao.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandFinalizarVenda.Create(Self, @FContext))
      .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandAtualizarItens.Create(Self, @FContext));
     // .AddCommand(TAPIRPCheffServiceVendaFechamentoCommandEmitirNota.Create(Self, @FContext));
    LInvoker.Execute(FFechamento);
  finally
    FreeAndNil(LInvoker);
  end;
end;

function TAPIRPCheffServiceVendaFechamento.Fechamento: TAPIRPCheffEntityVendaPostFechamento;
begin
  Result := FFechamento;
end;

function TAPIRPCheffServiceVendaFechamento.Fechamento( AValue: TAPIRPCheffEntityVendaPostFechamento): TAPIRPCheffServiceVendaFechamento;
begin
  Result      := Self;
  FFechamento := AValue;
end;

function TAPIRPCheffServiceVendaFechamento.IdEncerraVenda: Integer;
begin
  Result := FIdEncerraVenda;
end;

function TAPIRPCheffServiceVendaFechamento.IdEncerraVenda(AValue: Integer): TAPIRPCheffServiceVendaFechamento;
begin
  Result := Self;
  FIdEncerraVenda := AValue;
end;

procedure TAPIRPCheffServiceVendaFechamento.InicializarValores;
begin
  FIdEncerraVenda := 0;
end;

procedure TAPIRPCheffServiceVendaFechamento.ValidarTotalDeItens;
var
  LTotalItens: Integer;
  I: Integer;
begin
  LTotalItens := 0;
  for I := 0 to Pred(FVendaItens.Count) do
  begin
    if FVendaItens[I].situacao = siOK then
      LTotalItens := LTotalItens + 1;
  end;

  if LTotalItens <= 0 then
    raise Exception.Create('Venda n'#227'o possui itens ativos.');
end;

function TAPIRPCheffServiceVendaFechamento.Venda: TAPIRPCheffEntityVenda;
begin
  Result := FVenda;
end;

function TAPIRPCheffServiceVendaFechamento.VendaItens: TObjectList<TAPIRPCheffEntityVendaItem>;
begin
  Result := FVendaItens;
end;

end.
