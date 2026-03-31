unit APIRPCheff.Entity.Venda;

interface

uses
  APIRPCheff.Entity.Types,
  APIRPCheff.Entity.Cliente,
  APIRPCheff.Entity.FormaPagamento,
  APIRPCheff.Entity.VendaItem,
  GBSwagger.Model.Attributes,
  System.Math,
  System.SysUtils,
  System.Generics.Collections;

type
  TAPIRPCheffEntityVenda = class
  private
    FidEmpresa               : Integer;
    FidVenda                 : Integer;
    Fdata                    : TDateTime;
    FidCliente               : Integer;
    Fsituacao                : TRPCheffSituacaoVenda;
    FidUsuario               : Integer;
    FtipoVenda               : TRPCheffTipoVenda;
    FterminalAbertura        : string;
    FidCaixa                 : Integer;
    FdataAbertura            : TDateTime;
    FnumeroMesa              : Integer;
    FnumeroComanda           : Integer;
    FnomeMesaComanda         : string;
    FnumeroCouvertFeminino   : Integer;
    FnumeroPessoas           : Integer;
    FnumeroCouvertMasculino  : Integer;
    FimprimirPreFechamento   : Boolean;
    Fvalor                   : Currency;
    FvalorCouvertMasculino   : Currency;
    FvalorCouvertFeminino    : Currency;
    FvalorTaxaServico        : Currency;
    FnumeroCupom             : Integer;
    FvalorEntrada            : Currency;

    FtaxaCartao              : Currency;
    Fcliente                 : TAPIRPCheffEntityCliente;
    FtotalPrePago            : Currency;
    Fitens                   : TObjectList<TAPIRPCheffEntityVendaItem>;
    FidUsuarioPreFechamento  : Integer;
    FCobrarTaxaGarcom        :Boolean;
    FchaveEletronica: string;
    function GetValorTotal   : Currency;
    function GetTotalCredito : Currency;
  public
    constructor Create;
    destructor Destroy; override;

    function DescricaoMesaComanda : string;
    function NumeroCouvert     : Integer;
    function ValorCouvert      : Currency;
    function ValorPorPessoa    : Currency;
    function VendaPrePaga      : Boolean;
    function TotalItens        : Currency;

    property idEmpresa              : Integer read FidEmpresa write FidEmpresa;
    property idVenda                : Integer read FidVenda write FidVenda;
    property data                   : TDateTime read Fdata write Fdata;
    property dataAbertura           : TDateTime read FdataAbertura write FdataAbertura;
    property valor                  : Currency read Fvalor write Fvalor;
    property idCliente              : Integer read FidCliente write FidCliente;
    property situacao               : TRPCheffSituacaoVenda read Fsituacao write Fsituacao;
    property idUsuario              : Integer read FidUsuario write FidUsuario;
    property idUsuarioPreFechamento : Integer read FidUsuarioPreFechamento write FidUsuarioPreFechamento;
    property tipoVenda              : TRPCheffTipoVenda read FtipoVenda write FtipoVenda;
    property terminalAbertura       : string read FterminalAbertura write FterminalAbertura;
    property idCaixa                : Integer read FidCaixa write FidCaixa;
    property numeroMesa             : Integer read FnumeroMesa write FnumeroMesa;
    property numeroComanda          : Integer read FnumeroComanda write FnumeroComanda;
    property nomeMesaComanda        : string read FnomeMesaComanda write FnomeMesaComanda;
    property numeroCupom            : Integer read FnumeroCupom write FnumeroCupom;
    property numeroPessoas          : Integer read FnumeroPessoas write FnumeroPessoas;
    property numeroCouvertMasculino : Integer read FnumeroCouvertMasculino write FnumeroCouvertMasculino;
    property numeroCouvertFeminino  : Integer read FnumeroCouvertFeminino write FnumeroCouvertFeminino;
    property imprimirPreFechamento  : Boolean read FimprimirPreFechamento write FimprimirPreFechamento;

    property taxaCartao             : Currency read FtaxaCartao write FtaxaCartao;
    property totalPrePago           : Currency read FtotalPrePago write FtotalPrePago;
    property valorCouvertMasculino  : Currency read FvalorCouvertMasculino write FvalorCouvertMasculino;
    property valorCouvertFeminino   : Currency read FvalorCouvertFeminino write FvalorCouvertFeminino;
    property valorTaxaServico       : Currency read FvalorTaxaServico write FvalorTaxaServico;
    property valorEntrada           : Currency read FvalorEntrada write FvalorEntrada;
    property valorTotal             : Currency read GetValorTotal;
    property totalCredito           : Currency read GetTotalCredito;
    property cliente                : TAPIRPCheffEntityCliente read Fcliente write Fcliente;
    property itens                  : TObjectList<TAPIRPCheffEntityVendaItem> read Fitens write Fitens;
    property CobrarTaxaGarcom       : boolean read FCobrarTaxaGarcom write FCobrarTaxaGarcom;
    property chaveEletronica: string read FchaveEletronica write FchaveEletronica;

  end;

  TAPIRPCheffEntityVendaPatchCouvert = class
  private
    FnumeroPessoas: Integer;
    FnumeroCouvertFeminino: Integer;
    FnumeroCouvertMasculino: Integer;
    FidEmpresa: Integer;
    FidVenda: Integer;
  public
    function NumeroCouvert: Integer;

    [SwagIgnore]
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;

    [SwagIgnore]
    property idVenda: Integer read FidVenda write FidVenda;

    property numeroPessoas: Integer read FnumeroPessoas write FnumeroPessoas;
    property numeroCouvertFeminino: Integer read FnumeroCouvertFeminino write FnumeroCouvertFeminino;
    property numeroCouvertMasculino: Integer read FnumeroCouvertMasculino write FnumeroCouvertMasculino;
  end;

  TAPIRPCheffEntityVendaPatchNomeMesaComanda = class
  private
    Fnome: string;
    FidEmpresa: Integer;
    FidVenda: Integer;
  public
    [SwagIgnore]
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;

    [SwagIgnore]
    property idVenda: Integer read FidVenda write FidVenda;
    property nome: string read Fnome write Fnome;
  end;

  TAPIRPCheffEntityVendaPatchPreFechamento = class(TAPIRPCheffEntityVendaPatchCouvert)
  private
    FidUsuario: Integer;
    FimprimirPreFechamentoMobile: Boolean;
    FpreFechamentoMobileImpressaoInterna: Boolean;
  public
    property idUsuario: Integer read FidUsuario write FidUsuario;
    property imprimirPreFechamentoMobile: Boolean read FimprimirPreFechamentoMobile write FimprimirPreFechamentoMobile;
    property preFechamentoMobileImpressaoInterna: Boolean read FpreFechamentoMobileImpressaoInterna write FpreFechamentoMobileImpressaoInterna;
  end;

  TAPIRPCheffEntityVendaPostAbertura = class
  private
    FterminalAbertura: string;
    FidEmpresa: Integer;
    FidMesaComanda: Integer;
    FnomeMesaComanda: string;
  public
    [SwagIgnore]
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    [SwagIgnore]
    property idMesaComanda: Integer read FidMesaComanda write FidMesaComanda;
    property terminalAbertura: string read FterminalAbertura write FterminalAbertura;
    property nomeMesaComanda: string read FnomeMesaComanda write FnomeMesaComanda;
  end;

  TAPIRPCheffEntityVendaPostFechamentoPagamento = class
  private
    FidFormaPgto: Integer;
    Fvalor: Currency;
    FformaPagamento: TAPIRPCheffEntityFormaPagamento;
  public
    constructor Create;
    destructor Destroy; override;

    property idFormaPgto: Integer read FidFormaPgto write FidFormaPgto;
    property valor: Currency read Fvalor write Fvalor;

    [SwagIgnore]
    property formaPagamento: TAPIRPCheffEntityFormaPagamento read FformaPagamento;
  end;

  TAPIRPCheffEntityVendaPostFechamento = class
  private
    FidEmpresa                       : Integer;
    FidVenda                     : Integer;
    FidUsuario                   : Integer;
    Fpagamentos                  : TObjectList<TAPIRPCheffEntityVendaPostFechamentoPagamento>;
    FnumeroCouvertMasculino      : Integer;
    FnumeroCouvertFeminino       : Integer;
    FvalorDesconto               : Currency;
    FtipoDesconto                : TRPCheffTipoDesconto;
    FimprimirPreFechamentoMobile : Boolean;
    FimpressoraInterna           : Boolean;
    FvalorTaxaServico            : Currency;
    FCobrarTaxaGarcom            : Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function ImprimirMobile              : Boolean;
    function VisualizarFechamento    : Boolean;
    function ValorPagamento          : Currency;
    function ValorPagoEmDinheiro     : Currency;
    function PossuiCortesia          : Boolean;
    function PossuiNaoCortesia       : Boolean;
    function PossuiPagamentoDinheiro : Boolean;
    procedure AddPagamento;

    [SwagIgnore]
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    [SwagIgnore]
    property idVenda: Integer read FidVenda write FidVenda;
    property idUsuario: Integer read FidUsuario write FidUsuario;
    property numeroCouvertMasculino: Integer read FnumeroCouvertMasculino write FnumeroCouvertMasculino;
    property numeroCouvertFeminino: Integer read FnumeroCouvertFeminino write FnumeroCouvertFeminino;
    property tipoDesconto: TRPCheffTipoDesconto read FtipoDesconto write FtipoDesconto default tdValor;
    property valorDesconto: Currency read FvalorDesconto write FvalorDesconto;
    property imprimirPreFechamentoMobile: Boolean read FimprimirPreFechamentoMobile write FimprimirPreFechamentoMobile;
    property valorTaxaServico: Currency read FvalorTaxaServico write FvalorTaxaServico;
    property impressoraInterna: Boolean read FimpressoraInterna write FimpressoraInterna;
    property pagamentos: TObjectList<TAPIRPCheffEntityVendaPostFechamentoPagamento> read Fpagamentos write Fpagamentos;
    property CobrarTaxaGarcom: boolean read FCobrarTaxaGarcom write FCobrarTaxaGarcom;

  end;

