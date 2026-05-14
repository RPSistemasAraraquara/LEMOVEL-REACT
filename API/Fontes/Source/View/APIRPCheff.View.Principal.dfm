object APIRPCheffViewPrincipal: TAPIRPCheffViewPrincipal
  Left = 0
  Top = 0
  Margins.Left = 6
  Margins.Top = 6
  Margins.Right = 6
  Margins.Bottom = 6
  BorderStyle = bsDialog
  Caption = 'RP Cheff Gar'#231'om API Vers'#227'o 14.0.0.0'
  ClientHeight = 750
  ClientWidth = 1258
  Color = clBtnFace
  TransparentColorValue = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -24
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 192
  TextHeight = 32
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 1258
    Height = 496
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Configura'#231#227'o Impressora'
      object GroupBox2: TGroupBox
        Left = 0
        Top = 0
        Width = 1242
        Height = 436
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Align = alClient
        Caption = 'Impressora'
        TabOrder = 0
        object Label5: TLabel
          Left = 32
          Top = 48
          Width = 83
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Modelo'
        end
        object Label6: TLabel
          Left = 32
          Top = 150
          Width = 54
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Porta'
        end
        object Label7: TLabel
          Left = 510
          Top = 48
          Width = 85
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Colunas'
        end
        object Label8: TLabel
          Left = 654
          Top = 48
          Width = 83
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Espa'#231'os'
        end
        object Label9: TLabel
          Left = 798
          Top = 48
          Width = 111
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Linha Pulo'
        end
        object Label10: TLabel
          Left = 510
          Top = 150
          Width = 116
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Pag.codigo'
          Color = clBtnFace
          ParentColor = False
        end
        object EdtModeloImpressora: TComboBox
          Left = 32
          Top = 86
          Width = 464
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          TabOrder = 0
        end
        object EdtImpressoraColunas: TEdit
          Left = 510
          Top = 86
          Width = 132
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          NumbersOnly = True
          TabOrder = 1
          Text = '32'
        end
        object EdtImpressoraEspacos: TEdit
          Left = 654
          Top = 86
          Width = 132
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          NumbersOnly = True
          TabOrder = 2
        end
        object EdtImpressoraLinhaPulo: TEdit
          Left = 798
          Top = 86
          Width = 132
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          NumbersOnly = True
          TabOrder = 3
        end
        object BtnTestarImpresssao: TButton
          Left = 62
          Top = 266
          Width = 230
          Height = 50
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Testar Impress'#227'o'
          TabOrder = 4
          OnClick = BtnTestarImpresssaoClick
        end
        object EdtPortaImpressora: TComboBox
          Left = 32
          Top = 188
          Width = 464
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          TabOrder = 5
        end
        object cbCortarPapel: TCheckBox
          Left = 974
          Top = 86
          Width = 170
          Height = 40
          Hint = 
            'Conecta a Porta Serial a cada comando enviado'#13#10'Desconecta da Por' +
            'ta Serial ap'#243's o envio'
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Cortar Papel'
          Checked = True
          State = cbChecked
          TabOrder = 6
        end
        object cbxPagCodigo: TComboBox
          Left = 510
          Top = 188
          Width = 234
          Height = 40
          Hint = 'Pagina de c'#243'digo usada pela Impressora POS'
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Style = csDropDownList
          TabOrder = 7
        end
      end
    end
    object TabConfiguracaoAPI: TTabSheet
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Configura'#231#227'o API'
      ImageIndex = 1
      object grpAPI: TGroupBox
        Left = 16
        Top = 16
        Width = 1186
        Height = 146
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'API'
        TabOrder = 0
        object Label1: TLabel
          Left = 32
          Top = 48
          Width = 95
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Porta API'
        end
        object edtAPIPort: TEdit
          Left = 32
          Top = 86
          Width = 178
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          NumbersOnly = True
          TabOrder = 0
        end
      end
      object GroupBox1: TGroupBox
        Left = 16
        Top = 174
        Width = 1202
        Height = 292
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'Database'
        TabOrder = 1
        object Label2: TLabel
          Left = 528
          Top = 48
          Width = 42
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Port'
        end
        object Label3: TLabel
          Left = 32
          Top = 160
          Width = 107
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Username'
        end
        object Label4: TLabel
          Left = 528
          Top = 160
          Width = 97
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Password'
        end
        object lbl3: TLabel
          Left = 32
          Top = 48
          Width = 49
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Host'
        end
        object lbl4: TLabel
          Left = 718
          Top = 48
          Width = 49
          Height = 32
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          Caption = 'Alias'
        end
        object edtSGBDPort: TEdit
          Left = 528
          Top = 86
          Width = 178
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          NumbersOnly = True
          TabOrder = 1
        end
        object edtSGBDUsername: TEdit
          Left = 32
          Top = 198
          Width = 484
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          TabOrder = 3
        end
        object edtSGBDPassword: TEdit
          Left = 528
          Top = 198
          Width = 466
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          PasswordChar = '*'
          TabOrder = 4
        end
        object edtSGBDHost: TEdit
          Left = 32
          Top = 86
          Width = 484
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          TabOrder = 0
        end
        object edtSGBDAlias: TEdit
          Left = 718
          Top = 86
          Width = 466
          Height = 40
          Margins.Left = 6
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 6
          TabOrder = 2
        end
      end
    end
    object TabNFe: TTabSheet
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'NFe'
      ImageIndex = 2
      TabVisible = False
      object LblConfiguracaoNFe: TLabel
        Left = 12
        Top = 18
        Width = 317
        Height = 45
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'NFCe n'#227'o configurada'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -32
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label11: TLabel
        Left = 18
        Top = 80
        Width = 320
        Height = 32
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'Arquivo XML de Configura'#231#227'o'
      end
      object EdtNFeArquivoConfiguracao: TEdit
        Left = 18
        Top = 118
        Width = 1152
        Height = 40
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        TabOrder = 0
      end
      object BtnNFeProcurarArquivoConfiguracao: TButton
        Left = 1174
        Top = 116
        Width = 66
        Height = 50
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = '...'
        TabOrder = 1
        OnClick = BtnNFeProcurarArquivoConfiguracaoClick
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 496
    Width = 1258
    Height = 254
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alBottom
    TabOrder = 1
    object lblSwagger: TLabel
      Left = 282
      Top = 112
      Width = 99
      Height = 36
      Cursor = crHandPoint
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Swagger'
      Color = clBtnFace
      DragCursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -26
      Font.Name = 'Segoe UI'
      Font.Style = [fsUnderline]
      ParentColor = False
      ParentFont = False
      Visible = False
      OnClick = lblSwaggerClick
    end
    object lblStatusService: TLabel
      Left = 20
      Top = 114
      Width = 156
      Height = 32
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Servi'#231'o Parado'
    end
    object btnInstallService: TButton
      Left = 524
      Top = 14
      Width = 228
      Height = 52
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Install Service'
      TabOrder = 0
      OnClick = btnInstallServiceClick
    end
    object btnStartServer: TButton
      Left = 20
      Top = 14
      Width = 228
      Height = 52
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Start Server'
      TabOrder = 1
      OnClick = btnStartServerClick
    end
    object btnStopServer: TButton
      Left = 280
      Top = 14
      Width = 230
      Height = 52
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Stop Server'
      TabOrder = 2
      OnClick = btnStopServerClick
    end
    object btnUninstallService: TButton
      Left = 766
      Top = 14
      Width = 230
      Height = 52
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Uninstall Service'
      TabOrder = 3
      OnClick = btnUninstallServiceClick
    end
    object btnTestarConexao: TButton
      Left = 1010
      Top = 78
      Width = 230
      Height = 52
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Testar Conex'#227'o'
      TabOrder = 4
      OnClick = btnTestarConexaoClick
    end
    object btnSalvarConfiguracao: TButton
      Left = 1010
      Top = 14
      Width = 230
      Height = 52
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Salvar'
      TabOrder = 5
      OnClick = btnSalvarConfiguracaoClick
    end
  end
  object FileDialog: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'Arquivo Xml'
        FileMask = '*.xml'
      end>
    Options = []
    Left = 416
    Top = 32
  end
end
