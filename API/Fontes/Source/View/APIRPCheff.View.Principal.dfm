object APIRPCheffViewPrincipal: TAPIRPCheffViewPrincipal
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'RP Cheff Gar'#231'om API Vers'#227'o 18.0.0.4'
  ClientHeight = 537
  ClientWidth = 629
  Color = clBtnFace
  TransparentColorValue = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 629
    Height = 410
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Configura'#231#227'o Impressora'
      object GroupBox2: TGroupBox
        Left = 0
        Top = 0
        Width = 621
        Height = 380
        Align = alClient
        Caption = 'Impressora'
        TabOrder = 0
        object Label5: TLabel
          Left = 16
          Top = 24
          Width = 41
          Height = 15
          Caption = 'Modelo'
        end
        object Label6: TLabel
          Left = 16
          Top = 75
          Width = 28
          Height = 15
          Caption = 'Porta'
        end
        object Label7: TLabel
          Left = 255
          Top = 24
          Width = 43
          Height = 15
          Caption = 'Colunas'
        end
        object Label8: TLabel
          Left = 327
          Top = 24
          Width = 42
          Height = 15
          Caption = 'Espa'#231'os'
        end
        object Label9: TLabel
          Left = 399
          Top = 24
          Width = 56
          Height = 15
          Caption = 'Linha Pulo'
        end
        object Label10: TLabel
          Left = 255
          Top = 75
          Width = 60
          Height = 15
          Caption = 'Pag.codigo'
          Color = clBtnFace
          ParentColor = False
        end
        object EdtModeloImpressora: TComboBox
          Left = 16
          Top = 43
          Width = 232
          Height = 23
          TabOrder = 0
        end
        object EdtImpressoraColunas: TEdit
          Left = 255
          Top = 43
          Width = 66
          Height = 23
          NumbersOnly = True
          TabOrder = 1
          Text = '32'
        end
        object EdtImpressoraEspacos: TEdit
          Left = 327
          Top = 43
          Width = 66
          Height = 23
          NumbersOnly = True
          TabOrder = 2
        end
        object EdtImpressoraLinhaPulo: TEdit
          Left = 399
          Top = 43
          Width = 66
          Height = 23
          NumbersOnly = True
          TabOrder = 3
        end
        object BtnTestarImpresssao: TButton
          Left = 31
          Top = 133
          Width = 115
          Height = 25
          Caption = 'Testar Impress'#227'o'
          TabOrder = 4
          OnClick = BtnTestarImpresssaoClick
        end
        object EdtPortaImpressora: TComboBox
          Left = 16
          Top = 94
          Width = 232
          Height = 23
          TabOrder = 5
        end
        object cbCortarPapel: TCheckBox
          Left = 487
          Top = 43
          Width = 85
          Height = 20
          Hint = 
            'Conecta a Porta Serial a cada comando enviado'#13#10'Desconecta da Por' +
            'ta Serial ap'#243's o envio'
          Caption = 'Cortar Papel'
          Checked = True
          State = cbChecked
          TabOrder = 6
        end
        object cbxPagCodigo: TComboBox
          Left = 255
          Top = 94
          Width = 117
          Height = 23
          Hint = 'Pagina de c'#243'digo usada pela Impressora POS'
          Style = csDropDownList
          TabOrder = 7
        end
      end
    end
    object TabConfiguracaoAPI: TTabSheet
      Caption = 'Configura'#231#227'o API'
      ImageIndex = 1
      object grpAPI: TGroupBox
        Left = 8
        Top = 8
        Width = 593
        Height = 73
        Caption = 'API'
        TabOrder = 0
        object Label1: TLabel
          Left = 16
          Top = 24
          Width = 49
          Height = 15
          Caption = 'Porta API'
        end
        object edtAPIPort: TEdit
          Left = 16
          Top = 43
          Width = 89
          Height = 23
          NumbersOnly = True
          TabOrder = 0
        end
      end
      object GroupBox1: TGroupBox
        Left = 8
        Top = 87
        Width = 601
        Height = 146
        Caption = 'Database'
        TabOrder = 1
        object Label2: TLabel
          Left = 264
          Top = 24
          Width = 22
          Height = 15
          Caption = 'Port'
        end
        object Label3: TLabel
          Left = 16
          Top = 80
          Width = 53
          Height = 15
          Caption = 'Username'
        end
        object Label4: TLabel
          Left = 264
          Top = 80
          Width = 50
          Height = 15
          Caption = 'Password'
        end
        object lbl3: TLabel
          Left = 16
          Top = 24
          Width = 25
          Height = 15
          Caption = 'Host'
        end
        object lbl4: TLabel
          Left = 359
          Top = 24
          Width = 25
          Height = 15
          Caption = 'Alias'
        end
        object edtSGBDPort: TEdit
          Left = 264
          Top = 43
          Width = 89
          Height = 23
          NumbersOnly = True
          TabOrder = 1
        end
        object edtSGBDUsername: TEdit
          Left = 16
          Top = 99
          Width = 242
          Height = 23
          TabOrder = 3
        end
        object edtSGBDPassword: TEdit
          Left = 264
          Top = 99
          Width = 233
          Height = 23
          PasswordChar = '*'
          TabOrder = 4
        end
        object edtSGBDHost: TEdit
          Left = 16
          Top = 43
          Width = 242
          Height = 23
          TabOrder = 0
        end
        object edtSGBDAlias: TEdit
          Left = 359
          Top = 43
          Width = 233
          Height = 23
          TabOrder = 2
        end
      end
    end
    object TabNFe: TTabSheet
      Caption = 'NFC-e'
      ImageIndex = 2
      object LblConfiguracaoNFe: TLabel
        Left = 6
        Top = 9
        Width = 155
        Height = 21
        Caption = 'NFCe n'#227'o configurada'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object Label11: TLabel
        Left = 9
        Top = 40
        Width = 160
        Height = 15
        Caption = 'Arquivo XML de Configura'#231#227'o'
      end
      object Label12: TLabel
        Left = 9
        Top = 95
        Width = 163
        Height = 15
        Caption = 'Diret'#243'rio dos Schemas (NFC-e)'
      end
      object LblNFCeSobreposicao: TLabel
        Left = 9
        Top = 150
        Width = 311
        Height = 15
        Caption = 'Sobreposi'#231#227'o Fiscal NFC-e (opcional - vazio/0 usa o XML)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object LblNFCeIdCSC: TLabel
        Left = 9
        Top = 172
        Width = 36
        Height = 15
        Caption = 'ID CSC'
      end
      object LblNFCeCSC: TLabel
        Left = 199
        Top = 172
        Width = 22
        Height = 15
        Caption = 'CSC'
      end
      object LblNFCeAmbiente: TLabel
        Left = 459
        Top = 172
        Width = 52
        Height = 15
        Caption = 'Ambiente'
      end
      object LblNFCeSerie: TLabel
        Left = 9
        Top = 226
        Width = 25
        Height = 15
        Caption = 'S'#233'rie'
      end
      object LblNFCeNumero: TLabel
        Left = 99
        Top = 226
        Width = 99
        Height = 15
        Caption = 'N'#250'mero (pr'#243'ximo)'
      end
      object LblNFCeCertTipo: TLabel
        Left = 239
        Top = 226
        Width = 102
        Height = 15
        Caption = 'Tipo do Certificado'
      end
      object LblNFCeCertArquivo: TLabel
        Left = 9
        Top = 280
        Width = 145
        Height = 15
        Caption = 'Arquivo do Certificado (A1)'
      end
      object LblNFCeCertSenha: TLabel
        Left = 9
        Top = 334
        Width = 57
        Height = 15
        Caption = 'Senha (A1)'
      end
      object LblNFCeCertSerie: TLabel
        Left = 259
        Top = 334
        Width = 113
        Height = 15
        Caption = 'N'#250'mero de S'#233'rie (A3)'
      end
      object EdtNFeArquivoConfiguracao: TEdit
        Left = 9
        Top = 59
        Width = 576
        Height = 23
        TabOrder = 0
      end
      object BtnNFeProcurarArquivoConfiguracao: TButton
        Left = 587
        Top = 58
        Width = 33
        Height = 25
        Caption = '...'
        TabOrder = 1
        OnClick = BtnNFeProcurarArquivoConfiguracaoClick
      end
      object EdtNFeDiretorioSchemas: TEdit
        Left = 9
        Top = 114
        Width = 576
        Height = 23
        TabOrder = 2
      end
      object BtnNFeProcurarDiretorioSchemas: TButton
        Left = 587
        Top = 113
        Width = 33
        Height = 25
        Caption = '...'
        TabOrder = 3
        OnClick = BtnNFeProcurarDiretorioSchemasClick
      end
      object EdtNFCeIdCSC: TEdit
        Left = 9
        Top = 191
        Width = 180
        Height = 23
        TabOrder = 4
      end
      object EdtNFCeCSC: TEdit
        Left = 199
        Top = 191
        Width = 250
        Height = 23
        TabOrder = 5
      end
      object CbxNFCeAmbiente: TComboBox
        Left = 459
        Top = 191
        Width = 152
        Height = 23
        Style = csDropDownList
        TabOrder = 6
        Items.Strings = (
          'N'#227'o informado (usa XML)'
          'Homologa'#231#227'o'
          'Produ'#231#227'o')
      end
      object EdtNFCeSerie: TEdit
        Left = 9
        Top = 245
        Width = 80
        Height = 23
        NumbersOnly = True
        TabOrder = 7
      end
      object EdtNFCeNumero: TEdit
        Left = 99
        Top = 245
        Width = 130
        Height = 23
        NumbersOnly = True
        TabOrder = 8
      end
      object CbxNFCeCertTipo: TComboBox
        Left = 239
        Top = 245
        Width = 210
        Height = 23
        Style = csDropDownList
        TabOrder = 9
        Items.Strings = (
          'N'#227'o informado (usa XML)'
          'A1 - Arquivo (.pfx)'
          'A3 - Token/Cart'#227'o')
      end
      object EdtNFCeCertArquivo: TEdit
        Left = 9
        Top = 299
        Width = 540
        Height = 23
        TabOrder = 10
      end
      object BtnNFCeProcurarCertificado: TButton
        Left = 552
        Top = 298
        Width = 33
        Height = 25
        Caption = '...'
        TabOrder = 11
        OnClick = BtnNFCeProcurarCertificadoClick
      end
      object EdtNFCeCertSenha: TEdit
        Left = 9
        Top = 353
        Width = 240
        Height = 23
        PasswordChar = '*'
        TabOrder = 12
      end
      object EdtNFCeCertSerie: TEdit
        Left = 259
        Top = 353
        Width = 352
        Height = 23
        TabOrder = 13
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 410
    Width = 629
    Height = 127
    Align = alBottom
    TabOrder = 1
    object lblSwagger: TLabel
      Left = 141
      Top = 56
      Width = 51
      Height = 17
      Cursor = crHandPoint
      Caption = 'Swagger'
      Color = clBtnFace
      DragCursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsUnderline]
      ParentColor = False
      ParentFont = False
      Visible = False
      OnClick = lblSwaggerClick
    end
    object lblStatusService: TLabel
      Left = 10
      Top = 57
      Width = 78
      Height = 15
      Caption = 'Servi'#231'o Parado'
    end
    object btnInstallService: TButton
      Left = 262
      Top = 7
      Width = 114
      Height = 26
      Caption = 'Install Service'
      TabOrder = 0
      OnClick = btnInstallServiceClick
    end
    object btnStartServer: TButton
      Left = 10
      Top = 7
      Width = 114
      Height = 26
      Caption = 'Start Server'
      TabOrder = 1
      OnClick = btnStartServerClick
    end
    object btnStopServer: TButton
      Left = 140
      Top = 7
      Width = 115
      Height = 26
      Caption = 'Stop Server'
      TabOrder = 2
      OnClick = btnStopServerClick
    end
    object btnUninstallService: TButton
      Left = 383
      Top = 7
      Width = 115
      Height = 26
      Caption = 'Uninstall Service'
      TabOrder = 3
      OnClick = btnUninstallServiceClick
    end
    object btnTestarConexao: TButton
      Left = 505
      Top = 39
      Width = 115
      Height = 26
      Caption = 'Testar Conex'#227'o'
      TabOrder = 4
      OnClick = btnTestarConexaoClick
    end
    object btnSalvarConfiguracao: TButton
      Left = 505
      Top = 7
      Width = 115
      Height = 26
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
  object CertDialog: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'Certificado A1 (*.pfx)'
        FileMask = '*.pfx'
      end
      item
        DisplayName = 'Todos os arquivos (*.*)'
        FileMask = '*.*'
      end>
    Options = []
    Left = 416
    Top = 96
  end
end
