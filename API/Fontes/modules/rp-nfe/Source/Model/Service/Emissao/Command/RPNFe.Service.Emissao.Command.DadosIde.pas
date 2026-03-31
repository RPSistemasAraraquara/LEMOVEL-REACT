unit RPNFe.Service.Emissao.Command.DadosIde;

interface

uses
  System.SysUtils,
  System.Classes,
  ACBrUtil.Base,
  pcnConversao,
  pcnConversaoNFe,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoCommandDadosIde = class(TRPNFeServiceEmissaoCommand)
  private
    procedure CarregarNumeroNFe;
    procedure CarregarNumeroNFCe;
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandDadosIde }

procedure TRPNFeServiceEmissaoCommandDadosIde.CarregarNumeroNFCe;
var
  LNumeroNFCe: Integer;
  LNFe: TNFe;
begin
  LNumeroNFCe := FParent.Empresa.NFCeNumero + 1;
  LNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  LNFe.Ide.nNF := LNumeroNFCe;
  LNFe.Ide.cNF := Format('9%d9', [LNumeroNFCe]).ToInteger;
  LNFe.Ide.serie := FParent.Empresa.NFCeSerie;
  Log('Numeração %d usada para NFCe', [LNumeroNFCe]);

  FParent.DAO.EmpresaDAO.AtualizarNumeroNFCe(FParent.Empresa.Id);
end;

procedure TRPNFeServiceEmissaoCommandDadosIde.CarregarNumeroNFe;
var
  LNumeroNFe: Integer;
  LNFe: TNFe;
begin
  LNumeroNFe := FParent.Empresa.NFeNumero + 1;
  LNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  LNFe.Ide.nNF := LNumeroNFe;
  LNFe.Ide.cNF := Format('9%d9', [LNumeroNFe]).ToInteger;
  LNFe.Ide.serie := FParent.Empresa.NFeSerie;
  Log('Numeração %d usada para NFe', [LNumeroNFe]);

  FParent.DAO.EmpresaDAO.AtualizarNumeroNFe(FParent.Empresa.Id);
end;

procedure TRPNFeServiceEmissaoCommandDadosIde.Execute;
var
  LNFe: TNFe;
begin
  inherited;
  if FParent.Components.Emissor.ACBr.NotasFiscais.Count = 0 then
    FParent.Components.Emissor.ACBr.NotasFiscais.Add;

  LNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  LNFe.Ide.natOp := 'VENDA';
  LNFe.Ide.modelo := FParent.Configuracao.Modelo;
  LNFe.Ide.dEmi := Now;
  LNFe.Ide.tpNF := tnSaida;
  LNFe.Ide.tpEmis := teNormal;
  LNFe.Ide.cUF := UFtoCUF(FParent.Empresa.UF);
  LNFe.Ide.cMunFG := StrToInt(FParent.Empresa.CodigoIBGE.Replace('.', EmptyStr));
  LNFe.Ide.finNFe := fnNormal;
  LNFe.Ide.indFinal := cfConsumidorFinal;
  LNFe.Ide.indPres := pcPresencial;
  LNFe.Ide.tpAmb := TpcnTipoAmbiente.taHomologacao;
  if FParent.Configuracao.Producao then
    LNFe.Ide.tpAmb := TpcnTipoAmbiente.taProducao;

  if FParent.Configuracao.Modelo = 55 then
  begin
    LNFe.Ide.tpImp := tiRetrato;
    CarregarNumeroNFe;
    LNFe.Ide.dSaiEnt := LNFe.Ide.dEmi;
    LNFe.Ide.hSaiEnt := LNFe.Ide.dEmi;
  end
  else
  begin
    LNFe.Ide.tpImp := tiNFCe;
    CarregarNumeroNFCe;
  end;

  LNFe.Ide.idDest := doInterna;
  if FParent.Empresa.UF = FParent.Venda.Cliente.UF then
  begin
    LNFe.Ide.idDest := doInterestadual;
    if FParent.Venda.Cliente.UF = 'EX' then
      LNFe.Ide.idDest := doExterior;
  end;
end;

end.
