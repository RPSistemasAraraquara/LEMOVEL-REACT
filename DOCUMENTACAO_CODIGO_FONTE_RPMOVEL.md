# Documentação do Código-Fonte RP MOVEL

## 1. Visão geral da arquitetura

Este projeto é dividido em duas partes principais:

1. `APPReact/`
   Frontend mobile em React Native/Expo.

2. `API/Fontes/Source/`
   Backend em Delphi usando Horse/GBSwagger.

Na prática, o fluxo é este:

1. O usuário interage com uma tela React Native.
2. A tela usa `useApp()` para acessar o estado global do aplicativo.
3. O `AppContext` chama a camada HTTP em `APPReact/src/services/api.ts`.
4. `api.ts` consome endpoints REST da API Delphi.
5. A API passa pelo `Controller`, segue para `Service` quando há regra de negócio, e termina no `DAO`.
6. O `DAO` executa SQL nas tabelas do banco.

---

## 2. Onde ficam as partes principais no app

### 2.1 Tela de login

Arquivo:

- `APPReact/src/screens/LoginScreen.tsx`

Responsabilidade:

- renderiza os campos de usuário e senha;
- valida preenchimento básico;
- testa conectividade da API;
- consulta dados da empresa;
- chama o login real via contexto;
- redireciona para a tela inicial quando o usuário é autenticado.

Pontos principais:

- `LoginScreen` pega `login`, `checkApiConnection`, `saveAppSettings`, `user` e `appSettings` do contexto.
- O método `onSubmit`:
  - valida se usuário e senha foram digitados;
  - chama `checkApiConnection()`;
  - bloqueia acesso se a API estiver indisponível;
  - consulta `api.getCompanyInfo()` para validar se `utilizaRPMovel` está ativo;
  - por fim chama `login(normalizedUser, normalizedPassword)`.

Trechos importantes:

- frontend de login: `APPReact/src/screens/LoginScreen.tsx`
- função de login do contexto: `APPReact/src/context/AppContext.tsx`
- login HTTP: `APPReact/src/services/api.ts`

---

### 2.2 Contexto global do aplicativo

Arquivo:

- `APPReact/src/context/AppContext.tsx`

Esse é o coração do app mobile.

Ele concentra:

- usuário logado;
- configurações do app;
- catálogo;
- mesas/comandas;
- carrinho;
- mesa ativa;
- sincronização;
- abertura de venda;
- lançamento de itens;
- refresh de dashboard.

Funções importantes:

- `login`
- `logout`
- `refreshDashboard`
- `refreshMenu`
- `openTableByCard`
- `flushPendingItems`
- `asPayload`

### 2.3 Navegação

Arquivo:

- `APPReact/src/navigation/AppNavigator.tsx`

Responsabilidade:

- define todas as rotas do app;
- liga a tela de login, inicial, cardápio, gestão, fechamento, pagamento e demais fluxos.

Rotas principais:

- `Login`
- `Inicial`
- `Lancamento`
- `LancamentoFracionado`
- `Fechamento`
- `Pagamento`
- `PagamentoProgresso`
- `Configuracoes`
- `Sincronizar`

---

## 3. Como o login funciona

## 3.1 No frontend

Fluxo:

1. `LoginScreen.tsx` chama `onSubmit`.
2. `onSubmit` chama `checkApiConnection()`.
3. Se a API estiver ok, chama `login()` do contexto.
4. O `login()` do contexto chama `api.login(loginParam, senha)`.
5. A resposta vira `userProfile`.
6. Esse usuário é salvo em `setUser(userProfile)`.
7. O app faz `refreshDashboard()`.
8. O `LoginScreen` detecta `loggedUser` e navega para `Inicial`.

Arquivos:

- `APPReact/src/screens/LoginScreen.tsx`
- `APPReact/src/context/AppContext.tsx`
- `APPReact/src/services/api.ts`

## 3.2 Na camada HTTP do app

Arquivo:

- `APPReact/src/services/api.ts`

Função principal:

- `async login(login: string, senha: string): Promise<UserProfile>`

Endpoint chamado:

- `POST rpCheff/v1/empresa/${idEmpresa}/usuario/login`

Body enviado:

```json
{
  "login": "usuario",
  "senha": "senha"
}
```

Observação importante:

