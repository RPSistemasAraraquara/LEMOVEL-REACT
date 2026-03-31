unit RPNFe.Service.Emissao.Command.ResponsavelTecnico;

interface

uses
  System.SysUtils,
  System.Classes,
  ACBrUtil.Base,
  ACBrNFe.Classes,
  pcnConversao,
  pcnConversaoNFe,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Entity.Classes,
  RPNFe.Service.Emissao;

type
  TRPNFeServiceEmissaoCommandResponsavelTecnico = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandResponsavelTecnico }

procedure TRPNFeServiceEmissaoCommandResponsavelTecnico.Execute;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  FNFe.infRespTec.xContato := FParent.Configuracao.ResponsavelTecnico.Contato;
  FNFe.infRespTec.CNPJ := FParent.Configuracao.ResponsavelTecnico.CNPJ;
  FNFe.infRespTec.email := FParent.Configuracao.ResponsavelTecnico.Email;
  FNFe.infRespTec.fone := FParent.Configuracao.ResponsavelTecnico.Fone;
end;

end.
