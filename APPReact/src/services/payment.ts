import * as IntentLauncher from 'expo-intent-launcher';
import { Linking, NativeEventEmitter, NativeModules, Platform } from 'react-native';
import { logSyncDiagnostic, MobileAppSettings, PaymentMethod } from './api';
import { getGetNetPaymentEnvironment, getGetNetPosDigitalInfo } from './getnetPosDigital';
import {
  loadStoredGetNetSubsellers,
  loadStoredGetNetTransaction,
  saveStoredGetNetSubsellers,
  saveStoredGetNetTransaction,
  StoredGetNetSubseller,
  StoredGetNetSubsellers,
  StoredGetNetTransaction
} from './machineSettingsDb';

export type RPCheffPaymentProvider = 'manual' | 'stone' | 'pagbank' | 'cielo' | 'getnet';

export type RPCheffPaymentInput = {
  value: number;
  method: PaymentMethod;
  availableMethods: PaymentMethod[];
  settings: MobileAppSettings;
  idVenda?: number;
  onProgress?: (message: string) => void;
  getnet?: {
    splitPayloadRequest?: string;
    additionalInfo?: string;
    orderId?: string;
    creditType?: 'creditMerchant' | 'creditIssuer';
    installments?: number;
    dccReceiptImplemented?: boolean;
  };
};