implementation

{ TAPIRPCheffEntityVendaPatchCouvert }

function TAPIRPCheffEntityVendaPatchCouvert.NumeroCouvert: Integer;
begin
  Result := FnumeroCouvertFeminino + FnumeroCouvertMasculino;
end;

{ TAPIRPCheffEntityVenda }

constructor TAPIRPCheffEntityVenda.Create;
begin
  Fsituacao := svPendente;
  FtipoVenda := tvMesa;
  Fcliente := TAPIRPCheffEntityCliente.Create;
  Fitens := TObjectList<TAPIRPCheffEntityVendaItem>.Create;
end;

function TAPIRPCheffEntityVenda.DescricaoMesaComanda: string;
begin
  if FnumeroMesa > 0 then
    Result := 'Mesa ' + FnumeroMesa.ToString
  else
  if FnumeroComanda > 0 then
    Result := 'Comanda ' + FnumeroComanda.ToString;

  if FnomeMesaComanda <> EmptyStr then
    Result := Format('%s (%s)', [Result, FnomeMesaComanda]);
end;

destructor TAPIRPCheffEntityVenda.Destroy;
begin
  FreeAndNil(Fcliente);
  FreeAndNil(Fitens);
  inherited;
end;

function TAPIRPCheffEntityVenda.GetTotalCredito: Currency;
begin
  Result := FtotalPrePago - Fvalor - FvalorEntrada;
