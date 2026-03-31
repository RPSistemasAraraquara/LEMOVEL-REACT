object FormError: TFormError
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Erro'
  ClientHeight = 290
  ClientWidth = 463
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object memDetails: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 77
    Width = 454
    Height = 168
    Margins.Right = 6
    Align = alClient
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object pnlButton: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 251
    Width = 457
    Height = 36
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'pnlButton'
    ShowCaption = False
    TabOrder = 1
    object btnOK: TButton
      AlignWithMargins = True
      Left = 361
      Top = 3
      Width = 92
      Height = 29
      Align = alRight
      Caption = 'OK'
      ModalResult = 1
      TabOrder = 0
    end
  end
  object pnlTitulo: TPanel
    Left = 0
    Top = 0
    Width = 463
    Height = 74
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 2
    object imgError: TImage
      AlignWithMargins = True
      Left = 3
      Top = 7
      Width = 47
      Height = 60
      Margins.Top = 7
      Margins.Bottom = 7
      Align = alLeft
      Center = True
      Proportional = True
      Stretch = True
    end
    object lblError: TLabel
      AlignWithMargins = True
      Left = 59
      Top = 7
      Width = 397
      Height = 60
      Margins.Left = 5
      Margins.Top = 7
      Margins.Right = 7
      Margins.Bottom = 7
      Align = alClient
      AutoSize = False
      Caption = 'Ocorreu um erro inesperado.'#13#10
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      WordWrap = True
    end
  end
end
