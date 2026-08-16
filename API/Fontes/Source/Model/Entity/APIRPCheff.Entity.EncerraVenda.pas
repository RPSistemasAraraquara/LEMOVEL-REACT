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
    FcpfConsumidor  : string;
  public
    property idEncerraVenda : Integer  read FidEncerraVenda        write FidEncerraVenda;
    property idEmpresa      : Integer  read FidEmpresa             write FidEmpresa;
    property idVenda        : Integer  read FidVenda               write FidVenda;
    property valor          : Currency read Fvalor                 write Fvalor;
    property acrescimo      : Currency read Facrescimo             write Facrescimo;
    property desconto       : Currency read Fdesconto              write Fdesconto;
    property idFormaPgto    : Integer  read FidFormaPgto           write FidFormaPgto;
    // CPF/CNPJ do consumidor na nota (ven_cpfconsum) - a emissao da NFC-e le
    // daqui (coalesce com clientes.cli_004 no rp-nfe)
    property cpfConsumidor  : string   read FcpfConsumidor         write FcpfConsumidor;
  end;

implementation

end.
