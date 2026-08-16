import { Platform } from 'react-native';
import { api, MachinePaymentType, MobileAppSettings } from './api';
import {
  executeCieloReceiptPrint,
  executeGetNetReceiptPrint,
  executePlugPagReceiptPrint,
  executeStoneReceiptPrint,
  resolveConfiguredPaymentProvider
} from './payment';

export type RPCheffSalePrintInput = {
  idVenda: number;
  appSettings: MobileAppSettings;
  usarRotaMaquininha?: boolean;
};

export const resolveMachineType = (
  settings: MobileAppSettings,
  usarRotaMaquininha = true
): MachinePaymentType => {
  if (!usarRotaMaquininha) return 'tmpNenhum';
  const provider = resolveConfiguredPaymentProvider(settings);
  if (provider === 'stone') return 'tmpStone';
  if (provider === 'pagbank') return 'tmpPlugPag';
  if (provider === 'cielo') return 'tmpCielo';
  return 'tmpNenhum';
};

const stripPrinterMarkup = (value: string): string =>
  String(value || '')
    .replace(/\r\n/g, '\n')
    .replace(/<[^>\n]+>/g, '')
    .replace(/\n[ \t]+/g, '\n')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

// Comando de imagem (ex.: DANFCe da NFC-e em base64) precisa chegar bruto aos
// modulos nativos para ser impresso como bitmap - nao pode ser achatado para
// texto.
export const contentHasImageCommand = (raw: string): boolean => {
  const base = String(raw || '').trim();
  if (!base.startsWith('[') && !base.startsWith('{')) return false;
  return /"type"\s*:\s*"image"/i.test(base);
};

export const parsePrintCommandsToText = (raw: string): string => {
  const extractLines = (payload: unknown): string[] => {
    if (!payload) return [];
    if (Array.isArray(payload)) {
      return payload.flatMap((item) => extractLines(item));
    }

    if (typeof payload === 'string') {
      return [payload];
    }

    if (typeof payload !== 'object') {
      return [];
    }

    const command = payload as Record<string, unknown>;
    const type = String(command.type || '').toLowerCase();
    const content = command.content;

    if (type === 'line') {
      return [String(content ?? '--------------------------------')];
    }

    if (type === 'text') {
      return [String(content ?? '')];
    }

    if (Array.isArray(command.commands)) {
      return extractLines(command.commands);
    }

    if (Array.isArray(command.data)) {
      return extractLines(command.data);
    }

    if (content !== undefined && content !== null) {
      return [String(content)];
    }

    return [];
  };

  const normalizeText = (value: string): string => stripPrinterMarkup(value);

  const tryParse = (value: string): string => {
    const parsed = JSON.parse(value);
    const lines = extractLines(parsed);
    const text = normalizeText(lines.join('\n'));
    return text || value;
  };

  const base = (raw || '').trim();
  if (!base) return '';

  if (base.startsWith('[') || base.startsWith('{')) {
    try {
      return tryParse(base);
    } catch {
      return stripPrinterMarkup(base);
    }
  }

  if ((base.startsWith('"[') && base.endsWith('"')) || (base.startsWith('"{') && base.endsWith('"'))) {
    try {
      const unquoted = JSON.parse(base);
      if (typeof unquoted === 'string') {
        return parsePrintCommandsToText(unquoted);
      }
      return stripPrinterMarkup(base);
    } catch {
      return stripPrinterMarkup(base);
    }
  }

  return stripPrinterMarkup(base);
};

const SUBTOTAL_RECEIPT_LINE_PATTERN = /^\s*Sub\s*-?\s*total\s*:/i;
const ITEM_TOTAL_RECEIPT_PATTERN = /=\s*R\$\s*(-?\d[\d.,]*)/i;

