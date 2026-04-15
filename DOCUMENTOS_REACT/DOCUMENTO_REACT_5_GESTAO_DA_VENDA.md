# Documento React 5 - Gestao da Venda

## Arquivos principais

- [SaleManagerScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/SaleManagerScreen.tsx:250)
- [api.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/api.ts:3262)
- [APIRPCheff.Controller.Venda.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Venda.pas:1)
- [APIRPCheff.Controller.VendaItem.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.VendaItem.pas:1)

## O que a tela faz

A [SaleManagerScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/SaleManagerScreen.tsx:250) e a tela de gestao da venda aberta.

Ela cuida de:

- carregar dados da venda
- listar itens
- mostrar garcom
- mostrar total
- cancelar item
- reabrir venda
- ir para pre-fechamento
- ir para fechamento final
- ir para pagamento parcial
- ir para juntar mesas

## Como a venda e carregada

Ela usa:

- `api.getSale(idVenda, true)`

Isso traz:

- cabecalho da venda
- itens
- totais
- situacao

## Onde as permissoes sao aplicadas

Antes de cada acao, a tela verifica `user`.

Exemplos reais:

- cancelar item:
  - `user?.permiteCancelarItemMobile`
- pre-fechamento:
  - `user?.permitePreFechamentoMesaComanda`
- fechamento:
  - `user?.permiteFechamentoMesaComanda`
- pagamento parcial:
  - `user?.permitePagamentoParcial`
- juntar mesas:
  - `user?.permiteJuntarMesaComanda`
- reabrir:
  - `user?.permiteReabrirMesaComanda`

Ou seja:

- a permissao nasce no login
- fica em `user`
- e a tela consulta isso antes de agir

## Cancelamento de item

Fluxo:

1. o operador toca para cancelar
2. a tela valida permissao
3. valida se a venda esta pendente
4. chama `api.cancelSaleItem(idVenda, numeroItem, idUsuario)`
5. recarrega a venda e o dashboard

Backend:

- controller de venda item
- regras de cancelamento

## Reabrir venda

Fluxo:

1. a tela valida permissao
2. valida se a venda esta em pre-fechamento
3. chama `api.reopenSale(idVenda)`
4. recarrega dados

Na API:

- `PATCH /venda/{idVenda}/reabertura`

No banco:

- a situacao da venda volta para pendente

## Navegacao para outras telas

A `SaleManagerScreen` nao faz tudo nela mesma.

Ela navega para:

- `Fechamento`
- `Pagamento`
- `JuntarMesa`

Isso e um padrao importante do React:

- tela de gestao orquestra
- tela especialista executa o fluxo detalhado
