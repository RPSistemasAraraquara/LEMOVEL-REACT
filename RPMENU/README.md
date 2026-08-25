# RPMENU React

Migracao do sistema Delphi IntraWeb `C:\Developer\Fast FOOD\RPMENU` para React/Vite, usando o layout e os componentes do projeto `C:\Developer\Fast FOOD\RPFOOD_REACTJS\SITE`.

## Tecnologia

- React 19
- TypeScript sobre JavaScript moderno
- Vite
- CSS e assets do layout RPFOOD_REACTJS

## Configuracao

Crie um `.env` a partir do `.env.example` quando precisar trocar API ou empresa:

```env
VITE_RPMENU_API_URL=http://127.0.0.1:9000/rpfood/v1
VITE_RPMENU_EMPRESA_ID=1
```

As variaveis antigas `VITE_RPFOOD_API_URL` e `VITE_RPFOOD_EMPRESA_ID` continuam aceitas como fallback para facilitar homologacao em ambientes ja configurados.

## Scripts

```bash
npm run dev
npm run build
npm run lint
npm run preview
```

## Paridade Inicial Migrada

- Home/cardapio por categorias
- Produtos por categoria
- Detalhe do item com tamanhos, opcionais e fracionamento
- Carrinho
- Login e cadastro do cliente
- Enderecos
- Finalizacao do pedido
- Acompanhamento e historico
- Pagamento Pix quando habilitado pela API
- Telas administrativas herdadas do layout de referencia

## Observacao

Os nomes de classes CSS e alguns caminhos de assets mantem o prefixo `rpfood` para preservar compatibilidade visual com o design system usado como referencia. A identidade do app, storage local e variaveis de ambiente foram separadas para `RPMENU`.
