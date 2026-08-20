unit RPNFe.Service.Emissao.Command.EnviarNota;

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
  TRPNFeServiceEmissaoCommandEnviarNota = class(TRPNFeServiceEmissaoCommand)
  private
    FNotaFiscal: NotaFiscal;
    FOnSetNota: TProc<TRPNFeEntityNFeNotaEletronica>;

    function EmitirNota: TRPNFeEntityNFeNotaEletronica;
    function EmitirContingencia: TRPNFeEntityNFeNotaEletronica;
    procedure SalvarRetorno;
    procedure SalvarXMLAutorizado(ANota: TRPNFeEntityNFeNotaEletronica);
  public
    constructor Create(AParent: TRPNFeServiceEmissao;
      AOnSetNota: TProc<TRPNFeEntityNFeNotaEletronica>); reintroduce;

    procedure Execute; override;
  end;

implementation

{ TRPNFeServiceEmissaoCommandEnviarNota }

constructor TRPNFeServiceEmissaoCommandEnviarNota.Create(AParent: TRPNFeServiceEmissao;
  AOnSetNota: TProc<TRPNFeEntityNFeNotaEletronica>);
begin
  inherited Create(AParent);
  FOnSetNota := AOnSetNota;
end;

function TRPNFeServiceEmissaoCommandEnviarNota.EmitirNota: TRPNFeEntityNFeNotaEletronica;
var
  LMotivo: string;
  LStatus: Integer;