end;

function TAPIRPCheffEntityVenda.GetValorTotal: Currency;
begin
  Result := Fvalor;
  if Fsituacao <> svFinalizada then
  begin
    Result := RoundTo(Fvalor + FvalorCouvertFeminino + FvalorCouvertMasculino + FvalorTaxaServico, -2);
    if Fcliente.id > 0 then
      Result := RoundTo(Fvalor + FvalorEntrada, -2);
  end;
end;

function TAPIRPCheffEntityVenda.NumeroCouvert: Integer;
begin
  Result := FnumeroCouvertFeminino + FnumeroCouvertMasculino;
end;

function TAPIRPCheffEntityVenda.TotalItens: Currency;
begin
  Result := 0;

  for var LItem in Fitens do
  begin
    if (Litem.fracoes.Count >0) then
     Result := Result + LItem.TotalFracoes
     else
     Result := Result + LItem.valorTotal;
  end;
end;

function TAPIRPCheffEntityVenda.ValorCouvert: Currency;
begin
  Result := FvalorCouvertMasculino + FvalorCouvertFeminino;
end;

function TAPIRPCheffEntityVenda.ValorPorPessoa: Currency;
begin
  Result := SimpleRoundTo(valorTotal / FnumeroPessoas, -2);
end;

function TAPIRPCheffEntityVenda.VendaPrePaga: Boolean;
begin
  Result := FtotalPrePago > 0;
