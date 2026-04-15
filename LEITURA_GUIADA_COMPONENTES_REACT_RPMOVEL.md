# Leitura Guiada de Componentes React no RP MOVEL

## 1. Objetivo

Este documento e uma aula pratica para voce aprender a ler componentes React olhando o codigo real do seu sistema.

A ideia aqui e:

- pegar uma tela simples e importante: `LoginScreen`
- pegar uma tela mais rica e mais "React": `InitialScreen`
- explicar bloco por bloco
- mostrar o que e conceito React e o que e regra do sistema

Se voce ler esse material com os arquivos abertos no VS Code, vai render muito.

Arquivos-base desta aula:

- `APPReact/src/screens/LoginScreen.tsx`
- `APPReact/src/screens/InitialScreen.tsx`
- `APPReact/src/context/AppContext.tsx`

---

## 2. Antes de comecar: como ler um componente React

Quando abrir um arquivo `.tsx`, leia nessa ordem:

1. imports
2. tipos
3. declaracao do componente
4. hooks de estado (`useState`)
5. hooks de efeito (`useEffect`)
6. funcoes locais (`onSubmit`, `openMesa`, etc.)
7. `return (...)`
8. estilos

Se voce tentar ler de cima para baixo sem esse mapa, parece um monte de coisa misturada.

Com esse mapa, voce entende:

- o que entra
- o que a tela guarda
- o que a tela observa
- o que a tela faz
- o que a tela desenha

---

## 3. Leitura guiada da `LoginScreen`

Arquivo:

- `APPReact/src/screens/LoginScreen.tsx`

Essa tela e otima para aprender porque:

- e pequena
- tem `useState`
- tem `useEffect`
- consome `Context`
- navega para outra tela
- chama a API via contexto

---

## 3.1 Bloco de imports

Logo no topo voce ve:

```ts
import React, { useEffect, useState } from 'react';
```

Aqui ja aparece a primeira ideia importante:

- `React` = base do componente
- `useState` = estado visual da tela
- `useEffect` = efeitos/ciclo de vida

Depois entram componentes do React Native:

- `ActivityIndicator`
- `Image`
- `KeyboardAvoidingView`
- `Pressable`
- `ScrollView`
- `Text`
- `TextInput`
- `View`

### Comparacao com Delphi

Isso e como a lista de controles que voce vai usar no form:

- `TEdit`
- `TLabel`
- `TButton`
- `TPanel`
- `TImage`

So que aqui tudo entra por import.

Tambem entram:

- `useNavigation`
- `useApp`
- `RootStackParams`
- `Colors`, `Radius`, `Space`
- `api`, `applyCompanyPolicyToSettings`, `CompanyInfo`

Isso significa:

- a tela vai navegar
- vai usar o contexto global
- vai usar tipos de rota
- vai usar tema visual
- vai consultar empresa e politica de configuracao

---

## 3.2 Declaracao do componente

Trecho:

```ts
export const LoginScreen: React.FC = () => {
```

Traducao:

- esta sendo criado um componente funcional chamado `LoginScreen`

### Comparacao com Delphi

Pense como o equivalente a:

```pascal
type
  TFrmLogin = class(TForm)
```

A diferenca e:

- no React moderno, o componente costuma ser uma funcao, nao uma classe

---

## 3.3 Hook de navegacao

Trecho:

```ts
const navigation = useNavigation<NativeStackNavigationProp<RootStackParams, 'Login'>>();
```

Isso quer dizer:

- esta tela recebeu acesso ao sistema de navegacao
- ela pode abrir outras telas ou resetar a pilha

### Delphi mental

Pense como:

- um objeto que permite abrir outro formulario ou trocar de tela

Mais adiante a tela usa isso para:

- ir para `Configuracoes`
- resetar para `Inicial`

---

## 3.4 Hook do contexto global

Trecho:

```ts
const { appSettings, login, loading, apiConnection, checkApiConnection, saveAppSettings, user: loggedUser } = useApp();
```

Isso e MUITO importante.

Aqui a tela esta dizendo:

- "quero pegar coisas do `AppContext`"

Ou seja:

