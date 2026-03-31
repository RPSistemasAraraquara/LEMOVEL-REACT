# RPCheff React Native - Fast Food (Expo)

Projeto migrado para React Native em `APPReact/ReactNative` com layout moderno (telas rápidas de operação, cardápio, gestão de mesa e fechamento).

## Como iniciar

1. Instalar dependências
```bash
cd "APPReact/ReactNative"
npm install
```

2. Iniciar Metro
```bash
npm start
```

3. Abrir no dispositivo
- Android: `npm run android`
- iOS: `npm run ios`
- Web: `npm run web`

## Telas migradas (fluxo principal completo)
- `src/screens/LoginScreen.tsx`
- `src/screens/InitialScreen.tsx` (painel inicial)
- `src/screens/HomeScreen.tsx` (mesas)
- `src/screens/MenuScreen.tsx` (cardápio)
- `src/screens/CartScreen.tsx` (carrinho)
- `src/screens/ItemLaunchScreen.tsx` (lançamento com tamanhos, quantidade decimal, observação, desconto/acréscimo e opcionais por tamanho)
- `src/screens/SaleManagerScreen.tsx` (gestão da venda ativa)
- `src/screens/SaleClosureScreen.tsx` (fechamento e split de pagamento)
- `src/screens/SalePaymentScreen.tsx` (pagamento parcial/antecipado)
- `src/screens/PaymentProgressScreen.tsx` (progresso de pagamento)
- `src/screens/TransferMergeScreen.tsx` (transferência e junção de mesas/vendas)
- `src/screens/PendingItemsScreen.tsx` (itens pendentes/ajustes)
- `src/screens/CouvertManagerScreen.tsx` (controle de couvert)
- `src/screens/ProductManagerScreen.tsx` (gestão de produtos)
- `src/screens/CategoryManagerScreen.tsx` (gestão de categorias)
- `src/screens/SettingsScreen.tsx` (configurações)
- `src/screens/SyncScreen.tsx` (sincronização com log)
- `src/services/api.ts` (cliente API Horse + fallback local)
- `src/navigation/AppNavigator.tsx` (stack + abas)
- `src/context/AppContext.tsx` (estado global)

## Rotas principais
- `Login`
- `Inicial`
- `Tabs` (`Mesas`, `Cardápio`, `Carrinho`, `Gestão`)
- `Lancamento`
- `Fechamento`
- `Pagamento`
- `PagamentoProgresso`
- `Transferencia`
- `JuntarMesa`
- `Produtos`
- `Categorias`
- `Sincronizar`
- `ItensPendentes`
- `Configuracoes`
- `Couvert`

## Como visualizar no Android Studio

### Opção 1 (mais rápida com Expo Go)
1. Abra o Android Studio e inicie um emulador Android.
2. No terminal:
```bash
cd "APPReact/ReactNative"
npm install
npm start
```
3. Com o Metro rodando, pressione `a`.
4. O app abre no emulador (Expo Go) e atualiza ao vivo.

### Opção 2 (projeto nativo no Android Studio)
1. Gere a pasta Android:
```bash
npx expo prebuild --platform android
```
2. Abra em Android Studio a pasta `APPReact/ReactNative/android`.
3. Selecione um device e clique **Run**.
4. Caso queira desenvolvimento com client nativo:
```bash
npx expo start --dev-client
```

## Endpoints esperados (API Horse)
- `POST /rpCheff/v1/empresa/{idEmpresa}/usuario/login`
- `GET /rpCheff/v1/empresa/{idEmpresa}/categoria`
- `GET /rpCheff/v1/empresa/{idEmpresa}/produto`
- `GET /rpCheff/v1/empresa/{idEmpresa}/mesa`
- `POST /rpCheff/v1/empresa/{idEmpresa}/mesa/{idMesa}/abertura`
- `GET /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}`
- `GET /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/pagamentoAntecipado`
- `POST /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/pagamento`
- `POST /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/fechamento`
- `PATCH /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/preFechamento`
- `PATCH /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/couvert`
- `PATCH /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/nome`
- `DELETE /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/item/{numeroItem}`
- `POST /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/item`
- `POST /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/item/lote`
- `POST /rpCheff/v1/empresa/{idEmpresa}/mesa/{idMesaOrigem}/transferencia/{idMesaDestino}`
- `POST /rpCheff/v1/empresa/{idEmpresa}/venda/{idVendaDestino}/juncao`
- `PATCH /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/reabertura`
- `GET /rpCheff/v1/empresa/{idEmpresa}/configuracaoMesa`
- `GET /rpCheff/v1/empresa/{idEmpresa}/configuracaoComanda`
- `GET /rpCheff/v1/empresa/{idEmpresa}/formaPagamento`
- `GET /rpCheff/v1/empresa/{idEmpresa}/usuario`

Se sua API estiver em outro host/porta, configure na tela de login (Base URL).
