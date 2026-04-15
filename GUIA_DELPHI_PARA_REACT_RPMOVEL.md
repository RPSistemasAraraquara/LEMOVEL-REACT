# Guia Delphi -> React no RP MOVEL

## 1. Objetivo deste guia

Este documento foi escrito para quem já domina Delphi e está migrando para React/React Native.

A ideia aqui nao e apenas dizer "onde esta cada coisa", mas ajudar voce a fazer a traducao mental entre os dois mundos.

Quando um desenvolvedor Delphi abre este projeto React pela primeira vez, a sensacao comum e:

- "onde esta o form?"
- "onde esta o DataModule?"
- "quem segura o estado?"
- "quem chama a API?"
- "quem grava no banco?"
- "por que tanta funcao pequena?"

Este guia responde isso usando o proprio RP MOVEL como exemplo.

---

## 2. A traducao mental: Delphi x React

## 2.1 Form x Screen/Component

No Delphi, voce pensa em:

- `TFormLogin`
- `TFrmMesa`
- `TFrmFechamento`

No React Native, a equivalencia mais proxima e:

- `LoginScreen.tsx`
- `InitialScreen.tsx`
- `SaleClosureScreen.tsx`

Diferenca importante:

- no Delphi, o formulario costuma concentrar interface, estado e parte da regra;
- no React, a tela costuma ficar mais "leve", delegando boa parte da logica para hooks, contexto e servicos.

Entao:

- `Screen` no React = equivalente funcional do seu `Form`

---

## 2.2 DataModule x Context + Service

No Delphi, e comum ter:

- um `DataModule` com conexoes, consultas, metodos de negocio e estado compartilhado.

No React deste projeto, isso foi dividido em duas partes:

1. `AppContext.tsx`
   Isso segura estado global da aplicacao.

2. `api.ts`
   Isso faz o papel de camada de acesso HTTP, quase como um DataModule REST.

Traducao:

- `AppContext` = sessao/estado global do app
- `api.ts` = camada de comunicacao com backend

Se eu tivesse que explicar do jeito mais Delphi possivel:

- `AppContext` parece um `DataModule` de sessao do usuario + estado da interface
- `api.ts` parece um `DataModule` de integracao REST

---

## 2.3 Variavel de formulario x state

No Delphi, voce faria algo como:

```pascal
private
  FUsuario: string;
  FMesaAtual: Integer;
```

No React, isso normalmente vira:

```ts
const [user, setUser] = useState('');
const [activeTable, setActiveTable] = useState<TableOrder | null>(null);
```

A diferenca principal e:

- no Delphi, voce altera a variavel e normalmente atualiza a tela manualmente;
- no React, quando o `state` muda, a tela redesenha sozinha.

Entao:

- `useState` = campo com atualizacao reativa de interface

---

## 2.4 Campo privado x useRef

No Delphi, voce teria uma variavel privada para guardar algo sem precisar redesenhar a tela.

No React, isso costuma ser `useRef`.

Exemplo no projeto:

- `userRef`
- `activeTableRef`
- `lastDashboardRefreshAtRef`

Regra pratica:

- `useState` quando a interface precisa reagir
- `useRef` quando voce quer guardar valor sem forcar renderizacao

Se quiser uma analogia Delphi:

- `useRef` e parecido com um campo privado do form
- `useState` e parecido com um campo privado que ainda por cima "da refresh" automatico na tela

---

## 2.5 Evento de tela x useEffect

No Delphi voce esta acostumado com:

- `FormCreate`
- `FormShow`
- `OnClose`
- `OnDestroy`

No React, isso costuma ser modelado por `useEffect`.

Exemplo:

```ts
useEffect(() => {
  // carrega algo
}, []);
```

Esse `[]` significa "executa uma vez", parecido com um `FormCreate`.

Outro exemplo:

```ts
useEffect(() => {
  // reage quando user muda
}, [user]);
```

Isso significa:

- "toda vez que `user` mudar, execute este bloco"

No Delphi isso lembra:

- um observer manual
- ou um codigo que voce colocaria em setters/eventos

---

## 2.6 Units x modulos TS/JS

No Delphi:

- cada `.pas` define uma unit com classes/funcoes/tipos

No TypeScript:

