unit RPNFe.Service.Emissao.Command.ItensImpostoPIS;

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
  TRPNFeServiceEmissaoCommandItensImpostoPIS = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandItensImpostoPIS }

procedure TRPNFeServiceEmissaoCommandItensImpostoPIS.Execute;
var
  I: Integer;
  LNFeProduto: TDetCollectionItem;
  LVendaItem: TRPNFeEntityVendaItem;
  LCstPis: TpcnCstPis;
  LOk: Boolean;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  for I := 0 to Pred(FParent.Venda.Itens.Count) do
  begin
    LVendaItem := FParent.Venda.Itens[I];
    LNFeProduto := FNFe.Det.Items[I];

    LCstPis := StrToCSTPIS(LOk, LVendaItem.Produto.PisCodigoSaida.ToString);
    if Integer(LCstPis) < 0 then
      raise Exception.CreateFmt('PIS CST do produto não cadastrado [%d]',
        [LVendaItem.Produto.PisCodigoSaida]);

    LNFeProduto.Imposto.PIS.CST := LCstPis;
    LNFeProduto.Imposto.PIS.vBC := LVendaItem.ValorTotal;
    LNFeProduto.Imposto.PIS.pPis := LVendaItem.Produto.Pis;
    LNFeProduto.Imposto.PIS.vPIS := LVendaItem.ValorTotal * LVendaItem.Produto.Pis / 100;
    LNFeProduto.Imposto.PIS.qBCProd := 0;
    LNFeProduto.Imposto.PIS.vAliqProd := 0;

    LNFeProduto.Imposto.PISST.vBC := 0;
    LNFeProduto.Imposto.PISST.pPis := 0;
    LNFeProduto.Imposto.PISST.qBCProd := 0;
    LNFeProduto.Imposto.PISST.vPIS := 0;
    LNFeProduto.Imposto.PISST.vAliqProd := 0;
  end;
end;

end.
