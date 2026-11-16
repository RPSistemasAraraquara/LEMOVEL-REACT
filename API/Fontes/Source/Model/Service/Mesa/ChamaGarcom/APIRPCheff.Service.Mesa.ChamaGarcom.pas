unit APIRPCheff.Service.Mesa.ChamaGarcom;

interface

uses
  APIRPCheff.DAO.Factory,
  System.SysUtils;

type
  TAPIRPCheffServiceMesaChamaGarcom = class
  private
    FDAO        : TAPIRPCheffDAOFactory;
    FNumeroMesa : string;
  public
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaChamaGarcom;
    function NumeroMesa(const AValue: string): TAPIRPCheffServiceMesaChamaGarcom;
    procedure Execute;
  end;

implementation

function TAPIRPCheffServiceMesaChamaGarcom.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceMesaChamaGarcom;
begin
  Result := Self;
  FDAO := AValue;
end;

procedure TAPIRPCheffServiceMesaChamaGarcom.Execute;
begin
  if not Assigned(FDAO) then
    raise Exception.Create('DAO nao configurado para chamar garcom.');

  if Trim(FNumeroMesa) = EmptyStr then
    raise Exception.Create('Numero da mesa nao informado.');

  if Length(Trim(FNumeroMesa)) > 20 then
    raise Exception.Create('Numero da mesa deve ter no maximo 20 caracteres.');

  FDAO.ChamaGarcomDAO.Inserir(FNumeroMesa);
end;

function TAPIRPCheffServiceMesaChamaGarcom.NumeroMesa(const AValue: string): TAPIRPCheffServiceMesaChamaGarcom;
begin
  Result := Self;
  FNumeroMesa := Trim(AValue);
end;

end.
