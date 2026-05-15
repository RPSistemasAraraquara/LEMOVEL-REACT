import AsyncStorage from '@react-native-async-storage/async-storage';
import * as FileSystem from 'expo-file-system/legacy';
import { NativeModules, Platform } from 'react-native';
import { loadStoredMachineSettings, saveStoredMachineSettings } from './machineSettingsDb';
import {
  countStoredCatalogProductSummaries,
  loadStoredCatalogFingerprint,
  loadStoredCatalogProduct,
  loadStoredCatalogProducts,
  loadStoredCatalogProductSummaries,
  saveStoredCatalogProducts
} from './productCatalogDb';
import type { ProductCatalogSummaryItem } from './productCatalogDb';

export type MenuItem = {
  id: number;
  idProduto: number;
  descricao: string;
  descricaoCurta?: string;
  codReferencia?: string;
  imagem?: string;
  imagem_db?: string;
  imagemLocalPath?: string;
  possuiImagem?: boolean;
  valorVenda: number;
  valorUnitario?: number;
  idCategoria?: number;
  b_venda_mobile?: boolean;
  vendaPorTamanho?: boolean;
  tamanhoPadrao?: string;
  tamanhoP?: string;
  tamanhoM?: string;
  tamanhoG?: string;
  tamanhoGG?: string;
  tamanhoExtra?: string;
  valorTamanhoP?: number;
  valorTamanhoM?: number;
  valorTamanhoG?: number;
  valorTamanhoGG?: number;
  valorTamanhoExtra?: number;
  usaQuantidadeDecimal?: boolean;
  permiteFracao?: boolean;
  happyHourAtivar?: boolean;
  happyHour?: ProductHappyHour;
  opcionais?: ProductOptional[];
  catalogCompact?: boolean;
};

export type ProductHappyHour = {
  segundaFeira?: boolean;
  tercaFeira?: boolean;
  quartaFeira?: boolean;
  quintaFeira?: boolean;
  sextaFeira?: boolean;
  sabado?: boolean;
  domingo?: boolean;
  tipoMesa?: boolean;
  tipoComanda?: boolean;
  horaInicial?: string | number;
  horaFinal?: string | number;
  valor?: number;
};

export type ProductSizeOption = {
  code: string;
  label: string;
  value: number;
  unitLabel?: string;
};

export type ProductOptional = {
  idOpcional: number;
  descricao: string;
  valor: number;
  gratis?: boolean;
  opcionalP?: string;
  opcionalM?: string;
  opcionalG?: string;
  opcionalGG?: string;
  opcionalExtra?: string;
  valorOpcionalP?: number;
  valorOpcionalM?: number;
  valorOpcionalG?: number;
  valorOpcionalGG?: number;
  valorOpcionalExtra?: number;
};

export type LaunchOptionalPayload = {
  idOpcional: number;
  descricao: string;
  valor: number;
  gratis: boolean;
};

export type LaunchItemFractionPayload = {
  idProduto: number;
  produtoDescricao: string;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  acrescimo: number;
  observacao?: string;
  descricaoTamanho?: string;
  opcionais: LaunchOptionalPayload[];
};

export type LaunchItemPayload = {
  idProduto: number;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  desconto: number;
  acrescimo: number;
  tamanho: string;
  vendaPorTamanho: boolean;
  descricaoTamanho: string;
  observacao?: string;
  idMesaVinculada: number;
  idGarcom?: number;
  terminalImpressao?: string;
  TerminalImpressao?: string;
  opcionais: LaunchOptionalPayload[];
  fracoes?: LaunchItemFractionPayload[];
};

export type Category = {
  id: number;
  descricao: string;
};

export type PaymentMethod = {
  codigo: number;
  descricao: string;
  sfiCodigo?: number;
  sfiDescricao?: string;
  cortesia?: boolean;
  utilizaControleCartao?: boolean;
  utilizaPagamentoOnline?: boolean;
  pagamentoEletronico?: boolean;
  prazoCartao?: number;
  taxaCartao?: number;
  idContaCorrente?: number;
};

export type SaleLineOptional = {
  idOpcional: number;
  descricao: string;
  valor: number;
  gratis?: boolean;
};

export type SaleLineFraction = {
  idProduto: number;
  produtoDescricao: string;
  numeroItem?: number;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  acrescimo?: number;
  observacao?: string;
  descricaoTamanho?: string;
  opcionais?: SaleLineOptional[];
};

export type SaleLine = {
  idProduto: number;
  produtoDescricao: string;
  imagem?: string;
  numeroItem: number;
  itemFracionado: number;
  situacao?: string;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  desconto: number;
  acrescimo: number;
  idGarcom?: number;
  nomeGarcom?: string;
  tamanho: string;
  descricaoTamanho?: string;
  dataHora?: string;
  observacao?: string;
  vendaPorTamanho: boolean;
  idMesaVinculada?: number;
  opcionais?: SaleLineOptional[];
  fracoes?: SaleLineFraction[];
};

export type SalePayment = {
  idVendaPagamentoAntecipado?: number;
  idFormaPagamento?: number;
  valor: number;
  formaPagamento?: PaymentMethod;
  dataHora?: string;
  observacao?: string;
  taxaServico?: boolean;
};

export type Sale = {
  idVenda: number;
  idUsuario?: number;
  valor: number;
  valorTotal?: number;
  situacao?: string;
  numeroMesa?: number;
  numeroComanda?: number;
  nomeMesaComanda?: string;
  numeroPessoas?: number;
  numeroCouvertMasculino?: number;
  numeroCouvertFeminino?: number;
  valorCouvertMasculino?: number;
  valorCouvertFeminino?: number;
  valorTaxaServico?: number;
  valorEntrada?: number;
  valorPagamentoAntecipado?: number;
  valorDesconto?: number;
  tipoDesconto?: number;
  itens?: SaleLine[];
  pagamentos?: SalePayment[];
};

export type SaleClosureLine = {
  idFormaPgto: number;
  valor: number;
};

export type SaleClosurePayload = {
  idVenda: number;
  idUsuario: number;
  numeroPessoas?: number;
  numeroCouvertMasculino?: number;
  numeroCouvertFeminino?: number;
  valorDesconto?: number;
  tipoDesconto?: number;
  valorTaxaServico?: number;
  CobrarTaxaGarcom?: boolean;
  pagamentos: SaleClosureLine[];
  impressoraInterna?: boolean;
  imprimirPreFechamentoMobile?: boolean;
};

export type MachinePaymentType = 'tmpNenhum' | 'tmpVero' | 'tmpStone' | 'tmpPlugPag' | 'tmpCielo';

export type SalePrintRequest = {
  numeroColunas?: number;
  impressaoInterna?: boolean;
  tipoMaquina?: MachinePaymentType;
};

export type SalePartialPaymentPayload = {
  idVenda: number;
  idFormaPagamento: number;
  valor: number;
  idUsuario?: number;
};

export type SaleCouvertPayload = {
  numeroPessoas: number;
  numeroCouvertMasculino?: number;
  numeroCouvertFeminino?: number;
  valorTaxaServico?: number;
  CobrarTaxaGarcom?: boolean;
};

export type SyncTaskResult = {
  key: string;
  status: 'ok' | 'error' | 'skip';
  message: string;
  durationMs?: number;
};

export type SyncResult = {
  status: 'ok' | 'partial' | 'error';
  timestamp: string;
  summary: string[];
  details?: SyncTaskResult[];
};

type SyncAllOptions = {
  onTaskStart?: (task: string) => void;
  onTaskFinish?: (result: SyncTaskResult) => void;
};

type CategoryListOptions = {
  requireRemote?: boolean;
  preferCache?: boolean;
  preferNativeHttp?: boolean;
  timeoutMs?: number;
};

type ProductListOptions = {
  requireRemote?: boolean;
  preferCache?: boolean;
  forceRemote?: boolean;
  preferNativeHttp?: boolean;
  timeoutMs?: number;
  preserveCachedImages?: boolean;
  compact?: boolean;
};

type UserListOptions = {
  requireRemote?: boolean;
  preferCache?: boolean;
};

export type TableOrder = {
  idMesa: number;
  idComanda?: number;
  numeroMesa?: number;
  numeroComanda?: number;
  nomeMesaComanda: string;
  situacao: string;
  statusOriginal?: string;
  statusCode?: string;
  valorTotal?: number;
  idVenda?: number;
  tipo?: 'mesa' | 'comanda';
  venda?: {
    idVenda?: number;
    situacao?: string;
    nomeMesaComanda?: string;
    valorTotal?: number;
    valorPagamentoAntecipado?: number;
  };
};

const extractTableDisplayNumber = (value?: string): number => {
  const match = String(value || '').match(/\d+/);
  return match ? Number(match[0]) || 0 : 0;
};

export function getTableOrderDisplayNumber(table: TableOrder): number {
  const isComanda = table.tipo === 'comanda' || Number(table.idComanda || 0) > 0;
  const explicitNumber = isComanda
    ? Number(table.numeroComanda || table.numeroMesa || 0)
    : Number(table.numeroMesa || table.numeroComanda || 0);

  if (explicitNumber > 0) {
    return explicitNumber;
  }

  const displayNumber =
    extractTableDisplayNumber(table.venda?.nomeMesaComanda) ||
    extractTableDisplayNumber(table.nomeMesaComanda);

  if (displayNumber > 0) {
    return displayNumber;
  }

  return Number(isComanda ? table.idComanda || table.idMesa : table.idMesa || table.idComanda || 0) || 0;
}

export function getTableOrderDisplayLabel(table: TableOrder): string {
  const name = String(table.nomeMesaComanda || table.venda?.nomeMesaComanda || '').trim();
  if (name) {
    return name;
  }

  const isComanda = table.tipo === 'comanda' || Number(table.idComanda || 0) > 0;
  return `${isComanda ? 'Comanda' : 'Mesa'} ${getTableOrderDisplayNumber(table) || 0}`.trim();
}

export type UserProfile = {
  idUsuario: number;
  nome: string;
  login: string;
  permiteCancelarItemMobile?: boolean;
  permitePreFechamentoMesaComanda?: boolean;
  permiteFechamentoMesaComanda?: boolean;
  permiteAlterarTaxa10?: boolean;
  permiteJuntarMesaComanda?: boolean;
  permiteReabrirMesaComanda?: boolean;
  permitePagamentoParcial?: boolean;
  permiteDescontoFechamento?: boolean;
};

export type CompanyConfig = {
  idEmpresa?: number;
  usaVendaPorTamanho?: boolean;
  taxaAdicionalMesa?: boolean;
  taxaServicoPct?: number;
  couvertAtivo?: boolean;
  couvertMascFemObrigatorio?: boolean;
  valorCouvertMasculino?: number;
  valorCouvertFeminino?: number;
};

export type CompanyInfo = {
  idEmpresa?: number;
  utilizaRPMovel?: boolean;
  utilizaIntegracaoStone?: boolean;
  utilizaIntegracaoCielo?: boolean;
  utilizaIntegracaoPagBank?: boolean;
  utilizaIntegracaoGetNet?: boolean;
};

export type MobileAppSettings = {
  baseUrl: string;
  empresaId: number;
  terminalImpressao: string;
  salvarLoginSenha: boolean;
  utilizaCatraca: boolean;
  cobrarMaiorValorFracionado: boolean;
  vincularComandaComMesa: boolean;
  imprimirMesaAposFechamento: boolean;
  imprimirComandaAposFechamento: boolean;
  controleHappyHour: boolean;
  controlePromocao: boolean;
  pesquisaCodigoProduto: boolean;
  controleProximoGratis: boolean;
  utilizaCategorias: boolean;
  exibirImagem: boolean;
  exigeNomeAbertura: boolean;
  utilizaImpressoraInterna: boolean;
  imprimirFichaIndividualProdutos: boolean;
  imprimirModelo: string;
  impressoraPaginaCodigo: string;
  impressoraControlePorta: boolean;
  impressoraBluetooth: string;
  impressaoColunas: number;
  impressaoEspaco: number;
  impressaoLinhasPulo: number;
  sincronizarAposLogin: boolean;
  modoExibicao: 'mesa' | 'comanda' | 'mesaComanda';
  utilizaMaquininhaStone: boolean;
  tipoIntegracao: 'nenhum' | 'vero' | 'stone' | 'pagbank' | 'cielo' | 'getnet';
  modeloMaquininha: string;
  usuario?: string;
  senha?: string;
};

export const OPENING_SETTINGS_CONFLICT_MESSAGE =
  'Não é permitido vincular comanda com mesa e exigir nome na abertura da mesa/comanda simultaneamente.';

export const hasConflictingOpeningSettings = (
  settings: Pick<MobileAppSettings, 'vincularComandaComMesa' | 'exigeNomeAbertura'>
) => Boolean(settings.vincularComandaComMesa && settings.exigeNomeAbertura);

const fallbackProfile: UserProfile = {
  idUsuario: 1,
  nome: 'Demo Garçom',
  login: 'demo',
  permiteCancelarItemMobile: false,
  permitePreFechamentoMesaComanda: false,
  permiteFechamentoMesaComanda: false,
  permiteAlterarTaxa10: false,
  permiteJuntarMesaComanda: false,
  permiteReabrirMesaComanda: false,
  permitePagamentoParcial: false,
  permiteDescontoFechamento: false
};

const fallbackCategories: Category[] = [
  { id: 1, descricao: 'Hambúrgueres' },
  { id: 2, descricao: 'Acompanhamentos' },
  { id: 3, descricao: 'Bebidas' }
];

const fallbackProducts: MenuItem[] = [
  {
    id: 1,
    idProduto: 1001,
    descricao: 'X-Big Fire',
    descricaoCurta: 'Pão brioche, burger, queijo e molho especial',
    valorVenda: 29.9,
    valorUnitario: 29.9,
    idCategoria: 1,
    b_venda_mobile: true,
    vendaPorTamanho: true,
    tamanhoPadrao: 'M',
    tamanhoP: 'P',
    tamanhoM: 'M',
    tamanhoG: 'G',
    tamanhoGG: 'GG',
    tamanhoExtra: 'E',
    valorTamanhoP: 24,
    valorTamanhoM: 29.9,
    valorTamanhoG: 33.5,
    valorTamanhoGG: 37,
    valorTamanhoExtra: 41,
    usaQuantidadeDecimal: false,
    opcionais: [{ idOpcional: 201, descricao: 'Bacon', valor: 4, gratis: false }]
  },
  {
    id: 2,
    idProduto: 1002,
    descricao: 'X-Crispy Chicken',
    descricaoCurta: 'Frango crocante com alface e maionese',
    valorVenda: 27.5,
    valorUnitario: 27.5,
    idCategoria: 1,
    b_venda_mobile: true,
    vendaPorTamanho: false,
    tamanhoPadrao: 'M',
    usaQuantidadeDecimal: false,
    opcionais: []
  },
  {
    id: 3,
    idProduto: 2001,
    descricao: 'Batata Média',
    descricaoCurta: 'Batata dourada com sal e azeite',
    valorVenda: 12,
    valorUnitario: 12,
    idCategoria: 2,
    b_venda_mobile: true,
    vendaPorTamanho: false,
    usaQuantidadeDecimal: true,
    tamanhoPadrao: 'U',
    opcionais: []
  },
  {
    id: 4,
    idProduto: 3001,
    descricao: 'Refrigerante 350ml',
    descricaoCurta: 'Lata ou garrafa',
    valorVenda: 7.5,
    valorUnitario: 7.5,
    idCategoria: 3,
    b_venda_mobile: true,
    vendaPorTamanho: false,
    usaQuantidadeDecimal: false,
    tamanhoPadrao: 'U',
    opcionais: []
  }
];

const fallbackTables: TableOrder[] = [
  { idMesa: 1, nomeMesaComanda: 'Mesa 01', situacao: 'Aberta', valorTotal: 44.4, idVenda: 101 },
  { idMesa: 2, nomeMesaComanda: 'Mesa 02', situacao: 'Livre', valorTotal: 0, idVenda: 0 },
  { idMesa: 3, nomeMesaComanda: 'Mesa 03', situacao: 'Fechando', valorTotal: 82.9, idVenda: 0 }
];

export const defaultMobileSettings: MobileAppSettings = {
  baseUrl: 'http://104.234.189.194:9000/',
  empresaId: 1,
  terminalImpressao: 'PB09217174334',
  salvarLoginSenha: true,
  utilizaCatraca: false,
  cobrarMaiorValorFracionado: false,
  vincularComandaComMesa: false,
  imprimirMesaAposFechamento: true,
  imprimirComandaAposFechamento: true,
  controleHappyHour: false,
  controlePromocao: false,
  pesquisaCodigoProduto: false,
  controleProximoGratis: false,
  utilizaCategorias: true,
  exibirImagem: true,
  exigeNomeAbertura: false,
  utilizaImpressoraInterna: true,
  imprimirFichaIndividualProdutos: false,
  imprimirModelo: 'Padrão ESC/POS',
  impressoraPaginaCodigo: 'UTF-8',
  impressoraControlePorta: false,
  impressoraBluetooth: 'Nenhuma',
  impressaoColunas: 48,
  impressaoEspaco: 0,
  impressaoLinhasPulo: 1,
  sincronizarAposLogin: true,
  modoExibicao: 'mesa',
  utilizaMaquininhaStone: true,
  tipoIntegracao: 'cielo',
  modeloMaquininha: 'Cielo',
  usuario: '1',
  senha: '1'
};

const STORAGE_KEY = '@rpcheff:mobile-settings';
const CATALOG_STORAGE_VERSION = 5;
const CATALOG_PRODUCT_WRITE_BATCH_SIZE = 80;
const PRODUCT_CATALOG_TIMEOUT_MS = 60000;
const SYNC_PRODUCT_CATALOG_TIMEOUT_MS = 30000;
const PRODUCT_IMAGE_CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const PRODUCT_IMAGE_DOWNLOAD_CONCURRENCY = 2;

function buildCatalogStoragePrefix(baseUrl: string, empresaId: number): string {
  const normalizedBaseUrl = String(baseUrl || '')
    .trim()
    .toLowerCase()
    .replace(/\/+$/, '');
  const baseToken = normalizedBaseUrl
    ? normalizedBaseUrl.replace(/[^a-z0-9]+/gi, '_').replace(/^_+|_+$/g, '')
    : 'default';
  return `@rpcheff:catalog:v${CATALOG_STORAGE_VERSION}:${empresaId}:${baseToken}`;
}

function buildCatalogImageDirectory(baseUrl: string, empresaId: number): string | null {
  const rootDirectory = FileSystem.documentDirectory || FileSystem.cacheDirectory;
  if (!rootDirectory) {
    return null;
  }

  const normalizedBaseUrl = String(baseUrl || '')
    .trim()
    .toLowerCase()
    .replace(/\/+$/, '');
  const baseToken = normalizedBaseUrl
    ? normalizedBaseUrl.replace(/[^a-z0-9]+/gi, '_').replace(/^_+|_+$/g, '')
    : 'default';

  return `${rootDirectory}rpcheff-catalog/${empresaId}/${baseToken}/`;
}

function buildCatalogRemoteImagePath(baseUrl: string, empresaId: number, idProduto?: number | null) {
  const productId = Number(idProduto || 0);
  const directory = buildCatalogImageDirectory(baseUrl, empresaId);
  if (!directory || !Number.isFinite(productId) || productId <= 0) {
    return null;
  }

  const normalizedProductId = Math.trunc(productId);
  return {
    directory,
    path: `${directory}${normalizedProductId}-remote.jpg`,
    tempPath: `${directory}${normalizedProductId}-remote.download`
  };
}

const fallbackPaymentMethods: PaymentMethod[] = [
  { codigo: 1, descricao: 'Dinheiro', sfiCodigo: 1 },
  { codigo: 2, descricao: 'Cartão de Débito', sfiCodigo: 4 },
  { codigo: 3, descricao: 'Cartão de Crédito', sfiCodigo: 3 },
  { codigo: 4, descricao: 'PIX', sfiCodigo: 17 }
];

const AUTH_USERNAME = 'RP515TEMAS_CH3FF';
const AUTH_PASSWORD = 'RP515TEMAS';

const requestDefaults = {
  timeoutMs: 15000
};

export const quickConnectionCheckTimeoutMs = 8000;

type NativeHttpResponse = {
  body?: string | null;
  status: number;
  statusText?: string;
};

type NativeHttpModule = {
  request: (
    url: string,
    method: string,
    headers: Record<string, string>,
    body: string | null,
    timeoutMs: number
  ) => Promise<NativeHttpResponse>;
};

type ApiRequestInit = RequestInit & {
  timeoutMs?: number;
  preferNativeHttp?: boolean;
};

const nativeHttpModule: NativeHttpModule | undefined =
  Platform.OS === 'android' ? (NativeModules.RPCheffHttp as NativeHttpModule | undefined) : undefined;

let activeProductImageDownloads = 0;
const productImageDownloadQueue: Array<() => void> = [];
const productImageWebCache = new Map<string, string>();

