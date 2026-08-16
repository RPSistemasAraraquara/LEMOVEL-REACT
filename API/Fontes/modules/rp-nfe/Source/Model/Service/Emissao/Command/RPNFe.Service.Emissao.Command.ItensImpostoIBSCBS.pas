unit RPNFe.Service.Emissao.Command.ItensImpostoIBSCBS;

// Reforma Tributaria (IBS/CBS) - NT 2025.002.
// Porte fiel de TEmissorNFCe.DadosProdutosRT e TEmissorNFCe.NotaTotalRT do
// RPCHEFF_VCL (Geral\uEmissorNFCe.pas): mesmas regras, mesmas tabelas
// (materiais.cst_rt_nfce/cclasstrib_rt_nfce/rt_param_bc_*, dfe_classtrib_rt,
// dfe_cst_rt) e mesma classe de calculo (TFuncoesAdicionaisRT).
// Diferenca intencional: onde o desktop mostra ShowMessage e segue, aqui a
// emissao levanta excecao (vira aviso nao-fatal no fechamento da venda).

interface

uses
  System.SysUtils,
  ACBrNFe.Classes,
  ACBrDFe.Conversao,
  RPNFe.Entity.Classes,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoCommandItensImpostoIBSCBS = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;

    // Totalizadores da nota (equivalentes aos campos Total_* do TEmissorNFCe).
    FTotalVBCIBSCBS: Double;
    FTotalVIBSUF: Double;
    FTotalVIBSMun: Double;
    FTotalVIBS: Double;
    FTotalVCBS: Double;
    FTotalVDifUF: Double;
    FTotalVDifMun: Double;
    FTotalVDifCBS: Double;
    FTotalVDevTribUF: Double;
    FTotalVDevTribMun: Double;
    FTotalVDevTribCBS: Double;
    FTotalVCredPres: Double;
    FTotalVCredPresCBS: Double;
    FTotalVIBSMono: Double;
    FTotalVCBSMono: Double;
    FTotalVIBSMonoReten: Double;
    FTotalVCBSMonoReten: Double;
    FTotalVIBSMonoRet: Double;
    FTotalVCBSMonoRet: Double;
    FTotalVIS: Double;

    procedure PreencherItem(AVendaItem: TRPNFeEntityVendaItem; ANFeProduto: TDetCollectionItem);
    procedure PreencherTotais;
  public
    procedure Execute; override;
  end;

implementation

uses
  uFuncoesAdicionaisRT;

{ TRPNFeServiceEmissaoCommandItensImpostoIBSCBS }

procedure TRPNFeServiceEmissaoCommandItensImpostoIBSCBS.Execute;
var
  I: Integer;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;

  FTotalVBCIBSCBS := 0;
  FTotalVIBSUF := 0;
  FTotalVIBSMun := 0;
  FTotalVIBS := 0;
  FTotalVCBS := 0;
  FTotalVDifUF := 0;
  FTotalVDifMun := 0;
  FTotalVDifCBS := 0;
  FTotalVDevTribUF := 0;
  FTotalVDevTribMun := 0;
  FTotalVDevTribCBS := 0;
  FTotalVCredPres := 0;
  FTotalVCredPresCBS := 0;
  FTotalVIBSMono := 0;
  FTotalVCBSMono := 0;
  FTotalVIBSMonoReten := 0;
  FTotalVCBSMonoReten := 0;
  FTotalVIBSMonoRet := 0;
  FTotalVCBSMonoRet := 0;
  FTotalVIS := 0;

  for I := 0 to Pred(FParent.Venda.Itens.Count) do
    PreencherItem(FParent.Venda.Itens[I], FNFe.Det.Items[I]);

  PreencherTotais;
end;

procedure TRPNFeServiceEmissaoCommandItensImpostoIBSCBS.PreencherItem(
  AVendaItem: TRPNFeEntityVendaItem; ANFeProduto: TDetCollectionItem);
const
  // Mesmas constantes do desktop (DadosProdutosRT): sem IS, sem diferimento,
  // sem credito presumido e sem ad rem parametrizados nesta fase.
  vpDifIBS = 0.0;
  vpDifCBS = 0.0;
  vpCredPresIBS = 0.0;
  pCredPresCBS = 0.0;
  adRemIBS = 0.0;
  adRemCBS = 0.0;
