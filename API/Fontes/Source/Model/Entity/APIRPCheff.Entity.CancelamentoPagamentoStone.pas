unit APIRPCheff.Entity.CancelamentoPagamentoStone;

interface

uses
  APIRPCheff.Entity.Types;

type
  TAPIRPCheffEntityCancelamentoPagamentoStone = class
  private
    Fid                   : Integer;
    FidEmpresa            : Integer;
    FIdVenda              : Integer;
    FDataHoraCancelamento :TDateTime;
    FValorCancelamento    : Currency;
    FCodigoAutorizacao    : string;
    FTerminal             :string;
  public
  property Id:  Integer  read Fid write Fid;
  property IdEmpresa:Integer  read FidEmpresa write FidEmpresa;
  property IdVenda:Integer read FIdVenda write FIdVenda;
  property  ValorCancelamento:Currency read FValorCancelamento write FValorCancelamento;
  property DataHoraCancelamento:TDateTime read FDataHoraCancelamento write FDataHoraCancelamento;
  property CodigoAutorizacao:string  read FCodigoAutorizacao write FCodigoAutorizacao;
  property Terminal:string read FTerminal write FTerminal;


  end;

implementation

{ TAPIRPCheffEntityCancelamentoPagamentoStone }

end.