function runProductImageDownload<T>(task: () => Promise<T>): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const execute = () => {
      activeProductImageDownloads += 1;
      task()
        .then(resolve, reject)
        .finally(() => {
          activeProductImageDownloads = Math.max(0, activeProductImageDownloads - 1);
          const next = productImageDownloadQueue.shift();
          if (next) {
            next();
          }
        });
    };

    if (activeProductImageDownloads < PRODUCT_IMAGE_DOWNLOAD_CONCURRENCY) {
      execute();
      return;
    }

    productImageDownloadQueue.push(execute);
  });
}

async function downloadProductImageAsDataUri(imageUrl: string): Promise<string | undefined> {
  try {
    const response = await fetch(imageUrl, {
      headers: authHeader()
    });
    if (!response.ok) {
      return undefined;
    }

    const buffer = await response.arrayBuffer();
    const bytes = new Uint8Array(buffer);
    if (!bytes.byteLength) {
      return undefined;
    }

    const headerMimeType = String(response.headers.get('content-type') || '')
      .split(';', 1)[0]
      .trim();
    const mimeType = /^image\//i.test(headerMimeType)
      ? headerMimeType
      : detectImageMimeTypeFromBytes(Array.from(bytes.subarray(0, 16)));

    return buildDataUri(bytesToBase64(Array.from(bytes)), mimeType || 'image/jpeg');
  } catch {
    return undefined;
  }
}

type GetRequestCacheEntry = {
  payload: unknown;
  expiresAt: number;
};

type GetRequestCache = {
  [key: string]: GetRequestCacheEntry;
};

const GET_CACHE_TTL_DEFAULT_MS = 3000;
const GET_CACHE_TTL = {
  tables: 2500,
  comandas: 2500,
  categories: 30000,
  products: 30000
};
const NO_CACHE_HEADERS = {
  'Cache-Control': 'no-cache',
  Pragma: 'no-cache'
};

type NativeLoggingGlobal = typeof globalThis & {
  nativeLoggingHook?: (message: string, level: number) => void;
};

export function logSyncDiagnostic(message: string, level = 1) {
  const formatted = `[RP_SYNC] ${message}`;
  try {
    const nativeLoggingHook = (globalThis as NativeLoggingGlobal).nativeLoggingHook;
    if (typeof nativeLoggingHook === 'function') {
      nativeLoggingHook(formatted, level);
      return;
    }
  } catch {
    // Diagnostico nunca deve interferir no fluxo principal.
  }

  try {
    console.info(formatted);
  } catch {
    // Sem fallback de log disponivel.
  }
}

function getAuthorizationHeaderValue(): string {
  const raw = `${AUTH_USERNAME}:${AUTH_PASSWORD}`;
  const base64 = toBase64(raw);
  return `Basic ${base64}`;
}

function authHeader(): HeadersInit {
  return {
    Authorization: getAuthorizationHeaderValue()
  };
}

function normalizeRequestHeaders(headers?: HeadersInit): Record<string, string> {
  const normalized: Record<string, string> = {};

  if (!headers) {
    return normalized;
  }

  if (typeof Headers !== 'undefined' && headers instanceof Headers) {
    headers.forEach((value: string, key: string) => {
      normalized[key] = value;
    });
    return normalized;
  }

  if (Array.isArray(headers)) {
    headers.forEach(([key, value]) => {
      normalized[String(key)] = String(value);
    });
    return normalized;
  }

  Object.entries(headers).forEach(([key, value]) => {
    if (typeof value === 'undefined') {
      return;
    }

    normalized[key] = String(value);
  });

  return normalized;
}

function isTransientAndroidNetworkError(error: unknown): boolean {
  const message =
    error instanceof Error
      ? error.message
      : typeof error === 'string'
      ? error
      : error && typeof error === 'object' && 'message' in error
      ? String((error as { message?: unknown }).message || '')
      : '';

  const normalized = message.toLowerCase();
  return (
    normalized.includes('unexpected end of stream') ||
    normalized.includes('connection abort') ||
    normalized.includes('connection reset') ||
    normalized.includes('aborted') ||
    normalized.includes('aborterror') ||
    normalized.includes('timeout') ||
    normalized.includes('timed out') ||
    normalized.includes('tempo limite') ||
    normalized.includes('eofexception') ||
    normalized.includes('socketexception')
  );
}

function isTransientFetchNetworkError(error: unknown): boolean {
  const message =
    error instanceof Error
      ? error.message
      : typeof error === 'string'
      ? error
      : error && typeof error === 'object' && 'message' in error
      ? String((error as { message?: unknown }).message || '')
      : '';

  const normalized = message.toLowerCase();
  return (
    normalized.includes('network request failed') ||
    normalized.includes('failed to fetch') ||
    normalized.includes('unexpected end of stream') ||
    normalized.includes('connection abort') ||
    normalized.includes('connection reset') ||
    normalized.includes('aborted') ||
    normalized.includes('aborterror') ||
    normalized.includes('timeout') ||
    normalized.includes('timed out') ||
    normalized.includes('tempo limite') ||
    normalized.includes('eofexception') ||
    normalized.includes('socketexception')
  );
}

function buildAbsoluteUrl(baseUrl: string, path: string): string {
  const normalized = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  const trimmed = path.startsWith('/') ? path.slice(1) : path;
  return `${normalized}/${trimmed}`;
}

function normalizeMobileBaseUrl(value: unknown): string {
  const fallback = defaultMobileSettings.baseUrl;
  const trimmed = String(value ?? '').trim().replace(/\/+$/, '');
  if (!trimmed) {
    return fallback;
  }

  let normalized = trimmed;
  if (!/^https?:\/\//i.test(normalized)) {
    normalized = `http://${normalized}`;
  }

  if (Platform.OS === 'android' && /(^https?:\/\/)(localhost|127\.0\.0\.1)(:\d+)?(\/.*)?/i.test(normalized)) {
    normalized = normalized.replace(/localhost|127\.0\.0\.1/gi, '10.0.2.2');
  }

  return normalized;
}

export function buildProductImageUrl(baseUrl: string, empresaId: number, idProduto?: number | null): string | undefined {
  const numericId = Number(idProduto || 0);
  if (!Number.isFinite(numericId) || numericId <= 0) {
    return undefined;
  }

  return buildAbsoluteUrl(baseUrl, `rpCheff/v1/empresa/${empresaId}/produto/${Math.trunc(numericId)}/imagem`);
}

export function getProductImageSource(baseUrl: string, empresaId: number, idProduto?: number | null) {
  const uri = buildProductImageUrl(baseUrl, empresaId, idProduto);
  if (!uri) {
    return undefined;
  }

  return {
    uri,
    headers: {
      Authorization: getAuthorizationHeaderValue()
    }
  };
}

export async function cacheProductImageOnDemand(
  baseUrl: string,
  empresaId: number,
  idProduto?: number | null
): Promise<string | undefined> {
  const imageUrl = buildProductImageUrl(baseUrl, empresaId, idProduto);
  const imagePath = buildCatalogRemoteImagePath(baseUrl, empresaId, idProduto);
  if (!imageUrl || (Platform.OS !== 'web' && !imagePath)) {
    return undefined;
  }

  const readCachedPath = async () => {
    if (!imagePath) {
      return { path: undefined, fresh: false };
    }

    try {
      const info = await FileSystem.getInfoAsync(imagePath.path);
      if (!info.exists || info.isDirectory || info.size <= 0) {
        return { path: undefined, fresh: false };
      }

      const modifiedAtMs =
        typeof info.modificationTime === 'number' && Number.isFinite(info.modificationTime)
          ? info.modificationTime * 1000
          : 0;
      const fresh = modifiedAtMs <= 0 || Date.now() - modifiedAtMs <= PRODUCT_IMAGE_CACHE_TTL_MS;
      return { path: imagePath.path, fresh };
    } catch {
      return { path: undefined, fresh: false };
    }
  };

  const cached = await readCachedPath();
  if (cached.path && cached.fresh) {
    return cached.path;
  }

  if (Platform.OS === 'web') {
    const cachedDataUri = productImageWebCache.get(imageUrl);
    if (cachedDataUri) {
      return cachedDataUri;
    }
  }

  return runProductImageDownload(async () => {
    if (Platform.OS === 'web') {
      const queuedCachedDataUri = productImageWebCache.get(imageUrl);
      if (queuedCachedDataUri) {
        return queuedCachedDataUri;
      }

      const downloadedDataUri = await downloadProductImageAsDataUri(imageUrl);
      if (downloadedDataUri) {
        productImageWebCache.set(imageUrl, downloadedDataUri);
      }
      return downloadedDataUri;
    }

    const nativeImagePath = imagePath;
    if (!nativeImagePath) {
      return undefined;
    }

    const queuedCached = await readCachedPath();
    if (queuedCached.path && queuedCached.fresh) {
      return queuedCached.path;
    }

    try {
      await FileSystem.makeDirectoryAsync(nativeImagePath.directory, { intermediates: true });
      await FileSystem.deleteAsync(nativeImagePath.tempPath, { idempotent: true }).catch(() => null);
      const result = await FileSystem.downloadAsync(imageUrl, nativeImagePath.tempPath, {
        headers: {
          Authorization: getAuthorizationHeaderValue()
        }
      });

      if (result.status < 200 || result.status >= 300) {
        await FileSystem.deleteAsync(nativeImagePath.tempPath, { idempotent: true }).catch(() => null);
        return queuedCached.path;
      }

      await FileSystem.deleteAsync(nativeImagePath.path, { idempotent: true }).catch(() => null);
      await FileSystem.moveAsync({
        from: nativeImagePath.tempPath,
        to: nativeImagePath.path
      });
      return nativeImagePath.path;
    } catch {
      await FileSystem.deleteAsync(nativeImagePath.tempPath, { idempotent: true }).catch(() => null);
      return queuedCached.path;
    }
  });
}

function parseNumber(value: any, fallback = 0): number {
  if (typeof value === 'number') return Number.isFinite(value) ? value : fallback;
  if (typeof value === 'string') {
    const numeric = Number(value.replace(',', '.'));
    return Number.isFinite(numeric) ? numeric : fallback;
  }
  return fallback;
}

function parseBoolean(value: any, fallback = false): boolean {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') return ['1', 'true', 'sim', 's', 'y', 'yes'].includes(value.toLowerCase());
  return fallback;
}

function resolveField(value: unknown, keys: string[]): unknown {
  if (!value || typeof value !== 'object') return undefined;
  const source = value as Record<string, unknown>;

  for (const key of keys) {
    if (Object.prototype.hasOwnProperty.call(source, key)) {
      return source[key];
    }

    const match = Object.keys(source).find((item) => item.toLowerCase() === key.toLowerCase());
    if (match) {
      return source[match];
    }
  }

  return undefined;
}

function normalizeStatus(value: unknown): string {
  const raw = sanitizeText(value, '');
  if (!raw) {
    if (typeof value === 'number') {
      return mapStatusCode(Number(value));
    }
    return '';
  }

  const normalized = sanitizeText(raw, '').toLowerCase();
  if (normalized && normalized.match(/^-?\d+$/)) {
    return mapStatusCode(Number(normalized));
  }

  return normalized;
}

function mapStatusCode(code: number): string {
  switch (code) {
    case 0:
      return 'digitacao';
    case 1:
      return 'finalizada';
    case 2:
      return 'cancelada';
    case 8:
      return 'pendente';
    case 15:
      return 'aguardando';
    case 19:
      return 'reservada';
    case 21:
      return 'prefechamento';
    default:
      return '';
  }
}

export function normalizeSaleStatus(value: unknown): string {
  const raw = normalizeStatus(value);
  return raw.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
}

export function isTableStatusQuickLaunch(value: unknown): boolean {
  const status = normalizeSaleStatus(value);
  return (
    status.includes('digitacao') ||
    status.includes('pendente') ||
    status.includes('prefechamento') ||
    status.includes('pre-fechamento') ||
    status.includes('aberta')
  );
}

export function isTableStatusReserved(value: unknown): boolean {
  const status = normalizeSaleStatus(value);
  return (
    status.includes('reservada') ||
    status.includes('reserva') ||
    status.includes('smreservada') ||
    status.includes('aguard') ||
    status.includes('liber')
  );
}

export function formatTableStatusLabel(value: unknown): string {
  const status = normalizeSaleStatus(value).toLowerCase();
  if (!status) {
    return '';
  }

  if (status.includes('prefechamento') || status.includes('pre-fechamento')) {
    return 'Pré-fechamento';
  }
  if (status.includes('pendente')) {
    return 'Pendente';
  }
  if (status.includes('digitacao')) {
    return 'Digitação';
  }
  if (status.includes('finalizada')) {
    return 'Finalizada';
  }
  if (status.includes('cancelada')) {
    return 'Cancelada';
  }
  if (status.includes('reservada') || status.includes('reserva') || status.includes('smreservada')) {
    return 'Reservada';
  }
  if (status.includes('aguard')) {
    return 'Aguardando';
  }
  if (status.includes('smdisponivel') || status.includes('dispon') || status.includes('liber')) {
    return 'Disponível';
  }
  if (status.includes('ocup') || status.includes('aberta')) {
    return 'Ocupada';
  }

  const raw = String(value || '').trim();
  if (!raw) {
    return '';
  }

  const cleaned = raw.replace(/^sm/i, '');
  return cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
}

function normalizeNomeMesa(id: number, prefix: string, fallbackId: number, providedName?: string) {
  const base = sanitizeText(providedName, '').trim();
  if (base) return base;
  return `${prefix} ${fallbackId || id || 0}`.trim();
}

function parsePaymentIntegration(values: Record<string, unknown>): MobileAppSettings['tipoIntegracao'] {
  const rawIntegration = resolveField(values, [
    'tipoIntegracao',
    'tipo_integracao',
    'tipoMaquinaPagamento',
    'tipo_maquina_pagamento',
    'tipoMaquina',
    'tipo_maquina',
    'cbTipoIntegracao',
    'cb_tipo_integracao'
  ]);

  if (typeof rawIntegration === 'string') {
    const normalized = rawIntegration.toLowerCase().trim();
    if (
      normalized === 'vero' ||
      normalized === 'stone' ||
      normalized === 'pagbank' ||
      normalized === 'cielo' ||
      normalized === 'getnet' ||
      normalized === 'plugpag' ||
      normalized === 'tmpplugpag' ||
      normalized === 'tmplugpag'
    ) {
      if (normalized === 'plugpag' || normalized === 'tmpplugpag' || normalized === 'tmplugpag') {
        return 'pagbank';
      }
      return normalized;
    }

    const parsedIndex = Number(normalized);
    if (Number.isFinite(parsedIndex)) {
      if (parsedIndex === 1) return 'vero';
      if (parsedIndex === 2) return 'stone';
      if (parsedIndex === 3) return 'pagbank';
      if (parsedIndex === 4) return 'cielo';
      if (parsedIndex === 5) return 'getnet';
      return 'nenhum';
    }
  }

  if (typeof rawIntegration === 'number' && Number.isFinite(rawIntegration)) {
    if (rawIntegration === 1) return 'vero';
    if (rawIntegration === 2) return 'stone';
    if (rawIntegration === 3) return 'pagbank';
    if (rawIntegration === 4) return 'cielo';
    if (rawIntegration === 5) return 'getnet';
  }

  if (parseBoolean(values.utilizaIntegracaoCielo, false)) return 'cielo';
  if (parseBoolean(values.utilizaIntegracaoPagBank, false)) return 'pagbank';
  if (parseBoolean(values.utilizaIntegracaoGetNet, false)) return 'getnet';
  if (parseBoolean(values.rp_movel_integracao_cielo, false)) return 'cielo';
  if (parseBoolean(values.rp_movel_integracao_pagbank, false)) return 'pagbank';
  if (parseBoolean(values.rp_movel_integracao_getnet, false)) return 'getnet';
  if (parseBoolean(values.utilizaIntegracaoStone, false) || parseBoolean(values.rp_movel_integracao_stone, false)) {
    return 'stone';
  }

  return 'nenhum';
}

function sanitizeText(value: any, fallback = ''): string {
  if (typeof value === 'string') return value.trim();
  if (typeof value === 'boolean') return value ? 'true' : 'false';
  return fallback;
}

function normalizeMobileSettings(payload: unknown): MobileAppSettings {
  const value = (payload as Record<string, unknown>) || {};
  const tipoIntegracao = parsePaymentIntegration(value);
  const salvarLoginSenha = parseBoolean(value.salvarLoginSenha, defaultMobileSettings.salvarLoginSenha);
  const categoriaLegacyDisabled = resolveField(value, [
    'naoUtilizarCategoria',
    'naoUtilizaCategoria',
    'switchNaoUtilizarCategoria'
  ]);
  return {
    baseUrl: normalizeMobileBaseUrl(value.baseUrl || value.servidor),
    empresaId: parseNumber(
      (value as Record<string, unknown>).empresaId || (value as Record<string, unknown>).empresa,
      defaultMobileSettings.empresaId
    ),
    terminalImpressao: sanitizeText(value.terminalImpressao, defaultMobileSettings.terminalImpressao),
    salvarLoginSenha,
    utilizaCatraca: parseBoolean(value.utilizaCatraca, defaultMobileSettings.utilizaCatraca),
    cobrarMaiorValorFracionado: parseBoolean(
      value.cobrarMaiorValorFracionado,
      defaultMobileSettings.cobrarMaiorValorFracionado
    ),
    vincularComandaComMesa: parseBoolean(
      value.vincularComandaComMesa,
      defaultMobileSettings.vincularComandaComMesa
    ),
    imprimirMesaAposFechamento: parseBoolean(
      resolveField(value, [
        'imprimirMesaAposFechamento',
        'swtchMesaImpressaoFechamento'
      ]),
      defaultMobileSettings.imprimirMesaAposFechamento
    ),
    imprimirComandaAposFechamento: parseBoolean(
      resolveField(value, [
        'imprimirComandaAposFechamento',
        'swtchComandaImpressaoFechamento'
      ]),
      defaultMobileSettings.imprimirComandaAposFechamento
    ),
    controleHappyHour: parseBoolean(value.controleHappyHour, defaultMobileSettings.controleHappyHour),
    controlePromocao: parseBoolean(value.controlePromocao, defaultMobileSettings.controlePromocao),
    pesquisaCodigoProduto: parseBoolean(value.pesquisaCodigoProduto, defaultMobileSettings.pesquisaCodigoProduto),
    controleProximoGratis: parseBoolean(value.controleProximoGratis, defaultMobileSettings.controleProximoGratis),
    utilizaCategorias:
      categoriaLegacyDisabled !== undefined
        ? !parseBoolean(categoriaLegacyDisabled, false)
        : parseBoolean(
            resolveField(value, ['utilizaCategorias', 'utilizaCategoria']),
            defaultMobileSettings.utilizaCategorias
          ),
    exibirImagem: parseBoolean(
      resolveField(value, ['exibirImagem', 'exibir_imagem']),
      defaultMobileSettings.exibirImagem
    ),
    exigeNomeAbertura: parseBoolean(value.exigeNomeAbertura, defaultMobileSettings.exigeNomeAbertura),
    utilizaImpressoraInterna: parseBoolean(
      value.utilizaImpressoraInterna,
      defaultMobileSettings.utilizaImpressoraInterna
    ),
    imprimirFichaIndividualProdutos: parseBoolean(
      value.imprimirFichaIndividualProdutos,
      defaultMobileSettings.imprimirFichaIndividualProdutos
    ),
    imprimirModelo: sanitizeText(
      (value as Record<string, unknown>).imprimirModelo || (value as Record<string, unknown>).impressoraModelo,
      defaultMobileSettings.imprimirModelo
    ),
    impressoraPaginaCodigo: sanitizeText(
      value.impressoraPaginaCodigo,
      defaultMobileSettings.impressoraPaginaCodigo
    ),
    impressoraControlePorta: parseBoolean(
      value.impressoraControlePorta,
      defaultMobileSettings.impressoraControlePorta
    ),
    impressoraBluetooth: sanitizeText(value.impressoraBluetooth, defaultMobileSettings.impressoraBluetooth),
    impressaoColunas: parseNumber(value.impressaoColunas, defaultMobileSettings.impressaoColunas),
    impressaoEspaco: parseNumber(value.impressaoEspaco, defaultMobileSettings.impressaoEspaco),
    impressaoLinhasPulo: parseNumber(value.impressaoLinhasPulo, defaultMobileSettings.impressaoLinhasPulo),
    sincronizarAposLogin: parseBoolean(value.sincronizarAposLogin, defaultMobileSettings.sincronizarAposLogin),
    modoExibicao: (sanitizeText(value.modoExibicao, defaultMobileSettings.modoExibicao) as
      | 'mesa'
      | 'comanda'
      | 'mesaComanda') || defaultMobileSettings.modoExibicao,
    utilizaMaquininhaStone: parseBoolean(value.utilizaMaquininhaStone, false) || tipoIntegracao !== 'nenhum',
    tipoIntegracao,
    modeloMaquininha: sanitizeText(value.modeloMaquininha, defaultMobileSettings.modeloMaquininha),
    usuario: salvarLoginSenha
      ? sanitizeText((value as Record<string, unknown>).usuario, defaultMobileSettings.usuario || '')
      : '',
    senha: salvarLoginSenha
      ? sanitizeText((value as Record<string, unknown>).senha, defaultMobileSettings.senha || '')
      : ''
  };
}

