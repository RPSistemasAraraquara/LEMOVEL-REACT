unit APIRPCheff.Entity.Composicao;

interface

type
  TAPIRPCheffEntityComposicao = class
  private
    FidComposicao         : Integer;
    Fdescricao            : string;
    FvalorCusto           : Currency;
    FestoqueMinimo        : Currency;
    FidEmpresa            : Integer;
    Frendimento           : Currency;
    FcodigoRef            : string;
    FidSetor              : Integer;
    FbaixarSetorPrincipal : Boolean;
  public
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property idComposicao: Integer read FidComposicao write FidComposicao;
    property descricao: string read Fdescricao write Fdescricao;
    property valorCusto: Currency read FvalorCusto write FvalorCusto;
    property estoqueMinimo: Currency read FestoqueMinimo write FestoqueMinimo;
    property rendimento: Currency read Frendimento write Frendimento;
    property codigoRef: string read FcodigoRef write FcodigoRef;
    property idSetor: Integer read FidSetor write FidSetor;
    property baixarSetorPrincipal: Boolean read FbaixarSetorPrincipal write FbaixarSetorPrincipal;
  end;

implementation

end.