export type RPCheffPaymentResult = {
  approved: boolean;
  provider: RPCheffPaymentProvider;
  method: PaymentMethod;
  value: number;
  sfiCodigo?: number;
  nsu: string;
  message: string;
  callerId?: string;
  cvNumber?: string;
  brand?: string;
  receiptAlreadyPrinted?: boolean;
  printMerchantPreference?: boolean;
  automationSlip?: string;
  pixPayloadResponse?: string;
  splitPayloadResponse?: string;
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
const GETNET_SUPPORTED_SFI = new Set([3, 4, 6, 11, 17]);

const ANDROID_ACTION_VIEW = 'android.intent.action.VIEW';
const GETNET_PAYMENT_URL = 'getnet://pagamento/v3/payment';
const GETNET_PAYMENT_V2_URL = 'getnet://pagamento/v2/payment';
const GETNET_REPRINT_URL = 'getnet://pagamento/v1/reprint';
const GETNET_GETINFOS_URL = 'getnet://pagamento/v1/getinfos';
const GETNET_CHECKSTATUS_URL = 'getnet://pagamento/v1/checkstatus';
const GETNET_CHECKSUBSELLERS_URL = 'getnet://pagamento/v1/checksubsellers';
const GETNET_REFUND_URL = 'getnet://pagamento/v1/refund';
const GETNET_REBATEDOR_PACKAGE = 'com.getnet.pesquisa.rebatedor';
const GETNET_REBATEDOR_HANDLER_ACTIVITY = 'com.getnet.pesquisa.rebatedor.deeplink.HandlerDeepLinkActivity';
const GETNET_ACTIVITY_RESULT_OK = -1;
const GETNET_ACTIVITY_RESULT_CANCELED = 0;
const GETNET_RESULT_SUCCESS = 0;
const GETNET_RESULT_DENIED = 1;
const GETNET_RESULT_CANCELLED = 2;
const GETNET_RESULT_FAILURE = 3;
const GETNET_RESULT_UNKNOWN = 4;
const GETNET_RESULT_PENDING = 5;

type PaymentTerminalTransactionType = 'credit' | 'debit' | 'pix' | 'voucher';

type GetNetModelValue = 'DX8000' | 'P2' | 'P3' | 'P4' | 'N910' | 'APOSA8';
type StoneModelValue = 'P2' | 'L400';

type RPCheffGetNetIntentTarget = {
  packageName?: string;
  className?: string;
};

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
  model?: string;
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

type RPCheffGetNetResult = {
  approved: boolean;
  nsu: string;
  message: string;
  sfiCodigo?: number;
  callerId: string;
  cvNumber?: string;
  brand?: string;
  transaction: StoredGetNetTransaction;
  receiptAlreadyPrinted?: boolean;
  printMerchantPreference?: boolean;
  automationSlip?: string;
  pixPayloadResponse?: string;
  splitPayloadResponse?: string;
};

type RPCheffGetNetIntentResponse = {
  activityResultCode: number;
  resultCode: number;
  resultDetails: string;
  message: string;
  raw: Record<string, unknown>;
};

export type RPCheffGetNetTerminalInfo = {
  result: number;
  ec: string;
  numSerie: string;
  numLogic: string;
  version: string;
  cnpj: string;
  nome?: string;
  razaoSocial: string;
  cidade: string;
  raw: Record<string, unknown>;
};

export type RPCheffGetNetTransactionStatus = {
  approved: boolean;
  pending: boolean;
  cancelled: boolean;
  denied: boolean;
  refunded?: boolean;
  transaction: StoredGetNetTransaction;
  message: string;
};

export type RPCheffGetNetRefundResult = {
  approved: boolean;
  message: string;
  amount: string;
  transaction?: StoredGetNetTransaction | null;
  raw: Record<string, unknown>;
};

export type RPCheffGetNetSubsellersResult = {
  approved: boolean;
  message: string;
  payload: StoredGetNetSubsellers;
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

type PaymentErrorWithCode = Error & { code?: string };

export type RPCheffMachinePaymentErrorDetails = {
  code?: string;
  rawMessage: string;
  message: string;
  diagnostic: string;
};

const normalizeDiagnosticText = (value?: string): string =>
  String(value || '')
    .replace(/\s+/g, ' ')
    .trim();

const extractErrorCode = (error: unknown): string | undefined => {
  if (!error || typeof error !== 'object') return undefined;
  const value = error as Record<string, unknown>;
  const candidates = [
    value.code,
    value.errorCode,
    value.nativeCode,
    (value.userInfo as Record<string, unknown> | undefined)?.code
  ];
  const found = candidates.find((item) => item !== undefined && item !== null && String(item).trim().length > 0);
  return found !== undefined && found !== null ? String(found).trim() : undefined;
};

const extractErrorMessage = (error: unknown): string => {
  if (!error) return '';
  if (typeof error === 'string') return error.trim();
  if (error instanceof Error && error.message) return error.message.trim();
  if (typeof error === 'object') {
    const value = error as Record<string, unknown>;
    const candidates = [value.message, value.mensagem, value.description, value.localizedMessage];
    const found = candidates.find((item) => typeof item === 'string' && String(item).trim().length > 0);
    if (typeof found === 'string') return found.trim();
  }
  return '';
};

const createMachinePaymentError = (message: string, code?: string): PaymentErrorWithCode => {
  const error = new Error(message) as PaymentErrorWithCode;
  if (code) {
    error.code = code;
  }
  return error;
};

export const describeMachinePaymentError = (
  providerLabel: string,
  error: unknown
): RPCheffMachinePaymentErrorDetails => {
  const code = extractErrorCode(error);
  const rawMessage = normalizeDiagnosticText(extractErrorMessage(error));
  const normalizedMessage = normalizeText(rawMessage);
  const normalizedCode = normalizeText(code);
  let message = rawMessage;

  if (!message) {
    message = `Falha ao processar pagamento na ${providerLabel}.`;
  }

  if (normalizedMessage.includes('nenhum pagamento foi registrado')) {
    return {
      code,
      rawMessage,
      message,
      diagnostic: `code=${code || 'sem-codigo'} message=${rawMessage || 'sem-mensagem'}`
    };
  }

  if (normalizedMessage.includes('tempo') || normalizedMessage.includes('timeout') || normalizedCode.includes('timeout')) {
    message = `A ${providerLabel} demorou para responder. Nenhum pagamento foi registrado no app. Confira se a transação apareceu na maquininha antes de tentar novamente.`;
  } else if (normalizedMessage.includes('cancel') || normalizedCode.includes('cancel')) {
    message = `Operação cancelada na ${providerLabel}. Nenhum pagamento foi registrado no app.`;
  } else if (normalizedCode.includes('busy') || normalizedMessage.includes('em andamento')) {
    message = `Já existe um pagamento ${providerLabel} em andamento. Aguarde a maquininha finalizar antes de tentar novamente.`;
  } else if (normalizedMessage === 'erro de processamento' || normalizedMessage.includes('erro de processamento')) {
    message = `A ${providerLabel} retornou "Erro de Processamento". Nenhum pagamento foi registrado no app. Confira a mensagem na maquininha e tente novamente.`;
  } else if (!normalizedMessage.includes('nenhum pagamento foi registrado')) {
    message = `${message} Nenhum pagamento foi registrado no app.`;
  }

  return {
    code,
    rawMessage,
    message,
    diagnostic: `code=${code || 'sem-codigo'} message=${rawMessage || 'sem-mensagem'} friendly=${message}`
  };
};

const summarizeNativePaymentResult = (raw: unknown): string => {
  if (!raw || typeof raw !== 'object') {
    return `rawType=${typeof raw}`;
  }

  const value = raw as Record<string, unknown>;
  const keys = [
    'approved',
    'success',
    'sucesso',
    'status',
    'code',
    'codigo',
    'statusCode',
    'responseCode',
    'message',
    'mensagem',
    'responseMessage',
    'description',
    'descricao',
    'sfiCodigo',
    'typeTransaction',
    'transactionType'
  ];
  const pairs = keys
    .filter((key) => value[key] !== undefined && value[key] !== null)
    .map((key) => `${key}=${normalizeDiagnosticText(String(value[key]))}`);

  if (pairs.length > 0) {
    return pairs.join(' ');
  }

  return `keys=${Object.keys(value).slice(0, 8).join(',') || 'sem-chaves'}`;
};

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
  if (index === 5) return 'getnet';
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
  if (normalized === 'getnet') return 'getnet';
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
  if (provider === 'getnet') return 'GetNet';
  return 'maquininha';
};

const formatGetNetAmount = (value: number): string => {
  const cents = Math.max(1, Math.round(Number(value || 0) * 100));
  return String(cents).padStart(12, '0');
};

const normalizeStoneTerminalModel = (value: unknown, fallback: StoneModelValue = 'P2'): StoneModelValue => {
  const normalized = String(value || '')
    .trim()
    .toUpperCase();

  if (normalized === 'L400' || normalized === 'POSITIVO' || normalized === 'POSITIVO L400') {
    return 'L400';
  }

  if (normalized === 'P2' || normalized === 'P2-B' || normalized === 'SUNMI' || normalized === 'STONE') {
    return 'P2';
  }

  return fallback;
};

const createGetNetCallerId = (): string => {
  const randomPart = Math.floor(Math.random() * 1_000_000)
    .toString()
    .padStart(6, '0');
  return `rp-${Date.now()}-${randomPart}`;
};

const parseGetNetBoolean = (value: unknown, fallback = false): boolean => {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    const normalized = normalizeText(value);
    if (['true', '1', 'sim', 'yes'].includes(normalized)) return true;
    if (['false', '0', 'nao', 'no'].includes(normalized)) return false;
  }
  return fallback;
};

