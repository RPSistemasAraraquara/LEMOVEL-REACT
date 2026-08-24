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
const appConfig = read('app.json');
const packageJson = read('package.json');
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
    name: 'Falha de conexao na abertura permite acessar configuracao protegida',
    ok:
      app.includes('API_RECONNECT_MESSAGE') &&
      app.includes('startupConnectionIssue') &&
      app.includes('retryStartupConnection') &&
      app.includes("openSettingsAuth('loading')") &&
      app.includes('Servidor sem resposta') &&
      app.includes('Verifique se o tablet esta na rede correta') &&
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
    name: 'Rodape das telas protegidas mostra Cardapio Tablet versao 1.0.0',
    ok:
      app.includes("APP_DISPLAY_NAME = 'CARDAPIO TABLET'") &&
      app.includes("APP_DISPLAY_VERSION = '1.0.0'") &&
      app.includes('Versão') &&
      app.includes('function AppFooter') &&
      (app.match(/<AppFooter \/>/g) || []).length >= 3 &&
      appConfig.includes('"version": "1.0.0"') &&
      packageJson.includes('"version": "1.0.0"') &&
      androidBuildGradle.includes('versionName "1.0.0"')
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
    name: 'Produto fracionado gera payload fracoes',
    ok: api.includes('fracoes: item.fracoes?.map') && app.includes('selectedFractionReady')
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
    name: 'Grade de produtos usa pre-cache e pausa imagens durante scroll',
    ok:
      imageCache.includes('Image.prefetch') &&
      imageCache.includes('prefetchProductImages') &&
      app.includes('pauseProductImages') &&
      app.includes('resumeProductImages') &&
      app.includes('deferProductImages') &&
      app.includes('removeClippedSubviews')
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
