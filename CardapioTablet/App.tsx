import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  AppState,
  BackHandler,
  FlatList,
  Image,
  KeyboardAvoidingView,
  Modal,
  NativeModules,
  Pressable,
  SafeAreaView,
  ScrollView,
  Share,
  StyleSheet,
  Text,
  TextInput,
  View
} from 'react-native';
import type { StyleProp, TextInputProps, ViewStyle } from 'react-native';
import { StatusBar } from 'expo-status-bar';

import { colors, radius, shadows, spacing } from './src/theme';
import type {
  CartItem,
  Category,
  CompanyStatus,
  LaunchItemFractionPayload,
  LaunchOptionalPayload,
  MenuItem,
  PendingOrder,
  ProductOptional,
  Sale,
  SaleLine,
  TableOrder,
  TabletDiagnostics,
  TabletSession,
  TabletSettings
} from './src/types';
import {
  buildLaunchPayload,
  findTableByNumber,
  getCartItemTotal,
  getCartTotal,
  getDefaultSizeCode,
  getOptionalDisplay,
  getOptionalPrice,
  getProductSizeLabel,
  getProductSizeOptions,
  getProductUnitPrice,
  isTableOpenForTablet,
  normalizeSaleStatus,
  roundMoney,
  TabletApi
} from './src/services/api';
import {
  buildPendingOrderQueueId,
  clearTabletSession,
  defaultTabletSettings,
  enqueuePendingOrder,
  loadPendingOrders,
  loadTabletDiagnostics,
  loadTabletSession,
  loadTabletSettings,
  removePendingOrder,
  saveTabletSession,
  saveTabletDiagnostics,
  saveTabletSettings,
  updatePendingOrder
} from './src/services/storage';
import { normalizeApiBaseUrl } from './src/services/network';
import {
  getFriendlyErrorMessage,
  isNetworkRequestError,
  NETWORK_SEND_FAILURE_MESSAGE,
  NETWORK_SEND_FAILURE_TITLE
} from './src/services/errors';
import {
  isProductImageFailed,
  markProductImageFailed,
  prefetchProductImages,
  resolveProductImageUri
} from './src/services/imageCache';

type AppMode = 'loading' | 'setup' | 'locked' | 'unlock' | 'settingsAuth' | 'menu' | 'cart';
type SettingsReturnMode = 'loading' | 'locked' | 'menu' | 'cart';
type SettingsAccessMode = 'initial' | 'waiter' | 'emergencyApi';
type AppDialogTone = 'info' | 'warning' | 'danger' | 'success';

type AppDialog = {
  title: string;
  message: string;
  tone?: AppDialogTone;
  primaryLabel?: string;
  secondaryLabel?: string;
  onConfirm?: () => void | Promise<void>;
  onCancel?: () => void;
};

type KioskLockTaskMode = 'locked' | 'pinned' | 'none' | 'active' | 'unsupported' | 'unknown';

type TabletKioskStatus = {
  secureKiosk: boolean;
  deviceOwner: boolean;
  profileOwner: boolean;
  managedOwner: boolean;
  lockTaskPermitted: boolean;
  lockTaskMode: KioskLockTaskMode;
  moduleAvailable: boolean;
};

type SettingsForm = {
  baseUrl: string;
  empresaId: string;
  mesaNumero: string;
  terminalName: string;
  cobrarMaiorValorFracionado: boolean;
};

const CUSTOMER_LOCK_MESSAGE = 'Mesa bloqueada. Solicite a liberacao ao garcom.';
const MODULE_DISABLED_MESSAGE = 'Modulo não habilitado';
const API_RECONNECT_MESSAGE = 'Sem resposta da API. Verifique a rede ou configure o IP do servidor.';
const APP_DISPLAY_BRAND = 'Cardapio Tablet';
const APP_DISPLAY_NAME = 'CARDAPIO TABLET';
const APP_DISPLAY_VERSION = '2.0.0';
const EMERGENCY_API_ADMIN_LOGIN = 'ADM';
const EMERGENCY_API_ADMIN_PASSWORD = '18021950';
const PRODUCT_TITLE_CONNECTORS = new Set(['a', 'ao', 'aos', 'as', 'com', 'da', 'das', 'de', 'do', 'dos', 'e', 'em', 'na', 'nas', 'no', 'nos', 'para', 'por', 'sem']);
const FRACTION_FLAVOR_COUNTS = [1, 2, 3, 4] as const;
const DEFAULT_FRACTION_FLAVOR_COUNT = 1;
const FRACTION_GROUP_TITLE = 'Item fracionado';
const SMART_SYNC_MIN_INTERVAL_MS = 5000;
const PRODUCT_IMAGE_PREFETCH_LIMIT = 64;
const PRODUCT_LAUNCH_ARM_DELAY_MS = 350;

type TabletKioskModule = {
  exitApp?: () => Promise<boolean>;
  getKioskStatus?: () => Promise<Partial<TabletKioskStatus>>;
};

const TabletKiosk = NativeModules.TabletKiosk as TabletKioskModule | undefined;

const DEFAULT_KIOSK_STATUS: TabletKioskStatus = {
  secureKiosk: false,
  deviceOwner: false,
  profileOwner: false,
  managedOwner: false,
  lockTaskPermitted: false,
  lockTaskMode: 'unknown',
  moduleAvailable: false
};

function formatMoney(value: number): string {
  return `R$ ${Number(value || 0).toFixed(2).replace('.', ',')}`;
}

function formatMesa(value: number): string {
  return String(Math.max(1, Math.trunc(Number(value || 1)))).padStart(2, '0');
}

function formatItemCount(value: number): string {
  const count = Math.max(0, Math.trunc(Number(value || 0)));
  return `${count} ${count === 1 ? 'item' : 'itens'}`;
}

function AppFooter() {
  return (
    <View style={styles.appFooter}>
      <Text style={styles.appFooterText}>
        {APP_DISPLAY_NAME}  Versão {APP_DISPLAY_VERSION}
      </Text>
    </View>
  );
}

function formatQuantity(value: number): string {
  const quantity = Number(value || 0);
  if (!Number.isFinite(quantity)) return '0';
  if (Number.isInteger(quantity)) return String(quantity);
  return quantity.toFixed(3).replace(/0+$/, '').replace(/\.$/, '').replace('.', ',');
}

function formatFractionFlavorCount(value: number): string {
  const count = Math.max(1, Math.trunc(Number(value || 1)));
  return `${count} ${count === 1 ? 'sabor' : 'sabores'}`;
}

function formatDateTime(value?: string): string {
  if (!value) return 'Ainda nao registrado';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'Ainda nao registrado';
  const pad = (part: number) => String(part).padStart(2, '0');
  return `${pad(date.getDate())}/${pad(date.getMonth() + 1)} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function formatDiagnosticsDateTime(value?: string): string {
  if (!value) return 'Nao registrado';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'Nao registrado';
  const pad = (part: number) => String(part).padStart(2, '0');
  return `${pad(date.getDate())}/${pad(date.getMonth() + 1)}/${date.getFullYear()} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function normalizeKioskStatus(status?: Partial<TabletKioskStatus> | null): TabletKioskStatus {
  const validModes = new Set<KioskLockTaskMode>(['locked', 'pinned', 'none', 'active', 'unsupported', 'unknown']);
  const lockTaskMode = validModes.has(status?.lockTaskMode as KioskLockTaskMode)
    ? (status?.lockTaskMode as KioskLockTaskMode)
    : 'unknown';

  return {
    secureKiosk: Boolean(status?.secureKiosk),
    deviceOwner: Boolean(status?.deviceOwner),
    profileOwner: Boolean(status?.profileOwner),
    managedOwner: Boolean(status?.managedOwner),
    lockTaskPermitted: Boolean(status?.lockTaskPermitted),
    lockTaskMode,
    moduleAvailable: Boolean(status)
  };
}

function getKioskStatusPresentation(status: TabletKioskStatus | null, checking: boolean) {
  if (checking && !status) {
    return {
      tone: 'neutral' as const,
      badge: '...',
      title: 'Verificando',
      message: 'Consultando o Android neste tablet.'
    };
  }

  if (status?.secureKiosk || status?.lockTaskMode === 'locked') {
    return {
      tone: 'success' as const,
      badge: 'OK',
      title: 'Ativo',
      message: 'Tablet em Lock Task seguro. Saida somente pela configuracao autorizada.'
    };
  }

  if (status?.lockTaskMode === 'pinned') {
    return {
      tone: 'danger' as const,
      badge: '!',
      title: 'Inseguro',
      message: 'Android esta em PINNED; o cliente ainda consegue sair pelo atalho do sistema.'
    };
  }

  if (status?.managedOwner && !status.lockTaskPermitted) {
    return {
      tone: 'warning' as const,
      badge: 'ADM',
      title: 'Quase pronto',
      message: 'Device Owner detectado, mas o Lock Task ainda nao foi liberado pelo Android.'
    };
  }

  if (status?.moduleAvailable === false) {
    return {
      tone: 'danger' as const,
      badge: '!',
      title: 'Modulo indisponivel',
      message: 'Nao foi possivel consultar o modo kiosk nativo deste tablet.'
    };
  }

  return {
    tone: 'danger' as const,
    badge: 'OFF',
    title: 'Inativo',
    message: 'Falta provisionar este tablet como Device Owner ou MDM para bloquear atalhos.'
  };
}

function getOkLabel(value?: boolean): string {
  if (value === true) return 'OK';
  if (value === false) return 'Falhou';
  return 'Sem teste';
}

function isEmergencyApiRecoveryCredentials(login: string, password: string): boolean {
  return (
    login.trim().toLocaleUpperCase('pt-BR') === EMERGENCY_API_ADMIN_LOGIN &&
    password.trim() === EMERGENCY_API_ADMIN_PASSWORD
  );
}

function getPendingOrderPresentation(order: PendingOrder): { label: string; tone: 'neutral' | 'warning' | 'danger' } {
  if (order.lastError) {
    return { label: 'Falhou', tone: 'danger' };
  }

  if (order.attempts > 0) {
    return { label: 'Aguardando nova tentativa', tone: 'warning' };
  }

  return { label: 'Aguardando envio', tone: 'neutral' };
}

function formatPendingOrderTitle(order: PendingOrder): string {
  const saleId = Number(order.session?.idVenda || 0);
  const saleLabel = saleId > 0 ? `Venda ${saleId}` : 'Venda sem id';
  return `Mesa ${formatMesa(order.session?.mesaNumero || order.settings?.mesaNumero || 1)} - ${saleLabel}`;
}

function buildTabletDiagnosticsReport({
  settings,
  diagnostics,
  pendingOrders,
  kioskStatus
}: {
  settings: TabletSettings;
  diagnostics: TabletDiagnostics;
  pendingOrders: PendingOrder[];
  kioskStatus: TabletKioskStatus | null;
}): string {
  const kioskPresentation = getKioskStatusPresentation(kioskStatus, false);
  const lines = [
    `${APP_DISPLAY_BRAND} - Diagnostico`,
    `Versao: ${APP_DISPLAY_VERSION}`,
    `Gerado em: ${formatDiagnosticsDateTime(new Date().toISOString())}`,
    '',
    'Configuracao',
    `Servidor API: ${settings.baseUrl}`,
    `Empresa: ${settings.empresaId}`,
    `Mesa: ${formatMesa(settings.mesaNumero)}`,
    `Terminal: ${settings.terminalName}`,
    `Modulo Cardapio Tablet: ${settings.utilizaCardapioTablet || diagnostics.utilizaCardapioTablet ? 'habilitado' : 'sem confirmacao'}`,
    '',
    'Rede e sincronizacao',
    `Modulo: ${getOkLabel(settings.utilizaCardapioTablet || diagnostics.utilizaCardapioTablet)} em ${formatDiagnosticsDateTime(diagnostics.lastModuleCheckAt)}`,
    `Sincronizacao: ${getOkLabel(diagnostics.lastSyncOk)} em ${formatDiagnosticsDateTime(diagnostics.lastSyncAt)}`,
    `Catalogo: ${diagnostics.lastCatalogSource === 'api' ? 'API' : 'sem leitura'} em ${formatDiagnosticsDateTime(diagnostics.lastCatalogAt)}`,
    `Ping API: ${getOkLabel(diagnostics.lastPingOk)}${diagnostics.lastPingMs ? ` (${diagnostics.lastPingMs}ms)` : ''}`,
    `Ultimo envio: ${getOkLabel(diagnostics.lastSendOk)} em ${formatDiagnosticsDateTime(diagnostics.lastSendAt)}`,
    '',
    'Kiosk Android',
    `Status: ${kioskPresentation.title}`,
    `Modo LockTask: ${kioskStatus?.lockTaskMode || 'desconhecido'}`,
    `Device Owner: ${kioskStatus?.deviceOwner ? 'sim' : 'nao'}`,
    `Lock Task permitido: ${kioskStatus?.lockTaskPermitted ? 'sim' : 'nao'}`,
    '',
    'Fila offline',
    `Pendencias: ${pendingOrders.length}`
  ];

  if (pendingOrders.length === 0) {
    lines.push('Nenhuma pendencia offline registrada.');
  } else {
    pendingOrders.slice(0, 10).forEach((order, index) => {
      const pendingStatus = getPendingOrderPresentation(order);
      lines.push(
        `${index + 1}. ${formatPendingOrderTitle(order)} - ${pendingStatus.label} - ${formatMoney(order.total)} - ${formatItemCount(order.items.length)} - ${formatDiagnosticsDateTime(order.updatedAt)}`,
        `   Tentativas: ${order.attempts}`,
        `   Erro: ${order.lastError || 'sem erro registrado'}`
      );
    });

    if (pendingOrders.length > 10) {
      lines.push(`Mais ${pendingOrders.length - 10} pendencia(s) nao listadas.`);
    }
  }

  lines.push(
    '',
    'Ultimos erros',
    `Envio: ${diagnostics.lastSendError || 'nenhum'}`,
    `Sincronizacao: ${diagnostics.lastSyncError || 'nenhum'}`
  );

  return lines.join('\n');
}

function getCredentialFailureMessage(error: unknown, fallback: string): string {
  const message = getFriendlyErrorMessage(error, fallback);
  const normalized = message.toLocaleLowerCase('pt-BR');

  if (
    normalized.includes('usuario') ||
    normalized.includes('usuário') ||
    normalized.includes('senha') ||
    normalized.includes('garcom') ||
    normalized.includes('garçom')
  ) {
    return 'Usuario ou senha nao conferem. Solicite ao garcom responsavel.';
  }

  return message;
}

function formatProductCardTitle(value: string): string {
  const normalized = value.replace(/\s+/g, ' ').trim();
  if (!normalized) return '';

  return normalized
    .toLocaleLowerCase('pt-BR')
    .split(' ')
    .map((word, wordIndex) => {
      const unitMatch = word.match(/^(\d+)(ml|l|g|kg|un|und)$/i);
      if (unitMatch) return `${unitMatch[1]} ${unitMatch[2].toLocaleLowerCase('pt-BR')}`;
      if (/\d/.test(word)) return word.toLocaleUpperCase('pt-BR');

      return word
        .split('-')
        .map((part, partIndex) => {
          if (!part) return part;
          if ((wordIndex > 0 || partIndex > 0) && PRODUCT_TITLE_CONNECTORS.has(part)) return part;
          return `${part.charAt(0).toLocaleUpperCase('pt-BR')}${part.slice(1)}`;
        })
        .join('-');
    })
    .join(' ');
}

function getCategoryInitial(value: string): string {
  return value.trim().charAt(0).toLocaleUpperCase('pt-BR') || '#';
}

function toSettingsForm(settings: TabletSettings): SettingsForm {
  return {
    baseUrl: settings.baseUrl,
    empresaId: String(settings.empresaId),
    mesaNumero: String(settings.mesaNumero),
    terminalName: settings.terminalName,
    cobrarMaiorValorFracionado: settings.cobrarMaiorValorFracionado
  };
}

function settingsFromForm(form: SettingsForm): TabletSettings {
  const mesaNumero = Math.max(1, Math.trunc(Number(form.mesaNumero.replace(',', '.')) || 1));
  const empresaId = Math.max(1, Math.trunc(Number(form.empresaId.replace(',', '.')) || 1));
  const terminalName = form.terminalName.trim() || `TABLET-MESA-${mesaNumero}`;

  return {
    baseUrl: normalizeApiBaseUrl(form.baseUrl, defaultTabletSettings.baseUrl),
    empresaId,
    mesaNumero,
    terminalName,
    pollingMs: 10000,
    cobrarMaiorValorFracionado: form.cobrarMaiorValorFracionado,
    configured: true,
    utilizaCardapioTablet: false
  };
}

function isSaleStatusOpenForTablet(value: unknown): boolean {
  const status = normalizeSaleStatus(value);
  if (!status) return true;
  return (
    status.includes('pendente') ||
    status.includes('digitacao') ||
    status.includes('aberta') ||
    status.includes('aberto')
  );
}

function buildSession(openedTable: TableOrder, settings: TabletSettings, user: { idUsuario: number; nome: string; login: string }): TabletSession {
  return {
    idVenda: Number(openedTable.idVenda || openedTable.venda?.idVenda || 0),
    idMesa: Number(openedTable.idMesa || settings.mesaNumero),
    mesaNumero: Number(openedTable.numeroMesa || settings.mesaNumero),
    waiterId: user.idUsuario,
    waiterName: user.nome,
    waiterLogin: user.login,
    openedAt: new Date().toISOString(),
    terminalName: settings.terminalName
  };
}

function buildLineId(session: TabletSession, suffix = ''): string {
  return [
    'tablet',
    session.mesaNumero,
    session.idVenda,
    Date.now(),
    Math.random().toString(36).slice(2, 8),
    suffix
  ].filter(Boolean).join('-');
}

function hasDuplicateFlavorSelection(values: Array<number | null>): boolean {
  const selected = values.filter((value): value is number => Number(value || 0) > 0);
  return selected.length !== new Set(selected).size;
}

function hasVisibleOptional(optional: ProductOptional): boolean {
  return Boolean(
    optional.descricao?.trim() ||
    optional.opcionalP?.trim() ||
    optional.opcionalM?.trim() ||
    optional.opcionalG?.trim() ||
    optional.opcionalGG?.trim() ||
    optional.opcionalExtra?.trim()
  );
}

function getVisibleProductOptionals(product: MenuItem | null | undefined): ProductOptional[] {
  return (product?.opcionais || []).filter(hasVisibleOptional);
}

function buildSelectedOptionals(
  optionals: ProductOptional[],
  getQuantity: (optionalId: number) => number,
  sizeCode: string
): LaunchOptionalPayload[] {
  return optionals.flatMap((optional): LaunchOptionalPayload[] => {
    const quantity = Math.max(0, Math.trunc(Number(getQuantity(optional.idOpcional) || 0)));
    if (quantity <= 0) return [];

    return Array.from({ length: quantity }, () => ({
      idOpcional: optional.idOpcional,
      descricao: getOptionalDisplay(optional, sizeCode) || optional.descricao,
      valor: getOptionalPrice(optional, sizeCode),
      gratis: Boolean(optional.gratis)
    }));
  });
}

function getOptionalsAddition(optionals: LaunchOptionalPayload[], quantity = 1): number {
  return optionals.reduce(
    (total, optional) => total + (optional.gratis ? 0 : Number(optional.valor || 0) * Number(quantity || 0)),
    0
  );
}

function summarizeOptionals(optionals: Array<{ idOpcional?: number; descricao: string }>): string {
  const counts = new Map<string, { descricao: string; quantidade: number }>();
  optionals.forEach((optional) => {
    const key = `${optional.idOpcional}:${optional.descricao}`;
    const current = counts.get(key) || { descricao: optional.descricao, quantidade: 0 };
    counts.set(key, {
      ...current,
      quantidade: current.quantidade + 1
    });
  });

  return Array.from(counts.values())
    .map((item) => (item.quantidade > 1 ? `${item.quantidade}x ${item.descricao}` : item.descricao))
    .join(', ');
}

function getOptionalsSignature(optionals: Array<{ idOpcional?: number; descricao: string; valor?: number; gratis?: boolean }>): string {
  const counts = new Map<string, number>();
  optionals.forEach((optional) => {
    const key = [
      optional.idOpcional || 0,
      optional.descricao.trim().toLocaleUpperCase('pt-BR'),
      Number(optional.valor || 0),
      optional.gratis ? 1 : 0
    ].join('|');
    counts.set(key, (counts.get(key) || 0) + 1);
  });

  return Array.from(counts.entries())
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([key, quantity]) => `${key}:${quantity}`)
    .join(';');
}

function getFractionOptionalsForPresentation<T extends { opcionais?: O[] }, O extends { idOpcional?: number; descricao: string; valor?: number; gratis?: boolean }>(
  fractions: T[]
): O[] {
  const optionalsByFraction = fractions
    .map((fraction) => fraction.opcionais || [])
    .filter((optionals) => optionals.length > 0);

  if (optionalsByFraction.length === 0) return [];

  const firstSignature = getOptionalsSignature(optionalsByFraction[0]);
  const sameOptionalsInEveryFraction = optionalsByFraction.every(
    (optionals) => getOptionalsSignature(optionals) === firstSignature
  );

  return sameOptionalsInEveryFraction ? optionalsByFraction[0] : optionalsByFraction.flat();
}

