unit APIRPCheff.Components;

interface

uses
  System.SysUtils,
{$IFNDEF LINUX}
  RPNFe.Controller,
{$ENDIF}
  APIRPCheff.Components.Connection,
  APIRPCheff.Components.Impressora,
  APIRPCheff.Components.JSON;

type
  TAPIRPCheffComponents = class
  private
    FConnection: TAPIRPCheffComponentConnection;
    FImpressora: TAPIRPCheffComponentsImpressora;
    FJSON: TAPIRPCheffComponentsJSON;
{$IFNDEF LINUX}
    FRPNFe: TRPNFeController;
{$ENDIF}
  public
    destructor Destroy; override;

    function Connection: TAPIRPCheffComponentConnection;
    function Impressora: TAPIRPCheffComponentsImpressora;
    function JSON: TAPIRPCheffComponentsJSON;
{$IFNDEF LINUX}
    function RPNFe: TRPNFeController;
{$ENDIF}
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
{$IFNDEF LINUX}
  FreeAndNil(FRPNFe);
{$ENDIF}
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

{$IFNDEF LINUX}
function TAPIRPCheffComponents.RPNFe: TRPNFeController;
begin
  if not Assigned(FRPNFe) then
    FRPNFe := TRPNFeController.Create;
  FRPNFe.Connection(Connection.GetConnection.Component);
  Result := FRPNFe;
end;
{$ENDIF}

end.
