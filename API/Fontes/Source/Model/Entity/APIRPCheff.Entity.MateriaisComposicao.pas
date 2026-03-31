unit APIRPCheff.Entity.MateriaisComposicao;

interface

uses
  System.SysUtils,
  APIRPCheff.Entity.Composicao;

type
  TAPIRPCheffEntityMateriaisComposicao = class
  private
    FidEmpresa    : Integer;
    FidMaterial   : Integer;
    FidComposicao : Integer;
    Fquantidade   : Currency;
    Fcomposicao   : TAPIRPCheffEntityComposicao;
  public
    constructor Create;
    destructor Destroy; override;

    property idEmpresa    : Integer read FidEmpresa write FidEmpresa;
    property idMaterial   : Integer read FidMaterial write FidMaterial;
    property idComposicao : Integer read FidComposicao write FidComposicao;
    property quantidade   : Currency read Fquantidade write Fquantidade;
    property composicao   : TAPIRPCheffEntityComposicao read Fcomposicao write Fcomposicao;
  end;

implementation

{ TAPIRPCheffEntityMateriaisComposicao }

constructor TAPIRPCheffEntityMateriaisComposicao.Create;
begin
  Fcomposicao := TAPIRPCheffEntityComposicao.Create;
end;

destructor TAPIRPCheffEntityMateriaisComposicao.Destroy;
begin
  FreeAndNil(Fcomposicao);
  inherited;
end;

end.