function getCombinedOptionalsForPresentation<T extends { opcionais?: O[] }, O extends { idOpcional?: number; descricao: string; valor?: number; gratis?: boolean }>(
  ownOptionals: O[] = [],
  fractions: T[] = []
): O[] {
  const fractionOptionals = getFractionOptionalsForPresentation<T, O>(fractions);
  if (ownOptionals.length === 0) return fractionOptionals;
  if (fractionOptionals.length === 0) return ownOptionals;
  return getOptionalsSignature(ownOptionals) === getOptionalsSignature(fractionOptionals)
    ? ownOptionals
    : [...ownOptionals, ...fractionOptionals];
}

function getCartLineFractions(item: CartItem): LaunchItemFractionPayload[] {
  return (item.fracoes || []).filter((fraction) => Boolean(fraction.produtoDescricao?.trim()));
}

function getSingleCartFraction(item: CartItem): LaunchItemFractionPayload | null {
  const fractions = getCartLineFractions(item);
  return fractions.length === 1 ? fractions[0] : null;
}

function getCartLineTitle(item: CartItem): string {
  const fractions = getCartLineFractions(item);
  if (fractions.length > 1) return FRACTION_GROUP_TITLE;
  return getSingleCartFraction(item)?.produtoDescricao || item.product.descricao;
}

function getCartLineSizeDescription(item: CartItem): string {
  const fractions = getCartLineFractions(item);
  const description = item.descricaoTamanho.trim();
  if (fractions.length > 1 && !/\b\d+\s+sabor(?:es)?\b/i.test(description)) {
    return [description, formatFractionFlavorCount(fractions.length)].filter(Boolean).join(' - ');
  }
  if (!getSingleCartFraction(item)) return description;
  return description.replace(/\s*-\s*1\s+sabor(?:es)?\s*$/i, '').trim();
}

function shouldShowCartFractionSummary(item: CartItem): boolean {
  return getCartLineFractions(item).length > 1;
}

function getCartLineOptionals(item: CartItem): LaunchOptionalPayload[] {
  return getCombinedOptionalsForPresentation(item.opcionais || [], getCartLineFractions(item));
}

function getCartLineObservation(item: CartItem): string {
  const observations = [
    item.observacao,
    ...getCartLineFractions(item).map((fraction) => fraction.observacao)
  ].filter((value): value is string => Boolean(value?.trim()));

  return Array.from(new Set(observations.map((value) => value.trim()))).join(' / ');
}

function getSingleSaleLineFraction(item: SaleLine) {
  return item.fracoes?.length === 1 ? item.fracoes[0] : null;
}

function getSaleLineTitle(item: SaleLine): string {
  if (Number(item.fracoes?.length || 0) > 1) return FRACTION_GROUP_TITLE;
  return getSingleSaleLineFraction(item)?.produtoDescricao || item.produtoDescricao || `Produto ${item.idProduto}`;
}

function getSaleLineOptionals(item: SaleLine): SaleLine['opcionais'] {
  return getCombinedOptionalsForPresentation(item.opcionais || [], item.fracoes || []);
}

function getSaleLineObservation(item: SaleLine): string {
  const observations = [
    item.observacao,
    ...(item.fracoes || []).map((fraction) => fraction.observacao)
  ].filter((value): value is string => Boolean(value?.trim()));

  return Array.from(new Set(observations.map((value) => value.trim()))).join(' / ');
}

function shouldShowSaleLineFractions(item: SaleLine): boolean {
  return Number(item.fracoes?.length || 0) > 1;
}

