unit APIRPCheff.Entity.ChamaGarcom;

interface

uses
  GBSwagger.Model.Attributes;

type
  TAPIRPCheffEntityChamaGarcom = class
  private
    FId         : Integer;
    FIdEmpresa  : Integer;
    FNumeroMesa : string;
  public
    [SwagIgnore]
    property id: Integer read FId write FId;

    [SwagIgnore]
    property idEmpresa: Integer read FIdEmpresa write FIdEmpresa;

    property numeroMesa: string read FNumeroMesa write FNumeroMesa;
  end;

implementation

end.
