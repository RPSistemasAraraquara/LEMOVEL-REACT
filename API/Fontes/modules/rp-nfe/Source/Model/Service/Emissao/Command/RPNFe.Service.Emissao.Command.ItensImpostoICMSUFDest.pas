unit RPNFe.Service.Emissao.Command.ItensImpostoICMSUFDest;

interface

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  ACBrUtil.Base,
  ACBrNFe.Classes,
  pcnConversao,
  pcnConversaoNFe,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Entity.Classes,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoCommandItensImpostoICMSUFDest = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;

    function InformarICMSUFDest(AVendaItem: TRPNFeEntityVendaItem; ANFeProduto: TDetCollectionItem): Boolean;
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandItensImpostoICMSUFDest }

procedure TRPNFeServiceEmissaoCommandItensImpostoICMSUFDest.Execute;
var
  I: Integer;
  LNFeProduto: TDetCollectionItem;
  LVendaItem: TRPNFeEntityVendaItem;
  LDifal: Double;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  for I := 0 to Pred(FParent.Venda.Itens.Count) do
  begin
    LVendaItem := FParent.Venda.Itens[I];
    LNFeProduto := FNFe.Det.Items[I];

    if not InformarICMSUFDest(LVendaItem, LNFeProduto) then
      Continue;

    LNFeProduto.Imposto.ICMSUFDest.vBCFCPUFDest := LNFeProduto.Imposto.ICMS.vBC;
    LNFeProduto.Imposto.ICMSUFDest.vBCUFDest := LNFeProduto.Imposto.ICMS.vBC;
    LNFeProduto.Imposto.ICMSUFDest.pFCPUFDest := 2;
    LNFeProduto.Imposto.ICMS.pST := LNFeProduto.Imposto.ICMS.pICMS + 2;
    LNFeProduto.Imposto.ICMSUFDest.pICMSUFDest := FParent.DAO.AliquotaDAO
      .AliquotaInterna(FParent.Venda.Cliente.UF);

    LNFeProduto.Imposto.ICMSUFDest.vFCPUFDest := (LNFeProduto.Imposto.ICMS.vBC *
      LNFeProduto.Imposto.ICMSUFDest.pFCPUFDest) / 100;

    LDifal:= LNFeProduto.Imposto.ICMS.vBC * ((LNFeProduto.Imposto.ICMSUFDest.pICMSUFDest -
      LNFeProduto.Imposto.ICMSUFDest.pICMSInter ) / 100);

    //PARTILHA DIFAL
    LNFeProduto.Imposto.ICMSUFDest.vICMSUFDest := (LDifal * LNFeProduto.Imposto.ICMSUFDest.pICMSInterPart) / 100; // Valor do ICMS Destino 80%
    LNFeProduto.Imposto.ICMSUFDest.vICMSUFRemet := (LDifal * (100 - LNFeProduto.Imposto.ICMSUFDest.pICMSInterPart)) / 100; // Valor do ICMS Remetente - 20%
  end;
end;

function TRPNFeServiceEmissaoCommandItensImpostoICMSUFDest.InformarICMSUFDest(
  AVendaItem: TRPNFeEntityVendaItem; ANFeProduto: TDetCollectionItem): Boolean;
var
  LCFOP: array of string;
begin
  Result := FNFe.Emit.CRT <> TpcnCRT.crtSimplesNacional;
  if Result then
    Result := FNFe.Ide.idDest = doInterna;
  if Result then
    Result := not (ANFeProduto.Imposto.ICMS.CST in [cst40, cst41]);

  LCFOP := ['1414', '1415', '1451', '1452', '1554', '1664', '1902', '1903', '1904',
    '1906', '1907', '1909', '6552', '6922', '6929', '1913', '1914', '1916',
    '1921', '1925', '2414', '2415', '2554', '2664', '2902', '2903', '2904',
    '2906', '2907', '2909', '2913', '2914', '2916', '2921', '2925', '5664',
    '5665', '5902', '5903', '5906', '5907', '5909', '5913', '5916', '5925',
    '6664', '6665', '6902', '6903', '6906', '6907', '6909', '6913', '6916',
    '6925', '6552', '6922', '6929'];
  if Result then
    Result := AnsiIndexStr(AVendaItem.Produto.CFOPConsumidor, LCFOP) < 0;
end;

end.
