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
  ERPNFeRejeicaoConfirmada = class(Exception);

  TRPNFeServiceEmissaoCommandEnviarNota = class(TRPNFeServiceEmissaoCommand)
  private
    FNotaFiscal: NotaFiscal;
    FOnSetNota: TProc<TRPNFeEntityNFeNotaEletronica>;

    function EmitirNota: TRPNFeEntityNFeNotaEletronica;
    function EmitirContingencia: TRPNFeEntityNFeNotaEletronica;
    function RejeicaoCadastralConfirmada(AStatus, AAmbiente: Integer;
      const AChave, ADigest: string): Boolean;
    procedure ValidarAutorizacao(const AChave, ADigest: string; AAmbiente: Integer);
    procedure RecuperarProtocoloComAlerta(const ARetorno, AVersao: string; AAmbiente: Integer);
    procedure SalvarRetorno(const AXml, ASufixo: string);
    procedure SalvarXMLAutorizado(ANota: TRPNFeEntityNFeNotaEletronica);
  public
    constructor Create(AParent: TRPNFeServiceEmissao;
      AOnSetNota: TProc<TRPNFeEntityNFeNotaEletronica>); reintroduce;

    procedure Execute; override;
    procedure Recuperar(ANota: TRPNFeEntityNFeNotaEletronica;
      const ATentativa: TRPNFeEntityTentativaNFCe);
  end;

implementation

uses
  ACBrDFe.Conversao,
  ACBrNFe,
  ACBrNFeWebServices,
  ACBrNFe.RetConsSit,
  ACBrNFe.Consts,
  ACBrUtil.Strings,
  ACBrUtil.XMLHTML,
  ACBrXmlDocument;

function StatusAutorizado(AStatus: Integer): Boolean;
begin
  Result := (AStatus = 100) or (AStatus = 120) or (AStatus = 150);
end;

{ TRPNFeServiceEmissaoCommandEnviarNota }

constructor TRPNFeServiceEmissaoCommandEnviarNota.Create(AParent: TRPNFeServiceEmissao;
  AOnSetNota: TProc<TRPNFeEntityNFeNotaEletronica>);
begin
  inherited Create(AParent);
  FOnSetNota := AOnSetNota;
end;

function TRPNFeServiceEmissaoCommandEnviarNota.EmitirNota: TRPNFeEntityNFeNotaEletronica;
var
  LACBr: TACBrNFe;
  LAmbiente: Integer;
  LChave: string;
  LDigest: string;
  LMotivo: string;
  LStatus: Integer;