- cada `.ts` ou `.tsx` define um modulo com funcoes, tipos e componentes

Exemplo:

- `api.ts` = unit de servicos HTTP
- `AppContext.tsx` = unit de estado global
- `LoginScreen.tsx` = unit de tela

---

## 2.7 DTO/Entity Delphi x types/interfaces TS

No Delphi, voce costuma ter:

- `TUsuario`
- `TVenda`
- `TProduto`

No TypeScript, isso costuma aparecer como:

- `type UserProfile = {...}`
- `type Sale = {...}`
- `type MenuItem = {...}`

Isso fica muito visivel em:

- `APPReact/src/services/api.ts`

Ali estao definidos muitos tipos que fazem o papel das entities do frontend.

---

## 3. Como o app sobe: do zero ate a tela

## 3.1 Ponto de entrada

Arquivo:

- `APPReact/index.js`

Conteudo principal:

- importa `App`
- chama `registerRootComponent(App)`

Se voce pensar em Delphi:

- isso lembra o inicio da aplicacao, antes de criar os forms principais

---

## 3.2 Componente raiz

Arquivo:

- `APPReact/App.tsx`

Estrutura:

1. `SafeAreaProvider`
2. `AppProvider`
3. `StatusBar`
4. `AppNavigator`

Traducao mental:

- `SafeAreaProvider` = suporte ao ambiente mobile
- `AppProvider` = "DataModule global" do app
- `AppNavigator` = controlador central de telas

Fluxo real:

1. o app inicia;
2. o contexto global e criado;
3. a navegacao e montada;
4. as telas passam a acessar esse contexto via `useApp()`.

---

## 3.3 Navegacao

Arquivo:

- `APPReact/src/navigation/AppNavigator.tsx`

Esse arquivo define:

- as rotas principais;
- a stack de navegacao;
- as tabs internas;
- o host global de alertas;
- parte da logica de abrir fechamento a partir da tab bar.

No Delphi, pense assim:

- `AppNavigator` = uma mistura de menu principal + roteador entre formularios

As rotas mais importantes sao:

- `Login`
- `Inicial`
- `Lancamento`
- `Fechamento`
- `Pagamento`
- `Configuracoes`
- `Sincronizar`

---

## 4. O papel do AppContext

Arquivo:

- `APPReact/src/context/AppContext.tsx`

Este e um dos arquivos mais importantes de todo o projeto.

Se eu tivesse que resumir em uma frase:

- `AppContext` e o "centro nervoso" do aplicativo mobile.

Ele cuida de:

- configuracao do servidor
- usuario logado
- listas de produtos/categorias
- dashboard de mesas/comandas
- carrinho
- mesa ativa
- refresh automatico
- login/logout
- sincronizacao
- abertura da venda
- envio de itens

## 4.1 O que e `createContext`

No React:

- `createContext` cria um canal global de dados

No projeto:

- `const AppContext = createContext<AppContextState | undefined>(undefined);`

Depois o hook:

- `useApp()`

permite fazer isto em qualquer tela:

```ts
const { user, refreshDashboard, openTableByCard } = useApp();
```

Traducao Delphi:

- em vez de acessar um DataModule global direto, a tela "consome" um contexto global

---

## 4.2 O que fica em state global

Em `AppProvider`, voce vai encontrar muito `useState`.

Exemplos:

- `baseUrl`
- `empresaId`
- `settingsReady`
- `user`
- `loading`
- `tables`
- `categories`
- `products`
- `activeTable`
- `cart`

Pense assim:

- tudo que varias telas precisam compartilhar vai para o contexto

No Delphi, isso e o tipo de coisa que muitos colocariam em:

- `DataModule`
- unit global
- singleton de sessao

---

## 4.3 O que sao os `useRef` do contexto

No `AppContext` existem varios `useRef`.

Exemplos:

- `userRef`
- `activeTableRef`
- `cartRef`
- `isSyncRunningRef`
- `lastDashboardRefreshAtRef`

Esses refs sao usados quando o valor:

- precisa persistir entre renders;
- mas nao precisa redesenhar a interface;
- ou precisa ser lido por callbacks assincronos sem "congelar" valor antigo.

Para quem vem do Delphi, isso e importante:

- closures em JS/TS podem capturar valor antigo;
- `ref.current` ajuda a pegar o valor mais novo sem rerender.

---

## 4.4 A funcao `login` no contexto

Funcao:

- `const login = async (loginParam: string, senha: string) => { ... }`

Fluxo:

1. ativa loading;
2. chama `api.login(loginParam, senha)`;
3. recebe `userProfile`;
4. salva em `setUser(userProfile)`;
5. salva configuracoes quando necessario;
6. chama `refreshDashboard()`;
7. retorna o usuario.

Pense em Delphi como:

- um metodo central de sessao que autentica e carrega o ambiente inicial

---

## 4.5 A funcao `refreshDashboard`

Essa funcao carrega as mesas/comandas e atualiza a tela inicial/gestao.

Ela e equivalente a algo como:

- "reconsultar o browse principal"

No Delphi, voce talvez faria:

- fechar query;
- reabrir query;
- atualizar grid;

No React:

- chama API;
- transforma dados;
- grava em `setTables(...)`;
- as telas reagem automaticamente.

---

## 4.6 A funcao `refreshMenu`

Essa funcao carrega:

- categorias
- produtos

Ela chama:

- `api.listCategories(...)`
- `api.listProducts(...)`

Depois salva em estado global.

Se voce quiser imaginar em Delphi:

- e como carregar o catalogo do sistema para memoria e depois bindar nas telas

---

## 4.7 A funcao `openTableByCard`

Essa funcao e importantissima para o fluxo de venda.

Ela decide:

- se vai abrir mesa ou comanda;
- se o nome digitado deve ir ou nao;
- se usa catraca;
- qual `idUsuario` deve ir na abertura.

Ela chama:

- `api.openTableByMode(...)`

E salva a mesa aberta como ativa em:

- `setActiveTable(...)`

No Delphi, isso e parecido com um metodo de abertura de atendimento que:

- chama o backend;
- recebe o id da venda;
- atualiza o form atual;
- deixa o contexto do atendimento pronto.

---

## 4.8 A funcao `flushPendingItems`

Essa e outra funcao central.

Ela:

1. pega o carrinho pendente;
2. garante que existe mesa/comanda ativa;
3. se a venda ainda nao existe, abre a venda;
4. converte itens com `asPayload`;
5. chama `api.launchItemsBatch(...)`;
6. limpa o carrinho;
7. faz `refreshDashboard()`.

Se voce programasse isso em Delphi, talvez fosse algo como:

```pascal
procedure TFrmLancaPedido.EnviarPendencias;
begin
  if VendaNaoExiste then
    AbrirVenda;

  MontarPayloadItens;
  EnviarItens;
  LimparCarrinho;
  AtualizarMesas;
end;
```

So que aqui isso esta organizado em funcoes menores e estado reativo.

---

## 5. A camada `api.ts`: o DataModule REST

Arquivo:

- `APPReact/src/services/api.ts`

Se existe um arquivo que um desenvolvedor Delphi vai reconhecer rapidamente em funcao, e este.

Ele concentra:

- tipos de dados do frontend
- parser dos objetos da API
- client HTTP
- cache
- login
- listagem de produtos/categorias/usuarios
- abertura de mesa/comanda
- consulta de venda
- lancamento de itens
- pre-fechamento
- fechamento
- pagamento parcial
- cancelamento de item

## 5.1 O que e a classe `ApiClient`

Trecho central:

- `export class ApiClient { ... }`

Ela e a classe que conversa com o backend.

No Delphi, lembre de algo como:

- uma classe de servicos REST
- ou um DataModule com metodos `CarregarProdutos`, `AbrirMesa`, `FecharVenda`

---

## 5.2 Como ela autentica

O app usa um header tecnico:

- `Authorization: Basic ...`

Isso e montado por:

- `getAuthorizationHeaderValue()`
- `authHeader()`

Depois a funcao `request(...)` sempre mistura:

1. `Content-Type`
2. `Authorization`
3. headers extras do endpoint

Isto e importante:

- o login do operador nao substitui a autenticacao tecnica;
- sao duas coisas separadas.

---

## 5.3 Como a API e chamada

Metodo central:

- `private async request(path, init)`

Ele:

1. monta URL completa;
2. mistura headers padrao com extras;
3. no Android tenta `fetch`;
4. em caso de erro transitorio pode cair para modulo nativo;
5. devolve `response` e `payload`.

Para quem vem de Delphi:

- isso e como centralizar toda comunicacao HTTP em um lugar so;
- em vez de cada tela fazer requisicao direta.

Isso e muito importante em React:

- tela nao deve sair chamando `fetch` desorganizado;
- a camada de servico precisa concentrar isso.

---

## 6. Fluxo detalhado do login

## 6.1 Tela

Arquivo:

- `APPReact/src/screens/LoginScreen.tsx`

Essa tela:

- exibe campos de usuario/senha;
- mostra status da API;
- permite abrir configuracao;
- redireciona para `Inicial` se ja existir usuario logado.

## 6.2 Sequencia do login

1. operador digita usuario e senha;
2. `onSubmit()` valida campos;
3. chama `checkApiConnection()`;
4. consulta informacoes da empresa;
5. verifica `utilizaRPMovel`;
6. chama `login(...)` do contexto;
7. contexto chama `api.login(...)`;
8. backend valida na tabela `usuarios`;
9. resposta volta como `UserProfile`;
10. `setUser(...)` atualiza o estado global;
11. navegacao vai para `Inicial`.

## 6.3 Backend do login

