unit APIRPCheff.Service.Venda.Impressao42Colunas;

interface

uses
  APIRPCheff.Service.Venda.Impressao,
  APIRPCheff.Service.Venda.Consulta,
  APIRPCheff.Resources,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  APIRPCheff.Utils,
  System.Generics.Collections,
  System.SysUtils,
  System.Math,
  System.Classes,
  System.StrUtils;

type
  TAPIRPCheffServiceVendaImpressao42Colunas = class(TAPIRPCheffServiceVendaImpressao)
  private
    FData          : TDateTime;
    FEmpresa       : TAPIRPCheffEntityEmpresa;
    FVenda         : TAPIRPCheffEntityVenda;
    FVendaItens    : TObjectList<TAPIRPCheffEntityVendaItem>;
    FValorPendente : Currency;
    FImpressao     : string;

    procedure CarregarVenda;
    procedure CarregarEmpresa;
    procedure CarregarItens;
    procedure CarregarItemNormal(AItem: TAPIRPCheffEntityVendaItem);
    procedure CarregarItemFracionado;
    procedure CarregarOpcionais(AItem: TAPIRPCheffEntityVendaItem);
    procedure CarregarTotal;
    procedure CarregarPagamentosAntecipados;
    procedure CarregarPagamentos;
    procedure CarregarGarcons;
    procedure CarregarRodape;
  public
    destructor Destroy; override;

    function Execute: TStream; override;
  end;

implementation

