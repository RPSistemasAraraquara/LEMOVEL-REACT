unit APIRPCheff.View.Principal;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellAPI,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  GBWinService.Setup.Interfaces,
  RPNFe.Controller,
  RPNFe.Entity.Classes,
  APIRPCheff.Controller,
  APIRPCheff.Components.Connection,
  APIRPCheff.Controller.API,
  APIRPCheff.Resources,
  Vcl.Buttons,
  Vcl.ExtCtrls,
  Vcl.ComCtrls;

type
  TAPIRPCheffViewPrincipal = class(TForm)
    PageControl1                      : TPageControl;
    TabSheet1                         : TTabSheet;
    GroupBox2                         : TGroupBox;
    Label5                            : TLabel;
    Label6                            : TLabel;
    Label7                            : TLabel;
    Label8                            : TLabel;
    Label9                            : TLabel;
    EdtModeloImpressora               : TComboBox;
    EdtImpressoraColunas              : TEdit;
    EdtImpressoraEspacos              : TEdit;
    EdtImpressoraLinhaPulo            : TEdit;
    BtnTestarImpresssao               : TButton;
    EdtPortaImpressora                : TComboBox;
    TabConfiguracaoAPI                : TTabSheet;
    grpAPI                            : TGroupBox;
    Label1                            : TLabel;
    edtAPIPort                        : TEdit;
    GroupBox1                         : TGroupBox;
    Label2                            : TLabel;
    Label3                            : TLabel;
    Label4                            : TLabel;
    lbl3                              : TLabel;
    lbl4                              : TLabel;
    edtSGBDPort                       : TEdit;
    edtSGBDUsername                   : TEdit;
    edtSGBDPassword                   : TEdit;
    edtSGBDHost                       : TEdit;
    edtSGBDAlias                      : TEdit;
    Panel1                            : TPanel;
    lblSwagger                        : TLabel;
    btnInstallService                 : TButton;
    btnStartServer                    : TButton;
    btnStopServer                     : TButton;
    btnUninstallService               : TButton;
    btnTestarConexao                  : TButton;
    btnSalvarConfiguracao             : TButton;
    lblStatusService                  : TLabel;
    cbCortarPapel                     : TCheckBox;
    cbxPagCodigo                      : TComboBox;
    Label10                           : TLabel;
    TabNFe                            : TTabSheet;
    LblConfiguracaoNFe                : TLabel;
    EdtNFeArquivoConfiguracao         : TEdit;
    Label11                           : TLabel;
    BtnNFeProcurarArquivoConfiguracao : TButton;
    FileDialog                        : TFileOpenDialog;
    procedure btnInstallServiceClick(Sender: TObject);
    procedure btnSalvarConfiguracaoClick(Sender: TObject);
    procedure btnStartServerClick(Sender: TObject);
    procedure btnStopServerClick(Sender: TObject);
    procedure btnUninstallServiceClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lblSwaggerClick(Sender: TObject);
    procedure btnTestarConexaoClick(Sender: TObject);
    procedure BtnTestarImpresssaoClick(Sender: TObject);
    procedure BtnNFeProcurarArquivoConfiguracaoClick(Sender: TObject);
  private
    FController: TAPIRPCheffController;
    procedure SalvarConfiguracoes;
    procedure CarregarConfiguracoes;

    procedure MontarListaImpressoras;

    procedure GerenciarInformacoes;
    procedure CarregarCodigosPagina;
    procedure LerConfiguracaoNFe;
  public
    destructor Destroy; override;
  end;

var
  APIRPCheffViewPrincipal: TAPIRPCheffViewPrincipal;

implementation

{$R *.dfm}

{ TAPIRPCheffViewPrincipal }

