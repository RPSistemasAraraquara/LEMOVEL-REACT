unit APIRPCheff.Resources.Configuracao;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Types,
  System.Zip;

type
  TAPIRPCheffResourcesConfiguracao = class
  private
    procedure LoadResource(const AResourceName, AFileName: string);
    procedure ExtractResource(const AResourceName, AZipFileName: string);
    procedure ExtrairDiretoriosNFe;
  public
    class procedure ConfiguracaoInicial;
  end;

implementation

{ TAPIRPCheffResourcesConfiguracao }

class procedure TAPIRPCheffResourcesConfiguracao.ConfiguracaoInicial;
begin
  with TAPIRPCheffResourcesConfiguracao.Create do
  try
    ExtrairDiretoriosNFe;
  finally
    Free;
  end;
end;

procedure TAPIRPCheffResourcesConfiguracao.ExtractResource(const AResourceName,
  AZipFileName: string);
var
  LZipFile: TZipFile;
  LZipFileName: string;
begin
  try
    LZipFileName := AZipFileName.Replace('\\', '\');

    ForceDirectories(ExtractFilePath(LZipFileName));
    LoadResource(AResourceName, LZipFileName);
    LZipFile := TZipFile.Create;
    try
      LZipFile.Open(LZipFileName, zmRead);
      LZipFile.ExtractAll(ExtractFilePath(LZipFileName));
      LZipFile.Close;
    finally
      LZipFile.Free;
    end;

    DeleteFile(LZipFileName);
  except
  end;
end;

procedure TAPIRPCheffResourcesConfiguracao.ExtrairDiretoriosNFe;
var
  LZipFileName: string;
begin
{$IFDEF MSWINDOWS}
  LZipFileName := ExtractFilePath(GetModuleName(HInstance)) + 'NFe.zip';
  ExtractResource('NFe', LZipFileName);
{$ENDIF}
end;

procedure TAPIRPCheffResourcesConfiguracao.LoadResource(const AResourceName,
  AFileName: string);
var
  LResource: TResourceStream;
begin
{$IFDEF MSWINDOWS}
  LResource := TResourceStream.Create(HInstance, AResourceName, RT_RCDATA);
  try
    LResource.SaveToFile(AFileName);
  finally
    LResource.Free;
  end;
{$ELSE}
  raise Exception.Create('Recurso embutido indisponivel no build Linux.');
{$ENDIF}
end;

initialization
  try
    TAPIRPCheffResourcesConfiguracao.ConfiguracaoInicial;
  except
  end;

end.
