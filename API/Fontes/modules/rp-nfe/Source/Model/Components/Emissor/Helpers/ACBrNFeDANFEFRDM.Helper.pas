unit ACBrNFeDANFEFRDM.Helper;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Rtti,
  Vcl.Graphics,
  Vcl.Imaging.jpeg,
  frxExportImage,
  ACBrUtil.Strings,
  ACBrUtil.FilesIO,
  ACBrNFe,
  ACBrNFe.Classes,
  ACBrNFeNotasFiscais,
  ACBrDFeDANFeReport,
  ACBrNFeDANFEFR,
  ACBrNFeDANFEFRDM;

type
  TACBrNFeFRClassHelper = class helper for TACBrNFeFRClass
  public
    function ImprimirDANFEImage(ANFE: TNFe = nil): TMemoryStream;
  end;

  TACBrNFeDANFEFRHelper = class helper for TACBrNFeDANFEFR
  private
    function GetDMDanfe: TACBrNFeFRClass;
  public
    function ImprimirDANFEImage(NFE: TNFe = nil): TMemoryStream;
  end;

  TNotasFiscaisHelper = class helper for TNotasFiscais
  public
    function ImprimirImage: TMemoryStream;
  end;

  TObjectHelper = class helper for TObject
  public
    function GetField(const AFieldName: string): TRttiField;
    procedure InvokeMethod(const AMethodName: string);
  end;

implementation

// Dilata os pixels pretos em 1 ponto nas 4 direcoes (engrossa os tracos das
// letras), pulando as linhas que pertencem ao QR Code. Linhas do QR sao
// detectadas por densidade: muito preto E sem sequencias brancas longas
// (linhas de texto sempre tem espacos largos entre palavras/colunas).
procedure DilatarPreservandoQRCode(ABitmap: TBitmap);
const
  DENSIDADE_QR = 0.18;
  MAIOR_BRANCO_QR = 48;
  GUARDA_QR = 4;
var
  LFonte: TBitmap;
  LEhQR: array of Boolean;
  LCur, LSrcCima, LSrcMeio, LSrcBaixo: PByteArray;
  X, Y, K: Integer;
  LPretos, LBrancoRun, LMaiorBranco: Integer;
begin
  if (ABitmap.Height < 3) or (ABitmap.Width < 3) then
    Exit;

  // Marca as linhas com cara de QR Code.
  SetLength(LEhQR, ABitmap.Height);
  for Y := 0 to ABitmap.Height - 1 do
  begin
    LSrcMeio := ABitmap.ScanLine[Y];
    LPretos := 0;
    LBrancoRun := 0;
    LMaiorBranco := 0;
    for X := 0 to ABitmap.Width - 1 do
      if LSrcMeio[X * 3] < 128 then
      begin
        Inc(LPretos);
        if LBrancoRun > LMaiorBranco then
          LMaiorBranco := LBrancoRun;
        LBrancoRun := 0;
      end
      else
        Inc(LBrancoRun);
    // Nao conta a margem branca do fim da linha.
    LEhQR[Y] := (LPretos > Round(ABitmap.Width * DENSIDADE_QR)) and
      (LMaiorBranco < MAIOR_BRANCO_QR);
  end;

  // Expande a marcacao (banda de guarda acima/abaixo do QR).
  for Y := ABitmap.Height - 1 downto 0 do
    if LEhQR[Y] then
      for K := 1 to GUARDA_QR do
      begin
        if Y - K >= 0 then
          LEhQR[Y - K] := True;
        if Y + K <= ABitmap.Height - 1 then
          LEhQR[Y + K] := True;
      end;

  LFonte := TBitmap.Create;
  try
    LFonte.PixelFormat := pf24bit;
    LFonte.SetSize(ABitmap.Width, ABitmap.Height);
    LFonte.Canvas.Draw(0, 0, ABitmap);

    for Y := 0 to ABitmap.Height - 1 do
    begin
      if LEhQR[Y] then
        Continue;

      LCur := ABitmap.ScanLine[Y];
      LSrcMeio := LFonte.ScanLine[Y];
      if Y > 0 then
        LSrcCima := LFonte.ScanLine[Y - 1]
      else
        LSrcCima := LSrcMeio;
      if Y < ABitmap.Height - 1 then
        LSrcBaixo := LFonte.ScanLine[Y + 1]
      else
        LSrcBaixo := LSrcMeio;

      for X := 0 to ABitmap.Width - 1 do
        if LSrcMeio[X * 3] >= 128 then
        begin
          if ((X > 0) and (LSrcMeio[(X - 1) * 3] < 128)) or
             ((X < ABitmap.Width - 1) and (LSrcMeio[(X + 1) * 3] < 128)) or
             (LSrcCima[X * 3] < 128) or (LSrcBaixo[X * 3] < 128) then
          begin
            LCur[X * 3] := 0;
            LCur[X * 3 + 1] := 0;
            LCur[X * 3 + 2] := 0;
          end;
        end;
    end;
  finally
    LFonte.Free;
  end;