const parseGetNetAmountValue = (value: unknown, fallback = 0): number => {
  const normalized = String(value || '').replace(/\D/g, '');
  if (!normalized) return fallback;
  const cents = Number(normalized);
  if (!Number.isFinite(cents)) return fallback;
  return cents / 100;
};

const parseGetNetCommissionNumber = (value: unknown): number | undefined => {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === 'string') {
    const normalized = value.replace(',', '.').trim();
    const parsed = Number(normalized);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return undefined;
};

const mapGetNetResultMessage = (resultCode: number, fallback?: string): string => {
  const text = String(fallback || '').trim();
  if (text) {
    return text;
  }

  if (resultCode === GETNET_RESULT_SUCCESS) return 'Pagamento aprovado via GetNet.';
  if (resultCode === GETNET_RESULT_DENIED) return 'Pagamento negado pela maquininha GetNet.';
  if (resultCode === GETNET_RESULT_CANCELLED) return 'Operação cancelada na maquininha GetNet.';
  if (resultCode === GETNET_RESULT_FAILURE) return 'Falha ao processar pagamento na maquininha GetNet.';
  if (resultCode === GETNET_RESULT_PENDING) return 'Pagamento pendente na GetNet. Consulte o status da transação.';
  return 'Falha ao processar pagamento na maquininha GetNet.';
};

const normalizeGetNetModel = (value: unknown, fallback: GetNetModelValue = 'P2'): GetNetModelValue => {
  const normalized = String(value || '')
    .trim()
    .toUpperCase();

  if (
    normalized === 'DX8000' ||
    normalized === 'INGENICO DX8000' ||
    normalized === 'INGENICO-DX8000' ||
    normalized === 'DX 8000'
  ) {
    return 'DX8000';
  }
  if (normalized === 'P3') return 'P3';
  if (normalized === 'P4') return 'P4';
  if (normalized === 'N910' || normalized === 'NEWLAND N910' || normalized === 'NEWLAND-N910') return 'N910';
  if (
    normalized === 'APOSA8' ||
    normalized === 'APOS A8' ||
    normalized === 'INGENICO APOS A8' ||
    normalized === 'A8'
  ) {
    return 'APOSA8';
  }
  return normalized === 'P2' ? 'P2' : fallback;
};

const detectGetNetModelFromTerminalInfo = (
  info: Awaited<ReturnType<typeof getGetNetPosDigitalInfo>> | null | undefined
): GetNetModelValue | null => {
  if (!info) {
    return null;
  }

  const candidates = [
    info.model,
    info.manufacturer,
    info.hardwareVersion,
    info.hardwareSn,
    info.serialNumber,
    info.firmwareVersion,
    info.romVersion
  ];

  for (const candidate of candidates) {
    const text = String(candidate || '').trim();
    if (!text) {
      continue;
    }

    const detected = normalizeGetNetModel(text, 'P2');
    if (detected !== 'P2' || text.toUpperCase() === 'P2') {
      return detected;
    }
  }

  return null;
};

const resolveRuntimeGetNetModel = async (settings: MobileAppSettings): Promise<GetNetModelValue> => {
  const configuredModel = normalizeGetNetModel(settings.modeloMaquininha);

  try {
    const terminalInfo = await getGetNetPosDigitalInfo();
    return detectGetNetModelFromTerminalInfo(terminalInfo) || configuredModel;
  } catch {
    return configuredModel;
  }
};

const resolveGetNetIntentTarget = (model: GetNetModelValue): RPCheffGetNetIntentTarget | null => {
  if (model !== 'P2') {
    return null;
  }

  return {
    packageName: GETNET_REBATEDOR_PACKAGE,
    className: GETNET_REBATEDOR_HANDLER_ACTIVITY
  };
};

const prepareGetNetEnvironment = async (settings: MobileAppSettings): Promise<void> => {
  if (Platform.OS !== 'android') {
    return;
  }

  try {
    await getGetNetPosDigitalInfo();
  } catch {
    // O SDK PosDigital é a camada oficial entre o app e o hardware GetNet.
    // Falha aqui não deve impedir a tentativa do pagamento via deeplink.
  }
};

export const ensureGetNetReadyForLivePayment = async (settings: MobileAppSettings): Promise<void> => {
  if (Platform.OS !== 'android') {
    return;
  }

  if (resolveConfiguredPaymentProvider(settings) !== 'getnet') {
    return;
  }

  try {
    const environment = await getGetNetPaymentEnvironment();
    if (environment.simulationMode) {
      throw new Error(
        'Terminal GetNet em modo simulacao. O deeplink de pagamento esta sendo atendido pelo Rebatedor, que nao realiza cobranca real. Instale ou homologue o aplicativo oficial de pagamento da GetNet antes de fechar a venda com cartao.'
      );
    }
  } catch (error: any) {
    if (error instanceof Error) {
      throw error;
    }
    throw new Error(error?.message || 'Nao foi possivel validar o ambiente de pagamento da GetNet.');
  }
};

const mapGetNetStatusMessage = (
  resultCode: number,
  resultDetails: string,
  refunded?: boolean
): string => {
  const details = String(resultDetails || '').trim();
  if (details) {
    return details;
  }

  if (resultCode === GETNET_RESULT_PENDING) {
    return 'Transacao Pix ainda pendente na GetNet.';
  }

  if (resultCode === GETNET_RESULT_SUCCESS) {
    return refunded ? 'Transacao localizada na GetNet e ja estornada.' : 'Transacao localizada com sucesso na GetNet.';
  }

  if (resultCode === GETNET_RESULT_CANCELLED) {
    return 'Transacao cancelada na GetNet.';
  }

  if (resultCode === GETNET_RESULT_DENIED) {
    return 'Transacao negada na GetNet.';
  }

  return 'Nenhum dado encontrado para o callerId informado na GetNet.';
};

