{===============================================================================
  ### REFORMA TRIBUTÁRIA - SISTEMA DE CÁLCULO IBS/CBS
  ---------------------------------------------------------------------------

  ## INFORMAÇÕES DO PRODUTO
  ---------------------------------------------------------------------------
  Nome:        Classe Reforma Tributária (IBS/CBS)
  Versão:      2.1
  Plataforma:  Pascal / ACBrNFe
  Projeto:     Classe Reforma tributaria - Auxiliar na emissão

  Desenvolvedor: Francisco Aurino
  ## E-mail: franciscoaurino@gmail.com
  ## WhatsApp: +5598988923379
  ## Site: https://rt.aurino.com.br

  ---------------------------------------------------------------------------

  ## DESCRIÇÃO
  ---------------------------------------------------------------------------
  Módulo auxiliar para gerenciamento, validação e cálculo dos impostos da
  Reforma Tributária (IBS e CBS) conforme Nota Técnica 2025.002.

  Implementa as fórmulas auxiliares para:
  • Base de Cálculo (vBC)
  • IBS Estadual (gIBSUF)
  • IBS Municipal (gIBSMun)
  • CBS Federal (gCBS)
  • Diferimento, Redução de Alíquota, Crédito Presumido
  • Tributação Monofásica, Imposto Seletivo
  • para Finalidade da NF-e => 1 - NF-e - Normal;

  Integração nativa com ACBrNFe (TDetCollectionItem).

  ---------------------------------------------------------------------------

  ## TERMOS DE LICENÇA E USO
  ---------------------------------------------------------------------------

  # DIREITOS CONCEDIDOS AO LICENCIADO:

    • Usar o código-fonte em projetos comerciais próprios
    • Modificar o código para adequação às necessidades internas
    • Compilar em aplicações distribuídas aos seus clientes finais
    • Utilizar em múltiplos projetos da mesma empresa/desenvolvedor adquirente
    • Criar cópias de backup para segurança

  # RESTRIÇÕES DE USO - O LICENCIADO NÃO PODE:

    • Revender o código-fonte de forma isolada sem autorização expressa
    • Distribuir em bibliotecas públicas, fóruns, GitHub ou repositórios
    • Remover avisos de copyright e créditos de autoria
    • Sublicenciar ou transferir a terceiros sem autorização
    • Realizar engenharia reversa para criar produtos concorrentes
    • Compartilhar credenciais de acesso ao suporte técnico

  ## PROPRIEDADE INTELECTUAL:

    Todos os direitos autorais pertencem ao DESENVOLVEDOR.
    Esta licença concede apenas DIREITO DE USO, não transferindo
    a propriedade do código-fonte.

  ---------------------------------------------------------------------------

  ## AVISOS LEGAIS E LIMITAÇÕES DE RESPONSABILIDADE
  ---------------------------------------------------------------------------

  ## LEIA COM ATENÇÃO ANTES DE USAR

  Este código implementa os cálculos conforme Nota Técnica 2025.002
  da Reforma Tributária Brasileira em caracter auxiliar. ENTRETANTO:

  # A responsabilidade tributária é SEMPRE do EMISSOR da NF-e
  # Validações finais DEVEM ser feitas por contador habilitado
  # Este software NÃO substitui consultoria tributária especializada
  # Testes homologatórios são OBRIGATÓRIOS antes de produção
  # Cada empresa DEVE validar com sua realidade fiscal específica
  # Cadastros corretos são ESSENCIAIS (CST, cClassTrib, alíquotas)

  # O DESENVOLVEDOR NÃO SE RESPONSABILIZA POR:

    • Perdas financeiras decorrentes de uso incorreto ou mal configurado
    • Multas, penalidades ou autuações fiscais aplicadas pela SEFAZ
    • Interpretações divergentes ou mudanças na legislação tributária
    • Alterações retroativas ou futuras nas regras fiscais
    • Incompatibilidades com outros componentes ou versões desatualizadas
    • Uso em ambientes não homologados ou sem testes adequados
    • Erros em dados de entrada (cadastros, parâmetros, configurações)
    • Indisponibilidade de serviços de terceiros (SEFAZ, ACBr, etc.)
    • Problemas causados por modificações realizadas pelo usuário e/ou desenvolvedor e afins.

  ## LIMITAÇÃO DE INDENIZAÇÃO:

    Em qualquer circunstância, a responsabilidade máxima do desenvolvedor
    está limitada ao valor efetivamente pago pela classe do produto.

  ---------------------------------------------------------------------------

  ### GARANTIAS
  ---------------------------------------------------------------------------

  # GARANTIAS FORNECIDAS:

    • Código livre de vírus e malwares conhecidos
    • Compilação com ACBrNFe atualizado
    • Estrutura XML conforme schema oficial da SEFAZ
    • Fórmulas de cálculo validadas com casos de teste em ambiente de homologação

  ---------------------------------------------------------------------------

  ## INFORMAÇÕES DE LICENCIAMENTO
  ---------------------------------------------------------------------------

  Este arquivo faz parte de um software proprietário licenciado.

  Copyright © 2025 Aurino. Todos os direitos reservados.

  A utilização deste código está sujeita aos termos de licença acordados
  no momento da aquisição. Uso não autorizado é proibido por lei.

  Para aquisição de atualição, suporte ou dúvidas:
  ## E-mail: franciscoaurino@gmail.com
  ## WhatsApp: +5598988923379
  ## Site: https://rt.aurino.com.br

  ---------------------------------------------------------------------------

  # AVISO FINAL
  ---------------------------------------------------------------------------

  AO UTILIZAR ESTE CÓDIGO, VOCÊ CONCORDA INTEGRALMENTE COM TODOS OS TERMOS
  E CONDIÇÕES ESTABELECIDOS NESTA LICENÇA.

  ---------------------------------------------------------------------------

  # HISTORICO DE REVISAO
  ---------------------------------------------------------------------------
   #1 27.11.2025 - melhorias no tratamento de arrendondamento e truncamento CalcularIBSUF
   #2 22.12.2025 - revisado e corrigido o perc. de red de alíquota CalcularIBSUF;
  ---------------------------------------------------------------------------

  Documento gerado automaticamente - Todos os direitos reservados

===============================================================================}



unit uFuncoesAdicionaisRT;

interface

uses
  SysUtils,
  IniFiles,
  StrUtils,
  Dialogs,
  Forms,
  Classes,
  Windows,
  Math,
  WinINet,
  Menus,

  {uses ACBrReg padrão - fatatoração 2025.06}
  acbrUtil, ACBrDFeReport,
  ACBrNFeNotasFiscais, ACBrNFeConfiguracoes,
  TypInfo, DateUtils, synacode, blcksock, FileCtrl,
  Printers, pcnAuxiliar, pcteConversaoCTe, pcnRetConsReciDFe,
  ACBrUtil.Base, ACBrUtil.FilesIO, ACBrUtil.DateTime, ACBrUtil.Strings,
  ACBrUtil.XMLHTML, ACBrNFe.Classes,
  ACBrDFe.Conversao, pcnConversao, pcnConversaoNFe,
  ACBrDFeConfiguracoes, ACBrDFeSSL, ACBrDFeOpenSSL, ACBrDFeUtil,
  Spin, OleCtrls, SHDocVw, ACBrMail, ACBrNFeDANFEClass,
  ACBrNFeDANFeRLClass, ACBrDFe,
  ShellAPI, XMLIntf, XMLDoc, zlib

  {uses ACBrReg padrão - fatatoração 2025.06}


   ;



    /// <summary>
    /// Registro para armazenar resultado de validação
    /// </summary>
    type
      TResultadoValidacao = record
        Valido: Boolean;               /// Combinação válida#
        Mensagem: string;              /// Mensagem de erro/sucesso
        RequerGComb: Boolean;          /// Requer grupo de combustível#
        CProdANPPadrao: string;        /// Código ANP padrão sugerido
        DescricaoPadrao: string;       /// Descrição padrão
        TipoCombustivel: string;       /// Tipo de combustível identificado
      end;



