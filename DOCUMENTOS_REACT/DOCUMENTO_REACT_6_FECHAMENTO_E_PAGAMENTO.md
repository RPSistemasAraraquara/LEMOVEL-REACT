# Documento React 6 - Fechamento e Pagamento

## Arquivos principais

- [SaleClosureScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/SaleClosureScreen.tsx:135)
- [payment.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/payment.ts:1)
- [api.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/api.ts:3314)
- [APIRPCheff.Controller.Venda.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Venda.pas:1)
- [APIRPCheff.DAO.Venda.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Venda.pas:1)

## O que a tela faz

A [SaleClosureScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/SaleClosureScreen.tsx:135) e uma das telas mais importantes do sistema.

Ela trabalha em dois modos:

- `pre`
- `final`

E cuida de:

- carregar a venda
- carregar formas de pagamento
- aplicar desconto
- calcular couvert e taxa
- processar maquininha
- pre-fechar
- fechar
- imprimir

## Como os dados sao carregados

O metodo `loadData()` chama em paralelo:

- `api.getSale(idVenda, true)`
- `api.listPaymentMethods()`
- `api.listPaymentsBySale(idVenda)`
- `api.getCompanyConfig()`

Entao essa tela junta:

- dados da venda
- configuracao da empresa
- formas de pagamento
- pagamentos parciais anteriores

## Pre-fechamento

Quando o modo e `pre`, a tela:

1. valida permissao do usuario
2. valida quantidade de pessoas/couvert
3. chama `api.preCloseSale(...)`
4. pode carregar preview da impressao
5. faz `refreshDashboard()`

Endpoint:

- `PATCH /venda/{idVenda}/preFechamento`

No backend:

- [APIRPCheff.Controller.Venda.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Venda.pas:179)
- [APIRPCheff.DAO.Venda.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Venda.pas:478)

Campos importantes:

- `usu_001_2`
- `imprimir_prefechamento_mobile`

## Fechamento final

Quando o modo e `final`, a tela:

1. valida permissao
2. valida usuario
3. monta as linhas de pagamento
4. processa maquininha quando necessario
5. consolida pagamentos aprovados
6. chama `api.closeSale(...)`
7. opcionalmente imprime
8. atualiza dashboard

Endpoint:

- `POST /venda/{idVenda}/fechamento`

No backend:

- [APIRPCheff.Controller.Venda.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Venda.pas:223)
- [APIRPCheff.DAO.Venda.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Venda.pas:63)

Campo importante no banco:

- `id_usuario_fech`

## Pagamento parcial

O fluxo de pagamento parcial passa por:

- `SaleManagerScreen` -> navega para `Pagamento`
- `SalePaymentScreen` -> registra pagamento parcial

Tabela relacionada:

- `venda_pag_antecipado`

## Integracao com maquininha

A tela usa funcoes do [payment.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/payment.ts:1) para:

- decidir provedor
- saber se precisa processar na maquininha
- executar integracao

Ou seja:

- `SaleClosureScreen` decide o fluxo
- `payment.ts` resolve o pagamento eletronico
