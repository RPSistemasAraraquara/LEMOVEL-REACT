# Curso Rapido de React Para Delphiano no RP MOVEL

## 1. Objetivo deste material

Este documento foi feito para voce que:

- programa ha anos em Delphi;
- entende bem formulario, evento, DataModule, DAO e banco;
- mas ainda se sente leigo em React.

A proposta aqui e bem direta:

- pegar os conceitos do React;
- mostrar o equivalente mental em Delphi;
- e aplicar isso no fluxo real do seu sistema.

Nao e um guia generico de internet.
E um guia usando o codigo do RP MOVEL.

---

## 2. A pergunta mais importante: "como pensar em React sem me perder?"

Se voce pensar do jeito abaixo, muita coisa ja comeca a encaixar:

### Delphi

Normalmente voce pensa assim:

1. formulario abre
2. evento dispara
3. chama metodo
4. consulta DataModule/DAO
5. atualiza tela

### React

No React deste projeto, pense assim:

1. tela renderiza
2. hooks montam estado e efeitos
3. tela chama funcoes do contexto
4. contexto chama `api.ts`
5. `api.ts` chama a API Delphi
6. API passa por Controller -> Service -> DAO
7. resultado volta
8. o estado muda
9. a tela renderiza de novo automaticamente

Resumo de bolso:

- no Delphi, voce geralmente manda a tela atualizar
- no React, voce muda o estado e a tela se atualiza sozinha

---

## 3. Mapa do sistema inteiro

Antes de entrar em `useState`, `useEffect` e cia, grave este mapa:

### Frontend

- `APPReact/index.js`
- `APPReact/App.tsx`
- `APPReact/src/navigation/AppNavigator.tsx`
- `APPReact/src/context/AppContext.tsx`
- `APPReact/src/services/api.ts`
- `APPReact/src/screens/...`

### Backend

- `API/Fontes/Source/Controller/...`
- `API/Fontes/Source/Model/Service/...`
- `API/Fontes/Source/Model/DAO/...`

### Fluxo padrao

1. Tela React
2. `useApp()`
3. `AppContext`
4. `api.ts`
5. endpoint REST
6. Controller Delphi
7. Service Delphi
8. DAO Delphi
9. tabela do banco

Se voce seguir esse caminho, quase tudo fica rastreavel.

---

## 4. Como o aplicativo nasce

## 4.1 `index.js`

Arquivo:

- `APPReact/index.js`

Funcao:

- registra o componente raiz `App`.

Pense nisso como:

- o bootstrap da aplicacao

---

## 4.2 `App.tsx`

Arquivo:

- `APPReact/App.tsx`

Estrutura:

1. `SafeAreaProvider`
2. `AppProvider`
3. `StatusBar`
4. `AppNavigator`

Traducao para Delphi:

- `SafeAreaProvider`: suporte visual do ambiente mobile
- `AppProvider`: quase como um DataModule global da sessao
- `AppNavigator`: controlador central de formularios/telas

O ponto mais importante aqui:

- toda tela fica "embrulhada" pelo `AppProvider`
- por isso qualquer tela consegue usar `useApp()`

---

## 5. O que e `Context` na pratica

## 5.1 A ideia do Context

No React, `Context` serve para compartilhar estado e funcoes entre varias telas/componentes sem ficar passando parametro manual por toda a arvore.

No seu projeto:

- `APPReact/src/context/AppContext.tsx`

Ali existem:

- `createContext(...)`
- `AppProvider`
- `useApp()`

### Comparacao com Delphi

O `Context` aqui cumpre um papel muito parecido com:

- um DataModule global
- ou uma sessao global da aplicacao

So que com atualizacao reativa.

---

## 5.2 Como usar

Em qualquer tela:

```ts
const { user, refreshDashboard, openTableByCard } = useApp();
```

Isso significa:

- eu estou pegando dados e funcoes do contexto global

No Delphi seria parecido com:

```pascal
DMApp.UsuarioAtual
DMApp.RefreshDashboard
DMApp.AbrirMesa(...)
```

So que no React isso e mais controlado e reativo.

---

