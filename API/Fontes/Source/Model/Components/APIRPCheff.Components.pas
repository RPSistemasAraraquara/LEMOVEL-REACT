unit APIRPCheff.Components;

interface

uses
  System.SysUtils,
  RPNFe.Controller,
  APIRPCheff.Components.Connection,
  APIRPCheff.Components.Impressora,
  APIRPCheff.Components.JSON;

type
  TAPIRPCheffComponents = class
  private
    FConnection: TAPIRPCheffComponentConnection;
    FImpressora: TAPIRPCheffComponentsImpressora;
    FJSON: TAPIRPCheffComponentsJSON;
    FRPNFe: TRPNFeController;
  public
    destructor Destroy; override;

    function Connection: TAPIRPCheffComponentConnection;
    function Impressora: TAPIRPCheffComponentsImpressora;
    function JSON: TAPIRPCheffComponentsJSON;
    function RPNFe: TRPNFeController;
  end;

implementation

{ TAPIRPCheffComponents }

function TAPIRPCheffComponents.Connection: TAPIRPCheffComponentConnection;
begin
  if not Assigned(FConnection) then
    FConnection := TAPIRPCheffComponentConnection.Create;
  Result := FConnection;
end;

destructor TAPIRPCheffComponents.Destroy;
begin
  FreeAndNil(FConnection);
  FreeAndNil(FImpressora);
  FreeAndNil(FJSON);
  FreeAndNil(FRPNFe);
  inherited;
end;

function TAPIRPCheffComponents.Impressora: TAPIRPCheffComponentsImpressora;
begin
  if not Assigned(FImpressora) then
    FImpressora := TAPIRPCheffComponentsImpressora.Create;
  Result := FImpressora;
end;

function TAPIRPCheffComponents.JSON: TAPIRPCheffComponentsJSON;
begin
  if not Assigned(FJSON) then
    FJSON := TAPIRPCheffComponentsJSON.Create;
  Result := FJSON;
end;

function TAPIRPCheffComponents.RPNFe: TRPNFeController;
begin
  if not Assigned(FRPNFe) then
    FRPNFe := TRPNFeController.Create;
  FRPNFe.Connection(Connection.GetConnection.Component);
  Result := FRPNFe;
end;

end.