type
  /// <summary>
  /// Registro para armazenar dados de redução de alíquota
  /// Contém informações sobre redução aplicável a uma classificação tributária
  /// </summary>
  TDadosReducao = record
    Tem: Boolean;           /// Indica se há redução aplicável
    pReducaoIBS: Double;    /// Percentual de redução IBS (0-100)
    pReducaoCBS: Double;    /// Percentual de redução CBS (0-100)
    pRedutor: Double;       /// Percentual redutor para compras governamentais (0-100)
  end;

  /// <summary>
  /// Classe utilitária para gerenciamento de Reforma Tributária
  /// Agrupa funções de validação, consulta e cálculo de impostos
  /// Trabalha diretamente com componentes ACBrNFe
  /// </summary>
  TFuncoesAdicionaisRT = class
  private
    /// <summary>
    /// Obtém o caminho completo do arquivo INI de configuração
    /// Localiza na mesma pasta do executável com o mesmo nome
    /// </summary>
    class function CaminhoArquivoINI: string;

    /// <summary>
    /// Valida se valor está dentro de faixa aceitável
    /// </summary>
    class function ValidarValor(valor: Double; minimo: Double = 0; maximo: Double = 10000000000): Boolean;

    /// <summary>
    /// Valida se percentual está entre 0 e 100
    /// </summary>
    class function ValidarPercentual(percentual: Double): Boolean;

  public
    // ========================================
    // GERENCIAMENTO DE CONFIGURAÇÃO
    // ========================================


    class function SNToBool(const Valor: string): Boolean;
    /// <summary>
    /// Grava status de ativação da Reforma Tributária no arquivo INI
    /// </summary>
    class procedure GravarINI(const Ativa: Boolean);

    /// <summary>
    /// Lê status de ativação da Reforma Tributária do arquivo INI
    /// Se arquivo não existir, cria com RT ativa por padrão
    /// </summary>
    class function LerINI: Boolean;

    // ========================================
    // VALIDAÇÃO DE CST/CSOSN
    // ========================================

    /// <summary>
    /// Verifica se CST permite isenção de IBS da UF
    /// CSTs válidas: 102, 300, 400
    /// </summary>
    class function CSTPermiteIsencaoIBSUF(const CST: string): Boolean;

    /// <summary>
    /// Valida se CST e CSOSN permitem tributação de IBS
    /// CSTs válidas: 00, 20, 90
    /// CSOSNs válidas: 101, 900
    /// </summary>
    class function CSTPermiteIBS(const CST, CSOSN: string): Boolean;

    /// <summary>
    /// Verifica se IBS está em condição suspensiva (diferimento)
    /// </summary>
    class function IBSEmCondicaoSuspensiva(const CST, CSOSN: string): Boolean;

    /// <summary>
    /// Converte CST PIS/COFINS para código CBS equivalente
    /// </summary>
    class function PisCofinsToCBS(const CST: string): string;

    /// <summary>
    /// Converte CST/CSOSN para classificação tributária IBS
    /// </summary>
    class function CSTCSOSNToIBS(const CSTStr, CSOSNStr: string): string;

    // ========================================
    // VALIDAÇÃO DE CLASSIFICAÇÃO TRIBUTÁRIA
    // ========================================

    /// <summary>
    /// Verifica se classificação tributária permite tributação regular
    /// </summary>
    class function ClassTribPermiteTribRegular(const ClassTrib: string): Boolean;

    /// <summary>
    /// Verifica se classificação tributária permite diferimento e seu percentual de reducao
    /// </summary>
    class function CClassTribPermiteDiferimento(
      const cClassTrib: string;
      out pReducaoIBS, pReducaoCBS: Double): Boolean;

    /// <summary>
    /// Valida se CST permite diferimento de IBS
    /// CSTs válidas: 020, 030, 040
    /// </summary>
    class function CSTPermiteDiferimento(const CST: string): Boolean;

    /// <summary>
    /// Verifica se classificação permite redução de alíquota
    /// Prefixos permitidos: 011, 012, 013, 210, 222
    /// </summary>
    class function PermiteReducaoAliquota(const cClassTrib: string): Boolean;

    /// <summary>
    /// Avalia se classificação permite crédito presumido
    /// </summary>
    class function AvaliarCredPres(const cClass: string): Boolean;

    // ========================================
    // OBTENÇÃO DE ALÍQUOTAS
    // ========================================

    /// <summary>
    /// Obtém dados completos de redução de alíquota
    /// </summary>
    class function ObtainPercentualReducao(
      const cClassTrib: string;
      out DadosRed: TDadosReducao): Boolean;

    // ========================================
    // CÁLCULOS DE BASE E ALÍQUOTA
    // ========================================

    /// <summary>
    /// Calcula Base de Cálculo (vBC) conforme normativo da Reforma Tributária
    /// Trabalha diretamente com TDetCollectionItem do ACBrNFe
    ///
    /// FÓRMULA:
    /// vBC = vProd + vServ + vFrete + vSeg + vOutro + vII - vDesc
    ///     - vPis - vCofins - vICMS - vICMSUFDest - vFCP - vFCPUFDest
    ///     - vICMSMono - vISSQN + vIS
    /// </summary>
    class function CalcularBaseCalculo(const Produto: TDetCollectionItem): Double;

    ///com paramentros de uso
    class function CalcularBaseCalculowithParams(
      const Produto: TDetCollectionItem;
      const IncluirVProd: Boolean = True;
      const IncluirVFrete: Boolean = True;
      const IncluirVSeg: Boolean = True;
      const IncluirVOutro: Boolean = True;
      const IncluirVII: Boolean = True;
      const IncluirVIS: Boolean = True;
      const IncluirVDesc: Boolean = True;
      const IncluirVPIS: Boolean = True;
      const IncluirVCOFINS: Boolean = True;
      const IncluirVICMS: Boolean = True;
      const IncluirVICMSUFDest: Boolean = True;
      const IncluirVFCP: Boolean = True;
      const IncluirVFCPUFDest: Boolean = True;
      const IncluirVICMSMono: Boolean = True;
      const IncluirVISSQN: Boolean = True): Double;

     var

    /// <summary>
    /// Calcula alíquota efetiva com aplicação de redução e redutor
    ///
    /// SEM compra governamental:
    ///   pAliqEfet = pAliq × (1 - pRedAliq / 100)
    ///
    /// COM compra governamental:
    ///   pAliqEfet = pAliq × (1 - pRedAliq / 100) × (1 - pRedutor / 100)
    /// </summary>
    class function CalcularAliquotaEfetiva(
      pAliq: Double;
      pRedAliq: Double;
      CompraGov: Boolean = False;
      pRedutor: Double = 0): Double;

      /// <summary>
      /// Calcula e preenche o grupo gTribRegular (Tributação Regular)
      /// conforme NT 2025.002 - Reforma Tributária do Consumo
      ///
      /// ESTRUTURA XML GERADA:
      /// <gTribRegular>
      ///   <CSTReg>000</CSTReg>
      ///   <cClassTribReg>000001</cClassTribReg>
      ///   <pAliqEfetRegIBSUF>15.00</pAliqEfetRegIBSUF>
      ///   <vTribRegIBSUF>150.15</vTribRegIBSUF>
      ///   <pAliqEfetRegIBSMun>8.00</pAliqEfetRegIBSMun>
      ///   <vTribRegIBSMun>8.08</vTribRegIBSMun>
      ///   <pAliqEfetRegCBS>13.00</pAliqEfetRegCBS>
      ///   <vTribRegCBS>13.13</vTribRegCBS>
      /// </gTribRegular>
      ///
      /// RESPONSABILIDADES:
      /// - Valida CST e Classificação Tributária
      /// - Calcula alíquotas efetivas (com reduções aplicáveis)
      /// - Calcula valores de tributação (IBS UF, IBS Município, CBS)
      /// - Preenche estrutura gTribRegular do ACBrNFe
      /// - Integração com dados já calculados em gIBSUF, gIBSMun, gCBS
      /// - Tratamento robusto de erros e validações
      ///
      /// PARÂMETROS:
      /// @param Produto: TDetCollectionItem (item da NF-e do ACBrNFe)
      /// @param vBC: Double - Base de Cálculo já calculada
      /// @param CST: String - Código de Situação Tributária (ex: '0000', '0001')
      /// @param cClassTrib: String - Classificação Tributária (ex: '550001', '000001')
      /// @param vpIBSUF: Double - Alíquota IBS nível UF (%)
      /// @param vpIBSMun: Double - Alíquota IBS nível Município (%)
      /// @param vAliqCBS: Double - Alíquota CBS nível Federal (%)
      /// @param TemReducao: Boolean - Indica se há redução de alíquota
      /// @param vpRedAliqIBS: Double - Percentual de redução IBS (0-100)
      /// @param vpRedAliqCBS: Double - Percentual de redução CBS (0-100)
      /// @param CompraGov: Boolean - Indica se é compra governamental (padrão: False)
      /// @param pRedutor: Double - Percentual redutor para compras gov (padrão: 0)
      ///
      /// RETORNO:
      /// @return: Boolean - True se preenchimento bem-sucedido, False caso contrário
      ///
      /// FÓRMULAS UTILIZADAS:
      /// 1. Alíquota com redução:
      ///    pAliqEfet = pAliq × (1 - pRedução / 100) × (1 - pRedutor / 100)
      ///
      /// 2. Valor do Tributo:
      ///    vTrib = vBC × pAliqEfet / 100
      ///
      /// EXEMPLO DE USO:
      ///   var
      ///     Produto: TDetCollectionItem;
      ///     vBC, vpIBSUF, vpIBSMun, vAliqCBS: Double;
      ///     CST, cClassTrib: String;
      ///   begin
      ///     // Supondo que você já tem os valores calculados:
      ///     Produto := ACBrNFe1.NotasFiscais[0].Det.Items[0];
      ///     vBC := 1000.00;
      ///     vpIBSUF := 15.00;
      ///     vpIBSMun := 8.00;
      ///     vAliqCBS := 13.00;
      ///     CST := '0000';
      ///     cClassTrib := '000001';
      ///
      ///     if TFuncoesAdicionaisRT.CalcularGTribRegular(
      ///       Produto, vBC, CST, cClassTrib,
      ///       vpIBSUF, vpIBSMun, vAliqCBS,
      ///       False, 0, 0, False, 0) then
      ///     begin
      ///       ShowMessage('gTribRegular calculado com sucesso!');
      ///     end;
      ///   end;
      ///
      /// NOTAS IMPORTANTES:
      /// - A função preenche SOMENTE gTribRegular
      /// - Os valores de gIBSUF, gIBSMun e gCBS devem ser calculados ANTES
      /// - A função apenas REPLICA os valores já calculados para gTribRegular
      /// - Não realiza novos cálculos, apenas validação e preenchimento
      /// - gTribRegular é utilizado quando NÃO há diferimento ou suspensão
      ///
      /// REFERÊNCIA NORMATIVA:
      /// - NT 2025.002 - Reforma Tributária do Consumo (RTC)
      /// - Grupo UB17 (gTribRegular)
      /// - Campo UB49 (CSTReg)
      /// - Campo UB50 (cClassTribReg)
      /// - Campos UB51-UB56 (Alíquotas e Valores)
      ///
      /// </summary>
      class function  CalcularGTribRegular(
        const Produto: TDetCollectionItem;
        const vBC: Double;
        const CST, cClassTrib: string;
        const pAliqIBSUF, pAliqIBSMun, pAliqCBS: Double;
        const TemReducao: Boolean;
        const pRedAliqIBS, pRedAliqCBS: Double;
        const CompraGov: Boolean;
        const pRedutor: Double
      ): Boolean;      ///

    /// </summary>
    class function CalcularDiferimento(
      vBC: Double;
      pAliq: Double;
      pDif: Double): Double;

    /// <summary>
    /// Calcula crédito presumido de IBS
    /// FÓRMULA: vCredPres = vBC × pCredPres / 100
    /// </summary>
    class function CalcularCreditoPresumido(
      vBC: Double;
      pCredPres: Double): Double;

    /// <summary>
    /// Calcula IBS da UF com todas as deduções e validações
    /// </summary>
    class function CalcularIBSUF(
        vBC: Double;
        pIBSUF: Double;
        pAliqEfet: Double;
        vDif: Double;
        vDevTrib: Double;
        vCredPres: Double;
        const TemReducao: Boolean = False;
        const AliqReducao : Double = 0
      ): Double;

    /// <summary>
    /// Calcula IBS do Município com todas as deduções e validações
    /// </summary>
    class function CalcularIBSMunicipio(
      vBC: Double;
      pIBSMun: Double;
      pAliqEfet: Double;
      vDif: Double;
      vDevTrib: Double;
      vCredPres: Double): Double;

    /// <summary>
    /// Calcula CBS (Contribuição sobre Bens e Serviços)
    /// </summary>
    class function CalcularCBS(
        vBC: Double;
        pCBS: Double;
        pAliqEfet: Double;
        TemReducao: Boolean = False;
        pRedAliq: Double = 0
      ): Double;

    // ========================================
    // ARREDONDAMENTO CONFORME PADRÃO SEFAZ
    // ========================================

    /// <summary>
    /// Arredonda valor para 2 casas decimais conforme padrão SEFAZ
    /// </summary>
    class function ArredondaSefaz(valor: Double): Double;

    /// <summary>
    /// Arredonda valor para SEFAZ com aplicação de piso mínimo
    /// Se resultado for menor que 0.01 mas positivo, retorna 0.01
    /// </summary>
    class function ArredondaValorParaSefaz(valor: Double): Double;
    class function TruncaSefaz(const AValor: Double; Casas: Integer = 2): Double;
    class function ArredondaAliquota(valor: Double): Double;


    /// <summary>
    /// Calcula Imposto Seletivo (IS) conforme NT 2025.002
    /// FÓRMULA: vIS = vBC × pAliqIS / 100
    /// COM REDUÇÃO: vIS = vBC × (pAliqIS × (1 - pRedIS/100)) / 100
    /// </summary>
    class function CalcularImpustoSeletivo(
      vBC: Double;
      pAliqIS: Double;
      pRedAliq: Double = 0;
      uTrib: string = 'P';
      qTrib: Double = 0): Double;

    /// <summary>
    /// Calcula e preenche tributação monofásica de IBS/CBS
    /// Operação em que o tributo é cobrado uma única vez na cadeia
    /// FÓRMULA: vMono = vBC × adRem / 100
    /// </summary>
    class function CalcularGIBSCBSMono(
      const Produto: TDetCollectionItem;
      const vBC: Double;
      const adRemIBS: Double;
      const adRemCBS: Double;
      const cClassTrib: string;
      const qBCMono : Double = 0;
      const pDifIBS : Double = 0;
      const pDifCBS : Double = 0): Boolean;

    /// <summary>
    /// Calcula monofásica com retenção
    /// FÓRMULA: vRet = vBC × pAliqRet / 100
    /// </summary>
    class function CalcularMonoReten(
      vBC: Double;
      pAliqRet: Double;
      eTipo: string = 'IBS'): Double;

    // <summary>
    /// Calcula diferimento em operação monofásica
    /// FÓRMULA: vDif = (vBC × pAliqMono / 100) × pDifMono / 100
    /// </summary>
    class function CalcularMonoDiferimento(
      vBC: Double;
      pAliqMono: Double;
      pDifMono: Double): Double;

    /// <summary>
    /// Valida se operação é compra governamental
    /// Órgãos públicos têm alíquotas reduzidas
    /// </summary>
    class function ValidarOperacaoCompraGov(
      const CNPJ: string;
      const CRTCliente: string = ''): Boolean;

    /// <summary>
    /// Calcula tributação com redutor de compra governamental
    /// FÓRMULA: pAliqEfet = pAliq × (1 - pRedAliq/100) × (1 - pRedutor/100)
    /// </summary>
    class function CalcularGTribCompraGov(
      const Produto: TDetCollectionItem;
      const vBC: Double;
      const pAliq: Double;
      const pRedAliq: Double;
      const pRedutor: Double): Boolean;

    /// <summary>
    /// Calcula crédito presumido específico para IBS
    /// FÓRMULA: vCredPresIBS = vIBS × pCredPres / 100
    /// Válido apenas a partir de 2027
    /// </summary>
    class function CalcularCredPresIBS(
      vIBS: Double;
      pCredPresIBS: Double;
      IBSSuspenso: Boolean = False): Double;

    /// <summary>
    /// Calcula crédito presumido específico para CBS
    /// FÓRMULA: vCredPresCBS = vCBS × pCredPres / 100
    /// Válido apenas a partir de 2027
    /// </summary>
    class function CalcularCredPresCBS(
      vCBS: Double;
      pCredPresCBS: Double;
      CBSSuspenso: Boolean = False): Double;

    /// <summary>
    /// Calcula devolução de tributo (separado de diferimento)
    /// Aplicável em devoluções, cancelamentos
    /// FÓRMULA: vDevTrib = vTribOriginal × percentualDevolução / 100
    /// </summary>
    class function CalcularDevolucaoTributo(
      vTribOriginal: Double;
      pPercentualDev: Double = 100): Double;

    /// <summary>
    /// Calcula ajuste de competência tributária
    /// Para reconhecimento de receita em período diferente
    /// FÓRMULA: vAjuste = vOriginal - vReconhecido
    /// </summary>
    class function CalcularAjusteCompetencia(
      vOriginal: Double;
      vReconhecido: Double;
      eTipo: string = 'EST'): Double;

    /// <summary>
    /// Valida se classificação tributária permite Imposto Seletivo
    /// </summary>
    class function ValidarClassTribIS(const cClassTrib: string): Boolean;

    /// <summary>
    /// Obtém percentual de redução de Imposto Seletivo
    /// </summary>
    class function ObtainPercentualReducaoIS(
      const cClassTrib: string;
      out DadosRed: TDadosReducao): Boolean;

    /// <summary>
    /// Preenche automaticamente o grupo de combustível baseado em validação
    ///
    /// PARÂMETROS:
    /// @param Produto: TDetCollectionItem - Item da NFe
    /// @param Resultado: TResultadoValidacao - Resultado da validação prévia
    /// @param xProdAutomatico: String - Descrição do produto (para auto-detecção)
    ///
    /// RETORNO:
    /// @return: Boolean - True se preenchido com sucesso
    ///
    /// EXEMPLO DE USO:
    ///   var
    ///     Resultado: TResultadoValidacao;
    ///     Produto: TDetCollectionItem;
    ///   begin
    ///     Produto := ACBrNFe1.NotasFiscais[0].Det.Items[0];
    ///     if TFuncoesAdicionaisRT.ValidarCSTcClassTrib(
    ///       CSTIBSCBSToStr(Produto.Imposto.IBSCBS.CST),
    ///       Produto.Imposto.IBSCBS.cClassTrib, Resultado) then
    ///     begin
    ///       if Resultado.RequerGComb then
    ///       begin
    ///         TFuncoesAdicionaisRT.PreencherGrupoCombustivel(
    ///           Produto, Resultado, Produto.Prod.xProd);
    ///       end;
    ///     end;
    ///   end;
    ///
    /// </summary>
    class function PreencherGrupoCombustivel(
      const Produto: TDetCollectionItem;
      const Resultado: TResultadoValidacao;
      const xProdAutomatico: string = ''): Boolean;



  end;

