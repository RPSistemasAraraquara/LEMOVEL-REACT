unit RPNFe.Service.Emissao.Command.AssinarXML;

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
  TRPNFeServiceEmissaoCommandAssinarXML = class(TRPNFeServiceEmissaoCommand)
  private
    FNFe: TNFe;
  public
    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandAssinarXML }

procedure TRPNFeServiceEmissaoCommandAssinarXML.Execute;
var
  LXmlAssinado: string;
  LData: string;
  LPath: string;
  LMotivo: string;
begin
  FNFe := FParent.Components.Emissor.ACBr.NotasFiscais.Items[0].NFe;
  Log('Assinando XML.');
  FParent.Components.Emissor.ACBr.NotasFiscais.Assinar;
  try
    LXmlAssinado := FParent.Components.Emissor.ACBr.NotasFiscais[0].XMLAssinado;
    LData := FormatDateTime('yyyyMMdd_hhmmss', Now);
    LPath := Format('\modelo_%d_serie_%d_rp_%d_numero_%d_%s_env-lot.xml', [FNFe.Ide.modelo,
      FNFe.Ide.serie, FNFe.Ide.cNF, FNFe.Ide.nNF, LData]);

    LPath := FParent.Configuracao.PathLog + LPath;
    Log('Salvando XML assinado em %s.', [LPath]);
    FParent.Components.Arquivos.Salvar(LXmlAssinado, LPath);
  except
  end;

  // Validar Regras de Negócio
  if not FParent.Components.Emissor.ACBr.NotasFiscais.ValidarRegrasdeNegocios(LMotivo) then
  begin
    LMotivo := LMotivo.Replace(#$D#$A, ' ').Replace(#$D, ' ').Replace(#$A, ' ');
    Log('XML Inválido: %s', [LMotivo]);

    if FParent.Contingencia then
    begin
      if (Pos('NCM', UpperCase(LMotivo)) > 0) or
         (Pos('CFOP', UpperCase(LMotivo)) > 0) or
         (Pos('GTIN', UpperCase(LMotivo)) > 0) or
         (Pos('CEAN', UpperCase(LMotivo)) > 0) or
         (Pos('CST', UpperCase(LMotivo)) > 0) or
         (Pos('CSOSN', UpperCase(LMotivo)) > 0) then
      begin
        Log('Contingencia offline: erro fiscal cadastral mantido para correcao e envio posterior.');
        Exit;
      end;
    end;

    raise Exception.Create(LMotivo);
  end;

  Log('XML Valido');
end;

end.
