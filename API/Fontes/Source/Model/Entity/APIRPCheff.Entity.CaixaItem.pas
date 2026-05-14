unit APIRPCheff.Entity.CaixaItem;

interface

type
  TAPIRPCheffEntityCaixaItem = class
  private
    FidEmpresa        : Integer;
    FidCaixa          : Integer;
    Fitem             : Integer;
    FtipoMovimento    : string;
    Fvalor            : Currency;
    FidFormaPgto      : Integer;
    FidVenda          : Integer;
    FitemEncerraVenda : Integer;
    FidEncerraVenda   : Integer;
    Fclassificacao    : string;
    Fantecipado       : Boolean;
    Fobservacao       : string;
  public
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property idCaixa: Integer read FidCaixa write FidCaixa;
    property item: Integer read Fitem write Fitem;
    property tipoMovimento: string read FtipoMovimento write FtipoMovimento;
    property valor: Currency read Fvalor write Fvalor;
    property idFormaPgto: Integer read FidFormaPgto write FidFormaPgto;
    property idVenda: Integer read FidVenda write FidVenda;
    property itemEncerraVenda: Integer read FitemEncerraVenda write FitemEncerraVenda;
    property idEncerraVenda: Integer read FidEncerraVenda write FidEncerraVenda;
    property classificacao: string read Fclassificacao write Fclassificacao;
    property antecipado: Boolean read Fantecipado write Fantecipado;
    property observacao: string read Fobservacao write Fobservacao;
  end;

implementation

end.
