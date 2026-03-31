unit APIRPCheff.Entity.EncerraVenda;

interface

type
  TAPIRPCheffEntityEncerraVenda = class
  private
    FidEmpresa      : Integer;
    FidVenda        : Integer;
    Fvalor          : Currency;
    Facrescimo      : Currency;
    Fdesconto       : Currency;
    FidFormaPgto    : Integer;
    FidEncerraVenda : Integer;
  public
    property idEncerraVenda : Integer  read FidEncerraVenda        write FidEncerraVenda;
    property idEmpresa      : Integer  read FidEmpresa             write FidEmpresa;
    property idVenda        : Integer  read FidVenda               write FidVenda;
    property valor          : Currency read Fvalor                 write Fvalor;
    property acrescimo      : Currency read Facrescimo             write Facrescimo;
    property desconto       : Currency read Fdesconto              write Fdesconto;
    property idFormaPgto    : Integer  read FidFormaPgto           write FidFormaPgto;
  end;

implementation

end.
