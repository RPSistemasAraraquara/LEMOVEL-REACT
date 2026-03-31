unit RPNFe.Service.Emissao.Command.DadosDest;

interface

uses
  System.SysUtils,
  pcnConversaoNFe,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoCommandDadosDest = class(TRPNFeServiceEmissaoCommand)
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandDadosDest }

procedure TRPNFeServiceEmissaoCommandDadosDest.Execute;
var
  LNFe: TNFe;
begin
  LNFe := FParent.Components.Emissor.ACBr.NotasFiscais[0].NFe;
  LNFe.Dest.CNPJCPF := FParent.Venda.Cliente.CpfCnpj;
  LNFe.Dest.indIEDest := TpcnindIEDest.inNaoContribuinte;
  LNFe.Dest.xNome := FParent.Venda.Cliente.Nome;
  LNFe.Dest.EnderDest.xLgr := FParent.Venda.Cliente.Logradouro;
  LNFe.Dest.EnderDest.nro := FParent.Venda.Cliente.Numero;
  LNFe.Dest.EnderDest.xCpl := FParent.Venda.Cliente.Complemento;
  LNFe.Dest.EnderDest.xBairro := FParent.Venda.Cliente.Bairro;
  LNFe.Dest.EnderDest.xMun := FParent.Venda.Cliente.Cidade;
  LNFe.Dest.EnderDest.UF := FParent.Venda.Cliente.UF;
  LNFe.Dest.EnderDest.cPais := 1058;
  LNFe.Dest.EnderDest.xPais := 'BRASIL';
  if FParent.Venda.Cliente.CodigoIBGE <> '' then
    LNFe.Dest.EnderDest.cMun := StrToInt(FParent.Venda.Cliente.CodigoIBGE.Replace('.', ''));
end;

end.