Controller:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.Usuario.pas`

DAO:

- `API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Usuario.pas`

Tabela:

- `usuarios`

Condicoes de validacao:

- empresa correta
- `trim(upper(usu_003)) = login`
- `usu_004 = senha`
- `sit_001 = 4`
- `b_funcao_garcom`

Em outras palavras:

- o sistema so autentica garcons/usuarios operacionais ativos

---

## 7. Fluxo detalhado de categorias e produtos

## 7.1 Categorias

Frontend:

- `api.listCategories()`

Endpoint:

- `GET /rpCheff/v1/empresa/{idEmpresa}/categoria`

Backend:

- `Controller.Categoria.Listar`
- `CategoriaDAO.Lista`

Tabela:

- `categoria`

Campos:

- `cat_001`
- `emp_001`
- `cat_002`
- `b_exibir_mobile`

## 7.2 Produtos

Frontend:

- `api.listProducts(exibirImagem, ...)`

Endpoint:

- `GET /rpCheff/v1/empresa/{idEmpresa}/produto?exibirImagem=true|false`

Backend:

- `Controller.Produto.ListarAtivos`
- `ProdutoDAO.Lista`

Tabela:

- `materiais`

Campos importantes:

- `mat_001`
- `cat_001`
- `mat_003`
- `mat_004`
- `mat_008`
- `imagem_db`

## 7.3 Como isso vai para a tela

Fluxo:

1. `refreshMenu()` chama categorias e produtos;
2. salva em contexto;
3. telas como `MenuScreen`, `ItemLaunchScreen` e `FractionLaunchScreen` leem do contexto;
4. a UI renderiza automaticamente.

No Delphi, o equivalente seria:

1. carregar datasets;
2. preencher listas;
3. refrescar controles.

A grande diferenca e:

- no React a UI reage ao estado;
- no Delphi normalmente voce manda a UI atualizar.

---

## 8. Fluxo detalhado da venda: do toque ate o banco

## 8.1 Ponto de entrada visual

A tela inicial e:

- `APPReact/src/screens/InitialScreen.tsx`

Ela exibe:

- mesas
- comandas
- filtros
- leitura por camera
- menu lateral

Ela consome do contexto:

- `tables`
- `refreshDashboard`
- `openTableByCard`
- `flushPendingItems`
- `user`

Ou seja:

- a tela nao "sabe tudo"
- ela usa o contexto para operar

---

## 8.2 Como a venda nasce

No RP MOVEL, a venda nasce quando mesa/comanda e aberta.

Frontend:

- `openTableByCard(...)`

Camada HTTP:

- `openTable(...)`
- `openComanda(...)`
- `openTableByMode(...)`

Endpoints:

- `POST /mesa/{idMesa}/abertura`
- `POST /comanda/{idComanda}/abertura`

Backend:

- `Controller.Mesa.AbrirMesa`
- `Controller.Comanda.AbrirComanda`
- `Service.Mesa.Abertura`
- `Service.Comanda.Abertura`
- `VendaDAO.Inserir`

Tabela criada:

- `venda`

## 8.3 O que a abertura grava

Na API, o service cria um objeto `TAPIRPCheffEntityVenda` e preenche:

- empresa
- data
- data abertura
- situacao pendente
- numero da mesa ou comanda
- tipo da venda
- terminal de abertura
- nome da mesa/comanda
- numero de pessoas
- caixa
- usuario da abertura

Depois chama:

- `VendaDAO.Inserir(...)`

## 8.4 Onde o usuario da abertura entra

Ponto crucial para entendimento:

- a API nao deduz esse usuario do login tecnico;
- ela usa o header HTTP `idUsuario`.

No backend:

- `Controller.Base.IdUsuario`

Esse metodo le:

- `FRequest.Headers['idUsuario']`

Depois:

- `Controller.Mesa.AbrirMesa` e `Controller.Comanda.AbrirComanda`
  passam isso para o service;
- o service faz `Result.venda.idUsuario := FIdUsuario`;
- o DAO grava em `usu_001_1`.

Essa e uma boa licao de arquitetura:

- no React voce precisa observar nao so o body da requisicao;
- muitas regras dependem de headers e contexto de chamada.

---

## 9. Fluxo detalhado do lancamento de itens

## 9.1 Tela de lancamento

Arquivos:

- `APPReact/src/screens/ItemLaunchScreen.tsx`
- `APPReact/src/screens/FractionLaunchScreen.tsx`

Essas telas:

- pegam produto selecionado;
- definem quantidade;
- tratam tamanhos;
- tratam opcionais;
- tratam observacoes;
- empurram o item para o carrinho.

## 9.2 O carrinho nao e a venda no banco

Esse ponto e muito importante para quem vem de Delphi.

No app:

- o carrinho e um estado local/global temporario;
- ele ainda nao e a gravacao definitiva no banco.

So quando `flushPendingItems()` roda e que os itens vao para a API.

Traducao Delphi:

- o carrinho e como uma estrutura em memoria antes do `Post/ApplyUpdates`

---

## 9.3 Como o payload do item e montado

Funcao:

- `asPayload(item)` em `AppContext.tsx`

Ela monta:

- `idProduto`
- `quantidade`
- `valorUnitario`
- `valorTotal`
- `desconto`
- `acrescimo`
- `tamanho`
- `descricaoTamanho`
- `observacao`
- `idMesaVinculada`
- `idGarcom`
- `opcionais`
- `fracoes`

## 9.4 Como os itens sao enviados

Funcao:

- `flushPendingItems()`

Passos:

1. pega `cartRef.current`;
2. verifica se existe `activeTable`;
3. se nao houver `idVenda`, abre a venda;
4. chama `api.launchItemsBatch(idVenda, itens)`;
5. limpa carrinho;
6. faz refresh.

API:

- `POST /venda/{idVenda}/item/lote`

Backend:

- `Controller.VendaItem.LancarItens`

No backend:

- cada item recebe `idEmpresa`
- cada item recebe `idVenda`
- se vier `idUsuario` no header, ele sobrescreve `idGarcom`

Tabela de destino:

- `vendaitem`

Tabela dos opcionais:

- `vendaitemopcional`

---

## 10. Fluxo detalhado da consulta da venda

## 10.1 No app

Metodo:

- `api.getSale(idVenda, listarItens)`

Endpoint:

- `GET /venda/{idVenda}`

Header:

- `listarItens`

## 10.2 Onde essa consulta e usada

Principalmente em telas de gestao e fechamento:

- `SaleManagerScreen.tsx`
- `SaleClosureScreen.tsx`

Essas telas usam a consulta para:

- carregar itens;
- carregar total;
- status;
- pagamentos parciais;
- situacao da mesa/comanda.

No Delphi, pense nisso como:

- abrir o mestre da venda + possiveis detalhes

---

## 11. Fluxo detalhado do pre-fechamento

Tela:

- `SaleClosureScreen.tsx`

Metodo frontend:

- `api.preCloseSale(...)`

Endpoint:

- `PATCH /venda/{idVenda}/preFechamento`

Backend:

- `Controller.Venda.ExecutarPreFechamento`
- `VendaDAO.PreFechamento`

O pre-fechamento:

- atualiza numero de pessoas;
- atualiza couverts;
- salva usuario do pre-fechamento;
- pode gerar conteudo de impressao;
- muda situacao da venda.

No banco, entram campos como:

- `usu_001_2`
- `imprimir_prefechamento_mobile`
- `pre_fech_mobile_imp_interna`

---

## 12. Fluxo detalhado do fechamento final

Tela:

- `SaleClosureScreen.tsx`

Essa tela e uma das mais complexas do projeto.

Ela trata:

- permissao do usuario;
- formas de pagamento;
- processamento em maquininha;
- validacoes de troco;
- taxa de servico;
- desconto;
- impressao;
- fechamento final.

## 12.1 Sequencia simplificada

1. usuario entra na tela com `idVenda`;
2. tela carrega dados da venda;
3. operador monta linhas de pagamento;
4. se a forma exige maquininha, processa antes;
5. consolida os pagamentos aprovados;
6. chama `api.closeSale(...)`;
7. backend fecha venda;
8. app imprime se necessario;
9. faz `refreshDashboard()`;
10. volta para a tela inicial.

## 12.2 Endpoint de fechamento

- `POST /venda/{idVenda}/fechamento`

Backend:

- `Controller.Venda.FecharVenda`

DAO:

- `VendaDAO.FinalizarVenda`

Alteracoes importantes na tabela `venda`:

- `id_usuario_fech`
- `sit_001 = 1`
- campos de impressao e visualizacao

---

## 13. Banco de dados: mapa minimo para voce se localizar

## 13.1 Usuarios

Tabela:

- `usuarios`

Campos que mais aparecem:

- `usu_001` = id
- `usu_002` = nome
- `usu_003` = login
- `usu_004` = senha
- `sit_001` = situacao

## 13.2 Categorias

Tabela:

- `categoria`

Campos:

- `cat_001`
- `cat_002`
- `b_exibir_mobile`

## 13.3 Produtos

Tabela:

- `materiais`

Campos:

- `mat_001`
- `mat_003`
- `mat_004`
- `mat_008`
- `imagem_db`

## 13.4 Venda principal

Tabela:

- `venda`

Campos muito importantes:

- `ven_001` = id venda
- `ven_025` = numero mesa
- `ven_026` = numero comanda
- `usu_001_1` = usuario abertura
- `usu_001_2` = usuario pre-fechamento
- `id_usuario_fech` = usuario fechamento
- `terminal_abertura`
- `nome_mesa_comanda`

## 13.5 Itens da venda

Tabela:

- `vendaitem`

## 13.6 Opcionais dos itens

Tabela:

- `vendaitemopcional`

## 13.7 Pagamentos parciais

Tabela:

- `venda_pag_antecipado`

---

## 14. Como ler um fluxo React sem se perder

Essa talvez seja a parte mais importante para sua migracao.

Quando voce pegar uma funcionalidade nova, siga esta ordem:

1. descubra a tela
2. veja o que ela pega de `useApp()`
3. veja que funcao do contexto ela chama
4. veja que metodo em `api.ts` essa funcao usa
5. veja o endpoint
6. abra o controller da API
7. veja se passa por service
8. termine no DAO
9. identifique a tabela SQL

Exemplo: abrir mesa

1. `InitialScreen`
2. `openTableByCard`
3. `api.openTableByMode`
4. endpoint `/mesa/{id}/abertura`
5. `Controller.Mesa.AbrirMesa`
6. `Service.Mesa.Abertura`
7. `VendaDAO.Inserir`
8. tabela `venda`

Isso funciona muito bem para praticamente todo o sistema.

---

## 15. Coisas que mais confundem quem vem do Delphi

## 15.1 "Nao estou vendo a classe da tela"

Porque em React moderno a tela normalmente e uma funcao:

```ts
export const LoginScreen: React.FC = () => { ... }
```

Em vez de:

```pascal
type
  TFrmLogin = class(TForm)
