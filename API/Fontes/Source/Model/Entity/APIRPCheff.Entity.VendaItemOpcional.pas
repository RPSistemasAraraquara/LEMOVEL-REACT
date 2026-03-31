unit APIRPCheff.Entity.VendaItemOpcional;

interface

uses
  GBSwagger.Model.Attributes;

type
  TAPIRPCheffEntityVendaItemOpcional = class
  private
    FidOpcional: Integer;
    Fdescricao: string;
    FidVenda: Integer;
    FidEmpresa: Integer;
    FidVendaItem: Integer;
    Fgratis: Boolean;
    Fvalor: Currency;
  public
    constructor Create;
    procedure Assign(ASource: TAPIRPCheffEntityVendaItemOpcional);

    [SwagIgnore]
    property idVenda: Integer read FidVenda write FidVenda;

    [SwagIgnore]
    property idEmpresa: Integer read FidEmpresa write FidEmpresa;

    [SwagIgnore]
    property idVendaItem: Integer read FidVendaItem write FidVendaItem;
    property idOpcional: Integer read FidOpcional write FidOpcional;

    [SwagProp(False, True)]
    property descricao: string read Fdescricao write Fdescricao;
    property gratis: Boolean read Fgratis write Fgratis;
    property valor: Currency read Fvalor write Fvalor;
  end;

implementation

{ TAPIRPCheffEntityVendaItemOpcional }

procedure TAPIRPCheffEntityVendaItemOpcional.Assign(ASource: TAPIRPCheffEntityVendaItemOpcional);
begin
  Self.idOpcional := ASource.idOpcional;
  Self.descricao := ASource.descricao;
  Self.idVenda := ASource.idVenda;
  Self.idEmpresa := ASource.idEmpresa;
  Self.idVendaItem := ASource.idVendaItem;
  Self.gratis := ASource.gratis;
  Self.valor := ASource.valor;
end;

constructor TAPIRPCheffEntityVendaItemOpcional.Create;
begin
  Fgratis := False;
end;

end.
