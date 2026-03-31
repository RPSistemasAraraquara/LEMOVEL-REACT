import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
import { MobileAppSettings, PaymentMethod } from './api';

export type RPCheffPaymentProvider = 'manual' | 'stone' | 'pagbank' | 'cielo';

export type RPCheffPaymentInput = {
  value: number;
  method: PaymentMethod;
  availableMethods: PaymentMethod[];
  settings: MobileAppSettings;
  idVenda?: number;
  onProgress?: (message: string) => void;
};

export type RPCheffPaymentResult = {
  approved: boolean;
  provider: RPCheffPaymentProvider;
  method: PaymentMethod;
  value: number;
  sfiCodigo?: number;
  nsu: string;
  message: string;
};

const notifyPaymentProgress = (input: RPCheffPaymentInput, message: string) => {
  try {
    input.onProgress?.(message);
  } catch {
    // ignora falha de callback de UI
  }
};

const ELECTRONIC_SFI = new Set([3, 4, 6, 11, 17]);
const PAGBANK_SUPPORTED_SFI = new Set([3, 4, 6, 11, 17]);
const STONE_SUPPORTED_SFI = new Set([3, 4, 6, 11, 17]);
const CIELO_SUPPORTED_SFI = new Set([3, 4, 6, 11, 17]);

type PaymentTerminalTransactionType = 'credit' | 'debit' | 'pix' | 'voucher';

type RPCheffNativePlugPagPayload = {
  amount: number;
  value: number;
  sfiCodigo: number;
  transactionType: PaymentTerminalTransactionType;
  idVenda?: number;
  methodCode: number;
  methodDescription: string;
  installments?: number;
  installmentType?: 'merchant' | 'buyer' | 'none';
  userReference?: string;
};

type RPCheffNativePlugPagPrintPayload = {
  content: string;
  columns?: number;
  title?: string;
};

type RPCheffNativePlugPagModule = {
  executePayment?: (payload: RPCheffNativePlugPagPayload) => Promise<unknown>;
  doPayment?: (payload: RPCheffNativePlugPagPayload) => Promise<unknown>;
  pay?: (payload: RPCheffNativePlugPagPayload) => Promise<unknown>;
  printReceipt?: (payload: RPCheffNativePlugPagPrintPayload) => Promise<unknown>;
  preparePayment?: () => Promise<unknown>;
  abortPayment?: () => Promise<unknown>;
  abort?: () => Promise<unknown>;
  cancelPayment?: () => Promise<unknown>;
};

type RPCheffNativePlugPagResult = {
  approved: boolean;
  nsu: string;
  message: string;
  sfiCodigo?: number;
};

type RPCheffNativePlugPagProgressEvent = {
  status?: string;
  message?: string;
  eventCode?: number;
};

type RPCheffNativeStonePayload = {
  amount: number;
  value: number;
  sfiCodigo: number;
  transactionType: PaymentTerminalTransactionType;
  methodCode: number;
  methodDescription: string;
  installments?: number;
  installmentType?: 'merchant' | 'buyer' | 'none';
  orderId?: string;
};

type RPCheffNativeStoneModule = {
  executePayment?: (payload: RPCheffNativeStonePayload) => Promise<unknown>;
  doPayment?: (payload: RPCheffNativeStonePayload) => Promise<unknown>;
  pay?: (payload: RPCheffNativeStonePayload) => Promise<unknown>;
  printReceipt?: (payload: RPCheffNativePlugPagPrintPayload) => Promise<unknown>;
};

type RPCheffNativeStoneResult = {
  approved: boolean;
  nsu: string;
  message: string;
  sfiCodigo?: number;
};

type RPCheffNativeCieloPayload = {
  amount: number;
  value: number;
  sfiCodigo: number;
  transactionType: PaymentTerminalTransactionType;
  methodCode: number;
  methodDescription: string;
  installments?: number;
  paymentCode?: string;
  accessToken?: string;
  clientId?: string;
  email?: string;
};

