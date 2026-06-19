program RPCheffGarcomAPILinux;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.SysUtils,
  APIRPCheff.Resources in 'Resources\APIRPCheff.Resources.pas',
  APIRPCheff.Controller.API in 'Source\Controller\APIRPCheff.Controller.API.pas',
  APIRPCheff.Controller.Categoria in 'Source\Controller\APIRPCheff.Controller.Categoria.pas',
  APIRPCheff.Controller.Comanda in 'Source\Controller\APIRPCheff.Controller.Comanda.pas',
  APIRPCheff.Controller.Empresa in 'Source\Controller\APIRPCheff.Controller.Empresa.pas',
  APIRPCheff.Controller.FormaPagamento in 'Source\Controller\APIRPCheff.Controller.FormaPagamento.pas',
  APIRPCheff.Controller.Mesa in 'Source\Controller\APIRPCheff.Controller.Mesa.pas',
  APIRPCheff.Controller.Produto in 'Source\Controller\APIRPCheff.Controller.Produto.pas',
  APIRPCheff.Controller.Usuario in 'Source\Controller\APIRPCheff.Controller.Usuario.pas',
  APIRPCheff.Controller.Venda in 'Source\Controller\APIRPCheff.Controller.Venda.pas',
  APIRPCheff.Controller.VendaItem in 'Source\Controller\APIRPCheff.Controller.VendaItem.pas';

begin
  try
    CreateServer;
    StartServer;
    Writeln(Format('RPCheff Mobile API online na porta %d.', [APP_RESOURCES.API_PORT]));
    Writeln('Pressione Ctrl+C para encerrar.');

    while True do
      TThread.Sleep(1000);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
