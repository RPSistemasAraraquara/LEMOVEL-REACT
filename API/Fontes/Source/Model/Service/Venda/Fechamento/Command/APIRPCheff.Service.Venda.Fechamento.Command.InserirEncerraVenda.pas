unit APIRPCheff.Service.Venda.Fechamento.Command.InserirEncerraVenda;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  System.Math,
  System.Generics.Collections,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandInserirEncerraVenda =   class(TAPIRPCheffServiceVendaFechamentoCommand)
  private
    FFechamento: TAPIRPCheffEntityVendaPostFechamento;
    function ObterIdFormaPagamento: Integer;
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandInserirEncerraVenda }

procedure TAPIRPCheffServiceVendaFechamentoCommandInserirEncerraVenda.Execute(
  AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LEncerraVenda: TAPIRPCheffEntityEncerraVenda;
  LVenda: TAPIRPCheffEntityVenda;
  LDAO: TAPIRPCheffDAOEncerraVenda;
begin
  FFechamento := AFechamento;
  LEncerraVenda := FParent.DAO.EncerraVendaDAO.Buscar(AFechamento.idVenda);
  LVenda := FParent.Venda;
  try
    if Assigned(LEncerraVenda) then
    begin
      FParent.IdEncerraVenda(LEncerraVenda.idEncerraVenda);
      Exit;
    end
    else
    begin
      LEncerraVenda             := TAPIRPCheffEntityEncerraVenda.Create;
      LEncerraVenda.idEmpresa   := AFechamento.idEmpresa;
      LEncerraVenda.idVenda     := AFechamento.idVenda;
      LEncerraVenda.valor       := LVenda.valorTotal;
      LEncerraVenda.idFormaPgto := ObterIdFormaPagamento;
      if AFechamento.pagamentos.Count > 0 then
        if AFechamento.pagamentos[0].formaPagamento.cortesia then
          LEncerraVenda.valor   := 0;

      LDAO                      := FParent.DAO.EncerraVendaDAO;
      LDAO.ManagerTransaction(False);
      LDAO.Inserir(LEncerraVenda);
      FParent.IdEncerraVenda(LEncerraVenda.idEncerraVenda);
    end;
  finally
    FreeAndNil(LEncerraVenda);
  end;
end;

function TAPIRPCheffServiceVendaFechamentoCommandInserirEncerraVenda.ObterIdFormaPagamento: Integer;
var
  LPrePago: TObjectList<TAPIRPCheffEntityVendaPrePago>;
  LValorAntecipado : TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
begin
  Result := -1;
  if FFechamento.pagamentos.Count > 0 then
   Result := FFechamento.pagamentos[0].idFormaPgto
  else
  begin
    LValorAntecipado :=FParent.DAO.VendaPagamentoAntecipadoDAO.Listar(FFechamento.idVenda);
      try
       if LValorAntecipado.Count > 0 then
      begin
        Result := LValorAntecipado[0].idFormaPagamento;
        if FFechamento.pagamentos.Count > 0 then
          FFechamento.pagamentos[0].idFormaPgto := Result;

        Exit;
      end
      else
      begin
        LPrePago := FParent.DAO.VendaPrePagoDAO.Listar(FFechamento.idVenda);
        try
          if LPrePago.Count > 0 then
            Result := LPrePago[0].IdFormaPagamento;
        finally
          FreeAndNil(LPrePago);
        end;
      end;
    finally
      FreeAndNil(LValorAntecipado);
    end;
  end;


end;

end.
