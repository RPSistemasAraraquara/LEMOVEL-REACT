unit APIRPCheff.Entity.VendaPrePago;

interface

type
  TAPIRPCheffEntityVendaPrePago = class
  private
    FId               : Integer;
    FIdVenda          : Integer;
    FIdEmpresa        : Integer;
    FIdFormaPagamento : Integer;
    FValor            : Currency;
    FData             : TDateTime;
  public
    property Id: Integer read FId write FId;
    property IdVenda: Integer read FIdVenda write FIdVenda;
    property IdEmpresa: Integer read FIdEmpresa write FIdEmpresa;
    property IdFormaPagamento: Integer read FIdFormaPagamento write FIdFormaPagamento;
    property Valor: Currency read FValor write FValor;
    property Data: TDateTime read FData write FData;
  end;

implementation

end.
