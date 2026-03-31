unit RPNFe.Service.Emissao.Command.Totais;

interface

uses
  System.SysUtils,
  System.Classes,
  ACBrUtil.Base,
  ACBrNFe.Classes,
  pcnConversao,
  pcnConversaoNFe,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Entity.Classes,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoCommandTotais = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandTotais }

procedure TRPNFeServiceEmissaoCommandTotais.Execute;
var
  I: Integer;
  LNFeProduto: TDetCollectionItem;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  for I := 0 to Pred(FParent.Venda.Itens.Count) do
  begin
    LNFeProduto := FNFe.Det.Items[I];

    FNFe.Total.ICMSTot.vFCPUFDest := FNFe.Total.ICMSTot.vFCPUFDest + LNFeProduto.Imposto.ICMSUFDest.vFCPUFDest;
    FNFe.Total.ICMSTot.vICMSUFDest := FNFe.Total.ICMSTot.vICMSUFDest + LNFeProduto.Imposto.ICMSUFDest.vICMSUFDest;
    FNFe.Total.ICMSTot.vICMSUFRemet := FNFe.Total.ICMSTot.vICMSUFRemet + LNFeProduto.Imposto.ICMSUFDest.vICMSUFRemet;

    FNFe.Total.ICMSTot.vICMS := FNFe.Total.ICMSTot.vICMS + LNFeProduto.Imposto.ICMS.vICMS;
    FNFe.Total.ICMSTot.vBC := FNFe.Total.ICMSTot.vBC + LNFeProduto.Imposto.ICMS.vBC;
    FNFe.Total.ICMSTot.vBCST := FNFe.Total.ICMSTot.vBCST + LNFeProduto.Imposto.ICMS.vBCST;
    FNFe.Total.ICMSTot.vST := FNFe.Total.ICMSTot.vST + LNFeProduto.Imposto.ICMS.vICMSST;
    FNFe.Total.ICMSTot.vProd := FNFe.Total.ICMSTot.vProd + LNFeProduto.Prod.vProd;
    FNFe.Total.ICMSTot.vFrete := FNFe.Total.ICMSTot.vFrete + LNFeProduto.Prod.vFrete;
    FNFe.Total.ICMSTot.vSeg := FNFe.Total.ICMSTot.vSeg + LNFeProduto.Prod.vSeg;
    FNFe.Total.ICMSTot.vDesc := FNFe.Total.ICMSTot.vDesc + LNFeProduto.Prod.vDesc;
    FNFe.Total.ICMSTot.vII := FNFe.Total.ICMSTot.vII + LNFeProduto.Imposto.II.vII;
    FNFe.Total.ICMSTot.vIPI := FNFe.Total.ICMSTot.vIPI + LNFeProduto.Imposto.IPI.vIPI;
    FNFe.Total.ICMSTot.vPIS := FNFe.Total.ICMSTot.vPIS + LNFeProduto.Imposto.PIS.vPIS;
    FNFe.Total.ICMSTot.vCOFINS := FNFe.Total.ICMSTot.vCOFINS + LNFeProduto.Imposto.COFINS.vCOFINS;
    FNFe.Total.ICMSTot.vOutro := FNFe.Total.ICMSTot.vOutro + LNFeProduto.Prod.vOutro;
    FNFe.Total.ICMSTot.vNF := FParent.Venda.Valor;

    // lei da transparencia de impostos
    FNFe.Total.ICMSTot.vTotTrib := FNFe.Total.ICMSTot.vTotTrib + LNFeProduto.Imposto.vTotTrib;

    FNFe.Total.ISSQNtot.vServ := FNFe.Total.ISSQNtot.vServ + LNFeProduto.Imposto.ISSQN.vBC;
    FNFe.Total.ISSQNtot.vBC := FNFe.Total.ISSQNtot.vBC + LNFeProduto.Imposto.ISSQN.vBC;
    FNFe.Total.ISSQNtot.vISS := FNFe.Total.ISSQNtot.vISS + LNFeProduto.Imposto.ISSQN.vISSQN;
    FNFe.Total.ISSQNtot.cRegTrib := RTISSMicroempresaMunicipal;
    if FNFe.Total.ISSQNtot.vServ > 0 then
      FNFe.Total.ISSQNtot.dCompet := FParent.Venda.Data;

    FNFe.Transp.modFrete := mfSemFrete;
  end;
end;

end.