const mapGetNetResponseToSfi = (typeValue: unknown, inputTypeValue: unknown, fallback?: number): number | undefined => {
  const joined = `${normalizeText(typeof typeValue === 'string' ? typeValue : '')} ${normalizeText(
    typeof inputTypeValue === 'string' ? inputTypeValue : ''
  )}`.trim();

  if (!joined) {
    return fallback;
  }

  if (joined.includes('pix')) return 17;
  if (joined.includes('debit') || joined.includes('debito')) return 4;
  if (joined.includes('voucher') || joined.includes('refeicao') || joined.includes('alimentacao')) return 11;
  if (joined.includes('13') || joined.includes('12') || joined.includes('11')) return 3;
  if (joined.includes('credit') || joined.includes('credito')) return 3;
  return fallback;
};

const buildStoredGetNetTransaction = (
  raw: Record<string, unknown>,
  overrides: {
    callerId?: string;
    amount?: string;
    resultCode?: number;
    resultDetails?: string;
    refunded?: boolean;
  } = {}
): StoredGetNetTransaction => {
  const amount = String(overrides.amount || raw.amount || '').trim();
  const callerId = String(overrides.callerId || raw.callerId || '').trim();

  return {
    callerId,
    amount,
    amountValue: parseGetNetAmountValue(amount),
    result: Number(overrides.resultCode ?? raw.result ?? GETNET_RESULT_UNKNOWN),
    resultDetails: String(overrides.resultDetails || raw.resultDetails || '').trim() || undefined,
    nsu: String(raw.nsu || '').trim() || undefined,
    nsuLastSuccessfulMessage: String(raw.nsuLastSuccesfullMessage || raw.nsuLastSuccessfullMessage || '').trim() || undefined,
    cvNumber: String(raw.cvNumber || raw.refundCvNumber || '').trim() || undefined,
    brand: String(raw.brand || '').trim() || undefined,
    type: String(raw.type || '').trim() || undefined,
    inputType: String(raw.inputType || '').trim() || undefined,
    installments: String(raw.installments || '').trim() || undefined,
    gmtDateTime: String(raw.gmtDateTime || '').trim() || undefined,
    nsuLocal: String(raw.nsuLocal || '').trim() || undefined,
    authorizationCode: String(raw.authorizationCode || '').trim() || undefined,
    cardBin: String(raw.cardBin || '').trim() || undefined,
    cardLastDigits: String(raw.cardLastDigits || '').trim() || undefined,
    cardholderName: String(raw.cardholderName || '').trim() || undefined,
    extraScreensResult: String(raw.extraScreensResult || '').trim() || undefined,
    splitPayloadResponse: String(raw.splitPayloadResponse || '').trim() || undefined,
    pixPayloadResponse: String(raw.pixPayloadResponse || '').trim() || undefined,
    automationSlip: String(raw.automationSlip || '').trim() || undefined,
    refunded:
      typeof overrides.refunded === 'boolean'
        ? overrides.refunded
        : raw.refunded === undefined
          ? undefined
          : parseGetNetBoolean(raw.refunded, false),
    orderId: String(raw.orderId || '').trim() || undefined,
    receiptAlreadyPrinted: parseGetNetBoolean(raw.receiptAlreadyPrinted, false),
    printMerchantPreference:
      raw.printMerchantPreference === undefined ? undefined : parseGetNetBoolean(raw.printMerchantPreference, false),
    provider: 'getnet',
    raw,
    updatedAt: new Date().toISOString()
  };
};

const normalizeStoredGetNetSubseller = (payload: unknown, index: number): StoredGetNetSubseller | null => {
  if (!payload || typeof payload !== 'object') {
    return null;
  }

  const value = payload as Record<string, unknown>;
  const idRaw = value.id ?? value.identifier ?? value.codigo ?? value.code ?? index + 1;
  const name = String(value.name ?? value.nome ?? value.subsellerName ?? '').trim();
  const document = String(value.document ?? value.documento ?? value.cpfCnpj ?? value.cnpjCpf ?? '').trim();

  return {
    id: Number.isFinite(Number(idRaw)) ? Number(idRaw) : index + 1,
    document,
    name,
    occupation: String(value.occupation ?? value.funcao ?? '').trim() || undefined,
    comissionPercentage: parseGetNetCommissionNumber(
      value.comissionPercentage ?? value.commissionPercentage ?? value.percentualComissao
    ),
    comissionValue: parseGetNetCommissionNumber(
      value.comissionValue ?? value.commissionValue ?? value.valorComissao
    )
  };
};

