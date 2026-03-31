unit RPNFe.Service.Emissao.Command.DadosEmit;

interface

uses
  System.SysUtils,
  pcnConversaoNFe,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoCommandDadosEmit = class(TRPNFeServiceEmissaoCommand)
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandDadosEmit }

procedure TRPNFeServiceEmissaoCommandDadosEmit.Execute;
var
  LNFe: TNFe;
begin
  LNFe := FParent.Components.Emissor.ACBr.NotasFiscais[0].NFe;
  LNFe.Emit.CNPJCPF := FParent.Empresa.Cnpj;
  LNFe.Emit.IE := FParent.Empresa.InscricaoEstadual;
  LNFe.Emit.IM := FParent.Empresa.InscricaoMunicipal;
  LNFe.Emit.CNAE:= FParent.Empresa.Cnae;
  LNFe.Emit.xNome := FParent.Empresa.Nome;
  LNFe.Emit.xFant := FParent.Empresa.RazaoSocial;
  LNFe.Emit.EnderEmit.fone := FParent.Empresa.Telefone;
  LNFe.Emit.EnderEmit.CEP := StrToInt(FParent.Empresa.Cep.Replace('.', '').Replace('-', ''));
  LNFe.Emit.EnderEmit.xLgr := FParent.Empresa.Logradouro;
  LNFe.Emit.EnderEmit.nro := FParent.Empresa.Numero;
  LNFe.Emit.EnderEmit.xCpl := FParent.Empresa.Complemento;
  LNFe.Emit.EnderEmit.xBairro := FParent.Empresa.Bairro;
  LNFe.Emit.EnderEmit.cMun := StrToInt(FParent.Empresa.CodigoIBGE.Replace('-', '').Replace('.', ''));
  LNFe.Emit.EnderEmit.xMun := FParent.Empresa.Cidade;
  LNFe.Emit.EnderEmit.UF := FParent.Empresa.UF;
  LNFe.Emit.EnderEmit.cPais := 1058;
  LNFe.Emit.EnderEmit.xPais := 'BRASIL';
  LNFe.Emit.IEST := '';
  LNFe.Emit.CRT := TpcnCRT(FParent.Empresa.CrtCodigo - 1);
end;

end.