export default function App() {
  const [mode, setMode] = useState<AppMode>('loading');
  const [settings, setSettings] = useState<TabletSettings>(defaultTabletSettings);
  const [settingsForm, setSettingsForm] = useState<SettingsForm>(toSettingsForm(defaultTabletSettings));
  const [session, setSession] = useState<TabletSession | null>(null);
  const [activeTable, setActiveTable] = useState<TableOrder | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<MenuItem[]>([]);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | null>(null);
  const [banner, setBanner] = useState('');
  const [busyLabel, setBusyLabel] = useState('');
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const [settingsAuthLogin, setSettingsAuthLogin] = useState('');
  const [settingsAuthPassword, setSettingsAuthPassword] = useState('');
  const [settingsReturnMode, setSettingsReturnMode] = useState<SettingsReturnMode>('locked');
  const [settingsAccessMode, setSettingsAccessMode] = useState<SettingsAccessMode>('initial');
  const [startupConnectionIssue, setStartupConnectionIssue] = useState(false);
  const [sendingCart, setSendingCart] = useState(false);
  const [networkFailureVisible, setNetworkFailureVisible] = useState(false);
  const [appDialog, setAppDialog] = useState<AppDialog | null>(null);
  const [selectedProduct, setSelectedProduct] = useState<MenuItem | null>(null);
  const [selectedSize, setSelectedSize] = useState('U');
  const [selectedQuantity, setSelectedQuantity] = useState(1);
  const [selectedObservation, setSelectedObservation] = useState('');
  const [selectedOptionalQty, setSelectedOptionalQty] = useState<Record<number, number>>({});
  const [selectedFractionCount, setSelectedFractionCount] = useState(DEFAULT_FRACTION_FLAVOR_COUNT);
  const [selectedFractionIds, setSelectedFractionIds] = useState<Array<number | null>>([]);
  const [selectedFractionDetails, setSelectedFractionDetails] = useState<Record<number, MenuItem>>({});
  const [selectedFractionOptionalQty, setSelectedFractionOptionalQty] = useState<
    Record<number, Record<number, number>>
  >({});
  const [productLaunchReady, setProductLaunchReady] = useState(false);
  const [orderPreviewVisible, setOrderPreviewVisible] = useState(false);
  const [orderPreviewLoading, setOrderPreviewLoading] = useState(false);
  const [orderPreviewSale, setOrderPreviewSale] = useState<Sale | null>(null);
  const [pendingOrders, setPendingOrders] = useState<PendingOrder[]>([]);
  const [diagnostics, setDiagnostics] = useState<TabletDiagnostics>({});
  const [retryingPendingOrders, setRetryingPendingOrders] = useState(false);
  const [failedImageUris, setFailedImageUris] = useState<Record<string, true>>({});
  const [kioskStatus, setKioskStatus] = useState<TabletKioskStatus | null>(null);
  const [checkingKioskStatus, setCheckingKioskStatus] = useState(false);
  const appStateRef = useRef(AppState.currentState);
  const syncingRef = useRef(false);
  const lastSyncAttemptAtRef = useRef(0);
  const productLaunchArmTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const productDetailRequestSeqRef = useRef(0);
  const fractionDetailRequestCounterRef = useRef(0);
  const fractionDetailRequestByIndexRef = useRef<Record<number, number>>({});

  const api = useMemo(() => new TabletApi(settings.baseUrl, settings.empresaId), [settings.baseUrl, settings.empresaId]);
  const cartTotal = useMemo(() => getCartTotal(cart), [cart]);
  const showAppDialog = useCallback((dialog: AppDialog) => {
    setAppDialog(dialog);
  }, []);

  const closeAppDialog = useCallback(() => {
    setAppDialog(null);
  }, []);

  const confirmAppDialog = useCallback(() => {
    const onConfirm = appDialog?.onConfirm;
    setAppDialog(null);
    if (onConfirm) {
      void onConfirm();
    }
  }, [appDialog]);

  const cancelAppDialog = useCallback(() => {
    const onCancel = appDialog?.onCancel;
    setAppDialog(null);
    onCancel?.();
  }, [appDialog]);

  const selectedProductSizes = useMemo(
    () => (selectedProduct ? getProductSizeOptions(selectedProduct) : []),
    [selectedProduct]
  );
  const selectedProductOptionals = useMemo(
    () => getVisibleProductOptionals(selectedProduct),
    [selectedProduct]
  );
  const categoryProductCounts = useMemo(() => {
    return products.reduce<Map<number, number>>((acc, product) => {
      const categoryId = Number(product.idCategoria || 0);
      if (categoryId <= 0 || product.b_venda_mobile === false) return acc;
      acc.set(categoryId, (acc.get(categoryId) || 0) + 1);
      return acc;
    }, new Map<number, number>());
  }, [products]);

  const fractionFlavorOptions = useMemo(() => {
    if (!selectedProduct?.permiteFracao) return [];
    const categoryId = Number(selectedProduct.idCategoria || 0);
    return products
      .filter((product) => product.b_venda_mobile !== false)
      .filter((product) => !categoryId || Number(product.idCategoria || 0) === categoryId)
      .sort((left, right) => left.descricao.localeCompare(right.descricao));
  }, [products, selectedProduct]);

  const selectedFractionProducts = useMemo(() => {
    if (!selectedProduct?.permiteFracao) return [];
    const byId = new Map(fractionFlavorOptions.map((product) => [product.idProduto, product]));
    return selectedFractionIds.map((id, index) => {
      if (!id) return null;
      const detail = selectedFractionDetails[index];
      return detail?.idProduto === id ? detail : byId.get(id) || null;
    });
  }, [fractionFlavorOptions, selectedFractionDetails, selectedFractionIds, selectedProduct]);

  const selectedFractionOptionalsByIndex = useMemo(
    () => selectedFractionProducts.map((product) => getVisibleProductOptionals(product)),
    [selectedFractionProducts]
  );

  const selectedFractionLaunchOptionalsByIndex = useMemo(
    () =>
      selectedFractionOptionalsByIndex.map((optionals, index) =>
        buildSelectedOptionals(
          optionals,
          (optionalId) => selectedFractionOptionalQty[index]?.[optionalId] || 0,
          selectedSize
        )
      ),
    [selectedFractionOptionalQty, selectedFractionOptionalsByIndex, selectedSize]
  );

  const selectedOptionals = useMemo(() => {
    if (!selectedProduct) return [];
    return buildSelectedOptionals(
      selectedProductOptionals,
      (optionalId) => selectedOptionalQty[optionalId] || 0,
      selectedSize
    );
  }, [selectedOptionalQty, selectedProduct, selectedProductOptionals, selectedSize]);

  const selectedFractionReady = useMemo(() => {
    if (!selectedProduct?.permiteFracao) return true;
    return (
      selectedFractionIds.length === selectedFractionCount &&
      selectedFractionIds.every((id) => Number(id || 0) > 0) &&
      !hasDuplicateFlavorSelection(selectedFractionIds)
    );
  }, [selectedFractionCount, selectedFractionIds, selectedProduct]);

  const selectedLineTotal = useMemo(() => {
    if (!selectedProduct) return 0;
    if (selectedProduct.permiteFracao && selectedFractionProducts.length === selectedFractionCount) {
      const validFractions = selectedFractionProducts.filter((product): product is MenuItem => Boolean(product));
      if (validFractions.length !== selectedFractionCount) return 0;
      const fractionQuantity = 1 / selectedFractionCount;
      const fractionPrices = validFractions.map((product) => getProductUnitPrice(product, selectedSize));
      const maxUnitPrice = Math.max(...fractionPrices);
      const orderCount = Math.max(1, Math.round(selectedQuantity));
      const baseUnitTotal = fractionPrices.reduce((total, price) => {
        const unitPrice = settings.cobrarMaiorValorFracionado ? maxUnitPrice : price;
        return total + unitPrice * fractionQuantity;
      }, 0);
      const optionalValue = selectedFractionLaunchOptionalsByIndex.reduce(
        (total, optionals) => total + getOptionalsAddition(optionals, fractionQuantity),
        0
      );
      return roundMoney(baseUnitTotal * orderCount + optionalValue * orderCount);
    }

    const unitValue = getProductUnitPrice(selectedProduct, selectedSize);
    const optionalValue = selectedOptionals.reduce(
      (total, optional) => total + (optional.gratis ? 0 : optional.valor * selectedQuantity),
      0
    );
    return roundMoney(unitValue * selectedQuantity + optionalValue);
  }, [
    selectedFractionCount,
    selectedFractionLaunchOptionalsByIndex,
    selectedFractionProducts,
    selectedOptionals,
    selectedProduct,
    selectedQuantity,
    selectedSize,
    settings.cobrarMaiorValorFracionado
  ]);

  const filteredProducts = useMemo(() => {
    return products.filter((product) => {
      if (selectedCategoryId && Number(product.idCategoria || 0) !== selectedCategoryId) {
        return false;
      }

      return true;
    });
  }, [products, selectedCategoryId]);
  const visibleOrderLines = useMemo(
    () => (orderPreviewSale?.itens || []).filter((line) => line.situacao !== 'cancelada'),
    [orderPreviewSale]
  );

  useEffect(() => {
    const validOptionalIds = new Set(selectedProductOptionals.map((optional) => optional.idOpcional));
    setSelectedOptionalQty((current) => {
      let changed = false;
      const next: Record<number, number> = {};

      Object.entries(current).forEach(([key, value]) => {
        const idOpcional = Number(key);
        if (validOptionalIds.has(idOpcional)) {
          next[idOpcional] = value;
        } else {
          changed = true;
        }
      });

      return changed ? next : current;
    });
  }, [selectedProductOptionals]);

  useEffect(() => {
    setSelectedFractionOptionalQty((current) => {
      let changed = false;
      const next: Record<number, Record<number, number>> = {};

      Object.entries(current).forEach(([indexKey, quantities]) => {
        const index = Number(indexKey);
        if (index < 0 || index >= selectedFractionCount) {
          changed = true;
          return;
        }

        const validOptionalIds = new Set(
          (selectedFractionOptionalsByIndex[index] || []).map((optional) => optional.idOpcional)
        );
        const validQuantities: Record<number, number> = {};
        Object.entries(quantities).forEach(([optionalKey, quantity]) => {
          const optionalId = Number(optionalKey);
          if (validOptionalIds.has(optionalId)) {
            validQuantities[optionalId] = quantity;
          } else {
            changed = true;
          }
        });

        if (Object.keys(validQuantities).length > 0) {
          next[index] = validQuantities;
        } else if (Object.keys(quantities).length > 0) {
          changed = true;
        }
      });

      return changed ? next : current;
    });
  }, [selectedFractionCount, selectedFractionOptionalsByIndex]);

  useEffect(() => {
    void prefetchProductImages(filteredProducts, PRODUCT_IMAGE_PREFETCH_LIMIT);
  }, [filteredProducts]);

  useEffect(
    () => () => {
      productDetailRequestSeqRef.current += 1;
      if (productLaunchArmTimerRef.current) {
        clearTimeout(productLaunchArmTimerRef.current);
      }
    },
    []
  );

  const mergeDiagnostics = useCallback((patch: TabletDiagnostics) => {
    setDiagnostics((current) => {
      const next = {
        ...current,
        ...patch
      };
      void saveTabletDiagnostics(next);
      return next;
    });
  }, []);

  const refreshPendingOrders = useCallback(async () => {
    const loaded = await loadPendingOrders();
    setPendingOrders(loaded);
    mergeDiagnostics({ pendingOrderCount: loaded.length });
    return loaded;
  }, [mergeDiagnostics]);

  const refreshKioskStatus = useCallback(async () => {
    setCheckingKioskStatus(true);
    try {
      if (!TabletKiosk?.getKioskStatus) {
        setKioskStatus(DEFAULT_KIOSK_STATUS);
        return;
      }

      const status = await TabletKiosk.getKioskStatus();
      setKioskStatus(normalizeKioskStatus(status));
    } catch {
      setKioskStatus(DEFAULT_KIOSK_STATUS);
    } finally {
      setCheckingKioskStatus(false);
    }
  }, []);

  const shareTabletDiagnostics = useCallback(async () => {
    try {
      const currentPendingOrders = await refreshPendingOrders();
      const report = buildTabletDiagnosticsReport({
        settings,
        diagnostics: {
          ...diagnostics,
          pendingOrderCount: currentPendingOrders.length
        },
        pendingOrders: currentPendingOrders,
        kioskStatus
      });

      await Share.share({
        title: 'Diagnostico Cardapio Tablet',
        message: report
      });
    } catch (error) {
      showAppDialog({
        title: 'Diagnostico',
        message: getFriendlyErrorMessage(error, 'Nao foi possivel exportar o diagnostico.'),
        tone: 'danger'
      });
    }
  }, [diagnostics, kioskStatus, refreshPendingOrders, settings, showAppDialog]);

  const lockTablet = useCallback(async (message = CUSTOMER_LOCK_MESSAGE) => {
    await clearTabletSession();
    setSession(null);
    setActiveTable(null);
    setCart([]);
    setLogin('');
    setPassword('');
    setSettingsAuthLogin('');
    setSettingsAuthPassword('');
    setSettingsAccessMode('initial');
    setStartupConnectionIssue(false);
    setBanner(message);
    setMode('locked');
  }, []);

  const applyCompanyStatus = useCallback(
    async (baseSettings: TabletSettings, companyStatus: CompanyStatus, persist = true) => {
      const enabled = companyStatus.utilizaCardapioTablet === true;
      const checkedAt = new Date().toISOString();
      const updatedSettings = {
        ...baseSettings,
        utilizaCardapioTablet: enabled
      };

      mergeDiagnostics({
        lastModuleCheckAt: checkedAt,
        utilizaCardapioTablet: enabled,
        lastSyncError: enabled ? undefined : MODULE_DISABLED_MESSAGE
      });

      setSettings((current) =>
        current.baseUrl === baseSettings.baseUrl && Number(current.empresaId || 0) === Number(baseSettings.empresaId || 0)
          ? {
              ...current,
              utilizaCardapioTablet: enabled
            }
          : current
      );

      if (persist && baseSettings.configured && baseSettings.utilizaCardapioTablet !== enabled) {
        const savedSettings = await saveTabletSettings(updatedSettings);
        setSettings(savedSettings);
        setSettingsForm(toSettingsForm(savedSettings));
        return savedSettings;
      }

      return updatedSettings;
    },
    [mergeDiagnostics]
  );

  const syncCompanyStatus = useCallback(
    async (
      client: TabletApi,
      nextSettings: TabletSettings,
      options: { persist?: boolean; lockWhenDisabled?: boolean; silent?: boolean } = {}
    ) => {
      const companyStatus = await client.getCompanyStatus();
      const updatedSettings = await applyCompanyStatus(nextSettings, companyStatus, options.persist !== false);

      if (!updatedSettings.utilizaCardapioTablet) {
        if (options.lockWhenDisabled !== false) {
          await lockTablet(MODULE_DISABLED_MESSAGE);
        }
        if (!options.silent) {
          setBanner(MODULE_DISABLED_MESSAGE);
        }
        return false;
      }

      return true;
    },
    [applyCompanyStatus, lockTablet]
  );

  const loadCatalogFromClient = useCallback(
    async (client: TabletApi) => {
      setBusyLabel('Carregando cardapio...');
      try {
        const [nextCategories, nextProducts] = await Promise.all([
          client.listCategories(),
          client.listProducts(true)
        ]);
        setCategories(nextCategories);
        setProducts(nextProducts);
        setSelectedCategoryId((current) =>
          current && nextCategories.some((category) => category.id === current)
            ? current
            : nextCategories[0]?.id ?? null
        );
        mergeDiagnostics({
          lastCatalogAt: new Date().toISOString(),
          lastCatalogSource: 'api'
        });
      } finally {
        setBusyLabel('');
      }
    },
    [mergeDiagnostics]
  );

  const loadCatalog = useCallback(
    async () => loadCatalogFromClient(api),
    [api, loadCatalogFromClient]
  );

  useEffect(() => {
    const subscription = BackHandler.addEventListener('hardwareBackPress', () => true);
    return () => subscription.remove();
  }, []);

  useEffect(() => {
    if (mode === 'setup') {
      void refreshKioskStatus();
    }
  }, [mode, refreshKioskStatus]);

  const verifySession = useCallback(
    async (client: TabletApi, nextSettings: TabletSettings, nextSession: TabletSession, silent = false) => {
      try {
        const moduleEnabled = await syncCompanyStatus(client, nextSettings, { silent, lockWhenDisabled: true });
        if (!moduleEnabled) return false;

        const tables = await client.listTables();
        const table = findTableByNumber(tables, nextSession.mesaNumero || nextSettings.mesaNumero, nextSession.idMesa);
        const currentSaleId = Number(table?.idVenda || table?.venda?.idVenda || 0);

        if (!table || currentSaleId <= 0 || currentSaleId !== Number(nextSession.idVenda || 0) || !isTableOpenForTablet(table)) {
          await lockTablet(CUSTOMER_LOCK_MESSAGE);
          return false;
        }

        const sale = await client.getSale(nextSession.idVenda, false);
        if (sale?.situacao && !isSaleStatusOpenForTablet(sale.situacao)) {
          await lockTablet(CUSTOMER_LOCK_MESSAGE);
          return false;
        }

        setActiveTable({
          ...table,
          valorTotal: sale?.valorTotal ?? table.valorTotal,
          situacao: sale?.situacao || table.situacao
        });
        mergeDiagnostics({
          lastSyncAt: new Date().toISOString(),
          lastSyncOk: true,
          lastSyncError: undefined
        });
        setStartupConnectionIssue(false);
        if (!silent) {
          setBanner('');
        }
        return true;
      } catch (error) {
        const message = getFriendlyErrorMessage(error, 'Nao foi possivel consultar a mesa.');
        mergeDiagnostics({
          lastSyncAt: new Date().toISOString(),
          lastSyncOk: false,
          lastSyncError: message
        });
        if (!silent) {
          setBanner(message);
        } else {
          setStartupConnectionIssue(true);
          setBanner(API_RECONNECT_MESSAGE);
        }
        return true;
      }
    },
    [lockTablet, mergeDiagnostics, syncCompanyStatus]
  );

  const retryStartupConnection = useCallback(
    async (showBusy = true) => {
      if (!settings.configured) {
        setMode('setup');
        return;
      }

      if (!session) {
        setMode('locked');
        return;
      }

      if (showBusy) {
        setBusyLabel('Reconectando API...');
      }

      try {
        const alive = await verifySession(api, settings, session, true);
        if (!alive) return;
        await loadCatalog();
        mergeDiagnostics({
          lastSyncAt: new Date().toISOString(),
          lastSyncOk: true,
          lastSyncError: undefined
        });
        setStartupConnectionIssue(false);
        setBanner('');
        setMode('menu');
      } catch (error) {
        const message = getFriendlyErrorMessage(error, API_RECONNECT_MESSAGE);
        mergeDiagnostics({
          lastSyncAt: new Date().toISOString(),
          lastSyncOk: false,
          lastSyncError: message
        });
        setStartupConnectionIssue(true);
        setBanner(API_RECONNECT_MESSAGE);
        setMode('loading');
      } finally {
        if (showBusy) {
          setBusyLabel('');
        }
      }
    },
    [api, loadCatalog, mergeDiagnostics, session, settings, verifySession]
  );

  useEffect(() => {
    let alive = true;

    async function bootstrap() {
      const [loadedSettings, loadedSession, loadedDiagnostics, loadedPendingOrders] = await Promise.all([
        loadTabletSettings(),
        loadTabletSession(),
        loadTabletDiagnostics(),
        loadPendingOrders()
      ]);
      if (!alive) return;

      setStartupConnectionIssue(false);
      setSettings(loadedSettings);
      setSettingsForm(toSettingsForm(loadedSettings));
      setDiagnostics({
        ...loadedDiagnostics,
        pendingOrderCount: loadedPendingOrders.length
      });
      setPendingOrders(loadedPendingOrders);

      if (!loadedSettings.configured) {
        setMode('setup');
        return;
      }

      const client = new TabletApi(loadedSettings.baseUrl, loadedSettings.empresaId);
      try {
        const moduleEnabled = await syncCompanyStatus(client, loadedSettings, {
          lockWhenDisabled: false,
          silent: true
        });
        if (!moduleEnabled) {
          setBanner(MODULE_DISABLED_MESSAGE);
        }
      } catch (error) {
        mergeDiagnostics({
          lastModuleCheckAt: new Date().toISOString(),
          utilizaCardapioTablet: false,
          lastSyncError: getFriendlyErrorMessage(error, 'Nao foi possivel verificar o modulo Cardapio Tablet.')
        });
        setStartupConnectionIssue(true);
        setBanner(API_RECONNECT_MESSAGE);
      }

      if (!loadedSession) {
        setMode('locked');
        return;
      }

      setSession(loadedSession);
      const aliveSession = await verifySession(client, loadedSettings, loadedSession, true);
      if (!alive) return;

      if (aliveSession) {
        try {
          await loadCatalogFromClient(client);
          if (!alive) return;
          setStartupConnectionIssue(false);
          setBanner('');
          setMode('menu');
        } catch (error) {
          const message = getFriendlyErrorMessage(error, API_RECONNECT_MESSAGE);
          mergeDiagnostics({
            lastSyncAt: new Date().toISOString(),
            lastSyncOk: false,
            lastSyncError: message
          });
          setStartupConnectionIssue(true);
          setBanner(API_RECONNECT_MESSAGE);
          setMode('loading');
        }
      }
    }

    void bootstrap();
    return () => {
      alive = false;
    };
  }, [loadCatalogFromClient, mergeDiagnostics, syncCompanyStatus, verifySession]);

  useEffect(() => {
    if (!session || (mode !== 'menu' && mode !== 'cart')) return undefined;

    const timer = setInterval(() => {
      void verifySession(api, settings, session, true);
    }, settings.pollingMs);

    return () => clearInterval(timer);
  }, [api, mode, session, settings, verifySession]);

  useEffect(() => {
    if (mode !== 'loading' || !startupConnectionIssue || !settings.configured || !session) return undefined;

    const timer = setInterval(() => {
      void retryStartupConnection(false);
    }, settings.pollingMs);

    return () => clearInterval(timer);
  }, [mode, retryStartupConnection, session, settings.configured, settings.pollingMs, startupConnectionIssue]);

  const isApiRecoveryAuthMode = useCallback(
    () => startupConnectionIssue || settingsReturnMode === 'loading',
    [settingsReturnMode, startupConnectionIssue]
  );

  const isCurrentApiCommunicating = useCallback(async () => {
    try {
      return await api.ping();
    } catch {
      return false;
    }
  }, [api]);

  const saveSettings = async () => {
    setBusyLabel('Salvando configuracao...');
    try {
      const formToSave =
        settingsAccessMode === 'emergencyApi'
          ? {
              ...settingsForm,
              empresaId: String(settings.empresaId),
              mesaNumero: String(settings.mesaNumero),
              terminalName: settings.terminalName,
              cobrarMaiorValorFracionado: settings.cobrarMaiorValorFracionado
            }
          : settingsForm;
      const normalizedSettings = settingsFromForm(formToSave);
      const client = new TabletApi(normalizedSettings.baseUrl, normalizedSettings.empresaId);
      const companyStatus = await client.getCompanyStatus();
      const moduleEnabled = companyStatus.utilizaCardapioTablet === true;
      const nextSettings = await saveTabletSettings({
        ...normalizedSettings,
        utilizaCardapioTablet: moduleEnabled
      });
      setSettings(nextSettings);
      setSettingsForm(toSettingsForm(nextSettings));
      mergeDiagnostics({
        lastModuleCheckAt: new Date().toISOString(),
        utilizaCardapioTablet: moduleEnabled,
        lastSyncError: moduleEnabled ? undefined : MODULE_DISABLED_MESSAGE
      });
      await clearTabletSession();
      setSession(null);
      setActiveTable(null);
      setCart([]);
      setSettingsAccessMode('initial');
      setStartupConnectionIssue(false);
      setBanner(moduleEnabled ? 'Configuracao salva.' : MODULE_DISABLED_MESSAGE);
      setMode('locked');
    } catch (error) {
      showAppDialog({
        title: 'Nao foi possivel salvar',
        message: getFriendlyErrorMessage(error, 'Confira os dados da configuracao e tente novamente.'),
        tone: 'danger'
      });
    } finally {
      setBusyLabel('');
    }
  };

  const testConnection = async () => {
    const nextSettings = settingsFromForm(settingsForm);
    setBusyLabel('Testando API...');
    const startedAt = Date.now();
    try {
      const client = new TabletApi(nextSettings.baseUrl, nextSettings.empresaId);
      const ok = await client.ping();
      const companyStatus = await client.getCompanyStatus();
      const moduleEnabled = companyStatus.utilizaCardapioTablet === true;
      mergeDiagnostics({
        lastPingAt: new Date().toISOString(),
        lastPingOk: ok,
        lastPingMs: Date.now() - startedAt,
        lastModuleCheckAt: new Date().toISOString(),
        utilizaCardapioTablet: moduleEnabled,
        lastSyncError: moduleEnabled ? undefined : MODULE_DISABLED_MESSAGE
      });
      setBanner(moduleEnabled ? (ok ? 'API respondeu com sucesso.' : 'API respondeu, mas nao confirmou o ping.') : MODULE_DISABLED_MESSAGE);
    } catch (error) {
      mergeDiagnostics({
        lastPingAt: new Date().toISOString(),
        lastPingOk: false,
        lastPingMs: Date.now() - startedAt,
        lastModuleCheckAt: new Date().toISOString(),
        utilizaCardapioTablet: false,
        lastSyncError: getFriendlyErrorMessage(error, 'Falha ao testar API.')
      });
      setBanner(getFriendlyErrorMessage(error, 'Falha ao testar API.'));
    } finally {
      setBusyLabel('');
    }
  };

  const openUnlock = () => {
    setBanner('');
    setLogin('');
    setPassword('');
    setMode('unlock');
  };

  const cancelUnlock = () => {
    setBanner('');
    setLogin('');
    setPassword('');
    setMode('locked');
  };

  const getSettingsReturnMode = (): SettingsReturnMode => {
    if ((settingsReturnMode === 'menu' || settingsReturnMode === 'cart') && !session) return 'locked';
    return settingsReturnMode;
  };

  const openSettingsAuth = (returnMode: SettingsReturnMode = 'locked') => {
    setSettingsReturnMode(returnMode);
    if (!settings.configured) {
      setSettingsAccessMode('initial');
      setMode('setup');
      return;
    }
    setBanner('');
    setSettingsAuthLogin('');
    setSettingsAuthPassword('');
    setMode('settingsAuth');
  };

  const openApiRecoverySettings = () => {
    setBanner(API_RECONNECT_MESSAGE);
    setSettingsAuthLogin('');
    setSettingsAuthPassword('');
    setSettingsForm(toSettingsForm(settings));
    setSettingsAccessMode('emergencyApi');
    setMode('setup');
  };

  const cancelSettingsAuth = () => {
    setBanner('');
    setSettingsAuthLogin('');
    setSettingsAuthPassword('');
    setSettingsAccessMode('initial');
    setMode(getSettingsReturnMode());
  };

  const cancelSettingsChange = () => {
    setBanner('');
    setSettingsForm(toSettingsForm(settings));
    setSettingsAccessMode('initial');
    setMode(getSettingsReturnMode());
  };

  const closeAuthorizedApp = () => {
    showAppDialog({
      title: 'Fechar APP',
      message: 'Deseja encerrar o cardapio deste tablet?',
      tone: 'warning',
      primaryLabel: 'Fechar APP',
      secondaryLabel: 'Cancelar',
      onConfirm: async () => {
        try {
          await TabletKiosk?.exitApp?.();
        } catch {
          BackHandler.exitApp();
        }
      }
    });
  };

  const authorizeSettingsChange = async () => {
    if (!settingsAuthLogin.trim() || !settingsAuthPassword.trim()) {
      showAppDialog({
        title: 'Credenciais obrigatorias',
        message: 'Informe usuario e senha do garcom para acessar a configuracao.',
        tone: 'warning'
      });
      return;
    }

    const recoveryAuthMode = isApiRecoveryAuthMode();
    const emergencyCredentials = isEmergencyApiRecoveryCredentials(settingsAuthLogin, settingsAuthPassword);

    setBusyLabel(recoveryAuthMode && emergencyCredentials ? 'Verificando comunicacao da API...' : 'Autorizando configuracao...');
    try {
      if (recoveryAuthMode && emergencyCredentials) {
        const apiCommunicating = await isCurrentApiCommunicating();
        if (apiCommunicating) {
          showAppDialog({
            title: 'API comunicando',
            message: 'A API respondeu. Use usuario e senha do garcom para alterar a configuracao.',
            tone: 'warning'
          });
          return;
        }

        openApiRecoverySettings();
        return;
      }

      await api.login(settingsAuthLogin, settingsAuthPassword);
      setSettingsForm(toSettingsForm(settings));
      setSettingsAccessMode('waiter');
      setStartupConnectionIssue(false);
      setBanner('Configuracao liberada para o garcom.');
      setMode('setup');
    } catch (error) {
      const recoveryMessage =
        recoveryAuthMode
          ? 'Sem resposta da API. Para trocar o IP do servidor, informe o usuario ADM e a senha emergencial autorizada.'
          : getCredentialFailureMessage(error, 'Nao foi possivel autorizar a configuracao.');

      showAppDialog({
        title: recoveryAuthMode ? 'Acesso emergencial negado' : 'Acesso negado',
        message: recoveryMessage,
        tone: 'danger'
      });
    } finally {
      setSettingsAuthLogin('');
      setSettingsAuthPassword('');
      setBusyLabel('');
    }
  };

  const syncCurrentMenu = useCallback(
    async ({
      loadingLabel = 'Sincronizando mesa e cardapio...',
      showErrorAlert = false,
      force = false
    }: {
      loadingLabel?: string;
      showErrorAlert?: boolean;
      force?: boolean;
    } = {}) => {
      if (syncingRef.current) return;

      if (!session) {
        await lockTablet(CUSTOMER_LOCK_MESSAGE);
        return;
      }

      const now = Date.now();
      if (!force && now - lastSyncAttemptAtRef.current < SMART_SYNC_MIN_INTERVAL_MS) {
        return;
      }

      lastSyncAttemptAtRef.current = now;
      syncingRef.current = true;
      setBusyLabel(loadingLabel);
      try {
        const alive = await verifySession(api, settings, session, false);
        if (!alive) return;
        await loadCatalog();
        mergeDiagnostics({
          lastSyncAt: new Date().toISOString(),
          lastSyncOk: true,
          lastSyncError: undefined
        });
      } catch (error) {
        const message = getFriendlyErrorMessage(error, 'Nao foi possivel sincronizar o cardapio.');
        mergeDiagnostics({
          lastSyncAt: new Date().toISOString(),
          lastSyncOk: false,
          lastSyncError: message
        });
        if (showErrorAlert) {
          showAppDialog({
            title: 'Sincronizacao',
            message,
            tone: 'warning'
          });
        } else {
          setBanner(message);
        }
      } finally {
        syncingRef.current = false;
        setBusyLabel('');
      }
    },
    [api, loadCatalog, lockTablet, mergeDiagnostics, session, settings, showAppDialog, verifySession]
  );

  const refreshCurrentMenu = useCallback(
    async () =>
      syncCurrentMenu({
        loadingLabel: 'Atualizando mesa e cardapio...',
        showErrorAlert: true,
        force: true
      }),
    [syncCurrentMenu]
  );

  useEffect(() => {
    const subscription = AppState.addEventListener('change', (nextState) => {
      const previousState = appStateRef.current;
      appStateRef.current = nextState;

      if (
        nextState === 'active' &&
        (previousState === 'inactive' || previousState === 'background') &&
        session &&
        (mode === 'menu' || mode === 'cart')
      ) {
        void syncCurrentMenu();
      }
    });

    return () => subscription.remove();
  }, [mode, session, syncCurrentMenu]);

  const authorizeTable = async () => {
    if (!login.trim() || !password.trim()) {
      showAppDialog({
        title: 'Credenciais obrigatorias',
        message: 'Informe usuario e senha do garcom para liberar a mesa.',
        tone: 'warning'
      });
      return;
    }

    setBusyLabel('Liberando mesa...');
    try {
      const moduleEnabled = await syncCompanyStatus(api, settings, { lockWhenDisabled: true });
      if (!moduleEnabled) return;

      const user = await api.login(login, password);
      const tables = await api.listTables();
      const table = findTableByNumber(tables, settings.mesaNumero);
      if (!table) {
        throw new Error(`Mesa ${settings.mesaNumero} nao encontrada na API.`);
      }

      let openedTable = table;
      const currentSaleId = Number(table.idVenda || table.venda?.idVenda || 0);
      if (currentSaleId > 0) {
        if (!isTableOpenForTablet(table)) {
          throw new Error('Esta mesa nao esta disponivel para pedidos no tablet.');
        }
      } else {
        openedTable = await api.openTable(
          table.idMesa || settings.mesaNumero,
          settings.terminalName,
          user.idUsuario,
          `Mesa ${settings.mesaNumero}`
        );
      }

      if (!isTableOpenForTablet(openedTable)) {
        throw new Error('A mesa foi aberta, mas nao ficou disponivel para pedidos.');
      }

      const nextSession = buildSession(openedTable, settings, user);
      await saveTabletSession(nextSession);
      setSession(nextSession);
      setActiveTable(openedTable);
      setCart([]);
      setBanner('');
      await loadCatalog();
      setMode('menu');
    } catch (error) {
      showAppDialog({
        title: 'Liberacao negada',
        message: getCredentialFailureMessage(error, 'Nao foi possivel liberar a mesa.'),
        tone: 'danger'
      });
    } finally {
      setLogin('');
      setPassword('');
      setBusyLabel('');
    }
  };

  const clearFractionOptionalQuantities = (index: number) => {
    setSelectedFractionOptionalQty((current) => {
      if (!current[index]) return current;
      const next = { ...current };
      delete next[index];
      return next;
    });
  };

  const loadFractionProductDetail = (index: number, flavor: MenuItem) => {
    const requestToken = ++fractionDetailRequestCounterRef.current;
    fractionDetailRequestByIndexRef.current[index] = requestToken;
    const catalogOptionals = getVisibleProductOptionals(flavor);

    setSelectedFractionDetails((current) => ({
      ...current,
      [index]: { ...flavor, opcionais: catalogOptionals }
    }));

    void api
      .getProduct(flavor.idProduto, false)
      .then((detail) => {
        if (fractionDetailRequestByIndexRef.current[index] !== requestToken || !detail) return;
        const detailOptionals = getVisibleProductOptionals(detail);

        setSelectedFractionDetails((current) => {
          if (current[index]?.idProduto !== flavor.idProduto) return current;
          return {
            ...current,
            [index]: {
              ...flavor,
              ...detail,
              imagem: detail.imagem || flavor.imagem,
              opcionais: detailOptionals.length > 0 ? detailOptionals : catalogOptionals
            }
          };
        });
      })
      .catch(() => undefined);
  };

  const openProduct = (product: MenuItem) => {
    const requestSeq = ++productDetailRequestSeqRef.current;
    const catalogOptionals = getVisibleProductOptionals(product);
    fractionDetailRequestByIndexRef.current = {};
    if (productLaunchArmTimerRef.current) {
      clearTimeout(productLaunchArmTimerRef.current);
      productLaunchArmTimerRef.current = null;
    }

    setProductLaunchReady(false);
    setSelectedProduct({ ...product, opcionais: catalogOptionals });
    setSelectedSize(getDefaultSizeCode(product));
    setSelectedQuantity(1);
    setSelectedObservation('');
    setSelectedOptionalQty({});
    setSelectedFractionCount(DEFAULT_FRACTION_FLAVOR_COUNT);
    setSelectedFractionIds(product.permiteFracao ? [product.idProduto] : []);
    setSelectedFractionDetails(
      product.permiteFracao ? { 0: { ...product, opcionais: catalogOptionals } } : {}
    );
    setSelectedFractionOptionalQty({});
    productLaunchArmTimerRef.current = setTimeout(() => {
      productLaunchArmTimerRef.current = null;
      setProductLaunchReady(true);
    }, PRODUCT_LAUNCH_ARM_DELAY_MS);

    void api
      .getProduct(product.idProduto, false)
      .then((detail) => {
        if (requestSeq !== productDetailRequestSeqRef.current || !detail) return;
        const detailOptionals = getVisibleProductOptionals(detail);

        setSelectedProduct((current) => {
          if (!current || current.idProduto !== product.idProduto) return current;
          return {
            ...product,
            ...detail,
            imagem: detail.imagem || product.imagem,
            opcionais: detailOptionals.length > 0 ? detailOptionals : catalogOptionals
          };
        });

        if (product.permiteFracao) {
          setSelectedFractionDetails((current) => {
            if (current[0]?.idProduto !== product.idProduto) return current;
            return {
              ...current,
              0: {
                ...product,
                ...detail,
                imagem: detail.imagem || product.imagem,
                opcionais: detailOptionals.length > 0 ? detailOptionals : catalogOptionals
              }
            };
          });
        }
      })
      .catch(() => undefined);
  };

  const closeProduct = () => {
    productDetailRequestSeqRef.current += 1;
    fractionDetailRequestByIndexRef.current = {};
    if (productLaunchArmTimerRef.current) {
      clearTimeout(productLaunchArmTimerRef.current);
      productLaunchArmTimerRef.current = null;
    }

    setProductLaunchReady(false);
    setSelectedProduct(null);
    setSelectedOptionalQty({});
    setSelectedObservation('');
    setSelectedFractionIds([]);
    setSelectedFractionDetails({});
    setSelectedFractionOptionalQty({});
    setSelectedFractionCount(DEFAULT_FRACTION_FLAVOR_COUNT);
  };

  const changeQuantity = (delta: number) => {
    if (!selectedProduct) return;
    const step = selectedProduct.usaQuantidadeDecimal && !selectedProduct.permiteFracao ? 0.1 : 1;
    setSelectedQuantity((current) => {
      const next = Math.max(step, Number(current || step) + delta * step);
      return selectedProduct.usaQuantidadeDecimal && !selectedProduct.permiteFracao
        ? Number(next.toFixed(3))
        : Math.max(1, Math.round(next));
    });
  };

  const changeOptionalQuantity = (idOpcional: number, delta: number) => {
    setSelectedOptionalQty((current) => {
      const next = Math.max(0, Math.trunc(Number(current[idOpcional] || 0)) + delta);
      if (next <= 0) {
        const copy = { ...current };
        delete copy[idOpcional];
        return copy;
      }
      return {
        ...current,
        [idOpcional]: next
      };
    });
  };

  const changeFractionOptionalQuantity = (index: number, idOpcional: number, delta: number) => {
    setSelectedFractionOptionalQty((current) => {
      const currentQuantities = current[index] || {};
      const nextQuantity = Math.max(0, Math.trunc(Number(currentQuantities[idOpcional] || 0)) + delta);
      const nextQuantities = { ...currentQuantities };

      if (nextQuantity <= 0) {
        delete nextQuantities[idOpcional];
      } else {
        nextQuantities[idOpcional] = nextQuantity;
      }

      const next = { ...current };
      if (Object.keys(nextQuantities).length > 0) {
        next[index] = nextQuantities;
      } else {
        delete next[index];
      }
      return next;
    });
  };

  const changeFractionCount = (count: number) => {
    const normalized = Math.max(1, Math.min(4, Math.trunc(count)));
    setSelectedFractionCount(normalized);
    Object.keys(fractionDetailRequestByIndexRef.current).forEach((indexKey) => {
      const index = Number(indexKey);
      if (index >= normalized) {
        delete fractionDetailRequestByIndexRef.current[index];
      }
    });
    setSelectedFractionDetails((current) =>
      Object.fromEntries(
        Object.entries(current).filter(([indexKey]) => Number(indexKey) < normalized)
      ) as Record<number, MenuItem>
    );
    setSelectedFractionOptionalQty((current) =>
      Object.fromEntries(
        Object.entries(current).filter(([indexKey]) => Number(indexKey) < normalized)
      ) as Record<number, Record<number, number>>
    );
    setSelectedFractionIds((current) => {
      const next = current.slice(0, normalized);
      while (next.length < normalized) {
        next.push(null);
      }
      if (next.length > 0 && !next[0] && selectedProduct?.idProduto) {
        next[0] = selectedProduct.idProduto;
      }
      return next;
    });
  };

  const selectFractionFlavor = (index: number, idProduto: number) => {
    if (selectedFractionIds[index] === idProduto) return;
    const flavor = fractionFlavorOptions.find((product) => product.idProduto === idProduto);
    if (!flavor) return;

    clearFractionOptionalQuantities(index);
    loadFractionProductDetail(index, flavor);
    setSelectedFractionIds((current) => {
      const next = current.slice(0, selectedFractionCount);
      while (next.length < selectedFractionCount) {
        next.push(null);
      }
      next[index] = idProduto;
      return next;
    });
  };

  const addSelectedProductToCart = () => {
    if (!productLaunchReady) return;

    if (!session || !selectedProduct) {
      void lockTablet(CUSTOMER_LOCK_MESSAGE);
      return;
    }

    const unitValue = getProductUnitPrice(selectedProduct, selectedSize);
    const label = getProductSizeLabel(selectedProduct, selectedSize);
    const lineId = buildLineId(session);

    if (selectedProduct.permiteFracao) {
      const flavors = selectedFractionProducts.filter((product): product is MenuItem => Boolean(product));
      if (!selectedFractionReady || flavors.length !== selectedFractionCount) {
        showAppDialog({
          title: 'Sabores pendentes',
          message: 'Selecione todos os sabores do produto fracionado sem repetir.',
          tone: 'warning'
        });
        return;
      }

      const orderCount = Math.max(1, Math.round(selectedQuantity));
      const fractionQuantity = Number((1 / selectedFractionCount).toFixed(3));
      const flavorPrices = flavors.map((product) => getProductUnitPrice(product, selectedSize));
      const maxUnitPrice = Math.max(...flavorPrices);
      const averageUnitPrice = roundMoney(
        flavorPrices.reduce((total, price) => total + price * fractionQuantity, 0)
      );
      const parentUnitPrice = settings.cobrarMaiorValorFracionado ? maxUnitPrice : averageUnitPrice;
      const nextItems: CartItem[] = Array.from({ length: orderCount }, (_, orderIndex) => {
        const itemLineId = buildLineId(session, orderCount > 1 ? `P${orderIndex + 1}` : '');
        const fracoes: LaunchItemFractionPayload[] = flavors.map((flavor, flavorIndex) => {
          const flavorUnitPrice = settings.cobrarMaiorValorFracionado
            ? maxUnitPrice
            : getProductUnitPrice(flavor, selectedSize);
          const fractionLaunchId = `${itemLineId}:F${flavorIndex + 1}`;
          const fractionOptionals = selectedFractionLaunchOptionalsByIndex[flavorIndex] || [];
          const fractionAddition = roundMoney(getOptionalsAddition(fractionOptionals, fractionQuantity));
          return {
            mobileLaunchId: fractionLaunchId,
            MobileLaunchId: fractionLaunchId,
            idProduto: flavor.idProduto,
            produtoDescricao: flavor.descricao,
            quantidade: fractionQuantity,
            valorUnitario: flavorUnitPrice,
            valorTotal: roundMoney(flavorUnitPrice * fractionQuantity),
            acrescimo: fractionAddition,
            observacao: selectedObservation.trim() || undefined,
            descricaoTamanho: `${label} (${flavorIndex + 1}/${selectedFractionCount})`,
            opcionais: fractionOptionals
          };
        });

        return {
          lineId: itemLineId,
          product: selectedProduct,
          quantidade: 1,
          valorUnitario: parentUnitPrice,
          tamanho: selectedSize,
          descricaoTamanho: `${label} - ${formatFractionFlavorCount(selectedFractionCount)}`,
          observacao: selectedObservation.trim() || undefined,
          opcionais: [],
          fracoes
        };
      });

      setCart((current) => [...current, ...nextItems]);
      closeProduct();
      return;
    }

    const item: CartItem = {
      lineId,
      product: selectedProduct,
      quantidade: selectedQuantity,
      valorUnitario: unitValue,
      tamanho: selectedSize,
      descricaoTamanho: label,
      observacao: selectedObservation.trim() || undefined,
      opcionais: selectedOptionals
    };

    setCart((current) => [...current, item]);
    closeProduct();
  };

  const removeCartItem = (lineId: string) => {
    setCart((current) => current.filter((item) => item.lineId !== lineId));
  };

  const sendCart = async () => {
    if (sendingCart) return;

    if (!session) {
      await lockTablet(CUSTOMER_LOCK_MESSAGE);
      return;
    }

    if (cart.length === 0) {
      showAppDialog({
        title: 'Carrinho vazio',
        message: 'Adicione ao menos um item antes de enviar.',
        tone: 'info'
      });
      return;
    }

    setSendingCart(true);
    setBusyLabel('Enviando pedido...');
    try {
      const alive = await verifySession(api, settings, session, false);
      if (!alive) return;

      const payload = cart.map((item) =>
        buildLaunchPayload(item, session.idMesa, session.waiterId, session.terminalName)
      );
      await api.launchItemsBatch(session.idVenda, payload);
      const nextPendingOrders = await removePendingOrder(buildPendingOrderQueueId(session, cart));
      setPendingOrders(nextPendingOrders);
      mergeDiagnostics({
        lastSendAt: new Date().toISOString(),
        lastSendOk: true,
        lastSendError: undefined,
        pendingOrderCount: nextPendingOrders.length
      });
      setCart([]);
      setMode('menu');
      setBanner('Pedido enviado para a cozinha.');
      await verifySession(api, settings, session, true);
    } catch (error) {
      if (isNetworkRequestError(error)) {
        const queueId = buildPendingOrderQueueId(session, cart);
        const nextPendingOrders = await enqueuePendingOrder({
          queueId,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          attempts: 0,
          lastError: NETWORK_SEND_FAILURE_MESSAGE,
          session,
          settings,
          items: cart,
          total: cartTotal
        });
        setPendingOrders(nextPendingOrders);
        mergeDiagnostics({
          lastSendAt: new Date().toISOString(),
          lastSendOk: false,
          lastSendError: NETWORK_SEND_FAILURE_MESSAGE,
          pendingOrderCount: nextPendingOrders.length
        });
        setBanner(NETWORK_SEND_FAILURE_MESSAGE);
        setNetworkFailureVisible(true);
      } else {
        const message = getFriendlyErrorMessage(error, 'Nao foi possivel enviar o pedido.');
        mergeDiagnostics({
          lastSendAt: new Date().toISOString(),
          lastSendOk: false,
          lastSendError: message
        });
        showAppDialog({
          title: 'Erro no envio',
          message,
          tone: 'danger'
        });
      }
    } finally {
      setSendingCart(false);
      setBusyLabel('');
    }
  };

  const closeNetworkFailure = () => {
    setNetworkFailureVisible(false);
    setBanner((current) => (current === NETWORK_SEND_FAILURE_MESSAGE ? '' : current));
  };

  const retryPendingOrderQueue = async () => {
    if (retryingPendingOrders) return;

    const orders = await refreshPendingOrders();
    if (orders.length === 0) {
      setBanner('Nao ha pedidos pendentes para reenviar.');
      return;
    }

    setRetryingPendingOrders(true);
    setBusyLabel('Reenviando pedidos pendentes...');
    let sentCount = 0;
    let failedCount = 0;
    let lastError = '';

    try {
      for (const order of orders) {
        try {
          const client = new TabletApi(order.settings.baseUrl, order.settings.empresaId);
          const moduleEnabled = await syncCompanyStatus(client, order.settings, {
            persist: false,
            lockWhenDisabled: false,
            silent: true
          });
          if (!moduleEnabled) {
            throw new Error(MODULE_DISABLED_MESSAGE);
          }

          const sale = await client.getSale(order.session.idVenda, false);
          if (sale?.situacao && !isSaleStatusOpenForTablet(sale.situacao)) {
            throw new Error('A venda desta pendencia nao esta mais aberta.');
          }

          const payload = order.items.map((item) =>
            buildLaunchPayload(item, order.session.idMesa, order.session.waiterId, order.session.terminalName)
          );
          await client.launchItemsBatch(order.session.idVenda, payload);
          await removePendingOrder(order.queueId);
          sentCount += 1;
        } catch (error) {
          failedCount += 1;
          lastError = getFriendlyErrorMessage(error, 'Nao foi possivel reenviar uma pendencia.');
          await updatePendingOrder(order.queueId, {
            attempts: order.attempts + 1,
            lastError
          });
        }
      }

      const nextPendingOrders = await refreshPendingOrders();
      mergeDiagnostics({
        lastSendAt: new Date().toISOString(),
        lastSendOk: failedCount === 0,
        lastSendError: failedCount > 0 ? lastError : undefined,
        pendingOrderCount: nextPendingOrders.length
      });

      if (failedCount > 0) {
        showAppDialog({
          title: 'Pendencias do pedido',
          message: `${sentCount} reenviado(s). ${failedCount} ainda pendente(s). ${lastError}`,
          tone: 'warning'
        });
      } else {
        setBanner(`${sentCount} pedido(s) pendente(s) reenviado(s).`);
      }
    } finally {
      setRetryingPendingOrders(false);
      setBusyLabel('');
    }
  };

  const openOrderPreview = async () => {
    if (!session) {
      await lockTablet(CUSTOMER_LOCK_MESSAGE);
      return;
    }

    setOrderPreviewVisible(true);
    setOrderPreviewLoading(true);
    try {
      const alive = await verifySession(api, settings, session, false);
      if (!alive) {
        setOrderPreviewVisible(false);
        return;
      }

      const sale = await api.getSale(session.idVenda, true);
      if (!sale) {
        throw new Error('Nao foi possivel carregar os itens do pedido.');
      }

      setOrderPreviewSale(sale);
      setActiveTable((current) =>
        current
          ? {
              ...current,
              valorTotal: sale.valorTotal ?? sale.valor ?? current.valorTotal,
              situacao: sale.situacao || current.situacao,
              venda: current.venda
                ? {
                    ...current.venda,
                    valorTotal: sale.valorTotal ?? sale.valor ?? current.venda.valorTotal,
                    situacao: sale.situacao || current.venda.situacao
                  }
                : current.venda
            }
          : current
      );
    } catch (error) {
      const message = getFriendlyErrorMessage(error, 'Nao foi possivel carregar o pedido.');
      showAppDialog({
        title: 'Visualizar pedido',
        message,
        tone: 'warning'
      });
    } finally {
      setOrderPreviewLoading(false);
    }
  };

  const closeOrderPreview = () => {
    setOrderPreviewVisible(false);
  };

  const renderBusyOverlay = () => {
    if (!busyLabel) return null;
    return (
      <View style={styles.busyOverlay}>
        <View style={styles.busyBox}>
          <ActivityIndicator size="large" color={colors.primary} />
          <Text style={styles.busyText}>{busyLabel}</Text>
        </View>
      </View>
    );
  };

  const renderBanner = () => {
    if (!banner || (mode === 'loading' && startupConnectionIssue)) return null;
    return (
      <Pressable style={styles.banner} onPress={() => setBanner('')}>
        <Text style={styles.bannerText}>{banner}</Text>
      </Pressable>
    );
  };

  const renderLoading = () => {
    const showConnectionActions = settings.configured && startupConnectionIssue;

    return (
      <View style={styles.centerScreen}>
        <View style={[styles.loadingCard, showConnectionActions && styles.loadingCardIssue]}>
          <View style={styles.loadingBadge}>
            <Text style={styles.loadingBadgeText}>{showConnectionActions ? 'REDE' : 'API'}</Text>
          </View>

          {showConnectionActions ? (
            <View style={styles.loadingAlertIcon}>
              <Text style={styles.loadingAlertIconText}>!</Text>
            </View>
          ) : (
            <ActivityIndicator size="large" color={colors.primary} />
          )}

          <View style={styles.loadingTextBlock}>
            <Text style={styles.centerTitle}>
              {showConnectionActions ? 'Servidor sem resposta' : 'Carregando cardapio tablet'}
            </Text>
            <Text style={styles.loadingDescription}>
              {showConnectionActions
                ? 'Verifique se o tablet esta na rede correta ou acesse a configuracao para ajustar o IP do servidor.'
                : 'Sincronizando mesa, modulo e cardapio deste tablet.'}
            </Text>
          </View>

          {showConnectionActions ? (
            <View style={styles.loadingActions}>
              <ActionButton label="Tentar novamente" variant="secondary" onPress={() => retryStartupConnection(true)} />
              <ActionButton label="Configurar API" variant="config" onPress={() => openSettingsAuth('loading')} />
            </View>
          ) : null}
        </View>
        <AppFooter />
      </View>
    );
  };

  const renderEmptyState = (title: string, description: string) => (
    <View style={styles.emptyState}>
      <View style={styles.emptyStateIcon}>
        <Text style={styles.emptyStateIconText}>RP</Text>
      </View>
      <Text style={styles.emptyStateTitle}>{title}</Text>
      <Text style={styles.emptyStateText}>{description}</Text>
    </View>
  );

  const renderNetworkFailureModal = () => (
    <Modal visible={networkFailureVisible} transparent animationType="fade" onRequestClose={closeNetworkFailure}>
      <View style={styles.noticeBackdrop}>
        <View style={styles.noticeCard}>
          <View style={styles.noticeBadge}>
            <Text style={styles.noticeBadgeText}>!</Text>
          </View>
          <Text style={styles.noticeTitle}>{NETWORK_SEND_FAILURE_TITLE}</Text>
          <Text style={styles.noticeText}>{NETWORK_SEND_FAILURE_MESSAGE}</Text>
          <View style={styles.noticeActions}>
            <ActionButton label="Entendi" onPress={closeNetworkFailure} />
          </View>
        </View>
      </View>
    </Modal>
  );

  const renderAppDialog = () => {
    if (!appDialog) return null;

    const tone = appDialog.tone || 'info';
    const hasSecondaryAction = Boolean(appDialog.secondaryLabel);

    return (
      <Modal visible transparent animationType="fade" onRequestClose={closeAppDialog}>
        <View style={styles.dialogBackdrop}>
          <View style={styles.dialogCard}>
            <View style={styles.dialogTopLine} />
            <View style={styles.dialogHeader}>
              <View
                style={[
                  styles.dialogIcon,
                  tone === 'danger' && styles.dialogIconDanger,
                  tone === 'warning' && styles.dialogIconWarning,
                  tone === 'success' && styles.dialogIconSuccess
                ]}
              >
                <Text
                  style={[
                    styles.dialogIconText,
                    tone === 'danger' && styles.dialogIconTextDanger,
                    tone === 'warning' && styles.dialogIconTextWarning,
                    tone === 'success' && styles.dialogIconTextSuccess
                  ]}
                >
                  {tone === 'success' ? 'OK' : tone === 'info' ? 'i' : '!'}
                </Text>
              </View>
              <View style={styles.dialogTitleBox}>
                <Text style={styles.dialogEyebrow}>Cardapio Tablet</Text>
                <Text style={styles.dialogTitle}>{appDialog.title}</Text>
              </View>
            </View>

            <Text style={styles.dialogMessage}>{appDialog.message}</Text>

            <View style={styles.dialogActions}>
              {hasSecondaryAction ? (
                <ActionButton
                  label={appDialog.secondaryLabel || 'Cancelar'}
                  variant="secondary"
                  compact
                  onPress={cancelAppDialog}
                />
              ) : null}
              <ActionButton
                label={appDialog.primaryLabel || 'Entendi'}
                variant={hasSecondaryAction && tone === 'danger' ? 'danger' : 'primary'}
                compact
                onPress={confirmAppDialog}
              />
            </View>
          </View>
        </View>
      </Modal>
    );
  };

  const renderSetup = () => {
    const kioskPresentation = getKioskStatusPresentation(kioskStatus, checkingKioskStatus);
    const emergencyApiAccess = settingsAccessMode === 'emergencyApi';

    return (
      <KeyboardAvoidingView style={[styles.screen, styles.setupScreen]}>
        <View style={styles.setupShell}>
          <View style={styles.setupSidebar}>
            <ScrollView
              style={styles.setupSidebarScroll}
              contentContainerStyle={styles.setupSidebarContent}
              showsVerticalScrollIndicator={false}
            >
              <View>
                <Text style={styles.setupEyebrow}>Cardapio Tablet</Text>
                <Text style={styles.setupHeroTitle}>{emergencyApiAccess ? 'API' : 'Configuracao'}</Text>
                <Text style={styles.setupHeroText}>Mesa {formatMesa(Number(settingsForm.mesaNumero || settings.mesaNumero))}</Text>
              </View>
              <View style={styles.setupSummary}>
                <View style={styles.setupSummaryItem}>
                  <Text style={styles.setupSummaryLabel}>Empresa</Text>
                  <Text style={styles.setupSummaryValue}>{settingsForm.empresaId || '-'}</Text>
                </View>
                <View style={styles.setupSummaryItem}>
                  <Text style={styles.setupSummaryLabel}>Terminal</Text>
                  <Text style={styles.setupSummaryValue} numberOfLines={1}>{settingsForm.terminalName || '-'}</Text>
                </View>
              </View>
            </ScrollView>
          </View>

          <View style={styles.setupPanel}>
            <ScrollView
              style={styles.setupScroll}
              contentContainerStyle={styles.setupScrollContent}
              keyboardShouldPersistTaps="handled"
              showsVerticalScrollIndicator
            >
              <View style={styles.setupHeader}>
                <View>
                  <Text style={styles.setupTitle}>{emergencyApiAccess ? 'Configuracao da API' : 'Configuracao do tablet'}</Text>
                  <Text style={styles.setupSubtitle}>
                    {emergencyApiAccess
                      ? 'Ajuste somente o endereco do servidor para recuperar a comunicacao.'
                      : 'Defina a API e a mesa fixa deste dispositivo.'}
                  </Text>
                </View>
                <View style={styles.setupMesaBadge}>
                  <Text style={styles.setupMesaBadgeLabel}>Mesa</Text>
                  <Text style={styles.setupMesaBadgeValue}>{formatMesa(Number(settingsForm.mesaNumero || settings.mesaNumero))}</Text>
                </View>
              </View>

              <View style={styles.setupFieldCard}>
                <LabeledInput
                  label="Servidor API"
                  placeholder="https://servidor:porta"
                  value={settingsForm.baseUrl}
                  onChangeText={(value) => setSettingsForm((current) => ({ ...current, baseUrl: value }))}
                  autoCapitalize="none"
                />
                {emergencyApiAccess ? (
                  <View style={styles.emergencyApiNotice}>
                    <Text style={styles.emergencyApiNoticeText}>
                      Acesso emergencial liberado somente porque a API atual nao comunicou. Empresa, mesa e terminal permanecem travados.
                    </Text>
                  </View>
                ) : null}
                <View style={styles.setupGrid}>
                  <LabeledInput
                    label="Empresa"
                    containerStyle={styles.inputGroupGrid}
                    value={settingsForm.empresaId}
                    onChangeText={(value) => setSettingsForm((current) => ({ ...current, empresaId: value }))}
                    keyboardType="numeric"
                    editable={!emergencyApiAccess}
                  />
                  <LabeledInput
                    label="Mesa"
                    containerStyle={styles.inputGroupGrid}
                    value={settingsForm.mesaNumero}
                    onChangeText={(value) => setSettingsForm((current) => ({ ...current, mesaNumero: value }))}
                    keyboardType="numeric"
                    editable={!emergencyApiAccess}
                  />
                </View>
                <LabeledInput
                  label="Terminal"
                  value={settingsForm.terminalName}
                  onChangeText={(value) => setSettingsForm((current) => ({ ...current, terminalName: value }))}
                  autoCapitalize="characters"
                  editable={!emergencyApiAccess}
                />
                <ToggleRow
                  label="Cobrar maior valor no fracionado"
                  value={settingsForm.cobrarMaiorValorFracionado}
                  onValueChange={(value) => setSettingsForm((current) => ({ ...current, cobrarMaiorValorFracionado: value }))}
                  disabled={emergencyApiAccess}
                />
              </View>

              {settings.configured ? (
              <View style={styles.setupDiagnosticsCard}>
                <View style={styles.diagnosticsHeader}>
                  <View>
                    <Text style={styles.diagnosticsTitle}>Diagnostico do tablet</Text>
                    <Text style={styles.diagnosticsSubtitle}>Rede, sincronizacao e pedidos pendentes.</Text>
                  </View>
                  <View style={[styles.diagnosticsCountBadge, pendingOrders.length > 0 && styles.diagnosticsCountBadgeWarning]}>
                    <Text style={[styles.diagnosticsCountValue, pendingOrders.length > 0 && styles.diagnosticsCountValueWarning]}>
                      {pendingOrders.length}
                    </Text>
                    <Text style={styles.diagnosticsCountLabel}>pend.</Text>
                  </View>
                </View>

                <View
                  style={[
                    styles.kioskStatusCard,
                    kioskPresentation.tone === 'success' && styles.kioskStatusCardSuccess,
                    kioskPresentation.tone === 'warning' && styles.kioskStatusCardWarning,
                    kioskPresentation.tone === 'danger' && styles.kioskStatusCardDanger
                  ]}
                >
                  <View
                    style={[
                      styles.kioskStatusBadge,
                      kioskPresentation.tone === 'success' && styles.kioskStatusBadgeSuccess,
                      kioskPresentation.tone === 'warning' && styles.kioskStatusBadgeWarning,
                      kioskPresentation.tone === 'danger' && styles.kioskStatusBadgeDanger
                    ]}
                  >
                    <Text
                      style={[
                        styles.kioskStatusBadgeText,
                        kioskPresentation.tone === 'success' && styles.kioskStatusBadgeTextSuccess,
                        kioskPresentation.tone === 'warning' && styles.kioskStatusBadgeTextWarning,
                        kioskPresentation.tone === 'danger' && styles.kioskStatusBadgeTextDanger
                      ]}
                    >
                      {kioskPresentation.badge}
                    </Text>
                  </View>
                  <View style={styles.kioskStatusContent}>
                    <Text style={styles.kioskStatusLabel}>Modo Kiosk Seguro</Text>
                    <Text style={styles.kioskStatusTitle}>{kioskPresentation.title}</Text>
                    <Text style={styles.kioskStatusText}>{kioskPresentation.message}</Text>
                  </View>
                  <ActionButton
                    label={checkingKioskStatus ? 'Verificando' : 'Verificar'}
                    variant="secondary"
                    compact
                    onPress={refreshKioskStatus}
                    disabled={checkingKioskStatus}
                  />
                </View>

                <View style={styles.diagnosticsGrid}>
                  <DiagnosticItem
                    label="Modulo"
                    value={`${settings.utilizaCardapioTablet || diagnostics.utilizaCardapioTablet ? 'OK' : diagnostics.lastModuleCheckAt ? 'Bloqueado' : 'Sem leitura'} - ${formatDateTime(diagnostics.lastModuleCheckAt)}`}
                    tone={settings.utilizaCardapioTablet || diagnostics.utilizaCardapioTablet ? 'success' : diagnostics.lastModuleCheckAt ? 'danger' : 'neutral'}
                  />
                  <DiagnosticItem
                    label="Sincronizacao"
                    value={`${getOkLabel(diagnostics.lastSyncOk)} - ${formatDateTime(diagnostics.lastSyncAt)}`}
                    tone={diagnostics.lastSyncOk === false ? 'danger' : diagnostics.lastSyncOk === true ? 'success' : 'neutral'}
                  />
                  <DiagnosticItem
                    label="Catalogo"
                    value={`${diagnostics.lastCatalogSource === 'api' ? 'API' : 'Sem leitura'} - ${formatDateTime(diagnostics.lastCatalogAt)}`}
                    tone={diagnostics.lastCatalogAt ? 'success' : 'neutral'}
                  />
                  <DiagnosticItem
                    label="Ping API"
                    value={`${getOkLabel(diagnostics.lastPingOk)}${diagnostics.lastPingMs ? ` - ${diagnostics.lastPingMs}ms` : ''}`}
                    tone={diagnostics.lastPingOk === false ? 'danger' : diagnostics.lastPingOk === true ? 'success' : 'neutral'}
                  />
                  <DiagnosticItem
                    label="Ultimo envio"
                    value={`${getOkLabel(diagnostics.lastSendOk)} - ${formatDateTime(diagnostics.lastSendAt)}`}
                    tone={diagnostics.lastSendOk === false ? 'danger' : diagnostics.lastSendOk === true ? 'success' : 'neutral'}
                  />
                </View>

                {pendingOrders.length > 0 ? (
                  <View style={styles.pendingOrderList}>
                    <View style={styles.pendingOrderListHeader}>
                      <Text style={styles.pendingOrderListTitle}>Fila offline</Text>
                      <Text style={styles.pendingOrderListMeta}>{pendingOrders.length} pendente(s)</Text>
                    </View>
                    {pendingOrders.slice(0, 3).map((order) => {
                      const pendingPresentation = getPendingOrderPresentation(order);
                      return (
                        <View style={styles.pendingOrderRow} key={order.queueId}>
                          <View
                            style={[
                              styles.pendingOrderDot,
                              pendingPresentation.tone === 'warning' && styles.pendingOrderDotWarning,
                              pendingPresentation.tone === 'danger' && styles.pendingOrderDotDanger
                            ]}
                          />
                          <View style={styles.pendingOrderTextBox}>
                            <Text style={styles.pendingOrderTitle} numberOfLines={1}>{formatPendingOrderTitle(order)}</Text>
                            <Text style={styles.pendingOrderMeta} numberOfLines={1}>
                              {pendingPresentation.label} - {formatMoney(order.total)} - {formatItemCount(order.items.length)} - {formatDateTime(order.updatedAt)}
                            </Text>
                            {order.lastError ? (
                              <Text style={styles.pendingOrderError} numberOfLines={1}>{order.lastError}</Text>
                            ) : null}
                          </View>
                        </View>
                      );
                    })}
                    {pendingOrders.length > 3 ? (
                      <Text style={styles.pendingOrderMore}>+{pendingOrders.length - 3} pendencia(s) na fila offline.</Text>
                    ) : null}
                  </View>
                ) : null}

                <View style={styles.diagnosticsFooter}>
                  <Text style={styles.diagnosticsLastError} numberOfLines={2}>
                    {pendingOrders[0]?.lastError || diagnostics.lastSendError || diagnostics.lastSyncError || 'Nenhuma falha registrada.'}
                  </Text>
                  <View style={styles.diagnosticsActions}>
                    <ActionButton
                      label="Exportar diagnostico"
                      variant="secondary"
                      compact
                      onPress={shareTabletDiagnostics}
                    />
                    <ActionButton
                      label="Reenviar pendencias"
                      variant="order"
                      compact
                      onPress={retryPendingOrderQueue}
                      disabled={pendingOrders.length === 0 || retryingPendingOrders}
                    />
                  </View>
                </View>
              </View>
              ) : null}

              <View style={styles.actionsRow}>
                {settings.configured && settingsAccessMode === 'waiter' ? (
                  <ActionButton label="Fechar APP" variant="danger" onPress={closeAuthorizedApp} />
                ) : null}
                {settings.configured ? <ActionButton label="Voltar" variant="secondary" onPress={cancelSettingsChange} /> : null}
                <ActionButton label="Testar API" variant="secondary" onPress={testConnection} />
                <ActionButton label="Salvar" onPress={saveSettings} />
              </View>
              <AppFooter />
            </ScrollView>
          </View>
        </View>
      </KeyboardAvoidingView>
    );
  };

  const renderLocked = () => (
    <View style={styles.lockedScreen}>
      <View style={styles.lockedHeader}>
        <Text style={styles.brand}>{APP_DISPLAY_BRAND}</Text>
        <Text style={styles.lockedMesa}>Mesa {formatMesa(settings.mesaNumero)}</Text>
      </View>

      <View style={styles.lockedPanel}>
        <Text style={styles.lockedTitle}>Aguardando liberacao</Text>
        <Text style={styles.lockedText}>O garcom deve informar usuario e senha para abrir a mesa.</Text>
        <View style={styles.lockedActions}>
          <ActionButton label="Liberar mesa" onPress={openUnlock} />
          <ActionButton label="Configuracao" variant="secondary" onPress={() => openSettingsAuth('locked')} />
        </View>
      </View>
    </View>
  );

  const renderUnlock = () => (
    <KeyboardAvoidingView style={[styles.screen, styles.authScreen]}>
      <View style={[styles.authShell, styles.unlockShell]}>
        <View style={[styles.authSidebar, styles.unlockSidebar]}>
          <View style={styles.authSidebarTop}>
            <Text style={styles.authSidebarEyebrow}>Atendimento</Text>
            <Text style={styles.authHeroTitle}>Liberar mesa</Text>
            <View style={[styles.authMesaCard, styles.unlockMesaCard]}>
              <Text style={styles.authMesaLabel}>Mesa</Text>
              <Text style={styles.authMesaValue}>{formatMesa(settings.mesaNumero)}</Text>
            </View>
          </View>

          <View style={styles.authSidebarBottom}>
            <View style={[styles.authAccessPanel, styles.unlockAccessPanel]}>
              <Text style={styles.authAccessLabel}>Status</Text>
              <Text style={styles.authAccessText}>Aguardando garcom</Text>
            </View>
            <View style={styles.authSummaryGrid}>
              <View style={styles.authSummaryItem}>
                <Text style={styles.authSummaryLabel}>Empresa</Text>
                <Text style={styles.authSummaryValue}>{settings.empresaId}</Text>
              </View>
              <View style={styles.authSummaryItem}>
                <Text style={styles.authSummaryLabel}>Terminal</Text>
                <Text style={styles.authSummaryValue} numberOfLines={1}>{settings.terminalName}</Text>
              </View>
            </View>
          </View>
        </View>

        <View style={styles.authPanel}>
          <View style={styles.authKickerRow}>
            <View style={[styles.authBadge, styles.unlockBadge]}>
              <Text style={[styles.authBadgeText, styles.unlockBadgeText]}>MESA</Text>
            </View>
            <Text style={styles.authKicker}>Abertura de atendimento</Text>
          </View>

          <View style={styles.authHeaderText}>
            <Text style={styles.authTitle}>Liberar mesa {formatMesa(settings.mesaNumero)}</Text>
            <Text style={styles.authSubtitle}>Credenciais do garcom responsavel pela abertura.</Text>
          </View>

          <View style={styles.authFieldCard}>
            <View style={styles.authFieldHeader}>
              <Text style={styles.authFieldTitle}>Credenciais</Text>
              <Text style={[styles.authFieldMeta, styles.unlockFieldMeta]}>Mesa {formatMesa(settings.mesaNumero)}</Text>
            </View>
            <LabeledInput
              label="Usuario"
              value={login}
              onChangeText={setLogin}
              autoCapitalize="none"
              autoCorrect={false}
              autoComplete="off"
              textContentType="none"
              importantForAutofill="no"
              containerStyle={styles.authInputGroup}
            />
            <LabeledInput
              label="Senha"
              value={password}
              onChangeText={setPassword}
              secureTextEntry
              autoCorrect={false}
              autoComplete="off"
              textContentType="none"
              importantForAutofill="no"
              containerStyle={styles.authInputGroupLast}
            />
          </View>

          <View style={styles.authActionsBar}>
            <Text style={styles.authActionNote}>A mesa sera aberta no terminal deste tablet.</Text>
            <View style={styles.authActionsRow}>
              <ActionButton label="Voltar" variant="secondary" onPress={cancelUnlock} />
              <ActionButton label="Liberar" onPress={authorizeTable} />
            </View>
          </View>
          <AppFooter />
        </View>
      </View>
    </KeyboardAvoidingView>
  );

  const renderSettingsAuth = () => {
    const recoveryAuthMode = isApiRecoveryAuthMode();

    return (
      <KeyboardAvoidingView style={[styles.screen, styles.authScreen]}>
        <View style={styles.authShell}>
          <View style={styles.authSidebar}>
            <View style={styles.authSidebarTop}>
              <Text style={styles.authSidebarEyebrow}>Cardapio Tablet</Text>
              <Text style={styles.authHeroTitle}>Area protegida</Text>
              <View style={styles.authMesaCard}>
                <Text style={styles.authMesaLabel}>Mesa</Text>
                <Text style={styles.authMesaValue}>{formatMesa(settings.mesaNumero)}</Text>
              </View>
            </View>

            <View style={styles.authSidebarBottom}>
              <View style={styles.authAccessPanel}>
                <Text style={styles.authAccessLabel}>Configuracao</Text>
                <Text style={styles.authAccessText}>{recoveryAuthMode ? 'Somente ADM' : 'Somente garcom'}</Text>
              </View>
              <View style={styles.authSummaryGrid}>
                <View style={styles.authSummaryItem}>
                  <Text style={styles.authSummaryLabel}>Empresa</Text>
                  <Text style={styles.authSummaryValue}>{settings.empresaId}</Text>
                </View>
                <View style={styles.authSummaryItem}>
                  <Text style={styles.authSummaryLabel}>Terminal</Text>
                  <Text style={styles.authSummaryValue} numberOfLines={1}>{settings.terminalName}</Text>
                </View>
              </View>
            </View>
          </View>

          <View style={styles.authPanel}>
            <View style={styles.authKickerRow}>
              <View style={styles.authBadge}>
                <Text style={styles.authBadgeText}>ADM</Text>
              </View>
              <Text style={styles.authKicker}>{recoveryAuthMode ? 'Recuperacao da API' : 'Autorizacao do garcom'}</Text>
            </View>

            <View style={styles.authHeaderText}>
              <Text style={styles.authTitle}>
                {recoveryAuthMode ? 'Liberar configuracao da API' : 'Liberar configuracao'}
              </Text>
              <Text style={styles.authSubtitle}>
                {recoveryAuthMode
                  ? 'Acesso local emergencial para trocar o IP quando o servidor nao responde.'
                  : 'Credenciais do garcom responsavel.'}
              </Text>
            </View>

            <View style={styles.authFieldCard}>
              <View style={styles.authFieldHeader}>
                <Text style={styles.authFieldTitle}>{recoveryAuthMode ? 'Acesso emergencial' : 'Identificacao'}</Text>
                <Text style={styles.authFieldMeta}>Mesa {formatMesa(settings.mesaNumero)}</Text>
              </View>
              <LabeledInput
                label="Usuario"
                value={settingsAuthLogin}
                onChangeText={setSettingsAuthLogin}
                autoCapitalize="none"
                autoCorrect={false}
                autoComplete="off"
                textContentType="none"
                importantForAutofill="no"
                containerStyle={styles.authInputGroup}
              />
              <LabeledInput
                label="Senha"
                value={settingsAuthPassword}
                onChangeText={setSettingsAuthPassword}
                secureTextEntry
                autoCorrect={false}
                autoComplete="off"
                textContentType="none"
                importantForAutofill="no"
                containerStyle={styles.authInputGroupLast}
              />
            </View>

            <View style={styles.authActionsBar}>
              <Text style={styles.authActionNote}>
                {recoveryAuthMode
                  ? 'Sem resposta da API. Somente o usuario ADM local pode liberar a troca de IP.'
                  : 'Alteracao restrita ao responsavel pela mesa.'}
              </Text>
              <View style={[styles.authActionsRow, recoveryAuthMode && styles.authActionsRowRecovery]}>
                <ActionButton label="Voltar" variant="secondary" onPress={cancelSettingsAuth} />
                <ActionButton label="Autorizar" onPress={authorizeSettingsChange} />
              </View>
            </View>
            <AppFooter />
          </View>
        </View>
      </KeyboardAvoidingView>
    );
  };

  const renderCategory = ({ item }: { item: Category }) => {
    const selected = selectedCategoryId === item.id;
    const itemCount = categoryProductCounts.get(item.id) || 0;
    return (
      <Pressable
        style={({ pressed }) => [
          styles.categoryButton,
          selected && styles.categoryButtonSelected,
          pressed && styles.categoryButtonPressed
        ]}
        onPress={() => setSelectedCategoryId(item.id)}
        android_ripple={{ color: colors.primarySoft }}
      >
        <View style={[styles.categoryInitial, selected && styles.categoryInitialSelected]}>
          <Text style={[styles.categoryInitialText, selected && styles.categoryInitialTextSelected]}>
            {getCategoryInitial(item.descricao)}
          </Text>
        </View>
        <View style={styles.categoryContent}>
          <Text style={[styles.categoryText, selected && styles.categoryTextSelected]} numberOfLines={2}>
            {item.descricao}
          </Text>
          <Text style={[styles.categoryMeta, selected && styles.categoryMetaSelected]}>{formatItemCount(itemCount)}</Text>
        </View>
        <View style={[styles.categoryCountPill, selected && styles.categoryCountPillSelected]}>
          <Text style={[styles.categoryCountText, selected && styles.categoryCountTextSelected]}>{itemCount}</Text>
        </View>
      </Pressable>
    );
  };

  const renderProduct = ({ item }: { item: MenuItem }) => {
    const imageUri = resolveProductImageUri(item);
    const imageUnavailable = imageUri ? Boolean(failedImageUris[imageUri] || isProductImageFailed(imageUri)) : false;
    const hasImage = Boolean(imageUri && !imageUnavailable);

    return (
      <Pressable style={styles.productCard} onPress={() => openProduct(item)} android_ripple={{ color: colors.primarySoft }}>
        <View style={styles.productImageBox}>
          {hasImage && imageUri ? (
            <Image
              source={{ uri: imageUri }}
              style={styles.productImage}
              resizeMode="contain"
              fadeDuration={0}
              onError={() => {
                markProductImageFailed(imageUri);
                setFailedImageUris((current) => ({
                  ...current,
                  [imageUri]: true
                }));
              }}
            />
          ) : (
            <View style={styles.productImageFallbackBox}>
              <Text style={styles.productImageFallback}>Sem foto</Text>
            </View>
          )}
          <View style={styles.productAddBadge}>
            <Text style={styles.productAddBadgeText}>+</Text>
          </View>
        </View>
        <View style={styles.productInfo}>
          <Text style={styles.productName} numberOfLines={2}>{formatProductCardTitle(item.descricao)}</Text>
          {item.descricaoCurta ? (
            <Text style={styles.productDescription} numberOfLines={2}>{item.descricaoCurta}</Text>
          ) : null}
          <View style={styles.productFooter}>
            <View style={styles.productPricePill}>
              <Text style={styles.productPrice}>{formatMoney(getProductUnitPrice(item, getDefaultSizeCode(item)))}</Text>
            </View>
            {item.permiteFracao ? <Text style={styles.fractionTag}>Fracionado</Text> : null}
          </View>
        </View>
      </Pressable>
    );
  };

  const renderMenu = () => (
    <View style={styles.menuScreen}>
      <View style={styles.topBar}>
        <View style={styles.topIdentity}>
          <Text style={styles.brandSmall}>Cardapio Tablet</Text>
          <Text style={styles.topMesa}>Mesa {formatMesa(session?.mesaNumero || settings.mesaNumero)}</Text>
        </View>
        <View style={styles.topStatus}>
          <Text style={styles.statusLabel}>Venda #{session?.idVenda || '-'}</Text>
          <Text style={styles.statusValue}>{formatMoney(activeTable?.valorTotal || 0)}</Text>
        </View>
        <View style={styles.topActions}>
          <ActionButton label="Configuracao" variant="config" compact onPress={() => openSettingsAuth('menu')} />
          <ActionButton label="Visualizar Pedido" variant="order" compact onPress={openOrderPreview} />
          <ActionButton label="Atualizar" variant="secondary" compact onPress={refreshCurrentMenu} />
          <ActionButton label={`Carrinho (${cart.length})`} variant="accent" compact onPress={() => setMode('cart')} />
        </View>
      </View>

      <View style={styles.menuBody}>
        <View style={styles.categoryRail}>
          <View style={styles.categoryHeader}>
            <Text style={styles.categoryTitle}>Categorias</Text>
            <View style={styles.categoryHeaderBadge}>
              <Text style={styles.categoryHeaderBadgeText}>{categories.length + 1}</Text>
            </View>
          </View>
          <Pressable
            style={({ pressed }) => [
              styles.categoryButton,
              selectedCategoryId === null && styles.categoryButtonSelected,
              pressed && styles.categoryButtonPressed
            ]}
            onPress={() => setSelectedCategoryId(null)}
            android_ripple={{ color: colors.primarySoft }}
          >
            <View style={[styles.categoryInitial, selectedCategoryId === null && styles.categoryInitialSelected]}>
              <Text style={[styles.categoryInitialText, selectedCategoryId === null && styles.categoryInitialTextSelected]}>
                T
              </Text>
            </View>
            <View style={styles.categoryContent}>
              <Text style={[styles.categoryText, selectedCategoryId === null && styles.categoryTextSelected]}>Todos</Text>
              <Text style={[styles.categoryMeta, selectedCategoryId === null && styles.categoryMetaSelected]}>
                {formatItemCount(products.length)}
              </Text>
            </View>
            <View style={[styles.categoryCountPill, selectedCategoryId === null && styles.categoryCountPillSelected]}>
              <Text style={[styles.categoryCountText, selectedCategoryId === null && styles.categoryCountTextSelected]}>
                {products.length}
              </Text>
            </View>
          </Pressable>
          <FlatList
            data={categories}
            renderItem={renderCategory}
            keyExtractor={(item) => String(item.id)}
            showsVerticalScrollIndicator={false}
            contentContainerStyle={styles.categoryListContent}
            initialNumToRender={14}
            maxToRenderPerBatch={8}
            windowSize={7}
          />
        </View>

        <View style={styles.productArea}>
          <FlatList
            data={filteredProducts}
            renderItem={renderProduct}
            keyExtractor={(item) => String(item.idProduto)}
            numColumns={4}
            columnWrapperStyle={styles.productRow}
            showsVerticalScrollIndicator={false}
            contentContainerStyle={[styles.productList, filteredProducts.length === 0 && styles.listEmptyContainer]}
            ListEmptyComponent={renderEmptyState(
              'Nenhum produto nesta categoria',
              'Escolha outra categoria ou chame o garcom para conferir o cardapio.'
            )}
            initialNumToRender={12}
            maxToRenderPerBatch={8}
            updateCellsBatchingPeriod={60}
            windowSize={11}
            removeClippedSubviews={false}
          />
        </View>
      </View>
    </View>
  );

  const renderCartItem = ({ item }: { item: CartItem }) => {
    const cartLineTitle = getCartLineTitle(item);
    const cartLineSizeDescription = getCartLineSizeDescription(item);
    const cartLineOptionals = getCartLineOptionals(item);
    const cartLineObservation = getCartLineObservation(item);
    const cartLineFractions = getCartLineFractions(item);
    const showFractionSummary = shouldShowCartFractionSummary(item);

    return (
      <View style={styles.cartLine}>
        <View style={styles.cartLineMain}>
          <Text style={styles.cartLineTitle}>{cartLineTitle}</Text>
          <Text style={styles.cartLineMeta}>
            {item.quantidade} x {formatMoney(item.valorUnitario)}
            {cartLineSizeDescription ? `  |  ${cartLineSizeDescription}` : ''}
          </Text>
          {cartLineOptionals.length > 0 && !showFractionSummary ? (
            <Text style={styles.cartLineOptionals} numberOfLines={2}>
              Adicionais: {summarizeOptionals(cartLineOptionals)}
            </Text>
          ) : null}
          {showFractionSummary ? (
            <View style={styles.cartFractionList}>
              <Text style={styles.cartFractionTitle}>Sabores ({formatFractionFlavorCount(cartLineFractions.length)})</Text>
              {cartLineFractions.map((fraction, index) => {
                const fractionOptionals = fraction.opcionais || [];
                const fractionObservation = fraction.observacao?.trim();

                return (
                  <View key={`${fraction.mobileLaunchId || index}-${fraction.idProduto}`} style={styles.cartFractionLine}>
                    <Text style={styles.cartFractionText}>
                      {index + 1}. {fraction.produtoDescricao}
                    </Text>
                    {fractionOptionals.length > 0 ? (
                      <Text style={styles.cartFractionDetail}>Adicionais: {summarizeOptionals(fractionOptionals)}</Text>
                    ) : null}
                    {fractionObservation && fractionObservation !== cartLineObservation ? (
                      <Text style={styles.cartFractionDetail}>Obs: {fractionObservation}</Text>
                    ) : null}
                  </View>
                );
              })}
            </View>
          ) : null}
          {cartLineObservation ? <Text style={styles.cartLineOptionals}>Obs: {cartLineObservation}</Text> : null}
        </View>
        <View style={styles.cartLineSide}>
          <Text style={styles.cartLineTotal}>{formatMoney(getCartItemTotal(item))}</Text>
          <Pressable style={styles.removeButton} onPress={() => removeCartItem(item.lineId)}>
            <Text style={styles.removeButtonText}>Remover</Text>
          </Pressable>
        </View>
      </View>
    );
  };

  const renderCart = () => (
    <View style={styles.cartScreen}>
      <View style={styles.topBar}>
        <View>
          <Text style={styles.brandSmall}>Carrinho da mesa</Text>
          <Text style={styles.topMesa}>Mesa {formatMesa(session?.mesaNumero || settings.mesaNumero)}</Text>
        </View>
        <View style={styles.topStatus}>
          <Text style={styles.statusLabel}>Itens ainda nao enviados</Text>
          <Text style={styles.statusValue}>{formatMoney(cartTotal)}</Text>
        </View>
        <View style={styles.topActions}>
          <ActionButton label="Voltar" variant="secondary" compact onPress={() => setMode('menu')} />
          <ActionButton label="Enviar pedido" compact onPress={sendCart} disabled={cart.length === 0 || sendingCart} />
        </View>
      </View>

      <FlatList
        data={cart}
        renderItem={renderCartItem}
        keyExtractor={(item) => item.lineId}
        contentContainerStyle={[styles.cartList, cart.length === 0 && styles.listEmptyContainer]}
        ListEmptyComponent={renderEmptyState(
          'Carrinho vazio',
          'Toque em um produto do cardapio para montar o pedido da mesa.'
        )}
      />
      <Text style={styles.cartHint}>Depois de enviado, qualquer ajuste deve ser feito pelo garcom.</Text>
    </View>
  );

  const renderOrderPreviewLine = ({ item }: { item: SaleLine }) => {
    const optionals = getSaleLineOptionals(item) || [];
    const observation = getSaleLineObservation(item);
    const fractions = item.fracoes || [];
    const showFractions = shouldShowSaleLineFractions(item);
    const lineTotal = item.valorTotal || roundMoney(item.valorUnitario * item.quantidade + item.acrescimo - item.desconto);

    return (
      <View style={styles.orderLine}>
        <View style={styles.orderQuantityBox}>
          <Text style={styles.orderQuantityValue}>{formatQuantity(item.quantidade)}</Text>
          <Text style={styles.orderQuantityLabel}>qtde</Text>
        </View>
        <View style={styles.orderLineMain}>
          <Text style={styles.orderLineTitle}>{formatProductCardTitle(getSaleLineTitle(item))}</Text>
          <View style={styles.orderLineMetaRow}>
            {item.descricaoTamanho ? <Text style={styles.orderLineMeta}>{item.descricaoTamanho}</Text> : null}
            {item.nomeGarcom ? <Text style={styles.orderLineMeta}>Garcom: {item.nomeGarcom}</Text> : null}
          </View>
          {optionals.length > 0 && !showFractions ? (
            <Text style={styles.orderLineText}>Adicionais: {summarizeOptionals(optionals)}</Text>
          ) : null}
          {observation ? <Text style={styles.orderLineText}>Obs: {observation}</Text> : null}
          {showFractions ? (
            <View style={styles.orderFractionBox}>
              <Text style={styles.orderFractionTitle}>Sabores</Text>
              {fractions.map((fraction, index) => {
                const fractionOptionals = fraction.opcionais || [];
                const fractionObservation = fraction.observacao?.trim();

                return (
                  <View key={`${fraction.numeroItem || index}-${fraction.idProduto}`} style={styles.orderFractionLine}>
                    <View style={styles.orderFractionMain}>
                      <Text style={styles.orderFractionText}>{formatProductCardTitle(fraction.produtoDescricao)}</Text>
                      {fractionOptionals.length > 0 ? (
                        <Text style={styles.orderFractionDetail}>Adicionais: {summarizeOptionals(fractionOptionals)}</Text>
                      ) : null}
                      {fractionObservation ? <Text style={styles.orderFractionDetail}>Obs: {fractionObservation}</Text> : null}
                    </View>
                    <Text style={styles.orderFractionValue}>{formatMoney(fraction.valorTotal)}</Text>
                  </View>
                );
              })}
            </View>
          ) : null}
        </View>
        <Text style={styles.orderLineTotal}>{formatMoney(lineTotal)}</Text>
      </View>
    );
  };

  const renderOrderPreviewModal = () => {
    const saleTotal = orderPreviewSale?.valorTotal ?? orderPreviewSale?.valor ?? activeTable?.valorTotal ?? 0;

    return (
      <Modal visible={orderPreviewVisible} transparent animationType="fade" onRequestClose={closeOrderPreview}>
        <View style={styles.modalBackdrop}>
          <View style={styles.orderModal}>
            <View style={styles.orderHeader}>
              <View>
                <Text style={styles.brandSmall}>Pedido da mesa</Text>
                <Text style={styles.orderTitle}>Mesa {formatMesa(session?.mesaNumero || settings.mesaNumero)}</Text>
              </View>
              <View style={styles.orderHeaderTotal}>
                <Text style={styles.statusLabel}>Venda #{session?.idVenda || '-'}</Text>
                <Text style={styles.orderTotal}>{formatMoney(saleTotal)}</Text>
              </View>
              <View style={styles.orderHeaderActions}>
                <ActionButton label="Atualizar" variant="secondary" compact onPress={openOrderPreview} disabled={orderPreviewLoading} />
                <ActionButton label="Fechar" variant="primary" compact onPress={closeOrderPreview} />
              </View>
            </View>

            {orderPreviewLoading ? (
              <View style={styles.orderLoading}>
                <ActivityIndicator size="large" color={colors.primary} />
                <Text style={styles.orderLoadingText}>Carregando pedido...</Text>
              </View>
            ) : (
              <FlatList
                data={visibleOrderLines}
                renderItem={renderOrderPreviewLine}
                keyExtractor={(item, index) => String(item.numeroItem || `${item.idProduto}-${index}`)}
                contentContainerStyle={[styles.orderList, visibleOrderLines.length === 0 && styles.listEmptyContainer]}
                ListEmptyComponent={renderEmptyState(
                  'Nenhum item enviado',
                  'Os itens confirmados pelo tablet aparecem aqui para conferencia.'
                )}
              />
            )}
          </View>
        </View>
      </Modal>
    );
  };

  const renderProductModal = () => {
    if (!selectedProduct) return null;
    const canLaunch = productLaunchReady &&
      (selectedProduct.permiteFracao ? selectedFractionReady : true);
    const modalImageUri = resolveProductImageUri(selectedProduct);
    const renderOptionalGrid = (
      optionals: ProductOptional[],
      getQuantity: (optional: ProductOptional) => number,
      onChange: (optional: ProductOptional, delta: number) => void
    ) => (
      <View style={styles.optionalGrid}>
        {optionals.map((optional) => {
          const quantity = getQuantity(optional);
          const selected = quantity > 0;
          const label = getOptionalDisplay(optional, selectedSize);
          const price = getOptionalPrice(optional, selectedSize);
          return (
            <View
              key={optional.idOpcional}
              style={[styles.optionalButton, selected && styles.optionalButtonSelected]}
            >
              <Text style={[styles.optionalText, selected && styles.optionalTextSelected]} numberOfLines={2}>
                {label}
              </Text>
              <Text style={[styles.optionalPrice, selected && styles.optionalTextSelected]}>
                {optional.gratis ? 'Gratis' : formatMoney(price)}
              </Text>
              <View style={styles.optionalStepper}>
                <Pressable
                  style={[styles.optionalStepButton, quantity <= 0 && styles.optionalStepButtonDisabled]}
                  onPress={() => onChange(optional, -1)}
                  disabled={quantity <= 0}
                >
                  <Text style={styles.optionalStepText}>-</Text>
                </Pressable>
                <Text style={[styles.optionalQtyText, selected && styles.optionalTextSelected]}>{quantity}</Text>
                <Pressable
                  style={styles.optionalStepButton}
                  onPress={() => onChange(optional, 1)}
                >
                  <Text style={styles.optionalStepText}>+</Text>
                </Pressable>
              </View>
            </View>
          );
        })}
      </View>
    );

    return (
      <Modal visible transparent animationType="fade" onRequestClose={closeProduct}>
        <View style={styles.modalBackdrop}>
          <View style={styles.productModal}>
            <View style={styles.productModalHeader}>
              <View style={styles.productModalHeaderText}>
                <Text style={styles.brandSmall}>Detalhe do produto</Text>
                <Text style={styles.modalTitle}>{formatProductCardTitle(selectedProduct.descricao)}</Text>
              </View>
              <Pressable style={styles.closeButton} onPress={closeProduct}>
                <Text style={styles.closeButtonText}>Fechar</Text>
              </Pressable>
            </View>

            <View style={styles.productModalBody}>
              <View style={styles.productModalPreview}>
                <View style={styles.modalImageFrame}>
                  {modalImageUri ? (
                    <Image source={{ uri: modalImageUri }} style={styles.modalImage} resizeMode="contain" fadeDuration={0} />
                  ) : (
                    <View style={styles.modalImageFallback}>
                      <Text style={styles.modalImageFallbackText}>Sem foto cadastrada</Text>
                    </View>
                  )}
                </View>

                <View style={styles.modalPricePanel}>
                  <Text style={styles.modalPriceLabel}>Valor atual</Text>
                  <Text style={styles.modalSubtitle}>{formatMoney(getProductUnitPrice(selectedProduct, selectedSize))}</Text>
                  {selectedProduct.permiteFracao ? <Text style={styles.modalTag}>Fracionado</Text> : null}
                </View>

                <Text style={styles.modalDescription}>
                  {selectedProduct.descricaoCurta || 'Produto preparado conforme o cardapio da casa.'}
                </Text>
              </View>

              <ScrollView
                style={styles.productModalOptions}
                contentContainerStyle={styles.productModalOptionsContent}
                showsVerticalScrollIndicator
                persistentScrollbar
                nestedScrollEnabled
                keyboardShouldPersistTaps="handled"
              >
                {selectedProductSizes.length > 1 ? (
                  <>
                    <Text style={styles.sectionLabel}>Tamanho</Text>
                    <View style={styles.sizeGrid}>
                      {selectedProductSizes.map((size) => {
                        const selected = selectedSize === size.code;
                        return (
                          <Pressable
                            key={size.code}
                            style={[styles.sizeButton, selected && styles.sizeButtonSelected]}
                            onPress={() => setSelectedSize(size.code)}
                          >
                            <Text style={[styles.sizeText, selected && styles.sizeTextSelected]}>{size.label}</Text>
                            <Text style={[styles.sizePrice, selected && styles.sizeTextSelected]}>{formatMoney(size.value)}</Text>
                          </Pressable>
                        );
                      })}
                    </View>
                  </>
                ) : null}

                {selectedProduct.permiteFracao ? (
                  <>
                    <Text style={styles.sectionLabel}>Sabores</Text>
                    <View style={styles.fractionCountRow}>
                      {FRACTION_FLAVOR_COUNTS.map((count) => {
                        const selected = selectedFractionCount === count;
                        return (
                          <Pressable
                            key={count}
                            style={[styles.fractionCountButton, selected && styles.fractionCountButtonSelected]}
                            onPress={() => changeFractionCount(count)}
                          >
                            <Text style={[styles.fractionCountText, selected && styles.fractionCountTextSelected]}>
                              {formatFractionFlavorCount(count)}
                            </Text>
                          </Pressable>
                        );
                      })}
                    </View>

                    {Array.from({ length: selectedFractionCount }).map((_, index) => {
                      const selectedFlavorId = selectedFractionIds[index];
                      const selectedFlavor = fractionFlavorOptions.find(
                        (flavor) => flavor.idProduto === selectedFlavorId
                      );
                      const orderedFlavorOptions = selectedFlavor
                        ? [
                            selectedFlavor,
                            ...fractionFlavorOptions.filter(
                              (flavor) => flavor.idProduto !== selectedFlavor.idProduto
                            )
                          ]
                        : fractionFlavorOptions;

                      return (
                        <View style={styles.fractionSlot} key={`fraction-${index}`}>
                          <Text style={styles.fractionSlotTitle}>Sabor {index + 1}</Text>
                          <ScrollView
                            horizontal
                            style={styles.fractionFlavorScroller}
                            contentContainerStyle={styles.fractionFlavorRow}
                            showsHorizontalScrollIndicator
                            persistentScrollbar
                            nestedScrollEnabled
                            keyboardShouldPersistTaps="handled"
                          >
                            {orderedFlavorOptions.map((flavor) => {
                              const selected = selectedFractionIds[index] === flavor.idProduto;
                              const duplicate = selectedFractionIds.some(
                                (id, otherIndex) => otherIndex !== index && id === flavor.idProduto
                              );
                              return (
                                <Pressable
                                  key={`${index}-${flavor.idProduto}`}
                                  style={[
                                    styles.fractionFlavorButton,
                                    selected && styles.fractionFlavorButtonSelected,
                                    duplicate && !selected && styles.fractionFlavorButtonDisabled
                                  ]}
                                  disabled={duplicate && !selected}
                                  onPress={() => selectFractionFlavor(index, flavor.idProduto)}
                                >
                                  <Text
                                    style={[
                                      styles.fractionFlavorText,
                                      selected && styles.fractionFlavorTextSelected
                                    ]}
                                    numberOfLines={2}
                                  >
                                    {flavor.descricao}
                                  </Text>
                                  <Text
                                    style={[
                                      styles.fractionFlavorPrice,
                                      selected && styles.fractionFlavorTextSelected
                                    ]}
                                  >
                                    {formatMoney(getProductUnitPrice(flavor, selectedSize))}
                                  </Text>
                                </Pressable>
                              );
                            })}
                          </ScrollView>
                        </View>
                      );
                    })}

                    {!selectedFractionReady ? (
                      <View style={styles.warningBox}>
                        <Text style={styles.warningText}>Selecione todos os sabores sem repetir.</Text>
                      </View>
                    ) : null}
                  </>
                ) : null}

                <Text style={styles.sectionLabel}>Quantidade</Text>
                <View style={styles.quantityRow}>
                  <Pressable style={styles.quantityButton} onPress={() => changeQuantity(-1)}>
                    <Text style={styles.quantityButtonText}>-</Text>
                  </Pressable>
                  <Text style={styles.quantityText}>{formatQuantity(selectedQuantity)}</Text>
                  <Pressable style={styles.quantityButton} onPress={() => changeQuantity(1)}>
                    <Text style={styles.quantityButtonText}>+</Text>
                  </Pressable>
                </View>

                {selectedProduct.permiteFracao ? (
                  selectedFractionProducts.map((flavor, index) => {
                    const optionals = selectedFractionOptionalsByIndex[index] || [];
                    if (!flavor || optionals.length === 0) return null;

                    return (
                      <View key={`fraction-optionals-${index}-${flavor.idProduto}`}>
                        <Text style={styles.sectionLabel}>
                          Opcionais do sabor {index + 1} - {flavor.descricao}
                        </Text>
                        {renderOptionalGrid(
                          optionals,
                          (optional) => selectedFractionOptionalQty[index]?.[optional.idOpcional] || 0,
                          (optional, delta) =>
                            changeFractionOptionalQuantity(index, optional.idOpcional, delta)
                        )}
                      </View>
                    );
                  })
                ) : selectedProductOptionals.length > 0 ? (
                  <>
                    <Text style={styles.sectionLabel}>Opcionais</Text>
                    {renderOptionalGrid(
                      selectedProductOptionals,
                      (optional) => selectedOptionalQty[optional.idOpcional] || 0,
                      (optional, delta) => changeOptionalQuantity(optional.idOpcional, delta)
                    )}
                  </>
                ) : null}

                <Text style={styles.sectionLabel}>Observacao</Text>
                <TextInput
                  style={styles.observationInput}
                  placeholder="Ex: sem cebola"
                  placeholderTextColor={colors.muted}
                  value={selectedObservation}
                  onChangeText={setSelectedObservation}
                  multiline
                />

              </ScrollView>
            </View>

            <View style={styles.modalFooter}>
              <Text style={styles.modalTotal}>{formatMoney(selectedLineTotal)}</Text>
              <ActionButton label="Adicionar" onPress={addSelectedProductToCart} disabled={!canLaunch} />
            </View>
          </View>
        </View>
      </Modal>
    );
  };

  const renderContent = () => {
    switch (mode) {
      case 'loading':
        return renderLoading();
      case 'setup':
        return renderSetup();
      case 'locked':
        return renderLocked();
      case 'unlock':
        return renderUnlock();
      case 'settingsAuth':
        return renderSettingsAuth();
      case 'cart':
        return renderCart();
      case 'menu':
      default:
        return renderMenu();
    }
  };

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar hidden />
      {renderContent()}
      {renderBanner()}
      {renderOrderPreviewModal()}
      {renderProductModal()}
      {renderNetworkFailureModal()}
      {renderAppDialog()}
      {renderBusyOverlay()}
    </SafeAreaView>
  );
}

