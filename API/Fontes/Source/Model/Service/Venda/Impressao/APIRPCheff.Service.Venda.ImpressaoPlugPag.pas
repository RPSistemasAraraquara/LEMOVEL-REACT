unit APIRPCheff.Service.Venda.ImpressaoPlugPag;

interface

uses
  APIRPCheff.Service.Venda.Impressao,
  APIRPCheff.Service.Venda.Consulta,
  APIRPCheff.Resources,
  APIRPCheff.Entity.Classes,
  APIRPCheff.Entity.Types,
  APIRPCheff.DAO.Factory,
  APIRPCheff.Utils,
  System.JSON,
  System.Generics.Collections,
  System.SysUtils,
  System.Math,
  System.Classes,
  System.StrUtils;

  type
  TAPIRPCheffServiceVendaImpressaoPlugPag = class(TAPIRPCheffServiceVendaImpressao)
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
    procedure CarregarOperadorPreFechamento;
  public
    destructor Destroy; override;

    function Execute: TStream; override;
  end;


implementation

{ TAPIRPCheffServiceVendaImpressaoPlugPag }

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarEmpresa;
begin
   FreeAndNil(FEmpresa);
  FDAO.EmpresaDAO.IdEmpresa(FIdEmpresa);
  FEmpresa := FDAO.EmpresaDAO.Busca;
  if not Assigned(FEmpresa) then
    raise Exception.CreateFmt('Empresa %d n'#227'o encontrada.', [FIdEmpresa]);

  FImpressao := '=========================' + sLineBreak;

  if not ContainsText(FEmpresa.nome, 'rpcheff') then
    FImpressao := FImpressao + FEmpresa.nome.PadRight(32, ' ') + sLineBreak;

  FImpressao := FImpressao +
  FEmpresa.endereco.PadRight(22, ' ') + FEmpresa.numero.PadLeft(6, '0') + sLineBreak;


  if FEmpresa.telefonePrincipal = 0 then
    FImpressao := FImpressao + 'Fone:' + FEmpresa.telefone + sLineBreak
  else
    FImpressao := FImpressao + 'Fone:' + FEmpresa.celular + sLineBreak;

  FImpressao := FImpressao + '=========================' + sLineBreak;
end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarGarcons;
var
  LGarcons: TList<Integer>;
  LTextoGarcom: string;
  LGarcom: TAPIRPCheffEntityUsuario;
begin
  LGarcons := TList<Integer>.Create;
  try
    for var LItem in FVendaItens do
    begin
      if LItem.idGarcom <= 0 then
        Continue;

      if LGarcons.Contains(LItem.idGarcom) then
        Continue;

      LGarcom := FDAO.UsuarioDAO.Busca(LItem.idGarcom);
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
      FImpressao := FImpressao + '-------------------------' + sLineBreak +
      'GARCONS (ATENDIMENTO)'.PadRight(28, ' ') + sLineBreak +
       LTextoGarcom.PadRight(28, ' ') + sLineBreak;
  finally
    LGarcons.Free;
  end;

end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarItemFracionado;
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


  for var LItem in FVendaItens do
  begin
    if not LItem.Fracionado then
      Continue;

    FImpressao := FImpressao +
    '******* Item Fracionado *******' + sLineBreak;


    for var LFracao in LItem.fracoes do
    begin
      FImpressao := FImpressao + LFracao.produtoDescricao ;

      if LFracao.DescricaoTamanho<>EmptyStr then
       FImpressao := FImpressao + ' (' + LFracao.descricaoTamanho + ')';

      FImpressao:=FImpressao+sLineBreak+

      Format('R$ %.2f', [LFracao.valorUnitario]).PadLeft(12, ' ') +
      FormatarQuantidadeFracionada(LFracao.quantidade, LFracao.valorUnitario, LFracao.valorTotal).PadLeft(6, ' ' ) +
      Format('R$ %.2f', [LFracao.valorTotal]).PadLeft(10 , ' ');

      FImpressao := FImpressao +  sLineBreak;
    end;


    FImpressao := FImpressao + '-------------------------' + sLineBreak;

    if not FImprimirOpcionais then
      Continue;

    for var LOpcional in LItem.opcionais do
      FImpressao := FImpressao +
      'Opc: '+  LOpcional.descricao + sLineBreak + sLineBreak;
  end;

end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarItemNormal(AItem: TAPIRPCheffEntityVendaItem);
var
  LFormatoQuantidade: string;
begin

  LFormatoQuantidade := '%.3f';
  if (not FImprimirDecimais) and (AItem.quantidade - Trunc(AItem.quantidade) = 0) then
    LFormatoQuantidade := '%.0f';

  FImpressao := FImpressao  + AItem.produtoDescricao ;

  if AItem.descricaoTamanho<>EmptyStr then
  FImpressao := FImpressao + ' (' + AItem.descricaoTamanho + ')';


  FImpressao := FImpressao +sLineBreak+  Format('%-8s %-6s %s',
  [Format('R$ %.2f', [AItem.valorUnitario]),
  Format(LFormatoQuantidade, [AItem.quantidade]),
  Format('R$ %.2f', [AItem.valorTotal])]) + sLineBreak + sLineBreak;

  if FImprimirOpcionais then
    CarregarOpcionais(AItem);
end;


procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarItens;
begin
  FImpressao := FImpressao +
    'Descricao do item' + sLineBreak +
    'Valor    Qtde   Total' + sLineBreak +
    '-------------------------' + sLineBreak;

  FreeAndNil(FVendaItens);
  FVendaItens := FDAO.VendaItemDAO.ListarVendasAgrupadosProdutos(FIdVenda);

  for var LItem in FVendaItens do
    if not LItem.Fracionado then
      CarregarItemNormal(LItem);

  CarregarItemFracionado;

end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarOpcionais( AItem: TAPIRPCheffEntityVendaItem);
begin
  if not FImprimirOpcionais then
    Exit;

  for var LOpcional in AItem.opcionais do
    FImpressao := FImpressao +
     'Opc.:'+ LOpcional.descricao + slinebreak ;
end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarPagamentos;
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
      FImpressao := FImpressao +
        LEncerramento.formaPagamento.descricao.PadLeft(22, ' ') +
        Format('R$ %.2f', [LEncerramento.ValorPago]).PadLeft(10, ' ') + sLineBreak;
    end;

    if LTotalTroco > 0 then
      FImpressao := FImpressao +
        'TROCO:'.PadLeft(5, ' ') +
        Format('R$ %.2f', [LTotalTroco]).PadLeft(20, ' ') + sLineBreak;

    if FValorPendente > 0 then
      FImpressao := FImpressao +
        'VALOR PENDENTE: R$ ' + Format('R$ %.2f', [FValorPendente]) + sLineBreak;

  finally
    LEncerramentos.Free;
  end;
end;


procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarPagamentosAntecipados;
var
  LPagamentos: TObjectList<TAPIRPCheffEntityVendaPagamentoAntecipado>;
begin
  LPagamentos := FDAO.VendaPagamentoAntecipadoDAO.Listar(FIdVenda);
  try
    for var LPagamento in LPagamentos do
    begin
      FValorPendente := FValorPendente - LPagamento.valor;
      FImpressao := FImpressao + LPagamento.formaPagamento.descricao.PadLeft(18, ' ')+
      Format('%.2f',[LPagamento.valor]).PadLeft(12, ' ') + sLineBreak;
    end;
  finally
    LPagamentos.Free;
  end;

end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarRodape;
begin
  FImpressao := FImpressao + '-------------------------' + sLineBreak +
  '                     RP Cheff '+sLineBreak+
  'www.sistemalechef.com.br' + sLineBreak +
  '-------------------------' + sLineBreak+ sLineBreak+ sLineBreak;
  FImpressao := FImpressao + sLineBreak;

end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarTotal;
var
  LTotalItens: Currency;
  LDesconto: Currency;
  LQuantidadeItens: Integer;
begin
  LTotalItens := 0;
  LDesconto := 0;
  LQuantidadeItens := 0;

  LTotalItens      := 0;
  LDesconto        := 0;
  LQuantidadeItens := 0;
  for var LItem in FVendaItens do
    LQuantidadeItens := LQuantidadeItens + 1 + LItem.fracoes.Count;

  FDAO.VendaItemDAO.TotalizarItensVenda(FIdVenda, LTotalItens, LDesconto);


  FImpressao := FImpressao + '-------------------------' + sLineBreak +
   'Sub total...:' +
    FormatarMoeda(LTotalItens) + sLineBreak;

  if LDesconto > 0 then
    FImpressao := FImpressao +
      'Desc itens: '.PadLeft(11, ' ') + Format('%.2f',  [LDesconto]).PadLeft(21, ' ' ) + sLineBreak;

  if FEmpresa.casaNoturna then
  begin
    FImpressao := FImpressao +'Taxa Entrada:'.PadLeft(13, ' ' )+
      Format('%.2f', [FVenda.valorEntrada]).PadLeft(15, ' ') + sLineBreak;

    FImpressao := FImpressao +
    'Taxa Cart'#227'o (+):'.PadLeft(16, ' ' )+
    Format('R$ %.2f', [FVenda.taxaCartao]).PadLeft(11, ' ')+ sLineBreak +
    'Taxa de Servi'#231'o.:'+
     Format('R$ %.2f', [FVenda.valorTaxaServico]) + sLineBreak +
      'TOTAL CONTA' +Format('R$ %.2f', [FVenda.valorTotal]).PadLeft(32, ' ')+
       '-------------------------' + sLineBreak +
      'Qtde. itens: ' + LQuantidadeItens.ToString.PadLeft(28, ' ') + sLineBreak +
        sLineBreak + '-------------------------' + sLineBreak;
  end
  else
  begin
    if FVenda.valorTaxaServico > 0 then
      FImpressao := FImpressao + 'Taxa de Servi'#231'o.:'+
      Format('R$ %.2f', [FVenda.valorTaxaServico]) + sLineBreak;

    if FVenda.ValorCouvert > 0 then
      FImpressao := FImpressao + FMensagemCouvert.PadLeft(22, ' ')+
        Format('R$ %.2f', [FVenda.ValorCouvert]).PadLeft(10, ' ')+ sLineBreak;

    FImpressao := FImpressao + sLineBreak +
      'TOTAL'.PadLeft(15, ' ')+  Format('R$ %.2f', [FVenda.valorTotal]).PadLeft(16, ' ')
       +sLineBreak+ '-------------------------' + sLineBreak +
      'Qtde. de itens   : ' + LQuantidadeItens.ToString + sLineBreak +
      'Qtde. de pessoas : ' + FVenda.numeroPessoas.ToString + sLineBreak +
      'Total por pessoa : '+ Format('R$ %.2f', [FVenda.ValorPorPessoa]) + sLineBreak +
      '-------------------------' + sLineBreak;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarVenda;
var
  LServiceConsulta: TAPIRPCheffServiceVendaConsulta;
begin
  FreeAndNil(FVenda);
  LServiceConsulta := TAPIRPCheffServiceVendaConsulta.Create;
  try
    LServiceConsulta.DAO(FDAO);
    FVenda := LServiceConsulta.AplicarTaxaServico(False).Buscar(FIdVenda, False);
    if not Assigned(FVenda) then
      raise Exception.CreateFmt('Venda %d n'#227'o encontrada.', [FIdVenda]);

    FValorPendente := FVenda.valorTotal;
    FImpressao := FImpressao +  FVenda.DescricaoMesaComanda +'  '+ '  -- Cupom: ' + FVenda.numeroCupom.ToString +
     sLineBreak +
      'Abert:' + FormatDateTime('dd/mm/yyyy hh:nn', FVenda.dataAbertura) + sLineBreak +
      'Fech:' + FormatDateTime('dd/mm/yyyy hh:nn', FData) + sLineBreak+
      'SIMPLES CONFERENCIA' + sLineBreak +
      '-------------------------' + sLineBreak;
  finally
    FreeAndNil(LServiceConsulta);
  end;
end;

destructor TAPIRPCheffServiceVendaImpressaoPlugPag.Destroy;
begin
  FreeAndNil(FVenda);
  FreeAndNil(FEmpresa);
  FreeAndNil(FVendaItens);
  inherited;
end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.CarregarOperadorPreFechamento;
var
  LOperadorFechamento: TAPIRPCheffEntityUsuario;
begin
  LOperadorFechamento := FDAO.UsuarioDAO.Busca(FVenda.idUsuarioPreFechamento);
  try
    if Assigned(LOperadorFechamento) then
    begin
      FImpressao := FImpressao + '-------------------------' + sLineBreak +
        'Solicitador por  : '+ sLineBreak+LOperadorFechamento.nome.PadLeft(30, ' ') + sLineBreak;
    end;
  finally
    FreeAndNil(LOperadorFechamento);
  end;
end;

function TAPIRPCheffServiceVendaImpressaoPlugPag.Execute: TStream;
var
  LJSONArray: TJSONArray;
  LJSONObject: TJSONObject;
  FLinhas: TStringList;
  LTexto: string;
  i: Integer;
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
  CarregarOperadorPreFechamento;
  CarregarRodape;

  ImprimirFichaIndividualVerificada;

  if FichaImpressaoIndividual<>'' then
   FImpressao := FImpressao+FichaImpressaoIndividual ;

  LJSONArray := TJSONArray.Create;
  FLinhas := TStringList.Create;
  try
    FLinhas.Text := FImpressao;

    for i := 0 to FLinhas.Count - 1 do
    begin
      LTexto := Trim(FLinhas[i]);
      if LTexto = '' then
        Continue;

      if (LTexto.Replace('=', '').Replace('-', '').Replace(' ', '') = '') and (LTexto.Length > 2) then
      begin

        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'line');
        LJSONObject.AddPair('content', LTexto);
      end
      else if i = 1 then
      begin
        // Nome da empresa
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'center');
        LJSONObject.AddPair('size', 'extrabig');
        LJSONObject.AddPair('style', 'bold');
      end
      else if i = 2 then
      begin
        // Endereço
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'center');
        LJSONObject.AddPair('size', 'small');
      end
      else if i = 3 then
      begin
        // Telefone
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'center');
        LJSONObject.AddPair('size', 'small');
      end
      else if LTexto.ToUpper.Contains('CUPOM:') then
      begin
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'center');
        LJSONObject.AddPair('size', 'big');
        LJSONObject.AddPair('style', 'bold');
      end
      else if LTexto.ToUpper.Contains('CUPOM PARA SIMPLES') then
      begin
        // CUPOM PARA SIMPLES CONFERÊNCIA
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'center');
        LJSONObject.AddPair('size', 'big');
        LJSONObject.AddPair('style', 'bold');
      end
      else if LTexto.ToUpper.Contains('ABERTURA') or
              LTexto.ToUpper.Contains('FECHAMENTO') then
      begin
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'left');
        LJSONObject.AddPair('size', 'medium');
      end
      else if LTexto.ToUpper.Contains('SUB TOTAL') then
      begin
        // Totais - alinhado à esquerda
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'left');
        LJSONObject.AddPair('size', 'medium');
        LJSONObject.AddPair('style', 'bold');
      end
      else if LTexto.ToUpper.Contains('TOTAL CONTA') then
      begin
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'center');
        LJSONObject.AddPair('size', 'extrabig');
        LJSONObject.AddPair('style', 'bold');
      end
      else if LTexto.ToUpper.Contains('VALOR PENDENTE') then
      begin
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', 'VALOR PENDENTE: R$ ' + FormatFloat('0.00', FValorPendente));
        LJSONObject.AddPair('align', 'center');
        LJSONObject.AddPair('size', 'big');
        LJSONObject.AddPair('style', 'bold');
      end
      else if LTexto.ToUpper.Contains('GAR'#199'ONS') or LTexto.ToUpper.Contains('SOLICITADOR') then
      begin
        // Cabeçalhos especiais
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'center');
        LJSONObject.AddPair('size', 'medium');
      end
      else if LTexto.ToUpper.Contains('WWW') then
      begin
        // Rodapé
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'center');
        LJSONObject.AddPair('size', 'medium');
        LJSONObject.AddPair('style', 'bold');
      end
      else if LTexto.ToUpper.Contains('VALOR') and LTexto.ToUpper.Contains('QTDE') then
      begin
        // Cabeçalho de itens
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'left');
        LJSONObject.AddPair('size', 'medium');
        LJSONObject.AddPair('style', 'bold');
      end
      else if (LTexto.Contains(',') and (LTexto.Contains(' ') or LTexto.Contains('.'))) and (Length(LTexto) <= 30) then
      begin
        // Linha com valores (valor unit, qtde, total)
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'left');
        LJSONObject.AddPair('size', 'medium');
      end

      else
      begin
        // Padrão
        LJSONObject := TJSONObject.Create;
        LJSONObject.AddPair('type', 'text');
        LJSONObject.AddPair('content', LTexto);
        LJSONObject.AddPair('align', 'left');
        LJSONObject.AddPair('size', 'medium');
      end;

      LJSONArray.Add(LJSONObject);
    end;
    Result := TStringStream.Create(LJSONArray.ToString, TEncoding.UTF8);
  finally
    FLinhas.Free;
    LJSONArray.Free;
  end;
