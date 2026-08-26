const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), 'utf8');
const readExternal = (absolutePath) => fs.readFileSync(absolutePath, 'utf8');
const apiRoot = path.resolve(root, '..', 'API', 'Fontes');

const app = read('App.tsx');
const api = read(path.join('src', 'services', 'api.ts'));
const storage = read(path.join('src', 'services', 'storage.ts'));
const network = read(path.join('src', 'services', 'network.ts'));
const errors = read(path.join('src', 'services', 'errors.ts'));
const imageCache = read(path.join('src', 'services', 'imageCache.ts'));
const types = read(path.join('src', 'types.ts'));
const theme = read(path.join('src', 'theme.ts'));
const appConfig = read('app.json');
const packageJson = read('package.json');
const releaseScript = read(path.join('scripts', 'release-tablet.ps1'));
const adbSmokeScript = read(path.join('scripts', 'adb-smoke-tablet.ps1'));
const kioskDocs = read(path.join('docs', 'KIOSK_ANDROID.md'));
const homologacaoDocs = read(path.join('docs', 'HOMOLOGACAO.md'));
const segurancaDocs = read(path.join('docs', 'SEGURANCA_CONFIGURACAO.md'));
const androidBuildGradle = read(path.join('android', 'app', 'build.gradle'));
const androidManifest = read(path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml'));
const mainActivity = read(path.join('android', 'app', 'src', 'main', 'java', 'br', 'com', 'sistemalechef', 'cardapiotablet', 'MainActivity.kt'));
const mainApplication = read(path.join('android', 'app', 'src', 'main', 'java', 'br', 'com', 'sistemalechef', 'cardapiotablet', 'MainApplication.kt'));
const kioskModule = read(path.join('android', 'app', 'src', 'main', 'java', 'br', 'com', 'sistemalechef', 'cardapiotablet', 'TabletKioskModule.kt'));
const deviceAdminReceiver = read(path.join('android', 'app', 'src', 'main', 'java', 'br', 'com', 'sistemalechef', 'cardapiotablet', 'TabletDeviceAdminReceiver.kt'));
const deviceAdminXml = read(path.join('android', 'app', 'src', 'main', 'res', 'xml', 'tablet_device_admin.xml'));
const empresaDao = readExternal(path.join(apiRoot, 'Source', 'Model', 'DAO', 'APIRPCheff.DAO.Empresa.pas'));
const empresaEntity = readExternal(path.join(apiRoot, 'Source', 'Model', 'Entity', 'APIRPCheff.Entity.Empresa.pas'));

const checks = [
  {
    name: 'Modulo Cardapio Tablet depende de empresas.utiliza_cardapiotablet',
    ok:
      types.includes('utilizaCardapioTablet') &&
      storage.includes('utilizaCardapioTablet: false') &&
      storage.includes('lastModuleCheckAt') &&
      api.includes('parseCompanyStatus') &&
      api.includes('getCompanyStatus') &&
      api.includes('utiliza_cardapiotablet') &&
      app.includes("MODULE_DISABLED_MESSAGE = 'Modulo não habilitado'") &&
      app.includes('syncCompanyStatus') &&
      app.includes('client.getCompanyStatus()') &&
      app.includes('utilizaCardapioTablet') &&
      empresaEntity.includes('utilizaCardapioTablet') &&
      empresaDao.includes('utiliza_cardapiotablet')
  },
  {
    name: 'Troca de mesa exige login do garcom',
    ok:
      app.includes('settingsAuth') &&
      app.includes('authorizeSettingsChange') &&
      app.includes('api.login(settingsAuthLogin, settingsAuthPassword)') &&
      !/label="Configuracao"[\s\S]{0,180}setMode\('setup'\)/.test(app)
  },
  {
    name: 'Configuracao do cardapio exige garcom e permite voltar ao menu sem salvar',
    ok:
      app.includes('label="Configuracao"') &&
      app.includes("openSettingsAuth('menu')") &&
      app.includes('cancelSettingsAuth') &&
      app.includes('cancelSettingsChange') &&
      app.includes('settingsReturnMode')
  },
  {
    name: 'Falha de conexao permite recuperar API somente com ADM local e API sem comunicacao',
    ok:
      app.includes('API_RECONNECT_MESSAGE') &&
      app.includes("EMERGENCY_API_ADMIN_LOGIN = 'ADM'") &&
      app.includes("EMERGENCY_API_ADMIN_PASSWORD = '18021950'") &&
      app.includes('isEmergencyApiRecoveryCredentials') &&
      app.includes('isApiRecoveryAuthMode') &&
      app.includes('isCurrentApiCommunicating') &&
      app.includes('startupConnectionIssue') &&
      app.includes('retryStartupConnection') &&
      app.includes("openSettingsAuth('loading')") &&
      app.includes('openApiRecoverySettings') &&
      app.includes("setSettingsAccessMode('emergencyApi')") &&
      app.includes("settingsAccessMode === 'emergencyApi'") &&
      app.includes('editable={!emergencyApiAccess}') &&
      app.includes('disabled={emergencyApiAccess}') &&
      app.includes('Acesso local emergencial') &&
      app.includes('Somente o usuario ADM local') &&
      app.includes('API comunicando') &&
      app.includes('Use usuario e senha do garcom') &&
      app.includes('Servidor sem resposta') &&
      app.includes('Verifique se o tablet esta na rede correta') &&
      /if \(recoveryAuthMode && emergencyCredentials\) \{[\s\S]*const apiCommunicating = await isCurrentApiCommunicating\(\)[\s\S]*if \(apiCommunicating\)[\s\S]*openApiRecoverySettings\(\)/.test(app) &&
      !app.includes('onPress={openApiRecoverySettings}') &&
      !/mode === 'loading'[\s\S]{0,800}setMode\('setup'\)/.test(app)
  },
  {
    name: 'Configuracao tem destaque visual e tela refinada para tablet',
    ok:
      app.includes('variant="config"') &&
      app.includes('styles.actionButtonConfig') &&
      app.includes('styles.actionButtonConfigBadge') &&
      app.includes('styles.setupShell') &&
      app.includes('styles.setupSidebar') &&
      app.includes('styles.setupFieldCard')
  },
  {
    name: 'Autorizacao de configuracao tem visual administrativo dedicado',
    ok:
      app.includes('styles.authShell') &&
      app.includes('styles.authBadge') &&
      app.includes('styles.authFieldCard') &&
      app.includes('Area protegida') &&
      app.includes('Liberar configuracao')
  },
  {
    name: 'Liberacao de mesa tem visual profissional dedicado ao garcom',
    ok:
      app.includes('styles.unlockShell') &&
      app.includes('styles.unlockBadge') &&
      app.includes('styles.unlockFieldMeta') &&
      app.includes('Abertura de atendimento') &&
      app.includes('Aguardando garcom')
  },
  {
    name: 'Credenciais do garcom nao reaproveitam usuario anterior',
    ok:
      /const openUnlock = \(\) => \{[\s\S]*setLogin\(''\)[\s\S]*setPassword\(''\)[\s\S]*setMode\('unlock'\)/.test(app) &&
      /const openSettingsAuth = [\s\S]*setSettingsAuthLogin\(''\)[\s\S]*setSettingsAuthPassword\(''\)[\s\S]*setMode\('settingsAuth'\)/.test(app) &&
      /const lockTablet = [\s\S]*setLogin\(''\)[\s\S]*setPassword\(''\)[\s\S]*setSettingsAuthLogin\(''\)[\s\S]*setSettingsAuthPassword\(''\)/.test(app) &&
      app.includes('importantForAutofill="no"') &&
      app.includes('autoComplete="off"') &&
      app.includes('textContentType="none"')
  },
  {
    name: 'Cardapio nao mostra banner redundante apos liberar mesa',
    ok: !/setBanner\(`Mesa \$\{formatMesa\([^}]+\)\} liberada\.`/.test(app)
  },
  {
    name: 'Rodape das telas protegidas mostra Cardapio Tablet versao 2.0.0',
    ok:
      app.includes("APP_DISPLAY_BRAND = 'Cardapio Tablet'") &&
      app.includes("APP_DISPLAY_NAME = 'CARDAPIO TABLET'") &&
      app.includes("APP_DISPLAY_VERSION = '2.0.0'") &&
      app.includes('Versão') &&
      app.includes('function AppFooter') &&
      (app.match(/<AppFooter \/>/g) || []).length >= 3 &&
      appConfig.includes('"version": "2.0.0"') &&
      appConfig.includes('"versionCode": 2') &&
      packageJson.includes('"version": "2.0.0"') &&
      androidBuildGradle.includes('versionCode 2') &&
      androidBuildGradle.includes('versionName "2.0.0"')
  },
  {
    name: 'Tela bloqueada usa marca Cardapio Tablet sem marca antiga',
    ok:
      app.includes('<Text style={styles.brand}>{APP_DISPLAY_BRAND}</Text>') &&
      !app.includes('Le' + 'Movel')
  },
  {
    name: 'Configuracao rola em telas menores sem esconder os botoes',
    ok:
      app.includes('styles.setupScroll') &&
      app.includes('styles.setupScrollContent') &&
      app.includes('styles.setupSidebarScroll') &&
      app.includes('showsVerticalScrollIndicator') &&
      !app.includes('minHeight: 680')
  },
  {
    name: 'Banners de rotina do carrinho e da sincronizacao ficam silenciosos',
    ok:
      !app.includes("setBanner('Item adicionado ao carrinho.')") &&
      !app.includes("setBanner('Produto fracionado adicionado ao carrinho.')") &&
      !app.includes('successBanner') &&
      !app.includes("Cardapio atualizado.")
  },
  {
    name: 'Visualizar Pedido mostra itens enviados sem acoes de alteracao',
    ok:
      app.includes('label="Visualizar Pedido"') &&
      app.includes('renderOrderPreviewModal') &&
      app.includes('api.getSale(session.idVenda, true)') &&
      app.includes('visibleOrderLines') &&
      !api.includes('cancelSaleItem')
  },
  {
    name: 'Falha de rede no envio mostra mensagem elegante sem erro tecnico cru',
    ok:
      app.includes('NETWORK_SEND_FAILURE_MESSAGE') &&
      errors.includes('Falha no envio da rede, chame o Garçom.') &&
      app.includes('renderNetworkFailureModal') &&
      app.includes('isNetworkRequestError(error)') &&
      !/Alert\.alert\('Erro no envio',\s*error instanceof Error \? error\.message/.test(app)
  },
  {
    name: 'Mensagens tecnicas de erro ficam centralizadas e amigaveis',
    ok:
      errors.includes('getFriendlyErrorMessage') &&
      errors.includes('isNetworkRequestError') &&
      app.includes('getFriendlyErrorMessage') &&
      app.includes("title: 'Erro no envio'") &&
      app.includes('showAppDialog')
  },
  {
    name: 'Alertas operacionais usam modal visual do Cardapio Tablet',
    ok:
      app.includes('renderAppDialog') &&
      app.includes('styles.dialogCard') &&
      app.includes('styles.dialogTopLine') &&
      app.includes('Credenciais obrigatorias') &&
      app.includes('getCredentialFailureMessage') &&
      !app.includes('Alert.alert')
  },
  {
    name: 'Falha de rede no envio gera fila local pendente sem duplicar pelo mesmo mobileLaunchId',
    ok:
      types.includes('export type PendingOrder') &&
      storage.includes('buildPendingOrderQueueId') &&
      storage.includes('enqueuePendingOrder') &&
      storage.includes('existingIndex') &&
      app.includes('enqueuePendingOrder({') &&
      app.includes('buildPendingOrderQueueId(session, cart)')
  },
  {
    name: 'Configuracao autorizada mostra diagnostico e reenvio de pendencias ao garcom',
    ok:
      types.includes('export type TabletDiagnostics') &&
      storage.includes('loadTabletDiagnostics') &&
      storage.includes('saveTabletDiagnostics') &&
      app.includes('setupDiagnosticsCard') &&
      app.includes('retryPendingOrderQueue') &&
      app.includes('Reenviar pendencias')
  },
  {
    name: 'Diagnostico pode ser exportado pelo compartilhamento nativo',
    ok:
      app.includes('Share') &&
      app.includes('shareTabletDiagnostics') &&
      app.includes('buildTabletDiagnosticsReport') &&
      app.includes('Exportar diagnostico') &&
      app.includes('Diagnostico Cardapio Tablet')
  },
  {
    name: 'Fila offline mostra pendencias detalhadas na configuracao',
    ok:
      app.includes('pendingOrderList') &&
      app.includes('getPendingOrderPresentation') &&
      app.includes('Aguardando envio') &&
      app.includes('Falhou') &&
      app.includes('formatPendingOrderTitle') &&
      app.includes('pendingOrderError')
  },
  {
    name: 'Release Android tem script unico de teste, build e validacao',
    ok:
      packageJson.includes('"release:android"') &&
      releaseScript.includes('npm run test:smoke') &&
      releaseScript.includes('assembleRelease') &&
      releaseScript.includes('aapt.exe') &&
      releaseScript.includes('apksigner.bat') &&
      releaseScript.includes('SHA256')
  },
  {
    name: 'Smoke ADB instala, abre e coleta evidencia do tablet',
    ok:
      packageJson.includes('"smoke:adb"') &&
      adbSmokeScript.includes('adb devices') &&
      adbSmokeScript.includes('install') &&
      adbSmokeScript.includes('monkey') &&
      adbSmokeScript.includes('dumpsys') &&
      adbSmokeScript.includes('adb-smoke-cardapio-tablet.txt')
  },
  {
    name: 'Kiosk forte e seguranca de configuracao estao documentados',
    ok:
      kioskDocs.includes('dpm list-owners') &&
      kioskDocs.includes('LOCK_TASK_MODE_LOCKED') &&
      kioskDocs.includes('npm run smoke:adb') &&
      homologacaoDocs.includes('CT-014 - Release e smoke ADB') &&
      homologacaoDocs.includes('CT-015 - Recuperacao emergencial da API') &&
      segurancaDocs.includes('pareamento') &&
      segurancaDocs.includes('Android Keystore') &&
      segurancaDocs.includes('token revogavel')
  },
  {
    name: 'Tablet nao expoe endpoints de fechamento/pagamento/transferencia/cancelamento',
    ok: !/\/(?:pre)?fechamento|\/pagamento|\/transferencia|\/juncao|\/reabertura|method:\s*'DELETE'/i.test(api)
  },
  {
    name: 'Envio usa lote de itens com idempotencia mobile',
    ok: api.includes('/item/lote') && api.includes('mobileLaunchId') && app.includes('buildLineId(session')
  },
  {
    name: 'Polling permanece fixo em 10 segundos',
    ok: storage.includes('pollingMs: 10000') && app.includes('settings.pollingMs')
  },
  {
    name: 'App sincroniza automaticamente ao abrir ou voltar para o primeiro plano',
    ok:
      app.includes('AppState.addEventListener') &&
      app.includes('syncCurrentMenu') &&
      app.includes('Sincronizando mesa e cardapio...') &&
      app.includes("nextState === 'active'")
  },
  {
    name: 'Sincronizacao automatica tem janela anti-burst e atualizar manual força sync',
    ok:
      app.includes('SMART_SYNC_MIN_INTERVAL_MS') &&
      app.includes('lastSyncAttemptAtRef') &&
      app.includes('force = false') &&
      app.includes('force: true')
  },
  {
    name: 'Troca de produto preserva somente os opcionais do produto atual',
    ok:
      api.includes('async getProduct(idProduto: number') &&
      api.includes('produto/${normalizedId}?exibirImagem=') &&
      api.includes('return parseMenuItem(payload)') &&
      app.includes('const catalogOptionals = getVisibleProductOptionals(product)') &&
      app.includes('const detailOptionals = getVisibleProductOptionals(detail)') &&
      app.includes('opcionais: detailOptionals.length > 0 ? detailOptionals : catalogOptionals') &&
      app.includes('productDetailRequestSeqRef') &&
      !app.includes('selectedProductDetailsLoading') &&
      app.includes('disabled={!canLaunch}')
  },
  {
    name: 'Produto fracionado gera payload fracoes',
    ok: api.includes('const fracoes = item.fracoes?.map') && app.includes('selectedFractionReady')
  },
  {
    name: 'Payload fracionado nao herda opcionais do item pai',
    ok:
      api.includes('const hasFractions = Boolean(item.fracoes?.length)') &&
      api.includes('const fractionOptionals = fraction.opcionais || []') &&
      !api.includes('const fractionOptionals = (fraction.opcionais || []).length > 0 ? fraction.opcionais : item.opcionais') &&
      api.includes('getLaunchOptionalsTotal(fractionOptionals, fractionQuantity)') &&
      api.includes('opcionais: hasFractions ? [] : item.opcionais.map(cloneLaunchOptional)') &&
      api.includes('opcionais: fractionOptionals.map(cloneLaunchOptional)')
  },
  {
    name: 'Opcionais de fracionado pertencem a cada sabor selecionado',
    ok:
      app.includes('selectedFractionOptionalQty') &&
      app.includes('selectedFractionOptionalsByIndex') &&
      app.includes('selectedFractionLaunchOptionalsByIndex') &&
      app.includes('changeFractionOptionalQuantity') &&
      app.includes('Opcionais do sabor {index + 1}') &&
      app.includes('const fractionOptionals = selectedFractionLaunchOptionalsByIndex[flavorIndex] || []') &&
      app.includes('opcionais: fractionOptionals') &&
      app.includes('opcionais: []') &&
      !app.includes('const fractionOptionals = selectedOptionals')
  },
  {
    name: 'Troca de sabor limpa somente os opcionais daquela fracao',
    ok:
      app.includes('clearFractionOptionalQuantities(index)') &&
      app.includes('setSelectedFractionOptionalQty((current) =>') &&
      app.includes('delete next[index]') &&
      app.includes('loadFractionProductDetail(index, flavor)')
  },
  {
    name: 'Carrinho de fracionado com 1 sabor exibe somente o sabor escolhido',
    ok:
      app.includes('function getSingleCartFraction') &&
      app.includes('fractions.length === 1 ? fractions[0] : null') &&
      app.includes('function getCartLineTitle') &&
      app.includes('getSingleCartFraction(item)?.produtoDescricao') &&
      app.includes('function getCartLineOptionals') &&
      app.includes('function getCartLineObservation') &&
      app.includes('const cartLineOptionals = getCartLineOptionals(item)') &&
      app.includes('const cartLineObservation = getCartLineObservation(item)') &&
      app.includes('function getCartLineFractions') &&
      app.includes('function shouldShowCartFractionSummary') &&
      app.includes('getCartLineFractions(item).length > 1') &&
      app.includes('const cartLineTitle = getCartLineTitle(item)') &&
      app.includes('const showFractionSummary = shouldShowCartFractionSummary(item)')
  },
  {
    name: 'Carrinho de fracionado com varios sabores nao usa sabor como titulo',
    ok:
      app.includes("const FRACTION_GROUP_TITLE = 'Item fracionado'") &&
      app.includes('if (fractions.length > 1) return FRACTION_GROUP_TITLE') &&
      app.includes('if (Number(item.fracoes?.length || 0) > 1) return FRACTION_GROUP_TITLE') &&
      app.includes('return getSingleCartFraction(item)?.produtoDescricao || item.product.descricao')
  },
  {
    name: 'Carrinho de fracionado mostra sabores e opcionais',
    ok:
      app.includes('function getCombinedOptionalsForPresentation') &&
      app.includes('return getCombinedOptionalsForPresentation(item.opcionais || [], getCartLineFractions(item))') &&
      app.includes('const cartLineFractions = getCartLineFractions(item)') &&
      app.includes('Sabores ({formatFractionFlavorCount(cartLineFractions.length)})') &&
      app.includes('cartLineFractions.map((fraction, index)') &&
      app.includes('cartLineOptionals.length > 0 && !showFractionSummary') &&
      app.includes('Adicionais: {summarizeOptionals(cartLineOptionals)}') &&
      app.includes('styles.cartFractionText')
  },
  {
    name: 'Visualizar Pedido mostra opcionais e observacao de item fracionado',
    ok:
      app.includes('function getFractionOptionalsForPresentation') &&
      app.includes('function getCombinedOptionalsForPresentation') &&
      app.includes('function getSaleLineOptionals') &&
      app.includes('function getSaleLineObservation') &&
      app.includes('const optionals = getSaleLineOptionals(item) || []') &&
      app.includes('const observation = getSaleLineObservation(item)') &&
      app.includes('const showFractions = shouldShowSaleLineFractions(item)') &&
      app.includes('optionals.length > 0 && !showFractions') &&
      app.includes('const fractionOptionals = fraction.opcionais || []') &&
      app.includes('styles.orderFractionDetail') &&
      api.includes("const rawOptionals = resolveField(source, ['opcionais', 'opcional', 'adicionais'])")
  },
  {
    name: 'Produto fracionado permite selecionar 1 sabor',
    ok:
      app.includes('FRACTION_FLAVOR_COUNTS = [1, 2, 3, 4]') &&
      app.includes('DEFAULT_FRACTION_FLAVOR_COUNT = 1') &&
      app.includes('formatFractionFlavorCount') &&
      app.includes("count === 1 ? 'sabor' : 'sabores'") &&
      app.includes('setSelectedFractionIds(product.permiteFracao ? [product.idProduto] : [])') &&
      /const normalized = Math\.max\(1,\s*Math\.min\(4,\s*Math\.trunc\(count\)\)\)/.test(app) &&
      !/const normalized = Math\.max\(2,\s*Math\.min\(4,\s*Math\.trunc\(count\)\)\)/.test(app) &&
      !app.includes('[2, 3, 4].map((count)')
  },
  {
    name: 'Produto por tamanho mostra somente tamanhos cadastrados',
    ok:
      api.includes('function hasConfiguredSizeOption') &&
      api.includes("sanitizeText(label, '').trim().length > 0 || Number(value || 0) > 0") &&
      api.includes('const configuredSizes = [') &&
      api.includes('hasConfiguredSizeOption(product.tamanhoP, product.valorTamanhoP)') &&
      api.includes('hasConfiguredSizeOption(product.tamanhoGG, product.valorTamanhoGG)') &&
      api.includes('hasConfiguredSizeOption(product.tamanhoExtra, product.valorTamanhoExtra)') &&
      api.includes('const valid = candidates.filter((_, index) => configuredSizes[index])') &&
      !api.includes("const valid = candidates.filter((item) => item.value > 0 || item.label.trim().length > 0)")
  },
  {
    name: 'Sabores fracionados mostram todos os produtos da categoria',
    ok:
      app.includes('const fractionFlavorOptions = useMemo') &&
      app.includes('.filter((product) => product.b_venda_mobile !== false)') &&
      app.includes('.filter((product) => !categoryId || Number(product.idCategoria || 0) === categoryId)') &&
      !app.includes('product.permiteFracao || product.vendaPorTamanho || product.idProduto === selectedProduct.idProduto') &&
      app.includes('const orderedFlavorOptions = selectedFlavor') &&
      app.includes('{orderedFlavorOptions.map((flavor) => {') &&
      app.includes('contentContainerStyle={styles.fractionFlavorRow}') &&
      app.includes('showsHorizontalScrollIndicator')
  },
  {
    name: 'Imagem do produto no card fica inteira e centralizada',
    ok:
      app.includes('style={styles.productImage}\n              resizeMode="contain"') &&
      /productImage:\s*\{[\s\S]{0,80}width:\s*'92%'[\s\S]{0,80}height:\s*'92%'/.test(app) &&
      /productImageBox:\s*\{[\s\S]{0,160}alignItems:\s*'center'[\s\S]{0,80}justifyContent:\s*'center'/.test(app) &&
      !app.includes('style={styles.productImage}\n              resizeMode="cover"')
  },
  {
    name: 'Fundo branco da foto nao aparece como bloco no card',
    ok:
      theme.includes("productCard: '#fffdf9'") &&
      theme.includes("productImageSurface: '#ffffff'") &&
      app.includes('backgroundColor: colors.productImageSurface')
  },
  {
    name: 'Detalhe fracionado mantem botao Adicionar fixo no rodape',
    ok:
      app.includes('<ActionButton label="Adicionar"') &&
      /productModal:\s*\{[\s\S]{0,220}height:\s*'94%'[\s\S]{0,120}maxHeight:\s*'96%'/.test(app) &&
      /productModalBody:\s*\{[\s\S]{0,120}flex:\s*1[\s\S]{0,80}minHeight:\s*0/.test(app) &&
      /productModalOptions:\s*\{[\s\S]{0,80}flex:\s*1[\s\S]{0,80}minHeight:\s*0/.test(app) &&
      /modalFooter:\s*\{[\s\S]{0,80}flexShrink:\s*0[\s\S]{0,180}minHeight:\s*82/.test(app)
  },
  {
    name: 'Detalhe do produto nao corta observacao nem sabores',
    ok:
      app.includes('showsVerticalScrollIndicator') &&
      app.includes('keyboardShouldPersistTaps="handled"') &&
      app.includes('style={styles.fractionFlavorScroller}') &&
      app.includes('contentContainerStyle={styles.fractionFlavorRow}') &&
      app.includes('persistentScrollbar') &&
      app.includes('nestedScrollEnabled') &&
      app.includes('paddingBottom: spacing.xxl + 96') &&
      /fractionFlavorScroller:\s*\{[\s\S]{0,100}maxHeight:\s*88/.test(app) &&
      app.includes('width: 340') &&
      app.includes('height: 238')
  },
  {
    name: 'Detalhe do produto bloqueia lancamento acidental ao trocar item',
    ok:
      app.includes('PRODUCT_LAUNCH_ARM_DELAY_MS = 350') &&
      app.includes('productLaunchReady') &&
      app.includes('productLaunchArmTimerRef') &&
      app.includes('setProductLaunchReady(false)') &&
      app.includes('setProductLaunchReady(true)') &&
      app.includes('clearTimeout(productLaunchArmTimerRef.current)') &&
      app.includes('if (!productLaunchReady) return') &&
      app.includes('const canLaunch = productLaunchReady &&') &&
      app.includes('disabled={!canLaunch}')
  },
  {
    name: 'Envio do carrinho tem trava contra toque duplicado',
    ok: app.includes('sendingCart') && app.includes('if (sendingCart) return')
  },
  {
    name: 'URL da API e normalizada antes de salvar e consultar',
    ok:
      network.includes('normalizeApiBaseUrl') &&
      network.includes('shouldUseHttpForLocalAddress') &&
      api.includes('normalizeApiBaseUrl(this.baseUrl)') &&
      storage.includes('normalizeApiBaseUrl(value?.baseUrl')
  },
  {
    name: 'Android permite HTTP local para API interna',
    ok: appConfig.includes('"usesCleartextTraffic": true') && androidManifest.includes('android:usesCleartextTraffic="true"')
  },
  {
    name: 'Inputs verticais nao usam flex expansivo',
    ok: app.includes('containerStyle={styles.inputGroupGrid}') && !/^\s*inputGroup:\s*\{\s*flex:\s*1/m.test(app)
  },
  {
    name: 'App bloqueia voltar do Android para nao sair do cardapio',
    ok: app.includes('BackHandler.addEventListener') && app.includes('hardwareBackPress') && app.includes('() => true')
  },
  {
    name: 'Android abre em modo imersivo/kiosk sem barras do sistema',
    ok:
      mainActivity.includes('enterKioskMode') &&
      mainActivity.includes('startLockTaskSafely') &&
      mainActivity.includes('startLockTask()') &&
      mainActivity.includes('LOCK_TASK_MODE_LOCKED') &&
      mainActivity.includes('LOCK_TASK_MODE_PINNED') &&
      mainActivity.includes('onUserInteraction') &&
      mainActivity.includes('FLAG_KEEP_SCREEN_ON') &&
      mainActivity.includes('navigationBars') &&
      mainActivity.includes('SYSTEM_UI_FLAG_HIDE_NAVIGATION') &&
      androidManifest.includes('android:lockTaskMode="if_whitelisted"') &&
      !mainActivity.includes('moveTaskToBack')
  },
  {
    name: 'Android suporta Lock Task gerenciado para impedir desbloqueio por atalho',
    ok:
      mainActivity.includes('DevicePolicyManager') &&
      mainActivity.includes('setLockTaskPackages') &&
      mainActivity.includes('LOCK_TASK_FEATURE_NONE') &&
      mainActivity.includes('isDeviceOwnerApp') &&
      mainActivity.includes('LOCK_TASK_MODE_LOCKED') &&
      mainActivity.includes('isPinnedLockTaskActive') &&
      mainActivity.includes('lock task fixado nao sera iniciado') &&
      mainActivity.includes('if (!managedLockTaskReady)') &&
      androidManifest.includes('android.permission.BIND_DEVICE_ADMIN') &&
      androidManifest.includes('.TabletDeviceAdminReceiver') &&
      deviceAdminReceiver.includes('DeviceAdminReceiver') &&
      deviceAdminXml.includes('<device-admin')
  },
  {
    name: 'Configuracao exibe status real do modo kiosk seguro',
    ok:
      kioskModule.includes('getKioskStatus') &&
      kioskModule.includes('secureKiosk') &&
      kioskModule.includes('lockTaskMode') &&
      kioskModule.includes('isLockTaskPermitted') &&
      app.includes('refreshKioskStatus') &&
      app.includes('getKioskStatusPresentation') &&
      app.includes('Modo Kiosk Seguro') &&
      app.includes('Falta provisionar este tablet como Device Owner ou MDM') &&
      app.includes('Android esta em PINNED') &&
      app.includes('styles.kioskStatusCard') &&
      app.includes('label={checkingKioskStatus ?')
  },
  {
    name: 'Fechamento do app fica restrito a configuracao autorizada',
    ok:
      app.includes('label="Fechar APP"') &&
      app.includes("settingsAccessMode === 'waiter'") &&
      app.includes('NativeModules.TabletKiosk') &&
      app.includes('TabletKiosk?.exitApp') &&
      app.includes('BackHandler.exitApp') &&
      mainApplication.includes('add(TabletKioskPackage())') &&
      kioskModule.includes('stopLockTask()') &&
      kioskModule.includes('finishAndRemoveTask()')
  },
  {
    name: 'Layout do cardapio usa header imersivo e grid de tablet sem resumo duplicado',
    ok:
      app.includes('numColumns={4}') &&
      app.includes('variant="accent"') &&
      !app.includes('productToolbar') &&
      !app.includes('productCountBox') &&
      !app.includes('disponiveis')
  },
  {
    name: 'Tela principal nao abre teclado por busca de produto',
    ok: !app.includes('placeholder="Buscar produto"') && !app.includes('searchText')
  },
  {
    name: 'Imagem do detalhe do produto preserva proporcao',
    ok:
      app.includes('styles.modalImageFrame') &&
      app.includes('resizeMode="contain"') &&
      app.includes('styles.productModalBody') &&
      app.includes('styles.productModalPreview')
  },
  {
    name: 'Grade de produtos mantem imagens carregadas durante scroll',
    ok:
      imageCache.includes('Image.prefetch') &&
      imageCache.includes('prefetchProductImages') &&
      app.includes('PRODUCT_IMAGE_PREFETCH_LIMIT = 64') &&
      app.includes('windowSize={11}') &&
      app.includes('removeClippedSubviews={false}') &&
      !app.includes('pauseProductImages') &&
      !app.includes('resumeProductImages') &&
      !app.includes('deferProductImages') &&
      !app.includes('Carregando foto')
  },
  {
    name: 'Estados vazios tem layout proprio no cardapio, carrinho e pedido',
    ok:
      app.includes('renderEmptyState') &&
      app.includes('emptyStateIcon') &&
      app.includes('Nenhum produto nesta categoria') &&
      app.includes('Carrinho vazio') &&
      app.includes('Nenhum item enviado')
  },
  {
    name: 'Cards de produto usam hierarquia visual sem titulo preto pesado',
    ok:
      app.includes('formatProductCardTitle') &&
      app.includes('styles.productPricePill') &&
      app.includes('styles.productAddBadge') &&
      app.includes('color: colors.productTitle') &&
      !/productName:\s*\{[\s\S]{0,180}color:\s*colors\.text/.test(app)
  },
  {
    name: 'Categorias usam navegacao visual com contagem e indicador selecionado',
    ok:
      app.includes('categoryProductCounts') &&
      app.includes('styles.categoryInitial') &&
      app.includes('styles.categoryCountPill') &&
      app.includes('styles.categoryMeta') &&
      app.includes('formatItemCount')
  }
];

const failed = checks.filter((check) => !check.ok);

checks.forEach((check) => {
  console.log(`${check.ok ? 'OK' : 'FAIL'} - ${check.name}`);
});

if (failed.length > 0) {
  process.exitCode = 1;
}
