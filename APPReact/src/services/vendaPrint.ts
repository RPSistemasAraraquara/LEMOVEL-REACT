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

export const loadSalePrintContent = async (input: RPCheffSalePrintInput): Promise<string> => {
  const machineType = resolveMachineType(input.appSettings, input.usarRotaMaquininha);
  const provider = resolveConfiguredPaymentProvider(input.appSettings);
  const suppressInternalWindowsPrint =
    Platform.OS === 'android' &&
    input.usarRotaMaquininha !== false &&
    (provider === 'stone' || provider === 'cielo' || provider === 'getnet');
  return api.getSalePrint(input.idVenda, {
    numeroColunas: input.appSettings.impressaoColunas,
    impressaoInterna: suppressInternalWindowsPrint ? false : input.appSettings.utilizaImpressoraInterna,
    tipoMaquina: machineType
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
  if (
    Platform.OS === 'android' &&
    machineType === 'tmpPlugPag' &&
    provider === 'pagbank'
  ) {
    const printableContent = parsePrintCommandsToText(content);
    if (!printableContent.trim()) {
      throw new Error('Conteúdo de impressão vazio para PagBank.');
    }

    await executePlugPagReceiptPrint({
      content: printableContent,
      settings: appSettings
    });
  } else if (Platform.OS === 'android' && machineType === 'tmpStone' && provider === 'stone') {
    const printableContent = String(content || '').trim();
    if (!printableContent.trim()) {
      throw new Error('Conteúdo de impressão vazio para Stone.');
    }

    await executeStoneReceiptPrint({
      content: printableContent,
      settings: appSettings
    });
  } else if (Platform.OS === 'android' && machineType === 'tmpCielo' && provider === 'cielo') {
    const printableContent = String(content || '').trim();
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

  return content;
};

export const executeSalePrint = async (input: RPCheffSalePrintInput): Promise<string> => {
  const content = await loadSalePrintContent(input);
  return printSaleContent({
    content,
    appSettings: input.appSettings,
    usarRotaMaquininha: input.usarRotaMaquininha
  });
};