function LabeledInput({
  label,
  value,
  onChangeText,
  keyboardType,
  secureTextEntry,
  autoCapitalize,
  autoCorrect,
  autoComplete,
  textContentType,
  importantForAutofill,
  placeholder,
  editable = true,
  containerStyle
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  keyboardType?: 'default' | 'numeric';
  secureTextEntry?: boolean;
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
  autoCorrect?: boolean;
  autoComplete?: TextInputProps['autoComplete'];
  textContentType?: TextInputProps['textContentType'];
  importantForAutofill?: TextInputProps['importantForAutofill'];
  placeholder?: string;
  editable?: boolean;
  containerStyle?: StyleProp<ViewStyle>;
}) {
  return (
    <View style={[styles.inputGroup, containerStyle]}>
      <Text style={styles.inputLabel}>{label}</Text>
      <TextInput
        style={[styles.input, !editable && styles.inputDisabled]}
        value={value}
        onChangeText={onChangeText}
        keyboardType={keyboardType}
        secureTextEntry={secureTextEntry}
        autoCapitalize={autoCapitalize}
        autoCorrect={autoCorrect}
        autoComplete={autoComplete}
        textContentType={textContentType}
        importantForAutofill={importantForAutofill}
        placeholder={placeholder}
        placeholderTextColor={colors.muted}
        editable={editable}
      />
    </View>
  );
}

