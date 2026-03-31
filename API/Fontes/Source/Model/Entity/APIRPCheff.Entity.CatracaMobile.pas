unit APIRPCheff.Entity.CatracaMobile;

interface

type
  TAPIRPCheffEntityCatracaMobile = class
  private
    Fid        : Integer;
    FidComanda : Integer;
    FidEmpresa : Integer;
    Fcomando   : string;
    Fdata      : TDateTime;
  public
    property id: Integer read Fid write Fid;
    property idComanda: Integer read FidComanda write FidComanda;
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property comando: string read Fcomando write Fcomando;
    property data: TDateTime read Fdata write Fdata;
  end;

implementation

end.
