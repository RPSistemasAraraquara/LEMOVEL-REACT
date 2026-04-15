# Documento React 4 - Cardapio e Lancamento

## Arquivos principais

- [MenuScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/MenuScreen.tsx:1)
- [ItemLaunchScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/ItemLaunchScreen.tsx:1)
- [FractionLaunchScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/FractionLaunchScreen.tsx:1)
- [AppContext.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/context/AppContext.tsx:501)
- [api.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/api.ts:3010)
- [APIRPCheff.Controller.Categoria.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Categoria.pas:1)
- [APIRPCheff.Controller.Produto.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Produto.pas:1)
- [APIRPCheff.Controller.VendaItem.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.VendaItem.pas:1)

## Como categorias e produtos chegam no app

No [AppContext.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/context/AppContext.tsx:824), `refreshMenu()` chama:

- `api.listCategories()`
- `api.listProducts()`

Endpoints:

- `GET /categoria`
- `GET /produto`

Tabelas do banco:

- categorias -> `categoria`
- produtos -> `materiais`

## Papel da `MenuScreen`

A [MenuScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/MenuScreen.tsx:1):

- mostra categorias
- mostra lista de produtos
- filtra por texto
- valida se ha mesa ativa
- abre a tela de lancamento

## O que acontece ao tocar em um produto

Fluxo:

1. `MenuScreen` chama `openLaunchScreen(item)`.
2. Ela verifica se existe mesa ativa.
3. Verifica se a venda esta em status pendente.
4. Se a mesa ainda nao tiver `idVenda`, tenta abrir.
5. Navega para `Lancamento`.

## O que acontece na tela `ItemLaunchScreen`

A [ItemLaunchScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/ItemLaunchScreen.tsx:1):

- recebe o produto da rota
- controla quantidade
- controla tamanho
- controla opcionais
- controla observacao
- prepara o item para o carrinho

Se for fracionado:

- navega para [FractionLaunchScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/FractionLaunchScreen.tsx:1)

## Carrinho nao e banco

No app:

- carrinho = memoria/estado

No banco:

- venda principal = `venda`
- itens = `vendaitem`
- opcionais = `vendaitemopcional`

Entao:

- adicionar item ao carrinho ainda nao significa gravar item na tabela

## Quem envia os itens de verdade

No [AppContext.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/context/AppContext.tsx:1188), `flushPendingItems()`:

1. pega o carrinho
2. garante mesa ativa
3. garante `idVenda`
4. usa `asPayload(...)` para transformar os itens
5. chama `api.launchItemsBatch(...)`
6. limpa carrinho
7. atualiza dashboard

## Endpoint que grava itens

No [api.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/api.ts:3238):

- `POST /venda/{idVenda}/item/lote`

No backend:

- [APIRPCheff.Controller.VendaItem.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.VendaItem.pas:86)

Esse controller:

- injeta `idEmpresa`
- injeta `idVenda`
- usa o header `idUsuario` para definir `idGarcom` quando vier

Tabelas:

- `vendaitem`
- `vendaitemopcional`