- além do login do operador, o app também usa autenticação básica fixa para falar com a API, montada em:
  - `getAuthorizationHeaderValue()`
  - `authHeader()`

Ou seja, existem duas camadas:

1. autenticação técnica da API via header `Authorization: Basic ...`
2. autenticação de operador via endpoint `/usuario/login`

## 3.3 Na API Delphi

Controller:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.Usuario.pas`

Método:

- `procedure Login;`

Fluxo:

1. lê o JSON do corpo em `TAPIRPCheffEntityLogin`;
2. chama `UsuarioDAO.Busca(login, senha)`;
3. se não achar usuário, responde erro;
4. se achar, devolve `TAPIRPCheffEntityUsuario`.

## 3.4 Como valida usuário de verdade

DAO:

- `API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Usuario.pas`

Método:

- `function Busca(ALogin, ASenha: string): TAPIRPCheffEntityUsuario;`

SQL de validação:

- tabela: `usuarios`
- campos usados:
  - `emp_001`
  - `usu_003` = login
  - `usu_004` = senha
  - `sit_001 = 4`
  - `b_funcao_garcom`

Isso significa que o login só aceita:

- usuário ativo;
- da empresa correta;
- com login e senha válidos;
- marcado como garçom/operador permitido para esse fluxo.

Campos carregados no usuário:

- `usu_001` -> `idUsuario`
- `usu_002` -> nome
- `usu_003` -> login
- permissões de cancelamento, pré-fechamento, fechamento, desconto, junção, reabertura e pagamento parcial

---

## 4. Onde o app chama categorias

## 4.1 No frontend

Arquivo:

- `APPReact/src/services/api.ts`

Método:

- `async listCategories(...)`

Endpoint:

- `GET rpCheff/v1/empresa/${idEmpresa}/categoria`

Uso principal:

- `AppContext.refreshMenu()`

Arquivo que dispara o carregamento:

- `APPReact/src/context/AppContext.tsx`

Fluxo:

1. `refreshMenu()` chama `api.listCategories()`;
2. o retorno é convertido para o tipo `Category`;
3. o contexto salva em `setCategories(...)`;
4. telas de cardápio e lançamento usam essas categorias para exibir filtros.

## 4.2 Na API

Controller:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.Categoria.pas`

Método:

- `procedure Listar;`

DAO:

- `API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Categoria.pas`

Método:

- `function Lista: TObjectList<TAPIRPCheffEntityCategoria>;`

## 4.3 Tabela do banco de categorias

Tabela:

- `categoria`

Campos relevantes:

- `cat_001` -> id da categoria
- `emp_001` -> empresa
- `cat_002` -> descrição
- `b_exibir_mobile` -> se pode aparecer no app
- `sit_001 = 4` -> ativo

Resumo:

- quando você perguntou “como chama a tabela categoria”, a resposta do banco é:
  - **tabela `categoria`**

---

## 5. Onde o app chama produtos

## 5.1 No frontend

Arquivo:

- `APPReact/src/services/api.ts`

Métodos principais:

- `async listProducts(exibirImagem = true, ...)`
- `buildProductImageUrl(...)`
- `getProductImageSource(...)`

Endpoints:

- `GET rpCheff/v1/empresa/${idEmpresa}/produto?exibirImagem=true|false`
- `GET rpCheff/v1/empresa/${idEmpresa}/produto/${idProduto}/imagem`

Uso principal:

- `AppContext.refreshMenu()` busca produtos e categorias juntos.

Arquivos envolvidos:

- `APPReact/src/context/AppContext.tsx`
- `APPReact/src/screens/MenuScreen.tsx`
- `APPReact/src/screens/ItemLaunchScreen.tsx`
- `APPReact/src/screens/FractionLaunchScreen.tsx`

## 5.2 Na API