implementation

{ TFuncoesAdicionaisRT }

// ============================================================
// GERENCIAMENTO DE CONFIGURAÇÃO
// ============================================================

class function TFuncoesAdicionaisRT.CaminhoArquivoINI: string;
var
  NomeExecutavel: string;
begin
  NomeExecutavel := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  Result := ExtractFilePath(ParamStr(0)) + NomeExecutavel + '.ini';
end;

class function TFuncoesAdicionaisRT.CClassTribPermiteDiferimento(
  const cClassTrib: string; out pReducaoIBS, pReducaoCBS: Double): Boolean;
begin
  // valores padrão
  pReducaoIBS := 0;
  pReducaoCBS := 0;
  Result := False;

  // compara como string (cClassTrib vem no formato '200003', '510001', etc.)
  if cClassTrib = '510001' then
  begin
    Result := True;
    pReducaoIBS := 0;   // conforme JSON https://dfe-portal.svrs.rs.gov.br/CFF/ClassificacaoTributaria
    pReducaoCBS := 0;   // conforme JSON https://dfe-portal.svrs.rs.gov.br/CFF/ClassificacaoTributaria
    Exit;
  end;

  if cClassTrib = '515001' then
  begin
    Result := True;
    pReducaoIBS := 60;  // conforme JSON https://dfe-portal.svrs.rs.gov.br/CFF/ClassificacaoTributaria
    pReducaoCBS := 60;  // conforme JSON https://dfe-portal.svrs.rs.gov.br/CFF/ClassificacaoTributaria
    Exit;
  end;

end;

class procedure TFuncoesAdicionaisRT.GravarINI(const Ativa: Boolean);
var
  Ini: TIniFile;
  Valor: string;
begin
  try
    ForceDirectories(ExtractFilePath(CaminhoArquivoINI));
    Ini := TIniFile.Create(CaminhoArquivoINI);
    try
      if Ativa then
        Valor := 'S'
      else
        Valor := 'N';
      Ini.WriteString('RT', 'Ativo', Valor);
    finally
      Ini.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao gravar configuração de Reforma Tributária: ' + E.Message);
  end;
end;

class function TFuncoesAdicionaisRT.LerINI: Boolean;
var
  Ini: TIniFile;
  Valor: string;
begin
  Result := False;

  try
    if not FileExists(CaminhoArquivoINI) then
      GravarINI(False);

    Ini := TIniFile.Create(CaminhoArquivoINI);
    try
      if not Ini.SectionExists('RT') then
        GravarINI(True);

      Valor := Ini.ReadString('RT', 'Ativo', 'N');
      Result := SameText(Valor, 'S');
    finally
      Ini.Free;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao ler configuração de Reforma Tributária: ' + E.Message);
      Result := False;
    end;
  end;
end;


// ============================================================
// VALIDAÇÃO AUXILIAR
// ============================================================

class function TFuncoesAdicionaisRT.ValidarValor(valor: Double; minimo: Double = 0; maximo: Double = 10000000000): Boolean;
begin
  Result := (valor >= minimo) and (valor <= maximo) and not IsNan(valor);
end;

{$REGION '====== 11: VALIDAÇÃO - REDUÇÃO IS ======'}

/// <summary>
/// Valida se classificação tributária permite Imposto Seletivo
/// </summary>
class function TFuncoesAdicionaisRT.ValidarClassTribIS(const cClassTrib: string): Boolean;
var
  Prefixo: string;
begin
  Result := False;

  if Length(Trim(cClassTrib)) < 3 then
    Exit;

  Prefixo := Copy(cClassTrib, 1, 3);

  { Prefixos que permitem IS }
  Result :=
    (Prefixo = '550') or { Combustíveis }
    (Prefixo = '620') or { Bebidas e tabaco }
    (Prefixo = '800') or
    (Prefixo = '810') or
    (Prefixo = '820') or
    (Prefixo = '830');