- `appSettings`: configuracoes do app
- `login`: funcao global de login
- `loading`: status de carregamento
- `apiConnection`: status da API
- `checkApiConnection`: funcao que testa a API
- `saveAppSettings`: grava configuracoes
- `loggedUser`: usuario atual do contexto

### Comparacao com Delphi

Isso lembra:

- acessar um DataModule ou sessao global

So que aqui a tela "consome" o contexto, em vez de acessar uma variavel global diretamente.

---

## 3.5 `useState` da tela de login

Trechos:

```ts
const [user, setUser] = useState(appSettings.usuario || '');
const [senha, setSenha] = useState(appSettings.senha || '');
const [error, setError] = useState('');
const [companyInfo, setCompanyInfo] = useState<CompanyInfo | null>(null);
```

Aqui a tela guarda 4 estados locais:

1. `user`
   O texto digitado no campo usuario.

2. `senha`
   O texto digitado no campo senha.

3. `error`
   Mensagem de erro mostrada na tela.

4. `companyInfo`
   Informacoes da empresa retornadas pela API.

### Delphi mental

Pense como:

- campos privados do formulario
- so que qualquer alteracao neles redesenha a interface

---

## 3.6 Primeiro `useEffect`: sincroniza campos com configuracao

Trecho:

```ts
useEffect(() => {
  setUser(appSettings.usuario || '');
  setSenha(appSettings.senha || '');
}, [appSettings.usuario, appSettings.senha]);
```

Traducao:

- sempre que `appSettings.usuario` ou `appSettings.senha` mudarem,
- atualize os campos locais da tela

### Por que isso existe?

Porque a tela pode abrir com configuracoes ja salvas.

Se o usuario alterou configuracao em outra tela e voltou:

- os campos precisam refletir isso

### Delphi mental

Isso seria parecido com:

- recarregar `EditUsuario.Text` e `EditSenha.Text` quando a configuracao for alterada

---

## 3.7 Segundo `useEffect`: limpa erro quando muda servidor/empresa

Trecho:

```ts
useEffect(() => {
  setError('');
}, [appSettings.baseUrl, appSettings.empresaId]);
```

Traducao:

- se o servidor ou empresa mudar, limpe a mensagem de erro

### Por que?

Porque um erro de login antigo pode nao fazer mais sentido depois que a configuracao tecnica foi trocada.

Isso e refinamento de UX.

---

## 3.8 Terceiro `useEffect`: carrega dados da empresa

Trecho resumido:

```ts
useEffect(() => {
  let active = true;

  const loadCompanyInfo = async () => {
    ...
    const company = await api.getCompanyInfo();
    ...
    setCompanyInfo(company);
    ...
    await saveAppSettings(normalizedSettings);
  };

  loadCompanyInfo().catch(() => null);

  return () => {
    active = false;
  };
}, [appSettings, saveAppSettings]);
```

Esse bloco e muito rico.

### O que ele faz?

1. consulta a empresa na API
2. salva em `companyInfo`
3. aplica a politica da empresa sobre configuracoes do app
4. se a tela desmontar antes da resposta voltar, evita atualizar estado

### O que e `let active = true`?

Isso e um truque comum no React para evitar atualizar estado depois que a tela saiu do ar.

No Delphi, seria equivalente a:

- "nao continue mexendo no form se ele ja foi destruido"

### O que e `return () => { active = false; }`?

Isso e a limpeza do efeito.

Quando a tela desmonta:

- `active` vira `false`

Entao, quando a promessa terminar, ela nao chama `setCompanyInfo` se a tela ja nao estiver mais ativa.

Isso e importante para evitar warning e bug.

---

## 3.9 Quarto `useEffect`: redireciona depois do login

Trecho:

```ts
useEffect(() => {
  if (loggedUser) {
    navigation.reset({
      index: 0,
      routes: [{ name: 'Inicial' }]
    });
  }
}, [loggedUser, navigation]);
```

Traducao:

- se houver usuario logado, reseta a navegacao e vai para `Inicial`

### O que e `navigation.reset`?

Nao e apenas navegar.

Ele limpa a pilha de navegacao e define `Inicial` como ponto atual.

### Por que isso e bom?

Porque o operador nao fica voltando para a tela de login com o botao "voltar".

### Delphi mental

Seria como:

- fechar a tela de login
- abrir a principal
- e impedir retorno acidental

---

## 3.10 Funcao `onSubmit`

Esse e o metodo mais importante da tela.

Trecho resumido:

```ts
const onSubmit = async () => {
  setError('');
  const normalizedUser = user.trim();
  const normalizedPassword = senha.trim();

  if (!normalizedUser || !normalizedPassword) {
    setError('Informe usuário e senha.');
    return;
  }

  const connection = await checkApiConnection();
  ...
  const currentCompanyInfo = companyInfo ?? (await api.getCompanyInfo().catch(() => null));
  ...
  await login(normalizedUser, normalizedPassword);
};
```

Vamos quebrar isso.

### Passo 1: limpa erro anterior

```ts
setError('');
```

### Passo 2: normaliza entrada

```ts
const normalizedUser = user.trim();
const normalizedPassword = senha.trim();
```

Isto remove espacos nas pontas.

### Passo 3: valida preenchimento

Se usuario ou senha estiverem vazios:

- mostra erro
- sai com `return`

### Passo 4: valida conexao da API

```ts
const connection = await checkApiConnection();
```

Se a API estiver com erro:

- mostra mensagem e aborta

### Passo 5: valida a empresa

```ts
const currentCompanyInfo = companyInfo ?? (await api.getCompanyInfo().catch(() => null));
if (currentCompanyInfo && currentCompanyInfo.utilizaRPMovel === false) {
  ...
}
```

Ou seja:

- mesmo com usuario e senha certos, o app ainda exige que a empresa esteja habilitada para o modulo mobile

### Passo 6: chama login do contexto

```ts
await login(normalizedUser, normalizedPassword);
```

Nao e a tela que autentica de verdade.

Ela apenas dispara o fluxo global de login.

### Delphi mental

Pense como:

- `BtnEntrarClick` validando campos e chamando um metodo central `Sessao.Login(...)`

---

## 3.11 Funcao `goConfig`

Trecho:

```ts
const goConfig = () => {
  navigation.navigate('Configuracoes');
};
```

Bem simples:

- abre a tela de configuracoes

### Delphi mental

Algo como:

- `FrmConfiguracoes.Show`

---

## 3.12 O `return (...)` da tela

Essa parte desenha a interface.

No React, o `return (...)` e como se voce estivesse dizendo:

- "com o estado atual, a tela deve ser assim"

### Principais blocos do layout

1. `KeyboardAvoidingView`
   Ajusta tela quando o teclado abre.

2. `ScreenRouteLabel`
   Componente auxiliar de rota.

3. elementos decorativos de fundo

4. `ScrollView`
   Permite rolagem da tela.

5. bloco de hero/logo

6. card do login

7. campos `TextInput`

8. erro condicional

9. status da API

10. botao entrar

11. botao configuracao

### O que e sintaxe como esta?

```tsx
{!!error && <Text style={styles.error}>{error}</Text>}
```

Isso significa:

- se `error` existir, renderize esse `Text`

No Delphi, equivaleria a:

- `LabelErro.Visible := Error <> '';`
- `LabelErro.Caption := Error;`

So que aqui isso esta descrito declarativamente no JSX.

---

## 4. Conclusao da `LoginScreen`

Se eu resumir a tela de login em uma frase:

- ela coleta dados locais, consome estado global, valida ambiente e dispara o login central da aplicacao

Entao ela nao e so "uma tela com dois edits".
Ela tambem:

- conversa com contexto
- conversa com navegacao
- observa configuracoes
- observa usuario logado
- aplica politica da empresa

---

## 5. Leitura guiada da `InitialScreen`

Agora vamos para uma tela mais "React de verdade".

Arquivo:

- `APPReact/src/screens/InitialScreen.tsx`

Essa tela ja mistura:

- muitos estados locais
- varios refs
- `useMemo`
- `useEffect`
- hooks customizados
- navegacao
- modais
- fluxo de leitura por camera
- abertura de mesa/comanda

Se voce entender essa tela, voce sobe muito de nivel.

---

## 5.1 Imports da `InitialScreen`

Logo no topo voce ve imports de:

- React Native
- navegacao
- `useApp`
- tipos
- componentes visuais
- hook customizado `useLinkedMesaBinding`

