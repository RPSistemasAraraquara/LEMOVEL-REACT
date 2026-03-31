unit APIRPCheff.Service.Venda.CancelarItem;

interface

uses
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaCancelarItem = class
  private
    FDAO          : TAPIRPCheffDAOFactory;
    FCancelamento : TAPIRPCheffEntityVendaItemCancelamento;

    procedure ValidarVenda;
    procedure CancelarVendaItem;
    procedure AtualizarValorVenda;
  public
    function DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaCancelarItem;
    function Cancelamento(AValue: TAPIRPCheffEntityVendaItemCancelamento): TAPIRPCheffServiceVendaCancelarItem;
    procedure Execute;
  end;

implementation

{ TAPIRPCheffServiceVendaCancelarItem }

procedure TAPIRPCheffServiceVendaCancelarItem.AtualizarValorVenda;
var
  LVendaDAO: TAPIRPCheffDAOVenda;
begin
  LVendaDAO := FDAO.VendaDAO;
  LVendaDAO.ManagerTransaction(False);
  try
    LVendaDAO.AtualizarTotalVenda(FCancelamento.idEmpresa, FCancelamento.idVenda);
  except
    on E: Exception do
    begin
      E.Message := 'Erro ao salvar atualizar total da venda: ' + E.Message;
      raise;
    end;
  end;
end;

function TAPIRPCheffServiceVendaCancelarItem.Cancelamento(
  AValue: TAPIRPCheffEntityVendaItemCancelamento): TAPIRPCheffServiceVendaCancelarItem;
begin
  Result := Self;
  FCancelamento := AValue;
end;

procedure TAPIRPCheffServiceVendaCancelarItem.CancelarVendaItem;
var
  LDAO: TAPIRPCheffDAOVendaItem;
begin
  LDAO := FDAO.VendaItemDAO;
  LDAO.ManagerTransaction(False);
  LDAO.Cancelar(FCancelamento);
end;

function TAPIRPCheffServiceVendaCancelarItem.DAO(AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaCancelarItem;
begin
  Result := Self;
  FDAO := AValue;
end;

procedure TAPIRPCheffServiceVendaCancelarItem.Execute;
begin
  ValidarVenda;
  FDAO.StartTransaction;
  try
    CancelarVendaItem;
    AtualizarValorVenda;
    FDAO.Commit;
  except
    FDAO.Rollback;
    raise;
  end;
end;

procedure TAPIRPCheffServiceVendaCancelarItem.ValidarVenda;
var
  LVenda: TAPIRPCheffEntityVenda;
begin
  LVenda := FDAO.VendaDAO.Buscar(FCancelamento.idVenda);
  try
    if LVenda.situacao = svPreFechamento then
      raise Exception.Create('Pr'#233'-Fechamento j'#225' emitido. Realize o cancelamento pelo caixa!');
  finally
    FreeAndNil(LVenda);
  end;
end;

end.
