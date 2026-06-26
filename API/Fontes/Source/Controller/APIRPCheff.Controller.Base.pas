unit APIRPCheff.Controller.Base;

interface

uses
  Horse,
  Horse.GBSwagger,
  Horse.GBSwagger.Controller,
  GBSwagger.Validator.Interfaces,
  Web.HTTPApp,
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  System.Classes,
  APIRPCheff.Controller;

type
  TAPIRPCheffControllerBase = class(THorseGBSwagger)
  private
    FController: TAPIRPCheffController;
  protected
    procedure Validar(AObject: TObject);
    function Controller: TAPIRPCheffController; overload;
    function Controller(AIdEmpresa: Integer): TAPIRPCheffController; overload;
    function IdEmpresa: Integer;
    function IdUsuario: Integer;
    procedure ValidarPermissaoTransferenciaMesa;
    procedure Response(AObject: TObject; ANotFoundMessage: string); overload;
    procedure Response(AObject: TObject; AOwner: Boolean = False); overload;
    procedure Response<T: class, constructor>(AList: TObjectList<T>; AOwner: Boolean = False); overload;
    function FromJSONObject<T: class, constructor>: T;
    function FromJSONArray<T: class, constructor>: TObjectList<T>;
  public
    destructor Destroy; override;
  end;

implementation

uses
  APIRPCheff.Entity.Classes;

{ TAPIRPCheffControllerBase }

function TAPIRPCheffControllerBase.Controller: TAPIRPCheffController;
begin
  if not Assigned(FController) then
  begin
    FController := TAPIRPCheffController.Create;
    FController.IdEmpresa(IdEmpresa);
  end;
  Result := FController;
end;

function TAPIRPCheffControllerBase.Controller(AIdEmpresa: Integer): TAPIRPCheffController;
begin
  if not Assigned(FController) then
    FController := TAPIRPCheffController.Create;
  Result := FController;
  Result.IdEmpresa(AIdEmpresa);
  Result.DAO.IdEmpresa(AIdEmpresa);
end;

destructor TAPIRPCheffControllerBase.Destroy;
begin
  FreeAndNil(FController);
  inherited;
end;

function TAPIRPCheffControllerBase.FromJSONArray<T>: TObjectList<T>;
begin
  Result := Controller.Components.JSON
    .FromJSONArray<T>(FRequest.Body<TJSONArray>);
end;

function TAPIRPCheffControllerBase.FromJSONObject<T>: T;
begin
  if FRequest.MethodType = mtDelete then
    Result := Controller.Components.JSON
      .FromJSONObject<T>(FRequest.Body)
  else
    Result := Controller.Components.JSON
      .FromJSONObject<T>(FRequest.Body<TJSONObject>);
end;

function TAPIRPCheffControllerBase.IdEmpresa: Integer;
begin
  Result := FRequest.Params.Field('idEmpresa').AsInteger;
end;

function TAPIRPCheffControllerBase.IdUsuario: Integer;
begin
  Result := 0;
  if FRequest.Headers.ContainsKey('idUsuario') then
    Result := FRequest.Headers.Field('idUsuario').AsInteger;
end;

procedure TAPIRPCheffControllerBase.ValidarPermissaoTransferenciaMesa;
var
  LIdUsuario: Integer;
  LUsuario: TAPIRPCheffEntityUsuario;
  LBody: TJSONObject;
  LValue: TJSONValue;
begin
  LIdUsuario := IdUsuario;
  if LIdUsuario <= 0 then
  begin
    try
      LBody := FRequest.Body<TJSONObject>;
      if Assigned(LBody) then
      begin
        LValue := LBody.Values['idUsuario'];
        if Assigned(LValue) then
          LIdUsuario := StrToIntDef(LValue.Value, 0);
      end;
    except
      LIdUsuario := 0;
    end;
  end;

  if LIdUsuario <= 0 then
  begin
    FResponse.Status(403);
    raise Exception.Create('Usu'#225'rio n'#227'o informado para transfer'#234'ncia.');
  end;

  LUsuario := Controller.DAO.UsuarioDAO.Busca(LIdUsuario);
  try
    if not Assigned(LUsuario) then
    begin
      FResponse.Status(403);
      raise Exception.CreateFmt('Usu'#225'rio %d n'#227'o encontrado para transfer'#234'ncia.', [LIdUsuario]);
    end;

    if not LUsuario.transferenciaMesa then
    begin
      FResponse.Status(403);
      raise Exception.Create('Usu'#225'rio n'#227'o possui permiss'#227'o para transferir mesa/comanda.');
    end;
  finally
    FreeAndNil(LUsuario);
  end;
end;

procedure TAPIRPCheffControllerBase.Response(AObject: TObject; AOwner: Boolean);
begin
  try
    Response(AObject, 'N'#227'o encontrado.');
  finally
    if AOwner then
    FreeAndNil(AObject);
  end;
end;

procedure TAPIRPCheffControllerBase.Response(AObject: TObject; ANotFoundMessage: string);
var
  LJSON: TJSONObject;
begin
  if not Assigned(AObject) then
  begin
    FResponse.Status(404);
    raise Exception.Create(ANotFoundMessage);
  end;

  LJSON := Controller.Components.JSON.ToJSONObject(AObject);
  FResponse.Send<TJSONObject>(LJSON);
end;

procedure TAPIRPCheffControllerBase.Response<T>(AList: TObjectList<T>; AOwner: Boolean);
var
  LJSON: TJSONArray;
begin
  LJSON := Controller.Components.JSON.ToJSONArray<T>(AList);
  try
    FResponse.Send<TJSONArray>(LJSON);
  finally
    if AOwner then
    FreeAndNil(AList);
  end;
end;

procedure TAPIRPCheffControllerBase.Validar(AObject: TObject);
begin
  SwaggerValidator.Validate(AObject);
end;

end.
