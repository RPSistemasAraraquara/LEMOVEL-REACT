import type { KeyboardEvent } from "react";

/**
 * Props para transformar um card clicavel (div/article com onClick) em algo que
 * o teclado e o leitor de tela alcancam.
 *
 * Use apenas em cards que NAO tenham botao ou link dentro: ARIA nao permite
 * conteudo interativo dentro de role="button". Quando o card ja tem um botao
 * proprio (ex.: o "+" da listagem), deixe a navegacao por teclado com esse botao
 * e apenas descreva a acao nele com aria-label.
 */
export function clickableCardProps(onActivate: () => void, label: string) {
  return {
    role: "button",
    tabIndex: 0,
    "aria-label": label,
    onClick: onActivate,
    onKeyDown: (event: KeyboardEvent<HTMLElement>) => {
      if (event.key !== "Enter" && event.key !== " ") {
        return;
      }

      event.preventDefault();
      onActivate();
    },
  } as const;
}
