unit APIRPCheff.Service.Venda.Impressao32Colunas;

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
  TAPIRPCheffServiceVendaImpressao32Colunas = class(TAPIRPCheffServiceVendaImpressao)
  private
    FData                    : TDateTime;
    FEmpresa                 : TAPIRPCheffEntityEmpresa;
    FVenda                   : TAPIRPCheffEntityVenda;
    FVendaItens              : TObjectList<TAPIRPCheffEntityVendaItem>;
    FValorPendente           : Currency;
    FImpressao               : string;
    FichaImpressaoIndividual : string;
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
    procedure ImprimirFichaIndividualVerificada;
  public
    destructor Destroy; override;
    function Execute: TStream; override;
  end;

implementation

{ TAPIRPCheffServiceVendaImpressao32Colunas }

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarEmpresa;
begin
  FreeAndNil(FEmpresa);
  FDAO.EmpresaDAO.IdEmpresa(FIdEmpresa);
  FEmpresa := FDAO.EmpresaDAO.Busca;
  if not Assigned(FEmpresa) then
    raise Exception.CreateFmt('Empresa %d N'#227'o encontrada.', [FIdEmpresa]);

  FImpressao := '</zera>' + sLineBreak +
    '<n><e>' + QuebraLinhaItemCupom(FEmpresa.nome, 32) + '</n></e>' + sLineBreak +
    AcertaTexto(FEmpresa.endereco, 'E', 23) +
    AcertaTexto(FEmpresa.numero, 'E', 8) + sLineBreak;

  if FEmpresa.telefonePrincipal = 0 then
    FImpressao := FImpressao + 'FONE: ' + AcertaTexto(FEmpresa.telefone, 'E', 26) + sLineBreak
  else
    FImpressao := FImpressao + 'FONE: ' + AcertaTexto(FEmpresa.celular, 'E', 26) + sLineBreak;

  FImpressao := FImpressao + '=='.PadRight(32, '=') + sLineBreak;
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarGarcons;
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
        '=='.PadRight(32, '=') + sLineBreak +
        'GAR'#199'ONS' + sLineBreak +
        QuebraLinhaItemCupom(LTextoGarcom, 32) + sLineBreak;
    end;
  finally
    LGarcons.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarItemFracionado;
var
  LPossuiFracionado: Boolean;
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

  FImpressao := FImpressao + '=='.PadRight(32, '=') + sLineBreak;

  for var LItem in FVendaItens do
  begin
    if not LItem.Fracionado then
      Continue;

    FImpressao := FImpressao +
      '-------- Item Fracionado -------' + sLineBreak;

//    for var LFracao in LItem.fracoes do
//      FImpressao := FImpressao + AcertaTexto(LFracao.produtoDescricao, 'E', 32) + sLineBreak +
//        AcertaTexto(Format('%.2f', [LFracao.valorUnitario]), 'D', 12) +
//        AcertaTexto(CurrToStr(LFracao.quantidade), 'D', 10) +
//        AcertaTexto(Format('%.2f', [LFracao.valorTotal]), 'D', 10) + sLineBreak;
//
//    FImpressao := FImpressao + '=='.PadRight(32, '=') + sLineBreak;

    for var LFracao in LItem.fracoes do
    begin
      FImpressao := FImpressao + LFracao.produtoDescricao ;

      if LFracao.DescricaoTamanho<>EmptyStr then
       FImpressao := FImpressao + ' (' + LFracao.descricaoTamanho + ')';

      FImpressao:=FImpressao+sLineBreak+
        AcertaTexto(Format('R$ %.2f', [LFracao.valorUnitario]), 'D', 12) +
        AcertaTexto(FormatarQuantidadeFracionada(LFracao.quantidade, LFracao.valorUnitario, LFracao.valorTotal), 'D', 10) +
        AcertaTexto(Format('R$ %.2f', [LFracao.valorTotal]), 'D', 10) ;

      FImpressao := FImpressao +  sLineBreak;
    end;


    if not FImprimirOpcionais then
      Continue;

    for var LOpcional in LItem.opcionais do
      FImpressao := FImpressao + '<n>' +
        QuebraLinhaItemCupom(LOpcional.descricao, 28, '    ', '') +
        '</n>' + sLineBreak + sLineBreak;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarItemNormal(AItem: TAPIRPCheffEntityVendaItem);
var
  LFormatoQuantidade: string;
begin
  LFormatoQuantidade := '%.3f';
  if (not FImprimirDecimais) and (AItem.quantidade - Trunc(AItem.quantidade) = 0) then
    LFormatoQuantidade := '%.0f';

  FImpressao := FImpressao + AcertaTexto(AItem.produtoDescricao, 'E', 32) + sLineBreak +
    AcertaTexto(Format('%.2f', [AItem.valorUnitario]), 'D', 12) +
    AcertaTexto(Format(LFormatoQuantidade, [AItem.quantidade]), 'D', 10) +
    AcertaTexto(Format('%.2f', [AItem.valorTotal]), 'D', 10) + sLineBreak + sLineBreak;

  if FImprimirOpcionais then
    CarregarOpcionais(AItem);
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarItens;
begin
//  FImpressao := FImpressao +
//    'descrição      Valor Qtde. Total' + sLineBreak +
//    '=='.PadRight(32, '=') + sLineBreak;
//
//  FreeAndNil(FVendaItens);
// FVendaItens := FDAO.VendaItemDAO.ListarVendasAgrupadosProdutos(FIdVenda);
//
//  for var LItem in FVendaItens do
//  begin
//    if not LItem.Fracionado  then
//      CarregarItemNormal(LItem);
//  end;
//
//  CarregarItemFracionado;
//  FVendaItens := FDAO.VendaItemDAO.ListarVendasAgrupadosProdutos(FIdVenda);
//
//  for var LItem in FVendaItens do
//    if not LItem.Fracionado then
//      CarregarItemNormal(LItem);
//
//  CarregarItemFracionado;

        FImpressao := FImpressao +
    'Descricao do item' + sLineBreak +
    'Valor         Qtde.       Total'+sLineBreak+
    '--------------------------------' + sLineBreak;

  FreeAndNil(FVendaItens);
  FVendaItens := FDAO.VendaItemDAO.ListarVendasAgrupadosProdutos(FIdVenda);

  for var LItem in FVendaItens do
    if not LItem.Fracionado then
      CarregarItemNormal(LItem);

  CarregarItemFracionado;


end;





procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarOpcionais(AItem: TAPIRPCheffEntityVendaItem);
var
  LOpcionais: TObjectList<TAPIRPCheffEntityVendaItemOpcional>;
begin
  if not FImprimirOpcionais then
    Exit;

 LOpcionais:=FDAO.VendaItemOpcionalDAO.ListarAgrupadoPorProduto(FIdVenda,AItem.numeroItem);
  try
    for var LOpcional in LOpcionais do
      FImpressao := FImpressao + '<n>' +
        QuebraLinhaItemCupom(LOpcional.descricao, 28, '    ', '') +
          '</n>' + sLineBreak + sLineBreak;
  finally
    FreeAndNil(LOpcionais);
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarPagamentos;
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
        AcertaTexto(LEncerramento.formaPagamento.descricao, 'E', 23) +
        AcertaTexto(Format('%.2f',[LEncerramento.ValorPago]), 'D', 9) + '</n>' + sLineBreak;
    end;
    if LTotalTroco > 0 then
      FImpressao := FImpressao + '<n>' +
        AcertaTexto('TROCO', 'E', 23) +
        AcertaTexto(Format('%.2f',[LTotalTroco]), 'D', 9) + '</n>' + sLineBreak;

    if FValorPendente > 0 then
      FImpressao := FImpressao + '<n>' +
        AcertaTexto('VALOR PENDENTE', 'E', 23) +
        AcertaTexto(Format('%.2f',[FValorPendente]), 'D', 9) + '</n>' + sLineBreak;
  finally
    FreeAndNil(LEncerramentos);
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarPagamentosAntecipados;
var
  LPagamentos: TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
begin
  LPagamentos := FDAO.VendaPagamentoAntecipadoDAO.Listar(FIdVenda);
  try
    for var LPagamento in LPagamentos do
    begin
      FValorPendente := FValorPendente - LPagamento.valor;
      FImpressao := FImpressao + '<n>' +
        AcertaTexto(LPagamento.formaPagamento.descricao, 'E', 23) +
        AcertaTexto(Format('%.2f',[LPagamento.valor]), 'D', 9) + '</n>' + sLineBreak
    end;
  finally
    FreeAndNil(LPagamentos);
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarRodape;
begin
  FImpressao := FImpressao + '=='.PadRight(32, '=') + sLineBreak +
    '</ce>RPCheff' + sLineBreak +
    'vers'#227'o ' + APP_RESOURCES.VersaoSistema + sLineBreak +
    '=='.PadRight(32, '=') + sLineBreak;

  FImpressao := FImpressao + sLineBreak + '<ce><e><n>' + sLineBreak +
    sLineBreak + sLineBreak + sLineBreak + sLineBreak;;
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarTotal;
var
  LTotalItens: Currency;
  LDesconto: Currency;
  LQuantidadeItens: Integer;
begin
  LTotalItens := 0;
  LDesconto := 0;
  LQuantidadeItens := 0;
  for var LItem in FVendaItens do
    LQuantidadeItens := LQuantidadeItens + 1 + LItem.fracoes.Count;

  FDAO.VendaItemDAO.TotalizarItensVenda(FIdVenda, LTotalItens, LDesconto);

  FImpressao := FImpressao + sLineBreak +
    'Sub total.............:'+
   AcertaTexto(FormatarMoeda(LTotalItens), 'D', 9) + sLineBreak;

  if LDesconto > 0 then
    FImpressao := FImpressao +
      '    Desconto nos itens: ' + format('%.2f',  [LDesconto]) + sLineBreak;

  if FEmpresa.casaNoturna then
  begin
    FImpressao := FImpressao + AcertaTexto('Taxa Entrada (+)', 'E', 22, '.') + ':' +
      AcertaTexto(Format('%.2f', [FVenda.valorEntrada]), 'D', 9) + sLineBreak;

    FImpressao := FImpressao +
      AcertaTexto('Taxa Cart'#227'o (+)', 'E', 22, '.') + ':' +
      AcertaTexto(Format('%.2f', [FVenda.taxaCartao]), 'D', 9) + sLineBreak +
      AcertaTexto('Taxa de servi'#231'o (+)', 'E', 22, '.') + ':' +
      AcertaTexto(Format('%.2f', [FVenda.valorTaxaServico]), 'D', 9) + sLineBreak + sLineBreak +
      AcertaTexto('_______', 'D', 32) + sLineBreak +
      '<n>TOTAL CONTA' + AcertaTexto(Format('R$%.2f', [FVenda.valorTotal]), 'D', 21) +
      '</n>' + sLineBreak + '................................' + sLineBreak +
      'Qtde. de itens: ' + LQuantidadeItens.ToString + sLineBreak +
      '' + sLineBreak + '=='.PadRight(32, '=') + sLineBreak;
  end
  else
  begin
    if FVenda.valorTaxaServico > 0 then
      FImpressao := FImpressao + AcertaTexto('Taxa de servi'#231'o (+)', 'E', 22, '.') + ':' +
        AcertaTexto(Format('%.2f', [FVenda.valorTaxaServico]), 'D', 9) + sLineBreak;

    if FVenda.ValorCouvert > 0 then
      FImpressao := FImpressao + AcertaTexto(FMensagemCouvert, 'E', 22, '.') + ':' +
        AcertaTexto(Format('%.2f', [FVenda.ValorCouvert]), 'D', 9) + sLineBreak;

    FImpressao := FImpressao + sLineBreak +
      AcertaTexto('_______', 'D', 32) + sLineBreak +
      '<n>TOTAL CONTA' + AcertaTexto(Format('R$ %.2f', [FVenda.valorTotal]), 'D', 21) +
      '</n>' + sLineBreak + '................................' + sLineBreak +
      'Qtde. de itens: ' + LQuantidadeItens.ToString + sLineBreak +
      'Qtde. de pessoas: ' + FVenda.numeroPessoas.ToString + sLineBreak +
      'Total por pessoa: ' + Format('R$%.2f', [FVenda.ValorPorPessoa]) + sLineBreak +
      '=='.PadRight(32, '=') + sLineBreak;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.CarregarVenda;
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
      'Abertura  :   ' + FormatDateTime('dd/mm/yyyy hh:nn', FVenda.dataAbertura) + sLineBreak +
      'Fechamento: ' + FormatDateTime('dd/mm/yyyy hh:nn', FData) + sLineBreak +
      '                Sem Valor Fiscal' + sLineBreak +
      '===============================' + sLineBreak;
  finally
    FreeAndNil(LServiceConsulta);
  end;
end;

destructor TAPIRPCheffServiceVendaImpressao32Colunas.Destroy;
begin
  FreeAndNil(FVenda);
  FreeAndNil(FEmpresa);
  FreeAndNil(FVendaItens);
  inherited;
end;

function TAPIRPCheffServiceVendaImpressao32Colunas.Execute: TStream;
var
  FImpressaoAnterior: string;
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
  ImprimirFichaIndividualVerificada;
 if FichaImpressaoIndividual<>'' then
   FImpressao := FImpressaoAnterior + sLineBreak + FImpressao;

  Result := TStringStream.Create(FImpressao, TEncoding.UTF8);
end;

procedure TAPIRPCheffServiceVendaImpressao32Colunas.ImprimirFichaIndividualVerificada;
var
  LItem: TAPIRPCheffEntityVendaItem;
  LImpressoras: TObjectList<TAPIRPCheffEntityImpressaoProducao>;
begin
  FichaImpressaoIndividual := '';

  for LItem in FVendaItens do
  begin
    if not LItem.ImprimirFichaIndividual then
      Continue;

    if not Assigned(FEmpresa) then
    begin
      FDAO.EmpresaDAO.IdEmpresa(FIdEmpresa);
      FEmpresa := FDAO.EmpresaDAO.Busca;
      if not Assigned(FEmpresa) then
        raise Exception.CreateFmt('Empresa %d N'#227'o encontrada.', [FIdEmpresa]);
    end;

    LImpressoras := FDAO.ImpressaoProducaoDAO.Listar(LItem.idProduto, LItem.idVenda);
    try
      for var LImpressora in LImpressoras do
      begin
        FichaImpressaoIndividual := FichaImpressaoIndividual + sLineBreak +
          '===========================' + sLineBreak +
          FEmpresa.nome.PadRight(28, ' ') + sLineBreak +
          FEmpresa.endereco.PadRight(22, ' ') + FEmpresa.numero.PadLeft(6, '0') + sLineBreak;

        if FEmpresa.telefonePrincipal = 0 then
          FichaImpressaoIndividual := FichaImpressaoIndividual + 'FONE: ' + FEmpresa.telefone.PadRight(28, ' ') + sLineBreak
        else
          FichaImpressaoIndividual := FichaImpressaoIndividual + 'FONE: ' + FEmpresa.celular.PadRight(28, ' ') + sLineBreak;

        FichaImpressaoIndividual := FichaImpressaoIndividual +
          sLineBreak + '===========================' + sLineBreak + sLineBreak +
          'Venda: ' + LItem.idVenda.ToString + sLineBreak +
          'Data: ' + FormatDateTime('dd/mm/yyyy hh:nn', LItem.dataLancamento) + sLineBreak +
          'Impressora: ' + LImpressora.TipoVenda + sLineBreak +
          '===========================' + sLineBreak +
          '====== P A G O ======' + sLineBreak + sLineBreak +
          LItem.produtoDescricao + LItem.descricaoTamanho.PadLeft(28, ' ') + sLineBreak + sLineBreak +
          '===========================' + sLineBreak + sLineBreak + sLineBreak;
      end;
    finally
      FreeAndNil(LImpressoras);
    end;
  end;
end;



end.