Isso ja diz bastante sobre a tela:

- ela nao e uma tela simples
- ela tem muita interacao
- ela usa logica compartilhada

### O que e um hook customizado?

`useLinkedMesaBinding` e um hook criado pelo projeto.

Pense nele como:

- uma mini-classe/ferramenta de logica reutilizavel

Em Delphi, poderia lembrar:

- uma unit de apoio especializada num fluxo

---

## 5.2 Tipos locais

A tela declara tipos como:

- `StackNav`
- `InitialRoute`
- `TableStatusGroup`
- `FilterItem`
- `BarcodeScanningResult`

No Delphi, isso equivale a:

- declarar enums, records e aliases na unit

Isso ajuda o TypeScript a dizer:

- quais valores sao validos
- quais campos cada objeto deve ter

---

## 5.3 Funcoes auxiliares fora do componente

Antes de `InitialScreen`, existem funcoes como:

- `getCameraViewComponent`
- `statusText`
- `getFilterPalette`
- `getTableSaleStatus`
- `getTableBaseStatus`
- `hasOpenSale`
- `isQuickLaunchTable`
- `isReservedTable`
- `resolveGroup`
- `statusLabel`

### Por que isso fica fora do componente?

Porque essas funcoes:

- nao dependem do estado interno da tela
- podem ser reaproveitadas
- deixam o componente principal mais organizado

### Delphi mental

Isso e como mover funcoes auxiliares para a secao `implementation` da unit, em vez de entupir o corpo do form.

---

## 5.4 Comeco da `InitialScreen`

Trecho:

```ts
export const InitialScreen: React.FC = () => {
  const navigation = useNavigation<StackNav>();
  const route = useRoute<InitialRoute>();
  const isFocused = useIsFocused();
```

Aqui a tela pega:

- objeto de navegacao
- parametros da rota
- informacao se a tela esta visivel em foco

### O que e `useIsFocused()`?

Serve para saber:

- se esta tela realmente esta ativa na navegacao agora

Isso ajuda a evitar carregar ou processar coisas quando a tela esta "escondida".

---

## 5.5 Consumo do contexto global

Trecho muito importante:

```ts
const {
  tables,
  appSettings,
  settingsReady,
  refreshDashboard,
  flushPendingItems,
  cart,
  user,
  logout,
  openTableByCard,
  initialScreenMode,
  setActiveTable,
  setInitialScreenMode,
  setLinkedMesaSelection
} = useApp();
```

Aqui a tela pega tudo que precisa para operar:

- mesas/comandas
- configuracao do app
- refresh
- carrinho
- usuario
- logout
- abertura de mesa
- mesa ativa
- vinculo com mesa

### Delphi mental

Essa tela esta "consultando o DataModule da sessao" para saber o estado atual da aplicacao.

---

## 5.6 `useState` local da tela

Essa tela tem muitos estados locais.

Exemplos:

- `menuOpen`
- `filterVisible`
- `filterText`
- `readerOpen`
- `readerText`
- `readerLoading`
- `openNameModalVisible`
- `openNameText`
- `pendingOpenTable`
- `pendingLinkedMesaOpen`
- `readerCameraOpen`
- `CameraViewComponent`
- `gridWidth`
- `selectedFilter`

### O que isso mostra?

Mostra uma coisa muito importante sobre React:

- nem todo estado deve ficar global

Regra pratica:

- estado so da tela = `useState` local
- estado compartilhado do sistema = `Context`

### Exemplo real

`menuOpen`

- so interessa a essa tela
- logo fica local

`user`

- interessa a varias telas
- logo fica no contexto

---

## 5.7 `useRef` da `InitialScreen`

A tela tambem tem varios refs:

- `autoSendRunningRef`
- `autoSendEnabledRef`
- `autoSendTimerRef`
- `cartCountRef`
- `tableOpenLockRef`
- `linkedMesaOpenAutoPromptRef`
- `lastWarningRef`
- `filterInputRef`
- `cameraBusyRef`
- `dashboardRefreshInFlightRef`

Isso costuma assustar quem vem de Delphi.

Mas pense assim:

- esses sao campos privados de apoio
- usados para controlar fluxo assincrono ou recurso temporario