export const loadMobileSettings = async (): Promise<MobileAppSettings> => {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  const storedMachineSettings = await loadStoredMachineSettings();
  if (!raw) {
    if (!storedMachineSettings) {
      return defaultMobileSettings;
    }
    return normalizeMobileSettings({
      ...defaultMobileSettings,
      ...storedMachineSettings
    });
  }
  try {
    return normalizeMobileSettings({
      ...JSON.parse(raw),
      ...(storedMachineSettings || {})
    });
  } catch {
    return storedMachineSettings
      ? normalizeMobileSettings({
          ...defaultMobileSettings,
          ...storedMachineSettings
        })
      : defaultMobileSettings;
  }
};

export const saveMobileSettings = async (payload: MobileAppSettings): Promise<void> => {
  const data = normalizeMobileSettings(payload);
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  await saveStoredMachineSettings({
    utilizaMaquininhaStone: data.utilizaMaquininhaStone,
    tipoIntegracao: data.tipoIntegracao,
    modeloMaquininha: data.modeloMaquininha
  });
};

type StoredMenuItem = Omit<MenuItem, 'imagem' | 'imagemLocalPath'> & {
  imagem_db?: string;
  imagem_local_path?: string;
};

function extractStoredImagePayload(image?: string): string | undefined {
  const trimmed = String(image || '').trim();
  if (!trimmed) {
    return undefined;
  }

  if (/^(https?:\/\/|file:\/\/|content:\/\/|blob:|data:image\/)/i.test(trimmed)) {
    return undefined;
  }

  const normalizedPayload = trimmed.replace(/\s+/g, '');
  return normalizedPayload || undefined;
}

function extractStoredImageLocalPath(image?: string): string | undefined {
  const trimmed = String(image || '').trim();
  if (!trimmed) {
    return undefined;
  }

  return /^(file:\/\/|content:\/\/|data:image\/|blob:)/i.test(trimmed) ? trimmed : undefined;
}

function getImageFileExtensionFromPayload(imagePayload?: string): string {
  const mimeType = detectImageMimeTypeFromBase64(String(imagePayload || '').trim());
  if (mimeType === 'image/png') {
    return 'png';
  }
  if (mimeType === 'image/gif') {
    return 'gif';
  }
  if (mimeType === 'image/webp') {
    return 'webp';
  }
  return 'jpg';
}

function estimateBase64DecodedSize(imagePayload?: string): number {
  const normalizedPayload = String(imagePayload || '').replace(/\s+/g, '');
  if (!normalizedPayload) {
    return 0;
  }

  let padding = 0;
  if (normalizedPayload.endsWith('==')) {
    padding = 2;
  } else if (normalizedPayload.endsWith('=')) {
    padding = 1;
  }

  return Math.max(0, Math.floor((normalizedPayload.length * 3) / 4) - padding);
}

function stripInlineProductImage(item: MenuItem, forceHasImage?: boolean): MenuItem {
  const localPath = extractStoredImageLocalPath(item.imagemLocalPath || item.imagem);
  const hadInlineImage = Boolean(extractStoredImagePayload(item.imagem_db || item.imagem));
  const possuiImagem = forceHasImage ?? Boolean(localPath || hadInlineImage || item.possuiImagem);
  return {
    ...item,
    imagem: localPath,
    imagem_db: undefined,
    imagemLocalPath: localPath,
    possuiImagem
  };
}

function stripInlineProductImages(products: MenuItem[]): MenuItem[] {
  let changed = false;
  const resolved = products.map((item) => {
    if (!item.imagem && !item.imagem_db && !item.imagemLocalPath) {
      return item;
    }

    changed = true;
    return stripInlineProductImage(item);
  });

  return changed ? resolved : products;
}

