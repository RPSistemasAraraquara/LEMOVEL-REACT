# Seguranca de Configuracao

## Ideia para o item 7

A melhoria mais importante aqui e separar a senha do garcom da identidade tecnica do tablet.

Hoje a senha do garcom libera configuracao e abertura operacional. Para uma versao mais segura, eu faria um pareamento inicial do tablet com a API:

1. O sistema administrativo gera um QR Code de pareamento para empresa, mesa e terminal.
2. O QR Code contem um token temporario, com validade curta.
3. O tablet le o QR Code na primeira configuracao e chama a API de pareamento.
4. A API devolve um `deviceId` e um token de dispositivo limitado aquela empresa/mesa/terminal.
5. O token fica no Android Keystore, via `expo-secure-store` ou modulo nativo equivalente.
6. A API aceita sincronizacao/envio apenas de tablets pareados e ativos.
7. O garcom continua usando usuario/senha somente para acoes operacionais: liberar mesa, abrir configuracao e fechar app.

## Beneficios

- Se o tablet for perdido, basta revogar o dispositivo no servidor.
- Troca de IP continua sendo resolvida pela configuracao local autorizada.
- Nao precisa colocar senha fixa ou segredo forte dentro do APK.
- Um tablet da mesa 01 nao consegue se apresentar como outra mesa sem novo pareamento.
- O suporte consegue auditar qual dispositivo enviou cada pedido pendente.

## Escopo sugerido

Implementar em duas etapas:

1. Curto prazo: manter configuracao atual, adicionar exportacao de diagnostico e evidencia de kiosk.
2. Proxima versao: criar endpoint de pareamento, cadastro de dispositivos no banco, token revogavel e armazenamento seguro no Android.

Nao recomendo mudar isso junto com uma release de correcoes de rede, porque envolve API, banco e politica de revogacao. E uma evolucao boa para a versao seguinte.
