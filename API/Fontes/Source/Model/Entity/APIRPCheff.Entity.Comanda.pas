unit APIRPCheff.Entity.Comanda;

interface

uses
  APIRPCheff.Entity.Venda,
  APIRPCheff.Entity.Types,
  System.SysUtils;

type
  TAPIRPCheffEntityComanda = class
  private
    FidComanda : Integer;
    Fdescricao : string;
    Fnumero    : string;
    FidVenda   : Integer;
    FVenda     : TAPIRPCheffEntityVenda;
    FidEmpresa : Integer;
    function GetNomeMesaComanda: string;
    procedure SetVenda(const AValue: TAPIRPCheffEntityVenda);
  public
    constructor Create;
    destructor Destroy; override;

    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property idComanda: Integer read FidComanda write FidComanda;
    property descricao: string read Fdescricao write Fdescricao;
    property numero: string read Fnumero write Fnumero;
    property idVenda: Integer read FidVenda write FidVenda;
    property nomeMesaComanda: string read GetNomeMesaComanda;
    property venda: TAPIRPCheffEntityVenda read FVenda write SetVenda;
  end;

implementation

{ TAPIRPCheffEntityComanda }

constructor TAPIRPCheffEntityComanda.Create;
begin
  FVenda := TAPIRPCheffEntityVenda.Create;
  FVenda.situacao := svDigitacao;
end;

destructor TAPIRPCheffEntityComanda.Destroy;
begin
  FreeAndNil(FVenda);
  inherited;
end;

function TAPIRPCheffEntityComanda.GetNomeMesaComanda: string;
begin
  Result := Fdescricao;
  if (Assigned(FVenda)) and (FVenda.nomeMesaComanda <> EmptyStr) then
    Result := FVenda.nomeMesaComanda;
end;

procedure TAPIRPCheffEntityComanda.SetVenda(const AValue: TAPIRPCheffEntityVenda);
begin
  FreeAndNil(FVenda);
  FVenda := AValue;
end;

end.
