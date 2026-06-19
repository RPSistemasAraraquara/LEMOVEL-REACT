unit APIRPCheff.Components.Impressora;

interface

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo
{$IFDEF MSWINDOWS},
  ACBrDevice,
  ACBrWinUSBDevice,
  ACBrPosPrinter
{$ENDIF},
  APIRPCheff.Resources;

type
  TAPIRPCheffComponentsImpressora = class
  private
{$IFDEF MSWINDOWS}
    FPrinter: TACBrPosPrinter;
{$ENDIF}

    procedure ValidarImpressora;

  public
    constructor Create;
    destructor Destroy; override;

    function Configurar: TAPIRPCheffComponentsImpressora;
    function Ativar: TAPIRPCheffComponentsImpressora;
    function Desativar: TAPIRPCheffComponentsImpressora;
    procedure Imprimir(AConteudo: string);
    procedure ImprimirTeste;
    procedure ListarModelos(AList: TStrings);
    procedure ListarCodigoPagina(AList: TStrings);
    procedure ListarBluetooths(AList: TStrings);
    procedure ListarPortasUSB(AList:TStrings);
     procedure ListarCodigosPagina(AList: TStrings);
  end;

implementation

{ TAPIRPCheffComponentsImpressora }

function TAPIRPCheffComponentsImpressora.Ativar: TAPIRPCheffComponentsImpressora;
begin
  Result := Self;
{$IFDEF MSWINDOWS}
  try
    FPrinter.Ativar;
  except
    on E: Exception do
    begin
      E.Message := 'Erro ao ativar impressora: ' + E.Message;
      raise;
    end;
  end;
{$ENDIF}
end;

function TAPIRPCheffComponentsImpressora.Configurar: TAPIRPCheffComponentsImpressora;
{$IFDEF MSWINDOWS}
var
  PaginaCodigo: TACBrPosPaginaCodigo;
{$ENDIF}
begin
  Result := Self;
{$IFNDEF MSWINDOWS}
  Exit;
{$ENDIF}
{$IFDEF MSWINDOWS}
  Desativar;

  FPrinter.Porta := APP_RESOURCES.IMPRESSORA_PORTA;
  FPrinter.Modelo := TACBrPosPrinterModelo(APP_RESOURCES.IMPRESSORA_MODELO);
  FPrinter.LinhasBuffer := 5;
  FPrinter.LinhasEntreCupons := APP_RESOURCES.IMPRESSORA_LINHAS_PULO;
  FPrinter.EspacoEntreLinhas := APP_RESOURCES.IMPRESSORA_ESPACOS;
  FPrinter.ColunasFonteNormal := APP_RESOURCES.IMPRESSORA_COLUNAS;
  FPrinter.ControlePorta := True;
   try
    PaginaCodigo := TACBrPosPaginaCodigo(APP_RESOURCES.IMPRESSORA_PAGINA_CODE);
  except
    on E: Exception do
    begin
      PaginaCodigo := TACBrPosPaginaCodigo.pc850;
      raise Exception.CreateFmt('C'#243'digo de P'#225'gina inv'#225'lido. Usando padr'#227'o: %s. Erro: %s',
        [GetEnumName(TypeInfo(TACBrPosPaginaCodigo), Integer(PaginaCodigo)), E.Message]);
    end;
  end;
  FPrinter.PaginaDeCodigo := PaginaCodigo;

  FPrinter.CortaPapel := True;
  FPrinter.TraduzirTags := True;
  FPrinter.IgnorarTags := False;

  FPrinter.ConfigLogo.KeyCode1 := 1;
  FPrinter.ConfigLogo.KeyCode2 := 0;
  FPrinter.ConfigLogo.FatorX := 1;
  FPrinter.ConfigLogo.FatorY := 1;
  try
    FPrinter.Ativar;
  except
    on E: Exception do
      raise Exception.Create('Erro ao ativar impressora: ' + E.Message);
  end;
{$ENDIF}
end;

procedure TAPIRPCheffComponentsImpressora.ListarCodigosPagina(AList: TStrings);
{$IFDEF MSWINDOWS}
var
  LCodigo: TACBrPosPaginaCodigo;
{$ENDIF}
begin
  AList.Clear;
{$IFDEF MSWINDOWS}
  for LCodigo := Low(TACBrPosPaginaCodigo) to High(TACBrPosPaginaCodigo) do
    AList.Add(GetEnumName(TypeInfo(TACBrPosPaginaCodigo), Integer(LCodigo)));
{$ELSE}
  AList.Add('pc850');
{$ENDIF}
end;

constructor TAPIRPCheffComponentsImpressora.Create;
begin
{$IFDEF MSWINDOWS}
  FPrinter := TACBrPosPrinter.Create(nil);
{$ENDIF}
end;

function TAPIRPCheffComponentsImpressora.Desativar: TAPIRPCheffComponentsImpressora;
begin
  Result := Self;
{$IFDEF MSWINDOWS}
  try
    if FPrinter.Ativo then
      FPrinter.Desativar;
  except
    on E: Exception do
    begin
      E.Message := 'Erro ao desativar impressora: ' + E.Message;
      raise;
    end;
  end;
{$ENDIF}
end;

destructor TAPIRPCheffComponentsImpressora.Destroy;
begin
{$IFDEF MSWINDOWS}
  FreeAndNil(FPrinter);
{$ENDIF}
  inherited;
