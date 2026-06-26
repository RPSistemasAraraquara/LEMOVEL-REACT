export type CouvertLockCounts = {
  masculino: number;
  feminino: number;
};

export const normalizeCouvertCount = (value: unknown): number => {
  const parsed = Number(String(value ?? '').replace(',', '.'));
  const rounded = Math.round(parsed);
  return Number.isFinite(rounded) ? Math.max(0, rounded) : 0;
};

export const clampCouvertText = (value: unknown, minimum: number): string => (
  String(Math.max(normalizeCouvertCount(minimum), normalizeCouvertCount(value)))
);

export const adjustCouvertText = (current: unknown, delta: number, minimum: number): string => (
  String(Math.max(normalizeCouvertCount(minimum), normalizeCouvertCount(current) + delta))
);

export const buildCouvertReductionMessage = (
  next: CouvertLockCounts,
  minimum: CouvertLockCounts
): string => {
  const parts: string[] = [];

  if (next.masculino < minimum.masculino) {
    parts.push(`masculino ${minimum.masculino}`);
  }

  if (next.feminino < minimum.feminino) {
    parts.push(`feminino ${minimum.feminino}`);
  }

  return `Não é permitido diminuir couvert já lançado. Mínimo permitido: ${parts.join(' e ')}.`;
};

export const validateCouvertNotReduced = (
  next: CouvertLockCounts,
  minimum: CouvertLockCounts
): string | null => {
  const normalizedNext = {
    masculino: normalizeCouvertCount(next.masculino),
    feminino: normalizeCouvertCount(next.feminino)
  };
  const normalizedMinimum = {
    masculino: normalizeCouvertCount(minimum.masculino),
    feminino: normalizeCouvertCount(minimum.feminino)
  };

  if (
    normalizedNext.masculino >= normalizedMinimum.masculino &&
    normalizedNext.feminino >= normalizedMinimum.feminino
  ) {
    return null;
  }

  return buildCouvertReductionMessage(normalizedNext, normalizedMinimum);
};
