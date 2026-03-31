unit RPNFe.Components.Impressora.DanfeEscPos;

interface

uses
  System.SysUtils,
  ACBrNFeDANFEClass,
  ACBrNFeDANFeESCPOS,
  ACBrDFeReport,
  ACBrPosPrinter,
  pcnConversao;

type
  TACBrPosPrinterModelo = ACBrPosPrinter.TACBrPosPrinterModelo;

  TACBrPosPaginaCodigo = ACBrPosPrinter.TACBrPosPaginaCodigo;

  TRPNFeComponentsImpressoraDanfeEscPos = class
  private
    FDanfe: TACBrNFeDANFeESCPOS;
    FACBrPosPrinter: TACBrPosPrinter;

    procedure Configurar;
  public
    constructor Create;
    destructor Destroy; override;

    function DanfeEscPos: TACBrNFeDANFeESCPOS;

    function Modelo(const AValue: TACBrPosPrinterModelo): TRPNFeComponentsImpressoraDanfeEscPos;
    function PaginaDeCodigo(const AValue: TACBrPosPaginaCodigo): TRPNFeComponentsImpressoraDanfeEscPos;
    function Porta(const AValue: string): TRPNFeComponentsImpressoraDanfeEscPos;
    function Colunas(const AValue: Integer): TRPNFeComponentsImpressoraDanfeEscPos;
    function Espacos(const AValue: Integer): TRPNFeComponentsImpressoraDanfeEscPos;
    function CortaPapel(const AValue: Boolean): TRPNFeComponentsImpressoraDanfeEscPos;
    function LinhasEntreCupons(const AValue: Integer): TRPNFeComponentsImpressoraDanfeEscPos;
  end;

implementation

{ TRPNFeComponentsImpressoraDanfeEscPos }

function TRPNFeComponentsImpressoraDanfeEscPos.Colunas(const AValue: Integer): TRPNFeComponentsImpressoraDanfeEscPos;
begin
  Result := Self;
  FDanfe.PosPrinter.ColunasFonteNormal := AValue;
end;

procedure TRPNFeComponentsImpressoraDanfeEscPos.Configurar;
begin
  FDanfe.PosPrinter := FACBrPosPrinter;
  FDanfe.PosPrinter.Modelo := ppTexto;
  FDanfe.PosPrinter.Porta := 'COM9';
  FDanfe.PosPrinter.PaginaDeCodigo := pc850;
  FDanfe.TipoDANFE := TpcnTipoImpressao.tiSemGeracao;
  FDanfe.Sistema := 'RPSistemas';
end;

function TRPNFeComponentsImpressoraDanfeEscPos.CortaPapel(const AValue: Boolean): TRPNFeComponentsImpressoraDanfeEscPos;
begin
  Result := Self;
  FDanfe.PosPrinter.CortaPapel := AValue;
end;

constructor TRPNFeComponentsImpressoraDanfeEscPos.Create;
begin
  FDanfe := TACBrNFeDANFeESCPOS.Create(nil);
  FACBrPosPrinter := TACBrPosPrinter.Create(nil);
  Configurar;
end;

function TRPNFeComponentsImpressoraDanfeEscPos.DanfeEscPos: TACBrNFeDANFeESCPOS;
begin
  Result := FDanfe;
end;

destructor TRPNFeComponentsImpressoraDanfeEscPos.Destroy;
begin
  FDanfe.Free;
  FACBrPosPrinter.Free;
  inherited;
end;

function TRPNFeComponentsImpressoraDanfeEscPos.Espacos(const AValue: Integer): TRPNFeComponentsImpressoraDanfeEscPos;
begin
  Result := Self;
  FDanfe.PosPrinter.EspacoEntreLinhas := AValue;
end;

function TRPNFeComponentsImpressoraDanfeEscPos.LinhasEntreCupons(const AValue: Integer): TRPNFeComponentsImpressoraDanfeEscPos;
begin
  Result := Self;
  FDanfe.PosPrinter.LinhasEntreCupons := AValue;
end;

function TRPNFeComponentsImpressoraDanfeEscPos.Modelo(const AValue: TACBrPosPrinterModelo): TRPNFeComponentsImpressoraDanfeEscPos;
begin
  Result := Self;
  FDanfe.PosPrinter.Modelo := AValue;
end;

function TRPNFeComponentsImpressoraDanfeEscPos.PaginaDeCodigo(const AValue: TACBrPosPaginaCodigo): TRPNFeComponentsImpressoraDanfeEscPos;
begin
  Result := Self;
  FDanfe.PosPrinter.PaginaDeCodigo := AValue;
end;

function TRPNFeComponentsImpressoraDanfeEscPos.Porta(const AValue: string): TRPNFeComponentsImpressoraDanfeEscPos;
begin
  Result := Self;
  FDanfe.PosPrinter.Porta := AValue;
end;

end.
