unit APIRPCheff.Entity.Mesa;

interface

uses
  APIRPCheff.Entity.Types,
  APIRPCheff.Entity.Venda,
  System.SysUtils;

type
  TAPIRPCheffEntityMesa = class
  private
    FidEmpresa       : Integer;
    Fdescricao       : string;
    Fnumero          : string;
    Fsituacao        : TRPCheffSituacaoMesa;
    FidVenda         : Integer;
    FidMesa          : Integer;
    FnomeReserva     : string;
    FdataReserva     : TDateTime;
    FtelefoneReserva : string;
    FVenda           : TAPIRPCheffEntityVenda;
    function GetStatusDescription: string;
    function GetNomeMesaComanda: string;
    procedure SetVenda(const AValue: TAPIRPCheffEntityVenda);
  public
    constructor Create;
    destructor Destroy; override;

    property idEmpresa: Integer read FidEmpresa write FidEmpresa;
    property idMesa: Integer read FidMesa write FidMesa;
    property descricao: string read Fdescricao write Fdescricao;
    property numero: string read Fnumero write Fnumero;
    property idVenda: Integer read FidVenda write FidVenda;
    property situacao: TRPCheffSituacaoMesa read Fsituacao write Fsituacao;
    property nomeReserva: string read FnomeReserva write FnomeReserva;
    property telefoneReserva: string read FtelefoneReserva write FtelefoneReserva;
    property dataReserva: TDateTime read FdataReserva write FdataReserva;
    property nomeMesaComanda: string read GetNomeMesaComanda;
    property statusDescription: string read GetStatusDescription;
    property venda: TAPIRPCheffEntityVenda read FVenda write SetVenda;
  end;

implementation

{ TAPIRPCheffEntityMesa }

constructor TAPIRPCheffEntityMesa.Create;
begin
  Fsituacao := smDisponivel;
  FVenda := TAPIRPCheffEntityVenda.Create;
  FVenda.situacao := svDigitacao;
end;

destructor TAPIRPCheffEntityMesa.Destroy;
begin
  FreeAndNil(FVenda);
  inherited;
end;

function TAPIRPCheffEntityMesa.GetNomeMesaComanda: string;
begin
  Result := Fdescricao;
  if (Assigned(FVenda)) and (FVenda.nomeMesaComanda <> EmptyStr) then
    Result := FVenda.nomeMesaComanda;
end;

function TAPIRPCheffEntityMesa.GetStatusDescription: string;
begin
  Result := Fsituacao.Description;
end;

procedure TAPIRPCheffEntityMesa.SetVenda(const AValue: TAPIRPCheffEntityVenda);
begin
  FreeAndNil(FVenda);
  FVenda := AValue;
end;

end.