end;

{$ENDREGION}

{$REGION '====== 05: COMPRA GOVERNAMENTAL - VALIDAÇÃO ======'}
class function TFuncoesAdicionaisRT.ValidarOperacaoCompraGov(const CNPJ,
  CRTCliente: string): Boolean;
begin
  Result := False;

    try
      { Governo Federal }
      if Pos('00000000000191', CNPJ) = 1 then
      begin
        Result := True;
        Exit;
      end;

      { Padrão órgão público }
      if RightStr(CNPJ, 4) = '0001' then
      begin
        Result := True;
        Exit;
      end;

      { ISSQN - Pode ser órgão público }
      if CRTCliente = '3' then
      begin
        Result := True;
        Exit;
      end;

    except
      Result := False;
    end;
end;
{$ENDREGION}


class function TFuncoesAdicionaisRT.ValidarPercentual(percentual: Double): Boolean;
begin
  Result := (percentual >= 0) and (percentual <= 100) and not IsNan(percentual);
end;

// ============================================================
// VALIDAÇÃO DE CST/CSOSN
// ============================================================

class function TFuncoesAdicionaisRT.CSTPermiteIsencaoIBSUF(const CST: string): Boolean;
begin
  Result := (CST = '102') or (CST = '300') or (CST = '400');
end;

class function TFuncoesAdicionaisRT.CSTPermiteIBS(const CST, CSOSN: string): Boolean;
const
  cstValidados: array[0..2] of string = ('00', '20', '90');
  csosnValidados: array[0..1] of string = ('101', '900');
var
  i: Integer;
begin
  Result := False;

  { Valida CST }
  for i := 0 to High(cstValidados) do
    if CST = cstValidados[i] then
    begin
      Result := True;
      Exit;
    end;

  { Valida CSOSN }
  for i := 0 to High(csosnValidados) do
    if CSOSN = csosnValidados[i] then
    begin
      Result := True;
      Exit;
    end;
end;

class function TFuncoesAdicionaisRT.IBSEmCondicaoSuspensiva(const CST, CSOSN: string): Boolean;
begin
  Result := (CST = '30') or (CST = '40') or (CST = '41') or (CST = '50') or
            (CST = '60') or (CST = '70') or (CST = '90') or
            (CSOSN = '102') or (CSOSN = '300') or (CSOSN = '400') or
            (CSOSN = '500') or (CSOSN = '900');
end;

class function TFuncoesAdicionaisRT.PisCofinsToCBS(const CST: string): string;
var
  Cod: Integer;
begin
  Cod := StrToIntDef(CST, -1);

  case Cod of
    1, 50..66:    Result := '000001';
    2:            Result := '011001';
    3:            Result := '620001';
    4:            Result := '620005';
    5, 30, 70:    Result := '620002';
    6:            Result := '200001';
    7:            Result := '400001';
    8, 71..75:    Result := '410001';
    9:            Result := '550001';
    49, 98, 99:   Result := '900001';
  else
    Result := '900001';
  end;
end;

class function TFuncoesAdicionaisRT.PreencherGrupoCombustivel(
  const Produto: TDetCollectionItem; const Resultado: TResultadoValidacao;
  const xProdAutomatico: string): Boolean;
var
  cProdANP: string;
  xDesc: string;
begin
  Result := False;

  try
    { Validar se requer grupo de combustível }
    if not Resultado.RequerGComb then
    begin
      ShowMessage('Este produto não requer grupo de combustível');
      Exit;
    end;

    { Validar se Produto está inicializado }
    if not Assigned(Produto) then
    begin
      ShowMessage('Erro: Produto não inicializado em PreencherGrupoCombustivel');
      Exit;
    end;

    if not Assigned(Produto.Prod.comb) then
    begin
      ShowMessage('Erro: gComb não inicializado');
      Exit;
    end;

    {$REGION '====== AUTO-DETECÇÃO DE COMBUSTÍVEL ======'}
    { Tentar identificar o tipo de combustível pela descrição }
    cProdANP := Resultado.CProdANPPadrao;
    xDesc := Resultado.DescricaoPadrao;

    if xProdAutomatico <> '' then
    begin
      { Auto-detectar tipo de combustível }
      if Pos('GASOLINA', UpperCase(xProdAutomatico)) > 0 then
      begin
        if Pos('PREMIUM', UpperCase(xProdAutomatico)) > 0 then
          cProdANP := '001001002'  { Gasolina Premium }
        else
          cProdANP := '001001001'; { Gasolina Comum }
        xDesc := 'GASOLINA';
      end
      else if Pos('DIESEL', UpperCase(xProdAutomatico)) > 0 then
      begin
        if Pos('S-10', UpperCase(xProdAutomatico)) > 0 then
          cProdANP := '001002002'  { Diesel S-10 }
        else if Pos('S-500', UpperCase(xProdAutomatico)) > 0 then
          cProdANP := '001002003'  { Diesel S-500 }
        else
          cProdANP := '001002001'; { Diesel Comum }
        xDesc := 'DIESEL';
      end
      else if Pos('ETANOL', UpperCase(xProdAutomatico)) > 0 then
      begin
        cProdANP := '001003001'; { Etanol }
        xDesc := 'ETANOL';
      end
      else if Pos('GNV', UpperCase(xProdAutomatico)) > 0 then
      begin
        cProdANP := '001004001'; { GNV }
        xDesc := 'GNV';
      end
      else if Pos('BIODIESEL', UpperCase(xProdAutomatico)) > 0 then
      begin
        cProdANP := '001005001'; { Biodiesel }
        xDesc := 'BIODIESEL';
      end
      else if Pos('CERVEJA', UpperCase(xProdAutomatico)) > 0 then
      begin
        cProdANP := '001001001'; { Genérico }
        xDesc := 'CERVEJA';
      end
      else if Pos('VINHO', UpperCase(xProdAutomatico)) > 0 then
      begin
        cProdANP := '001001001'; { Genérico }
        xDesc := 'VINHO';
      end
      else if Pos('CIGARRO', UpperCase(xProdAutomatico)) > 0 then
      begin
        cProdANP := '001001001'; { Genérico }
        xDesc := 'CIGARRO';
      end;
    end;
    {$ENDREGION}

    {$REGION '====== PREENCHER gComb ======'}
    with Produto.Prod.comb do
    begin
      cProdANP := cProdANP;
      xDesc := xDesc;
      { OPCIONAL - se houver informação de CIDE (Contribuição de Intervenção) }
      { vCIDE := 0.00; }
    end;

    Result := True;
    {$ENDREGION}

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao preencher grupo de combustível: ' + E.Message);
      Result := False;
    end;
  end;
end;

class function TFuncoesAdicionaisRT.SNToBool(const Valor: string): Boolean;
begin
   Result := SameText(Valor, 'S');
end;

{$ENDREGION}

class function TFuncoesAdicionaisRT.CSTCSOSNToIBS(const CSTStr, CSOSNStr: string): string;
var
  CST, CSOSN: Integer;
begin
  Result := '000001';

  try
    CST := StrToIntDef(CSTStr, -1);
    CSOSN := StrToIntDef(CSOSNStr, -1);

    if CSOSN >= 0 then
    begin
      case CSOSN of
        101, 102: Result := '000001';
        103:      Result := '400001';
        201..203: Result := '620002';
        300, 400: Result := '410001';
        500:      Result := '620005';
        900:      Result := '900001';
      else
        Result := '000001';
      end;
    end
    else if CST >= 0 then
    begin
      case CST of
        0:   Result := '000001';
        10:  Result := '620001';
        20:  Result := '210001';
        30, 70: Result := '620002';
        40:  Result := '400001';
        41:  Result := '410001';
        50:  Result := '550001';
        51:  Result := '510001';
        60:  Result := '620005';
        90:  Result := '900001';
      else
        Result := '900001';
      end;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Erro em CSTCSOSNToIBS: ' + E.Message);
      Result := '900001';
    end;
  end;
end;

// ============================================================
// VALIDAÇÃO DE CLASSIFICAÇÃO TRIBUTÁRIA
// ============================================================

class function TFuncoesAdicionaisRT.ClassTribPermiteTribRegular(
  const ClassTrib: string): Boolean;
begin
  Result :=
    (ClassTrib = '200022') or
    (ClassTrib = '200024') or
    (ClassTrib = '550001') or
    (ClassTrib = '550002') or
    (ClassTrib = '550003') or
    (ClassTrib = '550004') or
    (ClassTrib = '550005') or
    (ClassTrib = '550006') or
    (ClassTrib = '550007') or
    (ClassTrib = '550008') or
    (ClassTrib = '550009') or
    (ClassTrib = '550010') or
    (ClassTrib = '550011') or
    (ClassTrib = '550012') or
    (ClassTrib = '550013') or
    (ClassTrib = '550014') or
    (ClassTrib = '550015') or
    (ClassTrib = '550016') or
    (ClassTrib = '550017');
end;


class function TFuncoesAdicionaisRT.CSTPermiteDiferimento(const CST: string): Boolean;
begin
  Result := (CST = '020') or (CST = '030') or (CST = '040');
end;

class function TFuncoesAdicionaisRT.PermiteReducaoAliquota(const cClassTrib: string): Boolean;
var
  Prefixo: string;
begin
  Result := False;

  if Length(Trim(cClassTrib)) < 3 then
    Exit;

  Prefixo := Copy(cClassTrib, 1, 3);

  // Prefixos que possuem redução de alíquota conforme arquivo JSON
  Result :=
    (Prefixo = '011') or
    (Prefixo = '012') or
    (Prefixo = '013') or
    (Prefixo = '200') or
    (Prefixo = '210') or
    (Prefixo = '211') or
    (Prefixo = '212') or
    (Prefixo = '213') or
    (Prefixo = '214') or
    (Prefixo = '215') or
    (Prefixo = '220') or
    (Prefixo = '221') or
    (Prefixo = '222') or
    (Prefixo = '223') or
    (Prefixo = '224') or
    (Prefixo = '225') or
    (Prefixo = '226') or
    (Prefixo = '227') or
    (Prefixo = '228') or
    (Prefixo = '229') or
    (Prefixo = '510') or
    (Prefixo = '515') or
    (Prefixo = '550') or
    (Prefixo = '620') or
    (Prefixo = '800') or
    (Prefixo = '810') or
    (Prefixo = '811') or
    (Prefixo = '820') or
    (Prefixo = '830');