## 6. `useState`: o equivalente ao estado visual da tela

## 6.1 O que e

`useState` cria um valor que, quando muda, faz a tela renderizar de novo.

Exemplo da tela de login:

- `const [user, setUser] = useState(appSettings.usuario || '');`
- `const [senha, setSenha] = useState(appSettings.senha || '');`
- `const [error, setError] = useState('');`

### Traducao mental

No Delphi, isso lembra:

- campos privados do form
- mais a parte visual sendo atualizada automaticamente

Exemplo Delphi mental:

```pascal
FUsuario := EditUsuario.Text;
FSenha := EditSenha.Text;
LabelErro.Caption := '...';
```

No React:

- voce nao atribui direto no controle
- voce muda o state
- e o JSX redesenha a interface

---

## 6.2 Onde voce ve isso no sistema

### Login

- `LoginScreen.tsx`

Usa `useState` para:

- usuario digitado
- senha digitada
- erro
- informacoes da empresa

### Home / Initial

- `InitialScreen.tsx`
- `HomeScreen.tsx`

Usam `useState` para:

- modais
- filtros
- leitura de codigo
- tabela pendente para abrir

### Fechamento

- `SaleClosureScreen.tsx`

Usa `useState` para:

- numero de pessoas
- couverts
- desconto
- pagamentos
- preview
- mensagens de status

Ou seja:

- tudo que precisa aparecer/refletir visualmente costuma ser `useState`

---

## 7. `useEffect`: o equivalente aos ciclos de vida e eventos de mudanca

## 7.1 O que e

`useEffect` executa codigo quando:

- a tela monta;
- algum valor muda;
- ou a tela desmonta.

### Analogias com Delphi

`useEffect(..., [])`

- parecido com `FormCreate`

`useEffect(..., [user])`

- parecido com "quando usuario mudar, faca algo"

`return () => { ... }`

- parecido com `OnDestroy` ou limpeza de recurso

---

## 7.2 Exemplo real na tela de login

Em `LoginScreen.tsx` existem `useEffect` que:

1. sincronizam os campos da tela com `appSettings`
2. limpam erro quando a configuracao muda
3. carregam informacoes da empresa
4. redirecionam para `Inicial` quando `loggedUser` existir

Isso e muito importante para voce entender:

- no React, muita logica de "quando tal coisa mudar, faca isso" vai para `useEffect`

No Delphi, isso muitas vezes estaria:

- em eventos de tela
- em setters
- ou espalhado em varios pontos do form

---

## 7.3 Exemplo real no dashboard

Em `HomeScreen.tsx`:

- existe um `useEffect(() => { refreshDashboard(); }, []);`

Ou seja:

- quando a tela monta, ela carrega o dashboard

Em Delphi, isso lembraria:

- abrir query no `FormShow` ou `FormCreate`

---

## 8. `useRef`: o campo privado que nao renderiza

## 8.1 O que e

`useRef` guarda um valor entre renders sem redesenhar a tela quando ele muda.

Exemplos no projeto:

- `userRef`
- `activeTableRef`
- `cartRef`
- `lastDashboardRefreshAtRef`
- `isSyncRunningRef`

### Traducao mental

No Delphi, pense em:

- um campo privado de classe

Mas com uma diferenca:

- no React ele e muito usado para escapar de problemas de callback assincrono e valor "antigo"

---

## 8.2 Quando usar mentalmente

Use este raciocinio:

### Se precisa atualizar a interface

- `useState`

### Se precisa apenas guardar valor de apoio

- `useRef`

Exemplo bom do projeto:

- o usuario visivel vai em `user`
- mas tambem existe `userRef.current`

Por que?

- porque em funcoes assincronas longas e mais seguro ler `userRef.current` do que depender do valor fechado em uma closure antiga

---

## 9. `useMemo`: cache de calculo

## 9.1 O que e

`useMemo` memoriza um resultado para evitar recalculo desnecessario.

Exemplo em `MenuScreen.tsx`:

- categorias filtradas
- produtos agrupados por categoria
- colunas da grade
- lista filtrada

### Traducao mental

No Delphi, e como:

