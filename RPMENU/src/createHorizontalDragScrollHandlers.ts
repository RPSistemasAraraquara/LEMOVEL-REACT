export type HorizontalDragState = {
  active: boolean;
  moved: boolean;
  pointerId: number | null;
  startX: number;
  startY: number;
  startScrollLeft: number;
  suppressClicksUntil: number;
};

/**
 * Distancia minima para tratar o gesto como arrasto e nao como clique.
 *
 * Um limiar baixo faz o tremor natural da mao ao clicar virar "arrasto", e o
 * clique acaba sendo cancelado sem o usuario entender o motivo.
 */
export const horizontalRailDragThreshold = 14;

/**
 * Margem a favor da rolagem vertical da pagina: so vira arrasto horizontal
 * quando a intencao no eixo X e claramente maior que no eixo Y.
 */
export const horizontalRailVerticalIntentBias = 8;

export type HorizontalDragIntent = "none" | "vertical" | "horizontal";

export function resolveHorizontalDragIntent(deltaX: number, deltaY: number): HorizontalDragIntent {
  const absDeltaX = Math.abs(deltaX);
  const absDeltaY = Math.abs(deltaY);

  if (absDeltaY >= horizontalRailDragThreshold && absDeltaY >= absDeltaX + horizontalRailVerticalIntentBias) {
    return "vertical";
  }

  if (absDeltaX < horizontalRailDragThreshold || absDeltaX < absDeltaY + horizontalRailVerticalIntentBias) {
    return "none";
  }

  return "horizontal";
}

export function createHorizontalDragState(): HorizontalDragState {
  return {
    active: false,
    moved: false,
    pointerId: null,
    startX: 0,
    startY: 0,
    startScrollLeft: 0,
    suppressClicksUntil: 0,
  };
}

export function isMousePrimaryButton(pointerType: string, button: number) {
  return pointerType !== "mouse" || button === 0;
}

/**
 * O arrasto por JS existe para o mouse, que nao tem rolagem por gesto.
 *
 * Em telas de toque quem rola o trilho e o proprio navegador: e mais fluido,
 * tem inercia e nao briga com a rolagem vertical da pagina. Se o JS tambem
 * mexesse no scrollLeft durante o toque, os dois disputariam o mesmo gesto.
 */
export function shouldStartPointerDrag(pointerType: string, button: number) {
  return pointerType === "mouse" && button === 0;
}

export function finishHorizontalDrag<T extends HTMLElement>(el: T | null, state: HorizontalDragState) {
  if (el && state.pointerId !== null && "releasePointerCapture" in el) {
    try {
      el.releasePointerCapture(state.pointerId);
    } catch {
      // Ignore browsers that already released the pointer.
    }
  }

  if (state.moved) {
    state.suppressClicksUntil = Date.now() + 220;
  }

  state.active = false;
  state.moved = false;
  state.pointerId = null;
}
