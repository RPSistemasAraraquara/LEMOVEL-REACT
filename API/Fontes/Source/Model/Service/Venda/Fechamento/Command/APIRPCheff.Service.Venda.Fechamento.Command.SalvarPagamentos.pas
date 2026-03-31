unit APIRPCheff.Service.Venda.Fechamento.Command.SalvarPagamentos;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Math,
  System.Generics.Collections,
  System.DateUtils,
  System.SysUtils;

type

  TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentos = class(TAPIRPCheffServiceVendaFechamentoCommand)
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentos }

uses
  APIRPCheff.Service.Venda.Fechamento.Command.SalvarPagamentos.VendaNormal,
  APIRPCheff.Service.Venda.Fechamento.Command.SalvarPagamentos.VendaPrePaga;

procedure TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentos.Execute(
  AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LCommand: TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentos;
begin
  LCommand := nil;
  try
    if FParent.Venda.VendaPrePaga then
      LCommand := TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaPrePaga.Create(FParent, FContext)
    else
      LCommand := TAPIRPCheffServiceVendaFechamentoCommandSalvarPagamentosVendaNormal.Create(FParent, FContext);
    LCommand.Execute(AFechamento);
  finally
    FreeAndNil(LCommand);
  end;
end;

end.
