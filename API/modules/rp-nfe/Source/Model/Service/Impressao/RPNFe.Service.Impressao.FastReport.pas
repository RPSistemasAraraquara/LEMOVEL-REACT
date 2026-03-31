unit RPNFe.Service.Impressao.FastReport;

interface

uses
  System.Classes,
  System.SysUtils,
  ACBrNFe,
  ACBrNFeDANFEFR,
  ACBrNFeDANFEFRDM.Helper,
  RPNFe.Service.Impressao;

type
  TRPNFeServiceImpressaoFastReport = class(TRPNFeServiceImpressao)
  public
    function Execute: TMemoryStream; override;
  end;

implementation

{ TRPNFeServiceImpressaoFastReport }

function TRPNFeServiceImpressaoFastReport.Execute: TMemoryStream;
var
  LDanfe: TACBrNFeDANFEFR;
  LACBr: TACBrNFe;
begin
  CarregarXml;
  LACBr := FComponents.Emissor.ACBr;
  LDanfe := TACBrNFeDANFEFR.Create(nil);
  try
    LACBr.DANFE := LDanfe;
    LDanfe.Sistema := 'RP Sistemas';
    LDanfe.FastFile := ExtractFilePath(GetModuleName(HInstance)) + 'report\DANFeNFCe5_00.fr3';
    LACBr.NotasFiscais.Clear;
    LACBr.NotasFiscais.LoadFromString(FXml);
    Result := LACBr.NotasFiscais.ImprimirImage;
  finally
    LACBr.DANFE := nil;
    LDanfe.Free;
  end;
end;

end.
