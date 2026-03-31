unit APIRPCheff.Entity.SetorEstoqueOpcional;

interface

type
  TAPIRPCheffEntitySetorEstoqueOpcional = class
   private
    FidOpcional   : Integer;
    FidSetor      : Integer;
    FidEmpresa    : Integer;
    Fquantidade   : Currency;
  public
    property idOpcional   : Integer     read FidOpcional      write FidOpcional;
    property idSetor      : Integer     read FidSetor         write FidSetor;
    property idEmpresa    : Integer     read FidEmpresa       write FidEmpresa;
    property quantidade   : Currency    read Fquantidade      write Fquantidade;
  end;

implementation

end.