Controller:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.Produto.pas`

Métodos:

- `ListarAtivos`
- `Buscar`
- `BuscarImagem`
- `ListarPorCategoria`

DAO:

- `API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Produto.pas`

Métodos:

- `Lista`
- `Lista(AIdCategoria)`
- `Buscar`
- `BuscarImagem`

## 5.3 Tabela do banco de produtos

Tabela principal:

- `materiais`

Isso responde a sua pergunta “como chama a tabela produtos”:

- **tabela `materiais`**

Campos importantes mapeados pelo DAO:

- `mat_001` -> id do produto
- `cat_001` -> id da categoria
- `mat_003` -> descrição
- `mat_004` -> código de referência
- `mat_008` -> valor base
- `imagem_db` -> imagem
- `sit_001 = 4` -> produto ativo

Observações:

- o DAO ainda busca opcionais do produto por outro DAO;
- existe compactação de imagem para JPEG/base64 no backend para reduzir custo no app.

---

## 6. Onde a venda nasce no sistema

No RP MOVEL, a venda normalmente não nasce por um endpoint “criar venda” genérico.
Ela nasce quando o usuário abre uma mesa ou uma comanda.

Arquivos do app:

- `APPReact/src/context/AppContext.tsx`
- `APPReact/src/services/api.ts`

Métodos principais:

- `openTableByCard(...)` no contexto
- `openTable(...)` em `api.ts`
- `openComanda(...)` em `api.ts`
- `openTableByMode(...)` em `api.ts`

Endpoints:

- `POST /rpCheff/v1/empresa/{idEmpresa}/mesa/{idMesa}/abertura`
- `POST /rpCheff/v1/empresa/{idEmpresa}/comanda/{idComanda}/abertura`

Controllers:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.Mesa.pas`
- `API/Fontes/Source/Controller/APIRPCheff.Controller.Comanda.pas`

Services:

- `API/Fontes/Source/Model/Service/Mesa/Abertura/APIRPCheff.Service.Mesa.Abertura.pas`
- `API/Fontes/Source/Model/Service/Comanda/Abertura/APIRPCheff.Service.Comanda.Abertura.pas`

O que esses services fazem:

- validam empresa;
- verificam se a mesa/comanda está disponível;
- criam um `TAPIRPCheffEntityVenda`;
- preenchem:
  - empresa;
  - número da mesa ou comanda;
  - data;
  - situação pendente;
  - usuário de abertura;
  - caixa;
  - terminal de abertura;
  - nome da mesa/comanda;
- chamam `VendaDAO.Inserir(...)`.

---

## 7. Como chama a tabela venda

Tabela do banco:

- `venda`

Isso responde à sua pergunta “como chama a venda” no banco:

- **tabela `venda`**

DAO:

- `API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Venda.pas`

Métodos importantes:

- `Inserir`
- `Buscar`
- `PreFechamento`
- `FinalizarVenda`
- `AtualizarCouvert`
- `AtualizarNomeMesaComanda`
- `ReabrirMesaComanda`

Campos importantes:

- `ven_001` -> id da venda
- `emp_001` -> empresa
- `dat_001_1` -> data abertura
- `ven_025` -> número da mesa
- `ven_026` -> número da comanda
- `sit_001` -> situação
- `usu_001_1` -> usuário de abertura
- `usu_001_2` -> usuário do pré-fechamento
- `id_usuario_fech` -> usuário do fechamento
- `terminal_abertura`
- `nome_mesa_comanda`
- `nro_pessoas`

Sobre o garçom de abertura:

- o campo de abertura que o sistema grava é `usu_001_1`;
- no objeto Delphi ele vira `Result.idUsuario`;
- esse valor vem do `IdUsuario` da requisição;
- no app mobile ele agora é enviado no header `idUsuario` ao abrir mesa/comanda.

---

## 8. Como a venda é consultada

## 8.1 No app

Arquivo:

- `APPReact/src/services/api.ts`

Método:

- `async getSale(idVenda: number, listarItens = true)`

Endpoint:

- `GET /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}`

Header opcional:

- `listarItens: true|false`

## 8.2 Na API

