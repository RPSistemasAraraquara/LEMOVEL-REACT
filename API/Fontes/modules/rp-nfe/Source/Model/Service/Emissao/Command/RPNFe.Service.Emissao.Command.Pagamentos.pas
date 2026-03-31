unit RPNFe.Service.Emissao.Command.Pagamentos;

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
  TRPNFeServiceEmissaoCommandPagamentos = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;

    procedure AtribuirDadosCartao(APagamento: TRPNFeEntityVendaPagamento; ANFePagamento: TpagCollectionItem);
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandPagamentos }

procedure TRPNFeServiceEmissaoCommandPagamentos.AtribuirDadosCartao(
  APagamento: TRPNFeEntityVendaPagamento; ANFePagamento: TpagCollectionItem);
var
  LBandeira: string;
begin
  ANFePagamento.tpIntegra := tiPagNaoIntegrado;
  if APagamento.Forma.TipoIntegracao = 1 then
  begin
    ANFePagamento.tpIntegra := tiPagIntegrado;
    ANFePagamento.CNPJ := APagamento.Forma.CnpjCredenciadora;
    ANFePagamento.cAut := APagamento.Autorizacao;
  end;

  LBandeira := APagamento.Forma.BandeiraCartao;
  if LBandeira = 'V' then
    ANFePagamento.tBand := bcVisa
  else
  if LBandeira = 'M' then
    ANFePagamento.tBand := bcMasterCard
  else
  if LBandeira = 'A' then
    ANFePagamento.tBand := bcAmericanExpress
  else
  if LBandeira = 'S' then
    ANFePagamento.tBand := bcSorocred
  else
  if LBandeira = 'D' then
    ANFePagamento.tBand := bcDinersClub
  else
  if LBandeira = 'E' then
    ANFePagamento.tBand := bcElo
  else
  if LBandeira = 'H' then
    ANFePagamento.tBand := bcHipercard
  else
  if LBandeira = 'R' then
    ANFePagamento.tBand := bcAura
  else
  if LBandeira = 'C' then
    ANFePagamento.tBand := bcCabal
  else
  if LBandeira = 'O' then
    ANFePagamento.tBand := bcOutros;
end;

procedure TRPNFeServiceEmissaoCommandPagamentos.Execute;
var
  LPagamento: TRPNFeEntityVendaPagamento;
  LNFePag: TpagCollectionItem;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  FNFe.pag.vTroco := 0;

  for LPagamento in FParent.Venda.Pagamentos do
  begin
    FNFe.pag.vTroco := LPagamento.Troco + FNFe.pag.vTroco;
    LNFePag := FNFe.pag.New;
    LNFePag.vPag := LPagamento.Valor + LPagamento.Troco;

    case LPagamento.Forma.SfiCodigo of
      1: LNFePag.tPag := fpDinheiro;
      2: LNFePag.tPag := fpCheque;
      3: LNFePag.tPag := fpCartaoCredito;
      4: LNFePag.tPag := fpCartaoDebito;
      5: LNFePag.tPag := fpCreditoLoja;
      10: LNFePag.tPag := fpValeAlimentacao;
      11: LNFePag.tPag := fpValeRefeicao;
      12: LNFePag.tPag := fpValePresente;
      13: LNFePag.tPag := fpValeCombustivel;
      15: LNFePag.tPag := fpBoletoBancario;
      16: LNFePag.tPag := fpDepositoBancario;
      17: LNFePag.tPag := fpPagamentoInstantaneo;
      18: LNFePag.tPag := fpTransfBancario;
      19: LNFePag.tPag := fpProgramaFidelidade;
    else
      LNFePag.tPag := fpOutro;
      LNFePag.xPag := 'Outros';
    end;

    if LNFePag.tPag in [fpCartaoCredito, fpCartaoDebito] then
      AtribuirDadosCartao(LPagamento, LNFePag);
  end;
end;


end.
