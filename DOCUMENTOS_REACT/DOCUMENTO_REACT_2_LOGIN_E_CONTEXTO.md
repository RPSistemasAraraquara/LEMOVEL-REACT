# Documento React 2 - Login e Contexto

## Arquivos principais

- [LoginScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/LoginScreen.tsx:22)
- [AppContext.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/context/AppContext.tsx:538)
- [api.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/api.ts:2811)
- [APIRPCheff.Controller.Usuario.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Usuario.pas:1)
- [APIRPCheff.DAO.Usuario.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Usuario.pas:1)

## Fluxo completo do login

1. O operador digita usuario e senha na [LoginScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/LoginScreen.tsx:22).
2. O metodo `onSubmit` valida campos vazios.
3. A tela chama `checkApiConnection()`.
4. A tela consulta `api.getCompanyInfo()` e verifica se `utilizaRPMovel` esta ativo.
5. A tela chama `login(normalizedUser, normalizedPassword)` do contexto.
6. O [AppContext.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/context/AppContext.tsx:538) chama `api.login(...)`.
7. O [api.ts](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/services/api.ts:2811) faz `POST /usuario/login`.
8. O controller Delphi recebe em [APIRPCheff.Controller.Usuario.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Controller/APIRPCheff.Controller.Usuario.pas:59).
9. O controller chama `UsuarioDAO.Busca(login, senha)`.
10. O DAO faz select na tabela `usuarios`.
11. Se achar usuario valido, devolve o perfil com permissoes.
12. O contexto salva em `setUser(userProfile)`.
13. O `AppNavigator` passa a liberar as telas internas.
14. A `LoginScreen` detecta `loggedUser` e navega para `Inicial`.

## O que a API verifica na tabela `usuarios`

Em [APIRPCheff.DAO.Usuario.pas](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/API/Fontes/Source/Model/DAO/APIRPCheff.DAO.Usuario.pas:24):

- `emp_001 = :idEmpresa`
- `usu_003 = login`
- `usu_004 = senha`
- `sit_001 = 4`
- `b_funcao_garcom`

Ou seja:

- usuario da empresa certa
- login e senha corretos
- usuario ativo
- usuario permitido no fluxo de garcom/operador

## Onde ficam as permissoes do usuario

O DAO carrega campos como:

- `permiteCancelarItemMobile`
- `permitePreFechamentoMesaComanda`
- `permiteFechamentoMesaComanda`
- `permiteJuntarMesaComanda`
- `permiteReabrirMesaComanda`
- `permitePagamentoParcial`
- `permiteDescontoFechamento`

Depois isso fica em `user` dentro do `AppContext`.

## O que e o `AppContext`

Em [AppContext.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/context/AppContext.tsx:190), o `AppProvider` guarda:

- usuario logado
- configuracao do app
- mesas/comandas
- produtos
- categorias
- carrinho
- mesa ativa

Se voce pensar em Delphi:

- esse arquivo faz o papel de uma sessao global viva da aplicacao