end;

procedure TAPIRPCheffServiceVendaImpressaoPlugPag.ImprimirFichaIndividualVerificada;
var
  LItem: TAPIRPCheffEntityVendaItem;
  LQuantidadeFichas: Integer;
begin
  FichaImpressaoIndividual := '';

  if not FImprimirFichaIndividualProdutos then
    Exit;

  for LItem in FVendaItens do
  begin
    if not LItem.ImprimirFichaIndividual then
      Continue;

    if not Assigned(FEmpresa) then
    begin
      FDAO.EmpresaDAO.IdEmpresa(FIdEmpresa);
      FEmpresa := FDAO.EmpresaDAO.Busca;
      if not Assigned(FEmpresa) then
        raise Exception.CreateFmt('Empresa %d n'#227'o encontrada.', [FIdEmpresa]);
    end;

    LQuantidadeFichas := QuantidadeFichasIndividuais(LItem.quantidade);
    for var LFicha := 1 to LQuantidadeFichas do
    begin
      FichaImpressaoIndividual := FichaImpressaoIndividual + sLineBreak +
        '=========================' + sLineBreak +
        FEmpresa.nome.PadRight(32, ' ') + sLineBreak +
        FEmpresa.endereco.PadRight(22, ' ') + FEmpresa.numero.PadLeft(6, '0') + sLineBreak;

      if FEmpresa.telefonePrincipal = 0 then
        FichaImpressaoIndividual := FichaImpressaoIndividual + 'Fone:' + FEmpresa.telefone + sLineBreak
      else
        FichaImpressaoIndividual := FichaImpressaoIndividual + 'Fone:' + FEmpresa.celular + sLineBreak;

      FichaImpressaoIndividual := FichaImpressaoIndividual +
        sLineBreak + '=========================' + sLineBreak + sLineBreak +
        'Venda: ' + LItem.idVenda.ToString + sLineBreak +
        'Data: ' + FormatDateTime('dd/mm/yyyy hh:nn', LItem.dataLancamento) + sLineBreak;

      if not LItem.TerminalImpressao.Trim.IsEmpty then
        FichaImpressaoIndividual := FichaImpressaoIndividual + 'Impressora: ' + LItem.TerminalImpressao + sLineBreak;

      FichaImpressaoIndividual := FichaImpressaoIndividual +
        '=========================' + sLineBreak +
        '====== P A G O ======' + sLineBreak + sLineBreak +
        LItem.produtoDescricao + LItem.descricaoTamanho.PadLeft(32, ' ') + sLineBreak + sLineBreak +
        '=========================' + sLineBreak +  sLineBreak;
    end;
  end;

end;

end.