end;

// Prepara o cupom para a impressora termica da maquininha:
// 1. Recorta as margens brancas laterais (cada pixel de margem desperdica
//    papel e diminui a fonte impressa);
// 2. REDUZ para a largura exata do papel (384 pontos) - se a maquininha
//    reescalar, o filtro bilinear transforma preto solido em cinza e a
//    impressao sai fraca;
// 3. BINARIZA depois da reducao (limiar puxado para o preto): todo pixel do
//    anti-serrilhado vira preto solido -> texto grosso e escuro.
procedure RecortarMargensLaterais(AStream: TMemoryStream);
const
  FOLGA = 8;
  LIMIAR_BRANCO = 245;
  // Largura em pontos da bobina 58mm (Stone/PagBank/Cielo).
  LARGURA_PAPEL = 384;
  // Apos a reducao, pixels mais escuros que isso viram preto puro. Quanto
  // maior, mais grossa/escura a impressao (cuidado para nao fechar o QR Code).
  LIMIAR_PRETO = 232;
var
  LJpeg: TJPEGImage;
  LBitmap: TBitmap;
  LRecorte: TBitmap;
  LFinal: TBitmap;
  LLinha: PByteArray;
  X, Y: Integer;
  LMinX, LMaxX: Integer;
  LLargura: Integer;
  LAlturaFinal: Integer;
begin
  LJpeg := TJPEGImage.Create;
  LBitmap := TBitmap.Create;
  try
    AStream.Position := 0;
    LJpeg.LoadFromStream(AStream);
    LBitmap.PixelFormat := pf24bit;
    LBitmap.Assign(LJpeg);

    LMinX := LBitmap.Width;
    LMaxX := -1;
    for Y := 0 to LBitmap.Height - 1 do
    begin
      LLinha := LBitmap.ScanLine[Y];
      for X := 0 to LBitmap.Width - 1 do
        if (LLinha[X * 3] < LIMIAR_BRANCO) or (LLinha[X * 3 + 1] < LIMIAR_BRANCO) or
           (LLinha[X * 3 + 2] < LIMIAR_BRANCO) then
        begin
          if X < LMinX then
            LMinX := X;
          if X > LMaxX then
            LMaxX := X;
        end;
    end;

    // Imagem toda branca: mantem como esta.
    if LMaxX <= LMinX then
      Exit;

    LMinX := LMinX - FOLGA;
    if LMinX < 0 then
      LMinX := 0;
    LMaxX := LMaxX + FOLGA;
    if LMaxX > LBitmap.Width - 1 then
      LMaxX := LBitmap.Width - 1;
    LLargura := LMaxX - LMinX + 1;

    LRecorte := TBitmap.Create;
    LFinal := TBitmap.Create;
    try
      LRecorte.PixelFormat := pf24bit;
      LRecorte.SetSize(LLargura, LBitmap.Height);
      LRecorte.Canvas.CopyRect(Rect(0, 0, LLargura, LBitmap.Height), LBitmap.Canvas,
        Rect(LMinX, 0, LMaxX + 1, LBitmap.Height));

      // Reduz para a largura do papel com HALFTONE (media dos pixels) - a
      // binarizacao em seguida recupera o preto solido no tamanho final.
      if LRecorte.Width > LARGURA_PAPEL then
      begin
        LAlturaFinal := Round(LRecorte.Height * (LARGURA_PAPEL / LRecorte.Width));
        LFinal.PixelFormat := pf24bit;
        LFinal.SetSize(LARGURA_PAPEL, LAlturaFinal);
        SetStretchBltMode(LFinal.Canvas.Handle, HALFTONE);
        SetBrushOrgEx(LFinal.Canvas.Handle, 0, 0, nil);
        StretchBlt(LFinal.Canvas.Handle, 0, 0, LARGURA_PAPEL, LAlturaFinal,
          LRecorte.Canvas.Handle, 0, 0, LRecorte.Width, LRecorte.Height, SRCCOPY);
      end
      else
        LFinal.Assign(LRecorte);

      // Binariza: preto solido ou branco puro (impressao termica escura).
      for Y := 0 to LFinal.Height - 1 do
      begin
        LLinha := LFinal.ScanLine[Y];
        for X := 0 to LFinal.Width - 1 do
          if (LLinha[X * 3] < LIMIAR_PRETO) or (LLinha[X * 3 + 1] < LIMIAR_PRETO) or
             (LLinha[X * 3 + 2] < LIMIAR_PRETO) then
          begin
            LLinha[X * 3] := 0;
            LLinha[X * 3 + 1] := 0;
            LLinha[X * 3 + 2] := 0;
          end
          else
          begin
            LLinha[X * 3] := 255;
            LLinha[X * 3 + 1] := 255;
            LLinha[X * 3 + 2] := 255;
          end;
      end;

      // Dilata o preto em 1 ponto (efeito negrito: mais area queimada por
      // letra = impressao mais forte), PROTEGENDO as linhas do QR Code para
      // nao fechar os modulos.
      DilatarPreservandoQRCode(LFinal);

      LJpeg.CompressionQuality := 100;
      LJpeg.Assign(LFinal);
      AStream.Clear;
      LJpeg.SaveToStream(AStream);
      AStream.Position := 0;
    finally
      LFinal.Free;
      LRecorte.Free;
    end;
  finally
    LBitmap.Free;
    LJpeg.Free;
  end;
