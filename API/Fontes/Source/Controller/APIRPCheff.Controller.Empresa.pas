unit APIRPCheff.Controller.Empresa;

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
  [SwagPath('empresa', 'Empresa')]
  TAPIRPCheffControllerEmpresa = class(TAPIRPCheffControllerBase)
  public
    [SwagGET('Listar Empresas')]
    [SwagResponse(200, TAPIRPCheffEntityEmpresa, True)]
    procedure Listar;

    [SwagGET('{idEmpresa}', 'Buscar empresa')]
    [SwagParamPath('idEmpresa', 'Id da empresa')]
    [SwagResponse(200, TAPIRPCheffEntityEmpresa)]
    procedure Buscar;

    [SwagGET('{idEmpresa}/configuracaoMesa', 'Configuracao mesa da empresa')]
    [SwagParamPath('idEmpresa', 'Id da empresa')]
    [SwagParamQuery('terminalAbertura', 'Nome do terminal cadastrado')]
    [SwagResponse(200, TAPIRPCheffEntityConfiguracaoMesa)]
    procedure BuscarConfiguracaoMesa;

    [SwagGET('{idEmpresa}/configuracaoComanda', 'Configuracao comanda da empresa')]
    [SwagParamPath('idEmpresa', 'Id da empresa')]
    [SwagParamQuery('terminalAbertura', 'Nome do terminal cadastrado')]
    [SwagResponse(200, TAPIRPCheffEntityConfiguracaoComanda)]
    procedure BuscarConfiguracaoComanda;
  end;

implementation

{ TAPIRPCheffControllerEmpresa }

procedure TAPIRPCheffControllerEmpresa.Buscar;
var
  LIdEmpresa: Integer;
  LEmpresa: TAPIRPCheffEntityEmpresa;
begin
  LIdEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
  LEmpresa := Controller.DAO.IdEmpresa(LIdEmpresa).EmpresaDAO.Busca;
  try
    Self.Response(LEmpresa);
  finally
    FreeAndNil(LEmpresa);
  end;
end;

procedure TAPIRPCheffControllerEmpresa.BuscarConfiguracaoComanda;
var
  LIdEmpresa: Integer;
  LConfiguracao: TAPIRPCheffEntityConfiguracaoComanda;
  LTerminal: string;
begin
  LIdEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
  LTerminal := '';
  if FRequest.Query.ContainsKey('terminalAbertura') then
    LTerminal := FRequest.Query.Field('terminalAbertura').AsString;
  LConfiguracao := Controller.DAO.ConfiguracaoComandaDAO.Buscar(LIdEmpresa, LTerminal);
  try
    Self.Response(LConfiguracao);
  finally
    FreeAndNil(LConfiguracao);
  end;
end;

procedure TAPIRPCheffControllerEmpresa.BuscarConfiguracaoMesa;
var
  LIdEmpresa: Integer;
  LConfiguracao: TAPIRPCheffEntityConfiguracaoMesa;
  LTerminal: string;
begin
  LIdEmpresa := FRequest.Params.Field('idEmpresa').AsInteger;
  LTerminal := '';
  if FRequest.Query.ContainsKey('terminalAbertura') then
    LTerminal := FRequest.Query.Field('terminalAbertura').AsString;
  LConfiguracao := Controller.DAO.ConfiguracaoMesaDAO.Buscar(LIdEmpresa, LTerminal);
  try
    Self.Response(LConfiguracao);
  finally
    FreeAndNil(LConfiguracao);
  end;
end;

procedure TAPIRPCheffControllerEmpresa.Listar;
var
  LEmpresas: TObjectList<TAPIRPCheffEntityEmpresa>;
begin
  LEmpresas := Controller(0).DAO.EmpresaDAO.List;
  try
    Self.Response<TAPIRPCheffEntityEmpresa>(LEmpresas);
  finally
    FreeAndNil(LEmpresas);
  end;
end;

initialization
  THorseGBSwaggerRegistry.RegisterPath(TAPIRPCheffControllerEmpresa);

end.
