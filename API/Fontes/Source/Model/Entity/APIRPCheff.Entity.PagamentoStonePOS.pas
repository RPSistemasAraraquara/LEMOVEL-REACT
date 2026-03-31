unit APIRPCheff.Entity.PagamentoStonePOS;

interface

uses
  APIRPCheff.Entity.Types;

type
  TAPIRPCheffEntityPagamentoStonePOS = class
  private
    Fid                : Integer;
    FIdEmpresa         : Integer;
    FIdVenda           : Integer;
    FValorPago         : Currency;
    FCodigoAutotizacao : string;
    FDataHoraVenda     : TDateTime;
    FBandeira          : string;
    FParcelas          : Integer;
    FTerminal          : string;

  public
    property id:Integer read Fid write Fid;
    property IdEmpresa: Integer read FIdEmpresa write FIdEmpresa;
    property IdVenda: Integer read FIdVenda write FIdVenda;
    property ValorPago: Currency read FValorPago write FValorPago;
    property CodigoAutotizacao  : string   read FCodigoAutotizacao write FCodigoAutotizacao;
    property DataHoraVenda: TDateTime read FDataHoraVenda write FDataHoraVenda;
    property Bandeira: string read FBandeira write FBandeira;
    property Parcelas: Integer read FParcelas write FParcelas;
    property Terminal : string   read FTerminal write FTerminal;
  end;

implementation

end.
