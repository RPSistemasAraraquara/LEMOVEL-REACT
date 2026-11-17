unit APIRPCheff.Service.Venda.PreFechamento;

interface

uses
  System.SysUtils,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.Components,
  APIRPCheff.DAO.Factory;

type
  TAPIRPCheffServiceVendaPreFechamento = class
  private
    FComponents : TAPIRPCheffComponents;
    FDAO        : TAPIRPCheffDAOFactory;
    FPatch      : TAPIRPCheffEntityVendaPatchPreFechamento;
  public

    function Components(const AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaPreFechamento;
    function DAO(const AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaPreFechamento;
    function Patch(const AValue: TAPIRPCheffEntityVendaPatchPreFechamento): TAPIRPCheffServiceVendaPreFechamento;
    procedure Execute;
  end;

implementation

{ TAPIRPCheffServiceVendaPreFechamento }

function TAPIRPCheffServiceVendaPreFechamento.Components(const AValue: TAPIRPCheffComponents): TAPIRPCheffServiceVendaPreFechamento;
begin
  Result      := Self;
  FComponents := AValue;
end;

function TAPIRPCheffServiceVendaPreFechamento.DAO(const AValue: TAPIRPCheffDAOFactory): TAPIRPCheffServiceVendaPreFechamento;
begin
  Result  := Self;
  FDAO    := AValue;
end;

procedure TAPIRPCheffServiceVendaPreFechamento.Execute;
var
  LVendaDAO: TAPIRPCheffDAOVenda;
  LVenda: TAPIRPCheffEntityVenda;
  LValorTaxa: Currency;
  LIgnorarTaxa: Boolean;
begin
  LVendaDAO := FDAO.IdEmpresa(FPatch.idEmpresa).VendaDAO;
  LVendaDAO.IdEmpresa(FPatch.idEmpresa);
  LVendaDAO.ManagerTransaction(False);
  FDAO.StartTransaction;
  try
    // PreFechamento valida a situacao e bloqueia a venda nesta transacao.
    LVendaDAO.PreFechamento(FPatch);
    LVenda := LVendaDAO.Buscar(FPatch.idVenda);
    try
      FreeAndNil(LVenda.itens);
      LVenda.itens := FDAO.VendaItemDAO.Listar(LVenda.idVenda, siOK);

      LValorTaxa := 0;
      LIgnorarTaxa := True;
      if LVenda.tipoVenda in [tvMesa, tvComanda] then
      begin
        // Sem taxa para escolher na tela, conserva a dispensa ja registrada.
        LIgnorarTaxa := LVenda.ignorarTaxaGarcom;
        if LVenda.valorTaxaServicoDisponivel > 0 then
        begin
          LIgnorarTaxa := not FPatch.CobrarTaxaGarcom;
          if not LIgnorarTaxa then
            LValorTaxa := LVenda.valorTaxaServicoDisponivel;
        end;
      end;

      LVendaDAO.AtualizarTotalVenda(LVenda.idEmpresa, LVenda.idVenda, LVenda.TotalItens,
        LValorTaxa, LVenda.percentualTaxaServico, LIgnorarTaxa);
    finally
      LVenda.Free;
    end;
    FDAO.Commit;
  except
    FDAO.Rollback;
    raise;
  end;
end;

function TAPIRPCheffServiceVendaPreFechamento.Patch(const AValue: TAPIRPCheffEntityVendaPatchPreFechamento): TAPIRPCheffServiceVendaPreFechamento;
begin
  Result := Self;
  FPatch := AValue;
end;

end.
