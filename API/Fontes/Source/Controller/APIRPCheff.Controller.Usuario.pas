unit APIRPCheff.Controller.Usuario;

interface

uses
  APIRPCheff.Controller.Base,
  APIRPCheff.Entity.Classes,
  Horse.GBSwagger.Registry,
  GBSwagger.Path.Attributes,
  GBSwagger.Validator.Interfaces,
  System.Generics.Collections,
  System.SysUtils;

type
  [SwagPath('empresa/{idEmpresa}/usuario', 'usu'#225'rio')]
  [SwagParamPath('idEmpresa', 'Id da empresa')]
  TAPIRPCheffControllerUsuario = class(TAPIRPCheffControllerBase)
  public
    [SwagGET('Listar Usuarios')]
    [SwagResponse(200, TAPIRPCheffEntityUsuario, True)]
    procedure Listar;

    [SwagGET('{login}', 'Buscar usuario pelo login')]
    [SwagParamPath('login', 'login do usuario')]
    [SwagResponse(200, TAPIRPCheffEntityUsuario)]
    [SwagResponse(404)]
    procedure BuscarPeloLogin;

    [SwagPOST('login', 'Login do usuario')]
    [SwagParamBody('login', TAPIRPCheffEntityLogin)]
    [SwagResponse(200, TAPIRPCheffEntityUsuario)]
    [SwagResponse(400)]
    procedure Login;
  end;

implementation

{ TAPIRPCheffControllerUsuario }

procedure TAPIRPCheffControllerUsuario.BuscarPeloLogin;
var
  LLogin: string;
  LUsuario: TAPIRPCheffEntityUsuario;
begin
  LLogin := FRequest.Params.Field('login').AsString;
  LUsuario := Controller.DAO.UsuarioDAO.Busca(LLogin);
  try
    Self.Response(LUsuario, Format('usu'#225'rio %s N'#227'o existe ou N'#227'o est'#225' ativo.', [LLogin]));
  finally
    FreeAndNil(LUsuario);
  end;
end;

procedure TAPIRPCheffControllerUsuario.Listar;
var
  LUsuarios: TObjectList<TAPIRPCheffEntityUsuario>;
begin
  LUsuarios := Controller.DAO.IdEmpresa(IdEmpresa)
    .UsuarioDAO.List;
  try
    Self.Response<TAPIRPCheffEntityUsuario>(LUsuarios);
  finally
    FreeAndNil(LUsuarios);
  end;
end;

procedure TAPIRPCheffControllerUsuario.Login;
var
  LLogin: TAPIRPCheffEntityLogin;
  LUsuario: TAPIRPCheffEntityUsuario;
begin
  LLogin := Self.FromJSONObject<TAPIRPCheffEntityLogin>;
  try
    LUsuario := Controller.DAO.IdEmpresa(IdEmpresa)
      .UsuarioDAO.Busca(LLogin.login, LLogin.senha);
    try
      if not Assigned(LUsuario) then
      begin
        FResponse.Status(400);
        raise Exception.Create('usu'#225'rio Gar'#231'om N'#227'o encontrado.');
      end;
      Self.Response(LUsuario);
    finally
      FreeAndNil(LUsuario);
    end;
  finally
    FreeAndNil(LLogin);
  end;
end;

initialization
  THorseGBSwaggerRegistry.RegisterPath(TAPIRPCheffControllerUsuario);

end.
