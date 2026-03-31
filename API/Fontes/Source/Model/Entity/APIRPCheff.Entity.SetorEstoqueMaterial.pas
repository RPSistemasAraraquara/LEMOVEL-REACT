unit APIRPCheff.Entity.SetorEstoqueMaterial;

interface

type
  TAPIRPCheffEntitySetorEstoqueMaterial = class
  private
    FidMaterial : Integer;
    FidEmpresa  : Integer;
    FidSetor    : Integer;
    Fquantidade : Currency;
  public
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property idMaterial: Integer read FidMaterial write FidMaterial;
    property idSetor: Integer read FidSetor write FidSetor;
    property quantidade: Currency read Fquantidade write Fquantidade;
  end;

implementation

end.