begin
  FNotaFiscal := FParent.Components.Emissor.ACBr.NotasFiscais[0];
  if FParent.Contingencia then
  begin
    Result := EmitirContingencia;
    Exit;
  end;

  Result := TRPNFeEntityNFeNotaEletronica.Create;
  try
    Result.Serie := FNotaFiscal.NFe.Ide.serie;
    Result.NumeroNFe := FNotaFiscal.NFe.Ide.nNF;
    Result.Modelo := FNotaFiscal.NFe.Ide.modelo;
    Result.Contingencia := False;
    Result.Erro := not FParent.Components.Emissor.ACBr.Enviar(1, False, True, False);
    if not Result.Erro then
    begin
      Result.DataAutorizacao := FNotaFiscal.NFe.procNFe.dhRecbto;
      Result.ChaveNFe := FNotaFiscal.NFe.procNFe.chNFe;
      Result.Protocolo := FNotaFiscal.NFe.procNFe.nProt;
    end;

    LStatus := FNotaFiscal.NFe.procNFe.cStat;
    LMotivo := FNotaFiscal.NFe.procNFe.xMotivo;
  except
    on E: EACBrDFeException do
    begin
      LMotivo := E.Message.Replace(#$D, ' ').Replace(#$A, ' ');
      LStatus := FParent.Components.Emissor.ACBr.WebServices.Enviar.cStat;
      Log('Retorno %d - %s', [LStatus, LMotivo]);

      if LStatus > 0 then
        LMotivo := FParent.Components.Emissor.ACBr.WebServices.Enviar.xMotivo;

      Log('Erro na sefaz %d - %s.', [LStatus, LMotivo]);
      // A entidade nao chega ao caller quando ha raise: libera para nao vazar
      // a cada emissao rejeitada (o erro viaja pela excecao).
      FreeAndNil(Result);
      raise;
    end;

    on E: Exception do
    begin
      LStatus := FNotaFiscal.NFe.procNFe.cStat;
      LMotivo := FNotaFiscal.NFe.procNFe.xMotivo;
      E.Message := Format('Erro %d %s: %s', [LStatus, LMotivo, E.Message]);
      FreeAndNil(Result);
      raise;
    end;
  end;

  SalvarRetorno;
  SalvarXMLAutorizado(Result);
  Result.Status := LStatus;
  Result.Motivo := LMotivo;
end;

function TRPNFeServiceEmissaoCommandEnviarNota.EmitirContingencia: TRPNFeEntityNFeNotaEletronica;
begin
  Result := TRPNFeEntityNFeNotaEletronica.Create;
  try
    Result.Serie := FNotaFiscal.NFe.Ide.serie;
    Result.NumeroNFe := FNotaFiscal.NFe.Ide.nNF;
    Result.Modelo := FNotaFiscal.NFe.Ide.modelo;
    Result.Contingencia := True;
    Result.Erro := False;
    Result.DataAutorizacao := Now;
    Result.ChaveNFe := Copy(FNotaFiscal.NFe.infNFe.ID, 4, 44);
    Result.Protocolo := EmptyStr;
    Result.Status := 0;
    Result.Motivo := 'NFC-e emitida em contingencia offline.';
    SalvarXMLAutorizado(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TRPNFeServiceEmissaoCommandEnviarNota.Execute;
var
  LNotaEletronica: TRPNFeEntityNFeNotaEletronica;
begin
  LNotaEletronica := EmitirNota;
  if Assigned(FOnSetNota) then
    FOnSetNota(LNotaEletronica);
end;

procedure TRPNFeServiceEmissaoCommandEnviarNota.SalvarRetorno;
var
  LXml: string;
  LData: string;
  LPath: string;
begin
  try
    LXml := FParent.Components.Emissor.ACBr.WebServices.EnvEvento.RetornoWS;
    if LXml = EmptyStr then
      LXml := FParent.Components.Emissor.ACBr.WebServices.Enviar.RetornoWS;

    LXml := FParent.Components.Emissor.FormatXmlContent(LXml);

    LData := FormatDateTime('yyyyMMdd_hhmmss', Now);
    LPath := Format('\modelo_%d_serie_%d_rp_%d_numero_%d_%s_ret-lot.xml', [FNotaFiscal.NFe.Ide.modelo,
      FNotaFiscal.NFe.Ide.serie, FNotaFiscal.NFe.Ide.cNF, FNotaFiscal.NFe.Ide.nNF, LData]);

    LPath := FParent.Configuracao.PathLog + LPath;
    FParent.Components.Arquivos.Salvar(LXml, LPath);
  except
  end;
end;

procedure TRPNFeServiceEmissaoCommandEnviarNota.SalvarXMLAutorizado(ANota: TRPNFeEntityNFeNotaEletronica);
var
  LXml: string;
  LPath: string;
  LBasePath: string;
  LDataEmissao: TDateTime;
begin
  if ANota.Erro then
    Exit;

  // O Xml da nota alimenta a impressao do DANFCe e a gravacao no banco: a
  // atribuicao NAO pode depender do sucesso da gravacao em disco.
  LXml := FNotaFiscal.XMLAssinado;
  if Trim(LXml) = EmptyStr then
    LXml := FNotaFiscal.GerarXML;
  LXml := FParent.Components.Emissor.FormatXmlContent(LXml);
  if Trim(LXml) = EmptyStr then
    raise Exception.Create('XML da NFC-e nao foi gerado.');
  ANota.Xml := LXml;

  try
    // Mesmo caminho/nome do desktop (uEmissorNFCe.CaminhoXMLVendaAutorizada):
    // <PathNFe>\yyyymm\<chave44>-nfe.xml. O desktop cancela/reimprime a partir
    // deste arquivo, entao o padrao precisa bater.
    LBasePath := FParent.Configuracao.PathNFe;
    if ANota.Contingencia then
      LBasePath := FParent.Configuracao.PathNFeContingencia;

    LDataEmissao := ANota.DataAutorizacao;
    if LDataEmissao = 0 then
      LDataEmissao := Now;
    LPath := Format('%s%s\%s-nfe.xml', [LBasePath,
      FormatDateTime('yyyymm', LDataEmissao), ANota.ChaveNFe]);
    ANota.XmlPath := LPath;

    FParent.Components.Arquivos.Salvar(LXml, LPath);
  except
  end;
end;

end.
