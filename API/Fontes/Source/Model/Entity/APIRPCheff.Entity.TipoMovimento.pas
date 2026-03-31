unit APIRPCheff.Entity.TipoMovimento;

interface

uses
  APIRPCheff.Entity.Types;

type
  TAPIRPCheffEntityTipoMovimento = class
  private
    FidEmpresa           : Integer;
    Ftipo                : string;
    FdataEmissao         : TDate;
    Fvalor               : Currency;
    Fdocumento           : string;
    Fobservacao          : string;
    Fcompensado          : Integer;
    FidUsuarioLancamento : Integer;
    FidUsuarioBaixa      : Integer;
    FidContaCorrente     : Integer;
    Fsituacao            : TRPCheffSituacao;
    FidVenda             : Integer;
    FidEncerraVenda      : Integer;
    FitemEncerraVenda    : Integer;
  public
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property tipo: string read Ftipo write Ftipo;
    property dataEmissao: TDate read FdataEmissao write FdataEmissao;
    property valor: Currency read Fvalor write Fvalor;
    property documento: string read Fdocumento write Fdocumento;
    property observacao: string read Fobservacao write Fobservacao;
    property compensado: Integer read Fcompensado write Fcompensado;
    property idUsuarioLancamento: Integer read FidUsuarioLancamento write FidUsuarioLancamento;
    property idUsuarioBaixa: Integer read FidUsuarioBaixa write FidUsuarioBaixa;
    property idContaCorrente: Integer read FidContaCorrente write FidContaCorrente;
    property situacao: TRPCheffSituacao read Fsituacao write Fsituacao;
    property idVenda: Integer read FidVenda write FidVenda;
    property idEncerraVenda: Integer read FidEncerraVenda write FidEncerraVenda;
    property itemEncerraVenda: Integer read FitemEncerraVenda write FitemEncerraVenda;
  end;

implementation

end.