function ToggleRow({
  label,
  value,
  onValueChange,
  disabled = false
}: {
  label: string;
  value: boolean;
  onValueChange: (value: boolean) => void;
  disabled?: boolean;
}) {
  return (
    <Pressable style={[styles.toggleRow, disabled && styles.toggleRowDisabled]} onPress={() => onValueChange(!value)} disabled={disabled}>
      <Text style={[styles.toggleLabel, disabled && styles.toggleLabelDisabled]}>{label}</Text>
      <View style={[styles.toggleBox, value && styles.toggleBoxActive, disabled && styles.toggleBoxDisabled]}>
        <Text style={[styles.toggleText, value && styles.toggleTextActive, disabled && styles.toggleTextDisabled]}>{value ? 'Sim' : 'Nao'}</Text>
      </View>
    </Pressable>
  );
}

function DiagnosticItem({
  label,
  value,
  tone = 'neutral'
}: {
  label: string;
  value: string;
  tone?: 'neutral' | 'success' | 'danger';
}) {
  return (
    <View style={styles.diagnosticItem}>
      <View style={[styles.diagnosticDot, tone === 'success' && styles.diagnosticDotSuccess, tone === 'danger' && styles.diagnosticDotDanger]} />
      <View style={styles.diagnosticTextBox}>
        <Text style={styles.diagnosticLabel}>{label}</Text>
        <Text style={styles.diagnosticValue} numberOfLines={1}>{value}</Text>
      </View>
    </View>
  );
}

