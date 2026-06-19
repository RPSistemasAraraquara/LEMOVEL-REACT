unit APIRPCheff.Resources;

interface

uses
  GBJSON.Interfaces,
  GBJSON.Helper,
  REST.Json,
  System.Classes,
  System.JSON,
  System.SysUtils
{$IFDEF MSWINDOWS},
  Winapi.Windows
{$ENDIF};

type
  TAPIRPCheffResources = class
  private
    FVersaoSistema: string;
    FAPI_PORT: Integer;
    FDATABASE_PASSWORD: string;
    FDATABASE_HOST: string;
    FDATABASE_USERNAME: string;
    FDATABASE_SCHEMA: string;
    FDATABASE_PORT: Integer;
    FDATABASE_ALIAS: string;
    FAUTH_USERNAME: string;
    FAUTH_PASSWORD: string;
    FIMPRESSORA_MODELO: Integer;
    FIMPRESSORA_PORTA: string;
    FIMPRESSORA_COLUNAS: Integer;
    FIMPRESSORA_ESPACOS: Integer;
    FIMPRESSORA_LINHAS_PULO: Integer;
    FIMPRESSORA_PAGINA_CODE: integer;
    FNFE_XML_CONFIGURACAO: string;

    function ResourceFile: string;
    procedure LoadConfig;
    procedure SaveConfig(AFileName: string); overload;
  public
    constructor Create;

    procedure SaveConfig; overload;
    function VersaoSistema: string;

    property API_PORT: Integer read FAPI_PORT write FAPI_PORT;
    property AUTH_USERNAME: string read FAUTH_USERNAME;
    property AUTH_PASSWORD: string read FAUTH_PASSWORD;
    property DATABASE_HOST: string read FDATABASE_HOST write FDATABASE_HOST;
    property DATABASE_PORT: Integer read FDATABASE_PORT write FDATABASE_PORT;
    property DATABASE_SCHEMA: string read FDATABASE_SCHEMA write FDATABASE_SCHEMA;
    property DATABASE_ALIAS: string read FDATABASE_ALIAS write FDATABASE_ALIAS;
    property DATABASE_USERNAME: string read FDATABASE_USERNAME write FDATABASE_USERNAME;
    property DATABASE_PASSWORD: string read FDATABASE_PASSWORD write FDATABASE_PASSWORD;
    property IMPRESSORA_MODELO: Integer read FIMPRESSORA_MODELO write FIMPRESSORA_MODELO;
    property IMPRESSORA_PORTA: string read FIMPRESSORA_PORTA write FIMPRESSORA_PORTA;
    property IMPRESSORA_COLUNAS: Integer read FIMPRESSORA_COLUNAS write FIMPRESSORA_COLUNAS;
    property IMPRESSORA_ESPACOS: Integer read FIMPRESSORA_ESPACOS write FIMPRESSORA_ESPACOS;
    property IMPRESSORA_LINHAS_PULO: Integer read FIMPRESSORA_LINHAS_PULO write FIMPRESSORA_LINHAS_PULO;
    property IMPRESSORA_PAGINA_CODE: integer read FIMPRESSORA_PAGINA_CODE write FIMPRESSORA_PAGINA_CODE;
    property NFE_XML_CONFIGURACAO: string read FNFE_XML_CONFIGURACAO write FNFE_XML_CONFIGURACAO;
  end;

var
  APP_RESOURCES: TAPIRPCheffResources;

implementation

{ TAPIRPCheffResources }

constructor TAPIRPCheffResources.Create;
begin
  FAPI_PORT := 9000;
  FAUTH_USERNAME := 'RP515TEMAS_CH3FF';
  FAUTH_PASSWORD := 'RP515TEMAS';
  FDATABASE_PORT := 5432;
  FDATABASE_SCHEMA := 'public';
  FDATABASE_HOST := '127.0.0.1';
  FDATABASE_ALIAS := 'teste';
  FDATABASE_USERNAME := 'postgres';
  FDATABASE_PASSWORD := 'postgres';
  FIMPRESSORA_MODELO := 0;
  FIMPRESSORA_PORTA := 'USB';
  FIMPRESSORA_ESPACOS := 0;
  FIMPRESSORA_COLUNAS := 32;
  FIMPRESSORA_LINHAS_PULO := 1;
  FNFE_XML_CONFIGURACAO := ExtractFilePath(ParamStr(0)) + 'CONFIGURACAO.XML';
  LoadConfig;
end;

procedure TAPIRPCheffResources.LoadConfig;
var
  LJSON: TJSONObject;
  LArquivo: TStringList;
begin
  LArquivo := TStringList.Create;
  try
    LArquivo.LoadFromFile(ResourceFile);
    LJSON := TGBJSONDefault.Deserializer.StringToJsonObject(LArquivo.Text);
    try
      if Assigned(LJSON) then
        TGBJSONDefault.Serializer.JsonObjectToObject(Self, LJSON);
    finally
      FreeAndNil(LJSON);
    end;
  finally
    FreeAndNil(LArquivo);
  end;
end;

function TAPIRPCheffResources.ResourceFile: string;
begin
  Result := ChangeFileExt(ParamStr(0), '.json');
  if not FileExists(Result) then
    SaveConfig(Result);
end;

procedure TAPIRPCheffResources.SaveConfig(AFileName: string);
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.fromObject(Self);
  try
    LJSON.SaveToFile(AFileName);
  finally
    LJSON.Free;
  end;
end;

procedure TAPIRPCheffResources.SaveConfig;
begin
  SaveConfig(ResourceFile);
end;

function TAPIRPCheffResources.VersaoSistema: string;
{$IFDEF MSWINDOWS}
const
  c_StringInfo = 'StringFileInfo\040904E4\FileVersion';
var
  LExeName: string;
  N: Cardinal;
  LLen: Cardinal;
  LBuffer: PChar;
  LValue : PChar;
begin
  if FVersaoSistema = EmptyStr then
  begin
    LExeName := GetModuleName(HInstance);
    FVersaoSistema := '';
    N := GetFileVersionInfoSize(PChar(LExeName), N);
    if N > 0 then
    begin
      LBuffer := AllocMem(N);
      try
        GetFileVersionInfo(PChar(LExeName), 0, N, LBuffer);
        if VerQueryValue(LBuffer, PChar(c_StringInfo), Pointer(LValue), LLen) then
          FVersaoSistema := Trim(LValue);
      finally
        FreeMem(LBuffer, N);
      end;
    end;
  end;

  Result := FVersaoSistema;
end;
{$ELSE}
begin
  if FVersaoSistema = EmptyStr then
    FVersaoSistema := 'Linux';

  Result := FVersaoSistema;
end;
{$ENDIF}

initialization
  APP_RESOURCES := TAPIRPCheffResources.Create;

finalization
  APP_RESOURCES.Free;

end.
