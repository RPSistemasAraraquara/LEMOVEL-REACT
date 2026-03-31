unit APIRPCheff.Entity.Caixa;

interface

uses
  APIRPCheff.Entity.Types;

type
  TAPIRPCheffEntityCaixa = class
  private
    FidCaixa      : Integer;
    FidEmpresa    : Integer;
    FdataAbertura : TDateTime;
    FvalorInicial : Currency;
    Fsituacao     : TRPCheffSituacao;
  public
    property idCaixa: Integer           read FidCaixa             write FidCaixa;
    property idEmpresa: Integer         read FidEmpresa           write FidEmpresa;
    property dataAbertura: TDateTime    read FdataAbertura        write FdataAbertura;
    property valorInicial: Currency     read FvalorInicial        write FvalorInicial;
    property situacao: TRPCheffSituacao read Fsituacao            write Fsituacao;
  end;

implementation

end.
