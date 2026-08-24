# Validacao local - Cardapio Tablet

Data: 2026-08-23 / 2026-08-24

## Validado

- `npm run test:smoke`
  - TypeScript sem erros.
  - Checagem de regras do tablet aprovada.
- `npx expo prebuild --platform android --clean`
  - Projeto nativo Android gerado em `android/`.
- `android/gradlew.bat assembleRelease`
  - Build release Android concluido com sucesso.
- APK gerado:
  - `dist/CardapioTablet-1.0.0-homologacao-debugsigned.apk`
  - Tamanho: `56.778.507` bytes.
  - SHA-256: `EFF1E4AB9913581D889BBB8746D193CBA3985DC4EEB70A0CF40F3F7953FB7D75`
  - Package: `br.com.sistemalechef.cardapiotablet`
  - Version: `1.0.0` / versionCode `1`
  - minSdk: `24`
  - targetSdk: `36`
  - native-code: `arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64`
  - Assinatura APK v2: verificada.
  - Manifest final contem `android:usesCleartextTraffic="true"` para permitir API HTTP local.
- API local:
  - `http://192.168.15.35:9000/rpCheff/v1/ping` respondeu HTTP 200 com corpo `Online`.
  - No aparelho Android conectado por ADB, `curl -s -m 8 http://192.168.15.35:9000/rpCheff/v1/ping` respondeu `Online`.
  - `https://192.168.15.35:9000/rpCheff/v1/ping` falhou por SSL; por isso a configuracao local deve usar HTTP.
