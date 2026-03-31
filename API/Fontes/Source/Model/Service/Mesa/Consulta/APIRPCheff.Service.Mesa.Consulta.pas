unit APIRPCheff.Service.Mesa.Consulta;

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
  TAPIRPCheffServiceMesaConsulta = class
  private
    FDAO                  : TAPIRPCheffDAOFactory;
    FServiceVendaConsulta : TAPIRPCheffServiceVendaConsulta;

    procedure CarregarVenda(AMesa: TAPIRPCheffEntityMesa);
  public
    destructor Destroy; override;

    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaConsulta;
    function Listar: TObjectList<TAPIRPCheffEntityMesa>;
    function ListarPorSituacao(ASituacao: TRPCheffSituacaoVenda): TObjectList<TAPIRPCheffEntityMesa>;
    function Consultar(AIdMesa: Integer): TAPIRPCheffEntityMesa;
  end;

implementation

{ TAPIRPCheffServiceMesaConsulta }


procedure TAPIRPCheffServiceMesaConsulta.CarregarVenda(AMesa: TAPIRPCheffEntityMesa);
begin
  if AMesa.idVenda > 0 then
  begin
    if not Assigned(FServiceVendaConsulta) then
    begin
      FreeAndNil(FServiceVendaConsulta);
      FServiceVendaConsulta := TAPIRPCheffServiceVendaConsulta.Create;
      FServiceVendaConsulta.DAO(FDAO);
    end;
    AMesa.venda := FServiceVendaConsulta.Buscar(AMesa.idVenda, False);
  end;
  if (AMesa.situacao = smReservada) and Assigned(AMesa.venda) then
    AMesa.venda.situacao := svReservada;
end;

function TAPIRPCheffServiceMesaConsulta.Consultar(AIdMesa: Integer): TAPIRPCheffEntityMesa;
begin
  Result := FDAO.MesaDAO.Busca(AIdMesa);
  try
    CarregarVenda(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TAPIRPCheffServiceMesaConsulta.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaConsulta;
begin
  Result := Self;
  FDAO := AValue;
end;

destructor TAPIRPCheffServiceMesaConsulta.Destroy;
begin
  FreeAndNil(FServiceVendaConsulta);
  inherited;
end;

//function TAPIRPCheffServiceMesaConsulta.Listar: TObjectList<TAPIRPCheffEntityMesa>;
//var
//  LMesa: TAPIRPCheffEntityMesa;
//begin
//  Result := FDAO.MesaDAO.List;
//  try
//    for LMesa in Result do
//      CarregarVenda(LMesa);
//  except
//    for LMesa in Result do
//      LMesa.Free;
//    FreeAndNil(Result);
//    raise;
//  end;
//end;

function TAPIRPCheffServiceMesaConsulta.Listar: TObjectList<TAPIRPCheffEntityMesa>;
var
  LMesa: TAPIRPCheffEntityMesa;
begin
  Result := FDAO.MesaDAO.List;
  try
    for LMesa in Result do
      CarregarVenda(LMesa);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TAPIRPCheffServiceMesaConsulta.ListarPorSituacao(ASituacao: TRPCheffSituacaoVenda): TObjectList<TAPIRPCheffEntityMesa>;
var
  LMesa: TAPIRPCheffEntityMesa;
begin
  Result := FDAO.MesaDAO.ListarPorSituacaoVenda(ASituacao);
  try
    for LMesa in Result do
      CarregarVenda(LMesa);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

end.
