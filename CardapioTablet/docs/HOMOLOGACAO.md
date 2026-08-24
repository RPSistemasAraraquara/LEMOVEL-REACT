# Homologacao - Cardapio Tablet

## Escopo

Validar o app de cardapio tablet sem alterar o fluxo do `APPReact`.

## Casos obrigatorios

### CT-001 - Configurar mesa do tablet

**Modulo:** Configuracao
**Tipo:** Funcional/mobile
**Pre-condicoes:** App instalado e API acessivel.

**Passos:**
1. Abrir o app sem configuracao salva.
2. Informar servidor, empresa, mesa e terminal.
3. Testar API.
4. Salvar.

**Resultado esperado:** App vai para tela bloqueada da mesa configurada.

### CT-002 - Bloquear troca de mesa sem garcom

**Modulo:** Seguranca operacional
**Tipo:** Permissao

**Passos:**
1. Na tela bloqueada, tocar em Trocar mesa.
2. Informar senha invalida.
3. Repetir com usuario/senha validos.

**Resultado esperado:** Senha invalida nao abre configuracao; senha valida abre configuracao.

### CT-003 - Liberar mesa livre

**Modulo:** Abertura de mesa
**Tipo:** Integracao/API/banco

**Passos:**
1. Deixar a mesa configurada livre no sistema.
2. Tocar em Liberar mesa.
3. Informar usuario/senha do garcom.

**Resultado esperado:** API cria venda pendente para a mesa e o app abre o cardapio.

**Validar no banco:** venda criada com mesa correta, usuario de abertura e terminal de abertura do tablet.

### CT-004 - Cliente envia pedido simples

**Modulo:** Cardapio/Carrinho
**Tipo:** Funcional/API/banco

**Passos:**
1. Adicionar produto normal ao carrinho.
2. Adicionar opcionais com quantidade.
3. Remover um item antes do envio.
4. Enviar pedido.

**Resultado esperado:** Apenas os itens restantes sao lancados na venda. O carrinho fica vazio.

**Validar no banco:** itens na venda, opcionais, valores, `id_lancamento_mobile`, garcom e terminal.

### CT-005 - Cliente envia produto fracionado

**Modulo:** Cardapio fracionado
**Tipo:** Funcional/API/banco

**Passos:**
1. Abrir produto fracionado.
2. Selecionar 2, 3 ou 4 sabores.
3. Tentar adicionar com sabor faltando.
4. Completar sabores e adicionar.
5. Enviar pedido.

**Resultado esperado:** App bloqueia sabor faltando/repetido e envia payload com `fracoes`.

### CT-006 - Mesa fechada bloqueia tablet

**Modulo:** Sincronizacao
**Tipo:** Regressao/concorrencia

**Passos:**
1. Com tablet liberado, fechar ou pre-fechar a mesa pelo sistema do garcom.
2. Aguardar ate 10 segundos.

**Resultado esperado:** Tablet volta para tela bloqueada e limpa carrinho local nao enviado.

### CT-007 - Cliente visualiza pedido enviado

**Modulo:** Visualizacao do pedido
**Tipo:** Funcional/API/permissao

**Passos:**
1. Com a mesa liberada e itens ja enviados, tocar em Visualizar Pedido.
2. Conferir itens, quantidades, tamanhos, opcionais, observacoes e total.
3. Tocar em Atualizar.
4. Tocar em Fechar.

**Resultado esperado:** O app mostra os itens da venda atual em modo somente leitura. Cliente nao consegue remover, cancelar, transferir, fechar, pagar ou alterar item nesta tela.

### CT-008 - Regressao do APPReact

**Modulo:** App existente
**Tipo:** Regressao

**Passos:**
1. Abrir o `APPReact`.
2. Executar login e fluxo de mesa ja existente.
3. Validar fechamento/pagamento/cancelamento conforme app atual.

**Resultado esperado:** Fluxo existente nao muda, porque o CardapioTablet nao altera arquivos do `APPReact`.

### CT-009 - Trava de fechamento do app

**Modulo:** Seguranca operacional
**Tipo:** Mobile/kiosk

**Passos:**
1. Abrir o app no tablet.
2. Tentar sair pelo BACK, barra inferior, Home e Recentes.
3. Entrar em Configuracao com usuario e senha do garcom.
4. Tocar em Fechar APP e confirmar.

**Resultado esperado:** Cliente nao consegue fechar o app pelo fluxo comum. A saida do app fica disponivel apenas na tela de configuracao autorizada. Para bloqueio absoluto de Home/Recentes, o Android deve estar com pinagem/Lock Task/MDM habilitado para o pacote do app.

### CT-010 - Modulo Cardapio Tablet habilitado na empresa

**Modulo:** Licenciamento/Configuracao
**Tipo:** Integracao/API/banco

**Passos:**
1. No banco, deixar `empresas.utiliza_cardapiotablet = false` para a empresa configurada.
2. Abrir o app, testar API, liberar mesa ou sincronizar.
3. Alterar para `empresas.utiliza_cardapiotablet = true`.
4. Sincronizar novamente e liberar a mesa com usuario/senha validos.

**Resultado esperado:** Com `false`, o app nao abre o cardapio e exibe `Modulo não habilitado`. Com `true`, o fluxo normal de liberacao e cardapio fica disponivel.

### CT-011 - Configuracao rolavel e banners de rotina silenciosos

**Modulo:** Layout/UX
**Tipo:** Mobile/tablet

**Passos:**
1. Abrir Configuracao em tela menor ou tablet em paisagem com altura reduzida.
2. Rolar a area de configuracao ate diagnostico, botoes e rodape.
3. Voltar ao cardapio, adicionar produto ao carrinho.
4. Tocar em Atualizar.

**Resultado esperado:** A configuracao rola sem esconder acoes. O app nao mostra banner para `Item adicionado ao carrinho` nem para sincronizacao bem-sucedida; banners continuam aparecendo apenas em eventos operacionais relevantes.

## Evidencias minimas

- Print da tela bloqueada e da tela de configuracao autorizada.
- Print do cardapio, carrinho, detalhe do produto e Visualizar Pedido.
- Evidencia da trava de fechamento e do botao Fechar APP na configuracao autorizada.
- Evidencia do bloqueio `Modulo não habilitado` quando `empresas.utiliza_cardapiotablet = false`.
- Evidencia de rolagem da tela de configuracao em tela baixa.
- Payload ou log da API no envio de lote.
- Consulta da venda e vendaitem no banco.
- Confirmacao visual de bloqueio apos fechamento da mesa.
