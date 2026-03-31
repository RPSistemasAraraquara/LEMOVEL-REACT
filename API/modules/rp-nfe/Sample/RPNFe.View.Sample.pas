unit RPNFe.View.Sample;

interface

uses
  System.TypInfo,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.PG, FireDAC.Phys.PGDef, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus,
  RPNFe.Entity.Classes,
  RPNFe.Components.Impressora.DanfeEscPos,
  RPNFe.Controller, Datasnap.DBClient, DBAccess, PgAccess;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    FDConnection1: TFDConnection;
    pgcNFe: TPageControl;
    TabEmissao: TTabSheet;
    TabConfiguracao: TTabSheet;
    TabLog: TTabSheet;
    Label1: TLabel;
    EdtIdVenda: TEdit;
    ChkProducao: TCheckBox;
    Label2: TLabel;
    EdtModelo: TEdit;
    Label3: TLabel;
    EdtTimeout: TEdit;
    GroupBox1: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    EdtResponsavelContato: TEdit;
    EdtResponsavelCNPJ: TEdit;
    EdtResponsavelEmail: TEdit;
    EdtResponsavelTelefone: TEdit;
    GroupBox2: TGroupBox;
    EdtPathSchemas: TEdit;
    Label8: TLabel;
    EdtPathNFe: TEdit;
    Label9: TLabel;
    Label10: TLabel;
    EdtPathNFeContingencia: TEdit;
    Label11: TLabel;
    EdtPathLog: TEdit;
    MemoLog: TMemo;
    pmPopup: TPopupMenu;
    LimparLog1: TMenuItem;
    BtnEmissao: TButton;
    TabCertificado: TTabSheet;
    GroupBox3: TGroupBox;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    EdtCertificadoArquivoPFX: TEdit;
    EdtCertificadoSenha: TEdit;
    EdtCertificadoIdToken: TEdit;
    EdtCertificadoCsc: TEdit;
    Label18: TLabel;
    EdtJustificativa: TEdit;
    Label19: TLabel;
    EdtProtocolo: TEdit;
    Label20: TLabel;
    EdtChaveNFe: TEdit;
    BtnCancelar: TButton;
    BtnImpressao: TButton;
    DataSetConfiguracao: TClientDataSet;
    TabImpressao: TTabSheet;
    GroupBox4: TGroupBox;
    Label16: TLabel;
    Label17: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    EdtModeloImpressora: TComboBox;
    EdtImpressoraColunas: TEdit;
    EdtImpressoraEspacos: TEdit;
    EdtImpressoraLinhaPulo: TEdit;
    BtnTestarImpresssao: TButton;
    EdtPortaImpressora: TComboBox;
    cbCortarPapel: TCheckBox;
    cbxPagCodigo: TComboBox;
    MemoXml: TMemo;
    Label25: TLabel;
    EdtImpressaoIdVenda: TEdit;
    BtnImpressaoImagem: TButton;
    PgConnection1: TPgConnection;
    procedure FormCreate(Sender: TObject);
    procedure LimparLog1Click(Sender: TObject);
    procedure BtnEmissaoClick(Sender: TObject);
    procedure BtnTestarImpresssaoClick(Sender: TObject);
    procedure BtnImpressaoImagemClick(Sender: TObject);
  private
    FController: TRPNFeController;

    procedure Log(AValue: string);
    procedure Emitir;

    procedure LerConfiguracao;
    procedure CarregarPropriedadesImpressora;
  public
    destructor Destroy; override;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.BtnEmissaoClick(Sender: TObject);
var
  LDataSet: TClientDataSet;
  I: Integer;
begin
  LDataSet := TClientDataSet.Create(nil);
  LDataSet.FileName := 'CONFIGURACAO.XML';
  LDataSet.Open;
  LDataSet.First;
  while not LDataSet.Eof do
  begin
    for I := 0 to Pred(LDataSet.FieldCount) do
      ShowMessage(LDataSet.fields[I].FieldName);
//    ShowMessage(LDataSet.fields[0].Value);
//    ShowMessage(LDataSet.fields[1].FieldName);
//    ShowMessage(LDataSet.fields[1].Value);
    LDataSet.Next;
  end;
  ShowMessage(LDataSet.RecordCount.ToString);
//  DataSetConfiguracao.LoadFromFile('CONFIGURACAO.XML');
//  DataSetConfiguracao.Active := True;
  ShowMessage(DataSetConfiguracao.FieldByName('EDNFCETOKEN').AsString);
  exit;
  Emitir;
end;

procedure TForm1.BtnImpressaoImagemClick(Sender: TObject);
var
  LXml: string;
  LIdVenda: Integer;
  LStream: TMemoryStream;
begin
  LXml := MemoXml.Lines.Text.Trim;
  LIdVenda := StrToIntDef(EdtImpressaoIdVenda.Text, 0);

  LStream := FController.Service.ImpressaoService
    .TipoDanfe(tdImage)
    .Xml(LXml)
    .IdVenda(LIdVenda)
    .Execute;
  try
    if Assigned(LStream) then
      LStream.SaveToFile('danfe.jpg');
  finally
    LStream.Free;
  end;