- fazer um cache calculado
- ou evitar refazer processamento toda vez que a tela repinta

No React, isso ajuda em listas grandes e telas pesadas.

---

## 9.2 Regra pratica

Nem tudo precisa de `useMemo`.

Use quando:

- o calculo e caro
- o resultado depende de algumas entradas especificas
- voce quer evitar refazer a conta em toda renderizacao

No projeto, ele aparece muito onde ha:

- filtro de produtos
- agrupamento de itens
- calculo de layout

---

## 10. `props`: parametros entre componentes

## 10.1 O que sao

`props` sao os parametros que um componente recebe de outro.

Exemplo mental em Delphi:

- parecido com passar parametros para um metodo
- ou preencher propriedades antes de dar `Show`

Exemplo:

```tsx
<MemoFoodCard item={item} onOpen={() => openLaunchScreen(item)} />
```

Aqui o componente `MemoFoodCard` recebe:

- `item`
- `onOpen`

---

## 10.2 Diferenca entre `props` e `Context`

### `props`

- para passar dados de pai para filho
- bom para componentes locais

### `Context`

- para dados globais
- bom para usuario, configuracao, mesa ativa, carrinho

No Delphi:

- `props` lembram parametros/propriedades
- `Context` lembra sessao global ou DataModule global

---

## 11. Renderizacao: o que significa "a tela renderizou"

Essa e uma das ideias mais importantes do React.

Renderizar significa:

- executar a funcao do componente
- recalcular o JSX
- atualizar a interface conforme o estado atual

No Delphi, muita gente imagina que a tela e "um objeto pronto" e vai mudando pedaços.

No React, a ideia e mais declarativa:

- dado o estado atual, qual tela deve aparecer?

Entao o componente descreve:

- "se loading, mostre spinner"
- "se user existe, navegue"
- "se erro existe, mostre erro"

Exemplo da tela de login:

- se `loading` for `true`, o botao mostra `ActivityIndicator`
- se `error` existir, aparece o texto de erro
- se `loggedUser` existir, ocorre a navegacao

---

## 12. Navegacao: equivalente a abrir formularios

## 12.1 Onde a navegacao e declarada

Arquivo:

- `APPReact/src/navigation/AppNavigator.tsx`

Ali estao as rotas:

- `Login`
- `Inicial`
- `Configuracoes`
- `Sincronizar`
- `Lancamento`
- `Fechamento`
- `Pagamento`
- etc

### Traducao Delphi

No Delphi seria algo como:

- um controlador central que decide quais formularios existem e como um leva ao outro

---

## 12.2 Como a navegacao funciona de verdade

Exemplo:

```ts
navigation.navigate('Configuracoes');
```

Ou:

```ts
navigation.navigate('Fechamento', {
  idVenda,
  idUsuario: user?.idUsuario
});
```

Isso equivale mentalmente a:

- abrir o proximo form passando parametros

---

## 12.3 Como o sistema decide que telas existem apos login

Em `AppNavigator.tsx`, existe esta logica:

- se `user` existe no contexto, o app adiciona as telas operacionais
- se nao existe, so a tela de login fica disponivel

Isso e muito importante.

Em outras palavras:

- a autenticacao nao so valida usuario
- ela muda a estrutura navegavel da aplicacao

No Delphi, isso seria parecido com:

- depois do login, carregar o menu principal e liberar formularios internos

---

## 13. Fluxo completo do login, detalhado do jeito que voce pediu

Agora vamos fazer o tipo de explicacao que ajuda de verdade:

"a tela X chama Y, que valida Z, que consulta tabela tal"

## 13.1 O operador abre a tela de login

Tela:

- `APPReact/src/screens/LoginScreen.tsx`

Ela exibe:

- campo usuario
- campo senha
- status da API
- botao entrar
- botao configuracoes

## 13.2 O operador clica em Entrar

Metodo:

- `onSubmit()`

Esse metodo faz:

1. limpa erro anterior
2. pega `user.trim()` e `senha.trim()`
3. se vazio, mostra `Informe usuario e senha`
4. chama `checkApiConnection()`

Ou seja:

