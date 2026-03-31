unit RPNFe.Components;

interface

uses
  RPNFe.Components.Arquivos,
  RPNFe.Components.Connection,
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Components.Impressora.DanfeEscPos,
  RPNFe.Components.Log;

type
  TRPNFeComponents = class
  private
    FArquivos: TRPNFeComponentsArquivos;
    FConnection: TRPNFeComponentsConnection;
    FEmissor: TRPNFeComponentsEmissorACBr;
    FImpressoraDanfeEscPos: TRPNFeComponentsImpressoraDanfeEscPos;
    FLog: TRPNFeComponentsLog;
  public
    destructor Destroy; override;

    function Arquivos: TRPNFeComponentsArquivos;
    function Connection: TRPNFeComponentsConnection;
    function Emissor: TRPNFeComponentsEmissorACBr;
    function ImpressoraDanfeEscPos: TRPNFeComponentsImpressoraDanfeEscPos;
    function Log: TRPNFeComponentsLog;
  end;

implementation

{ TRPNFeComponents }

function TRPNFeComponents.Arquivos: TRPNFeComponentsArquivos;
begin
  if not Assigned(FArquivos) then
    FArquivos := TRPNFeComponentsArquivos.Create;
  Result := FArquivos;
end;

function TRPNFeComponents.Connection: TRPNFeComponentsConnection;
begin
  if not Assigned(FConnection) then
    FConnection := TRPNFeComponentsConnection.Create;
  Result := FConnection;
end;

destructor TRPNFeComponents.Destroy;
begin
  FArquivos.Free;
  FConnection.Free;
  FEmissor.Free;
  FImpressoraDanfeEscPos.Free;
  FLog.Free;
  inherited;
end;

function TRPNFeComponents.Emissor: TRPNFeComponentsEmissorACBr;
begin
  if not Assigned(FEmissor) then
    FEmissor := TRPNFeComponentsEmissorACBr.Create;
  Result := FEmissor;
end;

function TRPNFeComponents.ImpressoraDanfeEscPos: TRPNFeComponentsImpressoraDanfeEscPos;
begin
  if not Assigned(FImpressoraDanfeEscPos) then
    FImpressoraDanfeEscPos := TRPNFeComponentsImpressoraDanfeEscPos.Create;
  Result := FImpressoraDanfeEscPos;
end;

function TRPNFeComponents.Log: TRPNFeComponentsLog;
begin
  if not Assigned(FLog) then
    FLog := TRPNFeComponentsLog.Create;
  Result := FLog;
end;

end.