end;


class function TFuncoesAdicionaisRT.AvaliarCredPres(const cClass: string): Boolean;
const
  cClassComCredPres: array[0..25] of string = (
    '410014', '410015', '410016', '410017',
    '200022', '200024',
    '550001', '550002', '550003', '550004', '550005', '550006',
    '550007', '550008', '550009', '550010', '550011', '550012',
    '550013', '550014', '550015', '550016', '550017', '550018',
    '550019', '550020'
  );
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(cClassComCredPres) do
    if cClass = cClassComCredPres[i] then
    begin
      Result := True;
      Exit;
    end;
end;



class function TFuncoesAdicionaisRT.ObtainPercentualReducao(
  const cClassTrib: string;
  out DadosRed: TDadosReducao): Boolean;
begin
  ZeroMemory(@DadosRed, SizeOf(DadosRed));
  DadosRed.Tem := False;
  DadosRed.pReducaoIBS := 0;
  DadosRed.pReducaoCBS := 0;
  DadosRed.pRedutor := 0;

  {===========================}
  { GRUPO 011 - Redução 60%  }
  {===========================}
  if Copy(cClassTrib, 1, 3) = '011' then
  begin
    DadosRed.Tem := True;
    DadosRed.pReducaoIBS := 60.0;
    DadosRed.pReducaoCBS := 60.0;
  end

  {============================================================}
  { GRUPO 012 e 200001..200024 - Redução 100% (Isenção total) }
  {============================================================}
  else if (Copy(cClassTrib, 1, 3) = '012') or
          ((Copy(cClassTrib, 1, 3) = '200') and
           (cClassTrib >= '200001') and
           (cClassTrib <= '200024')) then
  begin
    DadosRed.Tem := True;
    DadosRed.pReducaoIBS := 100.0;
    DadosRed.pReducaoCBS := 100.0;
  end

  {==============================}
  { GRUPO 013 - Reduções variadas }
  {==============================}
  else if cClassTrib = '013001' then
  begin
    DadosRed.Tem := True;
    DadosRed.pReducaoIBS := 30.0;
    DadosRed.pReducaoCBS := 30.0;
  end
  else if cClassTrib = '013002' then
  begin
    DadosRed.Tem := True;
    DadosRed.pReducaoIBS := 50.0;
    DadosRed.pReducaoCBS := 50.0;
  end

  {============================================================}
  { GRUPO 200 - Reduções específicas conforme JSON             }
  {============================================================}
  else if Copy(cClassTrib, 1, 3) = '200' then
  begin
    // Redução 100%: 200001..200024
    if (cClassTrib >= '200001') and (cClassTrib <= '200024') then
    begin
      DadosRed.Tem := True;
      DadosRed.pReducaoIBS := 100.0;
      DadosRed.pReducaoCBS := 100.0;
    end
    // Redução 60%: 200025..200045
    else if (cClassTrib >= '200025') and (cClassTrib <= '200045') then
    begin
      DadosRed.Tem := True;
      DadosRed.pReducaoIBS := 60.0;
      DadosRed.pReducaoCBS := 60.0;
    end
    // 80%: 200046
    else if cClassTrib = '200046' then
    begin
      DadosRed.Tem := True;
      DadosRed.pReducaoIBS := 80.0;
      DadosRed.pReducaoCBS := 80.0;
    end
    // 40%: 200047..200051
    else if (cClassTrib >= '200047') and (cClassTrib <= '200051') then
    begin
      DadosRed.Tem := True;
      DadosRed.pReducaoIBS := 40.0;
      DadosRed.pReducaoCBS := 40.0;
    end
    // 30%: 200052
    else if cClassTrib = '200052' then
    begin
      DadosRed.Tem := True;
      DadosRed.pReducaoIBS := 30.0;
      DadosRed.pReducaoCBS := 30.0;
    end
  end

  {============================================================}
  { GRUPO 515 - Diferimento com redução 0%                   }
  {============================================================}
  else if cClassTrib = '515001' then
  begin
    DadosRed.Tem := True;
    DadosRed.pReducaoIBS := 0.60;
    DadosRed.pReducaoCBS := 0.60;
  end;

  Result := DadosRed.Tem;
end;


/// <summary>
/// Obtém percentual de redução de Imposto Seletivo
/// </summary>
class function TFuncoesAdicionaisRT.ObtainPercentualReducaoIS(
  const cClassTrib: string; out DadosRed: TDadosReducao): Boolean;
begin

  ZeroMemory(@DadosRed, SizeOf(DadosRed));
  DadosRed.Tem := False;
  DadosRed.pReducaoIBS := 0;
  DadosRed.pReducaoCBS := 0;
  DadosRed.pRedutor := 0;

  { COMBUSTÍVEIS - GRUPO 550 }
  if Copy(cClassTrib, 1, 3) = '550' then
  begin
    DadosRed.Tem := False;
    DadosRed.pReducaoIBS := 0;
  end

  { BEBIDAS E TABACO - GRUPO 620 }
  else if Copy(cClassTrib, 1, 3) = '620' then
  begin
    { Bebidas }
    if Copy(cClassTrib, 1, 6) = '620001' then
    begin
      DadosRed.Tem := True;
      DadosRed.pReducaoIBS := 10;
    end
    { Tabaco }
    else if Copy(cClassTrib, 1, 6) = '620005' then
    begin
      DadosRed.Tem := False;
      DadosRed.pReducaoIBS := 0;
    end;
  end;

  Result := DadosRed.Tem;
end;



// ============================================================
// CÁLCULOS DE BASE E ALÍQUOTA
// ============================================================

class function TFuncoesAdicionaisRT.CalcularBaseCalculo(const Produto: TDetCollectionItem): Double;
var
  vBC: Double;
  vProd, vServ, vFrete, vSeg, vOutro, vII: Double;
  vDesc, vPis, vCofins: Double;
  vICMS, vICMSUFDest, vFCP, vFCPUFDest: Double;
  vICMSMono, vISSQN, vIS: Double;
begin
  try
    if not Assigned(Produto) then
    begin
      ShowMessage('Erro: Produto não inicializado');
      Result := 0;
      Exit;
    end;

    { Componentes positivos }

    //Produto.Prod.vFrete

    vProd  := IfThen(Assigned(Produto.Prod), Produto.Prod.vProd, 0);
    vFrete := IfThen(Assigned(Produto.Prod), Produto.Prod.vFrete, 0);
    vSeg   := IfThen(Assigned(Produto.Prod), Produto.Prod.vSeg, 0);
    vOutro := IfThen(Assigned(Produto.Prod), Produto.Prod.vOutro, 0);

    vII := IfThen(Assigned(Produto.Imposto.II), Produto.Imposto.II.vII, 0);
//    vIS := IfThen(Assigned(Produto.Imposto.), Produto.Imposto.IS.vIS, 0);


    { Componentes negativos }
    vDesc         := IfThen(Assigned(Produto.Prod) and (Produto.Prod.vDesc < 0), Produto.Prod.vDesc, 0);
    vPis          := IfThen(Assigned(Produto.Imposto.PIS) and (Produto.Imposto.PIS.vPIS > 0), Produto.Imposto.PIS.vPIS, 0);
    vCofins       := IfThen(Assigned(Produto.Imposto.COFINS) and (Produto.Imposto.COFINS.vCOFINS > 0), Produto.Imposto.COFINS.vCOFINS, 0);
    vICMS         := IfThen(Assigned(Produto.Imposto.ICMS) and (Produto.Imposto.ICMS.vICMS > 0), Produto.Imposto.ICMS.vICMS, 0);
    vICMSUFDest   := IfThen(Assigned(Produto.Imposto.ICMSUFDest) and (Produto.Imposto.ICMSUFDest.vICMSUFDest > 0), Produto.Imposto.ICMSUFDest.vICMSUFDest, 0);
    vFCP          := IfThen(Assigned(Produto.Imposto.ICMS) and (Produto.Imposto.ICMS.vFCP > 0), Produto.Imposto.ICMS.vFCP, 0);
    vFCPUFDest    := IfThen(Assigned(Produto.Imposto.ICMSUFDest) and Assigned(Produto.Imposto.ICMSUFDest) and (Produto.Imposto.ICMSUFDest.vBCFCPUFDest > 0), Produto.Imposto.ICMSUFDest.vBCFCPUFDest, 0);
    vICMSMono     := IfThen(Assigned(Produto.Imposto.ICMS) and (Produto.Imposto.ICMS.vICMS > 0) and (Pos('Mono', Produto.Imposto.ICMS.ClassName) > 0), Produto.Imposto.ICMS.vICMS, 0);
    vISSQN        := IfThen(Assigned(Produto.Imposto.ISSQN) and (Produto.Imposto.ISSQN.vDeducao > 0), Produto.Imposto.ISSQN.vDeducao, 0);

    { FÓRMULA: vBC = vProd + vServ + vFrete + vSeg + vOutro + vII - vDesc - vPis - vCofins - vICMS - vICMSUFDest - vFCP - vFCPUFDest - vICMSMono - vISSQN + vIS }
    vBC := vProd + vServ + vFrete + vSeg + vOutro + vII - vDesc - vPis - vCofins - vICMS - vICMSUFDest - vFCP - vFCPUFDest - vICMSMono - vISSQN + vIS;

    { Garante base não negativa }
    if vBC < 0 then
      vBC := 0;

    if not ValidarValor(vBC) then
    begin
      ShowMessage('Erro: Valor de Base de Cálculo inválido: ' + FloatToStr(vBC));
      Result := 0;
      Exit;
    end;

    Result := ArredondaSefaz(vBC);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Base de Cálculo: ' + E.Message);
      Result := 0;
    end;
  end;
end;

class function TFuncoesAdicionaisRT.CalcularBaseCalculowithParams(
  const Produto: TDetCollectionItem; const IncluirVProd, IncluirVFrete,
  IncluirVSeg, IncluirVOutro, IncluirVII, IncluirVIS, IncluirVDesc, IncluirVPIS,
  IncluirVCOFINS, IncluirVICMS, IncluirVICMSUFDest, IncluirVFCP,
  IncluirVFCPUFDest, IncluirVICMSMono, IncluirVISSQN: Boolean): Double;
