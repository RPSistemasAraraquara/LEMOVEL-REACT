unit RPNFe.DAO.Configuracao;

interface

uses
  System.SysUtils,
  Data.DB,
  Datasnap.DBClient,
  RPNFe.Entity.Classes;

type
  TRPNFeDAOConfiguracao = class
  private
    function LoadDataSet(const AFileName: string): TClientDataSet;

    function SetPosition(const ADataSet: TDataSet; const AName: string): Boolean;
    function LoadBoolField(const ADataSet: TDataSet; const AName: string): Boolean;
    function LoadStrField(const ADataSet: TDataSet; const AName: string): string;
    function LoadIntField(const ADataSet: TDataSet; const AName: string): Integer;
  public
    function Carregar(const AFileName: string): TRPNFeEntityConfiguracao;
  end;

implementation

{ TRPNFeDAOConfiguracao }

function TRPNFeDAOConfiguracao.Carregar(const AFileName: string): TRPNFeEntityConfiguracao;
var
  LDataSet: TClientDataSet;
begin
  Result := nil;
  LDataSet := LoadDataSet(AFileName);
  try
    if Assigned(LDataSet) then
    begin
      Result := TRPNFeEntityConfiguracao.Create;
      try
        if LDataSet.RecordCount > 0 then
        begin
          Result.Modelo := 65;
          Result.Producao := LoadIntField(LDataSet, 'RGNFCETIPOAMB') = 0;
          Result.Timeout := LoadIntField(LDataSet, 'EDNFCETIMEOUT');
          Result.RetirarAcentos := LoadBoolField(LDataSet, 'CKNFCERETIRARACENTOS');
          Result.NumeroTentativasEmissao := LoadIntField(LDataSet, 'EDNFCETENTATIVAS');
          Result.IntervaloEntreTentativas := LoadIntField(LDataSet, 'EDNFCEINTERVALO');
          Result.UtilizaResponsavelTecnico := LoadBoolField(LDataSet, 'CKUTILIZARCSRT');
          Result.CertificadoDigital.ArquivoPfx := LoadStrField(LDataSet, 'EDNFCECAMINHOCERTIFICADO');
          Result.CertificadoDigital.Senha := LoadStrField(LDataSet, 'EDNFCESENHACERTIFICADO');
          Result.CertificadoDigital.IdToken := LoadStrField(LDataSet, 'EDNFCEIDTOKEN');
          Result.CertificadoDigital.CscToken := LoadStrField(LDataSet, 'EDNFCETOKEN');
          Result.ResponsavelTecnico.Contato := LoadStrField(LDataSet, 'EDCSRTNOME');
          Result.ResponsavelTecnico.CNPJ := LoadStrField(LDataSet, 'EDCSRTCNPJ');
          Result.ResponsavelTecnico.Email := LoadStrField(LDataSet, 'EDCSRTEMAIL');
          Result.ResponsavelTecnico.Fone := LoadStrField(LDataSet, 'EDCSRTTELEFONE');
        end;
      except
        Result.Free;
        raise;
      end;
    end;
  finally
    LDataSet.Free;
  end;
end;

function TRPNFeDAOConfiguracao.LoadBoolField(const ADataSet: TDataSet;
  const AName: string): Boolean;
begin
  Result := False;
  if SetPosition(ADataSet, AName) then
    Result := ADataSet.FieldByName('LOGICO').AsString.ToLower = 'true';
end;

function TRPNFeDAOConfiguracao.LoadDataSet(const AFileName: string): TClientDataSet;
begin
  if FileExists(AFileName) then
  begin
    Result := TClientDataSet.Create(nil);
    Result.FileName := AFileName;
    Result.Open;
    Result.First;
  end
  else
    raise Exception.Create('Não encontrado o arquivo CONFIGURACAO.XML na pasta da aplicação.');
end;

function TRPNFeDAOConfiguracao.LoadIntField(const ADataSet: TDataSet;
  const AName: string): Integer;
begin
  Result := 0;
  if SetPosition(ADataSet, AName) then
    Result := ADataSet.FieldByName('NUMERO').AsInteger;
end;

function TRPNFeDAOConfiguracao.SetPosition(const ADataSet: TDataSet; const AName: string): Boolean;
begin
  Result := False;
  ADataSet.First;
  while not ADataSet.Eof do
  begin
    if ADataSet.FieldByName('NOME').AsString.ToLower = AName.ToLower then
      Exit(True);
    ADataSet.Next;
  end;
end;

function TRPNFeDAOConfiguracao.LoadStrField(const ADataSet: TDataSet;
  const AName: string): string;
begin
  Result := EmptyStr;
  if SetPosition(ADataSet, AName) then
    Result := ADataSet.FieldByName('TEXTO').AsString;
end;

end.
