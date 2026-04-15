# Documento React 1 - Fundamentos

## O que voce precisa fixar primeiro

Se voce vem de Delphi, faca esta traducao mental:

- `Screen` = parecido com `Form`
- `Context` = parecido com um DataModule global da sessao
- `api.ts` = parecido com uma camada REST central
- `useState` = estado visual da tela
- `useRef` = campo privado que nao redesenha tela
- `useEffect` = reacao a ciclo de vida ou mudanca de valor
- `useMemo` = cache de calculo
- `navigation.navigate(...)` = abrir outra tela

## Onde o app comeca

1. [index.js](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/index.js:1) registra o app.
2. [App.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/App.tsx:1) sobe `SafeAreaProvider`, `AppProvider` e `AppNavigator`.
3. [AppNavigator.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/navigation/AppNavigator.tsx:1) define as telas.
4. [AppContext.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/context/AppContext.tsx:190) guarda o estado global.

## Como ler qualquer componente React

1. Veja os `imports`.
2. Veja os `useState`.
3. Veja os `useEffect`.
4. Veja as funcoes locais.
5. Leia o `return (...)`.

## Diferenca central entre Delphi e React

No Delphi, voce costuma mandar a tela atualizar.

No React, voce muda o estado e a tela redesenha sozinha.

## Exemplo simples

Na [LoginScreen.tsx](/c:/Users/Rafael/Desktop/Developer/Fast%20FOOD/LEMOVEL-REACT/APPReact/src/screens/LoginScreen.tsx:22):

- `user` e `senha` sao `useState`
- `loggedUser` vem de `useApp()`
- quando `loggedUser` aparece, a tela navega para `Inicial`

## Regra de bolso

- dado compartilhado entre varias telas: `Context`
- dado so da tela: `useState`
- dado tecnico de apoio: `useRef`
- calculo derivado: `useMemo`