const buildStoredGetNetSubsellers = (
  raw: Record<string, unknown>,
  resultCode: number,
  resultDetails?: string
): StoredGetNetSubsellers => {
  const responseText = String(raw.consultaSubSellerResponse || '').trim();
  let parsedPayload: Record<string, unknown> = {};
  if (responseText) {
    try {
      parsedPayload = JSON.parse(responseText) as Record<string, unknown>;
    } catch {
      parsedPayload = {
        consultaSubSellerResponse: responseText
      };
    }
  }

  const marketplaceId = String(
    parsedPayload.marketPlaceId ??
      parsedPayload.marketplaceId ??
      parsedPayload.idMarketplace ??
      parsedPayload.idMarketPlace ??
      parsedPayload.anchorId ??
      parsedPayload.idAncora ??
      raw.marketPlaceId ??
      raw.marketplaceId ??
      ''
  ).trim();

  const subsellersRaw =
    (Array.isArray(parsedPayload.subsellers) && parsedPayload.subsellers) ||
    (Array.isArray(parsedPayload.subSellers) && parsedPayload.subSellers) ||
    (Array.isArray(parsedPayload.listaSubseller) && parsedPayload.listaSubseller) ||
    (Array.isArray(parsedPayload.listaSubsellers) && parsedPayload.listaSubsellers) ||
    [];

  const subsellers = subsellersRaw
    .map((item, index) => normalizeStoredGetNetSubseller(item, index))
    .filter((item): item is StoredGetNetSubseller => Boolean(item));

  return {
    marketPlaceId: marketplaceId,
    subsellers,
    result: resultCode,
    resultDetails: String(resultDetails || '').trim() || undefined,
    provider: 'getnet',
    raw: {
      ...raw,
      parsedPayload
    },
    updatedAt: new Date().toISOString()
  };
};

const executeGetNetIntent = async ({
  deeplink,
  extras,
  intentTarget,
  timeoutMs,
  timeoutMessage,
  startErrorMessage
}: {
  deeplink: string;
  extras?: Record<string, string>;
  intentTarget?: RPCheffGetNetIntentTarget | null;
  timeoutMs: number;
  timeoutMessage: string;
  startErrorMessage: string;
}): Promise<RPCheffGetNetIntentResponse> => {
  const canOpen = await Linking.canOpenURL(deeplink).catch(() => false);
  if (!canOpen) {
    throw new Error('Aplicativo da GetNet não encontrado neste dispositivo.');
  }

  let activityResult: Awaited<ReturnType<typeof IntentLauncher.startActivityAsync>>;
  try {
    const launchParams: IntentLauncher.IntentLauncherParams = {
      data: deeplink,
      ...(extras ? { extra: extras } : {}),
      ...(intentTarget?.packageName ? { packageName: intentTarget.packageName } : {}),
      ...(intentTarget?.className ? { className: intentTarget.className } : {})
    };

    activityResult = await withTimeout(
      IntentLauncher.startActivityAsync(ANDROID_ACTION_VIEW, launchParams),
      timeoutMs,
      timeoutMessage
    );
  } catch (error: any) {
    const canRetryWithoutTarget = Boolean(intentTarget?.packageName || intentTarget?.className);
    if (!canRetryWithoutTarget) {
      throw new Error(error?.message || startErrorMessage);
    }

    try {
      activityResult = await withTimeout(
        IntentLauncher.startActivityAsync(ANDROID_ACTION_VIEW, {
          data: deeplink,
          ...(extras ? { extra: extras } : {})
        }),
        timeoutMs,
        timeoutMessage
      );
    } catch (fallbackError: any) {
      throw new Error(fallbackError?.message || error?.message || startErrorMessage);
    }
  }

  const raw = ((activityResult as unknown as { extra?: Record<string, unknown> })?.extra || {}) as Record<
    string,
    unknown
  >;
  const activityResultCode = Number(
    (activityResult as unknown as { resultCode?: number })?.resultCode ?? GETNET_ACTIVITY_RESULT_CANCELED
  );
  const resultCode =
    raw.result !== undefined
      ? Number(raw.result)
      : activityResultCode === GETNET_ACTIVITY_RESULT_CANCELED
        ? GETNET_RESULT_CANCELLED
        : GETNET_RESULT_UNKNOWN;
  const resultDetails = String(raw.resultDetails || '').trim();

  return {
    activityResultCode,
    resultCode,
    resultDetails,
    message: mapGetNetResultMessage(resultCode, resultDetails),
    raw
  };
};