end;

procedure TForm1.BtnTestarImpresssaoClick(Sender: TObject);
var
  LXml: string;
  LIdVenda: Integer;
begin
  LXml := MemoXml.Lines.Text.Trim;
  LIdVenda := StrToIntDef(EdtImpressaoIdVenda.Text, 0);

  FController.Components.ImpressoraDanfeEscPos.Modelo(TACBrPosPrinterModelo(EdtModeloImpressora.ItemIndex))
    .Porta(EdtPortaImpressora.Text)
    .Colunas(StrToIntDef(EdtImpressoraColunas.Text, 0))
    .Espacos(StrToIntDef(EdtImpressoraEspacos.Text, 0))
    .CortaPapel(cbCortarPapel.Checked)
    .PaginaDeCodigo(TACBrPosPaginaCodigo(cbxPagCodigo.ItemIndex))
    .LinhasEntreCupons(StrToIntDef(EdtImpressoraLinhaPulo.Text, 0));

  FController.Service.ImpressaoService
    .TipoDanfe(tdPosPrinter)
    .Xml(LXml)
    .IdVenda(LIdVenda)
    .Execute;
end;

procedure TForm1.CarregarPropriedadesImpressora;
begin
  cbxPagCodigo.Items.Clear;
  for var LCodigo := Low(TACBrPosPaginaCodigo) to High(TACBrPosPaginaCodigo) do
    cbxPagCodigo.Items.Add(GetEnumName(TypeInfo(TACBrPosPaginaCodigo), Integer(LCodigo)));
  cbxPagCodigo.ItemIndex := 0;

  EdtModeloImpressora.Items.Clear;
  for var LModelo := Low(TACBrPosPrinterModelo) to High(TACBrPosPrinterModelo) do
    EdtModeloImpressora.Items.Add(GetEnumName(TypeInfo(TACBrPosPrinterModelo), Integer(LModelo)));
  EdtModeloImpressora.ItemIndex := 0;
end;

destructor TForm1.Destroy;
begin
  FController.Free;
  inherited;
end;

procedure TForm1.Emitir;
var
  LNotaEletronica: TRPNFeEntityNFeNotaEletronica;
begin
  LNotaEletronica := FController.Service.EmissaoService
    .IdVenda(StrToInt(EdtIdVenda.Text))
    .Execute;
  try
    ShowMessage(LNotaEletronica.MensagemStatus);
    EdtProtocolo.Text := LNotaEletronica.Protocolo;
    EdtChaveNFe.Text := LNotaEletronica.ChaveNFe;
  finally
    LNotaEletronica.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  pgcNFe.ActivePage := TabEmissao;
//  FDConnection1.Connected := True;
  PgConnection1.Connected := True;
  FController := TRPNFeController.Create;
  FController.Connection(PgConnection1)
    .Components.Log.OnLog(Self.Log);

  LerConfiguracao;
  CarregarPropriedadesImpressora;
end;

procedure TForm1.LerConfiguracao;
var
  LConfiguracao: TRPNFeEntityConfiguracao;
  LFileName: string;
begin
  LFileName := ExtractFilePath(GetModuleName(HInstance)) + 'CONFIGURACAO.XML';
  LConfiguracao := FController.DAO.ConfiguracaoDAO.Carregar(LFileName);
  try
    ChkProducao.Checked := LConfiguracao.Producao;
    EdtModelo.Text := LConfiguracao.Modelo.ToString;
    EdtTimeout.Text := LConfiguracao.Timeout.ToString;
    EdtResponsavelCNPJ.Text := LConfiguracao.ResponsavelTecnico.CNPJ;
    EdtResponsavelEmail.Text := LConfiguracao.ResponsavelTecnico.Email;
    EdtResponsavelContato.Text := LConfiguracao.ResponsavelTecnico.Contato;
    EdtResponsavelTelefone.Text := LConfiguracao.ResponsavelTecnico.Fone;
    EdtPathSchemas.Text := LConfiguracao.PathSchemas;
    EdtPathNFe.Text := LConfiguracao.PathNFe;
    EdtPathNFeContingencia.Text := LConfiguracao.PathNFeContingencia;
    EdtPathLog.Text := LConfiguracao.PathLog;
    EdtCertificadoArquivoPFX.Text := LConfiguracao.CertificadoDigital.ArquivoPfx;
    EdtCertificadoSenha.Text := LConfiguracao.CertificadoDigital.Senha;
    EdtCertificadoIdToken.Text := LConfiguracao.CertificadoDigital.IdToken;
    EdtCertificadoCsc.Text := LConfiguracao.CertificadoDigital.CscToken;
  finally
    LConfiguracao.Free;
  end;
end;

procedure TForm1.LimparLog1Click(Sender: TObject);
begin
  MemoLog.Lines.Clear;
end;

procedure TForm1.Log(AValue: string);
begin
  MemoLog.Lines.Add(AValue);
end;

initialization
  ReportMemoryLeaksOnShutdown := True;

end.