begin
  LACBr                      := FParent.Components.Emissor.ACBr;
  FNotaFiscal                := LACBr.NotasFiscais[0];
  if FParent.Contingencia then
  begin
    Result                   := EmitirContingencia;
    Exit;
  end;

  Result                     := TRPNFeEntityNFeNotaEletronica.Create;
  try
    Result.Serie             := FNotaFiscal.NFe.Ide.serie;
    Result.NumeroNFe         := FNotaFiscal.NFe.Ide.nNF;
    Result.Modelo            := FNotaFiscal.NFe.Ide.modelo;
    Result.Contingencia      := False;
    LChave                   := FNotaFiscal.NumID;
    LDigest                  := FNotaFiscal.NFe.signature.DigestValue;
    LAmbiente                := StrToInt(TipoAmbienteToStr(FNotaFiscal.NFe.Ide.tpAmb));

    try
      if Result.Modelo = 65 then
        // Enviar assinaria novamente: o lote deve usar o XML ja guardado na tentativa.
        Result.Erro          := not LACBr.WebServices.Envia(1, True, False)
      else
        Result.Erro          := not LACBr.Enviar(1, False, True, False);
    except
      on E: EACBrDFeException do
      begin
        LStatus              := LACBr.WebServices.Enviar.cStat;
        LMotivo              := E.Message.Replace(#$D, ' ').Replace(#$A, ' ');
        Log('Erro no envio fiscal %d - %s.', [LStatus, LMotivo]);
        SalvarRetorno(LACBr.WebServices.Enviar.RetornoWS, 'ret-lot');
        if (Result.Modelo = 65) and
          RejeicaoCadastralConfirmada(LStatus, LAmbiente, LChave, LDigest) then
          raise ERPNFeRejeicaoConfirmada.CreateFmt('%d - %s',
            [LStatus, LACBr.WebServices.Enviar.xMotivo]);
        raise;
      end;
    end;

    if not Result.Erro then
    begin
      if Result.Modelo = 65 then
        ValidarAutorizacao(LChave, LDigest, LAmbiente);
      Result.DataAutorizacao := FNotaFiscal.NFe.procNFe.dhRecbto;
      Result.ChaveNFe        := FNotaFiscal.NFe.procNFe.chDFe;
      Result.Protocolo       := FNotaFiscal.NFe.procNFe.nProt;
    end;

    Result.Status            := FNotaFiscal.NFe.procNFe.cStat;
    Result.Motivo            := FNotaFiscal.NFe.procNFe.xMotivo;
    SalvarRetorno(LACBr.WebServices.Enviar.RetornoWS, 'ret-lot');
    SalvarXMLAutorizado(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TRPNFeServiceEmissaoCommandEnviarNota.RejeicaoCadastralConfirmada(
  AStatus, AAmbiente: Integer; const AChave, ADigest: string): Boolean;
var
  LEnvio: TNFeRecepcao;
  LResposta: TRetConsSitNFe;
begin
  Result                     := False;
  // NCM, municipio/CRT do emitente e classificacao tributaria de IBS/CBS.
  case AStatus of
    471, 480, 481, 778, 1024: ;
  else
    Exit;
  end;
  if (Length(AChave) <> 44) or (ADigest = EmptyStr) then
    Exit;

  LEnvio                     := FParent.Components.Emissor.ACBr.WebServices.Enviar;
  if Pos('<retEnviNFe', LEnvio.RetWS) = 0 then
    Exit;

  LResposta                  := TRetConsSitNFe.Create(LEnvio.VersaoServico);
  try
    try
      // Mesmo leitor usado pelo ACBr para o protocolo no envio sincrono.
      LResposta.XmlRetorno  := StringReplace(LEnvio.RetWS, 'retEnviNFe', 'retConsSitNFe',
        [rfReplaceAll]);
      if not LResposta.LerXml then
        Exit;
      Result                := (LResposta.cStat = 104) and
        (LResposta.protNFe.cStat = AStatus) and
        (LResposta.protNFe.chDFe = AChave) and
        (StrToInt(TipoAmbienteToStr(LResposta.tpAmb)) = AAmbiente) and
        (StrToInt(TipoAmbienteToStr(LResposta.protNFe.tpAmb)) = AAmbiente) and
        (LResposta.protNFe.nProt = EmptyStr) and
        ((LResposta.protNFe.digVal = EmptyStr) or (LResposta.protNFe.digVal = ADigest));
    except
      on E: Exception do
        Log('Retorno fiscal sem comprovacao de rejeicao da tentativa: %s', [E.Message]);
    end;
  finally
    LResposta.Free;
  end;
end;

procedure TRPNFeServiceEmissaoCommandEnviarNota.ValidarAutorizacao(
  const AChave, ADigest: string; AAmbiente: Integer);
begin
  with FNotaFiscal.NFe.procNFe do
    if not StatusAutorizado(cStat) or (chDFe <> AChave) or
      (not (Length(nProt) in [15, 17])) or (OnlyNumber(nProt) <> nProt) or (dhRecbto = 0) or
      (StrToInt(TipoAmbienteToStr(tpAmb)) <> AAmbiente) or
      (ADigest = EmptyStr) or (digVal <> ADigest) or
      (Pos('<nfeProc ', FNotaFiscal.XMLOriginal) = 0) or
      (Pos('<protNFe', FNotaFiscal.XMLOriginal) = 0) then
      raise Exception.Create(
        'A NFC-e permanece pendente de conciliacao: protocolo ou XML da autorizacao incompleto ou divergente.');
end;

procedure TRPNFeServiceEmissaoCommandEnviarNota.RecuperarProtocoloComAlerta(
  const ARetorno, AVersao: string; AAmbiente: Integer);
var
  LDocumento: TACBrXmlDocument;
  LNoProtocolo: TACBrXmlNode;
  LResposta: TRetConsSitNFe;
begin
  LDocumento                 := TACBrXmlDocument.Create;
  try
    LDocumento.LoadFromXml(ARetorno);
    LNoProtocolo             := nil;
    if Assigned(LDocumento.Root) then
      LNoProtocolo           := LDocumento.Root.Childrens.FindAnyNs('protNFe');
    if not Assigned(LNoProtocolo) then
      raise Exception.Create('A consulta da NFC-e com alerta nao trouxe protocolo.');

    LResposta               := TRetConsSitNFe.Create(AVersao);
    try
      // Esta versao do leitor ACBr ignora protNFe se cStat externo for 120.
      // Usa um envelope de leitura local reconhecido, sem modificar o protNFe recebido.
      LResposta.XmlRetorno  := Format('<retConsSitNFe %s versao="%s"><tpAmb>%d</tpAmb>' +
        '<cStat>104</cStat>%s</retConsSitNFe>',
        [NAME_SPACE, AVersao, AAmbiente, LNoProtocolo.OuterXml]);
      if not LResposta.LerXml or (LResposta.protNFe.cStat <> 120) or
        (LResposta.XMLprotNFe = EmptyStr) then
        raise Exception.Create('A consulta da NFC-e com alerta retornou protocolo invalido.');

      FNotaFiscal.NFe.procNFe.Assign(LResposta.protNFe);
      LResposta.protNFe.XML_DFe  := RemoverDeclaracaoXML(FNotaFiscal.XMLOriginal);
      LResposta.protNFe.XML_Prot := LResposta.XMLprotNFe;
      FNotaFiscal.XMLOriginal    := LResposta.protNFe.GerarXML;
    finally
      LResposta.Free;
    end;
  finally
    LDocumento.Free;
  end;
end;

procedure TRPNFeServiceEmissaoCommandEnviarNota.Recuperar(
  ANota: TRPNFeEntityNFeNotaEletronica; const ATentativa: TRPNFeEntityTentativaNFCe);
var
  LACBr: TACBrNFe;
  LConsulta: TNFeConsulta;
  LDigest: string;
begin
  if (Length(ATentativa.Chave) <> 44) or (OnlyNumber(ATentativa.Chave) <> ATentativa.Chave) or
    ((ATentativa.Ambiente <> 1) and (ATentativa.Ambiente <> 2)) or
    (ATentativa.XmlAssinado = EmptyStr) then
    raise Exception.Create('A tentativa fiscal possui chave, ambiente ou XML invalido.');

  LACBr                      := FParent.Components.Emissor.ACBr;
  LACBr.NotasFiscais.Clear;
  FNotaFiscal                := LACBr.NotasFiscais.Add;
  // XML usa o leitor ACBr sem regerar a nota ou passar por LoadFromString/AnsiString.
  FNotaFiscal.XML            := ATentativa.XmlAssinado;
  LDigest                    := FNotaFiscal.NFe.signature.DigestValue;
  if (FNotaFiscal.NumID <> ATentativa.Chave) or (FNotaFiscal.NFe.Ide.modelo <> 65) or
    (StrToInt(TipoAmbienteToStr(FNotaFiscal.NFe.Ide.tpAmb)) <> ATentativa.Ambiente) or
    (StrToInt(TipoAmbienteToStr(LACBr.Configuracoes.WebServices.Ambiente)) <> ATentativa.Ambiente) or
    (FNotaFiscal.NFe.procNFe.nProt <> EmptyStr) or (LDigest = EmptyStr) or
    not FNotaFiscal.VerificarAssinatura then
    raise Exception.Create('A NFC-e pendente possui identidade, ambiente ou assinatura divergente.');

  ANota.Serie                := FNotaFiscal.NFe.Ide.serie;
  ANota.NumeroNFe            := FNotaFiscal.NFe.Ide.nNF;
  ANota.Modelo               := FNotaFiscal.NFe.Ide.modelo;
  ANota.ChaveNFe             := ATentativa.Chave;
  ANota.Contingencia         := ATentativa.Contingencia;

  if ATentativa.Contingencia then
  begin
    if FNotaFiscal.NFe.Ide.tpEmis <> teOffLine then
      raise Exception.Create('O XML da tentativa nao e de contingencia offline.');

    ANota.DataAutorizacao    := FNotaFiscal.NFe.Ide.dEmi;
    ANota.Protocolo          := EmptyStr;
    ANota.Status             := 0;
    ANota.Motivo             := 'NFC-e emitida em contingencia offline.';
  end
  else
  begin
    if FNotaFiscal.NFe.Ide.tpEmis <> teNormal then
      raise Exception.Create('O tipo de emissao do XML da tentativa nao e normal.');

    LACBr.Configuracoes.Geral.FormaEmissao := teNormal;
    LConsulta                 := LACBr.WebServices.Consulta;
    try
      // Uma chave no primeiro parametro limparia o XML carregado.
      LACBr.Consultar('', False);
    except
      on E: Exception do
      begin
        Log('Falha na consulta da NFC-e %s: %s', [ATentativa.Chave, E.Message]);
        raise Exception.Create(
          'A NFC-e permanece pendente de conciliacao: nao foi possivel consultar a tentativa na SEFAZ.');
      end;
    end;
    SalvarRetorno(LConsulta.RetornoWS, 'ret-sit');
    Log('Consulta da NFC-e %s: %d - %s', [ATentativa.Chave, LConsulta.cStat, LConsulta.XMotivo]);

    // Ausencia temporaria (217), cancelamento e denegacao nunca liberam nova emissao.
    if not StatusAutorizado(LConsulta.cStat) or
      (StrToInt(TipoAmbienteToStr(LConsulta.tpAmb)) <> ATentativa.Ambiente) then
      raise Exception.CreateFmt(
        'A NFC-e permanece pendente de conciliacao: consulta SEFAZ %d - %s.',
        [LConsulta.cStat, LConsulta.XMotivo]);

    if (LConsulta.cStat = 120) and (LConsulta.protNFe.cStat = 0) and
      (LConsulta.Protocolo = EmptyStr) and (LConsulta.procEventoNFe.Count = 0) then
      RecuperarProtocoloComAlerta(LConsulta.RetWS, LConsulta.VersaoServico, ATentativa.Ambiente)
    else if not StatusAutorizado(LConsulta.protNFe.cStat) or
      (LConsulta.Protocolo <> LConsulta.protNFe.nProt) then
      raise Exception.Create('A NFC-e permanece pendente de conciliacao: protocolo de autorizacao ausente.');

    // O XML processado une o protNFe ao XML enviado, sem uma nova assinatura.
    ValidarAutorizacao(ATentativa.Chave, LDigest, ATentativa.Ambiente);
    ANota.DataAutorizacao    := FNotaFiscal.NFe.procNFe.dhRecbto;
    ANota.Protocolo          := FNotaFiscal.NFe.procNFe.nProt;
    ANota.Status             := FNotaFiscal.NFe.procNFe.cStat;
    ANota.Motivo             := FNotaFiscal.NFe.procNFe.xMotivo;
  end;
  ANota.Erro                 := False;
  SalvarXMLAutorizado(ANota);
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
    Result.DataAutorizacao := FNotaFiscal.NFe.Ide.dEmi;
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

procedure TRPNFeServiceEmissaoCommandEnviarNota.SalvarRetorno(const AXml, ASufixo: string);
var
  LData: string;
  LPath: string;
begin
  if AXml = EmptyStr then
    Exit;

  try
    LData                    := FormatDateTime('yyyyMMdd_hhmmss', Now);
    LPath                    := Format('\modelo_%d_serie_%d_rp_%d_numero_%d_%s_%s.xml',
      [FNotaFiscal.NFe.Ide.modelo, FNotaFiscal.NFe.Ide.serie, FNotaFiscal.NFe.Ide.cNF,
       FNotaFiscal.NFe.Ide.nNF, LData, ASufixo]);

    LPath                    := FParent.Configuracao.PathLog + LPath;
    FParent.Components.Arquivos.Salvar(AXml, LPath);
  except
    on E: Exception do
      Log('Falha ao gravar retorno fiscal: %s', [E.Message]);
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
  if ANota.Modelo = 65 then
    LXml                     := FNotaFiscal.XMLOriginal
  else
  begin
    LXml                     := FNotaFiscal.XMLAssinado;
    if Trim(LXml) = EmptyStr then
      LXml                   := FNotaFiscal.GerarXML;
    LXml                     := FParent.Components.Emissor.FormatXmlContent(LXml);
  end;
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