var
  vBC: Double;
  vProd, vServ, vFrete, vSeg, vOutro, vII, vIS: Double;
  vDesc, vPis, vCofins: Double;
  vICMS, vICMSUFDest, vFCP, vFCPUFDest: Double;
  vICMSMono, vISSQN: Double;
begin
  try
    { Validação inicial }
    if not Assigned(Produto) then
    begin
      ShowMessage('Erro: Produto não inicializado');
      Result := 0;
      Exit;
    end;

    { Inicializar acumulador }
    vBC := 0;


    { Produto }
    if IncluirVProd then
      vProd := IfThen(Assigned(Produto.Prod), Produto.Prod.vProd, 0)
    else
      vProd := 0;
    vBC := vBC + vProd;

    { Frete }
    if IncluirVFrete then
      vFrete := IfThen(Assigned(Produto.Prod), Produto.Prod.vFrete, 0)
    else
      vFrete := 0;
    vBC := vBC + vFrete;

    { Seguro }
    if IncluirVSeg then
      vSeg := IfThen(Assigned(Produto.Prod), Produto.Prod.vSeg, 0)
    else
      vSeg := 0;
    vBC := vBC + vSeg;

    { Outros }
    if IncluirVOutro then
      vOutro := IfThen(Assigned(Produto.Prod), Produto.Prod.vOutro, 0)
    else
      vOutro := 0;
    vBC := vBC + vOutro;

    { Imposto de Importação }
    if IncluirVII then
      vII := IfThen(Assigned(Produto.Imposto.II), Produto.Imposto.II.vII, 0)
    else
      vII := 0;
    vBC := vBC + vII;

    { Imposto Seletivo }
    if IncluirVIS then
      vIS := IfThen(Assigned(Produto.Imposto.ISEL), Produto.Imposto.ISEL.vIS, 0)
    else
      vIS := 0;
    vBC := vBC + vIS;


    { Desconto }
    if IncluirVDesc then
      vDesc := IfThen(Assigned(Produto.Prod) and (Produto.Prod.vDesc > 0), Produto.Prod.vDesc, 0)
    else
      vDesc := 0;
    vBC := vBC - vDesc;

    { PIS }
    if IncluirVPIS then
      vPis := IfThen(Assigned(Produto.Imposto.PIS) and (Produto.Imposto.PIS.vPIS > 0), Produto.Imposto.PIS.vPIS, 0)
    else
      vPis := 0;
    vBC := vBC - vPis;

    { COFINS }
    if IncluirVCOFINS then
      vCofins := IfThen(Assigned(Produto.Imposto.COFINS) and (Produto.Imposto.COFINS.vCOFINS > 0), Produto.Imposto.COFINS.vCOFINS, 0)
    else
      vCofins := 0;
    vBC := vBC - vCofins;

    { ICMS }
    if IncluirVICMS then
      vICMS := IfThen(Assigned(Produto.Imposto.ICMS) and (Produto.Imposto.ICMS.vICMS > 0), Produto.Imposto.ICMS.vICMS, 0)
    else
      vICMS := 0;
    vBC := vBC - vICMS;

    { ICMS UF Destino }
    if IncluirVICMSUFDest then
      vICMSUFDest := IfThen(Assigned(Produto.Imposto.ICMSUFDest) and (Produto.Imposto.ICMSUFDest.vICMSUFDest > 0), Produto.Imposto.ICMSUFDest.vICMSUFDest, 0)
    else
      vICMSUFDest := 0;
    vBC := vBC - vICMSUFDest;

    { FCP }
    if IncluirVFCP then
      vFCP := IfThen(Assigned(Produto.Imposto.ICMS) and (Produto.Imposto.ICMS.vFCP > 0), Produto.Imposto.ICMS.vFCP, 0)
    else
      vFCP := 0;
    vBC := vBC - vFCP;

    { FCP UF Destino }
    if IncluirVFCPUFDest then
      vFCPUFDest := IfThen(Assigned(Produto.Imposto.ICMSUFDest) and (Produto.Imposto.ICMSUFDest.vBCFCPUFDest > 0), Produto.Imposto.ICMSUFDest.vBCFCPUFDest, 0)
    else
      vFCPUFDest := 0;
    vBC := vBC - vFCPUFDest;

    { ICMS Monofásico }
    if IncluirVICMSMono then
      vICMSMono := IfThen(Assigned(Produto.Imposto.ICMS) and (Produto.Imposto.ICMS.vICMS > 0) and (Pos('Mono', Produto.Imposto.ICMS.ClassName) > 0), Produto.Imposto.ICMS.vICMS, 0)
    else
      vICMSMono := 0;
    vBC := vBC - vICMSMono;

    { ISS/Deduções }
    if IncluirVISSQN then
      vISSQN := IfThen(Assigned(Produto.Imposto.ISSQN) and (Produto.Imposto.ISSQN.vDeducao > 0), Produto.Imposto.ISSQN.vDeducao, 0)
    else
      vISSQN := 0;
    vBC := vBC - vISSQN;



    { Garante base não negativa }
    if vBC < 0 then
      vBC := 0;

    if not ValidarValor(vBC) then
    begin
      ShowMessage('Erro: Valor de Base de Cálculo inválido: ' + FloatToStr(vBC));
      Result := 0;
      Exit;
    end;

    Result := ArredondaSefaz(vBC);


  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Base de Cálculo: ' + E.Message);
      Result := 0;
    end;
  end;
end;


class function TFuncoesAdicionaisRT.CalcularAjusteCompetencia(vOriginal,
  vReconhecido: Double; eTipo: string): Double;
begin
 ///
end;




/// <summary>
/// Calcula devolução de tributo (separado de diferimento)
/// Aplicável em devoluções, cancelamentos
/// FÓRMULA: vDevTrib = vTribOriginal × percentualDevolução / 100
/// </summary>
class function TFuncoesAdicionaisRT.CalcularDevolucaoTributo(
  vTribOriginal: Double;
  pPercentualDev: Double = 100): Double;
var
  vDevTrib: Double;
begin
  try
    if not ValidarValor(vTribOriginal) or not ValidarPercentual(pPercentualDev) then
    begin
      Result := 0;
      Exit;
    end;

    { FÓRMULA: vDev = vTribOriginal × pDev / 100 }
    vDevTrib := vTribOriginal * (pPercentualDev / 100);

    Result := ArredondaValorParaSefaz(vDevTrib);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Devolução de Tributo: ' + E.Message);
      Result := 0;
    end;
  end;
end;



class function TFuncoesAdicionaisRT.CalcularDiferimento(
  vBC: Double;
  pAliq: Double;
  pDif: Double): Double;
var
  vDif: Double;
begin
  try
    // FÓRMULA: vDif = vBC × (pAliq / 100) × (pDif / 100)
    vDif := vBC * (pAliq / 100) * (pDif / 100);

    // Mesmo que tudo seja 0, o resultado ainda será 0, sem erro
    Result := ArredondaValorParaSefaz(vDif);

  except
    on E: Exception do
    begin
      // Em caso de falha, sempre retorna 0 (sem interromper o fluxo)
      Result := 0;
    end;
  end;
end;


class function TFuncoesAdicionaisRT.CalcularGIBSCBSMono(
  const Produto: TDetCollectionItem;
  const vBC, adRemIBS, adRemCBS: Double;
  const cClassTrib: string;
  const qBCMono: Double = 0;
  const pDifIBS: Double = 0;
  const pDifCBS: Double = 0
): Boolean;
var
  LqBCMono: Double;
  LvIBSMono, LvCBSMono: Double;
  LvIBSMonoReten, LvCBSMonoReten: Double;
  LvIBSMonoDif, LvCBSMonoDif: Double;
begin
  Result := False;

  try
    if not Assigned(Produto) then
      raise Exception.Create('Produto não inicializado em CalcularGIBSCBSMono.');

    if not Assigned(Produto.Imposto) or not Assigned(Produto.Imposto.IBSCBS) then
      raise Exception.Create('Estrutura IBSCBS não inicializada.');


    // Base
    if qBCMono > 0 then
      LqBCMono := qBCMono
    else
      LqBCMono := Produto.Prod.qTrib;

    // Cálculos principais
    LvIBSMono := ArredondaValorParaSefaz(LqBCMono * (adRemIBS / 100));
    LvCBSMono := ArredondaValorParaSefaz(LqBCMono * (adRemCBS / 100));

    LvIBSMonoReten := 0;
    LvCBSMonoReten := 0;
    LvIBSMonoDif   := 0;
    LvCBSMonoDif   := 0;

    // =============== gMonoPadrao ==================
    with Produto.Imposto.IBSCBS.gIBSCBSMono.gMonoPadrao do
    begin
      qBCMono  := LqBCMono;
      adRemIBS := adRemIBS;
      adRemCBS := adRemCBS;
      vIBSMono := LvIBSMono;
      vCBSMono := LvCBSMono;
    end;

    // =============== gMonoDif =====================
    if (pDifIBS > 0) or (pDifCBS > 0) then
    begin
      LvIBSMonoDif := ArredondaValorParaSefaz(LvIBSMono * (pDifIBS / 100));
      LvCBSMonoDif := ArredondaValorParaSefaz(LvCBSMono * (pDifCBS / 100));
    end;

    with Produto.Imposto.IBSCBS.gIBSCBSMono.gMonoDif do
    begin
      pDifIBS     := pDifIBS;
      vIBSMonoDif := LvIBSMonoDif;
      pDifCBS     := pDifCBS;
      vCBSMonoDif := LvCBSMonoDif;
    end;

    // =============== gMonoReten (Tributação Monofásica Sujeita a Retenção) =====================
    if cClassTrib = '620002' then
    begin
      with Produto.Imposto.IBSCBS.gIBSCBSMono.gMonoReten do
      begin
        qBCMonoReten  := LqBCMono;
        adRemIBSReten := adRemIBS;
        vIBSMonoReten := 0;
        adRemCBSReten := adRemCBS;
        vCBSMonoReten := 0;
      end;
    end;

    // =============== 620003: gMonoPadrao + gMonoDif =====================
    if cClassTrib = '620003' then
    begin
      // gMonoPadrao já preenchido acima

      // gMonoDif obrigatório para 620003
      with Produto.Imposto.IBSCBS.gIBSCBSMono.gMonoDif do
      begin
        pDifIBS     := pDifIBS;
        vIBSMonoDif := LvIBSMonoDif;
        pDifCBS     := pDifCBS;
        vCBSMonoDif := LvCBSMonoDif;
      end;
    end;

    // =============== gMonoRet (RETIDA ANTERIORMENTE) =====================
    if (cClassTrib = '620004') or (cClassTrib = '620005') or (cClassTrib = '620006') then
    begin
      with Produto.Imposto.IBSCBS.gIBSCBSMono.gMonoRet do
      begin
        qBCMonoRet  := LqBCMono;
        adRemIBSRet := adRemIBS;
        adRemCBSRet := adRemCBS;
        vIBSMonoRet := 0.00;
        vCBSMonoRet := 0.00;
      end;
    end;

    // =============== Totais ======================
    with Produto.Imposto.IBSCBS.gIBSCBSMono do
    begin
      vTotIBSMonoItem := ArredondaValorParaSefaz(LvIBSMono + LvIBSMonoReten - LvIBSMonoDif);
      vTotCBSMonoItem := ArredondaValorParaSefaz(LvCBSMono + LvCBSMonoReten - LvCBSMonoDif);
    end;

    Result := True;

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular gIBSCBSMono: ' + E.Message);
      Result := False;
    end;
  end;
