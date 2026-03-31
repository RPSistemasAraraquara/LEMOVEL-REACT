unit RPNFe.Service.Emissao.Command.ItensANP;

interface

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.Math,
  ACBrUtil.Base,
  ACBrNFe.Classes,
  pcnConversao,
  pcnConversaoNFe,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Entity.Classes,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoCommandItensANP = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;

    procedure AtribuiDadosGLP(AVendaItem: TRPNFeEntityVendaItem; ANFeProduto: TDetCollectionItem);
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandItensANP }

procedure TRPNFeServiceEmissaoCommandItensANP.AtribuiDadosGLP(AVendaItem: TRPNFeEntityVendaItem;
  ANFeProduto: TDetCollectionItem);
var
  LTotal: Double;
  LComb: TorigCombCollectionItem;
  LCodigoUF: Integer;
begin
  ANFeProduto.Prod.comb.descANP := 'GLP';
  ANFeProduto.Prod.comb.vPart := 0.00;
  if AVendaItem.Produto.PesoPartidaAnp > 0 then
  begin
    ANFeProduto.Prod.comb.vPart := ANFeProduto.Prod.vUnCom / AVendaItem.Produto.PesoPartidaAnp;
    ANFeProduto.Prod.uTrib := 'KG';
    ANFeProduto.Prod.qTrib := ANFeProduto.Prod.qCom * AVendaItem.Produto.PesoPartidaAnp;
    ANFeProduto.Prod.vUnTrib := ANFeProduto.Prod.vUnCom / AVendaItem.Produto.PesoPartidaAnp;

    LTotal := AVendaItem.Produto.Pglp + AVendaItem.Produto.Pgnn + AVendaItem.Produto.Pgni;
    if LTotal = 100 then
    begin
      ANFeProduto.Prod.comb.pGLP := AVendaItem.Produto.Pglp;
      ANFeProduto.Prod.comb.pGNn := AVendaItem.Produto.Pgnn;
      ANFeProduto.Prod.comb.pGNi := AVendaItem.Produto.Pgni;

      LCodigoUF := FParent.DAO.EstadoDAO.CodigoUF(FNFe.Emit.EnderEmit.UF);
      if AVendaItem.Produto.Pgnn > 0 then
      begin
        LComb := ANFeProduto.Prod.comb.origComb.New;
        LComb.indImport := iiNacional;
        LComb.cUFOrig := LCodigoUF;
        LComb.pOrig := 100;
      end;

      if AVendaItem.Produto.Pgni > 0 then
      begin
        LComb := ANFeProduto.Prod.comb.origComb.New;
        LComb.indImport := iiImportado;
        LComb.cUFOrig := LCodigoUF;
        LComb.pOrig := 100;
      end;
    end
    else
    begin
      ANFeProduto.Prod.comb.pGLP := 100;
      ANFeProduto.Prod.comb.pGNn := 0;
      ANFeProduto.Prod.comb.pGNi := 0;
    end;

    if ANFeProduto.Imposto.ICMS.CST = cst60 then
      if AnsiIndexStr(AVendaItem.Produto.CodigoAnp.Trim,
        ['210203001', '320101001', '320101002', '320102002', '320102001', '320102003',
         '320102005', '320201001', '320102001', '320103001', '220102001',
         '320301001', '320103002', '820101032', '820101026', '820101027', '820101004',
         '820101005', '820101022', '820101031', '820101030', '820101014', '820101006',
         '820101016', '820101015', '820101025', '820101017', '820101018', '820101019', '820101020',
         '820101021', '420105001', '420101005', '420101004', '420102005', '420106001', '420106002',
         '420301002', '510101001', '510201003', '420102004', '820101011', '830101001', '410103001',
         '510101002', '510301003', '420104001', '820101003', '420301004', '410101001', '510102001',
         '510103001', '820101033', '820101013', '420202001', '410102001', '510102002', '510301001',
         '820101034', '820101012', '420301001', '430101004', '510201001']) >= 0 then
        ANFeProduto.Imposto.ICMS.CST := cstRep60;

    if ANFeProduto.Imposto.ICMS.CST = cst61 then
    begin
      ANFeProduto.Imposto.ICMS.adRemICMSRet := AVendaItem.Produto.Adrem;
      ANFeProduto.Imposto.ICMS.qBCMonoRet   := ANFeProduto.Prod.qCom * AVendaItem.Produto.PesoPartidaAnp;
      ANFeProduto.Imposto.ICMS.vICMSMonoRet := ANFeProduto.Imposto.ICMS.adRemICMSRet * ANFeProduto.Imposto.ICMS.qBCMonoRet;
    end;
  end;
end;

procedure TRPNFeServiceEmissaoCommandItensANP.Execute;
var
  I: Integer;
  LNFeProduto: TDetCollectionItem;
  LVendaItem: TRPNFeEntityVendaItem;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  for I := 0 to Pred(FParent.Venda.Itens.Count) do
  begin
    LVendaItem := FParent.Venda.Itens[I];
    LNFeProduto := FNFe.Det.Items[I];

    if LVendaItem.Produto.CodigoAnp.Trim.IsEmpty then
      Continue;

    LNFeProduto.Prod.comb.cProdANP := StrToInt(LVendaItem.Produto.CodigoAnp);
    LNFeProduto.Prod.comb.descANP := LVendaItem.Produto.Descricao;
    LNFeProduto.Prod.comb.UFcons := FNFe.Dest.EnderDest.UF;

    if LVendaItem.Produto.CodigoAnp.Trim.Equals('210203001') then
      AtribuiDadosGLP(LVendaItem, LNFeProduto);
  end;
end;

end.
