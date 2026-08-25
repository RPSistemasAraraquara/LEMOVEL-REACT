import type { Opcional, Produto, ProdutoOpcional } from "./types";

type SizeOption = {
  code: "P" | "M" | "G" | "GG" | "EXTRA";
  label: string;
  value: number;
};

type SizeCode = SizeOption["code"];

function equalsIgnoreCase(left: string, right: string): boolean {
  return left.trim().toLowerCase() === right.trim().toLowerCase();
}

function sizeOptions(product: Produto): SizeOption[] {
  const options: SizeOption[] = [];

  if (product.valorTamanhoP > 0) {
    options.push({ code: "P", label: product.tamanhoP, value: product.valorTamanhoP });
  }

  if (product.valorTamanhoM > 0) {
    options.push({ code: "M", label: product.tamanhoM, value: product.valorTamanhoM });
  }

  if (product.valorTamanhoG > 0) {
    options.push({ code: "G", label: product.tamanhoG, value: product.valorTamanhoG });
  }

  if (product.valorTamanhoGG > 0) {
    options.push({ code: "GG", label: product.tamanhoGG, value: product.valorTamanhoGG });
  }

  if (product.valorTamanhoExtra > 0) {
    options.push({ code: "EXTRA", label: product.tamanhoExtra, value: product.valorTamanhoExtra });
  }

  return options;
}

function resolveProductSizeCodeInternal(product: Produto, selected: string): SizeCode | "" {
  if (!selected.trim()) {
    return "";
  }

  const normalized = selected.trim();
  for (const option of sizeOptions(product)) {
    if (
      equalsIgnoreCase(normalized, option.code) ||
      (option.code === "EXTRA" && equalsIgnoreCase(normalized, "XG")) ||
      equalsIgnoreCase(normalized, option.label)
    ) {
      return option.code;
    }
  }

  return "";
}

export function resolveProductSize(product: Produto, selected: string): string {
  const code = resolveProductSizeCodeInternal(product, selected);
  return sizeOptions(product).find((option) => option.code === code)?.label ?? "";
}

export function resolveProductSizeCode(product: Produto, selected: string): string {
  return resolveProductSizeCodeInternal(product, selected);
}

export function remapProductSize(product: Produto, selected: string, fallbackProduct?: Produto): string {
  const directMatch = resolveProductSize(product, selected);
  if (directMatch) {
    return directMatch;
  }

  const fallbackCode = fallbackProduct ? resolveProductSizeCodeInternal(fallbackProduct, selected) : "";
  if (!fallbackCode) {
    return "";
  }

  return sizeOptions(product).find((option) => option.code === fallbackCode)?.label ?? "";
}

/**
 * Indica se o produto realmente e vendido por tamanho.
 * Espelha a regra da API (RPFoodAPI.Controller.Base: `if produto.vendaPorTamanho`),
 * onde produto sem venda por tamanho sempre grava tamanho vazio.
 */
export function productSupportsSize(product: Produto): boolean {
  return product.vendaPorTamanho && sizeOptions(product).length > 0;
}

export function defaultProductSize(product: Produto): string {
  const resolvedDefault = resolveProductSize(product, product.tamanhoPadrao);
  if (resolvedDefault) {
    return resolvedDefault;
  }

  return sizeOptions(product)[0]?.label ?? "";
}

export function productPriceBySize(product: Produto, selected: string): number {
  const resolved = resolveProductSize(product, selected);
  const match = sizeOptions(product).find((option) => option.label === resolved);
  return match?.value || product.valFinal;
}

export function optionPriceBySize(option: Opcional, selected: string): number {
  const normalized = selected.trim();

  if (!normalized) {
    return option.valor;
  }

  if (option.valorTamanhoP > 0 && (equalsIgnoreCase(normalized, "P") || equalsIgnoreCase(normalized, option.tamanhoP))) {
    return option.valorTamanhoP;
  }

  if (option.valorTamanhoM > 0 && (equalsIgnoreCase(normalized, "M") || equalsIgnoreCase(normalized, option.tamanhoM))) {
    return option.valorTamanhoM;
  }

  if (option.valorTamanhoG > 0 && (equalsIgnoreCase(normalized, "G") || equalsIgnoreCase(normalized, option.tamanhoG))) {
    return option.valorTamanhoG;
  }

  if (option.valorTamanhoGG > 0 && (equalsIgnoreCase(normalized, "GG") || equalsIgnoreCase(normalized, option.tamanhoGG))) {
    return option.valorTamanhoGG;
  }

  if (
    option.valorTamanhoExtra > 0 &&
    (equalsIgnoreCase(normalized, "EXTRA") || equalsIgnoreCase(normalized, "XG") || equalsIgnoreCase(normalized, option.tamanhoExtra))
  ) {
    return option.valorTamanhoExtra;
  }

  return option.valor;
}

export function usesCategoryRule(options: ProdutoOpcional[]): boolean {
  return options.some((option) => option.groupId > 0);
}

export function categoryWithoutLimit(option: ProdutoOpcional): boolean {
  return option.groupId > 0 && option.opcionalMinimo <= 0 && option.opcionalMaximo <= 0;
}

/**
 * Limites do fracionamento, espelhando empresas.quantidade_maxima_fracao_produtos.
 * O valor representa o total de partes do item (sabor principal + sabores extras).
 */
export const MIN_FRACTION_PARTS = 2;
export const MAX_FRACTION_PARTS = 4;

/** Normaliza o valor vindo da API para a faixa aceita, caindo no maximo quando ausente ou invalido. */
export function normalizeMaxFractionParts(value: unknown): number {
  const parsed = Math.trunc(Number(value));

  if (!Number.isFinite(parsed) || parsed <= 0) {
    return MAX_FRACTION_PARTS;
  }

  return Math.min(MAX_FRACTION_PARTS, Math.max(MIN_FRACTION_PARTS, parsed));
}

/** Quantos sabores extras ainda cabem, dado o teto da empresa. O principal ja ocupa uma parte. */
export function maxExtraFractions(maxParts: number): number {
  return normalizeMaxFractionParts(maxParts) - 1;
}

export function countSelectedFractions(fractions: Record<number, number>): number {
  return Object.values(fractions).reduce((sum, quantity) => sum + quantity, 0);
}

export function principalFractionQuantity(fractions: Record<number, number>, maxParts: number): number {
  return normalizeMaxFractionParts(maxParts) - countSelectedFractions(fractions);
}

export function sizeButtons(product: Produto): Array<{ code: string; label: string; value: number }> {
  return sizeOptions(product);
}
