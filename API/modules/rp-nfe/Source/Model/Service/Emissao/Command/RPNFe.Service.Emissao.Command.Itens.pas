unit RPNFe.Service.Emissao.Command.Itens;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  ACBrUtil.Base,
  ACBrNFe.Classes,
  pcnConversao,
  pcnConversaoNFe,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Entity.Classes,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoCommandItens = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;

    procedure AtribuirGTIN(AVendaItem: TRPNFeEntityVendaItem; ANFeProduto: TDetCollectionItem);
    procedure AtribuirValorTotTrib(AVendaItem: TRPNFeEntityVendaItem; ANFeProduto: TDetCollectionItem);
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandItens }

procedure TRPNFeServiceEmissaoCommandItens.AtribuirGTIN(AVendaItem: TRPNFeEntityVendaItem;
  ANFeProduto: TDetCollectionItem);
var
  LEan: string;
begin
  LEan := 'SEM GTIN';
  if (AVendaItem.Produto.Ean.Length = 8) or (AVendaItem.Produto.Ean.Length = 13) then
    LEan := AVendaItem.Produto.Ean;
  ANFeProduto.Prod.cEAN := LEan;
  ANFeProduto.Prod.cEANTrib := LEan;
end;

procedure TRPNFeServiceEmissaoCommandItens.AtribuirValorTotTrib(AVendaItem: TRPNFeEntityVendaItem;
  ANFeProduto: TDetCollectionItem);
var
  LIbpt: TRPNFeEntityIBPT;
  LValorEstadual: Currency;
  LValorMunicipal: Currency;
  LValorFederal: Currency;
begin
  ANFeProduto.Imposto.vTotTrib := 0;
  LIbpt := FParent.DAO.IBPTDAO.Buscar(AVendaItem.Produto.NCM);
  try
    if Assigned(LIbpt) then
    begin
      LValorEstadual := RoundTo(AVendaItem.ValorTotal * (LIbpt.AliquotaEstadual / 100), -2);
      LValorMunicipal := RoundTo(AVendaItem.ValorTotal * (LIbpt.AliquotaMunicipal / 100), -2);
      LValorFederal := RoundTo(AVendaItem.ValorTotal * (LIbpt.AliquotaFederalNacional / 100), -2);
      ANFeProduto.Imposto.vTotTrib := LValorEstadual + LValorMunicipal + LValorFederal;
    end;
  finally
    LIbpt.Free;
  end;
end;

procedure TRPNFeServiceEmissaoCommandItens.Execute;
var
  LNFeProduto: TDetCollectionItem;
  LVendaItem: TRPNFeEntityVendaItem;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  for LVendaItem in FParent.Venda.Itens do
  begin
    LNFeProduto := FNFe.Det.New;
    LNFeProduto.Prod.nItem := FNFe.Det.Count;
    LNFeProduto.Prod.cProd := LVendaItem.Produto.Codigo.ToString;
    LNFeProduto.Prod.xProd := LVendaItem.Produto.Descricao;
    LNFeProduto.Prod.NCM := LVendaItem.Produto.NCM;
    LNFeProduto.Prod.CEST := LVendaItem.Produto.CEST;
    LNFeProduto.Prod.CFOP := LVendaItem.Produto.CFOPConsumidor;
    LNFeProduto.Prod.uCom := LVendaItem.Unidade.Unidade;
    LNFeProduto.Prod.qCom := LVendaItem.Quantidade;
    LNFeProduto.Prod.vUnCom := LVendaItem.ValorUnitario;
    LNFeProduto.Prod.vProd := LVendaItem.ValorTotal;
    LNFeProduto.Prod.uTrib := LVendaItem.Unidade.Unidade;
    LNFeProduto.Prod.qTrib := LVendaItem.Quantidade;
    LNFeProduto.Prod.vUnTrib := LVendaItem.ValorUnitario;
    LNFeProduto.Prod.vOutro := 0;
    LNFeProduto.Prod.vDesc := 0;

    if FParent.Venda.PercentualTaxa > 0 then
      LNFeProduto.Prod.vOutro := LVendaItem.ValorTotal * FParent.Venda.PercentualTaxa / 100;

    AtribuirGTIN(LVendaItem, LNFeProduto);
    AtribuirValorTotTrib(LVendaItem, LNFeProduto);
  end;
end;

end.