const parseReceiptMoney = (value: string): number | null => {
  const cleanValue = String(value || '').replace(/[^\d,.-]/g, '');
  if (!cleanValue) return null;

  const commaIndex = cleanValue.lastIndexOf(',');
  const dotIndex = cleanValue.lastIndexOf('.');
  const decimalIndex = Math.max(commaIndex, dotIndex);
  const normalized =
    decimalIndex >= 0
      ? `${cleanValue.slice(0, decimalIndex).replace(/[^\d-]/g, '') || '0'}.${cleanValue
          .slice(decimalIndex + 1)
          .replace(/\D/g, '')
          .padEnd(2, '0')
          .slice(0, 2)}`
      : cleanValue.replace(/[^\d-]/g, '');

  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
};

const formatReceiptMoney = (value: number): string => {
  const sign = value < 0 ? '-' : '';
  const [wholeValue, decimalValue] = Math.abs(value).toFixed(2).split('.');
  const wholeWithThousands = wholeValue.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `${sign}${wholeWithThousands},${decimalValue}`;
};

const extractReceiptItemsSubtotal = (content: string): number | null => {
  const lines = String(content || '').split(/\r\n|\n|\r/);
  let subtotalInCents = 0;
  let foundItemTotal = false;

  lines.forEach((line) => {
    const match = line.match(ITEM_TOTAL_RECEIPT_PATTERN);
    if (!match) return;

    const value = parseReceiptMoney(match[1]);
    if (value === null || value < 0 || value > 1000000) return;

    subtotalInCents += Math.round(value * 100);
    foundItemTotal = true;
  });

  return foundItemTotal ? subtotalInCents / 100 : null;
};

const replaceSubtotalLineInText = (
  content: string,
  replacementLine: string
): { content: string; changed: boolean } => {
  const originalContent = String(content || '');
  const lineBreak = originalContent.includes('\r\n')
    ? '\r\n'
    : originalContent.includes('\r')
      ? '\r'
      : '\n';
  const lines = originalContent.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
  let changed = false;

  const nextLines = lines.map((line) => {
    const lineWithoutMarkup = stripPrinterMarkup(line);
    if (!SUBTOTAL_RECEIPT_LINE_PATTERN.test(lineWithoutMarkup)) {
      return line;
    }

    changed = true;
    const leadingSpaces = line.match(/^\s*/)?.[0] || '';
    return `${leadingSpaces}${replacementLine}`;
  });

  return {
    content: changed ? nextLines.join(lineBreak) : originalContent,
    changed
  };
};

const replaceSubtotalLineInPayload = (
  payload: unknown,
  replacementLine: string
): { payload: unknown; changed: boolean } => {
  if (typeof payload === 'string') {
    const result = replaceSubtotalLineInText(payload, replacementLine);
    return { payload: result.content, changed: result.changed };
  }

  if (Array.isArray(payload)) {
    let changed = false;
    const nextPayload = payload.map((item) => {
      const result = replaceSubtotalLineInPayload(item, replacementLine);
      changed = changed || result.changed;
      return result.payload;
    });
    return { payload: changed ? nextPayload : payload, changed };
  }

  if (!payload || typeof payload !== 'object') {
    return { payload, changed: false };
  }

  const currentPayload = payload as Record<string, unknown>;
  const nextPayload: Record<string, unknown> = { ...currentPayload };
  let changed = false;

  Object.keys(currentPayload).forEach((key) => {
    const result = replaceSubtotalLineInPayload(currentPayload[key], replacementLine);
    if (result.changed) {
      nextPayload[key] = result.payload;
      changed = true;
    }
  });

  return { payload: changed ? nextPayload : payload, changed };
};

