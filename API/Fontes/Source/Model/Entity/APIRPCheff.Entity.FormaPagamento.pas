unit APIRPCheff.Entity.FormaPagamento;

interface

uses
  System.SysUtils;

type
  TAPIRPCheffEntityFormaPagamento = class
  private
    Fdescricao                        : string;
    Fcodigo                           : Integer;
    FsfiCodigo                        : Integer;
    FidEmpresa                        : Integer;
    Fcortesia                         : Boolean;
    FutilizaControleCartao            : Boolean;
    FidContaCorrente                  : Integer;
    FtaxaCartao                       : Currency;
    FprazoCartao                      : Integer;
    FutilizaPagamentoOnline           : Boolean;
    FPermitePagamentoParceladoOnline  : Boolean;
    FJuros                            : Double;
    FemiteFiscal                      : Boolean;
    FExibirFormaPgtoAPP               : Boolean;
    function GetSfiDescricao          : string;
  public
    procedure Assign(ASource: TAPIRPCheffEntityFormaPagamento);
    function Dinheiro: Boolean;

    property codigo                         : Integer  read Fcodigo                           write Fcodigo;
    property idEmpresa                      : Integer  read FidEmpresa                        write FidEmpresa;
    property descricao                      : string   read Fdescricao                        write Fdescricao;
    property sfiCodigo                      : Integer  read FsfiCodigo                        write FsfiCodigo;
    property sfiDescricao                   : string   read GetSfiDescricao;
    property cortesia                       : Boolean  read Fcortesia                         write Fcortesia;
    property utilizaControleCartao          : Boolean  read FutilizaControleCartao            write FutilizaControleCartao;
    property idContaCorrente                : Integer  read FidContaCorrente                  write FidContaCorrente;
    property taxaCartao                     : Currency read FtaxaCartao                       write FtaxaCartao;
    property prazoCartao                    : Integer  read FprazoCartao                      write FprazoCartao;
    property utilizaPagamentoOnline         : Boolean  read FutilizaPagamentoOnline           write FutilizaPagamentoOnline;
    property PermitePagamentoParceladoOnline: Boolean  read FPermitePagamentoParceladoOnline  write FPermitePagamentoParceladoOnline;
    property Juros                          : Double   read FJuros                            write FJuros;
    property emiteFiscal                    : Boolean  read FemiteFiscal                      write FemiteFiscal;
    property ExibirFormaPgtoAPP             : Boolean read FExibirFormaPgtoAPP                write FExibirFormaPgtoAPP;
  end;

implementation

{ TAPIRPCheffEntityFormaPagamento }

procedure TAPIRPCheffEntityFormaPagamento.Assign( ASource: TAPIRPCheffEntityFormaPagamento);
begin
  Fcodigo                             := ASource.codigo;
  FidEmpresa                          := ASource.idEmpresa;
  Fdescricao                          := ASource.descricao;
  FsfiCodigo                          := ASource.sfiCodigo;
  Fcortesia                           := ASource.cortesia;
  FutilizaControleCartao              := ASource.utilizaControleCartao;
  FidContaCorrente                    := ASource.idContaCorrente;
  FtaxaCartao                         := ASource.taxaCartao;
  FprazoCartao                        := ASource.prazoCartao;
  FutilizaPagamentoOnline             := ASource.utilizaPagamentoOnline;
  FPermitePagamentoParceladoOnline    := ASource.PermitePagamentoParceladoOnline;
  FJuros                              := ASource.Juros;
  FExibirFormaPgtoAPP                 := ASource.ExibirFormaPgtoAPP;
end;

function TAPIRPCheffEntityFormaPagamento.Dinheiro: Boolean;
begin
  Result := FsfiCodigo = 1;
end;

function TAPIRPCheffEntityFormaPagamento.GetSfiDescricao: string;
begin
  Result := 'Outras';
  if sfiCodigo = 1 then
    Result := 'Dinheiro'
  else
  if sfiCodigo = 2 then
    Result := 'Cheque'
  else
  if sfiCodigo = 3 then
    Result := 'cr'#233'dito'
  else
  if sfiCodigo = 4 then
    Result := 'd'#233'bito'
  else
  if sfiCodigo = 11 then
    Result := 'Refei'#231#227'o'
  else
  if sfiCodigo = 17 then
    Result := 'Pix';
end;

end.