const executeGetNetNative = async (
  input: RPCheffPaymentInput,
  sfiCodigo: number
): Promise<RPCheffGetNetResult | null> => {
  if (Platform.OS !== 'android') {
    throw new Error('GetNet disponível somente no Android.');
  }

  const transactionType = resolveTransactionType(input.method, sfiCodigo);
  if (!transactionType) {
    throw new Error('Forma de pagamento não suportada para GetNet.');
  }

  const splitPayloadRequest = String(input.getnet?.splitPayloadRequest || '').trim();
  const useSplitPayment = splitPayloadRequest.length > 0;
  const callerId = createGetNetCallerId();
  await ensureGetNetReadyForLivePayment(input.settings);
  const runtimeModel = await resolveRuntimeGetNetModel(input.settings);
  const intentTarget = resolveGetNetIntentTarget(runtimeModel);
  const extras: Record<string, string> = {
    paymentType: transactionType,
    amount: formatGetNetAmount(input.value),
    currencyPosition: 'CURRENCY_AFTER_AMOUNT',
    currencyCode: '986',
    allowPrintCurrentTransaction: 'false',
    disableTypedTransaction: 'false',
    disableMagStripe: 'false',
    disableCustomerSlipSpace: 'false'
  };

  if (!useSplitPayment) {
    extras.callerId = callerId;
  }

  const requestedInstallments = Math.max(1, Math.trunc(Number(input.getnet?.installments || 1)));
  const requestedCreditType = input.getnet?.creditType;

  if (transactionType === 'credit') {
    if (requestedCreditType === 'creditIssuer' || requestedCreditType === 'creditMerchant') {
      extras.creditType = requestedCreditType;
      extras.installments = String(Math.max(1, requestedInstallments));
    } else if (requestedInstallments > 1) {
      extras.creditType = 'creditMerchant';
      extras.installments = String(requestedInstallments);
    }
  }

  if (useSplitPayment) {
    extras.splitPayloadRequest = splitPayloadRequest;
  } else {
    extras.dccReceiptImplemented = input.getnet?.dccReceiptImplemented ? 'true' : 'false';
    if (String(input.getnet?.additionalInfo || '').trim()) {
      extras.additionalInfo = String(input.getnet?.additionalInfo || '').trim();
    }
  }

  const resolvedOrderId =
    String(input.getnet?.orderId || '').trim() ||
    (Number.isFinite(Number(input.idVenda || 0)) && Number(input.idVenda || 0) > 0
      ? String(Math.trunc(Number(input.idVenda || 0)))
      : '');
  if (resolvedOrderId) {
    extras.orderId = resolvedOrderId;
  }

  notifyPaymentProgress(input, 'Processando venda com GetNet. Aguarde na maquininha.');
  await prepareGetNetEnvironment(input.settings);

  const response = await executeGetNetIntent({
    deeplink: useSplitPayment ? GETNET_PAYMENT_V2_URL : GETNET_PAYMENT_URL,
    extras,
    intentTarget,
    timeoutMs: NATIVE_PAYMENT_TIMEOUT_MS,
    timeoutMessage: 'Tempo limite ao aguardar retorno da GetNet.',
    startErrorMessage: 'Falha ao iniciar pagamento na maquininha GetNet.'
  });
  const transaction = buildStoredGetNetTransaction(response.raw, {
    callerId: String(response.raw.callerId || extras.callerId || callerId).trim(),
    amount: extras.amount,
    resultCode: response.resultCode,
    resultDetails: response.resultDetails
  });
  await saveStoredGetNetTransaction(transaction);

  if (response.activityResultCode !== GETNET_ACTIVITY_RESULT_OK && response.resultCode === GETNET_RESULT_UNKNOWN) {
    throw new Error(response.message);
  }

  if (response.resultCode === GETNET_RESULT_SUCCESS) {
    return {
      approved: true,
      nsu: transaction.nsu || createNsu(),
      message: response.message,
      sfiCodigo: mapGetNetResponseToSfi(response.raw.type, response.raw.inputType, sfiCodigo),
      callerId: transaction.callerId,
      cvNumber: transaction.cvNumber,
      brand: transaction.brand,
      transaction,
      receiptAlreadyPrinted: transaction.receiptAlreadyPrinted,
      printMerchantPreference: transaction.printMerchantPreference,
      automationSlip: transaction.automationSlip,
      pixPayloadResponse: transaction.pixPayloadResponse,
      splitPayloadResponse: transaction.splitPayloadResponse
    };
  }

  if (response.resultCode === GETNET_RESULT_PENDING) {
    throw new Error(response.message);
  }

  if (response.resultCode === GETNET_RESULT_CANCELLED) {
    throw new Error(response.message);
  }

  if (
    response.resultCode === GETNET_RESULT_DENIED ||
    response.resultCode === GETNET_RESULT_FAILURE ||
    response.resultCode === GETNET_RESULT_UNKNOWN
  ) {
    throw new Error(response.message);
  }

  throw new Error(response.message || 'Falha ao processar pagamento na maquininha GetNet.');
};

export const executeGetNetReceiptPrint = async ({
  settings
}: {
  settings: MobileAppSettings;
}): Promise<boolean> => {
  if (Platform.OS !== 'android') return false;
  if (resolveConfiguredPaymentProvider(settings) !== 'getnet') return false;

  const runtimeModel = await resolveRuntimeGetNetModel(settings);
  const response = await executeGetNetIntent({
    deeplink: GETNET_REPRINT_URL,
    intentTarget: resolveGetNetIntentTarget(runtimeModel),
    timeoutMs: 60000,
    timeoutMessage: 'Tempo limite ao solicitar reimpressão na GetNet.',
    startErrorMessage: 'Falha ao iniciar reimpressão na maquininha GetNet.'
  });

  if (response.resultCode === GETNET_RESULT_SUCCESS) {
    return true;
  }

  throw new Error(response.message || 'Falha ao imprimir pela maquininha GetNet.');
};

export const executeGetNetTerminalInfo = async ({
  settings
}: {
  settings: MobileAppSettings;
}): Promise<RPCheffGetNetTerminalInfo> => {
  if (Platform.OS !== 'android') {
    throw new Error('Consulta da GetNet disponível somente no Android.');
  }
  if (resolveConfiguredPaymentProvider(settings) !== 'getnet') {
    throw new Error('A integração GetNet não está selecionada nas configurações.');
  }

  const runtimeModel = await resolveRuntimeGetNetModel(settings);
  const response = await executeGetNetIntent({
    deeplink: GETNET_GETINFOS_URL,
    intentTarget: resolveGetNetIntentTarget(runtimeModel),
    timeoutMs: 60000,
    timeoutMessage: 'Tempo limite ao consultar dados do terminal GetNet.',
    startErrorMessage: 'Falha ao consultar dados do terminal GetNet.'
  });

  if (response.resultCode !== GETNET_RESULT_SUCCESS) {
    throw new Error(response.message || 'Falha ao consultar dados do terminal GetNet.');
  }

  return {
    result: response.resultCode,
    ec: String(response.raw.ec || '').trim(),
    numSerie: String(response.raw.numserie || '').trim(),
    numLogic: String(response.raw.numlogic || '').trim(),
    version: String(response.raw.version || '').trim(),
    cnpj: String(response.raw.cnpjEC || '').trim(),
    nome: String(response.raw.nomeEC || '').trim() || undefined,
    razaoSocial: String(response.raw.razaoSocialEC || '').trim(),
    cidade: String(response.raw.cidadeEC || '').trim(),
    raw: response.raw
  };
};