var
  LClassTrib: TRPNFeEntityClassTribRT;
  LCst: string;
  LClasse: string;
  vBCRefTrib: Double;
  vBCReduzida: Double;
  vAliqCBS: Double;
  vpIBSUF: Double;
  vpIBSMun: Double;
  vpRedAliqIBS: Double;
  vpRedAliqCBS: Double;
  TemReducaoAliquota: Boolean;
  Diferimento: Boolean;
  vgTribRegular: Boolean;
  ibsmono: Boolean;
  IBSSuspenso: Boolean;
  CBSSuspenso: Boolean;
  vTotalIBS: Double;
  vTotalCBS: Double;
  vItemIBSMono: Double;
  vItemCBSMono: Double;
  vCredPresIBSItem: Double;
  vCredPresCBSItem: Double;
begin
  vTotalIBS := 0;
  vTotalCBS := 0;
  IBSSuspenso := False;
  CBSSuspenso := False;

  // Aliquotas do emitente (empresas.aliq_cbs, estados.aliq_ibs_uf,
  // cidades.aliq_ibs_mun), como no desktop.
  vAliqCBS := FParent.Empresa.AliqCbs;
  vpIBSUF := FParent.Empresa.AliqIbsUf;
  vpIBSMun := FParent.Empresa.AliqIbsMun;

  // ====== Base de calculo com os parametros do produto (rt_param_bc_*) ======
  vBCRefTrib := TFuncoesAdicionaisRT.CalcularBaseCalculowithParams(
    ANFeProduto,
    AVendaItem.Produto.RtParamBcVlProd,
    AVendaItem.Produto.RtParamBcVlFrete,
    AVendaItem.Produto.RtParamBcVlSeg,
    AVendaItem.Produto.RtParamBcVlDesp,
    AVendaItem.Produto.RtParamBcII,
    AVendaItem.Produto.RtParamBcIS,
    AVendaItem.Produto.RtParamBcDesconto,
    AVendaItem.Produto.RtParamBcPis,
    AVendaItem.Produto.RtParamBcCofins,
    AVendaItem.Produto.RtParamBcIcms,
    AVendaItem.Produto.RtParamBcIcmsDest,
    AVendaItem.Produto.RtParamBcFcp,
    AVendaItem.Produto.RtParamBcFcpDest,
    AVendaItem.Produto.RtParamBcIcmsMono,
    AVendaItem.Produto.RtParamBcIssqn);

  if vBCRefTrib < 0 then
    vBCRefTrib := 0;

  ANFeProduto.Imposto.IBSCBS.gIBSCBS.vBC := vBCRefTrib;

  // ====== CST e classificacao tributaria do produto ======
  LCst := Trim(AVendaItem.Produto.CstRtNfce);
  LClasse := Trim(AVendaItem.Produto.CClassTribRtNfce);

  if (LCst = '') or (LClasse = '') then
    raise Exception.CreateFmt(
      'IBS/CBS nao configurado no produto %d (%s): informe CST e cClassTrib da NFC-e no cadastro.',
      [AVendaItem.Produto.Codigo, Trim(AVendaItem.Produto.Descricao)]);

  ANFeProduto.Imposto.IBSCBS.CST := StrToCSTIBSCBS(LCst);
  ANFeProduto.Imposto.IBSCBS.cClassTrib := LClasse;

  // ====== Flags da classificacao (dfe_classtrib_rt + dfe_cst_rt) ======
  LClassTrib := FParent.DAO.ClassTribRTDAO.Buscar(LClasse);
  if not Assigned(LClassTrib) then
    raise Exception.CreateFmt('Classificacao tributaria %s nao cadastrada (dfe_classtrib_rt).', [LClasse]);
  try
    if not LClassTrib.IndNfce then
      raise Exception.CreateFmt('Classificacao %s nao permitida para NFCE.', [LClasse]);

    TemReducaoAliquota := LClassTrib.IndRedAliq;
    Diferimento := LClassTrib.IndDif;
    vgTribRegular := LClassTrib.IndTribRegular;
    ibsmono := LClassTrib.IndIbsCbsMono;
    vpRedAliqIBS := LClassTrib.PRedIbs;
    vpRedAliqCBS := LClassTrib.PRedCbs;
  finally
    LClassTrib.Free;
  end;

  // CST 410 (isento): mesmo comportamento do desktop, nao preenche gIBSCBS.
  if ANFeProduto.Imposto.IBSCBS.CST = cst410 then
  begin
    ANFeProduto.infAdProd := ANFeProduto.infAdProd +
      Format('CST: %s cClassTrib: %s |IBS: R$%.2f CBS: R$%.2f IS: R$%.2f Total RT: R$%.2f',
      [CSTIBSCBSToStr(ANFeProduto.Imposto.IBSCBS.CST),
       ANFeProduto.Imposto.IBSCBS.cClassTrib, 0.0, 0.0, 0.0, 0.0]);
    Exit;
  end;

  // ====== Tributacao monofasica ======
  if ibsmono then
  begin
    if not TFuncoesAdicionaisRT.CalcularGIBSCBSMono(ANFeProduto, vBCRefTrib,
      adRemIBS, adRemCBS, LClasse, ANFeProduto.Prod.qTrib, vpDifIBS, vpDifCBS) then
      raise Exception.CreateFmt('Erro ao preencher gIBSCBSMono do produto %d.',
        [AVendaItem.Produto.Codigo]);

    vItemIBSMono := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(
      ANFeProduto.Imposto.IBSCBS.gIBSCBSMono.vTotIBSMonoItem);
    vItemCBSMono := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(
      ANFeProduto.Imposto.IBSCBS.gIBSCBSMono.vTotCBSMonoItem);

    FTotalVIBSMono := FTotalVIBSMono + vItemIBSMono;
    FTotalVCBSMono := FTotalVCBSMono + vItemCBSMono;

    ANFeProduto.infAdProd := ANFeProduto.infAdProd +
      Format('CST: %s cClassTrib: %s ',
      [CSTIBSCBSToStr(ANFeProduto.Imposto.IBSCBS.CST),
       ANFeProduto.Imposto.IBSCBS.cClassTrib]);
    Exit;
  end;

  // ====== Reducao de base ======
  if TemReducaoAliquota then
    vBCReduzida := TFuncoesAdicionaisRT.ArredondaSefaz(vBCRefTrib * ((100 - vpRedAliqCBS) / 100))
  else
    vBCReduzida := vBCRefTrib;

  // ====== IBS UF (estadual) ======
  with ANFeProduto.Imposto.IBSCBS.gIBSCBS.gIBSUF do
  begin
    pIBSUF := 0;
    vIBSUF := 0;
    gDif.pDif := 0;
    gDif.vDif := 0;
    gRed.pRedAliq := 0;
    gRed.pAliqEfet := 0;

    pIBSUF := vpIBSUF;

    if Diferimento then
    begin
      gDif.pDif := vpDifIBS;
      gDif.vDif := TFuncoesAdicionaisRT.CalcularDiferimento(vBCRefTrib, pIBSUF, vpDifIBS);
      if gDif.pDif = 0 then
        gDif.pDif := 0.000001; // Valor minimo apenas para criar a tag (igual desktop)
      if gDif.vDif = 0 then
        gDif.vDif := 0.0000;
      FTotalVDifUF := FTotalVDifUF + gDif.vDif;
    end;

    if TemReducaoAliquota then
    begin
      gRed.pRedAliq := vpRedAliqIBS;
      gRed.pAliqEfet := TFuncoesAdicionaisRT.CalcularAliquotaEfetiva(pIBSUF, gRed.pRedAliq, False, 0);
      vIBSUF := TFuncoesAdicionaisRT.CalcularIBSUF(vBCRefTrib, pIBSUF, gRed.pAliqEfet,
        gDif.vDif, gDevTrib.vDevTrib,
        ANFeProduto.Imposto.IBSCBS.gCredPresOper.gIBSCredPres.vCredPres,
        TemReducaoAliquota, gRed.pRedAliq);
    end
    else
    begin
      vIBSUF := TFuncoesAdicionaisRT.CalcularIBSUF(vBCRefTrib, pIBSUF, 0,
        gDif.vDif, gDevTrib.vDevTrib,
        ANFeProduto.Imposto.IBSCBS.gCredPresOper.gIBSCredPres.vCredPres);
    end;

    if vgTribRegular then
    begin
      // Rejeicao 1030: CST com tributacao regular zera o IBS proprio (igual desktop).
      pIBSUF := 0;
      vIBSUF := 0;
    end;

    FTotalVIBSUF := FTotalVIBSUF + vIBSUF + FTotalVDifUF;
    vTotalIBS := vTotalIBS + vIBSUF;
  end;

  // ====== IBS Municipio ======
  with ANFeProduto.Imposto.IBSCBS.gIBSCBS.gIBSMun do
  begin
    pIBSMun := 0;
    vIBSMun := 0;
    gRed.pRedAliq := 0;
    gRed.pAliqEfet := 0;

    pIBSMun := vpIBSMun;

    if Diferimento then
    begin
      gDif.pDif := vpDifCBS;
      gDif.vDif := TFuncoesAdicionaisRT.CalcularDiferimento(vBCRefTrib, pIBSMun, vpDifCBS);
      if gDif.pDif = 0 then
        gDif.pDif := 0.000001;
      if gDif.vDif = 0 then
        gDif.vDif := 0.0000;
      FTotalVDifMun := FTotalVDifMun + gDif.vDif;
    end;

    if TemReducaoAliquota then
    begin
      gRed.pRedAliq := vpRedAliqIBS;
      gRed.pAliqEfet := TFuncoesAdicionaisRT.CalcularAliquotaEfetiva(pIBSMun, gRed.pRedAliq, False, 0);
      vIBSMun := TFuncoesAdicionaisRT.CalcularIBSMunicipio(vBCReduzida, pIBSMun,
        gRed.pAliqEfet, gDif.vDif, gDevTrib.vDevTrib,
        ANFeProduto.Imposto.IBSCBS.gCredPresOper.gIBSCredPres.vCredPres);
    end
    else
    begin
      vIBSMun := TFuncoesAdicionaisRT.CalcularIBSMunicipio(vBCRefTrib, pIBSMun, 0,
        gDif.vDif, gDevTrib.vDevTrib,
        ANFeProduto.Imposto.IBSCBS.gCredPresOper.gIBSCredPres.vCredPres);
    end;

    FTotalVIBSMun := FTotalVIBSMun + vIBSMun - FTotalVDifMun;
    vTotalIBS := vTotalIBS + vIBSMun;
  end;

  // ====== CBS (nacional) ======
  with ANFeProduto.Imposto.IBSCBS.gIBSCBS.gCBS do
  begin
    pCBS := vAliqCBS;
    gRed.pRedAliq := 0;
    gRed.pAliqEfet := 0;

    if Diferimento then
    begin
      gDif.pDif := vpDifCBS;
      gDif.vDif := TFuncoesAdicionaisRT.CalcularDiferimento(vBCRefTrib, pCBS, vpDifCBS);
      if gDif.pDif = 0 then
        gDif.pDif := 0.000001;
      if gDif.vDif = 0 then
        gDif.vDif := 0.0000;
      FTotalVDifCBS := FTotalVDifCBS + gDif.vDif;
    end;

    if TemReducaoAliquota then
    begin
      gRed.pRedAliq := vpRedAliqCBS;
      gRed.pAliqEfet := TFuncoesAdicionaisRT.CalcularAliquotaEfetiva(pCBS, gRed.pRedAliq, False, 0);
      vCBS := TFuncoesAdicionaisRT.CalcularCBS(vBCRefTrib, pCBS, gRed.pAliqEfet,
        TemReducaoAliquota, vpRedAliqCBS);
    end
    else
    begin
      vCBS := TFuncoesAdicionaisRT.CalcularCBS(vBCRefTrib, pCBS, 0);
    end;

    vTotalCBS := vCBS + FTotalVDifCBS;
    FTotalVCBS := FTotalVCBS + vCBS;
  end;

  // ====== Credito presumido (2027+) ======
  if Date >= EncodeDate(2027, 1, 1) then
  begin
    if (not IBSSuspenso) and (vTotalIBS > 0) then
    begin
      vCredPresIBSItem := TFuncoesAdicionaisRT.CalcularCredPresIBS(vTotalIBS, vpCredPresIBS, IBSSuspenso);
      with ANFeProduto.Imposto.IBSCBS.gCredPresOper do
      begin
        cCredPres := cp01;
        gIBSCredPres.pCredPres := vpCredPresIBS;
        gIBSCredPres.vCredPres := vCredPresIBSItem;
        FTotalVCredPres := FTotalVCredPres + gIBSCredPres.vCredPres;
      end;
    end;

    if (not CBSSuspenso) and (vTotalCBS > 0) then
    begin
      vCredPresCBSItem := TFuncoesAdicionaisRT.CalcularCredPresCBS(vTotalCBS, pCredPresCBS, CBSSuspenso);
      with ANFeProduto.Imposto.IBSCBS.gCredPresOper do
      begin
        cCredPres := cp01;
        gIBSCredPres.pCredPres := pCredPresCBS;
        gIBSCredPres.vCredPres := vCredPresCBSItem;
        FTotalVCredPresCBS := FTotalVCredPresCBS + gIBSCredPres.vCredPres;
      end;
    end;
  end;

  // ====== Tributacao regular (gTribRegular) ======
  if vgTribRegular then
  begin
    if not TFuncoesAdicionaisRT.CalcularGTribRegular(ANFeProduto, vBCRefTrib,
      CSTIBSCBSToStr(ANFeProduto.Imposto.IBSCBS.CST),
      ANFeProduto.Imposto.IBSCBS.cClassTrib,
      vpIBSUF, vpIBSMun, vAliqCBS,
      TemReducaoAliquota, vpRedAliqIBS, vpRedAliqCBS, False, 0) then
      raise Exception.CreateFmt('Erro ao preencher gTribRegular do produto %d.',
        [AVendaItem.Produto.Codigo]);

    ANFeProduto.Imposto.IBSCBS.gIBSCBS.gIBSUF.pIBSUF := 0;
    ANFeProduto.Imposto.IBSCBS.gIBSCBS.gIBSUF.vIBSUF := 0;
  end;

  // ====== Totalizacao geral do item ======
  ANFeProduto.Imposto.IBSCBS.gIBSCBS.vIBS := vTotalIBS;
  FTotalVIBS := FTotalVIBS + vTotalIBS;

  // Em 2027 somar tambem os tributos ao vItem (igual desktop).
  ANFeProduto.vItem := TFuncoesAdicionaisRT.ArredondaSefaz(vBCRefTrib);

  FTotalVBCIBSCBS := FTotalVBCIBSCBS + vBCRefTrib;