Controller:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.Venda.pas`

Método:

- `procedure Consultar;`

Ele decide entre:

- `ConsultarJSON`
- `ConsultarTextPlain`

`ConsultarJSON`:

- busca a venda estruturada para o app.

`ConsultarTextPlain`:

- gera conteúdo de impressão.

---

## 9. Como os itens da venda são enviados

Essa é a parte mais importante quando falamos em “enviar a venda”.

O app não envia uma venda inteira de uma vez no lançamento.
Ele envia os itens para uma venda já aberta.

## 9.1 No app

Arquivo:

- `APPReact/src/context/AppContext.tsx`

Funções:

- `asPayload(item)`
- `flushPendingItems()`

`asPayload(item)` monta o JSON do item com:

- produto;
- quantidade;
- valor unitário;
- valor total;
- desconto;
- acréscimo;
- tamanho;
- observação;
- mesa vinculada;
- `idGarcom`;
- opcionais;
- frações.

Depois `flushPendingItems()`:

1. garante que existe mesa/comanda ativa;
2. se ainda não existir `idVenda`, abre a venda;
3. chama `api.launchItemsBatch(table.idVenda, pending.map(asPayload))`.

## 9.2 Endpoint usado para enviar itens

Arquivo:

- `APPReact/src/services/api.ts`

Método:

- `async launchItemsBatch(idVenda, items)`

Endpoint:

- `POST /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/item/lote`

Também existe:

- `POST /venda/{idVenda}/item` para item unitário

## 9.3 Na API

Controller:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.VendaItem.pas`

Métodos:

- `LancarItem`
- `LancarItens`
- `CancelarItem`
- `ListarItens`

Comportamento importante:

- a API lê o header `idUsuario`;
- se esse header vier, ela sobrescreve `idGarcom` do item com o usuário da requisição;
- isso padroniza o garçom responsável pelos itens.

## 9.4 Tabelas relacionadas aos itens

Tabelas principais:

- `vendaitem`
- `vendaitemopcional`

Então:

- venda principal fica em `venda`
- itens ficam em `vendaitem`
- opcionais dos itens ficam em `vendaitemopcional`

---

## 10. Como a venda é fechada

## 10.1 Tela de fechamento

Arquivo:

- `APPReact/src/screens/SaleClosureScreen.tsx`

Essa tela concentra:

- pré-fechamento;
- fechamento final;
- escolha de forma de pagamento;
- integração com maquininha;
- impressão;
- cálculo de desconto;
- taxa de serviço;
- troco;
- pagamento parcial.

## 10.2 Chamada no app

Arquivo:

- `APPReact/src/services/api.ts`

Métodos:

- `preCloseSale(...)`
- `closeSale(...)`

Endpoints:

- `PATCH /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/preFechamento`
- `POST /rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}/fechamento`

## 10.3 Na API

