unit APIRPCheff.Components.JSON;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  GBJSON.Config,
  GBJSON.Interfaces;

type
  TAPIRPCheffComponentsJSON = class
  public
    function ToJSONObject(AObject: TObject): TJSONObject;
    function ToJSONArray<T: class, constructor>(AList: TObjectList<T>): TJSONArray;
    function ToJSONString(AObject: TObject): string; overload;
    function ToJSONString<T: class, constructor>(AList: TObjectList<T>): string; overload;
    function FromJSONObject<T: class, constructor>(AJSONObject: TJSONObject): T; overload;
    function FromJSONObject<T: class, constructor>(AJSONObject: string): T; overload;
    function FromJSONArray<T: class, constructor>(AJSONArray: TJSONArray): TObjectList<T>;
  end;

implementation

{ TAPIRPCheffComponentsJSON }

function TAPIRPCheffComponentsJSON.FromJSONArray<T>(AJSONArray: TJSONArray): TObjectList<T>;
begin
  Result := TGBJSONDefault.Serializer<T>.JsonArrayToList(AJSONArray);
end;

function TAPIRPCheffComponentsJSON.FromJSONObject<T>(AJSONObject: TJSONObject): T;
begin
  Result := TGBJSONDefault.Serializer<T>.JsonObjectToObject(AJSONObject);
end;

function TAPIRPCheffComponentsJSON.FromJSONObject<T>(AJSONObject: string): T;
begin
  Result := TGBJSONDefault.Serializer<T>.JsonStringToObject(AJSONObject);
end;

function TAPIRPCheffComponentsJSON.ToJSONArray<T>(AList: TObjectList<T>): TJSONArray;
begin
  Result := TGBJSONDefault.Deserializer<T>.ListToJSONArray(AList);
end;

function TAPIRPCheffComponentsJSON.ToJSONObject(AObject: TObject): TJSONObject;
begin
  Result := TGBJSONDefault.Deserializer.ObjectToJsonObject(AObject);
end;

function TAPIRPCheffComponentsJSON.ToJSONString(AObject: TObject): string;
begin
  Result := TGBJSONDefault.Deserializer.ObjectToJsonString(AObject);
end;

function TAPIRPCheffComponentsJSON.ToJSONString<T>(AList: TObjectList<T>): string;
var
  LJSON: TJSONArray;
begin
  LJSON := TGBJSONDefault.Deserializer<T>.ListToJSONArray(AList);
  try
    Result := LJSON.ToString;
  finally
    LJSON.Free;
  end;
end;

initialization
  TGBJSONConfig.GetInstance.IgnoreEmptyValues(True);

end.