function ActionButton({
  label,
  onPress,
  variant = 'primary',
  compact = false,
  disabled = false
}: {
  label: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'danger' | 'accent' | 'config' | 'order';
  compact?: boolean;
  disabled?: boolean;
}) {
  return (
    <Pressable
      style={[
        styles.actionButton,
        compact && styles.actionButtonCompact,
        variant === 'secondary' && styles.actionButtonSecondary,
        variant === 'danger' && styles.actionButtonDanger,
        variant === 'accent' && styles.actionButtonAccent,
        variant === 'config' && styles.actionButtonConfig,
        variant === 'order' && styles.actionButtonOrder,
        disabled && styles.actionButtonDisabled
      ]}
      onPress={onPress}
      disabled={disabled}
    >
      {variant === 'config' ? (
        <View style={styles.actionButtonConfigBadge}>
          <Text style={styles.actionButtonConfigBadgeText}>ADM</Text>
        </View>
      ) : null}
      <Text
        style={[
          styles.actionButtonText,
          variant === 'secondary' && styles.actionButtonSecondaryText,
          variant === 'config' && styles.actionButtonConfigText,
          variant === 'order' && styles.actionButtonOrderText,
          disabled && styles.actionButtonDisabledText
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.background
  },
  screen: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.xl
  },
  setupScreen: {
    backgroundColor: colors.background,
    padding: spacing.lg
  },
  centerScreen: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.lg,
    padding: spacing.xl
  },
  centerTitle: {
    fontSize: 28,
    color: colors.text,
    fontWeight: '900',
    textAlign: 'center'
  },
  loadingCard: {
    width: '72%',
    maxWidth: 760,
    minWidth: 520,
    minHeight: 320,
    borderRadius: radius.xl,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.xl,
    gap: spacing.lg,
    ...shadows.card
  },
  loadingCardIssue: {
    borderTopWidth: 5,
    borderTopColor: colors.accent
  },
  loadingBadge: {
    minHeight: 34,
    minWidth: 72,
    borderRadius: radius.sm,
    backgroundColor: colors.primarySoft,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.md
  },
  loadingBadgeText: {
    color: colors.primary,
    fontSize: 13,
    fontWeight: '900'
  },
  loadingAlertIcon: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: '#fff4e5',
    borderWidth: 1,
    borderColor: '#fed7aa',
    alignItems: 'center',
    justifyContent: 'center'
  },
  loadingAlertIconText: {
    color: colors.accent,
    fontSize: 38,
    fontWeight: '900'
  },
  loadingTextBlock: {
    alignItems: 'center',
    gap: spacing.sm
  },
  loadingDescription: {
    maxWidth: 600,
    color: colors.muted,
    fontSize: 17,
    lineHeight: 25,
    fontWeight: '700',
    textAlign: 'center'
  },
  loadingActions: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.md,
    marginTop: spacing.sm
  },
  setupShell: {
    width: '88%',
    maxWidth: 1220,
    minWidth: 920,
    height: '100%',
    flexDirection: 'row',
    backgroundColor: colors.surface,
    borderRadius: radius.xl,
    borderWidth: 1,
    borderColor: colors.border,
    overflow: 'hidden',
    ...shadows.card
  },
  setupSidebar: {
    width: 320,
    backgroundColor: colors.primaryDark,
    overflow: 'hidden'
  },
  setupSidebarScroll: {
    flex: 1
  },
  setupSidebarContent: {
    flexGrow: 1,
    padding: spacing.xl,
    justifyContent: 'space-between',
    gap: spacing.xl
  },
  setupEyebrow: {
    color: '#b9d0e4',
    fontSize: 12,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  setupHeroTitle: {
    color: colors.surface,
    fontSize: 29,
    lineHeight: 35,
    fontWeight: '900',
    marginTop: spacing.sm
  },
  setupHeroText: {
    color: '#dbeaf6',
    fontSize: 18,
    fontWeight: '800',
    marginTop: spacing.md
  },
  setupSummary: {
    gap: spacing.md
  },
  setupSummaryItem: {
    minHeight: 74,
    borderRadius: radius.md,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.16)',
    padding: spacing.md,
    justifyContent: 'center'
  },
  setupSummaryLabel: {
    color: '#b9d0e4',
    fontSize: 12,
    fontWeight: '800',
    textTransform: 'uppercase'
  },
  setupSummaryValue: {
    color: colors.surface,
    fontSize: 18,
    fontWeight: '900',
    marginTop: spacing.xs
  },
  setupPanel: {
    flex: 1,
    minWidth: 0
  },
  setupScroll: {
    flex: 1
  },
  setupScrollContent: {
    flexGrow: 1,
    padding: spacing.xl,
    paddingBottom: spacing.xl
  },
  setupHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: spacing.lg,
    marginBottom: spacing.lg
  },
  setupMesaBadge: {
    minWidth: 96,
    minHeight: 72,
    borderRadius: radius.md,
    backgroundColor: colors.primarySoft,
    borderWidth: 1,
    borderColor: colors.borderStrong,
    alignItems: 'center',
    justifyContent: 'center'
  },
  setupMesaBadgeLabel: {
    color: colors.primary,
    fontSize: 11,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  setupMesaBadgeValue: {
    color: colors.primaryDark,
    fontSize: 28,
    fontWeight: '900'
  },
  setupFieldCard: {
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surfaceMuted,
    padding: spacing.lg,
    ...shadows.soft
  },
  setupDiagnosticsCard: {
    marginTop: spacing.md,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
    padding: spacing.lg,
    ...shadows.soft
  },
  diagnosticsHeader: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md,
    marginBottom: spacing.md
  },
  diagnosticsTitle: {
    color: colors.text,
    fontSize: 17,
    fontWeight: '900'
  },
  diagnosticsSubtitle: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: '700',
    marginTop: 2
  },
  diagnosticsCountBadge: {
    width: 64,
    minHeight: 46,
    borderRadius: radius.md,
    backgroundColor: colors.primarySoft,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center'
  },
  diagnosticsCountBadgeWarning: {
    backgroundColor: colors.warningSoft,
    borderColor: colors.productPriceBorder
  },
  diagnosticsCountValue: {
    color: colors.primary,
    fontSize: 20,
    lineHeight: 23,
    fontWeight: '900'
  },
  diagnosticsCountValueWarning: {
    color: colors.warning
  },
  diagnosticsCountLabel: {
    color: colors.muted,
    fontSize: 10,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  kioskStatusCard: {
    minHeight: 88,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surfaceMuted,
    padding: spacing.md,
    marginBottom: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md
  },
  kioskStatusCardSuccess: {
    backgroundColor: colors.successSoft,
    borderColor: '#b9e7cc'
  },
  kioskStatusCardWarning: {
    backgroundColor: colors.warningSoft,
    borderColor: colors.productPriceBorder
  },
  kioskStatusCardDanger: {
    backgroundColor: colors.dangerSoft,
    borderColor: '#f1bcc3'
  },
  kioskStatusBadge: {
    width: 58,
    height: 46,
    borderRadius: radius.md,
    backgroundColor: colors.primarySoft,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center'
  },
  kioskStatusBadgeSuccess: {
    backgroundColor: colors.surface,
    borderColor: '#b9e7cc'
  },
  kioskStatusBadgeWarning: {
    backgroundColor: colors.surface,
    borderColor: colors.productPriceBorder
  },
  kioskStatusBadgeDanger: {
    backgroundColor: colors.surface,
    borderColor: '#f1bcc3'
  },
  kioskStatusBadgeText: {
    color: colors.primary,
    fontSize: 13,
    fontWeight: '900'
  },
  kioskStatusBadgeTextSuccess: {
    color: colors.success
  },
  kioskStatusBadgeTextWarning: {
    color: colors.warning
  },
  kioskStatusBadgeTextDanger: {
    color: colors.danger
  },
  kioskStatusContent: {
    flex: 1
  },
  kioskStatusLabel: {
    color: colors.muted,
    fontSize: 10,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  kioskStatusTitle: {
    color: colors.text,
    fontSize: 18,
    lineHeight: 22,
    fontWeight: '900',
    marginTop: 2
  },
  kioskStatusText: {
    color: colors.muted,
    fontSize: 12,
    lineHeight: 16,
    fontWeight: '800',
    marginTop: 2
  },
  diagnosticsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm
  },
  diagnosticItem: {
    width: '48.8%',
    minHeight: 54,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surfaceMuted,
    paddingHorizontal: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm
  },
  diagnosticDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: colors.muted
  },
  diagnosticDotSuccess: {
    backgroundColor: colors.success
  },
  diagnosticDotDanger: {
    backgroundColor: colors.danger
  },
  diagnosticTextBox: {
    flex: 1
  },
  diagnosticLabel: {
    color: colors.muted,
    fontSize: 10,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  diagnosticValue: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '900',
    marginTop: 2
  },
  pendingOrderList: {
    marginTop: spacing.md,
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    gap: spacing.sm
  },
  pendingOrderListHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md
  },
  pendingOrderListTitle: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  pendingOrderListMeta: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: '800'
  },
  pendingOrderRow: {
    minHeight: 58,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surfaceMuted,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm
  },
  pendingOrderDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: colors.muted
  },
  pendingOrderDotWarning: {
    backgroundColor: colors.warning
  },
  pendingOrderDotDanger: {
    backgroundColor: colors.danger
  },
  pendingOrderTextBox: {
    flex: 1,
    minWidth: 0
  },
  pendingOrderTitle: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '900'
  },
  pendingOrderMeta: {
    color: colors.primary,
    fontSize: 12,
    fontWeight: '800',
    marginTop: 2
  },
  pendingOrderError: {
    color: colors.danger,
    fontSize: 11,
    fontWeight: '800',
    marginTop: 2
  },
  pendingOrderMore: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: '800'
  },
  diagnosticsFooter: {
    minHeight: 50,
    marginTop: spacing.md,
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md
  },
  diagnosticsActions: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: spacing.sm,
    flexShrink: 0
  },
  diagnosticsLastError: {
    flex: 1,
    color: colors.muted,
    fontSize: 12,
    lineHeight: 17,
    fontWeight: '700'
  },
  authScreen: {
    backgroundColor: colors.background,
    padding: spacing.lg
  },
  authShell: {
    width: '82%',
    maxWidth: 1080,
    minWidth: 820,
    minHeight: 548,
    flexDirection: 'row',
    backgroundColor: colors.surface,
    borderRadius: radius.xl,
    borderWidth: 1,
    borderColor: colors.border,
    overflow: 'hidden',
    ...shadows.card
  },
  unlockShell: {
    maxWidth: 1020
  },
  authSidebar: {
    width: 300,
    backgroundColor: colors.primaryDark,
    padding: spacing.xl,
    justifyContent: 'space-between'
  },
  unlockSidebar: {
    backgroundColor: colors.primaryDark
  },
  authSidebarTop: {
    gap: spacing.md
  },
  authSidebarEyebrow: {
    color: '#b9d0e4',
    fontSize: 12,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  authSidebarBottom: {
    gap: spacing.md
  },
  authPanel: {
    flex: 1,
    paddingHorizontal: spacing.xxl,
    paddingVertical: spacing.xl,
    justifyContent: 'center'
  },
  authKickerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md
  },
  authHeaderText: {
    marginBottom: spacing.lg
  },
  authBadge: {
    minWidth: 58,
    height: 38,
    borderRadius: radius.md,
    backgroundColor: colors.warningSoft,
    borderWidth: 1,
    borderColor: '#f5c377',
    alignItems: 'center',
    justifyContent: 'center'
  },
  authBadgeText: {
    color: colors.warning,
    fontSize: 15,
    fontWeight: '900'
  },
  unlockBadge: {
    backgroundColor: colors.accentSoft,
    borderColor: colors.productPriceBorder
  },
  unlockBadgeText: {
    color: colors.accent
  },
  authKicker: {
    color: colors.primary,
    fontSize: 13,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  authHeroTitle: {
    color: colors.surface,
    fontSize: 30,
    lineHeight: 36,
    fontWeight: '900'
  },
  authMesaCard: {
    width: 128,
    minHeight: 92,
    borderRadius: radius.md,
    backgroundColor: colors.primarySoft,
    borderWidth: 1,
    borderColor: colors.borderStrong,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.md
  },
  unlockMesaCard: {
    backgroundColor: colors.accentSoft,
    borderColor: colors.productPriceBorder
  },
  authMesaLabel: {
    color: colors.primary,
    fontSize: 12,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  authMesaValue: {
    color: colors.primaryDark,
    fontSize: 34,
    lineHeight: 39,
    fontWeight: '900'
  },
  authAccessPanel: {
    minHeight: 84,
    borderRadius: radius.md,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.18)',
    padding: spacing.md,
    justifyContent: 'center'
  },
  unlockAccessPanel: {
    backgroundColor: 'rgba(24,135,83,0.18)',
    borderColor: 'rgba(191,231,210,0.28)'
  },
  authAccessLabel: {
    color: '#b9d0e4',
    fontSize: 12,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  authAccessText: {
    color: colors.surface,
    fontSize: 20,
    lineHeight: 25,
    fontWeight: '900',
    marginTop: spacing.xs
  },
  authSummaryGrid: {
    gap: spacing.sm
  },
  authSummaryItem: {
    minHeight: 68,
    borderRadius: radius.md,
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.14)',
    padding: spacing.sm,
    justifyContent: 'center'
  },
  authSummaryLabel: {
    color: '#b9d0e4',
    fontSize: 10,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  authSummaryValue: {
    color: colors.surface,
    fontSize: 15,
    fontWeight: '900',
    marginTop: spacing.xs
  },
  authTitle: {
    color: colors.text,
    fontSize: 31,
    lineHeight: 37,
    fontWeight: '900'
  },
  authSubtitle: {
    color: colors.muted,
    fontSize: 16,
    lineHeight: 22,
    fontWeight: '700',
    marginTop: spacing.xs
  },
  authFieldCard: {
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surfaceMuted,
    padding: spacing.xl,
    marginBottom: spacing.lg,
    ...shadows.soft
  },
  authFieldHeader: {
    minHeight: 34,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md,
    marginBottom: spacing.md,
    paddingBottom: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: '#e1eaf1'
  },
  authFieldTitle: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '900'
  },
  authFieldMeta: {
    color: colors.primary,
    backgroundColor: colors.primarySoft,
    borderRadius: radius.sm,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    fontSize: 12,
    fontWeight: '900'
  },
  unlockFieldMeta: {
    color: colors.accent,
    backgroundColor: colors.accentSoft
  },
  authInputGroup: {
    marginBottom: spacing.lg
  },
  authInputGroupLast: {
    marginBottom: 0
  },
  authActionsBar: {
    minHeight: 58,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.lg
  },
  authActionNote: {
    flex: 1,
    color: colors.muted,
    fontSize: 13,
    lineHeight: 18,
    fontWeight: '700'
  },
  authActionsRow: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.md
  },
  authActionsRowRecovery: {
    flexShrink: 1,
    flexWrap: 'wrap'
  },
  appFooter: {
    minHeight: 30,
    marginTop: spacing.md,
    paddingTop: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center'
  },
  appFooterText: {
    color: colors.muted,
    fontSize: 11,
    lineHeight: 15,
    fontWeight: '900',
    textAlign: 'center'
  },
  unlockPanel: {
    width: '56%',
    maxWidth: 560,
    minWidth: 430,
    backgroundColor: colors.surface,
    borderRadius: 8,
    padding: spacing.xl,
    borderWidth: 1,
    borderColor: colors.border
  },
  setupTitle: {
    fontSize: 32,
    lineHeight: 38,
    fontWeight: '900',
    color: colors.text
  },
  setupSubtitle: {
    fontSize: 16,
    lineHeight: 22,
    color: colors.muted,
    marginTop: spacing.xs,
    marginBottom: 0
  },
  setupGrid: {
    flexDirection: 'row',
    gap: spacing.md
  },
  inputGroup: {
    marginBottom: spacing.md
  },
  inputGroupGrid: {
    flex: 1
  },
  inputLabel: {
    fontSize: 13,
    lineHeight: 17,
    color: colors.muted,
    fontWeight: '700',
    marginBottom: 6
  },
  input: {
    height: 58,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
    backgroundColor: colors.surface,
    color: colors.text,
    paddingHorizontal: spacing.md,
    paddingVertical: 0,
    fontSize: 16,
    textAlignVertical: 'center'
  },
  inputDisabled: {
    backgroundColor: colors.surfaceMuted,
    color: colors.muted
  },
  emergencyApiNotice: {
    minHeight: 48,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.productPriceBorder,
    backgroundColor: colors.warningSoft,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    justifyContent: 'center',
    marginBottom: spacing.md
  },
  emergencyApiNoticeText: {
    color: colors.warning,
    fontSize: 12,
    lineHeight: 17,
    fontWeight: '800'
  },
  toggleRow: {
    minHeight: 52,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
    backgroundColor: colors.surfaceMuted,
    paddingHorizontal: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.md,
    gap: spacing.md
  },
  toggleRowDisabled: {
    opacity: 0.72
  },
  toggleLabel: {
    color: colors.text,
    fontSize: 15,
    fontWeight: '800',
    flex: 1
  },
  toggleLabelDisabled: {
    color: colors.muted
  },
  toggleBox: {
    minWidth: 72,
    minHeight: 34,
    borderRadius: radius.sm,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center'
  },
  toggleBoxActive: {
    backgroundColor: colors.success,
    borderColor: colors.success
  },
  toggleBoxDisabled: {
    backgroundColor: colors.surfaceMuted,
    borderColor: colors.border
  },
  toggleText: {
    color: colors.muted,
    fontWeight: '900'
  },
  toggleTextActive: {
    color: colors.surface
  },
  toggleTextDisabled: {
    color: colors.muted
  },
  actionsRow: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.md,
    marginTop: spacing.sm
  },
  actionButton: {
    minHeight: 48,
    minWidth: 132,
    borderRadius: radius.md,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    gap: spacing.sm,
    paddingHorizontal: spacing.lg,
    borderWidth: 1,
    borderColor: colors.primary,
    ...shadows.button
  },
  actionButtonCompact: {
    minHeight: 40,
    minWidth: 104,
    paddingHorizontal: spacing.md
  },
  actionButtonSecondary: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    ...shadows.soft
  },
  actionButtonDanger: {
    backgroundColor: colors.danger,
    borderColor: colors.danger
  },
  actionButtonAccent: {
    backgroundColor: colors.success,
    borderColor: colors.success
  },
  actionButtonConfig: {
    backgroundColor: colors.accent,
    borderColor: '#c85f16',
    borderBottomWidth: 3,
    minWidth: 188,
    ...shadows.button
  },
  actionButtonOrder: {
    backgroundColor: colors.primarySoft,
    borderColor: colors.borderStrong,
    minWidth: 170
  },
  actionButtonDisabled: {
    backgroundColor: colors.surfaceMuted,
    borderColor: colors.border
  },
  actionButtonText: {
    color: colors.surface,
    fontWeight: '800',
    fontSize: 15
  },
  actionButtonSecondaryText: {
    color: colors.primary
  },
  actionButtonConfigText: {
    color: colors.surface,
    fontWeight: '900'
  },
  actionButtonOrderText: {
    color: colors.primaryDark,
    fontWeight: '900'
  },
  actionButtonConfigBadge: {
    minWidth: 38,
    height: 25,
    borderRadius: radius.sm,
    backgroundColor: colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.xs
  },
  actionButtonConfigBadgeText: {
    color: colors.accent,
    fontSize: 10,
    fontWeight: '900'
  },
  actionButtonDisabledText: {
    color: colors.muted
  },
  lockedScreen: {
    flex: 1,
    padding: spacing.xl,
    backgroundColor: colors.background
  },
  lockedHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.lg,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.lg,
    ...shadows.card
  },
  brand: {
    color: colors.accent,
    fontSize: 30,
    fontWeight: '900'
  },
  lockedMesa: {
    color: colors.primaryDark,
    fontSize: 30,
    fontWeight: '900'
  },
  lockedPanel: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.lg
  },
  lockedTitle: {
    color: colors.text,
    fontSize: 42,
    fontWeight: '900'
  },
  lockedText: {
    color: colors.muted,
    fontSize: 18,
    maxWidth: 520,
    textAlign: 'center'
  },
  lockedActions: {
    flexDirection: 'row',
    gap: spacing.md,
    marginTop: spacing.sm
  },
  menuScreen: {
    flex: 1,
    padding: spacing.md,
    gap: spacing.md,
    backgroundColor: colors.background
  },
  cartScreen: {
    flex: 1,
    padding: spacing.lg,
    gap: spacing.md,
    backgroundColor: colors.background
  },
  topBar: {
    minHeight: 104,
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderTopWidth: 5,
    borderTopColor: colors.accent,
    borderColor: colors.border,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.lg,
    ...shadows.card
  },
  topIdentity: {
    flex: 1
  },
  brandSmall: {
    color: colors.accent,
    fontSize: 13,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  topMesa: {
    color: colors.text,
    fontSize: 34,
    fontWeight: '900'
  },
  topStatus: {
    alignItems: 'flex-end',
    minWidth: 190
  },
  statusLabel: {
    color: colors.muted,
    fontSize: 13,
    fontWeight: '800'
  },
  statusValue: {
    color: colors.primaryDark,
    fontSize: 28,
    fontWeight: '900'
  },
  topActions: {
    flexDirection: 'row',
    gap: spacing.sm,
    alignItems: 'center'
  },
  menuBody: {
    flex: 1,
    flexDirection: 'row',
    gap: spacing.md
  },
  categoryRail: {
    width: 306,
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.md,
    ...shadows.card
  },
  categoryHeader: {
    minHeight: 32,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.md,
    paddingHorizontal: spacing.xs
  },
  categoryTitle: {
    color: colors.accent,
    fontSize: 12,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  categoryHeaderBadge: {
    minWidth: 30,
    height: 24,
    borderRadius: radius.sm,
    backgroundColor: colors.primarySoft,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.xs
  },
  categoryHeaderBadgeText: {
    color: colors.primary,
    fontSize: 12,
    fontWeight: '900'
  },
  categoryButton: {
    minHeight: 74,
    borderRadius: radius.md,
    paddingHorizontal: spacing.md,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    gap: spacing.sm,
    ...shadows.soft
  },
  categoryButtonSelected: {
    backgroundColor: colors.categorySelected,
    borderColor: colors.categorySelected,
    ...shadows.button
  },
  categoryButtonPressed: {
    transform: [{ scale: 0.99 }]
  },
  categoryInitial: {
    width: 36,
    height: 36,
    borderRadius: radius.sm,
    backgroundColor: colors.categoryCountSurface,
    alignItems: 'center',
    justifyContent: 'center'
  },
  categoryInitialSelected: {
    backgroundColor: 'rgba(255,255,255,0.18)'
  },
  categoryInitialText: {
    color: colors.primary,
    fontSize: 15,
    fontWeight: '900'
  },
  categoryInitialTextSelected: {
    color: colors.surface
  },
  categoryContent: {
    flex: 1,
    gap: 3
  },
  categoryText: {
    color: colors.categoryText,
    fontSize: 14,
    lineHeight: 18,
    fontWeight: '800'
  },
  categoryTextSelected: {
    color: colors.surface
  },
  categoryMeta: {
    color: colors.categoryMuted,
    fontSize: 11,
    fontWeight: '700'
  },
  categoryMetaSelected: {
    color: 'rgba(255,255,255,0.84)'
  },
  categoryCountPill: {
    minWidth: 34,
    height: 30,
    borderRadius: radius.sm,
    backgroundColor: colors.categoryCountSurface,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.xs
  },
  categoryCountPillSelected: {
    backgroundColor: colors.surface
  },
  categoryCountText: {
    color: colors.primary,
    fontSize: 13,
    fontWeight: '900'
  },
  categoryCountTextSelected: {
    color: colors.primaryDark
  },
  categoryListContent: {
    paddingBottom: spacing.lg
  },
  productArea: {
    flex: 1,
    gap: spacing.md
  },
  productList: {
    paddingBottom: spacing.xxl
  },
  listEmptyContainer: {
    flexGrow: 1,
    alignItems: 'center',
    justifyContent: 'center'
  },
  productRow: {
    gap: spacing.md,
    marginBottom: spacing.md
  },
  productCard: {
    flex: 1,
    minHeight: 238,
    maxWidth: '24.25%',
    backgroundColor: colors.productCard,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderTopWidth: 4,
    borderTopColor: colors.accent,
    borderColor: colors.border,
    overflow: 'hidden',
    ...shadows.card
  },
  productImageBox: {
    height: 136,
    backgroundColor: colors.productImageSurface,
    alignItems: 'center',
    justifyContent: 'center',
    borderBottomWidth: 1,
    borderBottomColor: colors.border
  },
  productImage: {
    width: '92%',
    height: '92%'
  },
  productImageFallbackBox: {
    minWidth: 100,
    minHeight: 38,
    borderRadius: radius.sm,
    backgroundColor: colors.primarySoft,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.md
  },
  productImageFallback: {
    color: colors.muted,
    fontSize: 13,
    fontWeight: '800'
  },
  productAddBadge: {
    position: 'absolute',
    right: spacing.sm,
    top: spacing.sm,
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: colors.success,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: colors.surface
  },
  productAddBadgeText: {
    color: colors.surface,
    fontSize: 22,
    lineHeight: 25,
    fontWeight: '900'
  },
  productInfo: {
    flex: 1,
    paddingHorizontal: spacing.md,
    paddingTop: 14,
    paddingBottom: spacing.sm,
    gap: 9,
    backgroundColor: colors.productCard
  },
  productName: {
    minHeight: 42,
    color: colors.productTitle,
    fontSize: 15,
    lineHeight: 20,
    fontWeight: '800'
  },
  productDescription: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 18
  },
  productFooter: {
    marginTop: 'auto',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: spacing.sm
  },
  productPricePill: {
    minHeight: 36,
    borderRadius: radius.sm,
    backgroundColor: colors.accentSoft,
    borderWidth: 1,
    borderColor: colors.productPriceBorder,
    paddingHorizontal: spacing.sm,
    alignItems: 'center',
    justifyContent: 'center'
  },
  productPrice: {
    color: colors.accent,
    fontSize: 18,
    fontWeight: '900'
  },
  fractionTag: {
    color: colors.warning,
    backgroundColor: colors.warningSoft,
    fontSize: 11,
    fontWeight: '800',
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: radius.sm
  },
  cartList: {
    gap: spacing.md,
    paddingBottom: spacing.xxl
  },
  cartLine: {
    minHeight: 104,
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.md,
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: spacing.lg,
    ...shadows.soft
  },
  cartLineMain: {
    flex: 1,
    gap: spacing.xs
  },
  cartLineTitle: {
    color: colors.text,
    fontSize: 18,
    fontWeight: '900'
  },
  cartLineMeta: {
    color: colors.muted,
    fontSize: 14,
    fontWeight: '700'
  },
  cartLineOptionals: {
    color: colors.muted,
    fontSize: 13
  },
  cartFractionList: {
    marginTop: spacing.xs,
    gap: 2
  },
  cartFractionTitle: {
    color: colors.primaryDark,
    fontSize: 13,
    fontWeight: '800'
  },
  cartFractionLine: {
    gap: 1
  },
  cartFractionText: {
    color: colors.productTitle,
    fontSize: 13,
    fontWeight: '700'
  },
  cartFractionDetail: {
    color: colors.muted,
    fontSize: 12,
    lineHeight: 16
  },
  cartLineSide: {
    minWidth: 150,
    alignItems: 'flex-end',
    justifyContent: 'space-between'
  },
  cartLineTotal: {
    color: colors.text,
    fontSize: 20,
    fontWeight: '900'
  },
  removeButton: {
    minHeight: 36,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.danger,
    paddingHorizontal: spacing.md,
    alignItems: 'center',
    justifyContent: 'center'
  },
  removeButtonText: {
    color: colors.danger,
    fontWeight: '800'
  },
  cartHint: {
    color: colors.muted,
    fontSize: 13,
    textAlign: 'right'
  },
  orderModal: {
    width: '86%',
    maxWidth: 1180,
    maxHeight: '90%',
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.border,
    ...shadows.card
  },
  orderHeader: {
    minHeight: 92,
    borderRadius: radius.lg,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderTopWidth: 5,
    borderTopColor: colors.accent,
    borderColor: colors.border,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.lg,
    marginBottom: spacing.md,
    ...shadows.soft
  },
  orderTitle: {
    color: colors.text,
    fontSize: 30,
    fontWeight: '900'
  },
  orderHeaderTotal: {
    minWidth: 180,
    alignItems: 'flex-end'
  },
  orderTotal: {
    color: colors.primaryDark,
    fontSize: 26,
    fontWeight: '900'
  },
  orderHeaderActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm
  },
  orderList: {
    gap: spacing.sm,
    paddingBottom: spacing.md
  },
  orderLine: {
    minHeight: 98,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
    padding: spacing.md,
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing.md,
    ...shadows.soft
  },
  orderQuantityBox: {
    minWidth: 66,
    minHeight: 58,
    borderRadius: radius.md,
    backgroundColor: colors.primarySoft,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.sm
  },
  orderQuantityValue: {
    color: colors.primaryDark,
    fontSize: 20,
    fontWeight: '900'
  },
  orderQuantityLabel: {
    color: colors.primary,
    fontSize: 10,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  orderLineMain: {
    flex: 1,
    gap: spacing.xs
  },
  orderLineTitle: {
    color: colors.text,
    fontSize: 18,
    fontWeight: '900'
  },
  orderLineMetaRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.xs
  },
  orderLineMeta: {
    color: colors.primaryDark,
    backgroundColor: colors.primarySoft,
    borderRadius: radius.sm,
    paddingHorizontal: spacing.sm,
    paddingVertical: 3,
    fontSize: 12,
    fontWeight: '800'
  },
  orderLineText: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 18,
    fontWeight: '700'
  },
  orderLineTotal: {
    minWidth: 112,
    color: colors.primaryDark,
    fontSize: 19,
    fontWeight: '900',
    textAlign: 'right'
  },
  orderFractionBox: {
    marginTop: spacing.xs,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
    padding: spacing.sm,
    gap: spacing.xs
  },
  orderFractionTitle: {
    color: colors.primary,
    fontSize: 12,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  orderFractionLine: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: spacing.md
  },
  orderFractionMain: {
    flex: 1,
    minWidth: 0,
    gap: 2
  },
  orderFractionText: {
    color: colors.productTitle,
    fontSize: 13,
    fontWeight: '800'
  },
  orderFractionDetail: {
    color: colors.muted,
    fontSize: 12,
    lineHeight: 16,
    fontWeight: '700'
  },
  orderFractionValue: {
    color: colors.accent,
    fontSize: 13,
    fontWeight: '900'
  },
  orderLoading: {
    minHeight: 240,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.md
  },
  orderLoadingText: {
    color: colors.muted,
    fontSize: 15,
    fontWeight: '800'
  },
  emptyText: {
    color: colors.muted,
    fontSize: 16,
    padding: spacing.xl,
    textAlign: 'center'
  },
  emptyState: {
    minHeight: 220,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.xl,
    gap: spacing.sm
  },
  emptyStateIcon: {
    width: 54,
    height: 54,
    borderRadius: radius.lg,
    backgroundColor: colors.primarySoft,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.xs
  },
  emptyStateIconText: {
    color: colors.primary,
    fontSize: 16,
    fontWeight: '900'
  },
  emptyStateTitle: {
    color: colors.text,
    fontSize: 22,
    fontWeight: '900',
    textAlign: 'center'
  },
  emptyStateText: {
    maxWidth: 380,
    color: colors.muted,
    fontSize: 14,
    lineHeight: 20,
    fontWeight: '700',
    textAlign: 'center'
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.55)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.xl
  },
  productModal: {
    width: '90%',
    maxWidth: 1180,
    height: '94%',
    maxHeight: '96%',
    backgroundColor: colors.surface,
    borderRadius: radius.xl,
    padding: 0,
    borderWidth: 1,
    borderColor: colors.border,
    overflow: 'hidden',
    ...shadows.card
  },
  productModalHeader: {
    minHeight: 74,
    borderTopWidth: 5,
    borderTopColor: colors.accent,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.lg,
    backgroundColor: colors.surface
  },
  productModalHeaderText: {
    flex: 1
  },
  productModalBody: {
    flex: 1,
    minHeight: 0,
    flexDirection: 'row',
    gap: spacing.lg,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.lg,
    backgroundColor: colors.background
  },
  productModalPreview: {
    width: 340,
    gap: spacing.md
  },
  productModalOptions: {
    flex: 1,
    minHeight: 0
  },
  productModalOptionsContent: {
    paddingBottom: spacing.xxl + 96
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: spacing.lg,
    marginBottom: spacing.md
  },
  modalTitle: {
    color: colors.text,
    fontSize: 26,
    lineHeight: 32,
    fontWeight: '900'
  },
  modalSubtitle: {
    color: colors.accent,
    fontSize: 20,
    fontWeight: '900',
    marginTop: spacing.xs
  },
  closeButton: {
    minHeight: 40,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.md
  },
  closeButtonText: {
    color: colors.primary,
    fontWeight: '800'
  },
  modalImageFrame: {
    width: '100%',
    height: 238,
    borderRadius: radius.lg,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md
  },
  modalImage: {
    width: '100%',
    height: '100%'
  },
  modalImageFallback: {
    flex: 1,
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.productImageSurface
  },
  modalImageFallbackText: {
    color: colors.muted,
    fontSize: 14,
    fontWeight: '900'
  },
  modalPricePanel: {
    minHeight: 84,
    borderRadius: radius.lg,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.lg,
    justifyContent: 'center',
    ...shadows.soft
  },
  modalPriceLabel: {
    color: colors.muted,
    fontSize: 11,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  modalTag: {
    alignSelf: 'flex-start',
    color: colors.warning,
    backgroundColor: colors.warningSoft,
    borderRadius: radius.sm,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    fontSize: 12,
    fontWeight: '900',
    marginTop: spacing.sm
  },
  modalDescription: {
    color: colors.muted,
    fontSize: 14,
    lineHeight: 20,
    fontWeight: '700'
  },
  sectionLabel: {
    color: colors.text,
    fontSize: 14,
    fontWeight: '900',
    marginTop: spacing.md,
    marginBottom: spacing.sm
  },
  sizeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm
  },
  sizeButton: {
    minWidth: 112,
    minHeight: 64,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surfaceMuted,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.md
  },
  sizeButtonSelected: {
    borderColor: colors.accent,
    backgroundColor: colors.accentSoft
  },
  sizeText: {
    color: colors.text,
    fontSize: 15,
    fontWeight: '900'
  },
  sizePrice: {
    color: colors.muted,
    fontSize: 13,
    fontWeight: '700',
    marginTop: spacing.xs
  },
  sizeTextSelected: {
    color: colors.accent
  },
  quantityRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md
  },
  quantityButton: {
    width: 50,
    height: 46,
    borderRadius: radius.md,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center'
  },
  quantityButtonText: {
    color: colors.primary,
    fontSize: 26,
    fontWeight: '900'
  },
  quantityText: {
    minWidth: 84,
    textAlign: 'center',
    color: colors.text,
    fontSize: 24,
    fontWeight: '900'
  },
  fractionCountRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm
  },
  fractionCountButton: {
    minHeight: 42,
    minWidth: 118,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surfaceMuted,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.md
  },
  fractionCountButtonSelected: {
    backgroundColor: colors.accentSoft,
    borderColor: colors.accent
  },
  fractionCountText: {
    color: colors.text,
    fontWeight: '900'
  },
  fractionCountTextSelected: {
    color: colors.accent
  },
  fractionSlot: {
    marginTop: spacing.md,
    gap: spacing.sm
  },
  fractionSlotTitle: {
    color: colors.muted,
    fontSize: 13,
    fontWeight: '900'
  },
  fractionFlavorScroller: {
    minHeight: 88,
    maxHeight: 88
  },
  fractionFlavorRow: {
    flexDirection: 'row',
    gap: spacing.sm,
    paddingRight: spacing.sm,
    paddingBottom: spacing.sm
  },
  fractionFlavorButton: {
    width: 150,
    minHeight: 74,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surfaceMuted,
    padding: spacing.sm,
    justifyContent: 'space-between'
  },
  fractionFlavorButtonSelected: {
    backgroundColor: colors.accentSoft,
    borderColor: colors.accent
  },
  fractionFlavorButtonDisabled: {
    opacity: 0.42
  },
  fractionFlavorText: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '900'
  },
  fractionFlavorPrice: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: '800'
  },
  fractionFlavorTextSelected: {
    color: colors.accent
  },
  optionalGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm
  },
  optionalButton: {
    width: '31.8%',
    minHeight: 112,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surfaceMuted,
    padding: spacing.sm,
    justifyContent: 'space-between'
  },
  optionalButtonSelected: {
    backgroundColor: colors.accentSoft,
    borderColor: colors.accent
  },
  optionalText: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '800'
  },
  optionalPrice: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: '800'
  },
  optionalStepper: {
    height: 34,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.xs
  },
  optionalStepButton: {
    width: 34,
    height: 34,
    borderRadius: radius.sm,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center'
  },
  optionalStepButtonDisabled: {
    backgroundColor: colors.border
  },
  optionalStepText: {
    color: colors.surface,
    fontSize: 18,
    fontWeight: '900'
  },
  optionalQtyText: {
    minWidth: 28,
    color: colors.text,
    fontSize: 16,
    textAlign: 'center',
    fontWeight: '900'
  },
  optionalTextSelected: {
    color: colors.accent
  },
  observationInput: {
    minHeight: 76,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
    padding: spacing.md,
    color: colors.text,
    textAlignVertical: 'top',
    fontSize: 15
  },
  warningBox: {
    marginTop: spacing.md,
    borderRadius: radius.md,
    backgroundColor: colors.warningSoft,
    borderWidth: 1,
    borderColor: '#ffd79a',
    padding: spacing.md
  },
  warningText: {
    color: colors.warning,
    fontWeight: '800'
  },
  modalFooter: {
    flexShrink: 0,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    minHeight: 82,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.md,
    backgroundColor: colors.surface,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.lg
  },
  modalTotal: {
    color: colors.text,
    fontSize: 26,
    fontWeight: '900'
  },
  banner: {
    position: 'absolute',
    left: spacing.lg,
    right: spacing.lg,
    bottom: spacing.lg,
    minHeight: 48,
    borderRadius: radius.md,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.lg
  },
  bannerText: {
    color: colors.surface,
    fontWeight: '800',
    fontSize: 15,
    textAlign: 'center'
  },
  noticeBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(9, 20, 32, 0.58)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.xl
  },
  noticeCard: {
    width: 420,
    maxWidth: '92%',
    borderRadius: radius.lg,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.xl,
    alignItems: 'center',
    ...shadows.card
  },
  noticeBadge: {
    width: 58,
    height: 58,
    borderRadius: radius.lg,
    backgroundColor: colors.dangerSoft,
    borderWidth: 1,
    borderColor: '#ffbbb5',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md
  },
  noticeBadgeText: {
    color: colors.danger,
    fontSize: 30,
    lineHeight: 34,
    fontWeight: '900'
  },
  noticeTitle: {
    color: colors.text,
    fontSize: 24,
    lineHeight: 30,
    fontWeight: '900',
    textAlign: 'center'
  },
  noticeText: {
    color: colors.muted,
    fontSize: 17,
    lineHeight: 24,
    fontWeight: '700',
    textAlign: 'center',
    marginTop: spacing.sm
  },
  noticeActions: {
    marginTop: spacing.lg
  },
  dialogBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(9, 20, 32, 0.62)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.xl
  },
  dialogCard: {
    width: 560,
    maxWidth: '92%',
    borderRadius: radius.xl,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    overflow: 'hidden',
    ...shadows.card
  },
  dialogTopLine: {
    height: 7,
    backgroundColor: colors.accent
  },
  dialogHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingHorizontal: spacing.xl,
    paddingTop: spacing.xl
  },
  dialogIcon: {
    width: 58,
    height: 58,
    borderRadius: radius.md,
    backgroundColor: colors.primarySoft,
    borderWidth: 1,
    borderColor: colors.borderStrong,
    alignItems: 'center',
    justifyContent: 'center'
  },
  dialogIconDanger: {
    backgroundColor: colors.dangerSoft,
    borderColor: '#f4b8bf'
  },
  dialogIconWarning: {
    backgroundColor: colors.warningSoft,
    borderColor: '#f7c784'
  },
  dialogIconSuccess: {
    backgroundColor: colors.successSoft,
    borderColor: '#a8dfbf'
  },
  dialogIconText: {
    color: colors.primary,
    fontSize: 24,
    lineHeight: 28,
    fontWeight: '900'
  },
  dialogIconTextDanger: {
    color: colors.danger
  },
  dialogIconTextWarning: {
    color: colors.warning
  },
  dialogIconTextSuccess: {
    color: colors.success,
    fontSize: 17,
    lineHeight: 21
  },
  dialogTitleBox: {
    flex: 1
  },
  dialogEyebrow: {
    color: colors.accent,
    fontSize: 12,
    lineHeight: 16,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  dialogTitle: {
    color: colors.text,
    fontSize: 27,
    lineHeight: 32,
    fontWeight: '900',
    marginTop: 2
  },
  dialogMessage: {
    color: colors.muted,
    fontSize: 18,
    lineHeight: 27,
    fontWeight: '700',
    marginTop: spacing.lg,
    paddingHorizontal: spacing.xl
  },
  dialogActions: {
    marginTop: spacing.xl,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    backgroundColor: '#f8fbfd',
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.lg,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.md
  },
  busyOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(244, 247, 250, 0.72)',
    alignItems: 'center',
    justifyContent: 'center'
  },
  busyBox: {
    minWidth: 240,
    minHeight: 132,
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.md,
    padding: spacing.lg,
    ...shadows.card
  },
  busyText: {
    color: colors.text,
    fontWeight: '800'
  }
});
