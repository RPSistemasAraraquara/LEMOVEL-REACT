unit RPNFe.Service.Emissao.Command.ItensImpostoICMS;

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
  TRPNFeServiceEmissaoCommandItensImpostoICMS = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;

    procedure AtribuirOrigem(AVendaItem: TRPNFeEntityVendaItem; ANFeProduto: TDetCollectionItem);
    procedure AtribuirCST(AVendaItem: TRPNFeEntityVendaItem; ANFeProduto: TDetCollectionItem);
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandItensImpostoICMS }

procedure TRPNFeServiceEmissaoCommandItensImpostoICMS.AtribuirCST(AVendaItem: TRPNFeEntityVendaItem;
  ANFeProduto: TDetCollectionItem);
var
  LArrayCst: array of string;
  LCst: TpcnCSTIcms;
  LCsosn: TpcnCSOSNIcms;
  LCso: string;
begin
  LCst := cst00;
  LCsosn := csosnVazio;
  LArrayCst := ['00', '10', '20', '30', '40', '41', '45', '50', '51', '60', '70',
    '80', '81', '90', '101', '102', '103', '201', '202', '203', '300',
    '400', '500', '900', '61'];

  LCso := AVendaItem.Produto.CsoCodigo.ToString.PadLeft(2, '0');
  case AnsiIndexStr(LCso, LArrayCst) of
    0: LCst := cst00;
    1: LCst := cst10;
    2: LCst := cst20;
    3: LCst := cst30;
    4: LCst := cst40;
    5: LCst := cst41;
    6: LCst := cst45;
    7: LCst := cst50;
    8: LCst := cst51;
    9: LCst := cst60;
    10: LCst := cst70;
    11: LCst := cst80;
    12: LCst := cst81;
    13: LCst := cst90;
    14: LCsosn := csosn101;
    15: LCsosn := csosn102;
    16: LCsosn := csosn103;
    17: LCsosn := csosn201;
    18: LCsosn := csosn202;
    19: LCsosn := csosn203;
    20: LCsosn := csosn300;
    21: LCsosn := csosn400;
    22: LCsosn := csosn500;
    23: LCsosn := csosn900;
    24: LCst := cst61;
  else
    raise Exception.CreateFmt('CST/CSOSN do produto n�o cadastrado [%d].',
      [AVendaItem.Produto.CsoCodigo]);
  end;

  ANFeProduto.Imposto.ICMS.CST := LCst;
  ANFeProduto.Imposto.ICMS.CSOSN := LCsosn;
end;

procedure TRPNFeServiceEmissaoCommandItensImpostoICMS.AtribuirOrigem(AVendaItem: TRPNFeEntityVendaItem;
  ANFeProduto: TDetCollectionItem);
var
  LOK: Boolean;
  LOrigem: TpcnOrigemMercadoria;
begin
  LOrigem := StrToOrig(LOK, AVendaItem.Produto.OrmCodigo.ToString);
  if not LOK then
    raise Exception.CreateFmt('Origem do produto n�o cadastrado [%d].', [AVendaItem.Produto.OrmCodigo]);

  ANFeProduto.Imposto.ICMS.orig := LOrigem;
end;

procedure TRPNFeServiceEmissaoCommandItensImpostoICMS.Execute;
var
  I: Integer;
  LNFeProduto: TDetCollectionItem;
  LVendaItem: TRPNFeEntityVendaItem;
  LPercentualBase: Currency;
  LTributado: Boolean;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  for I := 0 to Pred(FParent.Venda.Itens.Count) do
  begin
    LVendaItem := FParent.Venda.Itens[I];
    LNFeProduto := FNFe.Det.Items[I];
    LPercentualBase := 100;

    AtribuirOrigem(LVendaItem, LNFeProduto);
    AtribuirCST(LVendaItem, LNFeProduto);

    // Mesma regra do uEmissorNFCe (CalcularImpostoICMS): somente CST 00/20/90 e
    // CSOSN 101/900 calculam vBC/vICMS; os demais (40, 60, 102, 400, 500...)
    // ficam zerados e fora do ICMSTot, senao o total diverge do somatorio dos
    // itens (o XML desses grupos nao leva vBC).
    // Item do Simples carrega CSOSN e deixa o CST no default cst00, entao o
    // CSOSN decide primeiro.
    if LNFeProduto.Imposto.ICMS.CSOSN <> csosnVazio then
      LTributado := LNFeProduto.Imposto.ICMS.CSOSN in [csosn101, csosn900]
    else
      LTributado := LNFeProduto.Imposto.ICMS.CST in [cst00, cst20, cst90];

    LNFeProduto.Imposto.ICMS.pICMS := LVendaItem.Produto.Icms;

    if LTributado then
    begin
      if LNFeProduto.Imposto.ICMS.CST in [cst20, cst90] then
      begin
        LPercentualBase := 100 - LVendaItem.Produto.ReducaoBaseCalculoIcms;
        LNFeProduto.Imposto.ICMS.pRedBC := LVendaItem.Produto.ReducaoBaseCalculoIcms;
      end;

      // Arredonda por item, como o desktop, para o total bater com o somatorio.
      LNFeProduto.Imposto.ICMS.vBC := RoundTo(LVendaItem.ValorTotal * (LPercentualBase / 100), -2);
      LNFeProduto.Imposto.ICMS.vICMS := RoundTo(LNFeProduto.Imposto.ICMS.vBC * LVendaItem.Produto.Icms / 100, -2);
    end;

    if LNFeProduto.Imposto.ICMS.vICMS = 0 then
      LNFeProduto.Imposto.ICMS.vBC := 0;

    if FNFe.Emit.CRT = TpcnCRT.crtSimplesNacional then
      LNFeProduto.Imposto.ICMS.pST := LNFeProduto.Imposto.ICMS.pICMS;
  end;
end;

end.
