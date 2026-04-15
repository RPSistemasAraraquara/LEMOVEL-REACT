# Documento React 7 - API e Banco

## Como seguir o fluxo completo

Toda vez que quiser entender uma funcionalidade, siga esta sequencia:

1. tela React
2. `useApp()`
3. `AppContext`
4. `api.ts`
5. endpoint REST
6. controller Delphi
7. service Delphi
8. DAO Delphi
9. tabela do banco

## Tabelas principais do sistema

- usuarios -> `usuarios`
- categorias -> `categoria`
- produtos -> `materiais`
- venda principal -> `venda`
- itens da venda -> `vendaitem`
- opcionais dos itens -> `vendaitemopcional`
- pagamentos parciais -> `venda_pag_antecipado`

## Mapa rapido de endpoints importantes

### Login

- `POST /empresa/{idEmpresa}/usuario/login`

### Usuarios

- `GET /empresa/{idEmpresa}/usuario`
- `GET /empresa/{idEmpresa}/usuario/{login}`

### Categorias

- `GET /empresa/{idEmpresa}/categoria`

### Produtos

- `GET /empresa/{idEmpresa}/produto`
- `GET /empresa/{idEmpresa}/produto/{idProduto}`
- `GET /empresa/{idEmpresa}/produto/{idProduto}/imagem`

### Mesas e comandas

- `GET /empresa/{idEmpresa}/mesa`
- `GET /empresa/{idEmpresa}/comanda`
- `POST /empresa/{idEmpresa}/mesa/{idMesa}/abertura`
- `POST /empresa/{idEmpresa}/comanda/{idComanda}/abertura`

### Venda

- `GET /empresa/{idEmpresa}/venda/{idVenda}`
- `PATCH /empresa/{idEmpresa}/venda/{idVenda}/preFechamento`
- `POST /empresa/{idEmpresa}/venda/{idVenda}/fechamento`
- `PATCH /empresa/{idEmpresa}/venda/{idVenda}/reabertura`

### Itens

- `POST /empresa/{idEmpresa}/venda/{idVenda}/item`
- `POST /empresa/{idEmpresa}/venda/{idVenda}/item/lote`
- `DELETE /empresa/{idEmpresa}/venda/{idVenda}/item/{numeroItem}`

## O que vale memorizar

1. `usuarios` controla autenticacao e permissoes.
2. `categoria` e `materiais` montam o cardapio.
3. abrir mesa/comanda cria registro em `venda`.
4. lancar item grava em `vendaitem`.
5. fechar venda atualiza `venda` e pode gravar pagamentos.

## Regra pratica de depuracao

Se um problema aparecer no app:

1. veja em qual tela acontece
2. descubra qual funcao do contexto ela chama
3. veja qual metodo do `api.ts` esta envolvido
4. anote o endpoint
5. abra controller, service e DAO
6. confira a tabela no banco

Esse metodo funciona muito bem para quase todo o RP MOVEL.
