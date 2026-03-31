unit APIRPCheff.Service.Comanda.Consulta;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  APIRPCheff.Service.Venda.Consulta,
  System.DateUtils,
  System.SysUtils,
  System.Generics.Collections,
  System.Classes;

type
  TAPIRPCheffServiceComandaConsulta = class
  private
    FDAO                  : TAPIRPCheffDAOFactory;
    FServiceVendaConsulta : TAPIRPCheffServiceVendaConsulta;

    procedure CarregarVenda(AComanda: TAPIRPCheffEntityComanda);
  public
    destructor Destroy; override;

    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceComandaConsulta;
    function Listar: TObjectList<TAPIRPCheffEntityComanda>;
    function ListarPrePago: TObjectList<TAPIRPCheffEntityComanda>;
    function Consultar(AIdComanda: Integer): TAPIRPCheffEntityComanda;
  end;

implementation

{ TAPIRPCheffServiceComandaConsulta }

procedure TAPIRPCheffServiceComandaConsulta.CarregarVenda(AComanda: TAPIRPCheffEntityComanda);
begin
  if AComanda.idVenda > 0 then
  begin
    if not Assigned(FServiceVendaConsulta) then
    begin
      FServiceVendaConsulta := TAPIRPCheffServiceVendaConsulta.Create;
      FServiceVendaConsulta.DAO(FDAO);
    end;
    AComanda.venda := FServiceVendaConsulta.Buscar(AComanda.idVenda, False);
  end;
end;

function TAPIRPCheffServiceComandaConsulta.Consultar(AIdComanda: Integer): TAPIRPCheffEntityComanda;
begin
  Result := FDAO.ComandaDAO.Busca(AIdComanda);
  try
    CarregarVenda(Result);
  except
    FreeAndNil(Result);
   raise;
  end;
end;

function TAPIRPCheffServiceComandaConsulta.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceComandaConsulta;
begin
  Result := Self;
  FDAO := AValue;
end;

destructor TAPIRPCheffServiceComandaConsulta.Destroy;
begin
   if Assigned(FServiceVendaConsulta) then
    FreeAndNil(FServiceVendaConsulta);
  inherited;
end;

function TAPIRPCheffServiceComandaConsulta.Listar: TObjectList<TAPIRPCheffEntityComanda>;
var
  LComanda: TAPIRPCheffEntityComanda;
begin
  Result := FDAO.ComandaDAO.List;
  try
    for LComanda in Result do
      CarregarVenda(LComanda);
  except
    Result.Free;
    raise;
  end;
end;

function TAPIRPCheffServiceComandaConsulta.ListarPrePago: TObjectList<TAPIRPCheffEntityComanda>;
var
  LComanda: TAPIRPCheffEntityComanda;
begin
  Result := FDAO.ComandaDAO.ListarPrePago;
  try
    for LComanda in Result do
      CarregarVenda(LComanda);
  except
    Result.Free;
    raise;
  end;
end;

end.
