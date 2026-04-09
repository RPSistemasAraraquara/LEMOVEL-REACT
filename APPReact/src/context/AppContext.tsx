import React, { createContext, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { AppState as RNAppState, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  api,
  Category,
  defaultMobileSettings,
  hasConflictingOpeningSettings,
  LaunchItemPayload,
  loadMobileSettings,
  MobileAppSettings,
  MenuItem,
  OPENING_SETTINGS_CONFLICT_MESSAGE,
  saveMobileSettings,
  TableOrder,
  UserProfile
} from '../services/api';

type DashboardMode = 'mesa' | 'comanda' | 'mesaComanda';

export type LaunchOptional = {
  idOpcional: number;
  descricao: string;
  valor: number;
  gratis: boolean;
};

export type CartItem = Omit<MenuItem, 'opcionais'> & {
  lineId: string;
  quantidade: number;
  descricaoTamanho: string;
  tamanho: string;
  desconto: number;
  acrescimo: number;
  observacao?: string;
  idMesaVinculada: number;
  fractionGroupId?: string;
  valorUnitario: number;
  opcionais: LaunchOptional[];
};

type AppContextState = {
  baseUrl: string;
  apiConnection: {
    ok: boolean;
    checking: boolean;
    status?: number;
    message: string;
    payloadType: 'json' | 'text' | 'empty';
    lastChecked?: string;
  };
  appSettings: MobileAppSettings;
  settingsReady: boolean;
  user: UserProfile | null;
  loading: boolean;
  tables: TableOrder[];
  categories: Category[];
  products: MenuItem[];
  syncStatus: 'idle' | 'running' | 'success' | 'error';
  lastSyncAt?: string;
  selectedCategoryId: number | null;
  initialScreenMode: 'mesa' | 'comanda';
  cart: CartItem[];
  activeTable: TableOrder | null;
  linkedMesaSelection: TableOrder | null;
  hasActiveTable: boolean;
  hasOpenSale: boolean;
  ensureActiveTable: () => TableOrder;
  ensureOpenSale: () => TableOrder;
  login: (login: string, senha: string) => Promise<UserProfile>;
  refreshCurrentUserPermissions: () => Promise<void>;
  refreshDashboard: (
    forcedMode?: 'mesa' | 'comanda' | 'mesaComanda',
    options?: { force?: boolean }
  ) => Promise<void>;
  refreshMenu: () => Promise<void>;
  addToCart: (item: Omit<CartItem, 'lineId'>) => void;
  removeFromCart: (lineId: string) => void;
  clearCart: () => void;
  setBaseUrl: (url: string) => void;
  setEmpresaId: (id: number) => void;
  setAppSettings: (settings: MobileAppSettings) => void;
  saveAppSettings: (settings: MobileAppSettings) => Promise<void>;
  setSelectedCategoryId: (id: number | null) => void;
  setInitialScreenMode: (mode: 'mesa' | 'comanda') => void;
  openTableByCard: (
    tableId: number,
    nomeMesaComanda?: string,
    tableTypeHint?: 'mesa' | 'comanda'
  ) => Promise<TableOrder>;
  setActiveTable: (table: TableOrder | null) => void;
  setLinkedMesaSelection: (table: TableOrder | null) => void;
  checkApiConnection: (timeoutMs?: number) => Promise<ApiConnectionStatus>;
  checkoutCart: () => Promise<void>;
  flushPendingItems: () => Promise<boolean>;
  getLinkedTableId: (table?: TableOrder | null) => number;
  getLineTotal: (item: CartItem) => number;
  getCartTotal: () => number;
  logout: () => void;
  pauseAutoRefresh: () => void;
  resumeAutoRefresh: () => void;
};

const isDefaultTableDisplayName = (
  value: string | undefined,
  tableId: number,
  tableTypeHint?: 'mesa' | 'comanda'
) => {
  const normalized = String(value || '').trim().toLowerCase();
  if (!normalized) return false;

  const match = normalized.match(/^(mesa|comanda)\s+0*(\d+)$/i);
  if (!match) return false;

  const labelType = match[1] as 'mesa' | 'comanda';
  const numericId = Number(match[2] || 0);
  if (!Number.isFinite(numericId) || numericId !== Number(tableId || 0)) {
    return false;
  }

  if (tableTypeHint && labelType !== tableTypeHint) {
    return false;
  }

  return true;
};

const AppContext = createContext<AppContextState | undefined>(undefined);

export const useApp = () => {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp precisa estar dentro de AppProvider');
  return ctx;
};

const isPresent = (value: unknown): boolean => value !== undefined && value !== null;

const roundTo2 = (value: number) => Number(Number(value).toFixed(2));

type DashboardRefreshWaiter = {
  resolve: () => void;
  reject: (error: unknown) => void;
};

type PartialPaymentCacheEntry = {
  total: number;
  fetchedAt: number;
};

export type ApiConnectionStatus = {
  ok: boolean;
  checking: boolean;
  status?: number;
  message: string;
  payloadType: 'json' | 'text' | 'empty';
  lastChecked?: string;
};
const defaultConnectionState: ApiConnectionStatus = {
  ok: false,
  checking: false,
  status: undefined,
  message: 'Não verificada',
  payloadType: 'empty'
};

const isLocalhostUrl = (value: string) => /(^https?:\/\/)(localhost|127\.0\.0\.1)(:\d+)?(\/.*)?/i.test(value.trim());

const normalizeAndroidLocalhost = (baseUrl: string) => {
  if (Platform.OS !== 'android') return baseUrl;
  if (!isLocalhostUrl(baseUrl)) return baseUrl;
  return baseUrl.replace(/localhost|127\.0\.0\.1/gi, '10.0.2.2');
};

const normalizeBaseUrl = (value: string) => {
  const trimmed = value.trim().replace(/\/+$/, '');
  if (!trimmed) return defaultMobileSettings.baseUrl;
  if (/^https?:\/\//i.test(trimmed)) {
    return trimmed;
  }
  return `http://${trimmed}`;
};
const AUTO_REFRESH_INTERVAL_MS = 7000;
const AUTO_REFRESH_THROTTLE_MS = 1200;
const AUTO_MENU_REFRESH_THROTTLE_MS = 5000;
const PARTIAL_PAYMENT_TOTAL_TTL_MS = 4500;
const INITIAL_SCREEN_MODE_STORAGE_KEY = '@rpcheff_mobile:last_initial_screen_mode';

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [baseUrl, setBaseUrlState] = useState(defaultMobileSettings.baseUrl);
  const [empresaId, setEmpresaIdState] = useState(defaultMobileSettings.empresaId);
  const [appSettings, setAppSettingsState] = useState<MobileAppSettings>(defaultMobileSettings);
  const [settingsReady, setSettingsReady] = useState(false);
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(false);
  const [tables, setTables] = useState<TableOrder[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<MenuItem[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | null>(null);
  const [initialScreenMode, setInitialScreenModeState] = useState<'mesa' | 'comanda'>(
    defaultMobileSettings.modoExibicao === 'comanda' ? 'comanda' : 'mesa'
  );
  const [cart, setCart] = useState<CartItem[]>([]);
  const [activeTable, setActiveTableState] = useState<TableOrder | null>(null);
  const [linkedMesaSelection, setLinkedMesaSelectionState] = useState<TableOrder | null>(null);
  const [apiConnection, setApiConnection] = useState(defaultConnectionState);
  const [syncStatus, setSyncStatus] = useState<'idle' | 'running' | 'success' | 'error'>('idle');
  const [lastSyncAt, setLastSyncAt] = useState<string | undefined>(undefined);
  const isAppActiveRef = useRef(true);
  const syncTimerRef = React.useRef<ReturnType<typeof setTimeout> | null>(null);
  const refreshInFlightRef = useRef<Promise<void> | null>(null);
  const lastDashboardRefreshAtRef = useRef(0);
  const refreshQueueModeRef = useRef<DashboardMode | null>(null);
  const refreshQueueTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const refreshQueuePromiseRef = useRef<Promise<void> | null>(null);
  const refreshQueueWaitersRef = useRef<DashboardRefreshWaiter[]>([]);
  const refreshMenuInFlightRef = useRef<Promise<void> | null>(null);
  const refreshMenuQueueTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const refreshMenuQueuePromiseRef = useRef<Promise<void> | null>(null);
  const refreshMenuWaitersRef = useRef<DashboardRefreshWaiter[]>([]);
  const lastMenuRefreshAtRef = useRef(0);
  const partialPaymentTotalsRef = useRef<Record<number, PartialPaymentCacheEntry>>({});
  const tablesFingerprintRef = useRef('');
  const categoriesFingerprintRef = useRef('');
  const productsFingerprintRef = useRef('');
  const tablesRef = useRef<TableOrder[]>([]);
  const cartRef = useRef<CartItem[]>([]);
  const activeTableRef = useRef<TableOrder | null>(null);
  const userRef = useRef<UserProfile | null>(null);
  const isSyncRunningRef = useRef(false);
  const syncErrorCountRef = useRef(0);
  const pendingSyncErrorCountRef = useRef(0);
  const flushPendingInFlightRef = useRef<Promise<boolean> | null>(null);
  const retryPendingAfterFailureRef = useRef(false);
  const autoRefreshPauseRef = useRef(0);
  const hasActiveTable = Boolean(activeTable);
  const hasOpenSale = Boolean(activeTable?.idVenda && activeTable.idVenda !== 0);

  useEffect(() => {
    void (async () => {
      try {
        const settings = await loadMobileSettings();
        syncSettingsToApi(settings);
      } catch {
        syncSettingsToApi(defaultMobileSettings);
      } finally {
        setSettingsReady(true);
      }
    })();
  }, []);

  useEffect(() => {
    void (async () => {
      try {
        const storedMode = await AsyncStorage.getItem(INITIAL_SCREEN_MODE_STORAGE_KEY);
        if (storedMode === 'comanda' || storedMode === 'mesa') {
          setInitialScreenModeState(storedMode);
        }
      } catch {
        // Mantem o padrao local quando nao consegue restaurar o ultimo modo.
      }
    })();
  }, []);

  useEffect(() => {
    void AsyncStorage.setItem(INITIAL_SCREEN_MODE_STORAGE_KEY, initialScreenMode).catch(() => null);
  }, [initialScreenMode]);

  const syncSettingsToApi = (settings: MobileAppSettings) => {
    const normalizedUrl = normalizeBaseUrl(settings.baseUrl);
    const normalized: MobileAppSettings = {
      ...settings,
      baseUrl: normalizeAndroidLocalhost(normalizedUrl),
      empresaId: settings.empresaId || 1
    };
    setBaseUrlState(normalized.baseUrl);
    setEmpresaIdState(normalized.empresaId);
    setAppSettingsState(normalized);
    api.setBaseUrl(normalized.baseUrl);
    api.setEmpresa(normalized.empresaId);
  };

  const checkApiConnection = async (timeoutMs?: number): Promise<ApiConnectionStatus> => {
    setApiConnection((prev) => ({ ...prev, checking: true }));
    let next: ApiConnectionStatus;
    try {
      const result = await api.testApiConnection({ timeoutMs });
      next = {
        ok: result.ok,
        checking: false,
        status: result.status,
        message: result.message,
        payloadType: result.payloadType,
        lastChecked: new Date().toISOString()
      };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Erro desconhecido';
      next = {
        ok: false,
        checking: false,
        status: 0,
        message,
        payloadType: 'text',
        lastChecked: new Date().toISOString()
      };
    }
    setApiConnection(next);
    return next;
  };

  useEffect(() => {
    if (!settingsReady) {
      return;
    }

    void checkApiConnection().catch(() => null);
  }, [settingsReady, baseUrl, empresaId]);

  const ensureActiveTable = () => {
    if (!activeTable) {
      throw new Error('Selecione uma mesa antes de continuar.');
    }
    return activeTable;
  };

  const ensureOpenSale = () => {
    const table = ensureActiveTable();
    if (!table.idVenda) {
      throw new Error('Mesa sem venda aberta. Abra a mesa na aba Mesas antes de lançar.');
    }
    return table;
  };

  const getLinkedTableId = (table?: TableOrder | null) => {
    const source = table || activeTable;
    if (!source) return 0;
    if (source.tipo === 'comanda' && isPresent(source.idComanda) && Number(source.idComanda) > 0) {
      return Number(source.idComanda);
    }
    if (isPresent(source.idComanda) && Number(source.idComanda) > 0) {
      return Number(source.idComanda);
    }
    return Number(source.idMesa || 0);
  };

  const getTableFingerprint = (table: TableOrder) => {
    const total = Number(table.valorTotal ?? table.venda?.valorTotal ?? 0).toFixed(2);
    const vendaTotal = Number(table.venda?.valorTotal ?? 0).toFixed(2);
    const pagamentoAntecipado = Number(table.venda?.valorPagamentoAntecipado ?? 0).toFixed(2);
    const valorRestante = Number(
      Math.max(0, Number(table.valorTotal ?? table.venda?.valorTotal ?? 0) - Number(table.venda?.valorPagamentoAntecipado ?? 0))
    ).toFixed(2);
    return [
      table.idMesa || 0,
      table.idComanda || 0,
      table.tipo || '',
      table.nomeMesaComanda || '',
      table.situacao || '',
      table.venda?.situacao || '',
      table.statusCode || '',
      table.statusOriginal || '',
      table.idVenda || 0,
      total,
      vendaTotal,
      pagamentoAntecipado,
      valorRestante
    ].join('|');
  };

  const getTableIdentityKey = (table: Pick<TableOrder, 'tipo' | 'idMesa' | 'idComanda'>) =>
    `${table.tipo || 'mesa'}-${Number(table.idComanda || 0)}-${Number(table.idMesa || 0)}`;

  const isSameTableIdentity = (
    left: Pick<TableOrder, 'tipo' | 'idMesa' | 'idComanda'>,
    right: Pick<TableOrder, 'tipo' | 'idMesa' | 'idComanda'>
  ) => getTableIdentityKey(left) === getTableIdentityKey(right);

  const tablesFingerprint = (list: TableOrder[]) =>
    [...list]
      .sort((a, b) => getTableIdentityKey(a).localeCompare(getTableIdentityKey(b)))
      .map(getTableFingerprint)
      .join('::');

  const categoriesFingerprint = (list: Category[]) =>
    [...list]
      .sort((a, b) => a.id - b.id)
      .map((item) => `${item.id}|${item.descricao}`)
      .join('|');

  const productsFingerprint = (list: MenuItem[]) =>
    [...list]
      .sort((a, b) => a.id - b.id)
      .map(
        (item) =>
          `${item.id}|${item.valorVenda}|${item.descricao}|${item.vendaPorTamanho ? 1 : 0}|${item.permiteFracao ? 1 : 0}|${item.possuiImagem ? 1 : 0}|${item.imagem ? item.imagem.length : 0}|${item.imagem_db ? item.imagem_db.length : 0}|${item.imagemLocalPath ? item.imagemLocalPath.length : 0}|${(item.opcionais || [])
            .map(
              (optional) =>
                `${optional.idOpcional}:${optional.descricao}:${optional.valor}:${optional.opcionalP || ''}:${optional.opcionalM || ''}:${optional.opcionalG || ''}:${optional.opcionalGG || ''}:${optional.opcionalExtra || ''}`
            )
            .join(',')}`
      )
      .join('|');

  const applyCachedPartialPaymentTotals = (list: TableOrder[]) => {
    const now = Date.now();
    return list.map((table) => {
      const idVenda = Number(table.idVenda || table.venda?.idVenda || 0);
      if (!idVenda) {
        return table;
      }

      const cached = partialPaymentTotalsRef.current[idVenda];
      const cachedTotal = cached && now - cached.fetchedAt < PARTIAL_PAYMENT_TOTAL_TTL_MS ? cached.total : 0;

      return {
        ...table,
        venda: {
          ...(table.venda || {}),
          idVenda,
          valorTotal: Number(table.venda?.valorTotal ?? table.valorTotal ?? 0),
          valorPagamentoAntecipado: Number(cachedTotal || 0)
        }
      };
    });
  };

  const enrichPartialPaymentTotals = async (list: TableOrder[], force = false) => {
    const saleIds = [...new Set(
      list
        .map((table) => Number(table.idVenda || table.venda?.idVenda || 0))
        .filter((idVenda) => idVenda > 0)
    )];

    if (saleIds.length === 0) {
      return applyCachedPartialPaymentTotals(list);
    }

    const now = Date.now();
    const totalsEntries = await Promise.all(
      saleIds.map(async (idVenda) => {
        const cached = partialPaymentTotalsRef.current[idVenda];
        if (cached && !force && now - cached.fetchedAt < PARTIAL_PAYMENT_TOTAL_TTL_MS) {
          return [idVenda, cached.total] as const;
        }

        try {
          const payments = await api.listPaymentsBySale(idVenda);
          const total = roundTo2(payments.reduce((acc, payment) => acc + Number(payment.valor || 0), 0));
          partialPaymentTotalsRef.current[idVenda] = {
            total,
            fetchedAt: Date.now()
          };
          return [idVenda, total] as const;
        } catch {
          return [idVenda, cached?.total || 0] as const;
        }
      })
    );

    const totalsBySale = Object.fromEntries(totalsEntries) as Record<number, number>;

    return list.map((table) => {
      const idVenda = Number(table.idVenda || table.venda?.idVenda || 0);
      if (!idVenda) {
        return table;
      }

      return {
        ...table,
        venda: {
          ...(table.venda || {}),
          idVenda,
          valorTotal: Number(table.venda?.valorTotal ?? table.valorTotal ?? 0),
          valorPagamentoAntecipado: Number(totalsBySale[idVenda] || 0)
        }
      };
    });
  };

  const optionTotal = (item: Pick<CartItem, 'opcionais' | 'quantidade'>) => {
    return item.opcionais.reduce(
      (acc, optional) => acc + (optional.gratis ? 0 : optional.valor * item.quantidade),
      0
    );
  };

  const getLineTotal = (item: CartItem) => {
    const baseValue = item.valorUnitario * item.quantidade;
    const optionalValue = optionTotal(item);
    return roundTo2(baseValue + optionalValue + item.acrescimo - item.desconto);
  };

  const getCartTotal = () => roundTo2(cart.reduce((acc, it) => acc + getLineTotal(it), 0));

  const asPayload = (item: CartItem): LaunchItemPayload => ({
    idProduto: item.idProduto,
    quantidade: item.quantidade,
    valorUnitario: item.valorUnitario,
    valorTotal: getLineTotal(item),
    desconto: item.desconto,
    acrescimo: item.acrescimo,
    tamanho: item.tamanho,
    vendaPorTamanho: Boolean(item.vendaPorTamanho),
    descricaoTamanho: item.descricaoTamanho,
    observacao: item.observacao,
    idMesaVinculada: item.idMesaVinculada,
    idGarcom: user?.idUsuario || 0,
    opcionais: item.opcionais.map((optional) => ({
      idOpcional: optional.idOpcional,
      descricao: optional.descricao,
      valor: optional.valor,
      gratis: optional.gratis
    }))
  });

  const login = async (loginParam: string, senha: string) => {
    setLoading(true);
    try {
      const userProfile = await api.login(loginParam, senha);
      setUser(userProfile);
      if (appSettings.sincronizarAposLogin) {
        await api.syncAll().catch(() => null);
      }
      if (appSettings.salvarLoginSenha) {
        await saveAppSettings({
          ...appSettings,
          usuario: loginParam,
          senha: senha
        });
      }
      await refreshDashboard().catch(() => null);
      return userProfile;
    } finally {
      setLoading(false);
    }
  };

  const refreshCurrentUserPermissions = async () => {
    const currentUser = userRef.current;
    if (!currentUser) {
      return;
    }

    const users = await api.listUsers();
    if (!users.length) {
      return;
    }

    const currentLogin = String(currentUser.login || '').trim().toLowerCase();
    const updated =
      (currentLogin
        ? users.find((item) => String(item.login || '').trim().toLowerCase() === currentLogin)
        : undefined) ||
      users.find((item) => Number(item.idUsuario || 0) === Number(currentUser.idUsuario || 0));

    if (!updated) {
      return;
    }

    setUser((prev) => {
      if (!prev) {
        return prev;
      }

      if (
        Number(prev.idUsuario || 0) === Number(updated.idUsuario || 0) &&
        String(prev.nome || '') === String(updated.nome || '') &&
        String(prev.login || '') === String(updated.login || '') &&
        Boolean(prev.permiteCancelarItemMobile) === Boolean(updated.permiteCancelarItemMobile) &&
        Boolean(prev.permitePreFechamentoMesaComanda) === Boolean(updated.permitePreFechamentoMesaComanda) &&
        Boolean(prev.permiteFechamentoMesaComanda) === Boolean(updated.permiteFechamentoMesaComanda) &&
        Boolean(prev.permiteJuntarMesaComanda) === Boolean(updated.permiteJuntarMesaComanda) &&
        Boolean(prev.permiteReabrirMesaComanda) === Boolean(updated.permiteReabrirMesaComanda) &&
        Boolean(prev.permitePagamentoParcial) === Boolean(updated.permitePagamentoParcial) &&
        Boolean(prev.permiteDescontoFechamento) === Boolean(updated.permiteDescontoFechamento)
      ) {
        return prev;
      }

      return {
        ...prev,
        ...updated
      };
    });
  };

  const logout = () => {
    syncErrorCountRef.current = 0;
    pendingSyncErrorCountRef.current = 0;
    retryPendingAfterFailureRef.current = false;
    setSyncStatus('idle');
    setUser(null);
    setActiveTableState(null);
    setLinkedMesaSelectionState(null);
    setCart([]);
    setTables([]);
    setCategories([]);
    setProducts([]);
    setSelectedCategoryId(null);
  };

  const settleQueuedRefresh = (error?: unknown) => {
    if (!refreshQueuePromiseRef.current) return;

    const waiters = refreshQueueWaitersRef.current;
    refreshQueuePromiseRef.current = null;
    refreshQueueWaitersRef.current = [];

    if (error) {
      waiters.forEach(({ reject }) => reject(error));
      return;
    }

    waiters.forEach(({ resolve }) => resolve());
  };

  const addRefreshQueueWaiter = () => {
    if (!refreshQueuePromiseRef.current) {
      refreshQueuePromiseRef.current = new Promise<void>((resolve, reject) => {
        refreshQueueWaitersRef.current = [{ resolve, reject }];
      });
      return refreshQueuePromiseRef.current;
    }
    return refreshQueuePromiseRef.current;
  };

  const queueDashboardRefresh = (mode: DashboardMode, delayMs: number): Promise<void> => {
    const promise = addRefreshQueueWaiter();
    refreshQueueModeRef.current = mode;

    if (refreshQueueTimerRef.current) {
      clearTimeout(refreshQueueTimerRef.current);
    }

    refreshQueueTimerRef.current = setTimeout(() => {
      refreshQueueTimerRef.current = null;
      const nextMode = refreshQueueModeRef.current || mode;

      if (refreshInFlightRef.current) {
        refreshQueueModeRef.current = nextMode;
        return;
      }

      refreshQueueModeRef.current = null;
      refreshDashboard(nextMode, { force: true })
        .then(() => settleQueuedRefresh())
        .catch((error) => settleQueuedRefresh(error));
    }, delayMs);

    return promise;
  };

  const settleQueuedMenuRefresh = (error?: unknown) => {
    if (!refreshMenuQueuePromiseRef.current) return;

    const waiters = refreshMenuWaitersRef.current;
    refreshMenuQueuePromiseRef.current = null;
    refreshMenuWaitersRef.current = [];

    if (error) {
      waiters.forEach(({ reject }) => reject(error));
      return;
    }

    waiters.forEach(({ resolve }) => resolve());
  };

  const addRefreshMenuQueueWaiter = () => {
    if (!refreshMenuQueuePromiseRef.current) {
      refreshMenuQueuePromiseRef.current = new Promise<void>((resolve, reject) => {
        refreshMenuWaitersRef.current = [{ resolve, reject }];
      });
      return refreshMenuQueuePromiseRef.current;
    }
    return refreshMenuQueuePromiseRef.current;
  };

  const queueRefreshMenu = (delayMs: number): Promise<void> => {
    const promise = addRefreshMenuQueueWaiter();

    if (refreshMenuQueueTimerRef.current) {
      clearTimeout(refreshMenuQueueTimerRef.current);
    }

    refreshMenuQueueTimerRef.current = setTimeout(() => {
      refreshMenuQueueTimerRef.current = null;
      if (refreshMenuInFlightRef.current) {
        queueRefreshMenu(150);
        return;
      }

      refreshMenu()
        .then(() => settleQueuedMenuRefresh())
        .catch((error) => settleQueuedMenuRefresh(error));
    }, delayMs);

    return promise;
  };

  const refreshDashboard = async (
    forcedMode?: DashboardMode,
    options: { force?: boolean } = {}
  ) => {
    const mode = (forcedMode || appSettings.modoExibicao || 'mesa') as DashboardMode;

    if (refreshInFlightRef.current) {
      refreshQueueModeRef.current = mode;
      return refreshInFlightRef.current;
    }

    const now = Date.now();
    const shouldThrottle = !options.force && now - lastDashboardRefreshAtRef.current < AUTO_REFRESH_THROTTLE_MS;
    if (shouldThrottle) {
      return queueDashboardRefresh(mode, AUTO_REFRESH_THROTTLE_MS - (now - lastDashboardRefreshAtRef.current));
    }

    const refreshTask = (async () => {
      const rawList = await api.listTablesByMode(mode);
      const list = applyCachedPartialPaymentTotals(rawList);
      const nextFingerprint = tablesFingerprint(list);
      const currentFingerprint = tablesFingerprintRef.current;
      const shouldReplaceList = nextFingerprint !== currentFingerprint;

      setTables(shouldReplaceList ? list : [...list]);
      setActiveTableState((prev) => {
        if (!prev) return prev;
        const updated = list.find((item) => isSameTableIdentity(item, prev));
        if (!updated) return prev;
        if (
          prev.situacao === updated.situacao &&
          prev.statusCode === updated.statusCode &&
          prev.statusOriginal === updated.statusOriginal &&
          prev.idVenda === updated.idVenda &&
          prev.valorTotal === updated.valorTotal &&
          prev.nomeMesaComanda === updated.nomeMesaComanda &&
          prev.venda?.situacao === updated.venda?.situacao &&
          prev.venda?.valorPagamentoAntecipado === updated.venda?.valorPagamentoAntecipado
        ) {
          return prev;
        }
        return {
          ...updated,
          idVenda: isPresent(updated.idVenda) ? updated.idVenda : prev.idVenda
        };
      });

      void enrichPartialPaymentTotals(rawList, Boolean(options.force))
        .then((enrichedList) => {
          const enrichedFingerprint = tablesFingerprint(enrichedList);
          const currentEnrichedFingerprint = tablesFingerprintRef.current;
          const shouldReplaceEnriched = enrichedFingerprint !== currentEnrichedFingerprint;

          setTables(shouldReplaceEnriched ? enrichedList : [...enrichedList]);
          setActiveTableState((prev) => {
            if (!prev) return prev;
            const updated = enrichedList.find((item) => isSameTableIdentity(item, prev));
            if (!updated) return prev;
            if (
              prev.situacao === updated.situacao &&
              prev.statusCode === updated.statusCode &&
              prev.statusOriginal === updated.statusOriginal &&
              prev.idVenda === updated.idVenda &&
              prev.valorTotal === updated.valorTotal &&
              prev.nomeMesaComanda === updated.nomeMesaComanda &&
              prev.venda?.situacao === updated.venda?.situacao &&
              prev.venda?.valorPagamentoAntecipado === updated.venda?.valorPagamentoAntecipado
            ) {
              return prev;
            }
            return {
              ...updated,
              idVenda: isPresent(updated.idVenda) ? updated.idVenda : prev.idVenda
            };
          });
        })
        .catch(() => null);
    })();

    refreshInFlightRef.current = refreshTask;
    let executionError: unknown = null;
    try {
      await refreshTask;
      lastDashboardRefreshAtRef.current = Date.now();
    } catch (error) {
      executionError = error;
      throw error;
    } finally {
      refreshInFlightRef.current = null;
      const queuedMode = refreshQueueModeRef.current;
      refreshQueueModeRef.current = null;
      settleQueuedRefresh(executionError);

      if (!executionError && queuedMode) {
        setTimeout(() => {
          void refreshDashboard(queuedMode, { force: true }).catch(() => null);
        }, 0);
      }
    }
  };

  const refreshMenu = async () => {
    if (refreshMenuInFlightRef.current) {
      return queueRefreshMenu(0);
    }

    const now = Date.now();
    const timeSinceLastRefresh = now - lastMenuRefreshAtRef.current;
    if (timeSinceLastRefresh < AUTO_MENU_REFRESH_THROTTLE_MS) {
      return queueRefreshMenu(AUTO_MENU_REFRESH_THROTTLE_MS - timeSinceLastRefresh);
    }

    const refreshMenuTask = (async () => {
      const categoriesPromise = api.listCategories();
      const productsPromise = api.listProducts(false);

      const cats = await categoriesPromise;
      const categoryFingerprint = categoriesFingerprint(cats);
      const currentCategoryFingerprint = categoriesFingerprintRef.current;
      setCategories(currentCategoryFingerprint === categoryFingerprint ? categories : cats);

      const hasCategoryChanged = currentCategoryFingerprint !== categoryFingerprint;
      const categoryExists =
        selectedCategoryId !== null && cats.some((item) => item.id === selectedCategoryId);

      if (!hasCategoryChanged || !cats.length) {
        if (!categoryExists || !selectedCategoryId) {
          setSelectedCategoryId(cats[0]?.id ?? null);
        }
      } else if (!categoryExists) {
        setSelectedCategoryId(cats[0]?.id ?? null);
      } else if (!selectedCategoryId && cats.length > 0) {
        setSelectedCategoryId(cats[0].id);
      }

      const rawProducts = await productsPromise;
      const prod = rawProducts;
      const productFingerprint = productsFingerprint(prod);
      const currentProductFingerprint = productsFingerprintRef.current;
      setProducts(currentProductFingerprint === productFingerprint ? products : prod);
    })();

    refreshMenuInFlightRef.current = refreshMenuTask;
    let menuError: unknown = null;
    try {
      await refreshMenuTask;
      lastMenuRefreshAtRef.current = Date.now();
    } catch (error) {
      menuError = error;
      throw error;
    } finally {
      refreshMenuInFlightRef.current = null;
      settleQueuedMenuRefresh(menuError);
    }
  };

  const addToCart = (item: Omit<CartItem, 'lineId'>) => {
    const lineId = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
    setCart((prev) => [...prev, { ...item, lineId }]);
  };

  const removeFromCart = (lineId: string) => {
    setCart((prev) => {
      const selected = prev.find((item) => item.lineId === lineId);
      if (!selected) return prev;
      if (selected.fractionGroupId) {
        return prev.filter((item) => item.fractionGroupId !== selected.fractionGroupId);
      }
      return prev.filter((item) => item.lineId !== lineId);
    });
  };

  const clearCart = () => setCart([]);

  const setBaseUrl = (url: string) => {
    const cleanedUrl = normalizeBaseUrl(url);
    const normalizedUrl = normalizeAndroidLocalhost(cleanedUrl);
    setAppSettingsState((prev) => ({ ...prev, baseUrl: normalizedUrl }));
    setBaseUrlState(normalizedUrl);
    api.setBaseUrl(normalizedUrl);
  };

  const setEmpresaId = (id: number) => {
    setAppSettingsState((prev) => ({ ...prev, empresaId: id }));
    setEmpresaIdState(id);
    api.setEmpresa(id);
  };

  const setAppSettings = (settings: MobileAppSettings) => {
    syncSettingsToApi(settings);
  };

  const setInitialScreenMode = (mode: 'mesa' | 'comanda') => {
    setInitialScreenModeState(mode === 'comanda' ? 'comanda' : 'mesa');
  };

  const saveAppSettings = async (settings: MobileAppSettings) => {
    const normalized: MobileAppSettings = {
      ...appSettings,
      ...settings,
      empresaId: settings.empresaId || appSettings.empresaId || 1,
      baseUrl: settings.baseUrl?.trim() || appSettings.baseUrl
    };
    const sanitizedCredentials =
      normalized.salvarLoginSenha
        ? {
            usuario: String(normalized.usuario || '').trim(),
            senha: String(normalized.senha || '').trim()
          }
        : {
            usuario: '',
            senha: ''
          };
    const sanitized: MobileAppSettings = {
      ...normalized,
      ...sanitizedCredentials,
      baseUrl: normalized.baseUrl.trim()
    };

    if (hasConflictingOpeningSettings(sanitized)) {
      throw new Error(OPENING_SETTINGS_CONFLICT_MESSAGE);
    }

    syncSettingsToApi(sanitized);
    await saveMobileSettings(sanitized);
    await api.saveSettings(sanitized as Record<string, unknown>);
  };

  const setActiveTable = (table: TableOrder | null) => {
    if (activeTable && activeTable.idMesa !== table?.idMesa) {
      setCart([]);
    }
    if (!table) {
      setCart([]);
    }
    if (!table || table.tipo !== 'comanda') {
      setLinkedMesaSelectionState(null);
    } else if (!activeTable || !isSameTableIdentity(activeTable, table)) {
      setLinkedMesaSelectionState(null);
    }
    setActiveTableState(table);
  };

  const setLinkedMesaSelection = (table: TableOrder | null) => {
    if (!table || Number(table.idMesa || 0) <= 0) {
      setLinkedMesaSelectionState(null);
      return;
    }

    setLinkedMesaSelectionState({
      ...table,
      tipo: 'mesa',
      nomeMesaComanda: String(table.nomeMesaComanda || '').trim() || `Mesa ${Number(table.idMesa || 0)}`
    });
  };

  const isAutoRefreshAllowed = () => autoRefreshPauseRef.current <= 0;

  const pauseAutoRefresh = () => {
    autoRefreshPauseRef.current += 1;
    stopAutoRefresh();
  };

  const resumeAutoRefresh = () => {
    autoRefreshPauseRef.current = Math.max(0, autoRefreshPauseRef.current - 1);
    if (!isAutoRefreshAllowed() || !isAppActiveRef.current || !userRef.current) {
      return;
    }

    startAutoRefresh();
  };

  const stopAutoRefresh = () => {
    if (syncTimerRef.current) {
      clearTimeout(syncTimerRef.current);
      syncTimerRef.current = null;
    }
    if (refreshQueueTimerRef.current) {
      clearTimeout(refreshQueueTimerRef.current);
      refreshQueueTimerRef.current = null;
    }
    refreshQueueModeRef.current = null;
    settleQueuedRefresh(new Error('Sincronização interrompida'));
    if (refreshMenuQueueTimerRef.current) {
      clearTimeout(refreshMenuQueueTimerRef.current);
      refreshMenuQueueTimerRef.current = null;
    }
    settleQueuedMenuRefresh(new Error('Sincronização interrompida'));
  };

  const startAutoRefresh = () => {
    if (!isAutoRefreshAllowed()) return;

    stopAutoRefresh();

    const runLoop = async () => {
      if (!isAutoRefreshAllowed() || !isAppActiveRef.current || !userRef.current) return;
      if (isSyncRunningRef.current) {
        scheduleNextSync();
        return;
      }

      isSyncRunningRef.current = true;
      setSyncStatus('running');

      pendingSyncErrorCountRef.current = 0;
      retryPendingAfterFailureRef.current = false;

      let hasError = false;
      try {
        await refreshDashboard();
        syncErrorCountRef.current = 0;
      } catch {
        syncErrorCountRef.current += 1;
        hasError = true;
      }

      if (hasError) {
        setSyncStatus('error');
      } else {
        setSyncStatus('success');
        setLastSyncAt(new Date().toISOString());
      }

      isSyncRunningRef.current = false;
      scheduleNextSync();
    };

    const delayFromErrorCount = () => {
      const retryLevel = Math.max(syncErrorCountRef.current, pendingSyncErrorCountRef.current);
      if (retryLevel <= 1) return AUTO_REFRESH_INTERVAL_MS;
      if (retryLevel <= 3) return AUTO_REFRESH_INTERVAL_MS * 2;
      if (retryLevel <= 6) return AUTO_REFRESH_INTERVAL_MS * 3;
      return AUTO_REFRESH_INTERVAL_MS * 4;
    };

    const scheduleNextSync = () => {
      if (!isAutoRefreshAllowed() || !isAppActiveRef.current || !userRef.current) {
        return;
      }

      const delay = delayFromErrorCount();
      syncTimerRef.current = setTimeout(runLoop, delay);
    };

    runLoop();
  };

  React.useEffect(() => {
    const subscription = RNAppState.addEventListener('change', (nextState) => {
      isAppActiveRef.current = nextState === 'active';
      if (isAppActiveRef.current && userRef.current) {
        startAutoRefresh();
      } else {
        stopAutoRefresh();
      }
    });

    return () => subscription.remove();
  }, []);

  React.useEffect(() => {
    if (!user) {
      stopAutoRefresh();
      return;
    }

    isAppActiveRef.current = RNAppState.currentState === 'active';
    startAutoRefresh();
    return stopAutoRefresh;
  }, [user, appSettings.modoExibicao]);

  useEffect(() => {
    tablesRef.current = tables;
    tablesFingerprintRef.current = tablesFingerprint(tables);
  }, [tables]);

  useEffect(() => {
    categoriesFingerprintRef.current = categoriesFingerprint(categories);
  }, [categories]);

  useEffect(() => {
    productsFingerprintRef.current = productsFingerprint(products);
  }, [products]);

  useEffect(() => {
    cartRef.current = cart;
  }, [cart]);

  useEffect(() => {
    activeTableRef.current = activeTable;
  }, [activeTable]);

  useEffect(() => {
    userRef.current = user;
  }, [user]);

  const openTableByCard = async (
    tableId: number,
    nomeMesaComanda?: string,
    tableTypeHint?: 'mesa' | 'comanda'
  ) => {
    const nomeInformado = String(nomeMesaComanda || '').trim();
    let mode = appSettings.modoExibicao || 'mesa';
    if (tableTypeHint) {
      mode = tableTypeHint;
    }
    if (mode === 'mesaComanda' && /comanda|c[aã]rd/i.test(nomeInformado)) {
      mode = /comanda|c[aã]rd/i.test(nomeInformado) ? 'comanda' : 'mesa';
    }

    const sanitizedName = isDefaultTableDisplayName(
      nomeInformado,
      tableId,
      mode === 'mesaComanda' ? undefined : mode
    )
      ? undefined
      : nomeInformado || undefined;

    let table = await api.openTableByMode(tableId, sanitizedName, mode);
    const openedMode = (item: TableOrder) => item.tipo || 'mesa';
    const fallbackMode = openedMode(table);

    if (!table.idVenda || Number(table.idVenda) === 0) {
      if (fallbackMode === 'comanda') {
        const comandaList = await api.listComandas();
        const found = comandaList.find((item) =>
          Number(item.idMesa || 0) === Number(table.idMesa || tableId)
        );
        if (found?.idVenda && Number(found.idVenda) > 0) {
          table = found;
        }
      } else {
        const mesaList = await api.listTables();
        const found = mesaList.find((item) => Number(item.idMesa || 0) === Number(table.idMesa || tableId));
        if (found?.idVenda && Number(found.idVenda) > 0) {
          table = found;
        }
      }
    }

    if (!table.idVenda || Number(table.idVenda) === 0) {
      throw new Error('Não foi possível iniciar a venda para a mesa selecionada.');
    }

    const resolveMode = (item: TableOrder) => item.tipo || 'mesa';
    const nextMode = table.tipo || resolveMode(table);
    setTables((prev) => {
      const index = prev.findIndex(
        (item) => item.idMesa === table.idMesa && resolveMode(item) === nextMode
      );
      if (index === -1) {
        return [table, ...prev];
      }
      const nextList = [...prev];
      nextList[index] = { ...nextList[index], ...table };
      return nextList;
    });
    setActiveTable(table);
    return table;
  };

  const flushPendingItems = async () => {
    if (flushPendingInFlightRef.current) {
      return flushPendingInFlightRef.current;
    }

    const task = (async () => {
      const pending = cartRef.current;
      if (pending.length === 0) {
        retryPendingAfterFailureRef.current = false;
        return false;
      }

      let table = activeTableRef.current;
      if (!table) {
        throw new Error('Selecione uma mesa antes de enviar os itens.');
      }

      if (!table.idVenda || Number(table.idVenda) === 0) {
        const reopenedName = isDefaultTableDisplayName(
          table.nomeMesaComanda,
          table.idMesa,
          table.tipo
        )
          ? undefined
          : table.nomeMesaComanda;
        const opened = await openTableByCard(table.idMesa, reopenedName, table.tipo);
        table = opened;
        activeTableRef.current = opened;
        setActiveTableState(opened);
      }

      if (!table.idVenda) {
        throw new Error('Não foi possível abrir a venda da mesa.');
      }

      await api.launchItemsBatch(
        table.idVenda,
        pending.map(asPayload)
      );
      clearCart();
      await refreshDashboard();
      retryPendingAfterFailureRef.current = false;
      return true;
    })();

    flushPendingInFlightRef.current = task;
    try {
      return await task;
    } catch (error) {
      retryPendingAfterFailureRef.current = true;
      throw error;
    } finally {
      if (flushPendingInFlightRef.current === task) {
        flushPendingInFlightRef.current = null;
      }
    }
  };

  const checkoutCart = async () => {
    throw new Error('Envio disponível somente na tela Inicial (botão Atualizar).');
  };

  const value = useMemo(
    () => ({
      baseUrl,
      apiConnection,
      appSettings,
      settingsReady,
      user,
      loading,
      tables,
      categories,
      products,
      selectedCategoryId,
      initialScreenMode,
      cart,
      activeTable,
      linkedMesaSelection,
      hasActiveTable,
      hasOpenSale,
      ensureActiveTable,
      ensureOpenSale,
      login,
      refreshCurrentUserPermissions,
      refreshDashboard,
      refreshMenu,
      addToCart,
      removeFromCart,
      clearCart,
      setBaseUrl,
      setEmpresaId,
      setAppSettings,
      saveAppSettings,
      setSelectedCategoryId,
      setInitialScreenMode,
      openTableByCard,
      setActiveTable,
      setLinkedMesaSelection,
      checkApiConnection,
      checkoutCart,
      flushPendingItems,
      getLinkedTableId,
      getLineTotal,
      getCartTotal,
      syncStatus,
      lastSyncAt,
      logout,
      pauseAutoRefresh,
      resumeAutoRefresh
    }),
    [
      baseUrl,
      appSettings,
      user,
      loading,
      tables,
      categories,
      products,
      selectedCategoryId,
      initialScreenMode,
      cart,
      activeTable,
      linkedMesaSelection,
      hasActiveTable,
      hasOpenSale,
      apiConnection,
      syncStatus,
      lastSyncAt,
      settingsReady,
      initialScreenMode,
      pauseAutoRefresh,
      resumeAutoRefresh
    ]
  );

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
};