export const loadLastGetNetTransaction = async (): Promise<StoredGetNetTransaction | null> => {
  return loadStoredGetNetTransaction();
};

export const loadLastGetNetSubsellers = async (): Promise<StoredGetNetSubsellers | null> => {
  return loadStoredGetNetSubsellers();
};

export const executeGetNetStatus = async ({
  settings,
  callerId
}: {
  settings: MobileAppSettings;
  callerId?: string;
}): Promise<RPCheffGetNetTransactionStatus> => {
  if (Platform.OS !== 'android') {
    throw new Error('Consulta de status da GetNet disponível somente no Android.');
  }
  if (resolveConfiguredPaymentProvider(settings) !== 'getnet') {
    throw new Error('A integração GetNet não está selecionada nas configurações.');
  }

  const stored = await loadStoredGetNetTransaction();
  const resolvedCallerId = String(callerId || stored?.callerId || '').trim();
  if (!resolvedCallerId) {
    throw new Error('Nenhuma transação GetNet encontrada para consultar status.');
  }

  const runtimeModel = await resolveRuntimeGetNetModel(settings);
  const response = await executeGetNetIntent({
    deeplink: GETNET_CHECKSTATUS_URL,
    extras: {
      callerId: resolvedCallerId,
      allowPrintCurrentTransaction: 'false'
    },
    intentTarget: resolveGetNetIntentTarget(runtimeModel),
    timeoutMs: 60000,
    timeoutMessage: 'Tempo limite ao consultar status da GetNet.',
    startErrorMessage: 'Falha ao consultar status da transação GetNet.'
  });

  const mergedRaw = {
    ...(stored?.raw || {}),
    ...response.raw,
    callerId: resolvedCallerId
  };
  const transaction = buildStoredGetNetTransaction(mergedRaw, {
    callerId: resolvedCallerId,
    amount: String(response.raw.amount || stored?.amount || '').trim(),
    resultCode: response.resultCode,
    resultDetails: response.resultDetails,
    refunded:
      response.raw.refunded === undefined
        ? stored?.refunded
        : parseGetNetBoolean(response.raw.refunded, false)
  });
  await saveStoredGetNetTransaction(transaction);

  const message = mapGetNetStatusMessage(response.resultCode, response.resultDetails, transaction.refunded);

  return {
    approved: response.resultCode === GETNET_RESULT_SUCCESS,
    pending: response.resultCode === GETNET_RESULT_PENDING,
    cancelled: response.resultCode === GETNET_RESULT_CANCELLED,
    denied: response.resultCode === GETNET_RESULT_DENIED,
    refunded: transaction.refunded,
    transaction,
    message
  };
};

export const executeGetNetRefund = async ({
  settings,
  callerId
}: {
  settings: MobileAppSettings;
  callerId?: string;
}): Promise<RPCheffGetNetRefundResult> => {
  if (Platform.OS !== 'android') {
    throw new Error('Estorno da GetNet disponível somente no Android.');
  }
  if (resolveConfiguredPaymentProvider(settings) !== 'getnet') {
    throw new Error('A integração GetNet não está selecionada nas configurações.');
  }

  const stored = await loadStoredGetNetTransaction();
  const resolvedCallerId = String(callerId || stored?.callerId || '').trim();
  const amount = String(stored?.amount || '').trim();
  const cvNumber = String(stored?.cvNumber || '').trim();

  if (!resolvedCallerId && !cvNumber) {
    throw new Error('Nenhuma transação GetNet encontrada para estornar.');
  }
  if (!amount) {
    throw new Error('Valor da última transação GetNet não encontrado para estorno.');
  }

  const extras: Record<string, string> = {
    amount
  };
  if (cvNumber) {
    extras.cvNumber = cvNumber;
  }

  const runtimeModel = await resolveRuntimeGetNetModel(settings);
  const response = await executeGetNetIntent({
    deeplink: GETNET_REFUND_URL,
    extras,
    intentTarget: resolveGetNetIntentTarget(runtimeModel),
    timeoutMs: 60000,
    timeoutMessage: 'Tempo limite ao solicitar estorno na GetNet.',
    startErrorMessage: 'Falha ao iniciar estorno na maquininha GetNet.'
  });

  let transaction: StoredGetNetTransaction | null = stored || null;
  if (response.resultCode === GETNET_RESULT_SUCCESS) {
    const baseCallerId = String(stored?.callerId || resolvedCallerId || '').trim();
    transaction = buildStoredGetNetTransaction(
      {
        ...(stored?.raw || {}),
        ...response.raw,
        ...(baseCallerId ? { callerId: baseCallerId } : {})
      },
      {
        callerId: baseCallerId,
        amount: String(response.raw.amount || stored?.amount || amount).trim(),
        resultCode: response.resultCode,
        resultDetails: response.resultDetails,
        refunded: true
      }
    );
    await saveStoredGetNetTransaction(transaction);
  }

  if (response.resultCode !== GETNET_RESULT_SUCCESS) {
    throw new Error(response.message || 'Falha ao estornar transação na GetNet.');
  }

  return {
    approved: true,
    message: response.message || 'Estorno realizado com sucesso na GetNet.',
    amount: String(response.raw.amount || amount).trim(),
    transaction,
    raw: response.raw
  };
};