export const normalizeSalePrintSubtotal = (raw: string): string => {
  const base = String(raw || '').trim();
  if (!base) return '';

  const textContent = parsePrintCommandsToText(base);
  const itemsSubtotal = extractReceiptItemsSubtotal(textContent);
  if (itemsSubtotal === null || itemsSubtotal <= 0) return base;

  const replacementLine = `Sub total: R$ ${formatReceiptMoney(itemsSubtotal)}`;

  if (base.startsWith('[') || base.startsWith('{')) {
    try {
      const parsedPayload = JSON.parse(base);
      const result = replaceSubtotalLineInPayload(parsedPayload, replacementLine);
      if (result.changed) {
        return JSON.stringify(result.payload);
      }
    } catch {
      // Continua no fallback de texto simples abaixo.
    }
  }

  if ((base.startsWith('"[') && base.endsWith('"')) || (base.startsWith('"{') && base.endsWith('"'))) {
    try {
      const unquotedPayload = JSON.parse(base);
      if (typeof unquotedPayload === 'string') {
        return normalizeSalePrintSubtotal(unquotedPayload);
      }
    } catch {
      // Continua no fallback de texto simples abaixo.
    }
  }

  const result = replaceSubtotalLineInText(base, replacementLine);
  if (result.changed) return result.content;

  const textResult = replaceSubtotalLineInText(textContent, replacementLine);
  return textResult.changed ? textResult.content : base;
};

export const loadSalePrintContent = async (input: RPCheffSalePrintInput): Promise<string> => {
  const machineType = resolveMachineType(input.appSettings, input.usarRotaMaquininha);
  const provider = resolveConfiguredPaymentProvider(input.appSettings);
  const suppressInternalWindowsPrint =
    Platform.OS === 'android' &&
    input.usarRotaMaquininha !== false &&
    (provider === 'stone' || provider === 'pagbank' || provider === 'cielo' || provider === 'getnet');
  return api.getSalePrint(input.idVenda, {
    numeroColunas: input.appSettings.impressaoColunas,
    impressaoInterna: suppressInternalWindowsPrint ? false : input.appSettings.utilizaImpressoraInterna,
    tipoMaquina: machineType,
    imprimirFichaIndividualProdutos: input.appSettings.imprimirFichaIndividualProdutos
  });
};

export const printSaleContent = async ({
  content,
  appSettings,
  usarRotaMaquininha = true
}: {
  content: string;
  appSettings: MobileAppSettings;
  usarRotaMaquininha?: boolean;
}): Promise<string> => {
  const machineType = resolveMachineType(appSettings, usarRotaMaquininha);
  const provider = resolveConfiguredPaymentProvider(appSettings);
  const normalizedContent = normalizeSalePrintSubtotal(content);
  if (
    Platform.OS === 'android' &&
    machineType === 'tmpPlugPag' &&
    provider === 'pagbank'
  ) {
    // DANFCe (NFC-e): manda o JSON bruto com a imagem para o modulo nativo.
    const printableContent = contentHasImageCommand(normalizedContent)
      ? normalizedContent.trim()
      : parsePrintCommandsToText(normalizedContent);
    if (!printableContent.trim()) {
      throw new Error('Conteúdo de impressão vazio para PagBank.');
    }

    await executePlugPagReceiptPrint({
      content: printableContent,
      settings: appSettings
    });
  } else if (Platform.OS === 'android' && machineType === 'tmpStone' && provider === 'stone') {
    const printableContent = String(normalizedContent || '').trim();
    if (!printableContent.trim()) {
      throw new Error('Conteúdo de impressão vazio para Stone.');
    }

    await executeStoneReceiptPrint({
      content: printableContent,
      settings: appSettings
    });
  } else if (Platform.OS === 'android' && machineType === 'tmpCielo' && provider === 'cielo') {
    const printableContent = String(normalizedContent || '').trim();
    if (!printableContent.trim()) {
      throw new Error('Conteúdo de impressão vazio para Cielo.');
    }

    await executeCieloReceiptPrint({
      content: printableContent,
      settings: appSettings
    });
  } else if (Platform.OS === 'android' && provider === 'getnet') {
    await executeGetNetReceiptPrint({
      settings: appSettings
    });
  }

  return normalizedContent;
};

export const executeSalePrint = async (input: RPCheffSalePrintInput): Promise<string> => {
  const content = await loadSalePrintContent(input);
  return printSaleContent({
    content,
    appSettings: input.appSettings,
    usarRotaMaquininha: input.usarRotaMaquininha
  });
};