- antes de tentar autenticar o operador, o app valida se a API esta acessivel

## 13.3 O app testa a conectividade da API

Isso acontece via contexto:

- `checkApiConnection()`

que por baixo usa:

- `api.testApiConnection()`

Se a API nao responder corretamente:

- o login para
- a tela mostra erro tecnico

## 13.4 A tela tambem valida a empresa

Ainda no login, o app consulta:

- `api.getCompanyInfo()`

E verifica:

- `utilizaRPMovel`

Se estiver falso:

- o sistema bloqueia entrada com a mensagem
  `Modulo RPMOVEL nao ativo`

Entao o login nao depende apenas de usuario e senha.
Tambem depende da empresa estar habilitada para o modulo mobile.

## 13.5 A tela chama o `login()` do contexto

Se passou nas validacoes acima, a tela faz:

- `await login(normalizedUser, normalizedPassword);`

Esse `login()` nao e o da API ainda.
Esse e o login do `AppContext`.

## 13.6 O contexto chama o login HTTP

Em `AppContext.tsx`, a funcao `login(...)` chama:

- `api.login(loginParam, senha)`

Agora sim vai para o backend.

## 13.7 O frontend faz POST no endpoint de login

Arquivo:

- `APPReact/src/services/api.ts`

Endpoint:

- `POST /rpCheff/v1/empresa/{idEmpresa}/usuario/login`

Body enviado:

```json
{
  "login": "usuario_digitado",
  "senha": "senha_digitada"
}
```

## 13.8 A API recebe no controller de usuario

