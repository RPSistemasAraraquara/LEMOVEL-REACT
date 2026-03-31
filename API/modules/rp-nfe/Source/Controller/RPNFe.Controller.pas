unit RPNFe.Controller;

interface

uses
  System.SysUtils,
  System.Classes,
  RPNFe.Entity.Classes,
  RPNFe.Components,
  RPNFe.DAO.Factory,
  RPNFe.Service;

type
  TRPNFeController = class
  private
    FConnection: TComponent;
    FComponents: TRPNFeComponents;
    FDAO: TRPNFeDAOFactory;
    FService: TRPNFeService;
  public
    destructor Destroy; override;

    function Connection(AValue: TComponent): TRPNFeController;
    function Components: TRPNFeComponents;
    function DAO: TRPNFeDAOFactory;
    function Service: TRPNFeService;
  end;

implementation

{ TRPNFeController }

function TRPNFeController.Components: TRPNFeComponents;
begin
  if not Assigned(FComponents) then
    FComponents := TRPNFeComponents.Create;
  Result := FComponents;
end;

function TRPNFeController.Connection(AValue: TComponent): TRPNFeController;
begin
  Result := Self;
  FConnection := AValue;
  Components.Connection.SetComponent(FConnection);
end;

function TRPNFeController.DAO: TRPNFeDAOFactory;
begin
  if not Assigned(FDAO) then
    FDAO := TRPNFeDAOFactory.Create(Components);
  Result := FDAO;
end;

destructor TRPNFeController.Destroy;
begin
  FComponents.Free;
  FDAO.Free;
  FService.Free;
  inherited;
end;

function TRPNFeController.Service: TRPNFeService;
begin
  if not Assigned(FService) then
  begin
    FService := TRPNFeService.Create;
    FService.DAO(DAO)
      .Components(Components);
  end;
  Result := FService;
end;

end.
