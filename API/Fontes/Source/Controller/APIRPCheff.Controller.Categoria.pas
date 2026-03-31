unit APIRPCheff.Controller.Categoria;

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
  [SwagPath('empresa/{idEmpresa}/categoria', 'Categoria')]
  [SwagParamPath('idEmpresa', 'Id da empresa')]
  TAPIRPCheffControllerCategoria = class(TAPIRPCheffControllerBase)
  public
    [SwagGET('Listar Categorias')]
    [SwagResponse(200, TAPIRPCheffEntityCategoria, True)]
    procedure Listar;
  end;

implementation

{ TAPIRPCheffControllerCategoria }

procedure TAPIRPCheffControllerCategoria.Listar;
var
  LCategorias: TObjectList<TAPIRPCheffEntityCategoria>;
begin
  LCategorias := Controller.DAO.IdEmpresa(IdEmpresa)
    .CategoriaDAO.Lista;
  try
    Self.Response<TAPIRPCheffEntityCategoria>(LCategorias);
  finally
    FreeAndNil(LCategorias);
  end;
end;

initialization
  THorseGBSwaggerRegistry.RegisterPath(TAPIRPCheffControllerCategoria);

end.