Arquivo:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.Usuario.pas`

Metodo:

- `procedure Login;`

O controller:

1. le o JSON do body
2. cria `TAPIRPCheffEntityLogin`
3. chama `UsuarioDAO.Busca(login, senha)`

## 13.9 O DAO consulta a tabela `usuarios`

Arquivo:

- `API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Usuario.pas`

Metodo:

- `function Busca(ALogin, ASenha: string): TAPIRPCheffEntityUsuario;`

SQL de validacao:

- empresa correta
- login em `usu_003`
- senha em `usu_004`
- `sit_001 = 4`
- `b_funcao_garcom`

Traduzindo:

- a tabela e `usuarios`
- ele procura o usuario ativo
- da empresa atual
- com login e senha corretos
- e com permissao de funcao de garcom

Ou seja, respondendo exatamente ao seu exemplo:

- **a tela de login chama o contexto**
- **o contexto chama `api.login()`**
- **`api.login()` faz POST para `/usuario/login`**
- **o controller de usuario chama `UsuarioDAO.Busca()`**
- **o DAO faz select na tabela `usuarios`**
- **e ali verifica se o usuario existe, esta ativo e se `b_funcao_garcom` esta habilitado**

## 13.10 O usuario volta com permissoes

O DAO devolve campos como:

- `idUsuario`
- `nome`
- `login`
- `permiteCancelarItemMobile`
- `permitePreFechamentoMesaComanda`
- `permiteFechamentoMesaComanda`
- `permiteAlterarTaxa10`
- `permiteJuntarMesaComanda`
- `permiteReabrirMesaComanda`
- `permitePagamentoParcial`
- `permiteDescontoFechamento`

Entao:

- o login ja traz o perfil do operador e suas permissoes

## 13.11 O contexto salva o usuario

Quando o `api.login()` responde:

- o contexto faz `setUser(userProfile)`

E tambem:

- dispara `refreshDashboard()`

Ou seja:

- depois do login, o app ja carrega o ambiente inicial de trabalho

## 13.12 O AppNavigator muda as telas disponiveis

Como `user` passou a existir:

- `AppNavigator` passa a incluir `Inicial`, `Lancamento`, `Fechamento`, `Pagamento` etc

Entao:

- o login nao apenas "entra"
- ele muda quais telas a aplicacao disponibiliza

## 13.13 A tela de login redireciona

Em `LoginScreen.tsx`, existe um `useEffect` que observa `loggedUser`.

Se houver usuario:

- `navigation.reset({ routes: [{ name: 'Inicial' }] })`

Ou seja:

- depois do login, a tela manda para `Inicial`

---

## 14. Fluxo da tela inicial ate a abertura da venda

## 14.1 Tela inicial

Arquivo:

- `APPReact/src/screens/InitialScreen.tsx`

Ela usa do contexto:

- `tables`
- `refreshDashboard`
- `openTableByCard`
- `flushPendingItems`
- `user`
- `logout`

Essa tela:

- mostra as mesas/comandas
- permite filtro
- permite leitura por camera
- abre menu lateral
- abre configuracao/sincronizacao

## 14.2 O dashboard vem do contexto

Quem carrega mesas/comandas:

- `refreshDashboard()`

No React:

- a tela nao fala direto com a API
- ela usa o contexto

No Delphi isso seria parecido com:

- formulario principal chama um metodo central de sessao

## 14.3 Ao tocar numa mesa

Fluxo:

1. `InitialScreen` identifica a mesa/comanda clicada
2. chama `openTableByCard(...)`
3. se precisa nome, abre modal
4. se precisa vinculo com mesa, abre picker
5. senao chama abertura direto

## 14.4 O contexto decide como abrir

Em `AppContext.tsx`:

- `openTableByCard(...)`

Ela decide:

- se o modo e mesa
- se o modo e comanda
- se o modo depende do nome
- se usa catraca
- qual `idUsuario` enviar

Depois chama:

- `api.openTableByMode(...)`

## 14.5 O frontend chama a API de abertura

Em `api.ts`:

- `openTable(...)`
- `openComanda(...)`
- `openTableByMode(...)`

Endpoints:

- `POST /mesa/{idMesa}/abertura`
- `POST /comanda/{idComanda}/abertura`

Headers importantes:

- `idUsuario`
- `usaCatraca` quando necessario

Body:

- `terminalAbertura`
- `nomeMesaComanda` quando houver

## 14.6 O backend cria a venda

Controllers:

- `Controller.Mesa.AbrirMesa`
- `Controller.Comanda.AbrirComanda`

Services:

- `Service.Mesa.Abertura`
- `Service.Comanda.Abertura`

DAO:

- `VendaDAO.Inserir`

Tabela:

- `venda`

Entao:

- abrir mesa/comanda = criar registro na tabela `venda`

## 14.7 Onde entra o usuario da abertura

Controller base:

- `Controller.Base.IdUsuario`

Ele le:

- header `idUsuario`

Depois o service faz:

- `Result.venda.idUsuario := FIdUsuario`

E o DAO grava:

- `usu_001_1`

Por isso foi possivel corrigir o problema do garcom na abertura apenas garantindo o envio correto do header.

---

## 15. Fluxo do cardapio e lancamento de item

## 15.1 Tela de cardapio

Arquivo:

- `APPReact/src/screens/MenuScreen.tsx`

Ela usa:

- `categories`
- `products`
- `openTableByCard`
- `refreshMenu`
- `setActiveTable`
- `activeTable`

## 15.2 Quem carrega categorias e produtos

No contexto:

- `refreshMenu()`

No `api.ts`:

- `listCategories()`
- `listProducts()`

Na API:

- `Controller.Categoria.Listar`
- `Controller.Produto.ListarAtivos`

No banco:

- categorias -> `categoria`
- produtos -> `materiais`

## 15.3 Ao tocar num produto

`MenuScreen` chama:

- `openLaunchScreen(item)`

Essa funcao:

1. verifica se existe mesa ativa
2. verifica se a venda esta em status permitido
3. se necessario, reabre/atualiza a mesa ativa
4. navega para `Lancamento`

Entao aqui voce ve algo importante:

- React nao joga tudo na mesma tela
- ele navega para outra tela especializada no lancamento

## 15.4 Tela de lancamento

Arquivo:

- `APPReact/src/screens/ItemLaunchScreen.tsx`

Essa tela:

- recebe produto por parametro de rota
- ajusta quantidade
- tamanho
- opcionais
- observacao
- mesa vinculada

Depois:

- empurra item para o carrinho

Importante:

- o item ainda nao foi necessariamente para o banco nesse momento

---

## 16. Carrinho e envio dos itens

## 16.1 O carrinho nao e a tabela de venda

Esse ponto e essencial.

No app:

- carrinho = estado temporario

No banco:

- venda principal = `venda`
- itens = `vendaitem`

Entao:

- adicionar no carrinho nao e a mesma coisa que gravar `vendaitem`

## 16.2 Quem manda os itens de verdade

No `AppContext.tsx`:

- `asPayload(item)`
- `flushPendingItems()`

### `asPayload`

Transforma o item do carrinho em JSON da API:

- produto
- quantidade
- valor
- opcional
- fracao
- `idGarcom`

### `flushPendingItems`

Essa funcao:

1. pega os itens do carrinho
2. garante que existe mesa/comanda
3. garante que existe `idVenda`
4. chama `api.launchItemsBatch(idVenda, itens)`
5. limpa carrinho
6. atualiza dashboard

## 16.3 Endpoint que grava item

No `api.ts`:

- `launchItemsBatch(...)`

Endpoint:

- `POST /venda/{idVenda}/item/lote`

Na API:

- `Controller.VendaItem.LancarItens`

No banco:

- `vendaitem`
- `vendaitemopcional`

---

## 17. Fluxo da gestao da venda

## 17.1 Tela de gestao

Arquivo:

- `APPReact/src/screens/SaleManagerScreen.tsx`

Essa tela e como um painel do atendimento aberto.

Ela mostra:

- itens da venda
- total
- status
- garcom
- acoes de cancelar, pre-fechar, fechar, pagar parcialmente, juntar mesa, reabrir

## 17.2 Como ela protege as acoes por permissao

Exemplo real:

- antes de cancelar item:
  - verifica `user?.permiteCancelarItemMobile`

- antes de abrir pre-fechamento:
  - verifica `user?.permitePreFechamentoMesaComanda`

- antes de fechar:
  - verifica `user?.permiteFechamentoMesaComanda`

- antes de pagamento parcial:
  - verifica `user?.permitePagamentoParcial`

- antes de juntar mesas:
  - verifica `user?.permiteJuntarMesaComanda`

- antes de reabrir:
  - verifica `user?.permiteReabrirMesaComanda`

Ou seja:

- as permissoes trazidas no login sao aplicadas diretamente nas telas

Isso e uma licao importante:

- a permissao entra pelo login
- fica em `user`
- e cada tela confere antes de executar a acao

---

## 18. Fluxo do pre-fechamento e fechamento

## 18.1 Tela de fechamento

Arquivo:

- `APPReact/src/screens/SaleClosureScreen.tsx`

Ela trabalha em dois modos:

- `pre`
- `final`

Recebe pela rota:

- `idVenda`
- `idUsuario`
- `nomeMesaComanda`
- `tableType`
- `mode`

## 18.2 Pre-fechamento

Ao salvar pre-fechamento:

1. valida permissao
2. valida usuario
3. monta payload com pessoas/couvert/taxa
4. chama `api.preCloseSale(...)`
5. pode carregar preview de impressao
6. atualiza dashboard

Backend:

- `Controller.Venda.ExecutarPreFechamento`
- `VendaDAO.PreFechamento`

## 18.3 Fechamento final

Ao fechar:

1. valida permissao
2. valida usuario
3. processa formas de pagamento
4. se houver maquininha, processa antes
5. consolida pagamentos aprovados
6. chama `api.closeSale(...)`
7. backend fecha a venda
8. pode imprimir
9. atualiza dashboard
10. volta para `Inicial`

Backend:

- `Controller.Venda.FecharVenda`
- `VendaDAO.FinalizarVenda`

Tabela principal:

- `venda`

Campo importante:

- `id_usuario_fech`

---

## 19. Permissoes: onde nascem e onde sao usadas

## 19.1 Onde nascem

No backend, tabela:

- `usuarios`

DAO:

- `APIRPCheff.DAO.Usuario.pas`

Campos carregados:

- `b_permite_canc_item_mobile`
- `b_permite_prefechamento_mesa_comanda`
- `b_permite_fechamento_mesa_comanda`
- `b_permite_alterar_taxa10`
- `b_permite_juntar_mesa_comanda`
- `b_reabrir_mesa_comanda`
- `b_permite_pag_antecipado_mesa_comanda`
- `b_permite_desconto_fechamento_mesa_comanda`

## 19.2 Onde o frontend guarda

No objeto `user`, dentro do contexto.

## 19.3 Onde o frontend usa

Exemplos:

- `SaleManagerScreen.tsx`
- `SaleClosureScreen.tsx`
- `TransferMergeScreen.tsx`

Ou seja:

- permissao vem do banco
- passa pela API
- entra no login
- fica no contexto
- e e testada nas telas

---

## 20. Como estudar React neste sistema sem sofrimento

Use sempre este metodo de leitura:

### Passo 1

Ache a tela

### Passo 2

Veja o que ela pega de `useApp()`

### Passo 3

Veja o que ela faz em `onPress`, `onSave`, `onSubmit`, `useEffect`

### Passo 4

Siga para a funcao do contexto

### Passo 5

Siga para o metodo em `api.ts`

### Passo 6

Anote o endpoint

### Passo 7

Abra o Controller Delphi

### Passo 8

Se houver Service, siga para ele

### Passo 9

Termine no DAO e identifique a tabela

Exemplo de estudo:

#### Login

1. `LoginScreen`
2. `login()` do contexto
3. `api.login()`
4. `/usuario/login`
5. `Controller.Usuario.Login`
6. `DAO.Usuario.Busca`
7. tabela `usuarios`

#### Abrir mesa

1. `InitialScreen`
2. `openTableByCard`
3. `api.openTableByMode`
4. `/mesa/{id}/abertura`
5. `Controller.Mesa.AbrirMesa`
6. `Service.Mesa.Abertura`
7. `VendaDAO.Inserir`
8. tabela `venda`

#### Lancar item

1. `ItemLaunchScreen`
2. carrinho/contexto
3. `flushPendingItems`
4. `api.launchItemsBatch`
5. `/venda/{id}/item/lote`
6. `Controller.VendaItem.LancarItens`
7. tabelas `vendaitem` e `vendaitemopcional`

---

## 21. A diferenca mais importante entre o jeito Delphi e o jeito React

### No Delphi

Voce normalmente pensa:

- "qual evento do form vai fazer isso?"

### No React

Voce precisa pensar:

- "qual estado representa isso?"
- "quem e dono desse estado?"
- "quem precisa reagir quando ele muda?"

Esse e o pulo do gato.

Quando essa chave vira na cabeca, React deixa de parecer "estranho" e passa a parecer apenas outra forma de organizar fluxo.

---

## 22. Resumo final, em linguagem bem direta

Se eu te explicasse o sistema inteiro em poucas frases, eu diria assim:

1. `App.tsx` sobe o app
2. `AppProvider` cria a sessao global
3. `AppNavigator` decide as telas
4. `LoginScreen` autentica o operador
5. `AppContext` guarda usuario, mesas, carrinho e configuracoes
6. `api.ts` conversa com a API Delphi
7. `InitialScreen` mostra as mesas/comandas
8. `MenuScreen` mostra o cardapio
9. `ItemLaunchScreen` monta item e joga no carrinho
10. `flushPendingItems()` envia itens para a venda
11. `SaleManagerScreen` administra a venda aberta
12. `SaleClosureScreen` pre-fecha ou fecha a venda
13. a API Delphi valida, grava e consulta tudo no banco

---

## 23. Proximo passo ideal para voce

Agora que voce tem:

- a visao geral
- a documentacao tecnica
- o guia Delphi -> React
- e este mini-curso pratico

o melhor proximo passo e um material focado so em codigo React basico com exemplos reais do seu projeto:

- como ler um componente linha por linha
- como entender `return (...)`
- como funciona JSX
- por que `onPress={() => ...}` parece "estranho" para quem vem de Delphi
- como props e hooks se misturam

Se quiser, eu posso fazer esse proximo agora como:

- **"Aprendendo a ler um componente React do zero usando a LoginScreen e a InitialScreen"**

Esse provavelmente vai ser o material mais util para acelerar sua migracao.
