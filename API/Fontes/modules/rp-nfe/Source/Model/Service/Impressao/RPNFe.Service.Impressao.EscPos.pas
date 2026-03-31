unit RPNFe.Service.Impressao.EscPos;

interface

uses
  System.Classes,
  ACBrNFe,
  ACBrNFeDANFeESCPOS,
  RPNFe.Components.Impressora.DanfeEscPos,
  RPNFe.Service.Impressao;

type
  TRPNFeServiceImpressaoEscPos = class(TRPNFeServiceImpressao)
  public
    function Execute: TMemoryStream; override;
  end;

implementation

{ TRPNFeServiceImpressaoEscPos }

function TRPNFeServiceImpressaoEscPos.Execute: TMemoryStream;
var
  LACBr: TACBrNFe;
  LDanfe: TACBrNFeDANFeESCPOS;
begin
  Result := nil;
  CarregarXml;
  LDanfe := FComponents.ImpressoraDanfeEscPos.DanfeEscPos;
  LACBr := FComponents.Emissor.ACBr;
  LACBr.DANFE := LDanfe;
  LDanfe.PosPrinter.Ativar;
  try
    LACBr.NotasFiscais.Clear;
    LACBr.NotasFiscais.LoadFromString(FXml);
    LACBr.NotasFiscais.Imprimir;
  finally
    LDanfe.PosPrinter.Desativar;
    LACBr.DANFE := nil;
  end;
end;

end.