```

O componente funcional substitui a classe visual.

---

## 15.2 "Quem segura meus campos privados?"

Depende do caso:

- `useState` para refletir na UI
- `useRef` para nao refletir
- `Context` para compartilhar globalmente

---

## 15.3 "Onde esta o evento de clique?"

Em vez de `Button1Click`, voce encontra:

```tsx
<Pressable onPress={onSubmit}>
```

Ou:

```tsx
onPress={() => navigation.navigate('Fechamento')}
```

---

## 15.4 "Onde esta o AfterOpen/BeforePost?"

No React isso normalmente vira composicao de funcoes e efeitos:

- carregar dados = `useEffect`
- antes de enviar = validacoes em funcoes como `onSave`
- depois de enviar = `setState`, `refreshDashboard`, navegacao, alertas

---

## 15.5 "Por que tem tanta funcao pequena?"

Porque no ecossistema React e comum separar:

- renderizacao
- estado
- efeitos
- servico HTTP
- validacao
- navegacao

No Delphi, historicamente muita coisa acaba ficando dentro do form.

No React, se voce tentar colocar tudo em um componente so, a manutencao fica ruim muito rapido.

---

## 16. Uma forma pratica de estudar este projeto

Se eu estivesse te acompanhando na migracao, eu sugeriria estudar nesta ordem:

1. `APPReact/App.tsx`
2. `APPReact/src/navigation/AppNavigator.tsx`
3. `APPReact/src/context/AppContext.tsx`
4. `APPReact/src/services/api.ts`
5. `APPReact/src/screens/LoginScreen.tsx`
6. `APPReact/src/screens/InitialScreen.tsx`
7. `APPReact/src/screens/ItemLaunchScreen.tsx`
8. `APPReact/src/screens/SaleManagerScreen.tsx`
9. `APPReact/src/screens/SaleClosureScreen.tsx`

Depois disso, do lado da API:

1. `Controller.Usuario`
2. `Controller.Categoria`
3. `Controller.Produto`
4. `Controller.Mesa`
5. `Controller.Comanda`
6. `Controller.VendaItem`
7. `Controller.Venda`
8. `DAO.Usuario`
9. `DAO.Categoria`
10. `DAO.Produto`
11. `DAO.Venda`

---

## 17. Caso real deste projeto: o bug do garcom na abertura

Esse caso e um excelente exemplo para voce entender a arquitetura.

Problema observado:

- na primeira abertura da mesa/comanda, `usu_001_1` e `id_garcom_abertura` vinham nulos

Analise:

1. no banco, `VendaDAO.Inserir` grava `usu_001_1` com `AVenda.idUsuario`
2. no service de abertura, `Result.venda.idUsuario := FIdUsuario`
3. o controller de abertura alimenta `FIdUsuario` com `Self.IdUsuario`
4. `Self.IdUsuario` le o header HTTP `idUsuario`
5. o app abria mesa/comanda sem mandar esse header

Correcao:

- `AppContext.openTableByCard` passou o `idUsuario` do operador
- `api.openTable/openComanda` passaram a enviar o header `idUsuario`

Licao importante:

- em React/REST, o problema nem sempre esta na tela;
- muitas vezes a cadeia completa precisa ser seguida:
  tela -> contexto -> service frontend -> endpoint -> controller -> service backend -> DAO -> banco

Esse raciocinio e muito parecido com Delphi em camadas.

---

## 18. Conclusao

Voce nao esta saindo de um mundo "organizado" para um "baguncado".
Voce esta saindo de um modelo onde:

- a classe visual costuma concentrar mais responsabilidades

para um modelo onde:

- estado, interface, navegacao e servicos ficam mais separados.

Se eu resumir a transicao em uma frase:

- no Delphi voce navega muito por classes visuais e units de dados;
- no React voce navega por telas, contexto, hooks e servicos.

Depois que esse mapa mental encaixa, o projeto para de parecer "espalhado" e comeca a ficar bastante previsivel.

---

## 19. Proximo passo recomendado

O proximo documento que mais vai te ajudar, na minha opiniao, e um destes:

1. "Fluxo completo da mesa/comanda com diagrama"
2. "Mapa do banco com nome tecnico e significado de campos"
3. "Guia de React para quem programa eventos e formularios em Delphi"
4. "Como depurar no React Native sem sofrer"

Se quiser, eu posso fazer agora o proximo mais util:

- um guia de `useState`, `useEffect`, `useRef`, `useMemo` e `Context` usando exemplos reais deste projeto, quase como um mini-curso para quem vem de Delphi.
