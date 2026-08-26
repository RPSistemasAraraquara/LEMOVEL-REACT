# Kiosk Android

O Cardapio Tablet entra em tela cheia ao abrir.

Para impedir que o cliente saia usando a combinacao do Android, o tablet precisa estar em modo gerenciado, com este app como Device Owner ou por MDM. Sem isso, o Android permite apenas screen pinning, que mostra ao usuario como desafixar o app.

Por seguranca, o app nao inicia o screen pinning comum. Ele so inicia Lock Task quando consegue configurar o modo gerenciado. Assim a tela do Android ensinando o atalho de saida nao aparece para o cliente.

## Provisionamento por ADB

Use em tablet recem-resetado, sem conta Google e sem outro administrador ativo:

```powershell
adb shell dpm set-device-owner br.com.sistemalechef.cardapiotablet/.TabletDeviceAdminReceiver
adb shell dpm list-owners
adb shell monkey -p br.com.sistemalechef.cardapiotablet -c android.intent.category.LAUNCHER 1
adb shell dumpsys activity activities | findstr /i "LockTask mLockTask"
```

O estado esperado depois de abrir o app e:

```text
LOCK_TASK_MODE_LOCKED
```

Neste estado, a saida do modo kiosk fica restrita ao botao `Fechar APP`, disponivel apenas depois da autorizacao do garcom na tela de configuracao.

Na tela de configuracao do tablet, o card `Modo Kiosk Seguro` consulta o Android:

- `Ativo`: tablet em Lock Task seguro.
- `Inativo`: falta Device Owner ou MDM.
- `Inseguro`: Android esta em screen pinning comum (`PINNED`), que nao deve ser usado com cliente.

Se o comando `set-device-owner` falhar por tablet ja provisionado, sera necessario resetar o dispositivo ou aplicar a politica por MDM.

## Checklist forte para loja

1. Instalar o APK atual do Cardapio Tablet.
2. Fazer factory reset antes do provisionamento quando o tablet ja tiver conta Google, dono anterior ou outro administrador.
3. Provisionar como Device Owner por ADB ou MDM.
4. Conferir `adb shell dpm list-owners` e confirmar `br.com.sistemalechef.cardapiotablet`.
5. Abrir o app e conferir `LOCK_TASK_MODE_LOCKED` no `dumpsys`.
6. Entrar em Configuracao com garcom autorizado e confirmar o card `Modo Kiosk Seguro` como `Ativo`.
7. Testar BACK, Home e Recentes; nenhum deles deve tirar o cliente do app.
8. Testar o botao `Fechar APP`; ele deve aparecer somente depois da autorizacao do garcom.

## Evidencia ADB

O projeto possui um smoke automatizado para coletar evidencia do tablet conectado:

```powershell
npm run smoke:adb
```

O script instala o ultimo APK de `dist`, abre o app e salva o relatorio em:

```text
dist\adb-smoke-cardapio-tablet.txt
```

Para apenas consultar um tablet que ja tem o app instalado, use:

```powershell
npm run smoke:adb -- -NoInstall
```