end;

{ TAPIRPCheffEntityVendaPostFechamento }

procedure TAPIRPCheffEntityVendaPostFechamento.AddPagamento;
begin
  Fpagamentos.Add(TAPIRPCheffEntityVendaPostFechamentoPagamento.Create);
end;

constructor TAPIRPCheffEntityVendaPostFechamento.Create;
begin
  Fpagamentos := TObjectList<TAPIRPCheffEntityVendaPostFechamentoPagamento>.Create;
  FimprimirPreFechamentoMobile := False;
  FimpressoraInterna := False;
end;

destructor TAPIRPCheffEntityVendaPostFechamento.Destroy;
begin
  FreeAndNil(Fpagamentos);
  inherited;
end;

function TAPIRPCheffEntityVendaPostFechamento.ImprimirMobile: Boolean;
begin
  Result := (FimprimirPreFechamentoMobile) or (FimpressoraInterna);
end;

function TAPIRPCheffEntityVendaPostFechamento.PossuiCortesia: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Pred(Fpagamentos.Count) do
  begin
    if Fpagamentos[I].formaPagamento.cortesia then
      Exit(True);
  end;
end;

function TAPIRPCheffEntityVendaPostFechamento.PossuiNaoCortesia: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Pred(Fpagamentos.Count) do
  begin
    if not Fpagamentos[I].formaPagamento.cortesia then
      Exit(True);
  end;
end;

function TAPIRPCheffEntityVendaPostFechamento.PossuiPagamentoDinheiro: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Pred(Fpagamentos.Count) do
  begin
    if Fpagamentos[I].formaPagamento.Dinheiro then
      Exit(True);
  end;
end;

function TAPIRPCheffEntityVendaPostFechamento.ValorPagamento: Currency;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Pred(Fpagamentos.Count) do
    Result := Result + Fpagamentos[I].valor;
end;

function TAPIRPCheffEntityVendaPostFechamento.ValorPagoEmDinheiro: Currency;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Pred(Fpagamentos.Count) do
    if Fpagamentos[I].formaPagamento.Dinheiro then
      Result := Result + Fpagamentos[I].valor;
end;

function TAPIRPCheffEntityVendaPostFechamento.VisualizarFechamento: Boolean;
begin
  Result := (FimprimirPreFechamentoMobile) or (FimpressoraInterna);
end;

{ TAPIRPCheffEntityVendaPostFechamentoPagamento }

constructor TAPIRPCheffEntityVendaPostFechamentoPagamento.Create;
begin
  FformaPagamento := TAPIRPCheffEntityFormaPagamento.Create;
end;

destructor TAPIRPCheffEntityVendaPostFechamentoPagamento.Destroy;
begin
  FreeAndNil(FformaPagamento);
  inherited;
end;

end.
