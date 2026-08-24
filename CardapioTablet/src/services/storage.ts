import AsyncStorage from '@react-native-async-storage/async-storage';

import type { CartItem, PendingOrder, TabletDiagnostics, TabletSession, TabletSettings } from '../types';
import { DEFAULT_API_BASE_URL, normalizeApiBaseUrl } from './network';

const SETTINGS_KEY = '@lemovel-cardapio-tablet:v1:settings';
const SESSION_KEY = '@lemovel-cardapio-tablet:v1:session';
const PENDING_ORDERS_KEY = '@lemovel-cardapio-tablet:v1:pending-orders';
const DIAGNOSTICS_KEY = '@lemovel-cardapio-tablet:v1:diagnostics';

export const defaultTabletSettings: TabletSettings = {
  baseUrl: DEFAULT_API_BASE_URL,
  empresaId: 1,
  mesaNumero: 1,
  terminalName: 'TABLET-MESA-1',
  pollingMs: 10000,
  cobrarMaiorValorFracionado: false,
  configured: false,
  utilizaCardapioTablet: false
};

function parseNumber(value: unknown, fallback: number): number {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Number(value.replace(',', '.'));
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function sanitizeSettings(value: Partial<TabletSettings> | null | undefined): TabletSettings {
  const mesaNumero = Math.max(1, Math.trunc(parseNumber(value?.mesaNumero, defaultTabletSettings.mesaNumero)));
  const terminalName = String(value?.terminalName || `TABLET-MESA-${mesaNumero}`).trim() || `TABLET-MESA-${mesaNumero}`;

  return {
    baseUrl: normalizeApiBaseUrl(value?.baseUrl, defaultTabletSettings.baseUrl),
    empresaId: Math.max(1, Math.trunc(parseNumber(value?.empresaId, defaultTabletSettings.empresaId))),
    mesaNumero,
    terminalName,
    pollingMs: 10000,
    cobrarMaiorValorFracionado: Boolean(value?.cobrarMaiorValorFracionado),
    configured: Boolean(value?.configured),
    utilizaCardapioTablet:
      typeof value?.utilizaCardapioTablet === 'boolean'
        ? value.utilizaCardapioTablet
        : defaultTabletSettings.utilizaCardapioTablet
  };
}

export async function loadTabletSettings(): Promise<TabletSettings> {
  try {
    const raw = await AsyncStorage.getItem(SETTINGS_KEY);
    if (!raw) return defaultTabletSettings;
    return sanitizeSettings(JSON.parse(raw) as Partial<TabletSettings>);
  } catch {
    return defaultTabletSettings;
  }
}

export async function saveTabletSettings(settings: TabletSettings): Promise<TabletSettings> {
  const normalized = sanitizeSettings({
    ...settings,
    configured: true
  });
  await AsyncStorage.setItem(SETTINGS_KEY, JSON.stringify(normalized));
  return normalized;
}

export async function loadTabletSession(): Promise<TabletSession | null> {
  try {
    const raw = await AsyncStorage.getItem(SESSION_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as TabletSession;
    if (!parsed || Number(parsed.idVenda || 0) <= 0 || Number(parsed.idMesa || 0) <= 0) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

export async function saveTabletSession(session: TabletSession): Promise<void> {
  await AsyncStorage.setItem(SESSION_KEY, JSON.stringify(session));
}

export async function clearTabletSession(): Promise<void> {
  await AsyncStorage.removeItem(SESSION_KEY);
}

export function buildPendingOrderQueueId(session: TabletSession, items: CartItem[]): string {
  const itemToken = items
    .map((item) => item.lineId)
    .filter(Boolean)
    .sort()
    .join('|');
  return `mesa-${session.mesaNumero}:venda-${session.idVenda}:${itemToken}`;
}

function sanitizePendingOrder(value: Partial<PendingOrder> | null | undefined): PendingOrder | null {
  if (!value?.session || !Array.isArray(value.items) || value.items.length === 0) {
    return null;
  }

  const queueId = String(value.queueId || buildPendingOrderQueueId(value.session, value.items)).trim();
  if (!queueId) return null;

  return {
    queueId,
    createdAt: String(value.createdAt || new Date().toISOString()),
    updatedAt: String(value.updatedAt || value.createdAt || new Date().toISOString()),
    attempts: Math.max(0, Math.trunc(parseNumber(value.attempts, 0))),
    lastError: value.lastError ? String(value.lastError) : undefined,
    session: value.session,
    settings: sanitizeSettings(value.settings),
    items: value.items,
    total: parseNumber(value.total, 0)
  };
}

export async function loadPendingOrders(): Promise<PendingOrder[]> {
  try {
    const raw = await AsyncStorage.getItem(PENDING_ORDERS_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as Array<Partial<PendingOrder>>;
    if (!Array.isArray(parsed)) return [];
    return parsed.map(sanitizePendingOrder).filter((item): item is PendingOrder => Boolean(item));
  } catch {
    return [];
  }
}

async function savePendingOrders(orders: PendingOrder[]): Promise<PendingOrder[]> {
  const sanitized = orders.map(sanitizePendingOrder).filter((item): item is PendingOrder => Boolean(item));
  await AsyncStorage.setItem(PENDING_ORDERS_KEY, JSON.stringify(sanitized));
  return sanitized;
}

export async function enqueuePendingOrder(order: PendingOrder): Promise<PendingOrder[]> {
  const current = await loadPendingOrders();
  const now = new Date().toISOString();
  const normalized = sanitizePendingOrder({
    ...order,
    updatedAt: now
  });
  if (!normalized) return current;

  const existingIndex = current.findIndex((item) => item.queueId === normalized.queueId);
  if (existingIndex >= 0) {
    current[existingIndex] = {
      ...current[existingIndex],
      ...normalized,
      createdAt: current[existingIndex].createdAt,
      attempts: current[existingIndex].attempts,
      updatedAt: now
    };
    return savePendingOrders(current);
  }

  return savePendingOrders([...current, normalized]);
}

export async function updatePendingOrder(queueId: string, patch: Partial<PendingOrder>): Promise<PendingOrder[]> {
  const now = new Date().toISOString();
  const current = await loadPendingOrders();
  return savePendingOrders(
    current.map((item) =>
      item.queueId === queueId
        ? {
            ...item,
            ...patch,
            updatedAt: now
          }
        : item
    )
  );
}

export async function removePendingOrder(queueId: string): Promise<PendingOrder[]> {
  const current = await loadPendingOrders();
  return savePendingOrders(current.filter((item) => item.queueId !== queueId));
}

function sanitizeDiagnostics(value: Partial<TabletDiagnostics> | null | undefined): TabletDiagnostics {
  return {
    lastSyncAt: value?.lastSyncAt ? String(value.lastSyncAt) : undefined,
    lastSyncOk: typeof value?.lastSyncOk === 'boolean' ? value.lastSyncOk : undefined,
    lastSyncError: value?.lastSyncError ? String(value.lastSyncError) : undefined,
    lastCatalogAt: value?.lastCatalogAt ? String(value.lastCatalogAt) : undefined,
    lastCatalogSource: value?.lastCatalogSource === 'api' ? 'api' : undefined,
    lastPingAt: value?.lastPingAt ? String(value.lastPingAt) : undefined,
    lastPingOk: typeof value?.lastPingOk === 'boolean' ? value.lastPingOk : undefined,
    lastPingMs: value?.lastPingMs !== undefined ? Math.max(0, Math.trunc(parseNumber(value.lastPingMs, 0))) : undefined,
    lastSendAt: value?.lastSendAt ? String(value.lastSendAt) : undefined,
    lastSendOk: typeof value?.lastSendOk === 'boolean' ? value.lastSendOk : undefined,
    lastSendError: value?.lastSendError ? String(value.lastSendError) : undefined,
    lastModuleCheckAt: value?.lastModuleCheckAt ? String(value.lastModuleCheckAt) : undefined,
    utilizaCardapioTablet:
      typeof value?.utilizaCardapioTablet === 'boolean' ? value.utilizaCardapioTablet : undefined,
    pendingOrderCount:
      value?.pendingOrderCount !== undefined
        ? Math.max(0, Math.trunc(parseNumber(value.pendingOrderCount, 0)))
        : undefined
  };
}

export async function loadTabletDiagnostics(): Promise<TabletDiagnostics> {
  try {
    const raw = await AsyncStorage.getItem(DIAGNOSTICS_KEY);
    if (!raw) return {};
    return sanitizeDiagnostics(JSON.parse(raw) as Partial<TabletDiagnostics>);
  } catch {
    return {};
  }
}

export async function saveTabletDiagnostics(value: TabletDiagnostics): Promise<TabletDiagnostics> {
  const normalized = sanitizeDiagnostics(value);
  await AsyncStorage.setItem(DIAGNOSTICS_KEY, JSON.stringify(normalized));
  return normalized;
}