Controller:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.Venda.pas`

Métodos:

- `ExecutarPreFechamento`
- `FecharVenda`

Fluxo do fechamento:

1. o app monta o payload com pagamentos;
2. a API injeta `idUsuario` a partir do header, quando presente;
3. o service de fechamento processa a regra de negócio;
4. `VendaDAO.FinalizarVenda(...)` muda a venda para finalizada;
5. pagamentos parciais e impressão podem acontecer em paralelo ao fluxo.

## 10.4 Tabelas envolvidas no fechamento/pagamento

Principais:

- `venda`
- `venda_pag_antecipado`
- `caixaitem`

Pagamento parcial:

- controller: `RegistrarPagamentoParcial`
- endpoint: `POST /venda/{idVenda}/pagamento`

---

## 11. Telas importantes e o papel de cada uma

### `APPReact/src/screens/LoginScreen.tsx`

- autenticação do operador.

### `APPReact/src/screens/InitialScreen.tsx`

- dashboard inicial de mesas/comandas;
- filtros;
- leitura por câmera;
- abertura da mesa/comanda;
- acesso a configuração e sincronização.

### `APPReact/src/screens/MenuScreen.tsx`

- cardápio/categorias.

### `APPReact/src/screens/ItemLaunchScreen.tsx`

- lançamento de item simples;
- garante abertura de venda se necessário;
- prepara retorno com itens pendentes.

### `APPReact/src/screens/FractionLaunchScreen.tsx`

- lançamento fracionado.

### `APPReact/src/screens/SaleManagerScreen.tsx`

- gestão da venda aberta;
- lista itens;
- mostra garçom;
- cancela item;
- abre fechamento;
- reabre;
- junta mesas/comandas.

### `APPReact/src/screens/SaleClosureScreen.tsx`

- pré-fechamento;
- fechamento final;
- pagamentos;
- impressão;
- integração TEF/maquininha.

### `APPReact/src/screens/SettingsScreen.tsx`

- configurações técnicas e operacionais.

### `APPReact/src/screens/SyncScreen.tsx`

- sincronização manual.

---

## 12. Onde exatamente ficam os dados de categoria, produto, usuário e venda no banco

### Usuários

- tabela: `usuarios`

### Categorias

- tabela: `categoria`

### Produtos

- tabela: `materiais`

### Venda principal

- tabela: `venda`

### Itens da venda

- tabela: `vendaitem`

### Opcionais dos itens

- tabela: `vendaitemopcional`

### Pagamentos parciais / antecipados

- tabela: `venda_pag_antecipado`

---

## 13. Mapa resumido do fluxo de venda

### 13.1 Abrir mesa/comanda

Frontend:

- `InitialScreen`
- `AppContext.openTableByCard`
- `api.openTableByMode`

API:

- `Controller.Mesa.AbrirMesa`
- `Controller.Comanda.AbrirComanda`
- `Service.Mesa.Abertura`
- `Service.Comanda.Abertura`
- `VendaDAO.Inserir`

Banco:

- `venda`

### 13.2 Lançar item

Frontend:

- `ItemLaunchScreen`
- `FractionLaunchScreen`
- `AppContext.flushPendingItems`
- `api.launchItemsBatch`

API:

- `Controller.VendaItem.LancarItens`

Banco:

- `vendaitem`
- `vendaitemopcional`

### 13.3 Consultar venda

Frontend:

- `api.getSale`

API:

- `Controller.Venda.Consultar`

Banco:

- `venda`
- `vendaitem`

### 13.4 Pré-fechar

Frontend:

- `SaleClosureScreen`
- `api.preCloseSale`

API:

- `Controller.Venda.ExecutarPreFechamento`
- `VendaDAO.PreFechamento`

Banco:

- `venda`

### 13.5 Fechar

Frontend:

- `SaleClosureScreen`
- `api.closeSale`

API:

- `Controller.Venda.FecharVenda`
- `VendaDAO.FinalizarVenda`

Banco:

- `venda`
- `venda_pag_antecipado`
- `caixaitem`

---

## 14. Observação importante sobre o usuário/garçom

A API usa um padrão importante:

- o usuário do operador não é deduzido automaticamente do login do app;
- ela lê o header HTTP `idUsuario`;
- esse valor alimenta:
  - abertura da venda;
  - lançamento de item;
  - fechamento;
  - parte dos fluxos de pagamento.

Por isso, quando esse header não vai na requisição:

- `usu_001_1` pode ficar nulo na abertura;
- o item pode ficar sem o garçom correto;
- fechamento pode perder rastreabilidade do operador.

Foi exatamente isso que gerou o problema que corrigimos na abertura inicial de mesa/comanda.

---

## 15. Respostas objetivas às suas perguntas

### Como chama a tabela produtos?

- `materiais`

### Como chama a tabela categoria?

- `categoria`

### Como chama a venda?

No banco:

- `venda`

No app/API:

- consulta por `/rpCheff/v1/empresa/{idEmpresa}/venda/{idVenda}`

### Como envia a venda?

O sistema trabalha em etapas:

1. abre mesa/comanda e cria registro em `venda`;
2. envia itens para `/venda/{idVenda}/item` ou `/item/lote`;
3. consulta a venda por `/venda/{idVenda}`;
4. faz pré-fechamento por `/venda/{idVenda}/preFechamento`;
5. faz fechamento final por `/venda/{idVenda}/fechamento`.

### Onde está a tela de login?

- `APPReact/src/screens/LoginScreen.tsx`

### Como valida usuários?

Frontend:

- `APPReact/src/services/api.ts` chama `/usuario/login`

Backend:

- `API/Fontes/Source/Controller/APIRPCheff.Controller.Usuario.pas`
- `API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Usuario.pas`

Banco:

- tabela `usuarios`
- login = `usu_003`
- senha = `usu_004`
- ativo = `sit_001 = 4`
- permitido para garçom = `b_funcao_garcom`

---

## 16. Próximos documentos que valem a pena fazer

Se você quiser, o próximo passo pode ser um documento ainda mais específico, separado em um destes formatos:

1. fluxo completo de mesa/comanda do toque na tela até o SQL;
2. fluxo completo de login e permissões;
3. mapa das tabelas do banco com nome técnico e significado dos campos;
4. mapa de integrações de pagamento por maquininha.

Esse documento atual já serve como visão geral técnica do sistema e como índice para navegar no código-fonte.
