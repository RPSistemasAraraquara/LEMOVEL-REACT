unit APIRPCheff.Entity.VendaPagamentoAntecipado;

interface

uses
  System.SysUtils,
  APIRPCheff.Entity.Types,
  APIRPCheff.Entity.FormaPagamento;

type
  TAPIRPCheffEntityVendaPagamentoAntecipado = class
  private
    FidVenda                    : Integer;
    FidEmpresa                  : Integer;
    Fvalor                      : Currency;
    FidVendaPagamentoAntecipado : Integer;
    Fsituacao                   : TRPCheffSituacao;
    FdataHora                   : TDateTime;
    FidFormaPagamento           : Integer;
    FformaPagamento             : TAPIRPCheffEntityFormaPagamento;
    FIdCaixa                    : Integer;
    FIdCaixaItem                : Integer;
    FObservacao                 : String;
    FIdUsuarioLancamento        : Integer;
    FTaxaServico                : Boolean;
    FValorTaxaServico           : Currency;
    FValorProduto               : Currency;
    procedure SetFormaPagamento(
      const Value: TAPIRPCheffEntityFormaPagamento);
  public
    constructor Create;
    destructor Destroy; override;

    property idVendaPagamentoAntecipado     : Integer                         read FidVendaPagamentoAntecipado    write FidVendaPagamentoAntecipado;
    property idVenda                        : Integer                         read FidVenda                       write FidVenda;
    property idEmpresa                      : Integer                         read FidEmpresa                     write FidEmpresa;
    property dataHora                       : TDateTime                       read FdataHora                      write FdataHora;
    property valor                          : Currency                        read Fvalor                         write Fvalor;
    property situacao                       : TRPCheffSituacao                read Fsituacao                      write Fsituacao;
    property idFormaPagamento               : Integer                         read FidFormaPagamento              write FidFormaPagamento;
    property formaPagamento                 : TAPIRPCheffEntityFormaPagamento read FformaPagamento                write SetFormaPagamento;
    property IdCaixa                        : Integer                         read FIdCaixa                       write FIdCaixa;
    property IdCaixaItem                    : Integer                         read FIdCaixaItem                   write FIdCaixaItem;
    property Observacao                     : String                          read FObservacao                    write FObservacao;
    property IdUsuarioLancamento            : Integer                         read FIdUsuarioLancamento           write FIdUsuarioLancamento;
    property TaxaServico                    : Boolean                         read FTaxaServico                   write FTaxaServico;
    property ValorTaxaServico               : Currency                        read FValorTaxaServico              write FValorTaxaServico;
    property ValorProduto                   : Currency                        read FValorProduto                  write FValorProduto;

  end;

implementation

{ TAPIRPCheffEntityVendaPagamentoAntecipado }

constructor TAPIRPCheffEntityVendaPagamentoAntecipado.Create;
begin
  FformaPagamento := TAPIRPCheffEntityFormaPagamento.Create;
end;

destructor TAPIRPCheffEntityVendaPagamentoAntecipado.Destroy;
begin
   FreeAndNil(FformaPagamento);
  inherited;
end;

procedure TAPIRPCheffEntityVendaPagamentoAntecipado.SetFormaPagamento(const Value: TAPIRPCheffEntityFormaPagamento);
begin
  FreeAndNil(FformaPagamento);
  FformaPagamento := Value;
end;

end.
