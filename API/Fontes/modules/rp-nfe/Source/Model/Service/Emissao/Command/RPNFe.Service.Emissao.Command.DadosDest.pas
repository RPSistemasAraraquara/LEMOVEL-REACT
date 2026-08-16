unit RPNFe.Service.Emissao.Command.DadosDest;

interface

uses
  System.SysUtils,
  pcnConversaoNFe,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Entity.Classes,
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
  LCliente: TRPNFeEntityCliente;
  LEnderecoCompleto: Boolean;
begin
  LNFe := FParent.Components.Emissor.ACBr.NotasFiscais[0].NFe;
  LCliente := FParent.Venda.Cliente;

  // Sem CPF/CNPJ o ACBr omite o grupo dest automaticamente (NFC-e sem
  // identificacao do consumidor), mesmo comportamento do PDV desktop.
  LNFe.Dest.indIEDest := TpcnindIEDest.inNaoContribuinte;
  LNFe.Dest.CNPJCPF := LCliente.CpfCnpj;
  LNFe.Dest.xNome := LCliente.Nome;

  // Endereco do destinatario so vai no XML se estiver completo; endereco parcial
  // gera rejeicao, e o IBGE ausente/invalido quebrava no StrToInt.
  LEnderecoCompleto :=
    (LCliente.Logradouro <> '') and
    (LCliente.Numero <> '') and
    (LCliente.Bairro <> '') and
    (LCliente.Cidade <> '') and
    (LCliente.UF <> '') and
    (LCliente.CodigoIBGE <> '');

  if LEnderecoCompleto then
  begin
    LNFe.Dest.EnderDest.xLgr := LCliente.Logradouro;
    LNFe.Dest.EnderDest.nro := LCliente.Numero;
    LNFe.Dest.EnderDest.xCpl := LCliente.Complemento;
    LNFe.Dest.EnderDest.xBairro := LCliente.Bairro;
    LNFe.Dest.EnderDest.xMun := LCliente.Cidade;
    LNFe.Dest.EnderDest.UF := LCliente.UF;
    LNFe.Dest.EnderDest.cPais := 1058;
    LNFe.Dest.EnderDest.xPais := 'BRASIL';
    LNFe.Dest.EnderDest.cMun := StrToIntDef(LCliente.CodigoIBGE.Replace('.', ''), 0);
  end;
end;

end.
