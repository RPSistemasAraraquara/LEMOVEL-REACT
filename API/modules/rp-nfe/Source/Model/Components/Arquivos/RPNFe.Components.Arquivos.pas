unit RPNFe.Components.Arquivos;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils;

type
  TRPNFeComponentsArquivos = class
  public
    procedure Salvar(AContent, AFileName: string);
    function Carregar(AFileName: string): string;
  end;

implementation

{ TRPNFeComponentsArquivos }

function TRPNFeComponentsArquivos.Carregar(AFileName: string): string;
begin
  Result := EmptyStr;
  if FileExists(AFileName) then
  begin
    with TStringList.Create do
    try
      LoadFromFile(AFileName);
      Result := Text;
    finally
      Free;
    end;
  end;
end;

procedure TRPNFeComponentsArquivos.Salvar(AContent, AFileName: string);
begin
  if AContent.Trim.IsEmpty then
    Exit;

  if not DirectoryExists(ExtractFilePath(AFileName)) then
    ForceDirectories(ExtractFilePath(AFileName));

  with TStringList.Create do
  try
    Text := AContent;
    SaveToFile(AFileName);
  finally
    Free;
  end;
end;

end.
