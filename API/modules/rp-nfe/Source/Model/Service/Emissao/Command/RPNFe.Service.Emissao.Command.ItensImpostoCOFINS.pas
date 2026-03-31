unit RPNFe.Service.Emissao.Command.ItensImpostoCOFINS;

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
  TRPNFeServiceEmissaoCommandItensImpostoCOFINS = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandItensImpostoCOFINS }

procedure TRPNFeServiceEmissaoCommandItensImpostoCOFINS.Execute;
var
  I: Integer;
  LNFeProduto: TDetCollectionItem;
  LVendaItem: TRPNFeEntityVendaItem;
  LCstCofins: TpcnCstCofins;
  LOk: Boolean;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  for I := 0 to Pred(FParent.Venda.Itens.Count) do
  begin
    LVendaItem := FParent.Venda.Itens[I];
    LNFeProduto := FNFe.Det.Items[I];


    LCstCofins := StrToCSTCOFINS(LOk, LVendaItem.Produto.CofinsCodigoSaida.ToString);
    if Integer(LCstCofins) < 0 then
      raise Exception.CreateFmt('COFINS CST do produto não cadastrado [%d]',
        [LVendaItem.Produto.CofinsCodigoSaida]);

    LNFeProduto.Imposto.COFINS.CST := LCstCofins;
    LNFeProduto.Imposto.COFINS.vBC := LVendaItem.ValorTotal;
    LNFeProduto.Imposto.COFINS.pCOFINS := LVendaItem.Produto.Cofins;
    LNFeProduto.Imposto.COFINS.vCOFINS := LVendaItem.ValorTotal * LVendaItem.Produto.Cofins / 100;;
    LNFeProduto.Imposto.COFINS.qBCProd := 0;
    LNFeProduto.Imposto.COFINS.vAliqProd := 0;

    // COFINS ST
    LNFeProduto.Imposto.COFINSST.vBC := 0;
    LNFeProduto.Imposto.COFINSST.pCOFINS := 0;
    LNFeProduto.Imposto.COFINSST.vCOFINS := 0;
    LNFeProduto.Imposto.COFINSST.qBCProd := 0;
    LNFeProduto.Imposto.COFINSST.vAliqProd := 0;
    LNFeProduto.Imposto.vTotTrib := 0;
  end;

end;

end.