export const executeGetNetCheckSubsellers = async ({
  settings
}: {
  settings: MobileAppSettings;
}): Promise<RPCheffGetNetSubsellersResult> => {
  if (Platform.OS !== 'android') {
    throw new Error('Consulta de Subsellers da GetNet disponível somente no Android.');
  }
  if (resolveConfiguredPaymentProvider(settings) !== 'getnet') {
    throw new Error('A integração GetNet não está selecionada nas configurações.');
  }

  const runtimeModel = await resolveRuntimeGetNetModel(settings);
  const response = await executeGetNetIntent({
    deeplink: GETNET_CHECKSUBSELLERS_URL,
    intentTarget: resolveGetNetIntentTarget(runtimeModel),
    timeoutMs: 60000,
    timeoutMessage: 'Tempo limite ao consultar os Subsellers da GetNet.',
    startErrorMessage: 'Falha ao consultar os Subsellers da GetNet.'
  });

  if (response.resultCode !== GETNET_RESULT_SUCCESS) {
    throw new Error(response.message || 'Falha ao consultar os Subsellers da GetNet.');
  }

  const payload = buildStoredGetNetSubsellers(response.raw, response.resultCode, response.resultDetails);
  await saveStoredGetNetSubsellers(payload);

  return {
    approved: true,
    message: response.message || 'Subsellers GetNet consultados com sucesso.',
    payload
  };
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
  model,
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
  model?: string;
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
        ...(typeof model === 'string' && model.trim() ? { model: model.trim() } : {}),
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
    model: normalizeStoneTerminalModel(settings.modeloMaquininha),
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
  const startedAt = Date.now();
  logSyncDiagnostic(
    `pagamento stone nativo inicio idVenda=${input.idVenda || 0} forma=${input.method.codigo} valor=${input.value.toFixed(2)} amount=${payload.amount} sfi=${sfiCodigo} tipo=${transactionType}`
  );
  try {
    notifyPaymentProgress(input, 'Abrindo Stone. Aguarde a confirmação na maquininha.');
    rawResult = await withTimeout(
      methodFn(payload),
      NATIVE_PAYMENT_TIMEOUT_MS,
      'Tempo limite ao aguardar retorno da Stone.'
    );
    logSyncDiagnostic(
      `pagamento stone nativo retorno idVenda=${input.idVenda || 0} ${summarizeNativePaymentResult(rawResult)} em ${Date.now() - startedAt}ms`
    );
  } catch (error: any) {
    const details = describeMachinePaymentError('Stone', error);
    logSyncDiagnostic(
      `pagamento stone nativo erro idVenda=${input.idVenda || 0} ${details.diagnostic} em ${Date.now() - startedAt}ms`,
      2
    );
    throw createMachinePaymentError(details.message, details.code);
  }

  const approved = parseNativeApproved(rawResult);
  const message = parseNativeMessage(rawResult);
  if (!approved) {
    const details = describeMachinePaymentError('Stone', { message: message || 'Pagamento negado pela maquininha Stone.' });
    logSyncDiagnostic(
      `pagamento stone nativo negado idVenda=${input.idVenda || 0} ${details.diagnostic} em ${Date.now() - startedAt}ms`,
      2
    );
    throw createMachinePaymentError(details.message, details.code);
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

class RPCheffGetNetPaymentStrategy extends RPCheffPaymentStrategy {
  async execute(input: RPCheffPaymentInput): Promise<RPCheffPaymentResult> {
    const sfiCodigo = detectSfi(input.method);
    if (typeof sfiCodigo !== 'number') {
      throw new Error('SFI da forma de pagamento não configurado para GetNet.');
    }

    if (!GETNET_SUPPORTED_SFI.has(sfiCodigo)) {
      throw new Error('Forma de pagamento não suportada para GetNet.');
    }

    const nativeResult = await executeGetNetNative(input, sfiCodigo);
    if (!nativeResult) {
      throw new Error('Integração GetNet não disponível neste build.');
    }

    const method = resolveMethodBySfi(input.availableMethods, input.method, nativeResult.sfiCodigo ?? sfiCodigo);
    notifyPaymentProgress(input, nativeResult.message || 'Pagamento aprovado via GetNet.');
    return {
      approved: nativeResult.approved,
      provider: 'getnet',
      method,
      value: input.value,
      sfiCodigo: detectSfi(method),
      nsu: nativeResult.nsu,
      message: nativeResult.message,
      callerId: nativeResult.callerId,
      cvNumber: nativeResult.cvNumber,
      brand: nativeResult.brand,
      receiptAlreadyPrinted: nativeResult.receiptAlreadyPrinted,
      printMerchantPreference: nativeResult.printMerchantPreference,
      automationSlip: nativeResult.automationSlip,
      pixPayloadResponse: nativeResult.pixPayloadResponse,
      splitPayloadResponse: nativeResult.splitPayloadResponse
    };
  }
}

const createStrategy = (provider: RPCheffPaymentProvider): RPCheffPaymentStrategy => {
  if (provider === 'stone') return new RPCheffStonePaymentStrategy();
  if (provider === 'pagbank') return new RPCheffPlugPagPaymentStrategy();
  if (provider === 'cielo') return new RPCheffCieloPaymentStrategy();
  if (provider === 'getnet') return new RPCheffGetNetPaymentStrategy();
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
