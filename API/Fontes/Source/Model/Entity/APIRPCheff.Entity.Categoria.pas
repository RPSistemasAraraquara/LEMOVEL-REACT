unit APIRPCheff.Entity.Categoria;

interface

type
  TAPIRPCheffEntityCategoria = class
  private
    FidCategoria     : Integer;
    Fdescricao       : string;
    FidEmpresa       : Integer;
    FPermiteVendaAPP : boolean;
  public
    property idCategoria: Integer read FidCategoria write FidCategoria;
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property descricao: string read Fdescricao write Fdescricao;
     property PermiteVendaAPP:  boolean  read FPermiteVendaAPP write FPermiteVendaAPP;
  end;

implementation

end.
