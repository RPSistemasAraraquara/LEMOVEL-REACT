unit APIRPCheff.Controller.FormaPagamento;

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
  [SwagPath('empresa/{idEmpresa}/formaPagamento', 'Forma Pagamento')]
  [SwagParamPath('idEmpresa', 'Id da empresa')]
  TAPIRPCheffControllerFormaPagamento = class(TAPIRPCheffControllerBase)
  public
    [SwagGET('Listar Formas de Pagamento')]
    [SwagResponse(200, TAPIRPCheffEntityFormaPagamento, True)]
    procedure Listar;
  end;

implementation

{ TAPIRPCheffControllerFormaPagamento }

procedure TAPIRPCheffControllerFormaPagamento.Listar;
var
  LPagamentos: TObjectList<TAPIRPCheffEntityFormaPagamento>;
begin
  LPagamentos := Controller.DAO.IdEmpresa(IdEmpresa)
    .FormaPagamentoDAO.Lista;
  try
    Self.Response<TAPIRPCheffEntityFormaPagamento>(LPagamentos);
  finally
    FreeAndNil(LPagamentos);
  end;
end;

initialization
  THorseGBSwaggerRegistry.RegisterPath(TAPIRPCheffControllerFormaPagamento);

end.