end;




class function TFuncoesAdicionaisRT.CalcularGTribCompraGov(
  const Produto: TDetCollectionItem;
  const vBC: Double;
  const pAliq: Double;
  const pRedAliq: Double;
  const pRedutor: Double): Boolean;
var
  pAliqEfet, vTrib: Double;
begin
  Result := False;

  try
    if not Assigned(Produto) then
    begin
      ShowMessage('Erro: Produto não inicializado em CalcularGTribCompraGov');
      Exit;
    end;

    if not ValidarValor(vBC) or not ValidarPercentual(pAliq) or
       not ValidarPercentual(pRedAliq) or not ValidarPercentual(pRedutor) then
    begin
      ShowMessage('Erro: Valores inválidos em CalcularGTribCompraGov');
      Exit;
    end;

    { Calcular alíquota efetiva com redutor }
    pAliqEfet := pAliq * (1 - (pRedAliq / 100)) * (1 - (pRedutor / 100));

    if pAliqEfet < 0 then
      pAliqEfet := 0;

    { Calcular valor }
    vTrib := vBC * (pAliqEfet / 100);
    vTrib := ArredondaValorParaSefaz(vTrib);

    Result := True;

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Compra Governamental: ' + E.Message);
      Result := False;
    end;
  end;
end;


//revisado 11.11.25 10:59
class function TFuncoesAdicionaisRT.CalcularAliquotaEfetiva(
  pAliq: Double;
  pRedAliq: Double;
  CompraGov: Boolean = False;
  pRedutor: Double = 0
): Double;
var
  pAliqEfet: Double;
begin
  try
    // Se vier como percentual (ex: 10 em vez de 0.10)
    if pAliq > 1 then
      pAliq := pAliq / 100;

    if pRedAliq > 1 then
      pRedAliq := pRedAliq / 100;

    // Fórmula: pAliqEfet = pAliq × (1 - pRedAliq)
    pAliqEfet := pAliq * (1 - pRedAliq);

    if CompraGov and (pRedutor > 0) then
      pAliqEfet := pAliqEfet * (1 - pRedutor / 100);

    if pAliqEfet < 0 then
      pAliqEfet := 0;

    // Retorna já em fração decimal (p.ex. 0.0600)
    Result := SimpleRoundTo(pAliqEfet, -2);

  except
    on E: Exception do
      Result := 0;
  end;
end;


class function TFuncoesAdicionaisRT.CalcularGTribRegular(
    const Produto: TDetCollectionItem;
    const vBC: Double;
    const CST, cClassTrib: string;
    const pAliqIBSUF, pAliqIBSMun, pAliqCBS: Double;
    const TemReducao: Boolean;
    const pRedAliqIBS, pRedAliqCBS: Double;
    const CompraGov: Boolean;
    const pRedutor: Double
  ): Boolean;
var
  LpAliqEfetIBSUF, LpAliqEfetIBSMun, LpAliqEfetCBS: Double;
  LvTribIBSUF, LvTribIBSMun, LvTribCBS: Double;
begin
  Result := False;

  try
    if not Assigned(Produto) then
      raise Exception.Create('Produto não inicializado.');

    if not Assigned(Produto.Imposto) then
      raise Exception.Create('Estrutura de imposto não inicializada.');

    // cria estrutura caso ainda não exista
    if Produto.Imposto.IBSCBS = nil then
      Produto.Imposto.IBSCBS := TIBSCBS.Create;
    if Produto.Imposto.IBSCBS.gIBSCBS = nil then
      Produto.Imposto.IBSCBS.gIBSCBS := TgIBSCBS.Create;
    if Produto.Imposto.IBSCBS.gIBSCBS.gTribRegular = nil then
      Produto.Imposto.IBSCBS.gIBSCBS.gTribRegular := TgTribRegular.Create;

    // --- Alíquotas efetivas ---
    LpAliqEfetIBSUF   := CalcularAliquotaEfetiva(pAliqIBSUF, IfThen(TemReducao, pRedAliqIBS, 0), CompraGov, pRedutor);
    LpAliqEfetIBSMun  := CalcularAliquotaEfetiva(pAliqIBSMun, IfThen(TemReducao, pRedAliqIBS, 0), CompraGov, pRedutor);
    LpAliqEfetCBS     := CalcularAliquotaEfetiva(pAliqCBS, IfThen(TemReducao, pRedAliqCBS, 0), CompraGov, pRedutor);

    // --- Valores calculados ---
    LvTribIBSUF       := ArredondaValorParaSefaz(vBC * (LpAliqEfetIBSUF / 100));
    LvTribIBSMun      := ArredondaValorParaSefaz(vBC * (LpAliqEfetIBSMun / 100));
    LvTribCBS         := ArredondaValorParaSefaz(vBC * (LpAliqEfetCBS / 100));

    // --- Preenche XML ---
    with Produto.Imposto.IBSCBS.gIBSCBS.gTribRegular do
    begin
      { CSTReg: Código de Situação Tributária (3 dígitos) }
      CSTReg               := produto.Imposto.IBSCBS.CST;
      { cClassTribReg: Classificação Tributária (6 dígitos) }
      cClassTribReg        := produto.Imposto.IBSCBS.cClassTrib;

      cClassTribReg        := cClassTrib;
      pAliqEfetRegIBSUF    := LpAliqEfetIBSUF;
      vTribRegIBSUF        := LvTribIBSUF;
      pAliqEfetRegIBSMun   := LpAliqEfetIBSMun;
      vTribRegIBSMun       := LvTribIBSMun;
      pAliqEfetRegCBS      := LpAliqEfetCBS;
      vTribRegCBS          := LvTribCBS;
    end;

    Result := True;

  except
    on E: Exception do
    begin
      // Aqui pode logar em vez de exibir
      ShowMessage('Erro ao calcular gTribRegular: ' + E.Message);
      Result := False;
    end;
  end;
end;


class function TFuncoesAdicionaisRT.CalcularCreditoPresumido(
  vBC: Double;
  pCredPres: Double): Double;
var
  vCredPres: Double;
begin
  try
    if not ValidarValor(vBC) or not ValidarPercentual(pCredPres) then
    begin
      Result := 0;
      Exit;
    end;

    { FÓRMULA: vCredPres = vBC × pCredPres / 100 }
    vCredPres := vBC * (pCredPres / 100);

    Result := ArredondaValorParaSefaz(vCredPres);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Crédito Presumido: ' + E.Message);
      Result := 0;
    end;
  end;
end;



/// <summary>
/// Calcula crédito presumido específico para CBS
/// FÓRMULA: vCredPresCBS = vCBS × pCredPres / 100
/// Válido apenas a partir de 2027
/// </summary>
class function TFuncoesAdicionaisRT.CalcularCredPresCBS(
  vCBS: Double;
  pCredPresCBS: Double;
  CBSSuspenso: Boolean = False): Double;
var
  vCredPres: Double;
begin
  try
    if not ValidarValor(vCBS) or not ValidarPercentual(pCredPresCBS) then
    begin
      Result := 0;
      Exit;
    end;

    { Se CBS está suspenso, não calcula agora }
    if CBSSuspenso then
    begin
      Result := 0;
      Exit;
    end;

    vCredPres := vCBS * (pCredPresCBS / 100);
    Result := ArredondaValorParaSefaz(vCredPres);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Crédito Presumido CBS: ' + E.Message);
      Result := 0;
    end;
  end;
end;



/// <summary>
/// Calcula crédito presumido específico para IBS
/// FÓRMULA: vCredPresIBS = vIBS × pCredPres / 100
/// Válido apenas a partir de 2027
/// </summary>
class function TFuncoesAdicionaisRT.CalcularCredPresIBS(
  vIBS: Double;
  pCredPresIBS: Double;
  IBSSuspenso: Boolean = False): Double;
var
  vCredPres: Double;
begin
  try
    if not ValidarValor(vIBS) or not ValidarPercentual(pCredPresIBS) then
    begin
      Result := 0;
      Exit;
    end;

    { Se IBS está suspenso, não calcula agora }
    if IBSSuspenso then
    begin
      Result := 0;
      Exit;
    end;

    vCredPres := vIBS * (pCredPresIBS / 100);
    Result := ArredondaValorParaSefaz(vCredPres);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Crédito Presumido IBS: ' + E.Message);
      Result := 0;
    end;
  end;
end;




class function TFuncoesAdicionaisRT.TruncaSefaz(const AValor: Double; Casas: Integer = 2): Double;
var
  Fator: Double;
begin
  Fator := Power(10, Casas);
  Result := Int(AValor * Fator) / Fator;
end;

//revisado em 22/12/2025 11:07
class function TFuncoesAdicionaisRT.CalcularIBSUF(
  vBC: Double;
  pIBSUF: Double;      // Alíquota nominal (ex: 17.0 para 17%)
  pAliqEfet: Double;   // Alíquota já reduzida (se vier calculada de fora)
  vDif: Double;
  vDevTrib: Double;
  vCredPres: Double;
  const TemReducao: Boolean = False;
  const AliqReducao: Double = 0 // Percentual de redução (ex: 60 para 60% de redução)
): Double;
var
  vIBSUF, AliqCalculada: Double;
  pPercentualPagar: Double;