- Aparelho Android:
  - APK instalado com `adb install -r`.
  - Tela bloqueada abriu no pacote `br.com.sistemalechef.cardapiotablet`.
  - Tela `Liberar mesa` validada por captura real; labels, inputs e botoes alinhados.
  - Tela de cardapio validada por captura real em modo imersivo, sem barra superior/inferior do Android.
  - App nao inicia mais o modo de pinagem comum (`PINNED`), pois ele mostra a mensagem nativa `O aplicativo foi fixado` e ensina o atalho de saida ao cliente.
  - Abertura limpa validada por captura em `dist/cardapio-kiosk-no-pinning-message-clean.png`: a mensagem nativa de pinagem nao aparece.
  - `adb shell dpm list-owners` retornou `no owners` neste tablet; por isso o Android ainda nao permite o kiosk inviolavel.
  - `dumpsys activity` retornou `mLockTaskModeState=NONE` sem Device Owner. O estado esperado para homologacao final do bloqueio e `LOCK_TASK_MODE_LOCKED`.
  - Tela de configuracao passa a exibir o indicador `Modo Kiosk Seguro`, consultando o Android pelo modulo nativo. Neste tablet sem Device Owner, o estado esperado do indicador e `Inativo`.
  - Tela de cardapio validada por captura real apos refinamento visual dos cards de produto e categorias.
  - Tela de cardapio validada por captura final em `dist/cardapio-tablet-qa-final-clean.png`.
  - Tela de cardapio validada por captura real sem campo `Buscar produto`, evitando abertura do teclado na tela principal.
  - Tela de cardapio validada por captura real sem o resumo redundante `categoria / itens disponiveis / produtos`; a contagem permanece apenas no menu de categorias.
  - Abertura do app passa a sincronizar mesa e cardapio automaticamente; ao voltar para primeiro plano, o app executa nova sincronizacao com loading `Sincronizando mesa e cardapio...`.
  - Produtos usam titulo em formato de cardapio, azul-acinzentado mais suave, preco em selo verde, badge de adicionar e fallback de imagem discreto.
  - Detalhe do produto validado por captura real com imagem em frame proporcional (`resizeMode="contain"`), sem distorcao.
  - Detalhe do produto validado por captura final em `dist/cardapio-tablet-product-modal-final.png`.
  - Categorias usam inicial, contagem de itens, contador em selo e selecao em azul forte com contraste branco.
  - Botao `Configuracao` validado na tela do cardapio com destaque visual administrativo `ADM`; antes de alterar mesa, servidor, empresa ou terminal, o app exige usuario e senha do garcom.
  - Botao `Fechar APP` criado apenas na tela de configuracao autorizada; ao confirmar, o modulo nativo Android chama `stopLockTask()` e encerra a Activity.
  - Botao `Visualizar Pedido` validado por captura real; carrega os itens enviados da venda atual e permite somente visualizar, atualizar ou fechar a janela.
  - Tela `Pedido da Mesa` validada por captura real; itens aparecem em modo somente leitura, sem botao de remover/adicionar.
  - Tela de configuracao refinada em layout dividido, com resumo lateral, destaque de mesa e bloco de campos centralizado.
  - Tela `Autorizar configuracao` refinada em layout administrativo dividido, com resumo lateral da mesa/terminal, selo de autorizacao, painel de credenciais e rodape de acao.
  - Tela `Liberar mesa` refinada com o mesmo padrao profissional, area lateral de atendimento, destaque da mesa, painel de credenciais e acao principal preservada. Validada por TypeScript e regra automatizada; captura real depende de o tablet estar em estado bloqueado/sem mesa aberta.
  - Visual do cardapio revisado usando `APPReact` como referencia: paleta azul petroleo/laranja, topo claro com linha de destaque, botoes arredondados, categorias em cards e produtos com selo de preco em destaque.
  - Tela `Autorizar configuracao` validada por captura real apos refinamento final; resumo lateral passou a exibir o terminal completo sem truncar.
  - Tela de configuracao autorizada permite `Voltar` sem salvar, retornando ao cardapio quando a configuracao foi aberta a partir do atendimento.
  - Campos de usuario e senha das telas `Liberar mesa` e `Autorizar configuracao` iniciam vazios e nao reaproveitam a credencial digitada anteriormente.
  - Alertas operacionais substituidos por modal visual proprio do Cardapio Tablet, validado por captura em `dist/cardapio-custom-dialog-final.png`.
  - Banner redundante `Mesa 01 liberada.` removido da entrada no cardapio, validado por captura em `dist/cardapio-after-banner-removal.png`.
  - Rodape `CARDAPIO TABLET  Versão 1.0.0` adicionado nas telas `Configuracao do tablet`, `Liberar mesa` e `Liberar configuracao`; regra automatizada adicionada ao smoke test.
  - Falha de rede no envio passa a exibir `Falha no envio da rede, chame o Garcom.` sem expor `Network request failed` ao cliente.
  - O app passa a consultar `GET /rpCheff/v1/empresa/{idEmpresa}` e bloquear o cardapio quando `empresas.utiliza_cardapiotablet` nao estiver verdadeiro, exibindo `Modulo não habilitado`.
  - A flag `utilizaCardapioTablet` fica persistida nas configuracoes/diagnostico local sempre que a sincronizacao consulta a empresa.
  - Tela de configuracao ajustada com rolagem propria para alturas menores, mantendo diagnostico, botoes e rodape acessiveis.
  - Banners de rotina `Item adicionado ao carrinho`, `Produto fracionado adicionado ao carrinho` e sucesso de sincronizacao foram removidos; erros e eventos operacionais continuam visiveis.
  - Botao `BACK` enviado por ADB; o processo continuou ativo e a janela permaneceu focada no app.
- Expo local:
  - `http://localhost:8081` respondeu HTTP 200.
- ADB:
  - Dispositivo conectado: `RX2WA0279AK`.

## Observacoes

- O APK atual e de homologacao interna e esta assinado com certificado debug.
- O app esconde barras do sistema e bloqueia `BACK`. O Lock Task comum (`PINNED`) nao e mais iniciado, porque expõe o atalho de saida. Para impedir saida por qualquer metodo do Android, o tablet deve ser provisionado como Device Owner/MDM e entrar em `LOCKED`.
- O indicador `Modo Kiosk Seguro` na configuracao deve ser usado como criterio operacional: somente `Ativo` confirma bloqueio forte; `Inativo` ou `Inseguro` significa que ainda falta provisionamento do Android.
- Assinatura release oficial com keystore de producao exige aprovacao explicita do Rafael antes de reutilizar qualquer credencial.
- `npm audit --omit=dev` ainda aponta vulnerabilidades herdadas de Expo/Metro/PostCSS/image-size; a correcao indicada pelo npm exige `npm audit fix --force` com upgrade quebrante para Expo 57, entao nao foi aplicada.
- Homologacao real ainda precisa de tablet conectado/provisionado em Device Owner para validar `LOCK_TASK_MODE_LOCKED`; abertura de mesa, lancamento, fracionado, bloqueio em 10 segundos e regressao do `APPReact` seguem validaveis no fluxo atual.
