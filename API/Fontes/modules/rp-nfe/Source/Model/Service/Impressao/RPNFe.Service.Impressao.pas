unit RPNFe.Service.Impressao;

interface

uses
  System.Classes,
  System.SysUtils,
  RPNFe.Entity.Classes,
  RPNFe.Components,
  RPNFe.DAO.Factory;

type
  TRPNFeServiceImpressao = class abstract
  protected
    FComponents: TRPNFeComponents;
    FDAO: TRPNFeDAOFactory;
    FIdVenda: Integer;
    FTipoDanfe: TRPNFeTipoDanfe;
    FXml: string;

    procedure CarregarXml;
  public
    function Components(const AValue: TRPNFeComponents): TRPNFeServiceImpressao;
    function DAO(const AValue: TRPNFeDAOFactory): TRPNFeServiceImpressao;
    function TipoDanfe(const AValue: TRPNFeTipoDanfe): TRPNFeServiceImpressao;

    function IdVenda(const AValue: Integer): TRPNFeServiceImpressao;
    function Xml(const AValue: string): TRPNFeServiceImpressao;

    function Execute: TMemoryStream; virtual;
  end;

implementation

{ TRPNFeServiceImpressao }

uses
  RPNFe.Components.Emissor.ACBr,
  RPNFe.Service.Impressao.EscPos,
  RPNFe.Service.Impressao.FastReport;

procedure TRPNFeServiceImpressao.CarregarXml;
begin
  if FXml.Trim.IsEmpty then
    FXml := FDAO.VendaDAO.Xml(FIdVenda);
  if FXml.Trim.IsEmpty then
    raise Exception.CreateFmt('Xml da Venda %d n�o encontrado.', [FIdVenda]);
end;

function TRPNFeServiceImpressao.Components(const AValue: TRPNFeComponents): TRPNFeServiceImpressao;
begin
  Result := Self;
  FComponents := AValue;
end;

function TRPNFeServiceImpressao.DAO(const AValue: TRPNFeDAOFactory): TRPNFeServiceImpressao;
begin
  Result := Self;
  FDAO := AValue;
end;

// Espera o emissor ficar livre ate o prazo (ms). True = lock adquirido.
function AguardarEmissorLivre(APrazoMs: Integer): Boolean;
var
  LDecorrido: Integer;
begin
  LDecorrido := 0;
  Result := EmissorLock.TryEnter;
  while (not Result) and (LDecorrido < APrazoMs) do
  begin
    Sleep(250);
    Inc(LDecorrido, 250);
    Result := EmissorLock.TryEnter;
  end;
end;

function TRPNFeServiceImpressao.Execute: TMemoryStream;
var
  LStrategy: TRPNFeServiceImpressao;
begin
  case FTipoDanfe of
    tdPosPrinter:
      LStrategy := TRPNFeServiceImpressaoEscPos.Create;
    tdImage:
      LStrategy := TRPNFeServiceImpressaoFastReport.Create;
  else
    raise Exception.Create('Tipo Danfe inv�lido.');
  end;

  // O emissor (ACBr/FastReport) e compartilhado por todas as threads:
  // serializa impressao e emissao para nao colidirem (Abort/travamento).
  // TryEnter com prazo: se uma emissao estiver segurando o lock (SEFAZ lenta),
  // a impressao falha com mensagem clara em vez de pendurar a thread e a
  // conexao do pool (o app tem timeout proprio e reexibe/retenta).
  // Reentrante: a impressao chamada de DENTRO da emissao entra direto.
  if not AguardarEmissorLivre(15000) then
    raise Exception.Create('Emissor fiscal ocupado (emissao em andamento). Tente novamente em instantes.');
  try
    LStrategy.Components(FComponents)
      .DAO(FDAO)
      .IdVenda(FIdVenda)
      .TipoDanfe(FTipoDanfe)
      .Xml(FXml);
    Result := LStrategy.Execute;
  finally
    EmissorLock.Leave;
    // Nao memoiza o XML entre chamadas: um XML de emissao anterior nao pode
    // vazar para a impressao de OUTRA venda.
    FXml := '';
    LStrategy.Free;
  end;
end;

function TRPNFeServiceImpressao.IdVenda(const AValue: Integer): TRPNFeServiceImpressao;
begin
  Result := Self;
  FIdVenda := AValue;
end;

function TRPNFeServiceImpressao.TipoDanfe(const AValue: TRPNFeTipoDanfe): TRPNFeServiceImpressao;
begin
  Result := Self;
  FTipoDanfe := AValue;
end;

function TRPNFeServiceImpressao.Xml(const AValue: string): TRPNFeServiceImpressao;
begin
  Result := Self;
  FXml := AValue;
end;

end.
