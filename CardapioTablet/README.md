# Cardapio Tablet

App Expo separado do `APPReact` para uso em tablet fixo na mesa do cliente.

## Fluxo

1. Configure API, empresa, numero da mesa e nome do terminal.
2. A tela fica bloqueada aguardando o garcom.
3. O garcom libera a mesa com usuario e senha.
4. O cliente monta o carrinho e pode remover itens somente antes de enviar.
5. Ao enviar, os itens sao lancados na venda aberta pelo endpoint existente de lote.
6. A cada 10 segundos o app consulta a mesa. Se a venda sair de estado aberto, o tablet bloqueia novamente e limpa o carrinho local.

## Regras preservadas

- Nao altera o fluxo, telas ou contexto do `APPReact`.
- Nao expoe fechamento, pagamento, transferencia, juncao de mesa ou cancelamento de item ja enviado.
- Usa somente os endpoints existentes de login, mesa, categoria, produto, venda e lancamento de item.
- Troca de mesa/configuracao exige usuario e senha do garcom.
- Produto fracionado permite selecao de 2, 3 ou 4 sabores e envia `fracoes` no payload.
- Opcionais aceitam quantidade antes do envio do pedido.

## Comandos

```bash
npm install
npm run test:smoke
npm start
```

## API local

Na configuracao do tablet, o servidor pode ser informado como `192.168.15.35:9000` ou `http://192.168.15.35:9000`.
Enderecos de rede local sem protocolo sao normalizados para HTTP, e o APK Android deste app permite HTTP local.

## Uso em tablet

O APK Android abre em modo imersivo, esconde as barras do sistema, mantem a tela ligada e bloqueia o botao voltar para nao tirar o cliente do cardapio.
Bloqueio absoluto de Home/Recentes exige modo kiosk/pinagem do proprio Android ou gerenciamento do dispositivo.

Os cenarios de homologacao estao em `docs/HOMOLOGACAO.md`.
As evidencias locais estao em `docs/VALIDACAO_LOCAL.md`.
