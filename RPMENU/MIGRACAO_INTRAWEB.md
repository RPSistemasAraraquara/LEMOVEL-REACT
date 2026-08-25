# Migracao IntraWeb para React

Projeto origem: `C:\Developer\Fast FOOD\RPMENU`

Projeto React gerado: `C:\Developer\Fast FOOD\LEMOVEL-REACT\RPMENU`

Base visual usada: `C:\Developer\Fast FOOD\RPFOOD_REACTJS\SITE`

## Rotas Migradas

| Rota legada IntraWeb | Tela React |
| --- | --- |
| `index.html` | Home/cardapio |
| `login.html` | Login do cliente |
| `esqueci-minha-senha.html` | Recuperacao de senha |
| `cliente-cadastro.html` | Cadastro do cliente |
| `cliente-dados.html` | Dados do cliente |
| `cliente-endereco.html` | Enderecos do cliente |
| `novo-endereco.html` | Novo endereco |
| `produto-por-categoria.html` | Produtos por categoria |
| `produtostodascategoria.html` | Todos os produtos |
| `pedido-item.html` | Detalhe do produto |
| `pedido-finalizar.html` | Fechamento do pedido |
| `pedido-pagamento.html` | Pagamento Pix |
| `pedido-acompanhamento.html` | Acompanhamento do pedido |
| `venda-historico.html` | Historico do cliente |
| `sobre.html` | Sobre a loja |
| `erro-404.html` / `erro-500.html` | Erro tratado |
| `admin/login.html` | Login administrativo |
| `admin/index.html` / `admin/index2.html` | Painel administrativo |

## Configuracao

Variaveis principais:

- `VITE_RPMENU_API_URL`: URL base da API. Padrao local: `/rpfood/v1`.
- `VITE_RPMENU_EMPRESA_ID`: empresa padrao usada pelo cardapio.
- `RPMENU_PROXY_TARGET`: alvo do proxy no Vite em desenvolvimento.

A aplicacao tambem aceita as variaveis antigas `VITE_RPFOOD_API_URL`, `VITE_RPFOOD_EMPRESA_ID` e `RPFOOD_PROXY_TARGET` como fallback para facilitar implantacao gradual.

## Validacao Executada

- `npm run lint`
- `npm run build`
- `node scripts\qa-routes.mjs`
- `node scripts\qa-responsive.mjs`
- `node scripts\qa-business-rules.mjs`

Relatorios e screenshots de QA ficam em `test-results/` e foram mantidos como evidencia local, mas ignorados pelo Git.
