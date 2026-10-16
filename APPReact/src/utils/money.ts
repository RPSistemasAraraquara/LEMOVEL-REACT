export type MonetaryPart = {
  value: number;
  quantity?: number;
  count?: number;
};

// The API stores prices with four decimal places and item quantities with three.
// Sum their exact scaled products before rounding the line total to cents.
const scaleDecimal = (value: number, places: number): number => {
  if (!Number.isFinite(value)) {
    throw new RangeError('Valor monetário inválido.');
  }
  const scaled = Number(Math.abs(value).toFixed(places).replace('.', ''));
  if (!Number.isSafeInteger(scaled)) {
    throw new RangeError('Valor monetário fora do intervalo seguro.');
  }
  return value < 0 ? -scaled : scaled;
};

export const roundLineAmount = (parts: readonly MonetaryPart[]): number => {
  let total = 0;
  for (const { value, quantity = 1, count = 1 } of parts) {
    if (!Number.isSafeInteger(count)) {
      throw new RangeError('Quantidade de opcionais inválida.');
    }
    const term = scaleDecimal(value, 4) * scaleDecimal(quantity, 3) * count;
    if (!Number.isSafeInteger(term) || !Number.isSafeInteger(total + term)) {
      throw new RangeError('Total monetário fora do intervalo seguro.');
    }
    total += term;
  }

  // One cent is 100000 units at the combined 4 + 3 decimal scale.
  const absolute = Math.abs(total);
  const cents = Math.trunc(absolute / 100000) + (absolute % 100000 >= 50000 ? 1 : 0);
  return Math.sign(total) * cents / 100;
};
