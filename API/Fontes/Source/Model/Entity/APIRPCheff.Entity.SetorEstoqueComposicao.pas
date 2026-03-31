unit APIRPCheff.Entity.SetorEstoqueComposicao;

interface

type
  TAPIRPCheffEntitySetorEstoqueComposicao = class
  private
    FidComposicao : Integer;
    FidSetor      : Integer;
    FidEmpresa    : Integer;
    Fquantidade   : Currency;
  public
    property idComposicao: Integer read FidComposicao write FidComposicao;
    property idSetor: Integer read FidSetor write FidSetor;
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property quantidade: Currency read Fquantidade write Fquantidade;
  end;

implementation

end.
