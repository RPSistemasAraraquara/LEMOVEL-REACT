unit APIRPCheff.Controller.Produto;

interface

uses
  APIRPCheff.Controller.Base,
  APIRPCheff.Entity.Classes,
  Horse.GBSwagger.Registry,
  GBSwagger.Path.Attributes,
  GBSwagger.Validator.Interfaces,
  System.Generics.Collections,
  System.Classes,
  System.SysUtils;

type
  [SwagPath('empresa/{idEmpresa}', 'Produto')]
  [SwagParamPath('idEmpresa', 'Id da empresa')]
  TAPIRPCheffControllerProduto = class(TAPIRPCheffControllerBase)
  public
    [SwagGET('produto', 'Listar Produtos')]
    [SwagResponse(200, TAPIRPCheffEntityProduto, True)]
    procedure ListarAtivos;

    [SwagGET('produto/{idProduto}', 'Buscar Produto')]
    [SwagParamPath('idProduto', 'Id do produto')]
    [SwagResponse(200, TAPIRPCheffEntityProduto)]
    procedure Buscar;

    [SwagGET('produto/{idProduto}/imagem', 'Buscar Imagem do Produto')]
    [SwagParamPath('idProduto', 'Id do produto')]
    procedure BuscarImagem;

    [SwagGET('categoria/{idCategoria}/produto', 'Listar Produtos por Categoria')]
    [SwagParamPath('idCategoria', 'Id da categoria')]
    [SwagResponse(200, TAPIRPCheffEntityProduto, True)]
    procedure ListarPorCategoria;
  end;

implementation

uses
  System.StrUtils;

{ TAPIRPCheffControllerProduto }

procedure TAPIRPCheffControllerProduto.Buscar;
var
  LIdEmpresa: Integer;
  LIdProduto: Integer;
  LExibirImagem: Boolean;
  LProduto: TAPIRPCheffEntityProduto;
begin
  LIdEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
  LIdProduto := FRequest.Params.Field('idProduto').AsInteger;
  LExibirImagem := not FRequest.Query.ContainsKey('exibirImagem') or
    AnsiMatchText(FRequest.Query.Field('exibirImagem').AsString.ToLower, ['true', '1', 'sim']);
  LProduto := Controller.DAO.IdEmpresa(LIdEmpresa).ProdutoDAO.ExibirImagem(LExibirImagem).Buscar(LIdProduto);
  try
    Self.Response(LProduto);
  finally
    FreeAndNil(LProduto);
  end;
end;

procedure TAPIRPCheffControllerProduto.BuscarImagem;
var
  LIdEmpresa: Integer;
  LIdProduto: Integer;
  LImagem: TMemoryStream;
begin
  LIdEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
  LIdProduto := FRequest.Params.Field('idProduto').AsInteger;
  LImagem := Controller.DAO.IdEmpresa(LIdEmpresa).ProdutoDAO.BuscarImagem(LIdProduto);
  try
    if not Assigned(LImagem) then
    begin
      FResponse.Status(404);
      raise Exception.Create('Imagem não encontrada.');
    end;

    LImagem.Position := 0;
    FResponse.AddHeader('Cache-Control', 'private, max-age=86400');
    FResponse.RawWebResponse.FreeContentStream := True;
    FResponse.RawWebResponse.ContentLength := LImagem.Size;
    FResponse.RawWebResponse.ContentStream := LImagem;
    FResponse.RawWebResponse.ContentType := 'image/jpeg';
    FResponse.RawWebResponse.SetCustomHeader('Content-Disposition', Format('inline; filename="produto_%d.jpg"', [LIdProduto]));
    FResponse.RawWebResponse.SendResponse;
    LImagem := nil;
  finally
    FreeAndNil(LImagem);
  end;
end;

procedure TAPIRPCheffControllerProduto.ListarAtivos;
var
  LExibirImagem: Boolean;
  LProdutos: TObjectList<TAPIRPCheffEntityProduto>;
begin
  LExibirImagem := not FRequest.Query.ContainsKey('exibirImagem') or
    AnsiMatchText(FRequest.Query.Field('exibirImagem').AsString.ToLower, ['true', '1', 'sim']);
  LProdutos := Controller.DAO.IdEmpresa(IdEmpresa)
    .ProdutoDAO.ExibirImagem(LExibirImagem).Lista;
  try
    Self.Response<TAPIRPCheffEntityProduto>(LProdutos);
  finally
    FreeAndNil(LProdutos);
  end;
end;

procedure TAPIRPCheffControllerProduto.ListarPorCategoria;
var
  LIdCategoria: Integer;
  LExibirImagem: Boolean;
  LProdutos: TObjectList<TAPIRPCheffEntityProduto>;
begin
  LIdCategoria := FRequest.Params.Field('idCategoria').AsInteger;
  LExibirImagem := not FRequest.Query.ContainsKey('exibirImagem') or
    AnsiMatchText(FRequest.Query.Field('exibirImagem').AsString.ToLower, ['true', '1', 'sim']);
  LProdutos := Controller.DAO.IdEmpresa(IdEmpresa)
    .ProdutoDAO.ExibirImagem(LExibirImagem).Lista(LIdCategoria);
  try
    Self.Response<TAPIRPCheffEntityProduto>(LProdutos);
  finally
    FreeAndNil(LProdutos);
  end;
end;

initialization
  THorseGBSwaggerRegistry.RegisterPath(TAPIRPCheffControllerProduto);

end.
