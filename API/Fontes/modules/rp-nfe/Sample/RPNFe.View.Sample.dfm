object Form1: TForm1
  Left = 0
  Top = 0
  Margins.Left = 5
  Margins.Top = 5
  Margins.Right = 5
  Margins.Bottom = 5
  Caption = 'Exemplo RPNFe'
  ClientHeight = 1058
  ClientWidth = 1436
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -28
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 168
  TextHeight = 38
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1436
    Height = 72
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Exemplo RPNFe'
    TabOrder = 0
  end
  object pgcNFe: TPageControl
    Left = 0
    Top = 72
    Width = 1436
    Height = 986
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ActivePage = TabImpressao
    Align = alClient
    TabOrder = 1
    object TabEmissao: TTabSheet
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Emiss'#227'o'
      object Label1: TLabel
        Left = 28
        Top = 28
        Width = 107
        Height = 38
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Id Venda'
      end
      object Label18: TLabel
        Left = 28
        Top = 231
        Width = 140
        Height = 38
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Justificativa'
      end
      object Label19: TLabel
        Left = 754
        Top = 231
        Width = 119
        Height = 38
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Protocolo'
      end
      object Label20: TLabel
        Left = 28
        Top = 343
        Width = 133
        Height = 38
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Chave NFe'
      end
      object EdtIdVenda: TEdit
        Left = 28
        Top = 75
        Width = 240
        Height = 46
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        NumbersOnly = True
        TabOrder = 0
        Text = '44515'
      end
      object BtnEmissao: TButton
        Left = 28
        Top = 154
        Width = 240
        Height = 44
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Emitir'
        TabOrder = 1
        OnClick = BtnEmissaoClick
      end
      object EdtJustificativa: TEdit
        Left = 28
        Top = 271
        Width = 716
        Height = 46
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        TabOrder = 2
      end
      object EdtProtocolo: TEdit
        Left = 754
        Top = 271
        Width = 492
        Height = 46
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        TabOrder = 3
      end
      object EdtChaveNFe: TEdit
        Left = 28
        Top = 383
        Width = 716
        Height = 46
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        TabOrder = 4
      end
      object BtnCancelar: TButton
        Left = 28
        Top = 459
        Width = 240
        Height = 43
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Cancelar'
        TabOrder = 5
      end
      object BtnImpressao: TButton
        Left = 278
        Top = 459
        Width = 240
        Height = 43
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Impress'#227'o'
        TabOrder = 6
      end
    end
    object TabConfiguracao: TTabSheet
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Configura'#231#227'o'
      ImageIndex = 1
      object Label2: TLabel
        Left = 5
        Top = 21
        Width = 95
        Height = 38
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Modelo'
      end
      object Label3: TLabel
        Left = 5
        Top = 133
        Width = 102
        Height = 38
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Timeout'
      end
      object ChkProducao: TCheckBox
        Left = 5
        Top = 236
        Width = 170
        Height = 44
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Produ'#231#227'o'
        Enabled = False
        TabOrder = 0
      end
      object EdtModelo: TEdit
        Left = 5
        Top = 63
        Width = 240
        Height = 46
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        NumbersOnly = True
        ReadOnly = True
        TabOrder = 1
        Text = '65'
      end
      object EdtTimeout: TEdit
        Left = 5
        Top = 175
        Width = 240
        Height = 46
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        NumbersOnly = True
        ReadOnly = True
        TabOrder = 2
        Text = '0'
      end
      object GroupBox1: TGroupBox
        Left = 378
        Top = 5
        Width = 924
        Height = 296
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Respons'#225'vel T'#233'cnico'
        TabOrder = 3
        object Label4: TLabel
          Left = 28
          Top = 63
          Width = 97
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Contato'
        end
        object Label5: TLabel
          Left = 530
          Top = 63
          Width = 62
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'CNPJ'
        end
        object Label6: TLabel
          Left = 28
          Top = 175
          Width = 66
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Email'
        end
        object Label7: TLabel
          Left = 530
          Top = 175
          Width = 61
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Fone'
        end
        object EdtResponsavelContato: TEdit
          Left = 28
          Top = 103
          Width = 492
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 0
        end
        object EdtResponsavelCNPJ: TEdit
          Left = 530
          Top = 103
          Width = 368
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 1
        end
        object EdtResponsavelEmail: TEdit
          Left = 28
          Top = 215
          Width = 492
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 2
        end
        object EdtResponsavelTelefone: TEdit
          Left = 530
          Top = 215
          Width = 368
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 3
        end
      end
      object GroupBox2: TGroupBox
        Left = 5
        Top = 312
        Width = 1297
        Height = 477
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Paths'
        TabOrder = 4
        object Label8: TLabel
          Left = 28
          Top = 49
          Width = 171
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Path Schemas'
        end
        object Label9: TLabel
          Left = 28
          Top = 161
          Width = 112
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Path NFe'
        end
        object Label10: TLabel
          Left = 28
          Top = 264
          Width = 282
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Path NFe Conting'#234'ncia'
        end
        object Label11: TLabel
          Left = 28
          Top = 376
          Width = 107
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Path Log'
        end
        object EdtPathSchemas: TEdit
          Left = 28
          Top = 89
          Width = 1243
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 0
        end
        object EdtPathNFe: TEdit
          Left = 28
          Top = 201
          Width = 1243
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 1
        end
        object EdtPathNFeContingencia: TEdit
          Left = 28
          Top = 305
          Width = 1243
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 2
        end
        object EdtPathLog: TEdit
          Left = 28
          Top = 417
          Width = 1243
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 3
        end
      end
    end
    object TabCertificado: TTabSheet
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Certificado'
      ImageIndex = 3
      object GroupBox3: TGroupBox
        Left = 5
        Top = 18
        Width = 1297
        Height = 586
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Caption = 'Certificado'
        TabOrder = 0
        object Label12: TLabel
          Left = 28
          Top = 49
          Width = 151
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Arquivo PFX'
        end
        object Label13: TLabel
          Left = 28
          Top = 161
          Width = 76
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Senha'
        end
        object Label14: TLabel
          Left = 28
          Top = 292
          Width = 104
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Id Token'
        end
        object Label15: TLabel
          Left = 236
          Top = 292
          Width = 49
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'CSC'
        end
        object EdtCertificadoArquivoPFX: TEdit
          Left = 28
          Top = 89
          Width = 1243
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 0
        end
        object EdtCertificadoSenha: TEdit
          Left = 28
          Top = 201
          Width = 310
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 1
          Text = '123456'
        end
        object EdtCertificadoIdToken: TEdit
          Left = 28
          Top = 333
          Width = 198
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 2
          Text = '000001'
        end
        object EdtCertificadoCsc: TEdit
          Left = 236
          Top = 333
          Width = 1035
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ReadOnly = True
          TabOrder = 3
          Text = 'd4d8c4d5-3258-4025-b55a-52c46ac9b379'
        end
      end
    end
    object TabLog: TTabSheet
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Log'
      ImageIndex = 2
      object MemoLog: TMemo
        Left = 0
        Top = 0
        Width = 1428
        Height = 933
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object TabImpressao: TTabSheet
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Impress'#227'o'
      ImageIndex = 4
      object GroupBox4: TGroupBox
        Left = 0
        Top = 0
        Width = 1428
        Height = 933
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Align = alClient
        Caption = 'Impressora'
        TabOrder = 0
        object Label16: TLabel
          Left = 28
          Top = 42
          Width = 95
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Modelo'
        end
        object Label17: TLabel
          Left = 28
          Top = 145
          Width = 64
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Porta'
        end
        object Label21: TLabel
          Left = 446
          Top = 42
          Width = 98
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Colunas'
        end
        object Label22: TLabel
          Left = 684
          Top = 42
          Width = 97
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Espa'#231'os'
        end
        object Label23: TLabel
          Left = 852
          Top = 42
          Width = 129
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Linha Pulo'
        end
        object Label24: TLabel
          Left = 446
          Top = 145
          Width = 135
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Pag.codigo'
          Color = clBtnFace
          ParentColor = False
        end
        object Label25: TLabel
          Left = 684
          Top = 149
          Width = 107
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Id Venda'
        end
        object EdtModeloImpressora: TComboBox
          Left = 28
          Top = 81
          Width = 406
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          TabOrder = 0
        end
        object EdtImpressoraColunas: TEdit
          Left = 446
          Top = 81
          Width = 228
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          NumbersOnly = True
          TabOrder = 1
          Text = '48'
        end
        object EdtImpressoraEspacos: TEdit
          Left = 684
          Top = 81
          Width = 158
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          NumbersOnly = True
          TabOrder = 2
          Text = '30'
        end
        object EdtImpressoraLinhaPulo: TEdit
          Left = 852
          Top = 81
          Width = 186
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          NumbersOnly = True
          TabOrder = 3
          Text = '5'
        end
        object BtnTestarImpresssao: TButton
          Left = 28
          Top = 256
          Width = 240
          Height = 43
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Testar Impress'#227'o'
          TabOrder = 4
          OnClick = BtnTestarImpresssaoClick
        end
        object EdtPortaImpressora: TComboBox
          Left = 28
          Top = 187
          Width = 406
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          TabOrder = 5
          Text = 'COM4'
        end
        object cbCortarPapel: TCheckBox
          Left = 1062
          Top = 88
          Width = 228
          Height = 35
          Hint = 
            'Conecta a Porta Serial a cada comando enviado'#13#10'Desconecta da Por' +
            'ta Serial ap'#243's o envio'
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Cortar Papel'
          TabOrder = 6
        end
        object cbxPagCodigo: TComboBox
          Left = 446
          Top = 187
          Width = 228
          Height = 46
          Hint = 'Pagina de c'#243'digo usada pela Impressora POS'
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Style = csDropDownList
          TabOrder = 7
        end
        object MemoXml: TMemo
          Left = 2
          Top = 436
          Width = 1424
          Height = 495
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Align = alBottom
          Lines.Strings = (
            '<?xml version="1.0" encoding="UTF-8"?><nfeProc versao="4.00" '
            
              'xmlns="http://www.portalfiscal.inf.br/nfe"><NFe xmlns="http://ww' +
              'w.portalfiscal.inf.br/nfe"><infNFe '
            'Id="NFe35250922003472000130650010000015041009150491" '
            
              'versao="4.00"><ide><cUF>35</cUF><cNF>00915049</cNF><natOp>VENDA<' +
              '/natOp><mod>65</mod><seri'
            'e'
            '>1</serie><nNF>1504</nNF><dhEmi>2025-09-01T08:29:36-'
            
              '03:00</dhEmi><tpNF>1</tpNF><idDest>1</idDest><cMunFG>3503208</cM' +
              'unFG><tpImp>4</tpImp><tpEm'
            'i'
            
              's>1</tpEmis><cDV>1</cDV><tpAmb>2</tpAmb><finNFe>1</finNFe><indFi' +
              'nal>1</indFinal><indPres>1</i'
            'n'
            
              'dPres><procEmi>0</procEmi><verProc>ACBrNFe</verProc></ide><emit>' +
              '<CNPJ>22003472000130</CNPJ><'
            'x'
            
              'Nome>RAFAEL LUIZ G M MENDONCA</xNome><xFant>R P SISTEMAS</xFant>' +
              '<enderEmit><xLgr>AVENIDA '
            
              'ALBERTO SANTOS DUMONT</xLgr><nro>1121</nro><xCpl>CASA: 28;</xCpl' +
              '><xBairro>JARDIM '
            
              'ARARAQUARA</xBairro><cMun>3503208</cMun><xMun>ARARAQUARA</xMun><' +
              'UF>SP</UF><CEP>14807'
            '2'
            
              '97</CEP><cPais>1058</cPais><xPais>BRASIL</xPais><fone>1630104052' +
              '</fone></enderEmit><IE>18123246'
            '9'
            '114</IE><IM>ISENTO</IM><CRT>1</CRT></emi'
            
              't><det nItem="1"><prod><cProd>12</cProd><cEAN>SEM GTIN</cEAN><xP' +
              'rod>NOTA FISCAL EMITIDA EM '
            'AMBIENTE DE HOMOLOGACAO - SEM VALOR '
            
              'FISCAL</xProd><NCM>19023000</NCM><CFOP>5102</CFOP><uCom>UN</uCom' +
              '><qCom>1.0000</qCom'
            '>'
            '<vUnCom>50.0000000000</vUnCom><vProd>50.00</vProd><cEANTrib>SEM '
            
              'GTIN</cEANTrib><uTrib>UN</uTrib><qTrib>1.0000</qTrib><vUnTrib>50' +
              '.0000000000</vUnTrib><vOutro>5.00'
            
              '</vOutro><indTot>1</indTot></prod><imposto><vTotTrib>5.60</vTotT' +
              'rib><ICMS><ICMSSN102><orig>0</o'
            'ri'
            
              'g><CSOSN>102</CSOSN></ICMSSN102></ICMS><PIS><PISOutr><CST>49</CS' +
              'T><vBC>55.00</vBC><pPIS'
            '>'
            
              '0.0000</pPIS><vPIS>0.00</vPIS></PISOutr></PIS><COFINS><COFINSOut' +
              'r><CST>49</CST><vBC>55.00</vB'
            'C'
            
              '><pCOFINS>0.0000</pCOFINS><vCOFINS>0.00</vCOFINS></COFINSOutr></' +
              'COFINS></imposto></det><tot'
            'al'
            
              '><ICMSTot><vBC>0.00</vBC><vICMS>0.00</vICMS><vICMSDeson>0.00</vI' +
              'CMSDeson><vFCP>0.00</vFCP>'
            '<'
            
              'vBCST>0.00</vBCST><vST>0.00</vST><vFCPST>0.00</vFCPST><vFCPSTRet' +
              '>0.00</vFCPSTRet><vProd>50.00'
            '</'
            
              'vProd><vFrete>0.00</vFrete><vSeg>0.00</vSeg><vDesc>0.00</vDesc><' +
              'vII>0.00</vII><vIPI>0.00</vIPI'
            
              '><vIPIDevol>0.00</vIPIDevol><vPIS>0.00</vPIS><vCOFINS>0.00</vCOF' +
              'INS><vOutro>5.00</vOutro><vNF>55'
            '.'
            
              '00</vNF><vTotTrib>5.60</vTotTrib></ICMSTot></total><transp><modF' +
              'rete>9</modFrete></transp><pag><'
            'd'
            
              'etPag><tPag>01</tPag><vPag>55.00</vPag></detPag></pag><infAdic><' +
              'infCpl>Operador: ADM - Caixa: '
            '604;Federal R$ 2,10 Estadual R$ 3,50 Municipal R$ '
            
              '0,00;</infCpl></infAdic></infNFe><infNFeSupl><qrCode>https://www' +
              '.homologacao.nfce.fazenda.sp.gov.br/qrc'
            'o'
            'de?p=35250922003472000130650010000015041009150491|2|2|1|'
            
              '67460100CCA1E4571444799633DBAEFBD05F62D2</qrCode><urlChave>https' +
              '://www.homologacao.nfce.fazenda.'
            's'
            'p.gov.br/consulta</urlChave></infNFeSupl><Signature '
            
              'xmlns="http://www.w3.org/2000/09/xmldsig#"><SignedInfo><Canonica' +
              'lizationMethod '
            'Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-'
            
              '20010315"></CanonicalizationMethod><SignatureMethod Algorithm="h' +
              'ttp://www.w3.org/2000/09/xmldsig#rsa-'
            'sha1"></SignatureMethod><Reference '
            
              'URI="#NFe35250922003472000130650010000015041009150491"><Transfor' +
              'ms><Transform '
            'Algorithm="http://www.w3.org/2000/'
            
              '09/xmldsig#enveloped-signature"></Transform><Transform Algorithm' +
              '="http://www.w3.org/TR/2001/REC-xml-'
            'c14n-20010315"></Transform></Transforms><DigestMethod '
            
              'Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"></DigestMetho' +
              'd><DigestValue>3CRk8QH2X3RlV'
            
              '+47JXKMQ5Qs2uE=</DigestValue></Reference></SignedInfo><Signature' +
              'Value>VQTyiZQuH9A3AHaOYq4URH3'
            'E'
            
              'k2nUYflID/fb1V4X2eBcuvu8zJ65udLoqKA30K1UEftUkiyWp3kfYGNrWZ8QguOv' +
              'Hfkr2J2AY0ROwmKgHQN1EXurYxg'
            'Ut'
            
              'F70TgUcVNSunJtEYPVHUCHHHKB1IlLTdV8tPBmVCP02ATntcljCqr3NiMUjpl2mh' +
              'AgD4dOl6PnHNYpEwuvGkzxAz3RK3'
            
              'XKmdhYuMnjkWuq5sFfZ98sxGFV3oTUKAPq4ZlgK1sR1y+WfPY4DdxKJo7uSdrkme' +
              't2Y'
            
              '+6cZZPZcfuGVuiLyAd16Rh/I0dDOK2cBBR3Fm6YlLPCMzqih/RROxxcSVOqekCtK' +
              'PA==</SignatureValue><KeyInfo>'
            '<X509Data><X509Certificate>MIIH6zCCBdOgAwIBAgIKW/ORloiK'
            
              '+ZRWbzANBgkqhkiG9w0BAQsFADBbMQswCQYDVQQGEwJCUjEWMBQGA1UECwwNQUMg' +
              'U3luZ3VsYXJJRDETMB'
            'E'
            
              'GA1UECgwKSUNQLUJyYXNpbDEfMB0GA1UEAwwWQUMgU3luZ3VsYXJJRCBNdWx0aXB' +
              'sYTAeFw0yNTA3MjgxODU'
            '2'
            
              'MDRaFw0yNjA3MjgxODU2MDRaMIHNMQswCQYDVQQGEwJCUjETMBEGA1UECgwKSUNQ' +
              'LUJyYXNpbDEiMCAGA'
            '1'
            'UECwwZQ2VydGlmaWNhZG8gRGlnaXRhbCB'
            
              'QSiBBMTEZMBcGA1UECwwQVmlkZW9jb25mZXJlbmNpYTEXMBUGA1UECwwOMjc1OTU' +
              '1NDMwMDAxNTUxHzAd'
            'B'
            
              'gNVBAsMFkFDIFN5bmd1bGFySUQgTXVsdGlwbGExMDAuBgNVBAMMJ1JBRkFFTCBMV' +
              'UlaIEcgTSBNRU5ET05DQTo'
            'y'
            
              'MjAwMzQ3MjAwMDEzMDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPr3' +
              'utMpAq7Vo9z80/1OfIX3rR'
            'Y'
            
              'JxldkEBNlzFpBNpu0eUIuP0L6MyjVuhhy60v2KU7qenOptqOoLkgDwJjGmQ/QTIC' +
              'tAvxIdmzp1fDuqhGxWXg0wQG6/n'
            's'
            
              'uPYjpQx9ln69fgoy+rn/tU1NWQsnXnXKUbqGZNCwsJ4/yqyCVC5boAu73RPc0NuD' +
              'egYS3FUTfs+674P'
            
              '+rsSPzLqaxVT+ZI/DmpOJzIpW8iSx/I28drMqWKzdgrFG3GdtwQ1gm0dhJuNu8UD' +
              'RXZKqiwyB9S'
            '+9+b5/JItem4iLsIVgTVnXyzO8z/1ZFdkUdsth'
            
              '+Y//itcJNztoDq/N/u/bV/tOIx3J6tvECAwEAAaOCAzwwggM4MA4GA1UdDwEB/wQ' +
              'EAwIF4DAdBgNVHSUEFjAUBggr'
            'B'
            
              'gEFBQcDBAYIKwYBBQUHAwIwCQYDVR0TBAIwADAfBgNVHSMEGDAWgBST4f9+HeX15' +
              'E3hOWKLIWmV5q9yFjAdBg'
            'NVHQ4EFgQU2HFBYo5aKW1aJrFZT'
            
              '+yRusDCwggwfwYIKwYBBQUHAQEEczBxMG8GCCsGAQUFBzAChmNodHRwOi8vc3luZ' +
              '3VsYXJpZC5jb20uYnIvcmVw'
            'b'
            
              '3NpdG9yaW8vYWMtc3luZ3VsYXJpZC1tdWx0aXBsYS9jZXJ0aWZpY2Fkb3MvYWMtc' +
              '3luZ3VsYXJpZC1tdWx0aXBsYS5'
            
              'wN2IwgYIGA1UdIAR7MHkwdwYHYEwBAgGBBTBsMGoGCCsGAQUFBwIBFl5odHRwOi8' +
              'vc3luZ3VsYXJpZC5jb20uYnIv'
            'c'
            'mVwb3NpdG9yaW8'
            
              'vYWMtc3luZ3VsYXJpZC1tdWx0aXBsYS9kcGMvZHBjLWFjLXN5bmd1bGFySUQtbXV' +
              'sdGlwbGEucGRmMIHQBgNVHR'
            'E'
            
              'EgcgwgcWgLQYFYEwBAwKgJAQiUkFGQUVMIExVSVogR09NRVMgTUFUVE9TTyBNRU5' +
              'ET05DQaAZBgVgTAEDA6AQ'
            'B'
            
              'A4yMjAwMzQ3MjAwMDEzMKBCBgVgTAEDBKA5BDcxODEyMTk4MjIyNDA4MzgyODA3M' +
              'DAwMDAwMDAwMDAw'
            'M'
            
              'DAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwoBcGBWBMAQMHoA4EDDAwMDAwMDAwMDAwM' +
              'IEccHJvZ3J'
            'h'
            'bWFjYW9AcnBzaXN0ZW1hLmNvbS5icjCB4gYDVR0fBIHaMIHXMG'
            
              '+gbaBrhmlodHRwOi8vaWNwLWJyYXNpbC5zeW5ndWxhcmlkLmNvbS5ici9yZXBvc2' +
              'l0b3Jpby9hYy1zeW5ndWxhcml'
            'k'
            
              'LW11bHRpcGxhL2xjci9sY3ItYWMtc3luZ3VsYXJpZC1tdWx0aXBsYS5jcmwwZKBi' +
              'oGCGXmh0dHA6Ly9zeW5ndWxhcml'
            'k'
            
              'LmNvbS5ici9yZXBvc2l0b3Jpby9hYy1zeW5ndWxhcmlkLW11bHRpcGxhL2xjci9s' +
              'Y3ItYWMtc3luZ3VsYXJpZC1tdWx0aX'
            'B'
            'sYS5jcmwwDQYJKoZIhvcNAQELBQADggIBAD/NMX3DYmQeRwyb52ML4cAYGQ0WOa'
            '+BCprLHB3QQxJ2qbDZUNhLXjnQjs74c/HZqKKNKnpA'
            
              '+YEJAMsg5o6R5nXXLgCxHnSZjPCIaALXgIAsp70utlBLjuoIaY0m7xXGO62cyaku' +
              'XpZW6UoebLWscM5Hj0bsdm0TCeG'
            '5'
            
              '8NnZ52M4vBF0NyDuSKSw/AAJcxGSIbb0TSmp4HQ4SHKMLcC2Gj/iI9o6MIzBAG2y' +
              'TsUvZi8+qSrVeJ3VANrpNxvNb'
            
              '+a+2n1DFdj6nYxBTda00GiRsqosKpSi8ittpDvV5s5KX6mTanb8ohzDyyhXkOnkQ' +
              'utkdAWUE7IDmaYKvfL'
            
              'S6RbJMu54d/c76VDSVHe1KAwHUq5G4ASTgkK9W58bjV29bfAWwBSIZMekgZof7IT' +
              'ZkkF6KGQTMd'
            '+wivhkOFHjfFUu'
            
              '+bmqlC2K740p7pP5gWRXx81DOnBo0owZArYtIp3eqMdRZJAxHbk/tBPlEvdNCOEc' +
              'M1nut83T87DM0RO6A0aGWDS'
            
              '+dLEp0axQgmJyGYjKfbsel+ocWWkRtNNiGg2zxQPOfAXNNxPZCnJEHd6CWz4yaCx' +
              '+g'
            
              '+7ua1y1I4uHIX9yrVghW8CslcBW208RM4jSF9Tf40ES4tLFreARyePtMBcEqyaiw' +
              '7iZkp1OPoVTqV56nLlolhWWG5Qmc'
            'G'
            
              'vd74yC9i4J+9EP</X509Certificate></X509Data></KeyInfo></Signature' +
              '></NFe><protNFe '
            
              'versao="4.00"><infProt><tpAmb>2</tpAmb><verAplic>SP_NFCE_PL_009_' +
              'V400</verAplic><chNFe>352509220'
            '0'
            
              '3472000130650010000015041009150491</chNFe><dhRecbto>2025-09-01T0' +
              '8:31:06-'
            
              '03:00</dhRecbto><nProt>135250001732836</nProt><digVal>3CRk8QH2X3' +
              'RlV'
            
              '+47JXKMQ5Qs2uE=</digVal><cStat>100</cStat><xMotivo>Autorizado o ' +
              'uso da NF-'
            'e</xMotivo></infProt></protNFe></nfeProc>')
          TabOrder = 8
        end
        object EdtImpressaoIdVenda: TEdit
          Left = 684
          Top = 187
          Width = 158
          Height = 46
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          NumbersOnly = True
          TabOrder = 9
        end
        object BtnImpressaoImagem: TButton
          Left = 304
          Top = 256
          Width = 240
          Height = 43
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Caption = 'Impressao Imagem'
          TabOrder = 10
          OnClick = BtnImpressaoImagemClick
        end
      end
    end
  end
  object FDConnection1: TFDConnection
    Params.Strings = (
      'Database=RP'
      'User_Name=postgres'
      'Password=123'
      'DriverID=PG')
    LoginPrompt = False
    Left = 576
    Top = 8
  end
  object pmPopup: TPopupMenu
    Left = 496
    Top = 8
    object LimparLog1: TMenuItem
      Caption = 'Limpar Log'
      OnClick = LimparLog1Click
    end
  end
  object DataSetConfiguracao: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 608
    Top = 8
  end
  object PgConnection1: TPgConnection
    Username = 'postgres'
    Server = 'localhost'
    LoginPrompt = False
    Database = 'RP'
    Connected = True
    Left = 994
    Top = 42
    EncryptedPassword = 'CEFFCDFFCCFF'
  end
end
