unit APIRPCheff.Entity.Error;

interface

type
  TAPIRPCheffEntityError = class
  private
    Ferror: string;
    Fdescription: String;
  public
    property error: string read Ferror write Ferror;
    property description: String read Fdescription write Fdescription;
  end;

implementation

end.