procedure TAPIRPCheffViewPrincipal.btnInstallServiceClick(Sender: TObject);
begin
  InstallService;
  ShowMessage('servi'#231'o Instalado');
end;

procedure TAPIRPCheffViewPrincipal.BtnNFeProcurarArquivoConfiguracaoClick(Sender: TObject);
begin
  if FileDialog.Execute then
    EdtNFeArquivoConfiguracao.Text := FileDialog.FileName;
end;

procedure TAPIRPCheffViewPrincipal.btnSalvarConfiguracaoClick(Sender: TObject);
begin
  SalvarConfiguracoes;
  FController.Components.Impressora.Desativar;
// LerConfiguracaoNFe;
end;

procedure TAPIRPCheffViewPrincipal.btnStartServerClick(Sender: TObject);
begin
  try
    BtnStartServer.Enabled := False;
    SalvarConfiguracoes;
    StartServer;
  finally
    GerenciarInformacoes;
  end;
end;

procedure TAPIRPCheffViewPrincipal.btnStopServerClick(Sender: TObject);
begin
  try
    BtnStopServer.Enabled := False;
    StopServer;
  finally
    GerenciarInformacoes;
  end;
end;

procedure TAPIRPCheffViewPrincipal.btnTestarConexaoClick(Sender: TObject);
begin
  try
    SalvarConfiguracoes;
    CreateConnection;
    ShowMessage('Conectado com sucesso.');
  except
    on E: Exception do
      ShowMessage('n'#227'o foi poss'#237'vel conectar na base de dados: ' + E.Message);
  end;
end;

procedure TAPIRPCheffViewPrincipal.BtnTestarImpresssaoClick(Sender: TObject);
begin
  try
    FController.Components.Impressora.ImprimirTeste;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TAPIRPCheffViewPrincipal.btnUninstallServiceClick(Sender: TObject);
begin
  UninstallService;
  ShowMessage('servi'#231'o Desinstalado');
end;

procedure TAPIRPCheffViewPrincipal.CarregarConfiguracoes;
begin
  edtAPIPort.Text                := APP_RESOURCES.API_PORT.ToString;
  edtSGBDPort.Text               := APP_RESOURCES.DATABASE_PORT.ToString;
  edtSGBDHost.Text               := APP_RESOURCES.DATABASE_HOST;
  edtSGBDAlias.Text              := APP_RESOURCES.DATABASE_ALIAS;
  edtSGBDUsername.Text           := APP_RESOURCES.DATABASE_USERNAME;
  edtSGBDPassword.Text           := APP_RESOURCES.DATABASE_PASSWORD;
  EdtModeloImpressora.ItemIndex  := APP_RESOURCES.IMPRESSORA_MODELO;
  EdtPortaImpressora.Text        := APP_RESOURCES.IMPRESSORA_PORTA;
  EdtImpressoraColunas.Text      := APP_RESOURCES.IMPRESSORA_COLUNAS.ToString;
  EdtImpressoraEspacos.Text      := APP_RESOURCES.IMPRESSORA_ESPACOS.ToString;
  EdtImpressoraLinhaPulo.Text    := APP_RESOURCES.IMPRESSORA_LINHAS_PULO.ToString;
  EdtNFeArquivoConfiguracao.Text := APP_RESOURCES.NFE_XML_CONFIGURACAO;
  cbxPagCodigo.ItemIndex         := APP_RESOURCES.IMPRESSORA_PAGINA_CODE;
end;

procedure TAPIRPCheffViewPrincipal.CarregarCodigosPagina;
begin
  cbxPagCodigo.Items.Clear;
  FController.Components.Impressora.ListarCodigosPagina(cbxPagCodigo.Items);
  if (APP_RESOURCES.IMPRESSORA_PAGINA_CODE >= 0) and  (APP_RESOURCES.IMPRESSORA_PAGINA_CODE < cbxPagCodigo.Items.Count) then
      cbxPagCodigo.ItemIndex := APP_RESOURCES.IMPRESSORA_PAGINA_CODE
    else
      cbxPagCodigo.ItemIndex := 0;
end;

destructor TAPIRPCheffViewPrincipal.Destroy;
begin
  try
    if ServiceRunning then
      StopServer;
  except
  end;

  FreeAndNil(FController);
  inherited;
end;

procedure TAPIRPCheffViewPrincipal.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePage := TabConfiguracaoAPI;
  FController := TAPIRPCheffController.Create;
  CarregarCodigosPagina;
  MontarListaImpressoras;
  CarregarConfiguracoes;
  GerenciarInformacoes;
  //LerConfiguracaoNFe;
end;

procedure TAPIRPCheffViewPrincipal.GerenciarInformacoes;
begin
  btnStopServer.Enabled := ServiceRunning;
  btnStartServer.Enabled := not ServiceRunning;
  lblSwagger.Visible := ServiceRunning;
  lblSwagger.Caption := Format('http://localhost:%s/swagger/doc/html', [edtAPIPort.Text]);
  LblStatusService.Caption := 'servi'#231'o Parado';
  if ServiceRunning then
    lblStatusService.Caption := 'servi'#231'o em Execu'#231#227'o';
end;

procedure TAPIRPCheffViewPrincipal.lblSwaggerClick(Sender: TObject);
begin
  ShellExecute(HInstance, 'open', PChar(lblSwagger.Caption), nil, nil, SW_SHOW);
end;

procedure TAPIRPCheffViewPrincipal.LerConfiguracaoNFe;
var
  LConfiguracao: TRPNFeEntityConfiguracao;
begin
  try
    LConfiguracao := FController.Components.RPNFe.DAO.ConfiguracaoDAO.Carregar(APP_RESOURCES.NFE_XML_CONFIGURACAO);
    try
      LblConfiguracaoNFe.Font.Color := clWindowText;
      LblConfiguracaoNFe.Caption := 'NFCE Configurado em ambiente de Homologa'#231#227'o';
      if LConfiguracao.Producao then
      begin
        LblConfiguracaoNFe.Caption := 'NFCE Configurado em ambiente de PRODU'#199#195'O';
        LblConfiguracaoNFe.Font.Color := clRed;
      end;
    finally
      LConfiguracao.Free;
    end;
  except
    on E: Exception do
    begin
      E.Message := 'Erro ao carregar configura'#231#245'es da NFCe: ' + E.Message;
      LblConfiguracaoNFe.Caption := 'NFCe N'#227'o configurada';
      raise;
    end;
  end;
end;

procedure TAPIRPCheffViewPrincipal.MontarListaImpressoras;
var
  LPorta: string;
begin
  FController.Components.Impressora.ListarModelos(EdtModeloImpressora.Items);

  LPorta := Trim(APP_RESOURCES.IMPRESSORA_PORTA);
  EdtPortaImpressora.Items.Clear;
  if LPorta <> '' then
    EdtPortaImpressora.Items.Add(LPorta);
  if EdtPortaImpressora.Items.IndexOf('USB') < 0 then
    EdtPortaImpressora.Items.Add('USB');
  if EdtPortaImpressora.Items.IndexOf('NULL') < 0 then
    EdtPortaImpressora.Items.Add('NULL');

  if EdtModeloImpressora.Items.Count > 0 then
  begin
    if (APP_RESOURCES.IMPRESSORA_MODELO >= 0) and
       (APP_RESOURCES.IMPRESSORA_MODELO < EdtModeloImpressora.Items.Count) then
      EdtModeloImpressora.ItemIndex := APP_RESOURCES.IMPRESSORA_MODELO
    else
      EdtModeloImpressora.ItemIndex := 0;
  end;

  if LPorta <> '' then
    EdtPortaImpressora.Text := LPorta
  else
    EdtPortaImpressora.ItemIndex := EdtPortaImpressora.Items.IndexOf('USB');
end;

procedure TAPIRPCheffViewPrincipal.SalvarConfiguracoes;
begin
  APP_RESOURCES.API_PORT               := StrToIntDef(edtAPIPort.Text, 9000);
  APP_RESOURCES.DATABASE_PORT          := StrToIntDef(edtSGBDPort.Text, 9000);
  APP_RESOURCES.DATABASE_HOST          := edtSGBDHost.Text;
  APP_RESOURCES.DATABASE_ALIAS         := edtSGBDAlias.Text;
  APP_RESOURCES.DATABASE_USERNAME      := edtSGBDUsername.Text;
  APP_RESOURCES.DATABASE_PASSWORD      := edtSGBDPassword.Text;
  APP_RESOURCES.IMPRESSORA_MODELO      := EdtModeloImpressora.ItemIndex;
  APP_RESOURCES.IMPRESSORA_PORTA       := EdtPortaImpressora.Text;
  APP_RESOURCES.IMPRESSORA_COLUNAS     := StrToIntDef(EdtImpressoraColunas.Text, 32);
  APP_RESOURCES.IMPRESSORA_ESPACOS     := StrToIntDef(EdtImpressoraEspacos.Text, 0);
  APP_RESOURCES.IMPRESSORA_LINHAS_PULO := StrToIntDef(EdtImpressoraLinhaPulo.Text, 0);
  APP_RESOURCES.IMPRESSORA_PAGINA_CODE :=cbxPagCodigo.ItemIndex;
 // APP_RESOURCES.NFE_XML_CONFIGURACAO   := EdtNFeArquivoConfiguracao.Text;
  APP_RESOURCES.SaveConfig;
end;

end.