end;

{ TACBrNFeFRClassHelper }

function TACBrNFeFRClassHelper.ImprimirDANFEImage(ANFE: TNFe): TMemoryStream;
var
  LExportImage: TfrxJPEGExport;
  LFile: string;
  I : Integer;
begin
  Result := nil;
  LExportImage := TfrxJPEGExport.Create(nil);
  try
    LExportImage.ShowProgress := False;
    LExportImage.ShowDialog := False;
    // 300 DPI + qualidade maxima: a impressora termica da maquininha reduz a
    // imagem para a largura do papel (384 pontos); exportar em resolucao alta
    // mantem o texto nitido (96 DPI gerava imagem MENOR que o papel e a
    // impressao saia borrada/serrilhada).
    LExportImage.Resolution := 300;
    LExportImage.JPEGQuality := 100;
    for I := 1 to TACBrNFe(DANFEClassOwner.ACBrNFe).NotasFiscais.Count do
    begin
      DANFEClassOwner.FIndexImpressaoIndividual := I;
      if PrepareReport(ANFE) then
      begin
        Result := TMemoryStream.Create;
        try
          LExportImage.FileName := ExtractFilePath(GetModuleName(HInstance)) + OnlyNumber(NFe.infNFe.ID) + '-nfe';

          ForceDirectories(ExtractFileDir(LExportImage.FileName));

          frxReport.Export(LExportImage);

          LFile := LExportImage.FileName + '.1.jpg';
          Result.LoadFromFile(LFile);
          Result.Position := 0;
          DeleteFile(LFile);

          try
            RecortarMargensLaterais(Result);
          except
            // Recorte e so otimizacao: em erro, segue com a imagem original.
            Result.Position := 0;
          end;
        except
          Result.Free;
          raise;
        end;
      end;
    end;
  finally
    LExportImage.Free;
  end;

  // Sem Result o caller sofreria access violation ao usar o stream: falha
  // clara e melhor (template ausente/corrompido ou XML sem nota carregada).
  if not Assigned(Result) then
    raise Exception.Create('Falha ao preparar o DANFE em imagem: verifique o template ' +
      'report\DANFeNFCe5_00.fr3 e o XML da nota.');
end;

{ TACBrNFeDANFEFRHelper }

function TACBrNFeDANFEFRHelper.GetDMDanfe: TACBrNFeFRClass;
var
  LField: TRttiField;
begin
  LField := Self.GetField('FdmDanfe');
  Result := TACBrNFeFRClass(LField.GetValue(Self).AsObject);
end;

function TACBrNFeDANFEFRHelper.ImprimirDANFEImage(NFE: TNFe): TMemoryStream;
var
  LDanfe: TACBrNFeFRClass;
begin
  LDanfe := GetDMDanfe;
  Result := LDanfe.ImprimirDANFEImage(nil);
end;

{ TNotasFiscaisHelper }

function TNotasFiscaisHelper.ImprimirImage: TMemoryStream;
var
  LACBr: TComponent;
begin
//  Self.InvokeMethod('VerificarDANFE');
  LACBr := TComponent(GetField('FACBrNFe').GetValue(Self).AsObject);
  Result := TACBrNFeDANFEFR(TACBrNFe(LACBr).DANFE).ImprimirDANFEImage;
end;

{ TObjectHelper }

function TObjectHelper.GetField(const AFieldName: string): TRttiField;
var
  LContext: TRttiContext;
  LType: TRttiType;
begin
  LContext := TRttiContext.Create;
  try
    LType := LContext.GetType(Self.ClassType);
    Result := LType.GetField(AFieldName);
  finally
    LContext.Free;
  end;
end;

procedure TObjectHelper.InvokeMethod(const AMethodName: string);
var
  LContext: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  LContext := TRttiContext.Create;
  try
    LType := LContext.GetType(Self.ClassType);
    LMethod := LType.GetMethod(AMethodName);
    LMethod.Invoke(Self, []);
  finally
    LContext.Free;
  end;
end;

end.
