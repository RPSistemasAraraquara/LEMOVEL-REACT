unit RPNFe.Components.Connection;

interface

uses
  System.SysUtils,
  System.Classes,
  ADRConn.Model.Interfaces;

type
  TRPNFeComponentsConnection = class
  private
    FConnection: IADRConnection;
  public
    function SetComponent(AValue: TComponent): TRPNFeComponentsConnection;
    function GetConnection: IADRConnection;
    function GetQuery: IADRQuery;
  end;

implementation

{ TRPNFeComponentsConnection }

function TRPNFeComponentsConnection.GetConnection: IADRConnection;
begin
  Result := FConnection;
end;

function TRPNFeComponentsConnection.GetQuery: IADRQuery;
begin
  Result := CreateQuery(GetConnection);
end;

function TRPNFeComponentsConnection.SetComponent(AValue: TComponent): TRPNFeComponentsConnection;
begin
  Result := Self;
  FConnection := CreateConnection(AValue);
end;

end.