{ TAPIRPCheffServiceVendaImpressao42Colunas }

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarEmpresa;
begin
  FreeAndNil(FEmpresa);
  FDAO.EmpresaDAO.IdEmpresa(FIdEmpresa);
  FEmpresa := FDAO.EmpresaDAO.Busca;
  if not Assigned(FEmpresa) then
    raise Exception.CreateFmt('Empresa %d N'#227'o encontrada.', [FIdEmpresa]);

  FImpressao := '</zera>' + sLineBreak +
    '<n><e>' + QuebraLinhaItemCupom(FEmpresa.nome, 42) + '</n></e>' + sLineBreak +
    AcertaTexto(FEmpresa.endereco, 'E', 34) +
    AcertaTexto(FEmpresa.numero, 'E', 8) + sLineBreak;

  if FEmpresa.telefonePrincipal = 0 then
    FImpressao := FImpressao + 'FONE: ' + AcertaTexto(FEmpresa.telefone, 'E', 40) + sLineBreak
  else
    FImpressao := FImpressao + 'FONE: ' + AcertaTexto(FEmpresa.celular, 'E', 40) + sLineBreak;

  FImpressao := FImpressao + '</linha_dupla>' + sLineBreak;
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarGarcons;
var
  LGarcons: TList<Integer>;
  LTextoGarcom: string;
begin
  LGarcons := TList<Integer>.Create;
  try
    LTextoGarcom := EmptyStr;

    for var LItem in FVendaItens do
    begin
      if LItem.idGarcom <= 0 then
        Continue;

      if LGarcons.Contains(LItem.idGarcom) then
        Continue;

      var LGarcom := FDAO.UsuarioDAO.Busca(LItem.idGarcom);
      try
        if not Assigned(LGarcom) then
          Continue;

        if Trim(LGarcom.nome) = EmptyStr then
          Continue;

        if LTextoGarcom <> EmptyStr then
          LTextoGarcom := LTextoGarcom + ', ';
        LTextoGarcom := LTextoGarcom + LGarcom.nome;
        LGarcons.Add(LItem.idGarcom);
      finally
        LGarcom.Free;
      end;
    end;

    if LTextoGarcom <> EmptyStr then
    begin
      FImpressao := FImpressao +
        '</linha_simples>' + sLineBreak +
        '</ce><n>GAR'#199'ONS</n></ae>' + sLineBreak +
        '<n>' + QuebraLinhaItemCupom(LTextoGarcom, 42) + '</n>' + sLineBreak;
    end;
  finally
    LGarcons.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarItemFracionado;
var
  LPossuiFracionado: Boolean;
  LDescricaoTamanhoFormatado:string;
begin
  LPossuiFracionado := False;
  for var LItem in FVendaItens do
  begin
    LPossuiFracionado := LItem.Fracionado;
    if LPossuiFracionado then
      Break;
  end;

  if not LPossuiFracionado then
    Exit;

  FImpressao := FImpressao + '</linha_simples>' + sLineBreak;

  for var LItem in FVendaItens do
  begin
    if not LItem.Fracionado then
      Continue;

    FImpressao := FImpressao +
      '</ce><n>------------- Item Fracionado ------------</n></ae>' + sLineBreak;


    for var LFracao in LItem.fracoes do
    begin
      LDescricaoTamanhoFormatado := IfThen(LFracao.descricaoTamanho <> '', ' (' + LFracao.descricaoTamanho + ')', '');

      FImpressao := FImpressao + QuebraLinhaItemCupom(LFracao.produtoDescricao + LDescricaoTamanhoFormatado, 17, '',
        AcertaTexto(Format('%.2f', [LFracao.valorUnitario]), 'D', 9) +
        AcertaTexto(FormatarQuantidadeFracionada(LFracao.quantidade, LFracao.valorUnitario, LFracao.valorTotal), 'D', 7) +
        AcertaTexto(Format('%.2f', [LFracao.valorTotal]), 'D', 9)) + sLineBreak;
    end;

    FImpressao := FImpressao + '</linha_simples>' + sLineBreak;

    if not FImprimirOpcionais then
      Continue;

    for var LOpcional in LItem.opcionais do
      FImpressao := FImpressao + '<n>' +
        QuebraLinhaItemCupom(LOpcional.descricao, 38, '    ', '') +
        '</n>' + sLineBreak + sLineBreak;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarItemNormal(AItem: TAPIRPCheffEntityVendaItem);
var
  LFormatoQuantidade: string;
    LDescricaoTamanhoFormatado:string;
begin
  LFormatoQuantidade := '%.3f';
  if (not FImprimirDecimais) and (AItem.quantidade - Trunc(AItem.quantidade) = 0) then
    LFormatoQuantidade := '%.0f';

    LDescricaoTamanhoFormatado := IfThen(AItem.descricaoTamanho <> '', ' (' + AItem.descricaoTamanho + ')', '');

  FImpressao := FImpressao + QuebraLinhaItemCupom(AItem.produtoDescricao +LDescricaoTamanhoFormatado , 17, '',
    AcertaTexto(Format('%.2f', [AItem.valorUnitario]), 'D', 9) +
    AcertaTexto(Format(LFormatoQuantidade, [AItem.quantidade]), 'D', 7) +
    AcertaTexto(Format('%.2f', [AItem.valorTotal]), 'D', 9)) + sLineBreak + sLineBreak;

  if FImprimirOpcionais then
    CarregarOpcionais(AItem);
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarItens;
begin
  FImpressao := FImpressao +
    'descri'#231#227'o do item   Valor   Qtde.    Total' + sLineBreak +
    '</linha_simples>' + sLineBreak;

  FreeAndNil(FVendaItens);
  FVendaItens := FDAO.VendaItemDAO.ListarVendasAgrupadosProdutos(FIdVenda);

  for var LItem in FVendaItens do
    if not LItem.Fracionado then
      CarregarItemNormal(LItem);

  CarregarItemFracionado;
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarOpcionais(AItem: TAPIRPCheffEntityVendaItem);
var
  LOpcionais: TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
begin
  if not FImprimirOpcionais then
    Exit;
  LOpcionais := FDAO.VendaItemOpcionalDAO.ListarAgrupadoPorProduto(FIdVenda, AItem.numeroItem);
  try
    for var LOpcional in LOpcionais do
      FImpressao := FImpressao + '<n>' +
        QuebraLinhaItemCupom(LOpcional.descricao, 38, '    ', '') +
          '</n>' + slinebreak + slinebreak;
  finally
    LOpcionais.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarPagamentos;
var
  LEncerramentos: TObjectList<TAPIRPCheffEntityEncerraVendaItem>;
  LTotalTroco: Currency;
begin
  LTotalTroco := 0;
  LEncerramentos := FDAO.EncerraVendaItemDAO.Listar(FVenda.idVenda);
  try
    for var LEncerramento in LEncerramentos do
    begin
      LTotalTroco := LTotalTroco + LEncerramento.trocoDinheiro;
      FValorPendente := FValorPendente - LEncerramento.valor;
      FImpressao := FImpressao + '<n>' +
        AcertaTexto(LEncerramento.formaPagamento.descricao, 'E', 33) +
        AcertaTexto(Format('%.2f',[LEncerramento.ValorPago]), 'D', 9) + '</n>' + sLineBreak;
    end;
    if LTotalTroco > 0 then
      FImpressao := FImpressao + '<n>' +
        AcertaTexto('TROCO', 'E', 33) +
        AcertaTexto(Format('%.2f',[LTotalTroco]), 'D', 9) + '</n>' + sLineBreak;

    if FValorPendente > 0 then
      FImpressao := FImpressao + '<n>' +
        AcertaTexto('VALOR PENDENTE', 'E', 33) +
        AcertaTexto(Format('%.2f',[FValorPendente]), 'D', 9) + '</n>' + sLineBreak;
  finally
    LEncerramentos.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarPagamentosAntecipados;
var
  LPagamentos: TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
begin
  LPagamentos := FDAO.VendaPagamentoAntecipadoDAO.Listar(FIdVenda);
  try
    for var LPagamento in LPagamentos do
    begin
      FValorPendente := FValorPendente - LPagamento.valor;
      FImpressao := FImpressao + '<n>' +
        AcertaTexto(LPagamento.formaPagamento.descricao, 'E', 33) +
        AcertaTexto(Format('%.2f',[LPagamento.valor]), 'D', 9) + '</n>' + sLineBreak
    end;
  finally
    LPagamentos.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarRodape;
begin
  FImpressao := FImpressao + '</linha_simples>' + sLineBreak +
    '</ce>RPCheff' + sLineBreak +
    'vers'#227'o ' + APP_RESOURCES.VersaoSistema + sLineBreak +
    '</linha_simples>' + sLineBreak;

  FImpressao := FImpressao + sLineBreak + '</corte_total>';
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarTotal;
var
  LTotalItens: Currency;
  LDesconto: Currency;
  LQuantidadeItens: Integer;
begin
  LTotalItens := 0;
  LDesconto := 0;
  LQuantidadeItens := 0;
  for var LItem in FVendaItens do
  begin
    if LItem.TotalFracoes>0 then
      LTotalItens := LTotalItens + LItem.TotalFracoes
    else
      LTotalItens := LTotalItens + LItem.valorTotal;


    LDesconto := LDesconto + LItem.desconto;
    LQuantidadeItens := LQuantidadeItens + 1 + LItem.fracoes.Count;
  end;

  FImpressao := FImpressao + '</linha_simples>' + sLineBreak +
    'Sub Total.......................:' +
    AcertaTexto(Format('R$ %.2f', [LTotalItens + LDesconto]), 'D', 9) + sLineBreak;

  if LDesconto > 0 then
    FImpressao := FImpressao +
      '    Desconto nos itens: ' + Format('%.2f',  [LDesconto]) + sLineBreak;

  if FEmpresa.casaNoturna then
  begin
    FImpressao := FImpressao + AcertaTexto('Taxa Entrada (+)', 'E', 32, '.') + ':' +
      AcertaTexto(Format('%.2f', [FVenda.valorEntrada]), 'D', 9) + sLineBreak;

    FImpressao := FImpressao +
      AcertaTexto('Taxa Cart'#227'o (+)', 'E', 32, '.') + ':' +
      AcertaTexto(Format('%.2f', [FVenda.taxaCartao]), 'D', 9) + sLineBreak +
      AcertaTexto('Taxa de servi'#231'o (+)', 'E', 32, '.') + ':' +
      AcertaTexto(Format('%.2f', [FVenda.valorTaxaServico]), 'D', 9) + sLineBreak + sLineBreak +
      '<n><e>TOTAL CONTA' + AcertaTexto(Format('R$ %.2f', [FVenda.valorTotal]), 'D', 10) +
      '</e></n>' + sLineBreak + '</linha_simples>' + sLineBreak +
      'Qtde. de itens: ' + LQuantidadeItens.ToString + sLineBreak +
      '' + sLineBreak + '</linha_simples>' + sLineBreak;
  end
  else
  begin
    if FVenda.valorTaxaServico > 0 then
      FImpressao := FImpressao + AcertaTexto('Taxa de servi'#231'o (+)', 'E', 32, '.') + ':' +
        AcertaTexto(Format('%.2f', [FVenda.valorTaxaServico]), 'D', 9) + sLineBreak;

    if FVenda.ValorCouvert > 0 then
      FImpressao := FImpressao + AcertaTexto(FMensagemCouvert, 'E', 32, '.') + ':' +
        AcertaTexto(Format('%.2f', [FVenda.ValorCouvert]), 'D', 9) + sLineBreak;

    FImpressao := FImpressao + sLineBreak +
      '<n><e>TOTAL CONTA' + AcertaTexto(Format('R$ %.2f', [FVenda.valorTotal]), 'D', 10) +
      '</e></n>' + sLineBreak + '</linha_simples>' + sLineBreak +
      'Qtde. de itens: ' + LQuantidadeItens.ToString + sLineBreak +
      'Qtde. de pessoas: ' + FVenda.numeroPessoas.ToString + sLineBreak +
      'Total por pessoa: ' + Format('R$%.2f', [FVenda.ValorPorPessoa]) + sLineBreak +
      '</linha_simples>' + sLineBreak;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao42Colunas.CarregarVenda;
var
  LServiceConsulta: TAPIRPCheffServiceVendaConsulta;
begin
  FreeAndNil(FVenda);
  LServiceConsulta := TAPIRPCheffServiceVendaConsulta.Create;
  try
    LServiceConsulta.DAO(FDAO);
    FVenda := LServiceConsulta.AplicarTaxaServico(False).Buscar(FIdVenda, False);
    if not Assigned(FVenda) then
      raise Exception.CreateFmt('Venda %d N'#227'o encontrada.', [FIdVenda]);

    FValorPendente := FVenda.valorTotal;
    FImpressao := FImpressao + '<n><e></ae>' + FVenda.DescricaoMesaComanda + ' - Cupom: ' + FVenda.numeroCupom.ToString +
      '</n></e>' + sLineBreak +
      'Abertura:   ' + FormatDateTime('dd/mm/yyyy hh:nn', FVenda.dataAbertura) + sLineBreak +
      'Fechamento: ' + FormatDateTime('dd/mm/yyyy hh:nn', FData) +
      '    Sem Valor Fiscal' + sLineBreak +
      '</linha_simples>' + sLineBreak;
  finally
    LServiceConsulta.Free;
  end;
end;

destructor TAPIRPCheffServiceVendaImpressao42Colunas.Destroy;
begin
  FVenda.Free;
  FEmpresa.Free;
  FVendaItens.Free;
  inherited;
end;

function TAPIRPCheffServiceVendaImpressao42Colunas.Execute: TStream;
begin
  FImpressao := EmptyStr;
  FData := Now;
  CarregarEmpresa;
  CarregarVenda;
  CarregarItens;
  CarregarTotal;
  CarregarPagamentosAntecipados;
  CarregarPagamentos;
  CarregarGarcons;
  CarregarRodape;

  Result := TStringStream.Create(FImpressao, TEncoding.UTF8);
end;

end.