type RPCheffNativeCieloModule = {
  executePayment?: (payload: RPCheffNativeCieloPayload) => Promise<unknown>;
  doPayment?: (payload: RPCheffNativeCieloPayload) => Promise<unknown>;
  pay?: (payload: RPCheffNativeCieloPayload) => Promise<unknown>;
  printReceipt?: (payload: RPCheffNativePlugPagPrintPayload) => Promise<unknown>;
};

type RPCheffNativeCieloResult = {
  approved: boolean;
  nsu: string;
  message: string;
  sfiCodigo?: number;
};

const NATIVE_PAYMENT_TIMEOUT_MS = 180000;

const withTimeout = <T>(promise: Promise<T>, timeoutMs: number, timeoutMessage: string): Promise<T> =>
  new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => {
      reject(new Error(timeoutMessage));
    }, timeoutMs);

    promise
      .then((result) => {
        clearTimeout(timer);
        resolve(result);
      })
      .catch((error) => {
        clearTimeout(timer);
        reject(error);
      });
  });

const normalizeText = (value?: string) =>
  (value || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();

const createNsu = () => `MOB-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

const detectSfiByText = (text?: string): number | undefined => {
  const normalized = normalizeText(text);
  if (!normalized) return undefined;
  if (normalized.includes('pix')) return 17;
  if (normalized.includes('credito') || normalized.includes('credit')) return 3;
  if (normalized.includes('debito') || normalized.includes('debit')) return 4;
  if (normalized.includes('refeicao') || normalized.includes('voucher') || normalized.includes('alimentacao')) return 11;
  return undefined;
};

const detectSfiByDescription = (description?: string): number | undefined => {
  const text = normalizeText(description);
  if (!text) return undefined;
  return detectSfiByText(text);
};

const detectSfi = (method: PaymentMethod): number | undefined => {
  if (typeof method.sfiCodigo === 'number' && Number.isFinite(method.sfiCodigo) && method.sfiCodigo > 0) {
    return method.sfiCodigo;
  }
  return detectSfiByText(method.sfiDescricao) ?? detectSfiByDescription(method.descricao);
};

const isOnlineTerminalPaymentMethod = (method: PaymentMethod): boolean => {
  if (method.utilizaPagamentoOnline || method.pagamentoEletronico) {
    return true;
  }

  const sfi = detectSfi(method);
  if (typeof sfi === 'number' && ELECTRONIC_SFI.has(sfi)) return true;

  const text = normalizeText(method.descricao);
  return (
    text.includes('cartao') ||
    text.includes('credito') ||
    text.includes('debito') ||
    text.includes('pix') ||
    text.includes('voucher') ||
    text.includes('refeicao')
  );
};

export const isElectronicPaymentMethod = (method: PaymentMethod): boolean => {
  return isOnlineTerminalPaymentMethod(method);
};

const mapIntegrationIndexToProvider = (index: number): RPCheffPaymentProvider => {
  if (index === 2) return 'stone';
  if (index === 3) return 'pagbank';
  if (index === 4) return 'cielo';
  return 'manual';
};

const parseIntegrationProvider = (value: unknown): RPCheffPaymentProvider | null => {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return mapIntegrationIndexToProvider(value);
  }

  if (typeof value !== 'string') {
    return null;
  }

  const normalized = normalizeText(value);
  if (!normalized) {
    return null;
  }

  if (normalized === 'stone') return 'stone';
  if (normalized === 'cielo') return 'cielo';
  if (
    normalized === 'pagbank' ||
    normalized === 'plugpag' ||
    normalized === 'tmpplugpag' ||
    normalized === 'tmplugpag'
  ) {
    return 'pagbank';
  }
  if (normalized === 'vero') return 'manual';

  const parsedIndex = Number(normalized);
  if (Number.isFinite(parsedIndex)) {
    return mapIntegrationIndexToProvider(parsedIndex);
  }

  return null;
};

const resolveProvider = (settings: MobileAppSettings): RPCheffPaymentProvider => {
  const values = ((settings || {}) as Record<string, unknown>) || {};
  const candidates = [
    values.tipoIntegracao,
    values.tipo_integracao,
    values.tipoMaquinaPagamento,
    values.tipo_maquina_pagamento,
    values.tipoMaquina,
    values.tipo_maquina,
    values.cbTipoIntegracao,
    values.cb_tipo_integracao
  ];

  for (const candidate of candidates) {
    const provider = parseIntegrationProvider(candidate);
    if (provider) {
      return provider;
    }
  }

  return 'manual';
};

export const resolveConfiguredPaymentProvider = (settings: MobileAppSettings): RPCheffPaymentProvider => {
  return resolveProvider(settings);
};

export const resolvePaymentProviderForMethod = (
  settings: MobileAppSettings,
  method: PaymentMethod
): RPCheffPaymentProvider => {
  if (!isElectronicPaymentMethod(method)) {
    return 'manual';
  }

  return resolveProvider(settings);
};

export const requiresPaymentProcessingAtAdd = (
  settings: MobileAppSettings,
  method: PaymentMethod
): boolean => {
  return resolvePaymentProviderForMethod(settings, method) !== 'manual';
};

export const formatPaymentProviderLabel = (provider: RPCheffPaymentProvider): string => {
  if (provider === 'pagbank') return 'PagBank';
  if (provider === 'stone') return 'Stone';
  if (provider === 'cielo') return 'Cielo';
  return 'maquininha';
};

const parseNativeBoolean = (value: unknown): boolean | undefined => {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    const text = normalizeText(value);
    if (['true', '1', 'sim', 'yes', 'ok', 'aprovado', 'approved', 'success', 'sucesso'].includes(text)) return true;
    if (['false', '0', 'nao', 'no', 'erro', 'error', 'negado', 'denied'].includes(text)) return false;
  }
  return undefined;
};

const parseNativeCodeApproved = (value: unknown): boolean | undefined => {
  if (typeof value === 'number') {
    return value === 0 || value === 200;
  }

  if (typeof value === 'string') {
    const text = normalizeText(value);
    if (['0', '00', '200', 'success', 'sucesso', 'approved', 'aprovado'].includes(text)) return true;
    if (['1', '-1', 'erro', 'error', 'negado', 'denied'].includes(text)) return false;
  }

  return undefined;
};

const parseNativeApproved = (raw: unknown): boolean => {
  if (!raw || typeof raw !== 'object') return true;
  const value = raw as Record<string, unknown>;

  const direct =
    parseNativeBoolean(value.approved) ??
    parseNativeBoolean(value.success) ??
    parseNativeBoolean(value.sucesso) ??
    parseNativeBoolean(value.resultado) ??
    parseNativeBoolean(value.status);

  if (typeof direct === 'boolean') return direct;

  const byCode =
    parseNativeCodeApproved(value.code) ??
    parseNativeCodeApproved(value.codigo) ??
    parseNativeCodeApproved(value.statusCode) ??
    parseNativeCodeApproved(value.responseCode);

  if (typeof byCode === 'boolean') return byCode;

  return true;
};

const parseNativeMessage = (raw: unknown): string | undefined => {
  if (!raw || typeof raw !== 'object') return undefined;
  const value = raw as Record<string, unknown>;
  const candidates = [
    value.message,
    value.mensagem,
    value.responseMessage,
    value.description,
    value.descricao
  ];
  const message = candidates.find((item) => typeof item === 'string' && String(item).trim().length > 0);
  return typeof message === 'string' ? message : undefined;
};

const parseNativeNsu = (raw: unknown): string | undefined => {
  if (!raw || typeof raw !== 'object') return undefined;
  const value = raw as Record<string, unknown>;
  const candidates = [
    value.nsu,
    value.NSU,
    value.authorizationCode,
    value.autorizacao,
    value.codigoAutorizacao,
    value.transactionCode,
    value.transactionId
  ];
  const nsu = candidates.find((item) => item !== undefined && item !== null && String(item).trim().length > 0);
  return nsu !== undefined && nsu !== null ? String(nsu).trim() : undefined;
};

const parseNativeSfi = (raw: unknown, fallback?: number): number | undefined => {
  if (!raw || typeof raw !== 'object') return fallback;
  const value = raw as Record<string, unknown>;
  const parsed = value.sfiCodigo ?? value.sfi ?? value.sfi_code;
  if (typeof parsed === 'number' && Number.isFinite(parsed)) return parsed;
  if (typeof parsed === 'string') {
    const num = Number(parsed);
    if (Number.isFinite(num)) return num;
  }
  return fallback;
};

const getNativeExecuteMethod = <T>(
  module: {
    executePayment?: (payload: T) => Promise<unknown>;
    doPayment?: (payload: T) => Promise<unknown>;
    pay?: (payload: T) => Promise<unknown>;
  } | null
) => {
  if (!module) return null;
  return (
    (typeof module.executePayment === 'function' && module.executePayment.bind(module)) ||
    (typeof module.doPayment === 'function' && module.doPayment.bind(module)) ||
    (typeof module.pay === 'function' && module.pay.bind(module)) ||
    null
  );
};

const getNativeAbortMethod = (
  module: {
    abortPayment?: () => Promise<unknown>;
    abort?: () => Promise<unknown>;
    cancelPayment?: () => Promise<unknown>;
  } | null
) => {
  if (!module) return null;
  return (
    (typeof module.abortPayment === 'function' && module.abortPayment.bind(module)) ||
    (typeof module.abort === 'function' && module.abort.bind(module)) ||
    (typeof module.cancelPayment === 'function' && module.cancelPayment.bind(module)) ||
    null
  );
};

const getNativePrintMethod = (
  module: {
    printReceipt?: (payload: RPCheffNativePlugPagPrintPayload) => Promise<unknown>;
  } | null
) => {
  if (!module) return null;
  return (
    (typeof module.printReceipt === 'function' && module.printReceipt.bind(module)) ||
    null
  );
};

const getPlugPagModule = (): RPCheffNativePlugPagModule | null => {
  const native = (NativeModules || {}) as Record<string, unknown>;
  const candidates = ['RPCheffPlugPag', 'RPCheffPagBank', 'PlugPagModule', 'RNPlugPag'];

  for (const key of candidates) {
    const module = native[key] as RPCheffNativePlugPagModule | undefined;
    if (
      module &&
      (typeof module.executePayment === 'function' ||
        typeof module.doPayment === 'function' ||
        typeof module.pay === 'function')
    ) {
      return module;
    }
  }

  return null;
};

const getPlugPagEmitter = (module: RPCheffNativePlugPagModule | null): NativeEventEmitter | null => {
  if (!module || Platform.OS !== 'android') {
    return null;
  }

  try {
    return new NativeEventEmitter(module as never);
  } catch {
    return null;
  }
};

const getStoneModule = (): RPCheffNativeStoneModule | null => {
  const native = (NativeModules || {}) as Record<string, unknown>;
  const candidates = ['RPCheffStone', 'RNStone', 'StoneModule'];

  for (const key of candidates) {
    const module = native[key] as RPCheffNativeStoneModule | undefined;
    if (getNativeExecuteMethod(module || null)) {
      return module || null;
    }
  }

  return null;
};

const getCieloModule = (): RPCheffNativeCieloModule | null => {
  const native = (NativeModules || {}) as Record<string, unknown>;
  const candidates = ['RPCheffCielo', 'RNCielo', 'CieloModule'];

  for (const key of candidates) {
    const module = native[key] as RPCheffNativeCieloModule | undefined;
    if (getNativeExecuteMethod(module || null)) {
      return module || null;
    }
  }

  return null;
};

const resolveTransactionType = (
  method: PaymentMethod,
  sfiCodigo?: number
): PaymentTerminalTransactionType | null => {
  if (sfiCodigo === 3) return 'credit';
  if (sfiCodigo === 4) return 'debit';
  if (sfiCodigo === 17) return 'pix';
  if (sfiCodigo === 6 || sfiCodigo === 11) return 'voucher';

  const text = normalizeText(method.descricao);
  if (text.includes('credito') || text.includes('credit')) return 'credit';
  if (text.includes('debito') || text.includes('debit')) return 'debit';
  if (text.includes('pix')) return 'pix';
  if (text.includes('voucher') || text.includes('refeicao') || text.includes('alimentacao')) return 'voucher';

  return null;
};

const executePlugPagNative = async (
  input: RPCheffPaymentInput,
  sfiCodigo: number
): Promise<RPCheffNativePlugPagResult | null> => {
  if (Platform.OS !== 'android') {
    throw new Error('PagBank disponível somente no Android.');
  }

  const module = getPlugPagModule();
  if (!module) {
    throw new Error('Módulo nativo PagBank não encontrado no app instalado.');
  }

  const methodFn = getNativeExecuteMethod<RPCheffNativePlugPagPayload>(module);

  if (!methodFn) {
    throw new Error('Método nativo da PagBank não disponível neste build.');
  }

  const transactionType = resolveTransactionType(input.method, sfiCodigo);
  if (!transactionType) {
    throw new Error('Forma de pagamento não suportada para PagBank.');
  }

  const payload: RPCheffNativePlugPagPayload = {
    amount: Math.max(1, Math.round(input.value * 100)),
    value: input.value,
    sfiCodigo,
    transactionType,
    idVenda: input.idVenda,
    methodCode: input.method.codigo,
    methodDescription: input.method.descricao,
    installments: 1,
    installmentType: 'none',
    userReference: `${Date.now()}`
  };

  let rawResult: unknown;
  const emitter = getPlugPagEmitter(module);
  const progressSubscription =
    emitter && typeof input.onProgress === 'function'
      ? emitter.addListener('RPCheffPlugPagProgress', (event: RPCheffNativePlugPagProgressEvent) => {
          if (typeof event?.message === 'string' && event.message.trim().length > 0) {
            input.onProgress?.(event.message.trim());
          }
        })
      : null;
  try {
    input.onProgress?.('Inicializando PagBank...');
    rawResult = await withTimeout(
      methodFn(payload),
      NATIVE_PAYMENT_TIMEOUT_MS,
      'Tempo limite ao aguardar retorno da PagBank.'
    );
  } catch (error: any) {
    throw new Error(error?.message || 'Falha ao processar pagamento na maquininha PagBank.');
  } finally {
    progressSubscription?.remove();
  }

  const approved = parseNativeApproved(rawResult);
  const message = parseNativeMessage(rawResult);
  if (!approved) {
    throw new Error(message || 'Pagamento negado pela maquininha PagBank.');
  }

  return {
    approved: true,
    nsu: parseNativeNsu(rawResult) || createNsu(),
    message: message || 'Pagamento aprovado via PAGBANK.',
    sfiCodigo: parseNativeSfi(rawResult, sfiCodigo)
  };
};

export const abortActivePayment = async (settings: MobileAppSettings): Promise<boolean> => {
  if (Platform.OS !== 'android') return false;
  if (resolveConfiguredPaymentProvider(settings) !== 'pagbank') return false;

  const module = getPlugPagModule();
  const abortFn = getNativeAbortMethod(module);
  if (!abortFn) return false;

  try {
    await abortFn();
    return true;
  } catch {
    return false;
  }
};

export const preparePaymentProvider = async (settings: MobileAppSettings): Promise<boolean> => {
  if (Platform.OS !== 'android') return false;
  if (resolveConfiguredPaymentProvider(settings) !== 'pagbank') return false;

  const module = getPlugPagModule();
  if (!module || typeof module.preparePayment !== 'function') {
    return false;
  }

  try {
    await module.preparePayment();
    return true;
  } catch {
    return false;
  }
};

export const executePlugPagReceiptPrint = async ({
  content,
  settings,
  title
}: {
  content: string;
  settings: MobileAppSettings;
  title?: string;
}): Promise<boolean> => {
  if (Platform.OS !== 'android') return false;
  if (resolveConfiguredPaymentProvider(settings) !== 'pagbank') return false;

  const printableContent = String(content || '').trim();
  if (!printableContent) {
    throw new Error('Conteúdo de impressão vazio para PagBank.');
  }

  const module = getPlugPagModule();
  const printFn = getNativePrintMethod(module);
  if (!printFn) {
    throw new Error('Método de impressão PagBank não disponível neste build.');
  }

  try {
    await withTimeout(
      printFn({
        content: printableContent,
        columns: Number(settings.impressaoColunas || 32),
        ...(typeof title === 'string' && title.trim() ? { title: title.trim() } : {})
      }),
      60000,
      'Tempo limite ao imprimir na PagBank.'
    );
    return true;
  } catch (error: any) {
    throw new Error(error?.message || 'Falha ao imprimir na PagBank.');
  }
};

const executeNativeTerminalReceiptPrint = async ({
  module,
  providerLabel,
  content,
  columns,
  title,
  timeoutMessage
}: {
  module:
    | RPCheffNativePlugPagModule
    | RPCheffNativeStoneModule
    | RPCheffNativeCieloModule
    | null;
  providerLabel: string;
  content: string;
  columns?: number;
  title?: string;
  timeoutMessage: string;
}): Promise<boolean> => {
  const printableContent = String(content || '').trim();
  if (!printableContent) {
    throw new Error(`Conteúdo de impressão vazio para ${providerLabel}.`);
  }

  const printFn = getNativePrintMethod(module);
  if (!printFn) {
    throw new Error(`Método de impressão ${providerLabel} não disponível neste build.`);
  }

  try {
    await withTimeout(
      printFn({
        content: printableContent,
        ...(typeof columns === 'number' && Number.isFinite(columns) ? { columns } : {}),
        ...(typeof title === 'string' && title.trim() ? { title: title.trim() } : {})
      }),
      60000,
      timeoutMessage
    );
    return true;
  } catch (error: any) {
    throw new Error(error?.message || `Falha ao imprimir na ${providerLabel}.`);
  }
};

export const executeStoneReceiptPrint = async ({
  content,
  settings,
  title
}: {
  content: string;
  settings: MobileAppSettings;
  title?: string;
}): Promise<boolean> => {
  if (Platform.OS !== 'android') return false;
  if (resolveConfiguredPaymentProvider(settings) !== 'stone') return false;

  return executeNativeTerminalReceiptPrint({
    module: getStoneModule(),
    providerLabel: 'Stone',
    content,
    columns: Number(settings.impressaoColunas || 32),
    title,
    timeoutMessage: 'Tempo limite ao imprimir na Stone.'
  });
};

export const executeCieloReceiptPrint = async ({
  content,
  settings,
  title
}: {
  content: string;
  settings: MobileAppSettings;
  title?: string;
}): Promise<boolean> => {
  if (Platform.OS !== 'android') return false;
  if (resolveConfiguredPaymentProvider(settings) !== 'cielo') return false;

  return executeNativeTerminalReceiptPrint({
    module: getCieloModule(),
    providerLabel: 'Cielo',
    content,
    columns: Number(settings.impressaoColunas || 32),
    title,
    timeoutMessage: 'Tempo limite ao imprimir na Cielo.'
  });
};

const executeStoneNative = async (
  input: RPCheffPaymentInput,
  sfiCodigo: number
): Promise<RPCheffNativeStoneResult | null> => {
  if (Platform.OS !== 'android') return null;

  const module = getStoneModule();
  if (!module) return null;

  const methodFn = getNativeExecuteMethod<RPCheffNativeStonePayload>(module);
  if (!methodFn) return null;

  const transactionType = resolveTransactionType(input.method, sfiCodigo);
  if (!transactionType) {
    throw new Error('Forma de pagamento não suportada para Stone.');
  }

  const payload: RPCheffNativeStonePayload = {
    amount: Math.max(1, Math.round(input.value * 100)),
    value: input.value,
    sfiCodigo,
    transactionType,
    methodCode: input.method.codigo,
    methodDescription: input.method.descricao,
    installments: 1,
    installmentType: 'none',
    orderId: `${Date.now()}`
  };

  let rawResult: unknown;
  try {
    rawResult = await methodFn(payload);
  } catch (error: any) {
    throw new Error(error?.message || 'Falha ao processar pagamento na maquininha Stone.');
  }

  const approved = parseNativeApproved(rawResult);
  const message = parseNativeMessage(rawResult);
  if (!approved) {
    throw new Error(message || 'Pagamento negado pela maquininha Stone.');
  }

  return {
    approved: true,
    nsu: parseNativeNsu(rawResult) || createNsu(),
    message: message || 'Pagamento aprovado via STONE.',
    sfiCodigo: parseNativeSfi(rawResult, sfiCodigo)
  };
};

const mapCieloPaymentCode = (transactionType: PaymentTerminalTransactionType): string => {
  if (transactionType === 'debit') return 'DEBITO_AVISTA';
  if (transactionType === 'pix') return 'PIX';
  if (transactionType === 'voucher') return 'VOUCHER_REFEICAO';
  return 'CREDITO_AVISTA';
};

const executeCieloNative = async (
  input: RPCheffPaymentInput,
  sfiCodigo: number
): Promise<RPCheffNativeCieloResult | null> => {
  if (Platform.OS !== 'android') return null;

  const module = getCieloModule();
  if (!module) return null;

  const methodFn = getNativeExecuteMethod<RPCheffNativeCieloPayload>(module);
  if (!methodFn) return null;

  const transactionType = resolveTransactionType(input.method, sfiCodigo);
  if (!transactionType) {
    throw new Error('Forma de pagamento não suportada para Cielo.');
  }

  const payload: RPCheffNativeCieloPayload = {
    amount: Math.max(1, Math.round(input.value * 100)),
    value: input.value,
    sfiCodigo,
    transactionType,
    methodCode: input.method.codigo,
    methodDescription: input.method.descricao,
    installments: 0,
    paymentCode: mapCieloPaymentCode(transactionType)
  };

  let rawResult: unknown;
  try {
    rawResult = await methodFn(payload);
  } catch (error: any) {
    throw new Error(error?.message || 'Falha ao processar pagamento na maquininha Cielo.');
  }

  const approved = parseNativeApproved(rawResult);
  const message = parseNativeMessage(rawResult);
  if (!approved) {
    throw new Error(message || 'Pagamento negado pela maquininha Cielo.');
  }

  return {
    approved: true,
    nsu: parseNativeNsu(rawResult) || createNsu(),
    message: message || 'Pagamento aprovado via CIELO.',
    sfiCodigo: parseNativeSfi(rawResult, sfiCodigo)
  };
};

const resolveMethodBySfi = (
  availableMethods: PaymentMethod[],
  fallbackMethod: PaymentMethod,
  sfiCodigo?: number
): PaymentMethod => {
  if (typeof sfiCodigo !== 'number') {
    return fallbackMethod;
  }

  const found = availableMethods.find((item) => Number(item.sfiCodigo) === Number(sfiCodigo));
  return found || fallbackMethod;
};

abstract class RPCheffPaymentStrategy {
  protected approve(
    input: RPCheffPaymentInput,
    provider: RPCheffPaymentProvider,
    sfiCodigo?: number
  ): RPCheffPaymentResult {
    const method = resolveMethodBySfi(input.availableMethods, input.method, sfiCodigo);
    return {
      approved: true,
      provider,
      method,
      value: input.value,
      sfiCodigo: detectSfi(method),
      nsu: createNsu(),
      message: `Pagamento aprovado via ${provider.toUpperCase()}.`
    };
  }

  abstract execute(input: RPCheffPaymentInput): Promise<RPCheffPaymentResult>;
}

class RPCheffManualPaymentStrategy extends RPCheffPaymentStrategy {
  async execute(input: RPCheffPaymentInput): Promise<RPCheffPaymentResult> {
    return this.approve(input, 'manual');
  }
}

class RPCheffStonePaymentStrategy extends RPCheffPaymentStrategy {
  async execute(input: RPCheffPaymentInput): Promise<RPCheffPaymentResult> {
    const sfiCodigo = detectSfi(input.method);
    if (typeof sfiCodigo !== 'number') {
      throw new Error('SFI da forma de pagamento não configurado para Stone.');
    }

    if (!STONE_SUPPORTED_SFI.has(sfiCodigo)) {
      throw new Error('Forma de pagamento não suportada para Stone.');
    }

    notifyPaymentProgress(input, 'Processando venda com Stone. Aguarde na maquininha.');
    const nativeResult = await executeStoneNative(input, sfiCodigo);
    if (!nativeResult) {
      throw new Error('Integração Stone não disponível neste build.');
    }

    const method = resolveMethodBySfi(input.availableMethods, input.method, nativeResult.sfiCodigo ?? sfiCodigo);
    notifyPaymentProgress(input, nativeResult.message || 'Pagamento aprovado via Stone.');
    return {
      approved: nativeResult.approved,
      provider: 'stone',
      method,
      value: input.value,
      sfiCodigo: detectSfi(method),
      nsu: nativeResult.nsu,
      message: nativeResult.message
    };
  }
}

class RPCheffPlugPagPaymentStrategy extends RPCheffPaymentStrategy {
  async execute(input: RPCheffPaymentInput): Promise<RPCheffPaymentResult> {
    const sfiCodigo = detectSfi(input.method);
    if (typeof sfiCodigo !== 'number') {
      throw new Error('SFI da forma de pagamento não configurado para PagBank.');
    }

    if (!PAGBANK_SUPPORTED_SFI.has(sfiCodigo)) {
      throw new Error('Forma de pagamento não suportada para PagBank.');
    }

    const nativeResult = await executePlugPagNative(input, sfiCodigo);
    if (!nativeResult) {
      throw new Error('Falha ao iniciar pagamento na PagBank.');
    }

    const method = resolveMethodBySfi(input.availableMethods, input.method, nativeResult.sfiCodigo ?? sfiCodigo);
    return {
      approved: nativeResult.approved,
      provider: 'pagbank',
      method,
      value: input.value,
      sfiCodigo: detectSfi(method),
      nsu: nativeResult.nsu,
      message: nativeResult.message
    };
  }
}

class RPCheffCieloPaymentStrategy extends RPCheffPaymentStrategy {
  async execute(input: RPCheffPaymentInput): Promise<RPCheffPaymentResult> {
    const sfiCodigo = detectSfi(input.method);
    if (typeof sfiCodigo !== 'number') {
      throw new Error('SFI da forma de pagamento não configurado para Cielo.');
    }

    if (!CIELO_SUPPORTED_SFI.has(sfiCodigo)) {
      throw new Error('Forma de pagamento não suportada para Cielo.');
    }

    notifyPaymentProgress(input, 'Processando venda com Cielo. Aguarde na maquininha.');
    const nativeResult = await executeCieloNative(input, sfiCodigo);
    if (!nativeResult) {
      throw new Error('Integração Cielo não disponível neste build.');
    }

    const method = resolveMethodBySfi(input.availableMethods, input.method, nativeResult.sfiCodigo ?? sfiCodigo);
    notifyPaymentProgress(input, nativeResult.message || 'Pagamento aprovado via Cielo.');
    return {
      approved: nativeResult.approved,
      provider: 'cielo',
      method,
      value: input.value,
      sfiCodigo: detectSfi(method),
      nsu: nativeResult.nsu,
      message: nativeResult.message
    };
  }
}

const createStrategy = (provider: RPCheffPaymentProvider): RPCheffPaymentStrategy => {
  if (provider === 'stone') return new RPCheffStonePaymentStrategy();
  if (provider === 'pagbank') return new RPCheffPlugPagPaymentStrategy();
  if (provider === 'cielo') return new RPCheffCieloPaymentStrategy();
  return new RPCheffManualPaymentStrategy();
};

export const executePayment = async (input: RPCheffPaymentInput): Promise<RPCheffPaymentResult> => {
  const value = Number(input.value || 0);
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error('Valor de pagamento inválido.');
  }

  if (!isElectronicPaymentMethod(input.method)) {
    return createStrategy('manual').execute(input);
  }

  const provider = resolvePaymentProviderForMethod(input.settings, input.method);
  return createStrategy(provider).execute(input);
};
