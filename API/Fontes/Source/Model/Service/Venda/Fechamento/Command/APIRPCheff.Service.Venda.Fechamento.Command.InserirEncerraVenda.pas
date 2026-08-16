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
    function ObterConfiguracao: TAPIRPCheffEntityConfiguracaoMesaComanda;
    function ObterValorAcrescimo: Currency;
    function ObterCpfCnpjNota: string;
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
  LCpfCnpjNota: string;
begin
  FFechamento := AFechamento;
  LCpfCnpjNota := ObterCpfCnpjNota;
  LEncerraVenda := FParent.DAO.EncerraVendaDAO.Buscar(AFechamento.idVenda);
  LVenda := FParent.Venda;
  try
    if Assigned(LEncerraVenda) then
    begin
      // Retentativa de fechamento: honra o CPF/CNPJ informado NESTA tentativa
      // (a emissao pos-commit le encerravenda.ven_cpfconsum).
      if LCpfCnpjNota <> '' then
      begin
        LDAO := FParent.DAO.EncerraVendaDAO;
        LDAO.ManagerTransaction(False);
        LDAO.AtualizarCpfConsumidor(LEncerraVenda.idEncerraVenda, LCpfCnpjNota);
      end;
      FParent.IdEncerraVenda(LEncerraVenda.idEncerraVenda);
      Exit;
    end
    else
    begin
      LEncerraVenda               := TAPIRPCheffEntityEncerraVenda.Create;
      LEncerraVenda.idEmpresa     := AFechamento.idEmpresa;
      LEncerraVenda.idVenda       := AFechamento.idVenda;
      LEncerraVenda.valor         := LVenda.valorTotal;
      LEncerraVenda.acrescimo     := ObterValorAcrescimo;
      LEncerraVenda.idFormaPgto   := ObterIdFormaPagamento;
      LEncerraVenda.cpfConsumidor := LCpfCnpjNota;
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

// So digitos e apenas tamanhos validos (11 = CPF, 14 = CNPJ); qualquer outra
// coisa vira vazio (nota sem identificacao). A validacao de digito
// verificador acontece no app antes do envio.
function TAPIRPCheffServiceVendaFechamentoCommandInserirEncerraVenda.ObterCpfCnpjNota: string;
var
  C: Char;
begin
  Result := '';
  for C in FFechamento.cpfCnpjNota do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;

  if (Length(Result) <> 11) and (Length(Result) <> 14) then
    Result := '';
end;

function TAPIRPCheffServiceVendaFechamentoCommandInserirEncerraVenda.ObterConfiguracao: TAPIRPCheffEntityConfiguracaoMesaComanda;
begin
  Result := nil;
  case FParent.Venda.tipoVenda of
    tvMesa:
      Result := FParent.DAO.ConfiguracaoMesaDAO.Buscar(FFechamento.idEmpresa);
    tvComanda:
      Result := FParent.DAO.ConfiguracaoComandaDAO.Buscar(FFechamento.idEmpresa);
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

function TAPIRPCheffServiceVendaFechamentoCommandInserirEncerraVenda.ObterValorAcrescimo: Currency;
var
  LConfiguracao: TAPIRPCheffEntityConfiguracaoMesaComanda;
  LValorTaxaServico: Currency;
  LValorCouvert: Currency;
begin
  LValorTaxaServico := 0;
  if FFechamento.CobrarTaxaGarcom then
    LValorTaxaServico := FFechamento.valorTaxaServico;

  LValorCouvert := 0;
  LConfiguracao := ObterConfiguracao;
  try
    if Assigned(LConfiguracao) and LConfiguracao.utilizaCouvert then
      LValorCouvert := (FFechamento.numeroCouvertMasculino * LConfiguracao.valorCouvertMasculino) +
        (FFechamento.numeroCouvertFeminino * LConfiguracao.valorCouvertFeminino);
  finally
    FreeAndNil(LConfiguracao);
  end;

  Result := SimpleRoundTo(LValorTaxaServico + LValorCouvert, -2);
end;

end.