end;

procedure TRPNFeServiceEmissaoCommandItensImpostoIBSCBS.PreencherTotais;
var
  vTotalIBS: Double;
  vTotalCBS: Double;
  SomaIBS: Double;
  SomaCBS: Double;
begin
  with FNFe do
  begin
    // Imposto Seletivo total.
    Total.ISTot.vIS := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVIS);

    // Base de calculo total IBS/CBS.
    Total.IBSCBSTot.vBCIBSCBS := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVBCIBSCBS);

    // Totais IBS.
    vTotalIBS := FTotalVIBSUF + FTotalVIBSMun;
    Total.IBSCBSTot.gIBS.vIBS := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(vTotalIBS);
    Total.IBSCBSTot.gIBS.vCredPres := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVCredPres);

    Total.IBSCBSTot.gIBS.gIBSUFTot.vDif := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVDifUF);
    Total.IBSCBSTot.gIBS.gIBSUFTot.vDevTrib := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVDevTribUF);
    Total.IBSCBSTot.gIBS.gIBSUFTot.vIBSUF := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVIBSUF);

    Total.IBSCBSTot.gIBS.gIBSMunTot.vDif := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVDifMun);
    Total.IBSCBSTot.gIBS.gIBSMunTot.vDevTrib := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVDevTribMun);
    Total.IBSCBSTot.gIBS.gIBSMunTot.vIBSMun := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVIBSMun);

    // Totais CBS.
    Total.IBSCBSTot.gCBS.vDif := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVDifCBS);
    Total.IBSCBSTot.gCBS.vDevTrib := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVDevTribCBS);
    vTotalCBS := FTotalVCBS;
    Total.IBSCBSTot.gCBS.vCBS := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(vTotalCBS);
    Total.IBSCBSTot.gCBS.vCredPres := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVCredPresCBS);

    // Totais monofasicos.
    with Total.IBSCBSTot.gMono do
    begin
      vIBSMono := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVIBSMono);
      vCBSMono := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVCBSMono);
      vIBSMonoReten := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVIBSMonoReten);
      vCBSMonoReten := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVCBSMonoReten);
      vIBSMonoRet := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVIBSMonoRet);
      vCBSMonoRet := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVCBSMonoRet);
    end;

    // Verificacao de consistencia (evita rejeicao 1092), igual desktop.
    SomaIBS := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVIBSMono);
    SomaCBS := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(FTotalVCBSMono);
    if Abs(SomaIBS - Total.IBSCBSTot.gMono.vIBSMono) > 0.01 then
      raise Exception.CreateFmt('Divergencia IBS Mono: soma itens = %.2f / total XML = %.2f',
        [SomaIBS, Total.IBSCBSTot.gMono.vIBSMono]);
    if Abs(SomaCBS - Total.IBSCBSTot.gMono.vCBSMono) > 0.01 then
      raise Exception.CreateFmt('Divergencia CBS Mono: soma itens = %.2f / total XML = %.2f',
        [SomaCBS, Total.IBSCBSTot.gMono.vCBSMono]);

    // Valor total da nota (em 2027 somar vTotalIBS + vTotalCBS), igual desktop.
    Total.vNFTot := TFuncoesAdicionaisRT.ArredondaValorParaSefaz(Total.ICMSTot.vNF);
  end;
end;

end.
