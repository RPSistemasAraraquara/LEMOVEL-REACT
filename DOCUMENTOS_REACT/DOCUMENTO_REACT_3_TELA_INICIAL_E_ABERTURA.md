# Documento React 3 - Tela Inicial e Abertura

## Arquivos principais

- [InitialScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/InitialScreen.tsx:1)
- [HomeScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/HomeScreen.tsx:1)
- [AppContext.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/context/AppContext.tsx:1120)
- [api.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/api.ts:3115)
- [APIRPCheff.Controller.Mesa.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Mesa.pas:1)
- [APIRPCheff.Controller.Comanda.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Comanda.pas:1)
- [APIRPCheff.Service.Mesa.Abertura.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Model/Service/Mesa/Abertura/APIRPCheff.Service.Mesa.Abertura.pas:1)
- [APIRPCheff.Service.Comanda.Abertura.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Model/Service/Comanda/Abertura/APIRPCheff.Service.Comanda.Abertura.pas:1)

## O papel da `InitialScreen`

A [InitialScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/InitialScreen.tsx:119) e a tela operacional de entrada depois do login.

Ela cuida de:

- mostrar mesas e comandas
- aplicar filtros
- ler codigo via camera
- abrir configuracoes e sincronizacao
- abrir mesa/comanda

## O que ela pega do contexto

A tela usa `useApp()` para pegar:

- `tables`
- `appSettings`
- `settingsReady`
- `refreshDashboard`
- `flushPendingItems`
- `cart`
- `user`
- `logout`
- `openTableByCard`
- `setActiveTable`

Ou seja:

- a tela nao faz tudo sozinha
- ela usa o contexto como camada central

## Fluxo de abertura de mesa/comanda

1. O operador toca numa mesa ou comanda.
2. A tela valida se as configuracoes ja carregaram.
3. Se a mesa ja tiver `idVenda`, ela apenas ativa a mesa e navega.
4. Se exigir nome na abertura, a tela abre um modal.
5. Se exigir vinculacao com mesa, abre o picker.
6. Se estiver tudo simples, chama `openTableByCard(...)`.

## O que `openTableByCard` faz

Em [AppContext.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/context/AppContext.tsx:1120):

- decide o modo `mesa`, `comanda` ou `mesaComanda`
- trata nome informado
- trata catraca
- pega o `idUsuario` do operador logado
- chama `api.openTableByMode(...)`
- salva a mesa aberta em `setActiveTable(...)`

## O que o frontend envia

No [api.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/api.ts:3115):

- `POST /mesa/{idMesa}/abertura`
- `POST /comanda/{idComanda}/abertura`

Headers importantes:

- `idUsuario`
- `usaCatraca` quando necessario

Body importante:

- `terminalAbertura`
- `nomeMesaComanda`

## O que o backend faz

Nos services Delphi:

- cria um objeto `Venda`
- preenche empresa, data, mesa/comanda, terminal e usuario
- chama `VendaDAO.Inserir(...)`

Tabela do banco:

- `venda`

Campo importante de abertura:

- `usu_001_1`

## Licao importante

No RP MOVEL, "abrir mesa/comanda" nao e so trocar de tela.

Na pratica, isso:

1. chama o backend
2. cria uma venda real
3. grava na tabela `venda`
