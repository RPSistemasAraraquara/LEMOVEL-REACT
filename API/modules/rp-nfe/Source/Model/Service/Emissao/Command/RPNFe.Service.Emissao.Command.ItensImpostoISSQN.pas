unit RPNFe.Service.Emissao.Command.ItensImpostoISSQN;

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
  TRPNFeServiceEmissaoCommandItensImpostoISSQN = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandItensImpostoISSQN }

procedure TRPNFeServiceEmissaoCommandItensImpostoISSQN.Execute;
var
  I: Integer;
  LNFeProduto: TDetCollectionItem;
  LVendaItem: TRPNFeEntityVendaItem;
  LOK: Boolean;
  LIss: TpcnindISS;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  for I := 0 to Pred(FParent.Venda.Itens.Count) do
  begin
    LVendaItem := FParent.Venda.Itens[I];
    LNFeProduto := FNFe.Det.Items[I];
    if not LVendaItem.Produto.Servico then
      Continue;

    LNFeProduto.Imposto.ISSQN.vBC := LVendaItem.ValorTotal;
    LNFeProduto.Imposto.ISSQN.vAliq := LVendaItem.Produto.Iss;
    LNFeProduto.Imposto.ISSQN.vISSQN := LVendaItem.ValorTotal * LVendaItem.Produto.Iss / 100;
    LNFeProduto.Imposto.ISSQN.cMunFG := StrToIntDef(FParent.Empresa.CodigoIBGE, 0);
    LNFeProduto.Imposto.ISSQN.cListServ := LVendaItem.Produto.IssServico;

    LIss := StrToindISS(LOK, LVendaItem.Produto.IssExigibilidade.ToString);
    if LOK then
      LNFeProduto.Imposto.ISSQN.indISS := LIss;

    LNFeProduto.Imposto.ISSQN.indIncentivo := iiSim;
    if LVendaItem.Produto.IssIncentivo <> 1 then
      LNFeProduto.Imposto.ISSQN.indIncentivo := iiNao;
  end;
end;

end.
