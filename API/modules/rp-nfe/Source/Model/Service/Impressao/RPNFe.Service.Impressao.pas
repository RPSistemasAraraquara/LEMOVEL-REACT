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
  RPNFe.Service.Impressao.EscPos,
  RPNFe.Service.Impressao.FastReport;

procedure TRPNFeServiceImpressao.CarregarXml;
begin
  if FXml.Trim.IsEmpty then
    FXml := FDAO.VendaDAO.Xml(FIdVenda);
  if FXml.Trim.IsEmpty then
    raise Exception.CreateFmt('Xml da Venda %d não encontrado.', [FIdVenda]);
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
    raise Exception.Create('Tipo Danfe inválido.');
  end;

  try
    LStrategy.Components(FComponents)
      .DAO(FDAO)
      .IdVenda(FIdVenda)
      .TipoDanfe(FTipoDanfe)
      .Xml(FXml);
    Result := LStrategy.Execute;
  finally
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
