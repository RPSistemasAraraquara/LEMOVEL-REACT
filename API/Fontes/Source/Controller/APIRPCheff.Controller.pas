unit APIRPCheff.Controller;

interface

uses
  System.SysUtils,
  APIRPCheff.Components,
  APIRPCheff.DAO.Factory,
  APIRPCheff.Service;

type
  TAPIRPCheffController = class
  private
    FIdEmpresa    : Integer;
    FComponents   : TAPIRPCheffComponents;
    FDAO          : TAPIRPCheffDAOFactory;
    FService      : TAPIRPCheffService;
  public
    destructor Destroy; override;

    function IdEmpresa(AValue: Integer): TAPIRPCheffController;
    function Components: TAPIRPCheffComponents;
    function DAO: TAPIRPCheffDAOFactory;
    function Service: TAPIRPCheffService;
  end;

implementation

{ TAPIRPCheffController }

function TAPIRPCheffController.Components: TAPIRPCheffComponents;
begin
  if not Assigned(FComponents) then
    FComponents := TAPIRPCheffComponents.Create;
  Result := FComponents;
end;

function TAPIRPCheffController.DAO: TAPIRPCheffDAOFactory;
begin
  if not Assigned(FDAO) then
  begin
    FDAO := TAPIRPCheffDAOFactory.Create(Components.Connection.GetConnection);
    FDAO.IdEmpresa(FIdEmpresa);
  end;
  Result := FDAO;
end;

destructor TAPIRPCheffController.Destroy;
begin
  FreeAndNil(FComponents);
  FreeAndNil(FDAO);
  FreeAndNil(FService);
  inherited;
end;

function TAPIRPCheffController.IdEmpresa(AValue: Integer): TAPIRPCheffController;
begin
  Result := Self;
  FIdEmpresa := AValue;
end;

function TAPIRPCheffController.Service: TAPIRPCheffService;
begin
  if not Assigned(FService) then
  begin
    FService := TAPIRPCheffService.Create;
    FService.DAO(DAO)
      .Components(Components);
  end;
  Result := FService;
end;

end.