Exemplos:

### `filterInputRef`

Referencia ao `TextInput`.

Lembra bastante:

- guardar referencia de um controle para focar nele depois

### `autoSendTimerRef`

Guarda `setTimeout`.

Em Delphi lembraria:

- guardar referencia de timer/controle de agendamento

### `tableOpenLockRef`

Impede reentrada/dupla abertura.

Em Delphi, seria parecido com:

- uma flag booleana privada do form

---

## 5.8 Configuracao do modo de exibicao

Trecho:

```ts
const configuredDisplayMode = appSettings.modoExibicao || 'mesa';
const [visibleMode, setVisibleMode] = React.useState<'mesa' | 'comanda'>(...);
```

Aqui temos um bom exemplo de mistura entre:

- configuracao global do app
- estado visual local da tela

`configuredDisplayMode`

- vem do contexto/configuracao

`visibleMode`

- representa como a tela esta mostrando agora

Isso e bem comum em React:

- parte vem do estado global
- parte vira estado local derivado

---

## 5.9 Hook customizado de vinculacao

Trecho:

```ts
const {
  bindingResolved,
  pickerVisible,
  pickerLoading,
  pickerTables,
  openPicker,
  closePicker,
  refreshPickerTables
} = useLinkedMesaBinding(...)
```

Isso quer dizer:

- a tela terceiriza uma parte da logica para um hook especializado

### Delphi mental

Seria como:

- colocar parte da regra numa unit auxiliar para o form nao ficar gigante

---

## 5.10 `useEffect` que sincroniza modo visivel

Esse efeito olha:

- `configuredDisplayMode`
- `initialScreenMode`
- `visibleMode`

e mantem tudo coerente.

Traducao:

- se a configuracao diz "comanda", a tela tem que ficar em comanda
- se diz "mesa", a tela tem que ficar em mesa
- se diz "mesaComanda", a tela acompanha o modo inicial

Isso e um exemplo excelente de `useEffect` reagindo a mudanca de dependencia.

### Delphi mental

Parece um bloco que voce chamaria sempre que a configuracao mudasse para atualizar o form.

---

## 5.11 `useMemo` de menuItems

Trecho:

```ts
const menuItems: FilterItem[] = React.useMemo(() => {
  ...
}, [isComandaMode]);
```

Isso calcula a lista de filtros:

- ocupadas
- livres
- todas
- reservadas

Mas:

- se estiver em modo comanda, `reservadas` nao entra

### O que voce aprende aqui?

`useMemo` e muito usado quando:

- ha uma lista derivada de outra informacao

No Delphi, voce talvez montaria essa lista dentro de um metodo chamado quando o modo mudasse.

Aqui o React recalcula automaticamente quando a dependencia mudar.

---

## 5.12 `useMemo` do layout

Trechos:

- `tableColumns`
- `cardWidth`

Esses blocos calculam quantas colunas cabem e qual largura os cards devem ter.

### Por que isso e React puro?

Porque a interface nao esta fixa.

Ela depende de:

- largura da tela
- largura do grid
- modo mesa/comanda

Entao o layout e derivado do estado.

---

## 5.13 `visibleTables`, `groupTotals` e `filteredTables`

Esses `useMemo` fazem o trabalho pesado de transformar a lista crua de mesas em algo pronto para a UI.

### `visibleTables`

Filtra por:

- modo configurado
- mesa ou comanda

### `groupTotals`

Agrupa e conta:

- todas
- ocupadas
- livres
- reservadas

### `filteredTables`

Aplica:

- filtro escolhido
- texto de pesquisa

### Delphi mental

Pense como:

- uma query em memoria
- ou listas filtradas/calculadas antes de preencher grid

---

## 5.14 Funcoes de leitura e abertura

A `InitialScreen` tambem tem funcoes como:

- parsear texto de QR/mesa
- abrir mesa digitando nome
- abrir via vinculo
- confirmar leitura

Isso mostra outra caracteristica forte de React:

- muitas acoes locais ficam como funcoes internas do componente

No Delphi isso costuma ficar como:

- metodos do form

Nesse ponto a semelhanca e grande.

---

## 5.15 Relacao da `InitialScreen` com o contexto

Essa tela nao grava diretamente no banco.