function buildCatalogProductsFingerprint(nextIds: number[], productJsonList: string[]): string {
  let hash = 2166136261;
  let totalLength = 0;
  const values = [JSON.stringify(nextIds), ...productJsonList];

  values.forEach((value) => {
    totalLength += value.length;
    for (let index = 0; index < value.length; index += 1) {
      hash ^= value.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
  });

  return `${values.length}:${totalLength}:${hash >>> 0}`;
}

function buildCatalogRawPayloadFingerprint(rawText?: string): string | null {
  if (!rawText) {
    return null;
  }

  let hash = 2166136261;
  for (let index = 0; index < rawText.length; index += 1) {
    hash ^= rawText.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }

  return `raw:${rawText.length}:${hash >>> 0}`;
}

function buildCatalogProductsSemanticFingerprint(products: MenuItem[]): string {
  let hash = 2166136261;
  let totalLength = 0;
  let valueCount = 0;

  const append = (value: unknown) => {
    const normalized = value === undefined || value === null ? '' : String(value);
    valueCount += 1;
    totalLength += normalized.length;

    const lengthToken = String(normalized.length);
    for (let index = 0; index < lengthToken.length; index += 1) {
      hash ^= lengthToken.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    hash ^= 58;
    hash = Math.imul(hash, 16777619);

    for (let index = 0; index < normalized.length; index += 1) {
      hash ^= normalized.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    hash ^= 124;
    hash = Math.imul(hash, 16777619);
  };

  products.forEach((item) => {
    append(item.id);
    append(item.idProduto);
    append(item.descricao);
    append(item.descricaoCurta);
    append(item.codReferencia);
    append(item.idCategoria);
    append(item.b_venda_mobile === false ? 0 : 1);
    append(item.vendaPorTamanho ? 1 : 0);
    append(item.tamanhoPadrao);
    append(item.tamanhoP);
    append(item.tamanhoM);
    append(item.tamanhoG);
    append(item.tamanhoGG);
    append(item.tamanhoExtra);
    append(item.valorTamanhoP || 0);
    append(item.valorTamanhoM || 0);
    append(item.valorTamanhoG || 0);
    append(item.valorTamanhoGG || 0);
    append(item.valorTamanhoExtra || 0);
    append(item.valorVenda || 0);
    append(item.valorUnitario || 0);
    append(item.usaQuantidadeDecimal ? 1 : 0);
    append(item.permiteFracao ? 1 : 0);
    append(item.possuiImagem ? 1 : 0);
    append(item.happyHourAtivar ? 1 : 0);
    append(item.happyHour?.valor || 0);
    append(item.happyHour?.horaInicial || '');
    append(item.happyHour?.horaFinal || '');
    append(item.happyHour?.tipoMesa ? 1 : 0);
    append(item.happyHour?.tipoComanda ? 1 : 0);
    append(item.happyHour?.segundaFeira ? 1 : 0);
    append(item.happyHour?.tercaFeira ? 1 : 0);
    append(item.happyHour?.quartaFeira ? 1 : 0);
    append(item.happyHour?.quintaFeira ? 1 : 0);
    append(item.happyHour?.sextaFeira ? 1 : 0);
    append(item.happyHour?.sabado ? 1 : 0);
    append(item.happyHour?.domingo ? 1 : 0);

    const optionals = item.opcionais || [];
    append(optionals.length);
    optionals.forEach((optional) => {
      append(optional.idOpcional);
      append(optional.descricao);
      append(optional.valor);
      append(optional.gratis ? 1 : 0);
      append(optional.opcionalP);
      append(optional.opcionalM);
      append(optional.opcionalG);
      append(optional.opcionalGG);
      append(optional.opcionalExtra);
      append(optional.valorOpcionalP || 0);
      append(optional.valorOpcionalM || 0);
      append(optional.valorOpcionalG || 0);
      append(optional.valorOpcionalGG || 0);
      append(optional.valorOpcionalExtra || 0);
    });
  });

  return `semantic:${valueCount}:${totalLength}:${hash >>> 0}`;
}

function toStoredMenuItem(item: MenuItem): StoredMenuItem {
  const { imagem, imagemLocalPath, imagem_db: discardedImagePayload, ...rest } = item;
  void discardedImagePayload;
  const storedLocalPath = extractStoredImageLocalPath(imagemLocalPath || imagem);
  return {
    ...rest,
    ...(storedLocalPath ? { imagem_local_path: storedLocalPath } : {})
  };
}

function toCatalogListMenuItem(item: MenuItem): MenuItem {
  const localPath = extractStoredImageLocalPath(item.imagemLocalPath || item.imagem);
  return {
    ...item,
    imagem: localPath,
    imagem_db: undefined,
    imagemLocalPath: localPath,
    opcionais: [],
    catalogCompact: true,
    possuiImagem: Boolean(localPath || item.possuiImagem)
  };
}

function buildCatalogPersistItems(products: MenuItem[]) {
  return products
    .map((item, index) => {
      const summary = toCatalogListMenuItem(item);
      const localPath = extractStoredImageLocalPath(summary.imagemLocalPath || summary.imagem);
      return {
        id: Number(summary.idProduto || summary.id || 0),
        sortOrder: index,
        compactJson: JSON.stringify(toStoredMenuItem(summary)),
        fullJson: JSON.stringify(toStoredMenuItem(item)),
        descricao: summary.descricao,
        descricaoCurta: summary.descricaoCurta,
        codReferencia: summary.codReferencia,
        idCategoria: summary.idCategoria,
        valorVenda: summary.valorVenda,
        valorUnitario: summary.valorUnitario,
        bVendaMobile: summary.b_venda_mobile !== false,
        vendaPorTamanho: Boolean(summary.vendaPorTamanho),
        tamanhoPadrao: summary.tamanhoPadrao,
        tamanhoP: summary.tamanhoP,
        tamanhoM: summary.tamanhoM,
        tamanhoG: summary.tamanhoG,
        tamanhoGG: summary.tamanhoGG,
        tamanhoExtra: summary.tamanhoExtra,
        valorTamanhoP: summary.valorTamanhoP,
        valorTamanhoM: summary.valorTamanhoM,
        valorTamanhoG: summary.valorTamanhoG,
        valorTamanhoGG: summary.valorTamanhoGG,
        valorTamanhoExtra: summary.valorTamanhoExtra,
        usaQuantidadeDecimal: Boolean(summary.usaQuantidadeDecimal),
        permiteFracao: Boolean(summary.permiteFracao),
        possuiImagem: Boolean(localPath || summary.possuiImagem),
        imagemLocalPath: localPath,
        happyHourAtivar: summary.happyHourAtivar,
        happyHourJson: summary.happyHour ? JSON.stringify(summary.happyHour) : undefined
      };
    })
    .filter((item) => item.id > 0);
}

function numberFromCatalogSummary(value: unknown, fallback = 0): number {
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : fallback;
}

function flagFromCatalogSummary(value: unknown, fallback = false): boolean {
  if (value === null || value === undefined) {
    return fallback;
  }
  return Number(value) !== 0;
}

function textFromCatalogSummary(value: unknown): string | undefined {
  const text = String(value || '').trim();
  return text || undefined;
}

function parseCatalogSummaryItem(row: ProductCatalogSummaryItem): MenuItem {
  const idProduto = Math.trunc(numberFromCatalogSummary(row.idProduto, 0));
  const localPath = extractStoredImageLocalPath(row.imagemLocalPath || undefined);
  const hasHappyHourMetadata = row.happyHourAtivar !== null && row.happyHourAtivar !== undefined || Boolean(row.happyHourJson);
  let happyHour: ProductHappyHour | undefined;

  if (row.happyHourJson) {
    try {
      happyHour = parseHappyHour(JSON.parse(row.happyHourJson));
    } catch {
      happyHour = undefined;
    }
  }

  return {
    id: idProduto,
    idProduto,
    descricao: String(row.descricao || ''),
    descricaoCurta: textFromCatalogSummary(row.descricaoCurta),
    codReferencia: textFromCatalogSummary(row.codReferencia),
    imagem: localPath,
    imagem_db: undefined,
    imagemLocalPath: localPath,
    possuiImagem: flagFromCatalogSummary(row.possuiImagem, Boolean(localPath)),
    idCategoria: numberFromCatalogSummary(row.idCategoria, 0) > 0 ? numberFromCatalogSummary(row.idCategoria, 0) : undefined,
    b_venda_mobile: flagFromCatalogSummary(row.bVendaMobile, true),
    vendaPorTamanho: flagFromCatalogSummary(row.vendaPorTamanho, false),
    tamanhoPadrao: String(row.tamanhoPadrao || ''),
    tamanhoP: String(row.tamanhoP || ''),
    tamanhoM: String(row.tamanhoM || ''),
    tamanhoG: String(row.tamanhoG || ''),
    tamanhoGG: String(row.tamanhoGG || ''),
    tamanhoExtra: String(row.tamanhoExtra || ''),
    valorTamanhoP: numberFromCatalogSummary(row.valorTamanhoP, 0),
    valorTamanhoM: numberFromCatalogSummary(row.valorTamanhoM, 0),
    valorTamanhoG: numberFromCatalogSummary(row.valorTamanhoG, 0),
    valorTamanhoGG: numberFromCatalogSummary(row.valorTamanhoGG, 0),
    valorTamanhoExtra: numberFromCatalogSummary(row.valorTamanhoExtra, 0),
    valorVenda: numberFromCatalogSummary(row.valorVenda, numberFromCatalogSummary(row.valorUnitario, 0)),
    valorUnitario: numberFromCatalogSummary(row.valorUnitario, numberFromCatalogSummary(row.valorVenda, 0)),
    usaQuantidadeDecimal: flagFromCatalogSummary(row.usaQuantidadeDecimal, false),
    permiteFracao: flagFromCatalogSummary(row.permiteFracao, false),
    happyHourAtivar: hasHappyHourMetadata ? flagFromCatalogSummary(row.happyHourAtivar, false) : undefined,
    happyHour,
    opcionais: [],
    catalogCompact: true
  };
}

function mergeProductWithCachedImage(product: MenuItem, cached?: MenuItem): MenuItem {
  const cachedLocalImagePath = extractStoredImageLocalPath(cached?.imagemLocalPath || cached?.imagem);
  if (product.possuiImagem === false) {
    return {
      ...product,
      imagem: undefined,
      imagem_db: undefined,
      imagemLocalPath: undefined,
      possuiImagem: false
    };
  }

  const currentLocalImagePath = extractStoredImageLocalPath(product.imagemLocalPath || product.imagem);
  const mergedLocalImagePath = currentLocalImagePath || cachedLocalImagePath;
  const mergedImagePayload = extractStoredImagePayload(product.imagem_db || product.imagem);
  const mergedInlineImage = resolveImageUri(product.imagem);

  if (product.imagem || product.imagem_db || product.imagemLocalPath) {
    return {
      ...product,
      imagem: mergedLocalImagePath || mergedInlineImage,
      imagem_db: mergedImagePayload,
      imagemLocalPath: mergedLocalImagePath,
      possuiImagem: Boolean(mergedLocalImagePath || mergedInlineImage || mergedImagePayload || product.possuiImagem)
    };
  }

  if (!cached?.imagem && !cached?.imagem_db && !cached?.imagemLocalPath) {
    return product;
  }

  return {
    ...product,
    imagem: mergedLocalImagePath,
    imagem_db: undefined,
    imagemLocalPath: mergedLocalImagePath,
    possuiImagem: Boolean(mergedLocalImagePath || product.possuiImagem)
  };
}

function mergeProductsWithCachedImages(products: MenuItem[], cachedProducts: MenuItem[]): MenuItem[] {
  if (!cachedProducts.length) {
    return products;
  }

  const cachedById = new Map<number, MenuItem>();
  cachedProducts.forEach((item) => {
    const id = Number(item.idProduto || item.id || 0);
    if (id > 0) {
      cachedById.set(id, item);
    }
  });
  return products.map((item) => mergeProductWithCachedImage(item, cachedById.get(Number(item.idProduto || item.id || 0))));
}

function hasMissingCatalogImageCache(products: MenuItem[]): boolean {
  return products.some(
    (item) => Boolean(item.possuiImagem) && !extractStoredImageLocalPath(item.imagemLocalPath || item.imagem)
  );
}

function parseOptional(value: any): ProductOptional {
  const baseValue = parseNumber(resolveField(value, ['valor', 'valorOpcional', 'valor_opcional']), 0);
  return {
    idOpcional: parseNumber(resolveField(value, ['idOpcional', 'id_opcional', 'id']), 0),
    descricao: String(resolveField(value, ['descricao', 'descricaoOpcional', 'descricao_opcional', 'opcional']) ?? '').trim(),
    valor: baseValue,
    gratis: parseBoolean(resolveField(value, ['gratis', 'b_gratis']), false),
    opcionalP: sanitizeText(resolveField(value, ['opcionalP', 'opc_p', 'opcional_p']) ?? '', ''),
    opcionalM: sanitizeText(resolveField(value, ['opcionalM', 'opc_m', 'opcional_m']) ?? '', ''),
    opcionalG: sanitizeText(resolveField(value, ['opcionalG', 'opc_g', 'opcional_g']) ?? '', ''),
    opcionalGG: sanitizeText(resolveField(value, ['opcionalGG', 'opc_gg', 'opcional_gg']) ?? '', ''),
    opcionalExtra: sanitizeText(resolveField(value, ['opcionalExtra', 'opc_extra', 'opcional_extra']) ?? '', ''),
    valorOpcionalP: parseNumber(resolveField(value, ['valorOpcionalP', 'valor_opc_p', 'valor_opcional_p']), baseValue),
    valorOpcionalM: parseNumber(resolveField(value, ['valorOpcionalM', 'valor_opc_m', 'valor_opcional_m']), baseValue),
    valorOpcionalG: parseNumber(resolveField(value, ['valorOpcionalG', 'valor_opc_g', 'valor_opcional_g']), baseValue),
    valorOpcionalGG: parseNumber(resolveField(value, ['valorOpcionalGG', 'valor_opc_gg', 'valor_opcional_gg']), baseValue),
    valorOpcionalExtra: parseNumber(resolveField(value, ['valorOpcionalExtra', 'valor_opc_extra', 'valor_opcional_extra']), baseValue)
  };
}

function hasHappyHourSourceMetadata(value: any): boolean {
  const nested = resolveField(value, ['happyHour', 'happy_hour']);
  if (nested && typeof nested === 'object') {
    return true;
  }

  const keys = [
    'happyHourAtivar',
    'happy_hour_ativar',
    'hh_ativar',
    'hh_dia_seg',
    'hh_dia_ter',
    'hh_dia_qua',
    'hh_dia_qui',
    'hh_dia_sex',
    'hh_dia_sab',
    'hh_dia_dom',
    'hh_inicial',
    'hh_final',
    'hh_valor'
  ];

  return keys.some((key) => resolveField(value, [key]) !== undefined);
}

function parseHappyHour(value: any): ProductHappyHour {
  const nested = resolveField(value, ['happyHour', 'happy_hour']);
  const hasNestedSource = Boolean(nested && typeof nested === 'object');
  const source = hasNestedSource ? nested : value;

  return {
    segundaFeira: parseBoolean(resolveField(source, ['segundaFeira', 'segunda_feira', 'hh_dia_seg']), false),
    tercaFeira: parseBoolean(resolveField(source, ['tercaFeira', 'terca_feira', 'hh_dia_ter']), false),
    quartaFeira: parseBoolean(resolveField(source, ['quartaFeira', 'quarta_feira', 'hh_dia_qua']), false),
    quintaFeira: parseBoolean(resolveField(source, ['quintaFeira', 'quinta_feira', 'hh_dia_qui']), false),
    sextaFeira: parseBoolean(resolveField(source, ['sextaFeira', 'sexta_feira', 'hh_dia_sex']), false),
    sabado: parseBoolean(resolveField(source, ['sabado', 'sábado', 'hh_dia_sab']), false),
    domingo: parseBoolean(resolveField(source, ['domingo', 'hh_dia_dom']), false),
    tipoMesa: parseBoolean(resolveField(source, ['tipoMesa', 'tipo_mesa', 'hh_tipo_mesa']), false),
    tipoComanda: parseBoolean(resolveField(source, ['tipoComanda', 'tipo_comanda', 'hh_tipo_comanda']), false),
    horaInicial: (() => {
      const raw = resolveField(source, ['horaInicial', 'hora_inicial', 'hh_inicial']);
      if (typeof raw === 'number') return raw;
      if (typeof raw === 'string') return raw.trim();
      return undefined;
    })(),
    horaFinal: (() => {
      const raw = resolveField(source, ['horaFinal', 'hora_final', 'hh_final']);
      if (typeof raw === 'number') return raw;
      if (typeof raw === 'string') return raw.trim();
      return undefined;
    })(),
    valor: parseNumber(
      resolveField(source, hasNestedSource ? ['valor', 'hh_valor'] : ['hh_valor', 'valorHappyHour', 'valor_happy_hour']),
      0
    )
  };
}

function normalizeSizeValue(value: unknown): number {
  const asNumber = Number(String(value || 0).replace(',', '.'));
  return Number.isFinite(asNumber) ? asNumber : 0;
}

function parseTimeToMinutes(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    const normalized = value >= 0 && value <= 1 ? value : Math.abs(value % 1);
    return Math.round(normalized * 24 * 60);
  }

  const raw = sanitizeText(value, '').trim();
  if (!raw) {
    return null;
  }

  const numeric = Number(raw.replace(',', '.'));
  if (Number.isFinite(numeric)) {
    const normalized = numeric >= 0 && numeric <= 1 ? numeric : Math.abs(numeric % 1);
    return Math.round(normalized * 24 * 60);
  }

  const match = raw.match(/(\d{1,2}):(\d{2})(?::(\d{2}))?/);
  if (!match) {
    return null;
  }

  const hours = Number(match[1] || 0);
  const minutes = Number(match[2] || 0);
  const seconds = Number(match[3] || 0);
  if (!Number.isFinite(hours) || !Number.isFinite(minutes) || !Number.isFinite(seconds)) {
    return null;
  }

  return hours * 60 + minutes + Math.round(seconds / 60);
}

function currentTimeInMinutes(referenceDate: Date): number {
  return referenceDate.getHours() * 60 + referenceDate.getMinutes();
}

function isHappyHourDayEnabled(item: MenuItem, referenceDate: Date): boolean {
  const happyHour = item.happyHour;
  if (!happyHour) {
    return false;
  }

  switch (referenceDate.getDay()) {
    case 0:
      return Boolean(happyHour.domingo);
    case 1:
      return Boolean(happyHour.segundaFeira);
    case 2:
      return Boolean(happyHour.tercaFeira);
    case 3:
      return Boolean(happyHour.quartaFeira);
    case 4:
      return Boolean(happyHour.quintaFeira);
    case 5:
      return Boolean(happyHour.sextaFeira);
    case 6:
      return Boolean(happyHour.sabado);
    default:
      return false;
  }
}

function isHappyHourSaleTypeEnabled(
  item: MenuItem,
  saleType?: 'mesa' | 'comanda'
): boolean {
  const happyHour = item.happyHour;
  if (!happyHour) {
    return false;
  }

  const mesaEnabled = happyHour.tipoMesa === true;
  const comandaEnabled = happyHour.tipoComanda === true;
  if (!mesaEnabled && !comandaEnabled) {
    return true;
  }

  if (saleType === 'mesa') {
    return mesaEnabled;
  }

  if (saleType === 'comanda') {
    return comandaEnabled;
  }

  return mesaEnabled || comandaEnabled;
}

export function hasMenuItemHappyHourMetadata(item?: MenuItem | null): boolean {
  if (!item || typeof item !== 'object') {
    return false;
  }

  return item.happyHourAtivar !== undefined || item.happyHour !== undefined;
}

export function isMenuItemHappyHourActive(
  item: MenuItem,
  referenceDate = new Date(),
  saleType?: 'mesa' | 'comanda'
): boolean {
  if (!item.happyHourAtivar || !item.happyHour) {
    return false;
  }

  if (!isHappyHourSaleTypeEnabled(item, saleType)) {
    return false;
  }

  if (!isHappyHourDayEnabled(item, referenceDate)) {
    return false;
  }

  const startMinutes = parseTimeToMinutes(item.happyHour.horaInicial);
  const endMinutes = parseTimeToMinutes(item.happyHour.horaFinal);
  if (startMinutes === null || endMinutes === null) {
    return false;
  }

  const nowMinutes = currentTimeInMinutes(referenceDate);
  return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
}

export function getMenuItemLaunchUnitPrice(
  item: MenuItem,
  sizeCode = '',
  options?: {
    enableHappyHour?: boolean;
    referenceDate?: Date;
    saleType?: 'mesa' | 'comanda';
  }
): number {
  const referenceDate = options?.referenceDate ?? new Date();
  if (options?.enableHappyHour !== false && isMenuItemHappyHourActive(item, referenceDate, options?.saleType)) {
    return Number(item.happyHour?.valor || 0);
  }

  if (!item.vendaPorTamanho && !item.permiteFracao) {
    return Number(item.valorUnitario || item.valorVenda || 0);
  }

  const candidates: Record<string, unknown> = {
    P: item.valorTamanhoP,
    M: item.valorTamanhoM,
    G: item.valorTamanhoG,
    GG: item.valorTamanhoGG,
    E: item.valorTamanhoExtra,
    EXTRA: item.valorTamanhoExtra
  };

  const key = String(sizeCode || '').toUpperCase();
  const direct = normalizeSizeValue(candidates[key]);
  if (direct > 0) return direct;

  const padrao = String(item.tamanhoPadrao || '').toUpperCase();
  const fallback = normalizeSizeValue(candidates[padrao]);
  if (fallback > 0) return fallback;

  return Number(item.valorUnitario || item.valorVenda || 0);
}

function parseMenuItem(value: any): MenuItem {
  const normalizedLocalImage = normalizeImageValue(resolveField(value, ['imagemLocalPath', 'imagem_local_path']));
  const normalizedImage = normalizeImageValue(resolveField(value, ['imagem', 'imagem_db', 'imagemDb']));
  const storedImagePayload = extractStoredImagePayload(
    normalizeImageValue(resolveField(value, ['imagem_db', 'imagemDb'])) || normalizedImage
  );
  const rawOptionals = resolveField(value, [
    'opcionais',
    'opcionaisProduto',
    'produtoOpcional',
    'produtoOpcionais',
    'opcionais_produto',
    'opcional'
  ]);
  const normalizedOptionals = Array.isArray(rawOptionals)
    ? rawOptionals
    : rawOptionals && typeof rawOptionals === 'object'
      ? [rawOptionals]
      : [];
  const hasHappyHourMetadata = hasHappyHourSourceMetadata(value);
  const item: MenuItem = {
    id: parseNumber(resolveField(value, ['idProduto', 'id']), 0),
    idProduto: parseNumber(resolveField(value, ['idProduto', 'id']), 0),
    descricao: String(value?.descricao ?? ''),
    descricaoCurta: value?.descricaoCurta ? String(value.descricaoCurta) : undefined,
    codReferencia: (() => {
      const rawCode = resolveField(value, ['codReferencia', 'cod_referencia', 'codigoReferencia', 'codigo_referencia', 'mat_004']);
      const normalizedCode = rawCode === undefined || rawCode === null ? '' : String(rawCode).trim();
      return normalizedCode || undefined;
    })(),
    imagem: normalizedLocalImage || normalizedImage,
    imagem_db: storedImagePayload,
    imagemLocalPath: normalizedLocalImage,
    catalogCompact: parseBoolean(resolveField(value, ['catalogCompact', 'catalog_compact']), false) || undefined,
    possuiImagem: parseBoolean(
      resolveField(value, ['possuiImagem', 'possui_imagem', 'temImagem', 'tem_imagem']),
      Boolean(normalizedLocalImage || normalizedImage)
    ),
    idCategoria: (() => {
      const rawCategory = resolveField(value, ['idCategoria', 'idcategoria']);
      return rawCategory ? parseNumber(rawCategory, 0) : undefined;
    })(),
    b_venda_mobile: parseBoolean(
      resolveField(value, [
        'b_venda_mobile',
        'bVendamobile',
        'bVendaMobile',
        'permiteVendaMobile',
        'PermiteVendaAPP',
        'permiteVendaAPP',
        'permite_venda_app'
      ]),
      true
    ),
    vendaPorTamanho: parseBoolean(
      resolveField(value, ['vendaPorTamanho', 'VendaPorTamanho', 'venda_por_tamanho', 'b_venda_tamanho', 'vendaTamanho']),
      false
    ),
    tamanhoPadrao: String(resolveField(value, ['tamanhoPadrao', 'tamanho_padrao']) ?? '').trim(),
    tamanhoP: String(resolveField(value, ['tamanhoP', 'tamanho_p']) ?? '').trim(),
    tamanhoM: String(resolveField(value, ['tamanhoM', 'tamanho_m']) ?? '').trim(),
    tamanhoG: String(resolveField(value, ['tamanhoG', 'tamanho_g']) ?? '').trim(),
    tamanhoGG: String(resolveField(value, ['tamanhoGG', 'tamanho_gg']) ?? '').trim(),
    tamanhoExtra: String(resolveField(value, ['tamanhoExtra', 'tamanho_extra']) ?? '').trim(),
    valorTamanhoP: parseNumber(
      resolveField(value, ['valorTamanhoP', 'valor_tamanho_p', 'valorP']),
      0
    ),
    valorTamanhoM: parseNumber(
      resolveField(value, ['valorTamanhoM', 'valor_tamanho_m', 'valorM']),
      0
    ),
    valorTamanhoG: parseNumber(
      resolveField(value, ['valorTamanhoG', 'valor_tamanho_g', 'valorG']),
      0
    ),
    valorTamanhoGG: parseNumber(
      resolveField(value, ['valorTamanhoGG', 'valor_tamanho_gg', 'valorGG']),
      0
    ),
    valorTamanhoExtra: parseNumber(
      resolveField(value, ['valorTamanhoExtra', 'valor_tamanho_extra', 'valorExtra']),
      0
    ),
    valorVenda: parseNumber(resolveField(value, ['valorVenda', 'valor_venda']), parseNumber(resolveField(value, ['valorUnitario', 'valor_unitario']), 0)),
    valorUnitario: parseNumber(resolveField(value, ['valorUnitario', 'valor_unitario']), parseNumber(resolveField(value, ['valorVenda', 'valor_venda']), 0)),
    usaQuantidadeDecimal: parseBoolean(
      resolveField(value, ['usaQuantidadeDecimal', 'usaQuantidadeDecimal', 'usa_quantidade_decimal']),
      false
    ),
    happyHourAtivar: hasHappyHourMetadata
      ? parseBoolean(resolveField(value, ['happyHourAtivar', 'happy_hour_ativar', 'hh_ativar']), false)
      : undefined,
    happyHour: hasHappyHourMetadata ? parseHappyHour(value) : undefined,
    permiteFracao: parseBoolean(
      resolveField(value, [
        'permiteFracao',
        'PermiteFracao',
        'permite_fracao',
        'permiteFracionado',
        'PermiteFracionado',
        'permite_fracionado',
        'b_permite_frac',
        'b_permite_fracao'
      ]),
      false
    ),
    opcionais: normalizedOptionals
      .map(parseOptional)
      .filter((optional) => optional.idOpcional > 0 || optional.descricao.trim().length > 0)
  };
  if (!item.id) {
    item.id = item.idProduto;
  }
  if (!item.valorVenda && item.valorUnitario) {
    item.valorVenda = item.valorUnitario;
  }
  return item;
}

function parseUserProfile(value: any): UserProfile {
  return {
    idUsuario: parseNumber(value?.idUsuario ?? value?.id ?? value?.usu_001, 1),
    nome: sanitizeText(value?.nome ?? value?.name ?? value?.usu_002, fallbackProfile.nome),
    login: sanitizeText(value?.login ?? value?.usuario ?? value?.usu_003, fallbackProfile.login),
    permiteCancelarItemMobile: parseBoolean(
      value?.permiteCancelarItemMobile ?? value?.b_permite_canc_item_mobile,
      Boolean(fallbackProfile.permiteCancelarItemMobile)
    ),
    permitePreFechamentoMesaComanda: parseBoolean(
      value?.permitePreFechamentoMesaComanda ?? value?.b_permite_prefechamento_mesa_comanda,
      Boolean(fallbackProfile.permitePreFechamentoMesaComanda)
    ),
    permiteFechamentoMesaComanda: parseBoolean(
      value?.permiteFechamentoMesaComanda ?? value?.b_permite_fechamento_mesa_comanda,
      Boolean(fallbackProfile.permiteFechamentoMesaComanda)
    ),
    permiteAlterarTaxa10: parseBoolean(
      value?.permiteAlterarTaxa10 ?? value?.b_permite_alterar_taxa10,
      Boolean(fallbackProfile.permiteAlterarTaxa10)
    ),
    permiteJuntarMesaComanda: parseBoolean(
      value?.permiteJuntarMesaComanda ?? value?.PermiteJuntarMesaComanda ?? value?.b_permite_juntar_mesa_comanda,
      Boolean(fallbackProfile.permiteJuntarMesaComanda)
    ),
    permiteReabrirMesaComanda: parseBoolean(
      value?.permiteReabrirMesaComanda ?? value?.PermiteReabrirMesaComanda ?? value?.b_reabrir_mesa_comanda,
      Boolean(fallbackProfile.permiteReabrirMesaComanda)
    ),
    permitePagamentoParcial: parseBoolean(
      value?.permitePagamentoParcial ?? value?.PermitePagamentoParcial ?? value?.b_permite_pag_antecipado_mesa_comanda,
      Boolean(fallbackProfile.permitePagamentoParcial)
    ),
    permiteDescontoFechamento: parseBoolean(
      value?.permiteDescontoFechamento ??
        value?.PermiteDescontoFechamento ??
        value?.b_permite_desconto_fechamento_mesa_comanda,
      Boolean(fallbackProfile.permiteDescontoFechamento)
    )
  };
}

function parseTable(value: any, source: 'mesa' | 'comanda' = 'mesa'): TableOrder {
  const venda: any = value?.venda && typeof value.venda === 'object' ? value.venda : null;
  const idComanda = parseNumber(
    resolveField(value, ['idComanda', 'id_comanda', 'id', 'idTabela']),
    parseNumber(value?.numeroComanda, 0)
  );
  const isComanda = source === 'comanda' || idComanda > 0;
  const statusFromBody = normalizeStatus(value?.situacao ?? venda?.situacao);
  const tableNumero = parseNumber(
    resolveField(value, ['numero', source === 'comanda' ? 'com_003' : 'mes_003']),
    parseNumber(resolveField(value, ['idMesa', 'id_mesa', 'id', 'idTabela']), 0)
  );
  const mesaNumero = tableNumero || parseNumber(venda?.numero, 0);
  const vendaComandaNumero = parseNumber(
    resolveField((venda ?? {}) as Record<string, unknown>, ['numeroComanda', 'numero_comanda', 'ven_026']),
    0
  );
  const comandaNumero = parseNumber(
    resolveField(value, ['numeroComanda', 'numero_comanda', 'com_003']),
    isComanda ? tableNumero || vendaComandaNumero || idComanda : vendaComandaNumero || idComanda
  );
  const resolvedMesaId = parseNumber(
    resolveField(value, ['idMesa', 'id_mesa', 'id', 'idTabela']),
    mesaNumero || parseNumber(venda?.idMesa, 0)
  );
  const vendaValorTotal = parseNumber(
    resolveField((venda ?? {}) as Record<string, unknown>, ['valorTotal', 'valor_total', 'valor']),
    0
  );
  const vendaValorPagamentoAntecipado = parseNumber(
    resolveField((venda ?? {}) as Record<string, unknown>, ['valorPagamentoAntecipado', 'valor_pagamento_antecipado']),
    parseNumber(resolveField(value, ['valorPagamentoAntecipado', 'valor_pagamento_antecipado']), 0)
  );
  const tableId = isComanda ? (idComanda || resolvedMesaId || parseNumber(venda?.numero, 0)) : resolvedMesaId;
  const safeTableId = parseNumber(tableId, 0);
  const normalizedMesaNumero = mesaNumero || undefined;
  const normalizedComandaNumero = (isComanda ? (comandaNumero || mesaNumero) : comandaNumero) || undefined;
  const nomeInformado = String(
    value?.nomeMesaComanda ??
    value?.descricao ??
    value?.mesaNome ??
    value?.comandaNome ??
    ''
  );

  return {
    idMesa: safeTableId,
    idComanda: idComanda || undefined,
    numeroMesa: normalizedMesaNumero,
    numeroComanda: normalizedComandaNumero,
    nomeMesaComanda: normalizeNomeMesa(
      resolvedMesaId,
      isComanda ? 'Comanda' : 'Mesa',
      normalizedComandaNumero || normalizedMesaNumero || 0,
      nomeInformado
    ),
    situacao: sanitizeText(value?.situacao, statusFromBody) || sanitizeText(venda?.situacao, ''),
    statusOriginal: sanitizeText(value?.situacao ?? venda?.situacao, ''),
    statusCode: sanitizeText(value?.statusCode ?? value?.status, ''),
    valorTotal: parseNumber(
      value?.valorTotal,
      parseNumber(
        value?.valor,
        parseNumber(value?.venda?.valorTotal, parseNumber(value?.venda?.valor, 0))
      )
    ),
    idVenda: parseNumber(value?.idVenda, parseNumber(venda?.idVenda, 0)),
    tipo: isComanda ? 'comanda' : 'mesa',
    venda: venda && typeof venda === 'object'
      ? {
          idVenda: parseNumber(venda.idVenda, 0),
          situacao: venda.situacao ? String(venda.situacao) : undefined,
          nomeMesaComanda: venda.nomeMesaComanda ? String(venda.nomeMesaComanda) : undefined,
          valorTotal: vendaValorTotal,
          valorPagamentoAntecipado: vendaValorPagamentoAntecipado
        }
      : undefined
  };
}

function parsePaymentMethod(value: any): PaymentMethod {
  const sfiRaw = resolveField(value, [
    'sfiCodigo',
    'sfi_codigo',
    'sfi',
    'sfiCode',
    'codigoSfi',
    'codigo_sfi'
  ]);
  const parsedSfi =
    sfiRaw === undefined || sfiRaw === null || String(sfiRaw).trim() === ''
      ? undefined
      : parseNumber(sfiRaw, 0);

  return {
    codigo: parseNumber(resolveField(value, ['codigo', 'id', 'idFormaPagamento', 'idFormaPgto', 'id_formapgto', 'for_001']), 0),
    descricao: sanitizeText(
      resolveField(value, ['descricao', 'nome', 'descricaoFormaPagamento', 'descricao_forma_pagamento', 'for_002']),
      ''
    ),
    sfiCodigo: typeof parsedSfi === 'number' && parsedSfi > 0 ? parsedSfi : undefined,
    sfiDescricao: sanitizeText(resolveField(value, ['sfiDescricao', 'sfi_descricao', 'descricaoSfi']), ''),
    cortesia: parseBoolean(resolveField(value, ['cortesia', 'b_cortesia']), false),
    utilizaControleCartao: parseBoolean(resolveField(value, ['utilizaControleCartao', 'utiliza_controle_cartao']), false),
    utilizaPagamentoOnline: parseBoolean(
      resolveField(value, [
        'utilizaPagamentoOnline',
        'utiliza_pagamento_online',
        'utilizaPagamentoEletronico',
        'utiliza_pagamento_eletronico',
        'pagamentoEletronico',
        'pagamento_eletronico'
      ]),
      false
    ),
    pagamentoEletronico: parseBoolean(
      resolveField(value, ['pagamentoEletronico', 'pagamento_eletronico', 'utilizaPagamentoOnline', 'utiliza_pagamento_online']),
      false
    ),
    prazoCartao: parseNumber(resolveField(value, ['prazoCartao', 'prazo_cartao']), 0),
    taxaCartao: parseNumber(resolveField(value, ['taxaCartao', 'taxa_cartao']), 0),
    idContaCorrente: parseNumber(resolveField(value, ['idContaCorrente', 'id_conta_corrente', 'id_contacorrente']), 0)
  };
}

function parseCompanyConfig(value: any): CompanyConfig {
  return {
    idEmpresa: parseNumber(value?.idEmpresa, parseNumber(value?.id, 0)),
    usaVendaPorTamanho: parseBoolean(value?.usaVendaPorTamanho ?? value?.vendaPorTamanho, false),
    taxaAdicionalMesa: parseBoolean(
      value?.taxaAdicionalMesa ?? value?.taxa_adicional_mesa ?? value?.taxaAdicional,
      false
    ),
    taxaServicoPct: parseNumber(value?.taxaServicoPct ?? value?.taxaServico ?? value?.taxa_servico, 0),
    couvertAtivo: parseBoolean(value?.couvertMesa ?? value?.couvertAtivo, false),
    couvertMascFemObrigatorio: parseBoolean(
      value?.couvertObrigatorioMesa ?? value?.couvertObrigatorio ?? value?.couvertMascFemObrigatorio,
      false
    ),
    valorCouvertMasculino: parseNumber(value?.valorCouvertMasculino ?? value?.valor_couvert_masc_mesa, 0),
    valorCouvertFeminino: parseNumber(value?.valorCouvertFeminino ?? value?.valor_couvert_fem_mesa, 0)
  };
}

function parseCompanyInfo(value: any): CompanyInfo {
  return {
    idEmpresa: parseNumber(value?.idEmpresa ?? value?.id ?? value?.emp_001, 0),
    utilizaRPMovel: parseBoolean(value?.utilizaRPMovel ?? value?.utiliza_rp_movel ?? value?.utilizarpmovel, true),
    utilizaIntegracaoStone: parseBoolean(
      value?.utilizaIntegracaoStone ?? value?.rp_movel_integracao_stone,
      true
    ),
    utilizaIntegracaoCielo: parseBoolean(
      value?.utilizaIntegracaoCielo ?? value?.rp_movel_integracao_cielo,
      true
    ),
    utilizaIntegracaoPagBank: parseBoolean(
      value?.utilizaIntegracaoPagBank ?? value?.rp_movel_integracao_pagbank,
      true
    ),
    utilizaIntegracaoGetNet: parseBoolean(
      value?.utilizaIntegracaoGetNet ?? value?.rp_movel_integracao_getnet,
      true
    )
  };
}

export function applyCompanyPolicyToSettings(
  settings: MobileAppSettings,
  company: CompanyInfo | null
): MobileAppSettings {
  if (!company) {
    return settings;
  }

  let tipoIntegracao = settings.tipoIntegracao;
  if (tipoIntegracao === 'stone' && !company.utilizaIntegracaoStone) {
    tipoIntegracao = 'nenhum';
  }
  if (tipoIntegracao === 'cielo' && !company.utilizaIntegracaoCielo) {
    tipoIntegracao = 'nenhum';
  }
  if (tipoIntegracao === 'pagbank' && !company.utilizaIntegracaoPagBank) {
    tipoIntegracao = 'nenhum';
  }
  if (tipoIntegracao === 'getnet' && !company.utilizaIntegracaoGetNet) {
    tipoIntegracao = 'nenhum';
  }

  const tipoFoiBloqueado = tipoIntegracao !== settings.tipoIntegracao;

  return {
    ...settings,
    tipoIntegracao,
    utilizaMaquininhaStone: tipoFoiBloqueado ? false : settings.utilizaMaquininhaStone
  };
}

function parseSaleLineOptional(value: any): SaleLineOptional {
  return {
    idOpcional: parseNumber(value?.idOpcional, parseNumber(value?.id, 0)),
    descricao: String(value?.descricao ?? ''),
    valor: parseNumber(value?.valor, 0),
    gratis: parseBoolean(value?.gratis, false)
  };
}

function parseSaleLineFraction(value: any): SaleLineFraction {
  const descricaoTamanho = resolveField(value, ['descricaoTamanho', 'DescricaoTamanho', 'descricao_tamanho']);
  return {
    idProduto: parseNumber(resolveField(value, ['idProduto', 'id_produto', 'mat_001']), 0),
    produtoDescricao: String(resolveField(value, ['produtoDescricao', 'descricao', 'mat_003']) ?? ''),
    numeroItem: parseNumber(resolveField(value, ['numeroItem', 'ite_001']), 0),
    quantidade: parseNumber(value?.quantidade, 0),
    valorUnitario: parseNumber(value?.valorUnitario, 0),
    valorTotal: parseNumber(value?.valorTotal, 0),
    acrescimo: parseNumber(value?.acrescimo, 0),
    observacao: value?.observacao ? String(value.observacao) : undefined,
    descricaoTamanho: descricaoTamanho ? String(descricaoTamanho) : undefined,
    opcionais: Array.isArray(value?.opcionais) ? value.opcionais.map(parseSaleLineOptional) : []
  };
}

function parseSaleLine(value: any): SaleLine {
  const normalizedSituacao = normalizeStatus(value?.situacao ?? value?.sit_001);
  const rawNomeGarcom = resolveField(value, ['nomeGarcom', 'nome_garcom']);
  const nomeGarcom = rawNomeGarcom ? String(rawNomeGarcom).trim() : '';
  return {
    idProduto: parseNumber(value?.idProduto, 0),
    produtoDescricao: String(value?.produtoDescricao ?? ''),
    imagem: normalizeImageValue(resolveField(value, ['imagem', 'imagem_db', 'imagemDb'])),
    numeroItem: parseNumber(value?.numeroItem, 0),
    itemFracionado: parseNumber(value?.itemFracionado ?? value?.item_fracionado, 0),
    situacao: normalizedSituacao.includes('cancel') ? 'cancelada' : normalizedSituacao || undefined,
    quantidade: parseNumber(value?.quantidade, 0),
    valorUnitario: parseNumber(value?.valorUnitario, 0),
    valorTotal: parseNumber(value?.valorTotal, 0),
    desconto: parseNumber(value?.desconto, 0),
    acrescimo: parseNumber(value?.acrescimo, 0),
    idGarcom: parseNumber(resolveField(value, ['idGarcom', 'gar_001']), 0),
    nomeGarcom: nomeGarcom || undefined,
    tamanho: String(value?.tamanho ?? 'U'),
    descricaoTamanho: value?.descricaoTamanho ? String(value.descricaoTamanho) : undefined,
    dataHora: resolveField(value, ['dataHora', 'data_hora', 'dataLancamento', 'data_lancamento'])
      ? String(resolveField(value, ['dataHora', 'data_hora', 'dataLancamento', 'data_lancamento']))
      : undefined,
    observacao: value?.observacao ? String(value.observacao) : undefined,
    vendaPorTamanho: parseBoolean(value?.vendaPorTamanho, false),
    idMesaVinculada: parseNumber(value?.idMesaVinculada, 0),
    opcionais: Array.isArray(value?.opcionais) ? value.opcionais.map(parseSaleLineOptional) : [],
    fracoes: Array.isArray(value?.fracoes) ? value.fracoes.map(parseSaleLineFraction) : []
  };
}

function parseSalePayment(value: any): SalePayment {
  const forma = resolveField(value, ['formaPagamento', 'forma_pagamento', 'forma', 'pagamento']);
  return {
    idVendaPagamentoAntecipado: parseNumber(
      resolveField(value, ['idVendaPagamentoAntecipado', 'id_venda_pag_antecipado', 'idVendaPagAntecipado']),
      0
    ),
    idFormaPagamento: parseNumber(
      resolveField(value, ['idFormaPagamento', 'idFormapagamento', 'idFormaPgto', 'id_formapgto', 'formaPagamentoId', 'for_001']),
      0
    ),
    valor: parseNumber(
      resolveField(value, ['valor', 'valorPagamento', 'valor_pagamento', 'valorPago', 'valor_pago', 'valor_antecipado']),
      0
    ),
    formaPagamento: forma ? parsePaymentMethod(forma) : undefined,
    dataHora: resolveField(value, ['dataHora', 'data_hora'])
      ? String(resolveField(value, ['dataHora', 'data_hora']))
      : undefined,
    observacao: resolveField(value, ['observacao', 'Observacao'])
      ? String(resolveField(value, ['observacao', 'Observacao']))
      : undefined,
    taxaServico: parseBoolean(resolveField(value, ['TaxaServico', 'taxaServico', 'b_taxa']), false)
  };
}

function parseSale(value: any): Sale {
  return {
    idVenda: parseNumber(value?.idVenda, 0),
    idUsuario: parseNumber(resolveField(value, ['idUsuario', 'id_usuario', 'usu_001']), 0),
    valor: parseNumber(value?.valor, 0),
    valorTotal: parseNumber(value?.valorTotal, parseNumber(value?.valor, 0)),
    situacao: value?.situacao ? String(value.situacao) : undefined,
    numeroMesa: parseNumber(value?.numeroMesa, 0),
    numeroComanda: parseNumber(value?.numeroComanda, 0),
    nomeMesaComanda: value?.nomeMesaComanda ? String(value.nomeMesaComanda) : undefined,
    numeroPessoas: parseNumber(value?.numeroPessoas, 0),
    numeroCouvertMasculino: parseNumber(
      resolveField(value, ['numeroCouvertMasculino', 'numero_couvert_masculino', 'nro_couvert_m']),
      0
    ),
    numeroCouvertFeminino: parseNumber(
      resolveField(value, ['numeroCouvertFeminino', 'numero_couvert_feminino', 'nro_couvert_f']),
      0
    ),
    valorCouvertMasculino: parseNumber(
      resolveField(value, [
        'valorCouvertMasculino',
        'valor_couvert_m',
        'valor_couvert_masc_mesa',
        'valor_couvert_masc_comanda'
      ]),
      0
    ),
    valorCouvertFeminino: parseNumber(
      resolveField(value, [
        'valorCouvertFeminino',
        'valor_couvert_f',
        'valor_couvert_fem_mesa',
        'valor_couvert_fem_comanda'
      ]),
      0
    ),
    valorTaxaServico: parseNumber(resolveField(value, ['valorTaxaServico', 'valor_taxa_servico', 'ven_008']), 0),
    valorEntrada: parseNumber(resolveField(value, ['valorEntrada', 'valor_entrada']), 0),
    valorPagamentoAntecipado: parseNumber(
      resolveField(value, ['valorPagamentoAntecipado', 'valor_pagamento_antecipado', 'valorPagoAntecipado']),
      0
    ),
    valorDesconto: parseNumber(resolveField(value, ['valorDesconto', 'valor_desconto']), 0),
    tipoDesconto:
      value?.tipoDesconto !== undefined && value?.tipoDesconto !== null
        ? parseNumber(value.tipoDesconto, 0)
        : undefined,
    itens: Array.isArray(value?.itens) ? value.itens.map(parseSaleLine) : [],
    pagamentos: Array.isArray(resolveField(value, ['pagamentos', 'pagamentosAntecipados', 'pagamentoAntecipado']))
      ? (resolveField(value, ['pagamentos', 'pagamentosAntecipados', 'pagamentoAntecipado']) as any[]).map(parseSalePayment)
      : []
  };
}

function normalizeImageValue(value: unknown): string | undefined {
  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (!trimmed) {
      return undefined;
    }

    if (/^(data:image\/|https?:\/\/|file:\/\/|content:\/\/)/i.test(trimmed)) {
      return trimmed;
    }

    return buildDataUri(trimmed, detectImageMimeTypeFromBase64(trimmed));
  }

  const bytes = extractImageBytes(value);
  if (!bytes?.length) {
    return undefined;
  }

  return buildDataUri(bytesToBase64(bytes), detectImageMimeTypeFromBytes(bytes));
}

function extractImageBytes(value: unknown): number[] | undefined {
  if (Array.isArray(value) && value.every((item) => Number.isFinite(item))) {
    return value.map((item) => Number(item) & 0xff);
  }

  if (!value || typeof value !== 'object') {
    return undefined;
  }

  const candidateMap = value as Record<string, unknown>;
  const nested =
    candidateMap.$values ??
    candidateMap.values ??
    candidateMap.bytes ??
    candidateMap.data ??
    candidateMap.imagem;

  if (Array.isArray(nested) && nested.every((item) => Number.isFinite(item))) {
    return nested.map((item) => Number(item) & 0xff);
  }

  return undefined;
}

function bytesToBase64(bytes: number[]): string {
  const chunks: string[] = [];
  for (let index = 0; index < bytes.length; index += 0x8000) {
    const slice = bytes.slice(index, index + 0x8000);
    chunks.push(String.fromCharCode(...slice));
  }
  return toBase64(chunks.join(''));
}

export function resolveImageUri(image?: string): string | undefined {
  if (!image) {
    return undefined;
  }

  const trimmed = image.trim();
  if (!trimmed) {
    return undefined;
  }

  if (/^(data:image\/|https?:\/\/|file:\/\/|content:\/\/|blob:)/i.test(trimmed)) {
    return trimmed;
  }

  return buildDataUri(trimmed, detectImageMimeTypeFromBase64(trimmed));
}

function buildDataUri(base64: string, mimeType: string): string {
  return `data:${mimeType};base64,${base64}`;
}

function detectImageMimeTypeFromBase64(base64: string): string {
  if (base64.startsWith('iVBOR')) {
    return 'image/png';
  }

  if (base64.startsWith('/9j/')) {
    return 'image/jpeg';
  }

  if (base64.startsWith('R0lGOD')) {
    return 'image/gif';
  }

  if (base64.startsWith('UklGR')) {
    return 'image/webp';
  }

  if (base64.startsWith('Qk')) {
    return 'image/bmp';
  }

  return 'image/jpeg';
}

function detectImageMimeTypeFromBytes(bytes: number[]): string {
  if (bytes.length >= 8 &&
      bytes[0] === 137 &&
      bytes[1] === 80 &&
      bytes[2] === 78 &&
      bytes[3] === 71) {
    return 'image/png';
  }

  if (bytes.length >= 3 &&
      bytes[0] === 255 &&
      bytes[1] === 216 &&
      bytes[2] === 255) {
    return 'image/jpeg';
  }

  if (bytes.length >= 4 &&
      bytes[0] === 71 &&
      bytes[1] === 73 &&
      bytes[2] === 70 &&
      bytes[3] === 56) {
    return 'image/gif';
  }

  if (bytes.length >= 4 &&
      bytes[0] === 82 &&
      bytes[1] === 73 &&
      bytes[2] === 70 &&
      bytes[3] === 70) {
    return 'image/webp';
  }

  if (bytes.length >= 2 &&
      bytes[0] === 66 &&
      bytes[1] === 77) {
    return 'image/bmp';
  }

  return 'image/jpeg';
}

function toBase64(input: string): string {
  if (typeof btoa === 'function') {
    return btoa(input);
  }

  const utf8Bytes: number[] = [];
  for (let i = 0; i < input.length; i += 1) {
    let char = input.charCodeAt(i);
    if (char < 0x80) {
      utf8Bytes.push(char);
      continue;
    }
    if (char < 0x800) {
      utf8Bytes.push(0xc0 | (char >> 6));
      utf8Bytes.push(0x80 | (char & 0x3f));
      continue;
    }
    if (char < 0xd800 || char >= 0xe000) {
      utf8Bytes.push(0xe0 | (char >> 12));
      utf8Bytes.push(0x80 | ((char >> 6) & 0x3f));
      utf8Bytes.push(0x80 | (char & 0x3f));
      continue;
    }
    i += 1;
    const highSurrogate = char;
    const lowSurrogate = input.charCodeAt(i);
    const codePoint = ((highSurrogate - 0xd800) << 10) + (lowSurrogate - 0xdc00) + 0x10000;
    utf8Bytes.push(0xf0 | (codePoint >> 18));
    utf8Bytes.push(0x80 | ((codePoint >> 12) & 0x3f));
    utf8Bytes.push(0x80 | ((codePoint >> 6) & 0x3f));
    utf8Bytes.push(0x80 | (codePoint & 0x3f));
  }

  const bytes = new Uint8Array(utf8Bytes);
  const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  let out = '';
  let i = 0;
  while (i < bytes.length) {
    const a = bytes[i++] || 0;
    const b = bytes[i++] || 0;
    const c = bytes[i++] || 0;
    const triplet = (a << 16) | (b << 8) | c;
    out +=
      CHARS[(triplet >> 18) & 0x3f] +
      CHARS[(triplet >> 12) & 0x3f] +
      CHARS[(triplet >> 6) & 0x3f] +
      CHARS[triplet & 0x3f];
  }

  const mod = bytes.length % 3;
  if (mod === 1) {
    return out.slice(0, -2) + '==';
  }
  if (mod === 2) {
    return out.slice(0, -1) + '=';
  }
  return out;
}

async function readJsonResponse(response: Response): Promise<{ payload: unknown; rawText: string }> {
  const text = await response.text();
  try {
    return {
      payload: text ? JSON.parse(text) : null,
      rawText: text
    };
  } catch {
    return {
      payload: text,
      rawText: text
    };
  }
}

async function safeJson(response: Response) {
  return (await readJsonResponse(response)).payload;
}

const extractApiErrorMessage = (payload: unknown, fallback: string): string => {
  if (typeof payload === 'string' && payload.trim().length > 0) {
    return payload.trim();
  }

  if (!payload || typeof payload !== 'object') {
    return fallback;
  }

  const value = payload as Record<string, unknown>;
  const candidates = [
    value.message,
    value.mensagem,
    value.error,
    value.erro,
    value.detail,
    value.detalhe,
    value.title
  ];

  const direct = candidates.find((item) => typeof item === 'string' && String(item).trim().length > 0);
  if (typeof direct === 'string') {
    return direct.trim();
  }

  if (Array.isArray(value.errors)) {
    const joined = value.errors
      .filter((item) => typeof item === 'string' && item.trim().length > 0)
      .join('\n');
    if (joined) {
      return joined;
    }
  }

  return fallback;
};

export class ApiClient {
  private readonly getCache: GetRequestCache = {};
  private readonly inFlightGet: Map<string, Promise<unknown>> = new Map();
  private cachedCatalogCategories: Category[] | null = null;
  private cachedCatalogProducts: MenuItem[] | null = null;
  private cachedCatalogProductSummaries: MenuItem[] | null = null;
  private cachedCatalogProductsFingerprint: string | null = null;
  private cachedCatalogSqliteKey: string | null = null;
  private cachedCatalogSqliteFingerprint: string | null = null;
  private cachedCatalogSqliteSummaryCount: number | null = null;
  private cachedUsers: UserProfile[] | null = null;
  private catalogSchemaReadyKey: string | null = null;
  private productCatalogLoadSeq = 0;
  private syncAllInFlight: Promise<SyncResult> | null = null;

  constructor(private baseUrl: string, private idEmpresa = 1) {}

  isSyncAllRunning(): boolean {
    return this.syncAllInFlight !== null;
  }

  setBaseUrl(value: string) {
    this.baseUrl = value;
    this.clearAllGetCache();
    this.inFlightGet.clear();
    this.clearCatalogMemoryCache();
  }

  setEmpresa(value: number) {
    this.idEmpresa = value;
    this.clearAllGetCache();
    this.inFlightGet.clear();
    this.clearCatalogMemoryCache();
  }

  private async resolveTerminalName(): Promise<string> {
    try {
      const settings = await loadMobileSettings();
      const terminal = sanitizeText(settings.terminalImpressao, '').toUpperCase();
      return terminal || 'mobile';
    } catch {
      return 'mobile';
    }
  }

  private async withTerminalImpressao(item: LaunchItemPayload): Promise<LaunchItemPayload> {
    const terminal = (
      sanitizeText(item.terminalImpressao, '') ||
      sanitizeText(item.TerminalImpressao, '') ||
      (await this.resolveTerminalName())
    ).toUpperCase();
    return {
      ...item,
      terminalImpressao: terminal,
      TerminalImpressao: terminal
    };
  }

  private async withTerminalImpressaoBatch(items: LaunchItemPayload[]): Promise<LaunchItemPayload[]> {
    const terminal = await this.resolveTerminalName();
    return items.map((item) => {
      const itemTerminal = (
        sanitizeText(item.terminalImpressao, '') ||
        sanitizeText(item.TerminalImpressao, '') ||
        terminal
      ).toUpperCase();

      return {
        ...item,
        terminalImpressao: itemTerminal,
        TerminalImpressao: itemTerminal
      };
    });
  }

  private buildUrl(path: string): string {
    return buildAbsoluteUrl(this.baseUrl, path);
  }

  private buildCacheKey(method: string, path: string, init: RequestInit = {}): string {
    const methodToken = method.toUpperCase();
    const body = init.body ? `:${typeof init.body === 'string' ? init.body : JSON.stringify(init.body)}` : '';
    return `${methodToken}:${path}${body ? `:${body}` : ''}`;
  }

  private getGetCacheTTL(path: string): number {
    if (path.includes(`/empresa/${this.idEmpresa}/mesa`)) {
      return GET_CACHE_TTL.tables;
    }

    if (path.includes(`/empresa/${this.idEmpresa}/comanda`)) {
      return GET_CACHE_TTL.comandas;
    }

    if (path.includes(`/empresa/${this.idEmpresa}/categoria`)) {
      return GET_CACHE_TTL.categories;
    }

    if (path.includes(`/empresa/${this.idEmpresa}/produto`)) {
      return GET_CACHE_TTL.products;
    }

    return GET_CACHE_TTL_DEFAULT_MS;
  }

  private readGetCache(key: string): unknown | null {
    const cached = this.getCache[key];
    if (!cached || Date.now() > cached.expiresAt) {
      delete this.getCache[key];
      return null;
    }

    return cached.payload;
  }

  private setGetCache(key: string, payload: unknown, path: string) {
    this.getCache[key] = {
      payload,
      expiresAt: Date.now() + this.getGetCacheTTL(path)
    };
  }

  private clearAllGetCache() {
    Object.keys(this.getCache).forEach((key) => delete this.getCache[key]);
  }

  private clearGetCacheByPrefix(prefix: string) {
    Object.keys(this.getCache).forEach((key) => {
      if (!key.includes(prefix)) {
        return;
      }
      delete this.getCache[key];
    });
    this.inFlightGet.forEach((_, key) => {
      if (key.includes(prefix)) {
        this.inFlightGet.delete(key);
      }
    });
  }

  private clearTablesGetCache() {
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/mesa`);
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/comanda`);
  }

  private clearMenuGetCache() {
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/categoria`);
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/produto`);
  }

  private clearProductGetCache() {
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/produto`);
  }

  private clearCategoryGetCache() {
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/categoria`);
  }

  private clearCatalogMemoryCache() {
    this.cachedCatalogCategories = null;
    this.cachedCatalogProducts = null;
    this.cachedCatalogProductSummaries = null;
    this.cachedCatalogProductsFingerprint = null;
    this.cachedCatalogSqliteKey = null;
    this.cachedCatalogSqliteFingerprint = null;
    this.cachedCatalogSqliteSummaryCount = null;
    this.cachedUsers = null;
    this.catalogSchemaReadyKey = null;
  }

  private rememberCatalogSqliteSummaryState(fingerprint: string | null, count: number) {
    if (Platform.OS === 'web' || !fingerprint || count <= 0) {
      return;
    }

    this.cachedCatalogSqliteKey = this.getCatalogStoragePrefix();
    this.cachedCatalogSqliteFingerprint = fingerprint;
    this.cachedCatalogSqliteSummaryCount = count;
  }

  private hasCatalogSqliteSummaryState(fingerprint: string, count: number) {
    if (Platform.OS === 'web') {
      return false;
    }

    return (
      this.cachedCatalogSqliteKey === this.getCatalogStoragePrefix() &&
      this.cachedCatalogSqliteFingerprint === fingerprint &&
      Number(this.cachedCatalogSqliteSummaryCount || 0) >= count
    );
  }

  private async materializeProductImages(
    products: MenuItem[],
    previousProducts: MenuItem[],
    options: { prefetchMissingRemote?: boolean } = {}
  ): Promise<MenuItem[]> {
    if (!products.length) {
      return products;
    }

    const imageDirectory = buildCatalogImageDirectory(this.baseUrl, this.idEmpresa);
    const canPersistFileImages = Platform.OS !== 'web' && Boolean(imageDirectory);
    if (Platform.OS !== 'web' && !canPersistFileImages) {
      return products.map((item) => stripInlineProductImage(item));
    }

    const previousProductsById = new Map<number, MenuItem>();
    previousProducts.forEach((item) => {
      const id = Number(item.idProduto || item.id || 0);
      if (id > 0) {
        previousProductsById.set(id, item);
      }
    });

    const hasAnyImagePayload = products.some((item) => Boolean(extractStoredImagePayload(item.imagem_db || item.imagem)));
    if (hasAnyImagePayload && canPersistFileImages) {
      try {
        await FileSystem.makeDirectoryAsync(imageDirectory as string, { intermediates: true });
      } catch {
        return products.map((item) => stripInlineProductImage(item));
      }
    }

    const resolvedProducts: MenuItem[] = [];
    for (const product of products) {
      const productId = Number(product.idProduto || product.id || 0);
      const previousProduct = previousProductsById.get(productId);
      const imagePayload = extractStoredImagePayload(product.imagem_db || product.imagem);
      const knownLocalPath =
        extractStoredImageLocalPath(product.imagemLocalPath || product.imagem) ||
        extractStoredImageLocalPath(previousProduct?.imagemLocalPath || previousProduct?.imagem);

      if (!imagePayload) {
        if (knownLocalPath) {
          resolvedProducts.push({
            ...product,
            imagem: knownLocalPath,
            imagem_db: undefined,
            imagemLocalPath: knownLocalPath,
            possuiImagem: product.possuiImagem !== false
          });
          continue;
        }

        if (options.prefetchMissingRemote && product.possuiImagem !== false && productId > 0) {
          const remoteImagePath = await cacheProductImageOnDemand(this.baseUrl, this.idEmpresa, productId).catch(() => undefined);
          if (remoteImagePath) {
            resolvedProducts.push({
              ...product,
              imagem: remoteImagePath,
              imagem_db: undefined,
              imagemLocalPath: remoteImagePath,
              possuiImagem: true
            });
            continue;
          }
        }

        resolvedProducts.push({
          ...product,
          imagem_db: undefined,
          imagemLocalPath: undefined
        });
        continue;
      }

      if (knownLocalPath && previousProduct?.imagem_db === imagePayload) {
        resolvedProducts.push({
          ...product,
          imagem: knownLocalPath,
          imagem_db: undefined,
          imagemLocalPath: knownLocalPath,
          possuiImagem: true
        });
        continue;
      }

      if (Platform.OS === 'web') {
        const inlineImageUri = buildDataUri(imagePayload, detectImageMimeTypeFromBase64(imagePayload));
        resolvedProducts.push({
          ...product,
          imagem: inlineImageUri,
          imagem_db: undefined,
          imagemLocalPath: inlineImageUri,
          possuiImagem: true
        });
        continue;
      }

      const imageExtension = getImageFileExtensionFromPayload(imagePayload);
      const imagePath = `${imageDirectory as string}${productId || resolvedProducts.length + 1}.${imageExtension}`;

      try {
        await FileSystem.writeAsStringAsync(imagePath, imagePayload, {
          encoding: FileSystem.EncodingType.Base64
        });
        resolvedProducts.push({
          ...product,
          imagem: imagePath,
          imagem_db: undefined,
          imagemLocalPath: imagePath,
          possuiImagem: true
        });
      } catch {
        resolvedProducts.push(stripInlineProductImage(product, true));
      }
    }

    return resolvedProducts;
  }

  private getCatalogStoragePrefix() {
    return buildCatalogStoragePrefix(this.baseUrl, this.idEmpresa);
  }

  private getCatalogStorageSuffix() {
    const currentPrefix = this.getCatalogStoragePrefix();
    const marker = `@rpcheff:catalog:v${CATALOG_STORAGE_VERSION}:`;
    return currentPrefix.startsWith(marker) ? currentPrefix.slice(marker.length) : '';
  }

  private async pruneLegacyCatalogStorage() {
    try {
      const suffix = this.getCatalogStorageSuffix();
      if (!suffix) {
        return;
      }

      const currentPrefix = this.getCatalogStoragePrefix();
      const keys = await AsyncStorage.getAllKeys();
      const staleKeys = keys.filter(
        (key) =>
          key.startsWith('@rpcheff:catalog:v') &&
          key.includes(`:${suffix}`) &&
          !key.startsWith(currentPrefix)
      );

      if (staleKeys.length > 0) {
        await AsyncStorage.multiRemove(staleKeys);
      }
    } catch {
      // Cache antigo nao pode bloquear sincronizacao.
    }
  }

  private getCatalogSchemaKey() {
    return `${this.getCatalogStoragePrefix()}:schema`;
  }

  private getCatalogCategoriesKey() {
    return `${this.getCatalogStoragePrefix()}:categories`;
  }

  private getCatalogProductIdsKey() {
    return `${this.getCatalogStoragePrefix()}:product_ids`;
  }

  private getCatalogProductFingerprintKey() {
    return `${this.getCatalogStoragePrefix()}:product_fingerprint`;
  }

  private getCatalogProductKey(idProduto: number) {
    return `${this.getCatalogStoragePrefix()}:product:${Math.trunc(idProduto)}`;
  }

  private async readCachedProductIds() {
    try {
      const raw = await AsyncStorage.getItem(this.getCatalogProductIdsKey());
      if (!raw) {
        return [] as number[];
      }

      const parsed = JSON.parse(raw);
      if (!Array.isArray(parsed)) {
        return [] as number[];
      }

      return parsed
        .map((item) => Number(item || 0))
        .filter((item, index, list) => Number.isFinite(item) && item > 0 && list.indexOf(item) === index);
    } catch {
      return [] as number[];
    }
  }

  private async ensureCatalogStorageSchema() {
    const schemaKey = this.getCatalogSchemaKey();
    if (this.catalogSchemaReadyKey === schemaKey) {
      return;
    }

    try {
      const storedVersion = Number((await AsyncStorage.getItem(schemaKey)) || 0);
      if (storedVersion !== CATALOG_STORAGE_VERSION) {
        await this.pruneLegacyCatalogStorage();
        const existingIds = await this.readCachedProductIds();
        const keysToRemove = [
          this.getCatalogCategoriesKey(),
          this.getCatalogProductIdsKey(),
          this.getCatalogProductFingerprintKey(),
          ...existingIds.map((id) => this.getCatalogProductKey(id))
        ];
        if (keysToRemove.length > 0) {
          await AsyncStorage.multiRemove(keysToRemove);
        }
        await AsyncStorage.setItem(schemaKey, String(CATALOG_STORAGE_VERSION));
      }
    } catch {
      // Falha de storage nao pode invalidar dados carregados da API.
    }

    this.catalogSchemaReadyKey = schemaKey;
  }

  private async loadCachedCategories(): Promise<Category[]> {
    if (this.cachedCatalogCategories) {
      return this.cachedCatalogCategories;
    }

    await this.ensureCatalogStorageSchema();

    try {
      const raw = await AsyncStorage.getItem(this.getCatalogCategoriesKey());
      if (!raw) {
        this.cachedCatalogCategories = [];
        return this.cachedCatalogCategories;
      }

      const parsed = JSON.parse(raw);
      if (!Array.isArray(parsed)) {
        this.cachedCatalogCategories = [];
        return this.cachedCatalogCategories;
      }

      this.cachedCatalogCategories = parsed
        .map((item) => ({
          id: parseNumber(resolveField(item, ['idCategoria', 'id']), 0),
          descricao: sanitizeText(resolveField(item, ['descricao']), '')
        }))
        .filter((item) => item.id > 0 && item.descricao);
      return this.cachedCatalogCategories;
    } catch {
      this.cachedCatalogCategories = [];
      return this.cachedCatalogCategories;
    }
  }

  private async saveCachedCategories(categories: Category[]) {
    await this.ensureCatalogStorageSchema();

    const normalized = [...categories]
      .filter((item) => Number(item.id || 0) > 0)
      .sort((a, b) => a.id - b.id)
      .map((item) => ({
        id: Number(item.id || 0),
        descricao: String(item.descricao || '').trim()
      }));

    this.cachedCatalogCategories = normalized;
    try {
      await AsyncStorage.setItem(this.getCatalogCategoriesKey(), JSON.stringify(normalized));
    } catch {
      await this.pruneLegacyCatalogStorage();
      try {
        await AsyncStorage.setItem(this.getCatalogCategoriesKey(), JSON.stringify(normalized));
      } catch {
        // Mantem cache em memoria quando o storage local esta indisponivel.
      }
    }
  }

  private async loadCachedProducts(options: { compact?: boolean } = {}): Promise<MenuItem[]> {
    if (options.compact && this.cachedCatalogProductSummaries) {
      return this.cachedCatalogProductSummaries;
    }
    if (!options.compact && this.cachedCatalogProducts) {
      return this.cachedCatalogProducts;
    }

    await this.ensureCatalogStorageSchema();

    const parseRows = (rows: string[]) =>
      rows
        .map((raw) => {
          if (!raw) {
            return null;
          }

          try {
            return parseMenuItem(JSON.parse(raw));
          } catch {
            return null;
          }
        })
        .filter((item): item is MenuItem => Boolean(item));

    try {
      if (options.compact) {
        const summaryStartedAt = Date.now();
        const summaryRows = await loadStoredCatalogProductSummaries(this.getCatalogStoragePrefix());
        if (summaryRows.length > 0) {
          this.cachedCatalogProductSummaries = summaryRows.map(parseCatalogSummaryItem);
          logSyncDiagnostic(
            `cache produtos sqlite compacto count=${this.cachedCatalogProductSummaries.length} em ${Date.now() - summaryStartedAt}ms`
          );
          return this.cachedCatalogProductSummaries;
        }
      }

      const sqliteRows = await loadStoredCatalogProducts(this.getCatalogStoragePrefix(), {
        compact: options.compact
      });
      if (sqliteRows.length > 0) {
        const products = parseRows(sqliteRows);
        if (options.compact) {
          this.cachedCatalogProductSummaries = products;
          return this.cachedCatalogProductSummaries;
        }

        this.cachedCatalogProducts = products;
        this.cachedCatalogProductSummaries = products.map(toCatalogListMenuItem);
        this.cachedCatalogProductsFingerprint = await loadStoredCatalogFingerprint(this.getCatalogStoragePrefix());
        this.rememberCatalogSqliteSummaryState(this.cachedCatalogProductsFingerprint, products.length);
        return this.cachedCatalogProducts;
      }
    } catch {
      // AsyncStorage antigo segue como fallback.
    }

    try {
      const ids = await this.readCachedProductIds();
      if (!ids.length) {
        this.cachedCatalogProducts = [];
        this.cachedCatalogProductSummaries = [];
        return options.compact ? this.cachedCatalogProductSummaries : this.cachedCatalogProducts;
      }

      const entries = await AsyncStorage.multiGet(ids.map((id) => this.getCatalogProductKey(id)));
      const products = parseRows(entries.map(([, raw]) => raw || ''));
      const fingerprint = await AsyncStorage.getItem(this.getCatalogProductFingerprintKey()).catch(() => null);
      this.cachedCatalogProducts = products;
      this.cachedCatalogProductSummaries = products.map(toCatalogListMenuItem);
      this.cachedCatalogProductsFingerprint = fingerprint;

      if (products.length > 0 && fingerprint) {
        await saveStoredCatalogProducts(
          this.getCatalogStoragePrefix(),
          buildCatalogPersistItems(products),
          fingerprint
        );
        this.rememberCatalogSqliteSummaryState(fingerprint, products.length);
      }

      return options.compact ? this.cachedCatalogProductSummaries : this.cachedCatalogProducts;
    } catch {
      this.cachedCatalogProducts = [];
      this.cachedCatalogProductSummaries = [];
      return options.compact ? this.cachedCatalogProductSummaries : this.cachedCatalogProducts;
    }
  }

  private async loadCachedProduct(idProduto: number): Promise<MenuItem | null> {
    const targetId = Math.trunc(Number(idProduto || 0));
    if (targetId <= 0) {
      return null;
    }

    const findInMemory = () =>
      this.cachedCatalogProducts?.find((item) => Number(item.idProduto || item.id || 0) === targetId) || null;

    const memoryProduct = findInMemory();
    if (memoryProduct) {
      return memoryProduct;
    }

    try {
      const raw = await loadStoredCatalogProduct(this.getCatalogStoragePrefix(), targetId);
      if (raw) {
        return parseMenuItem(JSON.parse(raw));
      }
    } catch {
      // AsyncStorage antigo segue como fallback.
    }

    try {
      const raw = await AsyncStorage.getItem(this.getCatalogProductKey(targetId));
      if (raw) {
        return parseMenuItem(JSON.parse(raw));
      }
    } catch {
      // Quando o item individual falhar, tentamos a carga completa abaixo.
    }

    const products = await this.loadCachedProducts();
    return products.find((item) => Number(item.idProduto || item.id || 0) === targetId) || null;
  }

  private async syncCatalogProductCount(): Promise<number> {
    const startedAt = Date.now();
    const productPath = `rpCheff/v1/empresa/${this.idEmpresa}/produto?exibirImagem=false`;
    const cachedProducts = await this.loadCachedProducts();
    const { response, payload, rawText } = await this.request(productPath, {
      preferNativeHttp: Platform.OS === 'android',
      timeoutMs: SYNC_PRODUCT_CATALOG_TIMEOUT_MS
    });
    if (!response.ok) {
      throw new Error(`Falha ao consultar ${productPath}: ${response.status}`);
    }
    if (!Array.isArray(payload)) {
      throw new Error('Erro na API');
    }

    logSyncDiagnostic(
      `produtos remoto count=${payload.length} exibirImagem=false preserveCachedImages=false em ${Date.now() - startedAt}ms`
    );

    const remoteFingerprint = buildCatalogRawPayloadFingerprint(rawText);
    let knownFingerprint = this.cachedCatalogProductsFingerprint;
    if (!knownFingerprint || knownFingerprint !== remoteFingerprint) {
      knownFingerprint = await loadStoredCatalogFingerprint(this.getCatalogStoragePrefix()).catch(() => null);
    }

    if (remoteFingerprint && knownFingerprint === remoteFingerprint && !hasMissingCatalogImageCache(cachedProducts)) {
      this.cachedCatalogProductsFingerprint = remoteFingerprint;
      logSyncDiagnostic(`produtos prontos inalterado count=${payload.length} em ${Date.now() - startedAt}ms`);
      return payload.length;
    }

    const remoteProducts = payload.map(parseMenuItem);
    const mergedProducts = mergeProductsWithCachedImages(remoteProducts, cachedProducts);
    const products = await this.materializeProductImages(mergedProducts, cachedProducts, {
      prefetchMissingRemote: true
    });
    await this.saveCachedProducts(products, {
      fingerprint: remoteFingerprint
    });
    logSyncDiagnostic(`produtos prontos count=${products.length} compact=false em ${Date.now() - startedAt}ms`);
    return products.length;
  }

  private async persistCachedProducts(
    pairs: [string, string][],
    nextIds: number[],
    staleKeys: string[],
    fingerprint: string
  ) {
    for (let index = 0; index < pairs.length; index += CATALOG_PRODUCT_WRITE_BATCH_SIZE) {
      const batch = pairs.slice(index, index + CATALOG_PRODUCT_WRITE_BATCH_SIZE);
      if (batch.length > 0) {
        await AsyncStorage.multiSet(batch);
      }
    }

    for (let index = 0; index < staleKeys.length; index += CATALOG_PRODUCT_WRITE_BATCH_SIZE) {
      await AsyncStorage.multiRemove(staleKeys.slice(index, index + CATALOG_PRODUCT_WRITE_BATCH_SIZE));
    }

    await AsyncStorage.multiSet([
      [this.getCatalogProductIdsKey(), JSON.stringify(nextIds)],
      [this.getCatalogProductFingerprintKey(), fingerprint]
    ]);
  }

  private async readCachedProductStorageFingerprint(previousIds: number[]) {
    if (!previousIds.length) {
      return null;
    }

    try {
      const entries = await AsyncStorage.multiGet(previousIds.map((id) => this.getCatalogProductKey(id)));
      if (entries.some(([, value]) => !value)) {
        return null;
      }

      return buildCatalogProductsFingerprint(
        previousIds,
        entries.map(([, value]) => value || '')
      );
    } catch {
      return null;
    }
  }

  private async saveCachedProducts(products: MenuItem[], options: { fingerprint?: string | null } = {}) {
    const startedAt = Date.now();
    await this.ensureCatalogStorageSchema();

    const uniqueById = new Map<number, MenuItem>();
    products.forEach((item) => {
      const id = Number(item.idProduto || item.id || 0);
      if (id > 0) {
        const storedLocalPath = extractStoredImageLocalPath(item.imagemLocalPath || item.imagem);
        uniqueById.set(id, {
          ...item,
          imagem: storedLocalPath,
          imagemLocalPath: storedLocalPath,
          imagem_db: undefined,
          possuiImagem: Boolean(storedLocalPath || item.possuiImagem)
        });
      }
    });

    const normalized = [...uniqueById.values()].sort((a, b) => (a.idProduto || a.id) - (b.idProduto || b.id));
    const nextIds = normalized.map((item) => Number(item.idProduto || item.id || 0)).filter((item) => item > 0);
    const hasResolvedLocalImages = normalized.some((item) => Boolean(extractStoredImageLocalPath(item.imagemLocalPath || item.imagem)));
    const fingerprint = options.fingerprint || buildCatalogProductsSemanticFingerprint(normalized);
    const verifiedSqliteSummary = this.hasCatalogSqliteSummaryState(fingerprint, normalized.length);
    const sqliteFingerprint = verifiedSqliteSummary
      ? fingerprint
      : await loadStoredCatalogFingerprint(this.getCatalogStoragePrefix()).catch(() => null);
    let previousFingerprint =
      this.cachedCatalogProductsFingerprint ||
      sqliteFingerprint ||
      (await AsyncStorage.getItem(this.getCatalogProductFingerprintKey()).catch(() => null));
    if (!previousFingerprint) {
      const previousIds = await this.readCachedProductIds();
      previousFingerprint = await this.readCachedProductStorageFingerprint(previousIds);
    }

    this.cachedCatalogProducts = normalized;
    this.cachedCatalogProductSummaries = normalized.map(toCatalogListMenuItem);
    if (previousFingerprint === fingerprint) {
      const shouldRefreshAsyncStorage = Platform.OS === 'web' && hasResolvedLocalImages;
      const sqliteSummaryCount = verifiedSqliteSummary
        ? normalized.length
        : sqliteFingerprint
          ? await countStoredCatalogProductSummaries(this.getCatalogStoragePrefix()).catch(() => 0)
          : 0;
      if (!shouldRefreshAsyncStorage && sqliteFingerprint && sqliteSummaryCount >= normalized.length) {
        this.cachedCatalogProductsFingerprint = fingerprint;
        this.rememberCatalogSqliteSummaryState(fingerprint, sqliteSummaryCount);
        logSyncDiagnostic(`cache produtos sem alteracao count=${normalized.length} em ${Date.now() - startedAt}ms`);
        return;
      }

      const previousIds = shouldRefreshAsyncStorage ? await this.readCachedProductIds() : [];
      const nextIdSet = shouldRefreshAsyncStorage ? new Set(nextIds) : null;
      const staleKeys =
        shouldRefreshAsyncStorage && nextIdSet
          ? previousIds.filter((id) => !nextIdSet.has(id)).map((id) => this.getCatalogProductKey(id))
          : [];
      const productJsonList = shouldRefreshAsyncStorage ? normalized.map((item) => JSON.stringify(toStoredMenuItem(item))) : [];
      const pairs = shouldRefreshAsyncStorage
        ? normalized.map(
            (item, index): [string, string] => [
              this.getCatalogProductKey(Number(item.idProduto || item.id || 0)),
              productJsonList[index]
            ]
          )
        : [];
      const persistItems = buildCatalogPersistItems(normalized);
      if (persistItems.length > 0 || pairs.length > 0) {
        await Promise.all([
          pairs.length > 0
            ? this.persistCachedProducts(pairs, nextIds, staleKeys, fingerprint)
            : Promise.resolve(),
          persistItems.length > 0
            ? saveStoredCatalogProducts(this.getCatalogStoragePrefix(), persistItems, fingerprint)
            : Promise.resolve()
        ]);
        this.rememberCatalogSqliteSummaryState(fingerprint, persistItems.length);
      }
      this.cachedCatalogProductsFingerprint = fingerprint;
      logSyncDiagnostic(`cache produtos sem alteracao count=${normalized.length} em ${Date.now() - startedAt}ms`);
      return;
    }

    const previousIds = await this.readCachedProductIds();
    const nextIdSet = new Set(nextIds);
    const staleKeys = previousIds.filter((id) => !nextIdSet.has(id)).map((id) => this.getCatalogProductKey(id));
    const productJsonList = normalized.map((item) => JSON.stringify(toStoredMenuItem(item)));
    const pairs = normalized.map(
      (item, index): [string, string] => [
        this.getCatalogProductKey(Number(item.idProduto || item.id || 0)),
        productJsonList[index]
      ]
    );
    const persistItems = buildCatalogPersistItems(normalized);

    try {
      await Promise.all([
        this.persistCachedProducts(pairs, nextIds, staleKeys, fingerprint),
        saveStoredCatalogProducts(this.getCatalogStoragePrefix(), persistItems, fingerprint)
      ]);
      this.cachedCatalogProductsFingerprint = fingerprint;
      this.rememberCatalogSqliteSummaryState(fingerprint, persistItems.length);
      logSyncDiagnostic(
        `cache produtos salvo count=${normalized.length} stale=${staleKeys.length} em ${Date.now() - startedAt}ms`
      );
    } catch {
      await this.pruneLegacyCatalogStorage();
      try {
        await Promise.all([
          this.persistCachedProducts(pairs, nextIds, staleKeys, fingerprint),
          saveStoredCatalogProducts(this.getCatalogStoragePrefix(), persistItems, fingerprint)
        ]);
        this.cachedCatalogProductsFingerprint = fingerprint;
        this.rememberCatalogSqliteSummaryState(fingerprint, persistItems.length);
        logSyncDiagnostic(
          `cache produtos salvo apos limpeza count=${normalized.length} stale=${staleKeys.length} em ${Date.now() - startedAt}ms`
        );
      } catch {
        // A sincronizacao deve continuar usando dados em memoria mesmo sem cache em disco.
        logSyncDiagnostic(`cache produtos indisponivel count=${normalized.length}`, 2);
      }
    }
  }

  private shouldCacheGet(path: string, init: RequestInit = {}): boolean {
    const method = (init.method || 'GET').toUpperCase();
    if (method !== 'GET') return false;

    // Mesa/comanda seguem o legado UseTag(False): sempre buscar mapa atualizado.
    return (
      path.includes(`/empresa/${this.idEmpresa}/categoria`) ||
      path.includes(`/empresa/${this.idEmpresa}/produto`)
    );
  }

  private async requestWithNativeHttp(
    url: string,
    fetchInit: RequestInit,
    headers: Record<string, string>,
    timeoutMs: number
  ) {
    if (!nativeHttpModule?.request) {
      throw new Error('Módulo HTTP nativo indisponível');
    }

    const executeNativeRequest = () =>
      nativeHttpModule.request(
        url,
        String(fetchInit.method || 'GET').toUpperCase(),
        headers,
        typeof fetchInit.body === 'string' ? fetchInit.body : null,
        timeoutMs
      );

    let nativeResponse: NativeHttpResponse;
    try {
      nativeResponse = await executeNativeRequest();
    } catch (error) {
      if (!isTransientAndroidNetworkError(error)) {
        throw error;
      }

      nativeResponse = await executeNativeRequest();
    }

    const response = {
      ok: nativeResponse.status >= 200 && nativeResponse.status < 300,
      status: nativeResponse.status,
      statusText: nativeResponse.statusText || '',
      text: async () => nativeResponse.body || ''
    } as Response;
    const { payload, rawText } = await readJsonResponse(response);
    return { response, payload, rawText };
  }

  private async requestWithFetch(
    path: string,
    url: string,
    fetchInit: RequestInit,
    headers: Record<string, string>,
    timeoutMs: number
  ) {
    const controller = typeof AbortController !== 'undefined' ? new AbortController() : null;
    const timeout = controller ? setTimeout(() => controller.abort(), timeoutMs) : null;

    const executeFetch = (signal?: AbortSignal) =>
      fetch(url, {
        ...fetchInit,
        headers,
        ...(signal ? { signal } : {})
      });

    const executeWithoutAbortSignal = async () => {
      let manualTimeout: ReturnType<typeof setTimeout> | null = null;

      try {
        return await Promise.race<Response>([
          executeFetch(),
          new Promise<Response>((_, reject) => {
            manualTimeout = setTimeout(() => reject(new Error(`Tempo limite excedido ao consultar ${path}`)), timeoutMs);
          })
        ]);
      } finally {
        if (manualTimeout) {
          clearTimeout(manualTimeout);
        }
      }
    };

    try {
      let response: Response;
      try {
        response = controller ? await executeFetch(controller.signal) : await executeWithoutAbortSignal();
      } catch (error: unknown) {
        const message = error instanceof Error ? error.message.toLowerCase() : '';
        const shouldRetryWithoutAbortSignal =
          Platform.OS === 'android' &&
          controller !== null &&
          !controller.signal.aborted &&
          (message.includes('network request failed') || message.includes('failed to fetch'));

        if (!shouldRetryWithoutAbortSignal) {
          throw error;
        }

        response = await executeWithoutAbortSignal();
      }

      const { payload, rawText } = await readJsonResponse(response);
      return { response, payload, rawText };
    } finally {
      if (timeout) {
        clearTimeout(timeout);
      }
    }
  }

  private async request(path: string, init: ApiRequestInit = {}) {
    const { timeoutMs: customTimeoutMs, preferNativeHttp = false, ...fetchInit } = init;
    const timeoutMs =
      typeof customTimeoutMs === 'number' && Number.isFinite(customTimeoutMs) && customTimeoutMs > 0
        ? customTimeoutMs
        : requestDefaults.timeoutMs;
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...normalizeRequestHeaders(authHeader()),
      ...normalizeRequestHeaders(fetchInit.headers)
    };
    const url = this.buildUrl(path);
    const fallbackTimeoutMs = Math.max(timeoutMs, Platform.OS === 'android' ? quickConnectionCheckTimeoutMs : 1500);

    if (Platform.OS === 'android' && nativeHttpModule?.request) {
      if (preferNativeHttp) {
        try {
          return await this.requestWithNativeHttp(url, fetchInit, headers, fallbackTimeoutMs);
        } catch (nativeError) {
          if (!isTransientAndroidNetworkError(nativeError)) {
            throw nativeError;
          }

          return this.requestWithFetch(path, url, fetchInit, headers, timeoutMs);
        }
      }

      try {
        return await this.requestWithFetch(path, url, fetchInit, headers, timeoutMs);
      } catch (fetchError) {
        if (!isTransientFetchNetworkError(fetchError)) {
          throw fetchError;
        }

        try {
          return await this.requestWithNativeHttp(url, fetchInit, headers, fallbackTimeoutMs);
        } catch (nativeError) {
          if (!isTransientAndroidNetworkError(nativeError)) {
            throw nativeError;
          }

          return this.requestWithFetch(path, url, fetchInit, headers, fallbackTimeoutMs);
        }
      }
    }

    return this.requestWithFetch(path, url, fetchInit, headers, timeoutMs);
  }

  private async requestJson(path: string, init: ApiRequestInit = {}): Promise<unknown> {
    if (!this.shouldCacheGet(path, init)) {
      const { response, payload } = await this.request(path, init);
      if (!response.ok) {
        throw new Error(`Falha ao consultar ${path}: ${response.status}`);
      }
      if (payload === null || payload === undefined) {
        throw new Error(`Resposta inválida em ${path}`);
      }
      return payload;
    }

    const method = (init.method || 'GET').toUpperCase();
    const cacheKey = this.buildCacheKey(method, path, init);
    const cached = this.readGetCache(cacheKey);

    if (cached !== null) {
      return cached;
    }

    const inFlight = this.inFlightGet.get(cacheKey);
    if (inFlight) {
      return inFlight;
    }

    const request = (async () => {
      const { response, payload } = await this.request(path, init);
      if (!response.ok) {
        throw new Error(`Falha ao consultar ${path}: ${response.status}`);
      }
      if (payload === null || payload === undefined) {
        throw new Error(`Resposta inválida em ${path}`);
      }
      this.setGetCache(cacheKey, payload, path);
      return payload;
    })();

    this.inFlightGet.set(cacheKey, request);

    try {
      return await request;
    } finally {
      const current = this.inFlightGet.get(cacheKey);
      if (current === request) {
        this.inFlightGet.delete(cacheKey);
      }
    }
  }

  async ping(): Promise<boolean> {
    const { response } = await this.request(`rpCheff/v1/ping`);
    return response.ok;
  }

  async testApiConnection(
    options: { timeoutMs?: number } = {}
  ): Promise<{ ok: boolean; status: number; message: string; payloadType: 'json' | 'text' | 'empty' }> {
    try {
      const { response, payload } = await this.request(`rpCheff/v1/ping`, {
        timeoutMs: options.timeoutMs,
        preferNativeHttp: Platform.OS === 'android'
      });

      if (response.ok || response.status !== 404) {
        return {
          ok: response.ok,
          status: response.status,
          message: response.statusText || 'Sem status',
          payloadType: payload === null ? 'empty' : typeof payload === 'string' ? 'text' : 'json'
        };
      }
    } catch {
      // Fallback para servidores legados sem /ping estável.
    }

    return this.testCompanyEndpoint(options);
  }

  async testCompanyEndpoint(
    options: { timeoutMs?: number } = {}
  ): Promise<{ ok: boolean; status: number; message: string; payloadType: 'json' | 'text' | 'empty' }> {
    const { response, payload } = await this.request(`rpCheff/v1/empresa/${this.idEmpresa}`, {
      timeoutMs: options.timeoutMs,
      preferNativeHttp: Platform.OS === 'android'
    });
    return {
      ok: response.ok,
      status: response.status,
      message: response.statusText || 'Sem status',
      payloadType: payload === null ? 'empty' : typeof payload === 'string' ? 'text' : 'json'
    };
  }

  private async resolveUserProfileByLogin(login: string): Promise<UserProfile | null> {
    const normalizedLogin = String(login || '').trim();
    if (!normalizedLogin) {
      return null;
    }

    try {
      const payload = await this.requestJson(
        `rpCheff/v1/empresa/${this.idEmpresa}/usuario/${encodeURIComponent(normalizedLogin)}`
      );
      if (payload && typeof payload === 'object') {
        const resolved = parseUserProfile(payload as Record<string, any>);
        if (Number(resolved.idUsuario || 0) > 0) {
          return resolved;
        }
      }
    } catch {
      // Continua para a busca em lote.
    }

    try {
      const normalizedLoginKey = normalizedLogin.toLowerCase();
      const users = await this.listUsers();
      return (
        users.find((item) => String(item.login || '').trim().toLowerCase() === normalizedLoginKey) ||
        users.find((item) => String(item.nome || '').trim().toLowerCase() === normalizedLoginKey) ||
        null
      );
    } catch {
      return null;
    }
  }

  async login(login: string, senha: string): Promise<UserProfile> {
    const normalizedLogin = String(login || '').trim();
    const normalizedPassword = String(senha || '').trim();
    if (!normalizedLogin || !normalizedPassword) {
      throw new Error('Informe usuário e senha.');
    }

    const { response, payload } = await this.request(`rpCheff/v1/empresa/${this.idEmpresa}/usuario/login`, {
      method: 'POST',
      body: JSON.stringify({ login: normalizedLogin, senha: normalizedPassword })
    });

    if (!response.ok) {
      throw new Error(extractApiErrorMessage(payload, 'Usuário ou senha inválidos.'));
    }

    if (!payload || typeof payload !== 'object') {
      throw new Error('Resposta inválida ao autenticar usuário.');
    }

    const resolvedUser = parseUserProfile(payload as Record<string, unknown>);
    if (Number(resolvedUser.idUsuario || 0) <= 0) {
      throw new Error('Usuário ou senha inválidos.');
    }

    return resolvedUser;
  }

  async listUsers(options: UserListOptions = {}): Promise<UserProfile[]> {
    if (options.preferCache && this.cachedUsers) {
      return this.cachedUsers;
    }

    try {
      const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/usuario`);
      if (!Array.isArray(payload)) throw new Error('Resposta inválida da API');
      const users = payload.map(parseUserProfile);
      this.cachedUsers = users;
      return users;
    } catch (error) {
      if (options.requireRemote) {
        throw error;
      }

      return this.cachedUsers || [];
    }
  }

  async getCompanyConfig(): Promise<{ mesa: CompanyConfig | null; comanda: CompanyConfig | null }> {
    const [mesa, comanda] = await Promise.allSettled([
      this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/configuracaoMesa`),
      this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/configuracaoComanda`)
    ]);

    return {
      mesa: mesa.status === 'fulfilled' ? parseCompanyConfig(mesa.value) : null,
      comanda: comanda.status === 'fulfilled' ? parseCompanyConfig(comanda.value) : null
    };
  }

  async getCompanyInfo(): Promise<CompanyInfo | null> {
    const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}`);
    if (!payload || typeof payload !== 'object') {
      return null;
    }
    return parseCompanyInfo(payload);
  }

  async saveSettings(payload: Record<string, unknown>): Promise<void> {
    const normalized = normalizeMobileSettings(payload);
    await saveMobileSettings(normalized);
  }

  private async resolveCatalogImagePreference(): Promise<boolean> {
    try {
      const settings = await loadMobileSettings();
      return settings.exibirImagem !== false;
    } catch {
      return defaultMobileSettings.exibirImagem;
    }
  }

  async syncPartial(task: string): Promise<SyncTaskResult> {
    const taskCode = String(task || '').toLowerCase();

    try {
      if (taskCode === 'catalogo') {
        const shouldShowImages = await this.resolveCatalogImagePreference();
        this.clearMenuGetCache();
        const [categories, productCount] = await Promise.all([
          this.listCategories({
            requireRemote: true,
            preferNativeHttp: Platform.OS === 'android',
            timeoutMs: SYNC_PRODUCT_CATALOG_TIMEOUT_MS
          }),
          this.syncCatalogProductCount()
        ]);
        return {
          key: task,
          status: categories.length > 0 || productCount > 0 ? 'ok' : 'skip',
          message: `Catálogo: ${categories.length} categorias | ${productCount} produtos${shouldShowImages ? ' | imagens por demanda' : ' | imagens desativadas'}`
        };
      }

      if (taskCode === 'produtos' || taskCode === 'produto') {
        const shouldShowImages = await this.resolveCatalogImagePreference();
        this.clearProductGetCache();
        const productCount = await this.syncCatalogProductCount();
        return {
          key: task,
          status: productCount > 0 ? 'ok' : 'skip',
          message: `${productCount} produtos atualizados com opcionais${shouldShowImages ? ' | imagens por demanda' : ' | imagens desativadas'}`
        };
      }

      if (taskCode === 'categorias' || taskCode === 'categoria') {
        this.clearCategoryGetCache();
        const categories = await this.listCategories({
          requireRemote: true,
          preferNativeHttp: Platform.OS === 'android',
          timeoutMs: SYNC_PRODUCT_CATALOG_TIMEOUT_MS
        });
        return {
          key: task,
          status: categories.length > 0 ? 'ok' : 'skip',
          message: `${categories.length} categorias atualizadas`
        };
      }

      if (taskCode === 'mesas' || taskCode === 'mesa' || taskCode === 'tabelas') {
        this.clearTablesGetCache();
        const responsePayload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/mesa`);
        if (!Array.isArray(responsePayload)) {
          throw new Error('Resposta inválida');
        }
        return {
          key: task,
          status: 'ok',
          message: `${responsePayload.length} mesas atualizadas`
        };
      }

      if (taskCode === 'formas' || taskCode === 'formasdepagamento' || taskCode === 'formaspagamento') {
        const responsePayload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/formaPagamento`);
        if (!Array.isArray(responsePayload)) {
          throw new Error('Resposta inválida');
        }
        return {
          key: task,
          status: 'ok',
          message: `${responsePayload.length} formas de pagamento atualizadas`
        };
      }

      if (taskCode === 'usuarios') {
        const users = await this.listUsers({ requireRemote: true });
        return {
          key: task,
          status: 'ok',
          message: `${users.length} usuários carregados`
        };
      }

      if (taskCode === 'configuracoes' || taskCode === 'configuracao') {
        const config = await this.getCompanyConfig();
        const total = Number(config.mesa !== null) + Number(config.comanda !== null);
        return {
          key: task,
          status: total > 0 ? 'ok' : 'skip',
          message: total > 0 ? 'Configurações de mesa/comanda carregadas' : 'Sem configuração disponível'
        };
      }

      return {
        key: task,
        status: 'error',
        message: 'Tarefa de sincronização desconhecida'
      };
    } catch (error: unknown) {
      return {
        key: task,
        status: 'error',
        message: error instanceof Error ? error.message : 'Falha na sincronização'
      };
    }
  }

  async syncAll(options: SyncAllOptions = {}): Promise<SyncResult> {
    if (this.syncAllInFlight) {
      logSyncDiagnostic('syncAll reutilizando execucao em andamento');
      return this.syncAllInFlight;
    }

    const syncTask = this.runSyncAll(options);
    this.syncAllInFlight = syncTask;
    try {
      return await syncTask;
    } finally {
      if (this.syncAllInFlight === syncTask) {
        this.syncAllInFlight = null;
      }
    }
  }

  private async runSyncAll(options: SyncAllOptions = {}): Promise<SyncResult> {
    const timestamp = new Date().toISOString();
    const tasks = ['catalogo', 'mesas', 'formas', 'configuracoes', 'usuarios'];
    const details = new Array<SyncTaskResult>(tasks.length);
    const maxParallelTasks = 4;
    const syncStartedAt = Date.now();
    logSyncDiagnostic(`syncAll inicio tasks=${tasks.join(',')}`);

    const runTask = async (task: string): Promise<SyncTaskResult> => {
      const startedAt = Date.now();
      logSyncDiagnostic(`etapa ${task} inicio`);
      try {
        options.onTaskStart?.(task);
      } catch {
        // Callback de UI nao pode interferir na sincronizacao.
      }

      const result = {
        ...(await this.syncPartial(task)),
        durationMs: Date.now() - startedAt
      };

      try {
        options.onTaskFinish?.(result);
      } catch {
        // Callback de UI nao pode interferir na sincronizacao.
      }

      logSyncDiagnostic(`etapa ${task} ${result.status} em ${result.durationMs}ms | ${result.message}`);
      return result;
    };

    let nextTaskIndex = 0;
    const workers = Array.from({ length: Math.min(maxParallelTasks, tasks.length) }, async () => {
      while (nextTaskIndex < tasks.length) {
        const taskIndex = nextTaskIndex;
        nextTaskIndex += 1;
        details[taskIndex] = await runTask(tasks[taskIndex]);
      }
    });

    await Promise.all(workers);
    const orderedDetails = details.filter((item): item is SyncTaskResult => Boolean(item));

    const status: SyncResult['status'] =
      orderedDetails.every((item) => item.status === 'ok') ? 'ok' : 'partial';

    const summary = [
      `Sincronização concluída em ${timestamp}.`,
      ...orderedDetails.map((item) => item.message)
    ];
    logSyncDiagnostic(`syncAll fim status=${status} em ${Date.now() - syncStartedAt}ms`);

    return {
      status,
      timestamp,
      summary,
      details: orderedDetails
    };
  }

  async listCategories(options: CategoryListOptions = {}): Promise<Category[]> {
    const cachedCategories = await this.loadCachedCategories();
    if (options.preferCache && cachedCategories.length > 0) {
      return cachedCategories;
    }

    try {
      const startedAt = Date.now();
      const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/categoria`, {
        preferNativeHttp: options.preferNativeHttp,
        timeoutMs: options.timeoutMs
      });
      if (!Array.isArray(payload)) throw new Error('Erro na API');
      logSyncDiagnostic(`categorias remoto count=${payload.length} em ${Date.now() - startedAt}ms`);
      const categories = payload.map((value: any) => ({
        id: parseNumber((value as any)?.idCategoria, parseNumber((value as any)?.id, 0)),
        descricao: sanitizeText((value as any)?.descricao, `Categoria ${parseNumber((value as any)?.idCategoria, 0)}`),
        PermiteVendaAPP: parseBoolean((value as any)?.PermiteVendaAPP, true)
      }));
      await this.saveCachedCategories(categories);
      return categories;
    } catch (error) {
      if (options.requireRemote) {
        throw error;
      }
      return cachedCategories.length ? cachedCategories : fallbackCategories;
    }
  }

  async listProducts(exibirImagem = true, options: ProductListOptions = {}): Promise<MenuItem[]> {
    if (options.forceRemote) {
      this.clearProductGetCache();
    }

    const preserveCachedImages = options.preserveCachedImages !== false;
    const shouldLoadCachedProducts = options.preferCache || preserveCachedImages || !options.requireRemote;
    const cachedProducts = shouldLoadCachedProducts ? await this.loadCachedProducts({ compact: options.compact }) : [];
    if (options.preferCache && !options.forceRemote && cachedProducts.length > 0) {
      return cachedProducts;
    }

    const loadSeq = ++this.productCatalogLoadSeq;
    const startedAt = Date.now();

    try {
      const productPath = `rpCheff/v1/empresa/${this.idEmpresa}/produto?exibirImagem=${exibirImagem ? 'true' : 'false'}`;
      const { response, payload, rawText } = await this.request(productPath, {
        preferNativeHttp: options.preferNativeHttp,
        timeoutMs:
          typeof options.timeoutMs === 'number' && Number.isFinite(options.timeoutMs) && options.timeoutMs > 0
            ? options.timeoutMs
            : PRODUCT_CATALOG_TIMEOUT_MS
      });
      if (!response.ok) {
        throw new Error(`Falha ao consultar ${productPath}: ${response.status}`);
      }
      if (!Array.isArray(payload)) throw new Error('Erro na API');
      logSyncDiagnostic(
        `produtos remoto count=${payload.length} exibirImagem=${exibirImagem} preserveCachedImages=${preserveCachedImages} em ${Date.now() - startedAt}ms`
      );
      const remoteFingerprint = buildCatalogRawPayloadFingerprint(rawText);
      let knownCatalogFingerprint = this.cachedCatalogProductsFingerprint;
      if (
        remoteFingerprint &&
        (!knownCatalogFingerprint || knownCatalogFingerprint !== remoteFingerprint)
      ) {
        const storedFingerprint = await loadStoredCatalogFingerprint(this.getCatalogStoragePrefix()).catch(() => null);
        if (storedFingerprint) {
          this.cachedCatalogProductsFingerprint = storedFingerprint;
          knownCatalogFingerprint = storedFingerprint;
        }
      }
      let cachedReusableProducts = options.compact ? this.cachedCatalogProductSummaries : this.cachedCatalogProducts;
      if (options.compact && !cachedReusableProducts && this.cachedCatalogProducts) {
        cachedReusableProducts = this.cachedCatalogProducts.map(toCatalogListMenuItem);
        this.cachedCatalogProductSummaries = cachedReusableProducts;
      }
      const canReuseUnchangedCatalog =
        !exibirImagem &&
        !preserveCachedImages &&
        remoteFingerprint &&
        remoteFingerprint === knownCatalogFingerprint &&
        cachedReusableProducts?.length === payload.length;

      if (canReuseUnchangedCatalog) {
        if (cachedReusableProducts) {
          logSyncDiagnostic(
            `produtos prontos cache_memoria count=${cachedReusableProducts.length} compact=${Boolean(options.compact)} em ${Date.now() - startedAt}ms`
          );
          return cachedReusableProducts;
        }
      }

      const remoteProducts = payload.map(parseMenuItem);
      const mergedProducts =
        exibirImagem || preserveCachedImages
          ? exibirImagem
            ? remoteProducts
            : mergeProductsWithCachedImages(remoteProducts, cachedProducts)
          : remoteProducts;
      const products =
        exibirImagem || preserveCachedImages
          ? await this.materializeProductImages(mergedProducts, cachedProducts)
          : stripInlineProductImages(mergedProducts);
      if (loadSeq === this.productCatalogLoadSeq) {
        await this.saveCachedProducts(products, {
          fingerprint: remoteFingerprint
        });
      }
      const resultProducts = options.compact ? products.map(toCatalogListMenuItem) : products;
      logSyncDiagnostic(`produtos prontos count=${resultProducts.length} compact=${Boolean(options.compact)} em ${Date.now() - startedAt}ms`);
      return resultProducts;
    } catch (error) {
      if (options.requireRemote) {
        throw error;
      }
      const fallback = cachedProducts.length ? cachedProducts : fallbackProducts;
      return options.compact ? fallback.map(toCatalogListMenuItem) : fallback;
    }
  }

  async getProduct(idProduto: number, exibirImagem = true): Promise<MenuItem | null> {
    const cachedProduct = await this.loadCachedProduct(idProduto);
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/produto/${idProduto}?exibirImagem=${exibirImagem ? 'true' : 'false'}`,
      {
        method: 'GET',
        timeoutMs: 30000
      }
    );
    if (!response.ok || !payload || typeof payload !== 'object') {
      return cachedProduct;
    }
    return mergeProductWithCachedImage(parseMenuItem(payload), cachedProduct || undefined);
  }

  async listTables(): Promise<TableOrder[]> {
    const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/mesa?_=${Date.now()}`, {
      headers: NO_CACHE_HEADERS
    });
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar mesas');
    return payload.map((value) => parseTable(value, 'mesa'));
  }

  async listTablesBySaleStatus(situacaoVenda: string): Promise<TableOrder[]> {
    const payload = await this.requestJson(
      `rpCheff/v1/empresa/${this.idEmpresa}/mesa?situacaoVenda=${encodeURIComponent(situacaoVenda)}&_=${Date.now()}`,
      { headers: NO_CACHE_HEADERS }
    );
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar mesas');
    return payload.map((value) => parseTable(value, 'mesa'));
  }

  async listComandas(): Promise<TableOrder[]> {
    const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/comanda?_=${Date.now()}`, {
      headers: NO_CACHE_HEADERS
    });
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar comandas');
    return payload.map((value) => parseTable(value, 'comanda'));
  }

  async listComandasBySaleStatus(situacaoVenda: string): Promise<TableOrder[]> {
    const payload = await this.requestJson(
      `rpCheff/v1/empresa/${this.idEmpresa}/comanda?situacaoVenda=${encodeURIComponent(situacaoVenda)}&_=${Date.now()}`,
      { headers: NO_CACHE_HEADERS }
    );
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar comandas');
    return payload.map((value) => parseTable(value, 'comanda'));
  }

  async listTablesByMode(mode: 'mesa' | 'comanda' | 'mesaComanda' = 'mesa'): Promise<TableOrder[]> {
    if (mode === 'comanda') {
      return this.listComandas();
    }

    if (mode === 'mesaComanda') {
      const [mesas, comandas] = await Promise.all([this.listTables(), this.listComandas()]);
      return [...mesas, ...comandas];
    }

    return this.listTables();
  }

  async openTable(tableId: number, nomeMesaComanda?: string, idUsuario = 0): Promise<TableOrder> {
    try {
      const terminal = await this.resolveTerminalName();
      const nomeInformado = String(nomeMesaComanda || '').trim();
      const body: Record<string, unknown> = {
        terminalAbertura: terminal
      };
      const headers: Record<string, string> = {};
      if (Number(idUsuario || 0) > 0) {
        headers.idUsuario = String(Math.trunc(Number(idUsuario)));
      }
      if (nomeInformado) {
        body.nomeMesaComanda = nomeInformado;
      }
      const { response, payload } = await this.request(
        `rpCheff/v1/empresa/${this.idEmpresa}/mesa/${tableId}/abertura`,
        {
          method: 'POST',
          headers,
          body: JSON.stringify(body)
        }
      );
      if (!response.ok) {
        throw new Error(`Não foi possível abrir a mesa ${tableId}.`);
      }
      if (!payload) {
        throw new Error('Resposta inválida ao abrir a mesa.');
      }
      const table = parseTable(payload, 'mesa');
      if (!table.idVenda || Number(table.idVenda) === 0) {
        throw new Error(`Não foi possível iniciar a venda para a mesa ${tableId}.`);
      }
      this.clearTablesGetCache();
      return table;
    } catch {
      throw new Error('Não foi possível abrir a mesa no momento.');
    }
  }

  async openComanda(
    comandaId: number,
    nomeMesaComanda?: string,
    usaCatraca = false,
    idUsuario = 0
  ): Promise<TableOrder> {
    try {
      const terminal = await this.resolveTerminalName();
      const nomeInformado = String(nomeMesaComanda || '').trim();
      const body: Record<string, unknown> = {
        terminalAbertura: terminal
      };
      const headers: Record<string, string> = {};
      if (usaCatraca) {
        headers.usaCatraca = 'true';
      }
      if (Number(idUsuario || 0) > 0) {
        headers.idUsuario = String(Math.trunc(Number(idUsuario)));
      }
      if (nomeInformado) {
        body.nomeMesaComanda = nomeInformado;
      }
      const { response, payload } = await this.request(
        `rpCheff/v1/empresa/${this.idEmpresa}/comanda/${comandaId}/abertura`,
        {
          method: 'POST',
          headers,
          body: JSON.stringify(body)
        }
      );
      if (!response.ok) {
        throw new Error(`Não foi possível abrir a comanda ${comandaId}.`);
      }
      if (!payload) {
        throw new Error('Resposta inválida ao abrir a comanda.');
      }
      const table = parseTable(payload, 'comanda');
      if (!table.idVenda || Number(table.idVenda) === 0) {
        throw new Error(`Não foi possível iniciar a venda para a comanda ${comandaId}.`);
      }
      this.clearTablesGetCache();
      return table;
    } catch {
      throw new Error('Não foi possível abrir a comanda no momento.');
    }
  }

  async openTableByMode(
    tableId: number,
    nomeMesaComanda?: string,
    mode: 'mesa' | 'comanda' | 'mesaComanda' = 'mesa',
    options: {
      usaCatraca?: boolean;
      idUsuario?: number;
    } = {}
  ): Promise<TableOrder> {
    const nomeInformado = String(nomeMesaComanda || '');
    if (mode === 'comanda') {
      return this.openComanda(tableId, nomeMesaComanda, Boolean(options.usaCatraca), Number(options.idUsuario || 0));
    }

    if (mode === 'mesaComanda' && /comanda|c[aã]rd/i.test(nomeInformado)) {
      return this.openComanda(tableId, nomeMesaComanda, Boolean(options.usaCatraca), Number(options.idUsuario || 0));
    }

    return this.openTable(tableId, nomeMesaComanda, Number(options.idUsuario || 0));
  }

  async launchItem(idVenda: number, item: LaunchItemPayload): Promise<LaunchItemPayload> {
    const payloadItem = await this.withTerminalImpressao(item);
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/item`,
      {
        method: 'POST',
        body: JSON.stringify(payloadItem)
      }
    );
    if (!response.ok) {
      throw new Error('Falha ao enviar item para a venda');
    }
    if (!payload) throw new Error('Resposta inválida da API');
    this.clearTablesGetCache();
    return payload as LaunchItemPayload;
  }

  async launchItemsBatch(idVenda: number, items: LaunchItemPayload[]): Promise<void> {
    const payloadItems = await this.withTerminalImpressaoBatch(items);
    const { response } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/item/lote`,
      {
        method: 'POST',
        body: JSON.stringify(payloadItems)
      }
    );
    if (!response.ok) {
      throw new Error('Falha ao enviar itens para a venda');
    }
    this.clearTablesGetCache();
  }

  async listPaymentMethods(): Promise<PaymentMethod[]> {
    try {
      const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/formaPagamento`);
      if (!Array.isArray(payload)) throw new Error('Erro na API');
      return payload.map(parsePaymentMethod);
    } catch {
      return fallbackPaymentMethods;
    }
  }

  async getSale(idVenda: number, listarItens = true): Promise<Sale | null> {
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}?_=${Date.now()}`,
      {
        headers: {
          ...NO_CACHE_HEADERS,
          listarItens: listarItens ? 'true' : 'false'
        }
      }
    );
    if (!response.ok || !payload || typeof payload !== 'object') return null;
    return parseSale(payload);
  }

  async transferTable(
    idOrigem: number,
    idDestino: number,
    tipo: 'mesa' | 'comanda' = 'mesa',
    idUsuario = 0
  ): Promise<void> {
    const resource = tipo === 'comanda' ? 'comanda' : 'mesa';
    const terminal = await this.resolveTerminalName();
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/${resource}/${idOrigem}/transferencia/${idDestino}`,
      {
        method: 'POST',
        body: JSON.stringify({
          terminal,
          idDestino,
          idUsuario
        })
      }
    );
    if (!response.ok) {
      throw new Error(extractApiErrorMessage(payload, `Falha ao transferir ${tipo}`));
    }
    this.clearTablesGetCache();
  }

  async joinSales(idVendaDestino: number, vendasOrigem: number[]): Promise<void> {
    const { response } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVendaDestino}/juncao`,
      {
        method: 'POST',
        body: JSON.stringify({ vendasOrigem })
      }
    );
    if (!response.ok) {
      throw new Error('Falha ao juntar mesas');
    }
    this.clearTablesGetCache();
  }

  async preCloseSale(
    idVenda: number,
    payload: SaleCouvertPayload & {
      idUsuario?: number;
      imprimirPreFechamentoMobile?: boolean;
      preFechamentoMobileImpressaoInterna?: boolean;
    },
    options: {
      accept?: 'application/json' | 'text/plain';
      numeroColunas?: number;
      impressaoInterna?: boolean;
      tipoMaquina?: MachinePaymentType;
    } = {}
  ): Promise<string | void> {
    const requestPayload = {
      ...payload,
      idVenda
    };

    const headers: Record<string, string> = {};
    const wantsTextPlain = options.accept === 'text/plain';
    if (wantsTextPlain) {
      headers.Accept = 'text/plain';
    }
    if (typeof options.numeroColunas === 'number' && Number.isFinite(options.numeroColunas)) {
      headers.numeroColunas = String(Math.max(1, Math.trunc(options.numeroColunas)));
    }
    if (typeof options.impressaoInterna === 'boolean') {
      headers.impressaoInterna = options.impressaoInterna ? 'true' : 'false';
    }
    if (options.tipoMaquina) {
      headers.tipoMaquina = options.tipoMaquina;
    }

    const queryMachine = options.tipoMaquina ? `?tipoMaquina=${encodeURIComponent(options.tipoMaquina)}` : '';
    const { response, payload: responsePayload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/preFechamento${queryMachine}`,
      {
        method: 'PATCH',
        headers,
        body: JSON.stringify(requestPayload),
        timeoutMs: 30000
      }
    );
    if (!response.ok) {
      throw new Error('Falha ao pré-fechar venda');
    }
    this.clearTablesGetCache();

    if (wantsTextPlain) {
      return typeof responsePayload === 'string'
        ? responsePayload
        : JSON.stringify(responsePayload ?? '');
    }
  }

  async closeSale(
    input: SaleClosurePayload,
    options: {
      accept?: 'application/json' | 'text/plain';
      numeroColunas?: number;
      impressaoInterna?: boolean;
      tipoMaquina?: MachinePaymentType;
    } = {}
  ): Promise<string | void> {
    const headers: Record<string, string> = {};
    const wantsTextPlain = options.accept === 'text/plain';

    if (wantsTextPlain) {
      headers.Accept = 'text/plain';
    }

    if (typeof options.numeroColunas === 'number' && Number.isFinite(options.numeroColunas)) {
      headers.numeroColunas = String(Math.max(1, Math.trunc(options.numeroColunas)));
    }

    if (typeof options.impressaoInterna === 'boolean') {
      headers.impressaoInterna = options.impressaoInterna ? 'true' : 'false';
    }

    if (options.tipoMaquina) {
      headers.tipoMaquina = options.tipoMaquina;
    }

    const queryMachine = options.tipoMaquina ? `?tipoMaquina=${encodeURIComponent(options.tipoMaquina)}` : '';
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${input.idVenda}/fechamento${queryMachine}`,
      {
        method: 'POST',
        headers,
        body: JSON.stringify(input),
        timeoutMs: 30000
      }
    );
    if (!response.ok) {
      throw new Error(extractApiErrorMessage(payload, 'Falha ao fechar venda'));
    }
    this.clearTablesGetCache();

    if (wantsTextPlain) {
      return typeof payload === 'string' ? payload : JSON.stringify(payload ?? '');
    }
  }

  async getSalePrint(idVenda: number, options: SalePrintRequest = {}): Promise<string> {
    const headers: Record<string, string> = {
      Accept: 'text/plain',
      listarItens: 'false'
    };

    if (typeof options.numeroColunas === 'number' && Number.isFinite(options.numeroColunas)) {
      headers.numeroColunas = String(Math.max(1, Math.trunc(options.numeroColunas)));
    }

    if (typeof options.impressaoInterna === 'boolean') {
      headers.impressaoInterna = options.impressaoInterna ? 'true' : 'false';
    }

    if (options.tipoMaquina) {
      headers.tipoMaquina = options.tipoMaquina;
    }

    const queryMachine = options.tipoMaquina ? `?tipoMaquina=${encodeURIComponent(options.tipoMaquina)}` : '';
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}${queryMachine}`,
      {
        method: 'GET',
        headers,
        timeoutMs: 30000
      }
    );

    if (!response.ok) {
      throw new Error(extractApiErrorMessage(payload, 'Falha ao buscar impressão da venda'));
    }

    if (typeof payload === 'string') {
      return payload;
    }

    if (payload === null || payload === undefined) {
      return '';
    }

    return JSON.stringify(payload);
  }

  async updateCouvert(
    idVenda: number,
    payload: SaleCouvertPayload
  ): Promise<void> {
    const { response } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/couvert`,
      {
        method: 'PATCH',
        body: JSON.stringify(payload)
      }
    );
    if (!response.ok) {
      throw new Error('Falha ao atualizar couvert');
    }
    this.clearTablesGetCache();
  }

  async setSaleName(
    idVenda: number,
    nomeMesaComanda: string
  ): Promise<void> {
    const { response } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/nome`,
      {
        method: 'PATCH',
        body: JSON.stringify({ nome: nomeMesaComanda })
      }
    );
    if (!response.ok) {
      throw new Error('Falha ao renomear venda');
    }
    this.clearTablesGetCache();
  }

  async listPaymentsBySale(idVenda: number): Promise<SalePayment[]> {
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/pagamentoAntecipado`
    );
    if (!response.ok || !Array.isArray(payload)) {
      throw new Error('Falha ao listar pagamentos da venda');
    }
    const parsed = payload.map(parseSalePayment);
    const seen = new Set<string>();
    return parsed.filter((item) => {
      const key = String(
        item.idVendaPagamentoAntecipado ||
        `${item.idFormaPagamento || 0}-${Number(item.valor || 0).toFixed(2)}-${item.dataHora || ''}`
      );
      if (seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    });
  }

  async registerPartialPayment(input: SalePartialPaymentPayload): Promise<void> {
    const payload = {
      idUsuario: input.idUsuario || 0,
      idEmpresa: this.idEmpresa,
      idFormaPagamento: input.idFormaPagamento,
      valor: Number(input.valor || 0).toFixed(2)
    };
    const { response, payload: responsePayload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${input.idVenda}/pagamento`,
      {
        method: 'POST',
        body: JSON.stringify(payload)
      }
    );
    if (!response.ok) {
      throw new Error(extractApiErrorMessage(responsePayload, 'Falha ao registrar pagamento parcial'));
    }
    this.clearTablesGetCache();
  }

  async reopenSale(idVenda: number): Promise<void> {
    const { response } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/reabertura`,
      {
        method: 'PATCH',
        body: '{}'
      }
    );
    if (!response.ok) {
      throw new Error('Falha ao reabrir venda');
    }
    this.clearTablesGetCache();
  }

  async cancelSaleItem(idVenda: number, numeroItem: number, idUsuario = 0): Promise<void> {
    const payload = {
      idVenda,
      numeroItem,
      idEmpresa: this.idEmpresa,
      idUsuario,
      justificativa: 'Cancelado no mobile'
    };
    const { response } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/item/${numeroItem}`,
      {
        method: 'DELETE',
        body: JSON.stringify(payload)
      }
    );
    if (!response.ok) {
      throw new Error('Falha ao cancelar item');
    }
  }
}

export const api = new ApiClient(defaultMobileSettings.baseUrl, defaultMobileSettings.empresaId);
