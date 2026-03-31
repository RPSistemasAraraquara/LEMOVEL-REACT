unit APIRPCheff.Entity.Cliente;

interface

type
  TAPIRPCheffEntityCliente = class
  private
    Fid        : Integer;
    Fnome      : string;
    Fdocumento : string;
  public
    property id: Integer read Fid write Fid;
    property nome: string read Fnome write Fnome;
    property documento: string read Fdocumento write Fdocumento;
  end;

implementation

end.