end;

procedure TAPIRPCheffComponentsImpressora.Imprimir(AConteudo: string);
begin
{$IFNDEF MSWINDOWS}
  raise Exception.Create('Impressao local indisponivel no build Linux da API.');
{$ENDIF}
{$IFDEF MSWINDOWS}
  ValidarImpressora;
  if not FPrinter.Ativo then
  begin
    Configurar;
    Ativar;
  end;

  FPrinter.Buffer.Text := AConteudo;
  if APP_RESOURCES.IMPRESSORA_MODELO = 0 then
    FPrinter.Buffer.SaveToFile('impressao.txt')
  else
    FPrinter.Imprimir;
{$ENDIF}
end;

procedure TAPIRPCheffComponentsImpressora.ImprimirTeste;
var
  LConteudo: string;
begin
  LConteudo :=
    '</zera>' + sLineBreak +
    '</linha_dupla>' + sLineBreak +
    'TEXTO NORMAL' + sLineBreak +
    '</ae>ALINHADO A ESQUERDA' + sLineBreak +
    '1 2 3 TESTANDO' + sLineBreak +
    '<n>FONTE NEGRITO</N>' + sLineBreak +
    '<e>FONTE EXPANDIDA</e>' + sLineBreak +
    '<a>FONTE ALT.DUPLA</a>' + sLineBreak +
    '<c>FONTE CONDENSADA</c>' + sLineBreak +
    '<in>FONTE INVERTIDA' + sLineBreak +
    '</in><S>FONTE SUBLINHA DA</s>' + sLineBreak +
    '<i>FONTE ITALICO</i>' + sLineBreak +
    '</fn></ce>ALINHADO NO CENTRO' + sLineBreak +
    '1 2 3 TESTANDO' + sLineBreak +
    '<n>FONTE NEGRITO</N>' + sLineBreak +
    '<e>FONTE EXPANDIDA</e>' + sLineBreak +
    '<a>FONTE ALT.DUPLA</a>' + sLineBreak +
    '<c>FONTE CONDENSADA</c>' + sLineBreak +
    '<in>FONTE INVERTIDA' + sLineBreak +
    '</in><S>FONTE SUBLINHADA</s>' + sLineBreak +
    '<i>FONTE ITALICO</i>' + sLineBreak +
    '</fn></ad>ALINHADO A DIREITA' + sLineBreak +
    '1 2 3 TESTANDO' + sLineBreak +
    '<n>FONTE NEGRITO</N>' + sLineBreak +
    '<e>FONTE EXPANDIDA</e>' + sLineBreak +
    '<a>FONTE ALT.DUPLA</a>' + sLineBreak +
    '<c>FONTE CONDENSADA</c>' + sLineBreak +
    '<in>FONTE INVERTIDA' + sLineBreak +
    '</in><S>FONTE SUBLINHADA</s>' + sLineBreak +
    '<i>FONTE ITALICO</i>' + sLineBreak +
    '</ae></fn>TEXTO NORMAL' + sLineBreak +
    '</corte_total>';

  Imprimir(LConteudo);
end;


procedure TAPIRPCheffComponentsImpressora.ListarPortasUSB(AList: TStrings);
begin
  AList.Clear;
{$IFDEF MSWINDOWS}
  FPrinter.Device.AcharPortasSeriais(AList);
  FPrinter.Device.AcharPortasUSB(AList);
  FPrinter.Device.AcharPortasRAW(AList);
{$ELSE}
  AList.Add('NULL');
{$ENDIF}
end;

procedure TAPIRPCheffComponentsImpressora.ListarBluetooths(AList: TStrings);
begin
  AList.Clear;
{$IFDEF MSWINDOWS}
  try
    FPrinter.Device.AcharPortasBlueTooth(AList);
  except
  end;
{$ENDIF}
  AList.Add('NULL');
end;

procedure TAPIRPCheffComponentsImpressora.ListarCodigoPagina(AList: TStrings);
{$IFDEF MSWINDOWS}
var
  LCodigo: TACBrPosPaginaCodigo;
{$ENDIF}
begin
  AList.Clear;
{$IFDEF MSWINDOWS}
  for LCodigo := Low(TACBrPosPaginaCodigo) to High(TACBrPosPaginaCodigo) do
    AList.Add(GetEnumName(TypeInfo(TACBrPosPaginaCodigo), Integer(LCodigo)));
{$ELSE}
  AList.Add('pc850');
{$ENDIF}
end;

procedure TAPIRPCheffComponentsImpressora.ListarModelos(AList: TStrings);
{$IFDEF MSWINDOWS}
var
  LModelo: TACBrPosPrinterModelo;
{$ENDIF}
begin
  AList.Clear;
{$IFDEF MSWINDOWS}
  for LModelo := Low(TACBrPosPrinterModelo) to High(TACBrPosPrinterModelo) do
    AList.Add(GetEnumName(TypeInfo(TACBrPosPrinterModelo), Integer(LModelo)));
{$ELSE}
  AList.Add('ppTexto');
{$ENDIF}
end;

procedure TAPIRPCheffComponentsImpressora.ValidarImpressora;
begin
  if APP_RESOURCES.IMPRESSORA_PORTA.Trim = EmptyStr then
    raise Exception.Create('Porta Impressora n'#227'o informada.');
end;

end.
