unit APIRPCheff.Service.Venda.Fechamento.Command.ValidarFechamento;

interface

uses
  APIRPCheff.Service.Venda.Fechamento.Command,
  APIRPCheff.Entity.Classes,
  System.Generics.Collections,
  APIRPCheff.Entity.Types,
  System.Math,
  System.SysUtils;

type
  TAPIRPCheffServiceVendaFechamentoCommandValidarFechamento = class(TAPIRPCheffServiceVendaFechamentoCommand)
  private
    FFechamento: TAPIRPCheffEntityVendaPostFechamento;
    procedure ValidarDesconto;
    function CalcularValorPagamentoAntecipado(AIdVenda: Integer): Currency;
  public
    procedure Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento); override;
  end;

implementation

{ TAPIRPCheffServiceVendaFechamentoCommandValidarFechamento }

procedure TAPIRPCheffServiceVendaFechamentoCommandValidarFechamento.Execute(AFechamento: TAPIRPCheffEntityVendaPostFechamento);
var
  LValorPendente: Currency;
  LValorPagamentoAntecipado: Currency;
begin
  FFechamento := AFechamento;

  if AFechamento.idUsuario <= 0 then
    raise Exception.Create('IdUsuario fechamento N'#227'o informado.');

  if AFechamento.idVenda <= 0 then
    raise Exception.Create('IdVenda N'#227'o informado.');

  LValorPagamentoAntecipado := CalcularValorPagamentoAntecipado(AFechamento.idVenda);
  LValorPendente            := FParent.Venda.valorTotal - AFechamento.valorDesconto - LValorPagamentoAntecipado;

  if LValorPendente > AFechamento.ValorPagamento then
    raise Exception.CreateFmt('Valor pagamento %s menor que o valor pendente da Venda %s.',
      [FormatCurr('R$ ,0.00', AFechamento.ValorPagamento),
       FormatCurr('R$ ,0.00', LValorPendente)]);

  ValidarDesconto;
end;


function TAPIRPCheffServiceVendaFechamentoCommandValidarFechamento.CalcularValorPagamentoAntecipado(AIdVenda: Integer): Currency;
var
  LVendaPagamentoAntecipado: TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
  LPagamento               : TAPIRPCheffEntityVendaPagamentoAntecipado;
begin
  Result := 0;
  LVendaPagamentoAntecipado := FParent.DAO.VendaPagamentoAntecipadoDAO.Listar(AIdVenda);
  try
    for LPagamento in LVendaPagamentoAntecipado do
      Result := Result + LPagamento.Valor;
  finally
    FreeAndNil(LVendaPagamentoAntecipado);
  end;
end;


procedure TAPIRPCheffServiceVendaFechamentoCommandValidarFechamento.ValidarDesconto;
var
  LUsuario        : TAPIRPCheffEntityUsuario;
  LValorPagamento : Currency;
  LValorProdutos  : Currency;
  LPercentual     : Currency;
  LMaximoPermitido: Currency;
begin
  if FFechamento.valorDesconto <= 0 then
    Exit;

  LValorProdutos := RoundTo(FParent.Venda.TotalItens, -2);
  if LValorProdutos < 0 then
    LValorProdutos := 0;
  if FFechamento.valorDesconto > LValorProdutos then
    raise Exception.CreateFmt('Desconto n'#227'o pode ser maior que o valor total dos produtos %s.',
      [FormatCurr('R$ ,0.00', LValorProdutos)]);

  LUsuario := FParent.DAO.UsuarioDAO.Busca(FFechamento.idUsuario);
  try
    if not Assigned(LUsuario) then
      raise Exception.CreateFmt('usu'#225'rio %d N'#227'o encontrado.', [FFechamento.idUsuario]);

    if not LUsuario.PermiteDescontoFechamento then
      raise Exception.Create('Usu'#225'rio n'#227'o possui permiss'#227'o para aplicar desconto no fechamento.');

    LValorPagamento := FFechamento.ValorPagamento;
    LPercentual := FFechamento.valorDesconto;
    if FFechamento.tipoDesconto = tdValor then
      LPercentual := (FFechamento.valorDesconto / LValorPagamento) * 100;

    LPercentual := RoundTo(LPercentual, -2);
    LMaximoPermitido := RoundTo(LUsuario.descontoMaximo, -2);
    if LPercentual > LMaximoPermitido then
      raise Exception.CreateFmt('Desconto aplicado foi de %s%% , M'#195#161'ximo permitido '#224' de %s%%.',
        [FormatCurr(',0.00', LPercentual), FormatCurr(',0.00', LMaximoPermitido)]);
  finally
    FreeAndNil(LUsuario);
  end;
end;

end.