begin
  Result := 0;
  try
    if not ValidarValor(vBC) then Exit;

    // 1. Caso de Isenção Total (Redução de 100%)
    if TemReducao and (AliqReducao >= 100) then
    begin
      Exit;
    end;

    // 2. Definição da Alíquota a ser aplicada
    if TemReducao then
    begin
      if (pAliqEfet > 0) then
      begin
        // Se a alíquota efetiva já foi calculada externamente
        AliqCalculada := pAliqEfet / 100;
      end
      else
      begin
        // Se temos a nominal e o percentual de redução (ex: reduz em 60%, paga 40%)
        // Cálculo: Alíquota Nominal * (1 - (Redução / 100))
        pPercentualPagar := (100 - AliqReducao) / 100;
        AliqCalculada := (pIBSUF / 100) * pPercentualPagar;
      end;
    end
    else
    begin
      // Sem redução, usa alíquota cheia
      AliqCalculada := pIBSUF / 100;
    end;

    // 3. Base x Alíquota (Cálculo do imposto bruto)
    vIBSUF := vBC * AliqCalculada;

    // 4. Aplicação das deduções (Diferimento, Devolução, Crédito Presumido)
    vIBSUF := vIBSUF - vDif - vDevTrib - vCredPres;

    // 5. Garantir que não fique negativo
    if vIBSUF < 0 then
      vIBSUF := 0;

    // Debug/Mensagem (Opcional - remover em produção)

   { showmessage('Base de Cálculo: ' + FloatToStr(vBC) + #13 +
                'Alíquota Aplicada: ' + FloatToStr(AliqCalculada * 100) + '%' + #13 +
                'vIBSUF Final: ' + CurrToStr(TruncaSefaz(vIBSUF)));

          }
    Result := TruncaSefaz(vIBSUF);

  except
    on E: Exception do
    begin
      // Log do erro se necessário
      Result := 0;
    end;
  end;
end;


{
///revisado em 27.11 UF PE e demais estados.
class function TFuncoesAdicionaisRT.CalcularIBSUF(
  vBC: Double;
  pIBSUF: Double;     // ex: 0.1000 = 0,10%
  pAliqEfet: Double;  // ex: 0.0600 = 0,06% após redução
  vDif: Double;
  vDevTrib: Double;
  vCredPres: Double;
  const TemReducao: Boolean = False;
  const AliqReducao : Currency = 0
): Double;
var
  vIBSUF, Aliq: Double;
begin
  try
    if not ValidarValor(vBC) then Exit(0);

    if (TemReducao) and (AliqReducao = 100 )then
    begin
      Result := 0 ;
      exit;
    end;

    if TemReducao and (pAliqEfet > 0) then
      Aliq := pAliqEfet / 100
    else
      Aliq := pIBSUF / 100;

    //Base x Aliquota final
    vIBSUF := vBC * Aliq;

    //deduções
    vIBSUF := vIBSUF - vDif - vDevTrib - vCredPres;


    if vIBSUF < 0 then vIBSUF := 0;


    showmessage ('vIBSUF TruncaSefaz = OFF:'+ CurrToStr(vIBSUF)
                +#10#13+
                'vIBSUF TruncaSefaz =  ON:'+ CurrToStr(TruncaSefaz(vIBSUF))
                ) ;

    Result := TruncaSefaz(vIBSUF);

  except
    Result := 0;
  end;
end;
          }



  (* revisao até 27.11.2025
class function TFuncoesAdicionaisRT.CalcularIBSUF(
  vBC: Double;
  pIBSUF: Double;
  pAliqEfet: Double;
  vDif: Double;
  vDevTrib: Double;
  vCredPres: Double;
  const TemReducao: Boolean = False
): Double;
var
  vIBSUF: Double;
begin
  try
    if not ValidarValor(vBC) then
      Exit;

    // ## Caso tenha redução de 100%, e a alíquota efetiva é zero, não calcula
    if TemReducao {and (pAliqEfet = 0)} then
      begin
        vIBSUF := 0;
        exit;
      end
    else
    begin
      // ## Caso normal: usa alíquota efetiva se > 0, senão usa alíquota padrão
      if pAliqEfet > 0 then
        vIBSUF := vBC * (pAliqEfet / 100)
      else
        vIBSUF := vBC * (pIBSUF / 100);
    end;

    // ## Subtrai deduções
    vIBSUF := vIBSUF - vDif - vDevTrib - vCredPres;

    if vIBSUF < 0 then
      vIBSUF := 0;

    Result := ArredondaValorParaSefaz(vIBSUF);

  except
    on E: Exception do
      Result := 0;
  end;

end;
     *)

class function TFuncoesAdicionaisRT.CalcularImpustoSeletivo(vBC, pAliqIS,
  pRedAliq: Double; uTrib: string; qTrib: Double): Double;
var
  pAliqEfet: Double;
  vIS: Double;
begin
  try
    { ===== VALIDAÇÕES ===== }
    if not ValidarValor(vBC) then
    begin
      Result := 0;
      Exit;
    end;

    if not ValidarPercentual(pAliqIS) or not ValidarPercentual(pRedAliq) then
    begin
      Result := 0;
      Exit;
    end;

    { ===== CALCULAR ALÍQUOTA EFETIVA ===== }
    if pRedAliq > 0 then
      pAliqEfet := pAliqIS * (1 - (pRedAliq / 100))
    else
      pAliqEfet := pAliqIS;

    { ===== CALCULAR IS ===== }
    { FÓRMULA: vIS = vBC × pAliqEfet / 100 }
    vIS := vBC * (pAliqEfet / 100);

    { Se tributação específica (por unidade) }
    if (uTrib = 'E') and (qTrib > 0) then
      vIS := vIS * qTrib;

    { Arredondar conforme SEFAZ }
    Result := ArredondaValorParaSefaz(vIS);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Imposto Seletivo: ' + E.Message);
      Result := 0;
    end;
  end;
end;

class function TFuncoesAdicionaisRT.CalcularMonoDiferimento(vBC, pAliqMono,
  pDifMono: Double): Double;
var
  vMono, vDif: Double;
begin
  try
    if not ValidarValor(vBC) or not ValidarPercentual(pAliqMono) or not ValidarPercentual(pDifMono) then
    begin
      Result := 0;
      Exit;
    end;

    { ===== CALCULAR DIFERIMENTO ===== }
    { FÓRMULA: vDif = vBC × pAliqMono × pDifMono / 100 }
    vMono := vBC * (pAliqMono / 100);
    vDif := vMono * (pDifMono / 100);

    Result := ArredondaValorParaSefaz(vDif);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Monofásica Diferimento: ' + E.Message);
      Result := 0;
    end;
  end;
end;


class function TFuncoesAdicionaisRT.CalcularMonoReten(vBC, pAliqRet: Double;
  eTipo: string): Double;
var
  vRet: Double;
begin
  try
    if not ValidarValor(vBC) or not ValidarPercentual(pAliqRet) then
    begin
      Result := 0;
      Exit;
    end;

    { ===== CALCULAR RETENÇÃO ===== }
    { FÓRMULA: vRet = vBC × pAliqRet / 100 }
    vRet := vBC * (pAliqRet / 100);

    Result := ArredondaValorParaSefaz(vRet);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular Monofásica Retenção: ' + E.Message);
      Result := 0;
    end;
  end;
end;

class function TFuncoesAdicionaisRT.CalcularIBSMunicipio(
  vBC: Double;
  pIBSMun: Double;
  pAliqEfet: Double;
  vDif: Double;
  vDevTrib: Double;
  vCredPres: Double): Double;
var
  vIBSMun: Double;
begin
  try
    if not ValidarValor(vBC) or not ValidarPercentual(pIBSMun) or not ValidarPercentual(pAliqEfet) then
    begin
      Result := 0;
      Exit;
    end;

    { FÓRMULA com alíquota efetiva }
    if pAliqEfet > 0 then
      vIBSMun := vBC * (pAliqEfet / 100)
    else
      vIBSMun := vBC * (pIBSMun / 100);

    { Subtrai deduções }
    vIBSMun := vIBSMun - vDif - vDevTrib - vCredPres;

    if vIBSMun < 0 then
      vIBSMun := 0;

    Result := ArredondaValorParaSefaz(vIBSMun);

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular IBS Município: ' + E.Message);
      Result := 0;
    end;
  end;
end;


class function TFuncoesAdicionaisRT.CalcularCBS(
  vBC: Double;
  pCBS: Double;
  pAliqEfet: Double;
  TemReducao: Boolean = False;
  pRedAliq: Double = 0
): Double;
var
  vCBS, pRed: Double;
begin
  try
    // ## Validação básica
    if not ValidarValor(vBC) or not ValidarPercentual(pCBS) then
    begin
      Result := 0;
      Exit;
    end;

    // ## Normaliza percentual de redução
    if TemReducao then
    begin
      if pRedAliq > 1 then
        pRed := pRedAliq / 100
      else
        pRed := pRedAliq;
    end
    else
      pRed := 0;

    // ## Caso redução total (100%) # zera o imposto
    if TemReducao and ((pRed >= 1) or (pAliqEfet <= 0)) then
    begin
      Result := 0;
      Exit;
    end;

    // ## Sem redução # aplica alíquota normal
    if not TemReducao then
    begin
      vCBS := vBC * (pCBS / 100);
    end
    else
    begin
      // Com redução # usa alíquota efetiva informada
      vCBS := vBC * (pAliqEfet / 100);
    end;

    // ## Arredonda para 2 casas decimais
    vCBS := RoundTo(vCBS, -2);

    // ## Proteção contra valores muito pequenos (rejeição 1035)
    if vCBS < 0.01 then
      vCBS := 0;

    Result := vCBS;

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao calcular CBS: ' + E.Message);
      Result := 0;
    end;
  end;
end;

// ============================================================
// ARREDONDAMENTO CONFORME PADRÃO SEFAZ
// ============================================================

class function TFuncoesAdicionaisRT.ArredondaAliquota(valor: Double): Double;
begin
  Result := Trunc(valor * 10000 + 0.5) / 10000;
end;

class function TFuncoesAdicionaisRT.ArredondaSefaz(valor: Double): Double;
begin
  Result :=Trunc(valor * 100 + 0.5) / 100;
end;

class function TFuncoesAdicionaisRT.ArredondaValorParaSefaz(valor: Double): Double;
begin
  try
   { if (valor > 0) and (valor < 0.01) then
   {   Result := 0.01
    else  }
      Result := SimpleRoundTo(valor,-2);

  except
    Result := 0;
  end;
end;

end.