Ela aciona o fluxo assim:

1. operador toca na mesa
2. `InitialScreen` chama `openTableByCard`
3. `openTableByCard` esta no `AppContext`
4. o contexto chama `api.openTableByMode`
5. `api.ts` faz o POST REST
6. a API Delphi cria a venda na tabela `venda`
7. o retorno volta
8. a tela ativa essa mesa e navega

Esse e um ponto central para entender React:

- a tela normalmente orquestra o fluxo
- mas quem executa a regra mais central costuma ser contexto + servico

---

## 5.16 O `return (...)` da `InitialScreen`

A parte visual da tela e grande, mas a chave de leitura e esta:

o `return` apenas descreve a interface com base no estado atual.

Entao, dependendo do estado:

- modal aparece ou nao
- lista muda
- filtro muda
- botoes mudam
- cards mudam

No Delphi, voce esta acostumado a:

- mudar propriedades dos controles

No React, a logica costuma ser:

- se `menuOpen` for true, mostre a camada do menu
- se `readerOpen` for true, mostre o leitor
- se `filteredTables` mudou, a lista desenhada muda junto

---

## 6. Onde a `LoginScreen` se conecta com o resto do sistema

Agora vamos amarrar o fluxo completo em linguagem simples.

### Passo 1

`LoginScreen` coleta usuario e senha

### Passo 2

ela chama `checkApiConnection()`

### Passo 3

ela consulta `api.getCompanyInfo()`

### Passo 4

ela chama `login()` do contexto

### Passo 5

o contexto chama `api.login()`

### Passo 6

`api.login()` faz POST em:

- `/rpCheff/v1/empresa/{idEmpresa}/usuario/login`

### Passo 7

o backend Delphi vai para:

- `Controller.Usuario.Login`
- `DAO.Usuario.Busca`

### Passo 8

o DAO faz select na tabela:

- `usuarios`

### Passo 9

se o usuario for valido:

- o contexto faz `setUser(...)`

### Passo 10

`AppNavigator` passa a liberar as telas internas

### Passo 11

`LoginScreen` redireciona para `Inicial`

Entao o encadeamento que voce queria, bem direto, e este:

- **LoginScreen -> AppContext.login -> api.login -> endpoint /usuario/login -> Controller.Usuario -> DAO.Usuario -> tabela usuarios**

---

## 7. Como estudar os proximos componentes sozinho

Depois deste documento, use sempre este metodo:

### Etapa 1

Abra os imports e veja:

- a tela navega?
- usa contexto?
- usa API direta?
- usa hook customizado?

### Etapa 2

Ache:

- `useState`
- `useRef`
- `useEffect`
- `useMemo`

### Etapa 3

Pergunte:

- o que e estado visual?
- o que e campo privado?
- o que e efeito?
- o que e calculo derivado?

### Etapa 4

Leia as funcoes de evento:

- `onSubmit`
- `onSave`
- `openMesa`
- `confirmOpenWithName`

### Etapa 5

So depois leia o `return (...)`

Se fizer isso, o componente para de parecer "embaralhado".

---

## 8. Conclusao

Se voce entendeu bem estas duas telas, voce ja aprendeu o principal do React no seu sistema:

- `LoginScreen` te ensina o fluxo basico de estado, efeito, contexto e navegacao
- `InitialScreen` te ensina um componente mais realista, com filtros, layout dinamico, refs, memos e interacao com o contexto

Em resumo:

- `useState` guarda o que a tela mostra
- `useEffect` reage a mudancas e ciclo de vida
- `useRef` guarda apoio sem renderizar
- `useMemo` evita recalculo
- `Context` compartilha estado global
- `props` passam dados entre componentes
- `navigation` troca telas
- `return (...)` desenha a UI com base no estado

---

## 9. Proximo passo ideal

Agora o melhor proximo material e este:

- **leitura guiada da `SaleManagerScreen` e da `SaleClosureScreen`**

Porque ai voce vai aprender:

- lista de itens
- permissoes por usuario
- pagamentos
- pre-fechamento
- fechamento
- validacoes de negocio

Ou seja:

- o coracao operacional do sistema

Se quiser, eu faco isso agora no mesmo formato de aula guiada.  
