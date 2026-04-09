import AsyncStorage from '@react-native-async-storage/async-storage';
import * as FileSystem from 'expo-file-system';
import { NativeModules, Platform } from 'react-native';

export type MenuItem = {
  id: number;
  idProduto: number;
  descricao: string;
  descricaoCurta?: string;
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
  opcionais?: ProductOptional[];
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
  opcionais: LaunchOptionalPayload[];
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
};

export type SyncTaskResult = {
  key: string;
  status: 'ok' | 'error' | 'skip';
  message: string;
};

export type SyncResult = {
  status: 'ok' | 'partial' | 'error';
  timestamp: string;
  summary: string[];
  details?: SyncTaskResult[];
};

export type TableOrder = {
  idMesa: number;
  idComanda?: number;
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

export type UserProfile = {
  idUsuario: number;
  nome: string;
  login: string;
  permiteCancelarItemMobile?: boolean;
  permitePreFechamentoMesaComanda?: boolean;
  permiteFechamentoMesaComanda?: boolean;
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
  tipoIntegracao: 'nenhum' | 'vero' | 'stone' | 'pagbank' | 'cielo';
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
  utilizaMaquininhaStone: false,
  tipoIntegracao: 'nenhum',
  modeloMaquininha: 'false',
  usuario: '',
  senha: ''
};

const STORAGE_KEY = '@rpcheff:mobile-settings';
const CATALOG_STORAGE_VERSION = 3;

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

export const quickConnectionCheckTimeoutMs = 4000;

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

const nativeHttpModule: NativeHttpModule | undefined =
  Platform.OS === 'android' ? (NativeModules.RPCheffHttp as NativeHttpModule | undefined) : undefined;

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
      return 'nenhum';
    }
  }

  if (typeof rawIntegration === 'number' && Number.isFinite(rawIntegration)) {
    if (rawIntegration === 1) return 'vero';
    if (rawIntegration === 2) return 'stone';
    if (rawIntegration === 3) return 'pagbank';
    if (rawIntegration === 4) return 'cielo';
  }

  if (parseBoolean(values.utilizaIntegracaoCielo, false)) return 'cielo';
  if (parseBoolean(values.utilizaIntegracaoPagBank, false)) return 'pagbank';
  if (parseBoolean(values.rp_movel_integracao_cielo, false)) return 'cielo';
  if (parseBoolean(values.rp_movel_integracao_pagbank, false)) return 'pagbank';
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
  if (!raw) return defaultMobileSettings;
  try {
    return normalizeMobileSettings(JSON.parse(raw));
  } catch {
    return defaultMobileSettings;
  }
};

export const saveMobileSettings = async (payload: MobileAppSettings): Promise<void> => {
  const data = normalizeMobileSettings(payload);
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(data));
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

  if (/^(https?:\/\/|file:\/\/|content:\/\/)/i.test(trimmed)) {
    return undefined;
  }

  const dataUriPrefixMatch = trimmed.match(/^data:image\/[^;]+;base64,/i);
  if (dataUriPrefixMatch) {
    const payload = trimmed.slice(dataUriPrefixMatch[0].length).replace(/\s+/g, '');
    return payload || undefined;
  }

  const normalizedPayload = trimmed.replace(/\s+/g, '');
  return normalizedPayload || undefined;
}

function extractStoredImageLocalPath(image?: string): string | undefined {
  const trimmed = String(image || '').trim();
  if (!trimmed) {
    return undefined;
  }

  return /^(file:\/\/|content:\/\/)/i.test(trimmed) ? trimmed : undefined;
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

function toStoredMenuItem(item: MenuItem): StoredMenuItem {
  const { imagem, imagemLocalPath, ...rest } = item;
  const storedImage = extractStoredImagePayload(item.imagem_db || imagem);
  return {
    ...rest,
    ...(storedImage ? { imagem_db: storedImage } : {}),
    ...(imagemLocalPath ? { imagem_local_path: imagemLocalPath } : {})
  };
}

function mergeProductWithCachedImage(product: MenuItem, cached?: MenuItem): MenuItem {
  const cachedLocalImagePath = extractStoredImageLocalPath(cached?.imagemLocalPath || cached?.imagem);
  const cachedInlineImage = resolveImageUri(cached?.imagem);
  const cachedImagePayload = cached?.imagem_db;
  const hasCachedImage = Boolean(cachedLocalImagePath || cachedInlineImage || cachedImagePayload);

  if (product.possuiImagem === false) {
    if (!product.imagem && !product.imagem_db && !product.imagemLocalPath && hasCachedImage) {
      return {
        ...product,
        imagem: cachedLocalImagePath || cachedInlineImage,
        imagem_db: cachedImagePayload,
        imagemLocalPath: cachedLocalImagePath,
        possuiImagem: true
      };
    }

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
  const mergedImagePayload = extractStoredImagePayload(product.imagem_db || product.imagem) || cachedImagePayload;
  const mergedInlineImage = resolveImageUri(product.imagem) || cachedInlineImage;

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
    imagem: mergedLocalImagePath || mergedInlineImage,
    imagem_db: mergedImagePayload,
    imagemLocalPath: mergedLocalImagePath,
    possuiImagem: true
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
  const item: MenuItem = {
    id: parseNumber(resolveField(value, ['idProduto', 'id']), 0),
    idProduto: parseNumber(resolveField(value, ['idProduto', 'id']), 0),
    descricao: String(value?.descricao ?? ''),
    descricaoCurta: value?.descricaoCurta ? String(value.descricaoCurta) : undefined,
    imagem: normalizedLocalImage || normalizedImage,
    imagem_db: storedImagePayload,
    imagemLocalPath: normalizedLocalImage,
    possuiImagem: parseBoolean(
      resolveField(value, ['possuiImagem', 'possui_imagem', 'temImagem', 'tem_imagem']),
      Boolean(normalizedLocalImage || normalizedImage)
    ),
    idCategoria: (() => {
      const rawCategory = resolveField(value, ['idCategoria', 'idcategoria']);
      return rawCategory ? parseNumber(rawCategory, 0) : undefined;
    })(),
    b_venda_mobile: parseBoolean(
      resolveField(value, ['b_venda_mobile', 'bVendamobile', 'bVendaMobile', 'permiteVendaMobile']),
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
    value?.numero,
    parseNumber(value?.idMesa, parseNumber(value?.id, parseNumber(value?.idTabela, 0)))
  );
  const mesaNumero = tableNumero || parseNumber(venda?.numero, 0);
  const comandaNumero = parseNumber(value?.numeroComanda, parseNumber(venda?.numeroComanda, idComanda));
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
    nomeMesaComanda: normalizeNomeMesa(resolvedMesaId, isComanda ? 'Comanda' : 'Mesa', comandaNumero || mesaNumero, nomeInformado),
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
    codigo: parseNumber(resolveField(value, ['codigo', 'id', 'idFormaPagamento', 'idFormaPgto']), 0),
    descricao: sanitizeText(
      resolveField(value, ['descricao', 'nome', 'descricaoFormaPagamento', 'descricao_forma_pagamento']),
      ''
    ),
    sfiCodigo: typeof parsedSfi === 'number' && parsedSfi > 0 ? parsedSfi : undefined,
    sfiDescricao: sanitizeText(resolveField(value, ['sfiDescricao', 'sfi_descricao', 'descricaoSfi']), ''),
    cortesia: parseBoolean(resolveField(value, ['cortesia']), false),
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
    idContaCorrente: parseNumber(resolveField(value, ['idContaCorrente', 'id_conta_corrente']), 0)
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
    opcionais: Array.isArray(value?.opcionais) ? value.opcionais.map(parseSaleLineOptional) : []
  };
}

function parseSalePayment(value: any): SalePayment {
  const forma = value?.formaPagamento;
  return {
    idVendaPagamentoAntecipado: parseNumber(value?.idVendaPagamentoAntecipado, 0),
    idFormaPagamento: parseNumber(value?.idFormaPagamento ?? value?.idFormapagamento, 0),
    valor: parseNumber(value?.valor, 0),
    formaPagamento: forma ? parsePaymentMethod(forma) : undefined,
    dataHora: value?.dataHora ? String(value.dataHora) : undefined,
    observacao: value?.observacao ? String(value.observacao) : undefined,
    taxaServico: parseBoolean(value?.TaxaServico ?? value?.taxaServico, false)
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
    valorTaxaServico: parseNumber(value?.valorTaxaServico, 0),
    valorEntrada: parseNumber(value?.valorEntrada, 0),
    valorDesconto: parseNumber(value?.valorDesconto, 0),
    tipoDesconto:
      value?.tipoDesconto !== undefined && value?.tipoDesconto !== null
        ? parseNumber(value.tipoDesconto, 0)
        : undefined,
    itens: Array.isArray(value?.itens) ? value.itens.map(parseSaleLine) : [],
    pagamentos: Array.isArray(value?.pagamentos) ? value.pagamentos.map(parseSalePayment) : []
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

  if (/^(data:image\/|https?:\/\/|file:\/\/|content:\/\/)/i.test(trimmed)) {
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

async function safeJson(response: Response) {
  const text = await response.text();
  try {
    return text ? JSON.parse(text) : null;
  } catch {
    return text;
  }
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
  private catalogSchemaReadyKey: string | null = null;

  constructor(private baseUrl: string, private idEmpresa = 1) {}

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
  }

  private clearTablesGetCache() {
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/mesa`);
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/comanda`);
  }

  private clearMenuGetCache() {
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/categoria`);
    this.clearGetCacheByPrefix(`/empresa/${this.idEmpresa}/produto`);
  }

  private clearCatalogMemoryCache() {
    this.cachedCatalogCategories = null;
    this.cachedCatalogProducts = null;
    this.catalogSchemaReadyKey = null;
  }

  private async materializeProductImages(products: MenuItem[], previousProducts: MenuItem[]): Promise<MenuItem[]> {
    if (!products.length) {
      return products;
    }

    const imageDirectory = buildCatalogImageDirectory(this.baseUrl, this.idEmpresa);
    if (!imageDirectory) {
      return products;
    }

    const previousProductsById = new Map<number, MenuItem>();
    previousProducts.forEach((item) => {
      const id = Number(item.idProduto || item.id || 0);
      if (id > 0) {
        previousProductsById.set(id, item);
      }
    });

    const hasAnyImagePayload = products.some((item) => Boolean(extractStoredImagePayload(item.imagem_db || item.imagem)));
    if (hasAnyImagePayload) {
      try {
        await FileSystem.makeDirectoryAsync(imageDirectory, { intermediates: true });
      } catch {
        return products;
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
          try {
            const info = await FileSystem.getInfoAsync(knownLocalPath);
            if (info.exists) {
              resolvedProducts.push({
                ...product,
                imagem: knownLocalPath,
                imagemLocalPath: knownLocalPath
              });
              continue;
            }
          } catch {}
        }

        resolvedProducts.push({
          ...product,
          imagemLocalPath: undefined
        });
        continue;
      }

      if (knownLocalPath && previousProduct?.imagem_db === imagePayload) {
        try {
          const info = await FileSystem.getInfoAsync(knownLocalPath);
          const expectedImageSize = estimateBase64DecodedSize(imagePayload);
          const currentImageSize = typeof info.size === 'number' ? info.size : 0;
          if (
            info.exists &&
            (!expectedImageSize || !currentImageSize || Math.abs(currentImageSize - expectedImageSize) <= 2)
          ) {
            resolvedProducts.push({
              ...product,
              imagem: knownLocalPath,
              imagem_db: imagePayload,
              imagemLocalPath: knownLocalPath,
              possuiImagem: true
            });
            continue;
          }
        } catch {}
      }

      const imageExtension = getImageFileExtensionFromPayload(imagePayload);
      const imagePath = `${imageDirectory}${productId || resolvedProducts.length + 1}.${imageExtension}`;

      try {
        await FileSystem.writeAsStringAsync(imagePath, imagePayload, {
          encoding: FileSystem.EncodingType.Base64
        });
        resolvedProducts.push({
          ...product,
          imagem: imagePath,
          imagem_db: imagePayload,
          imagemLocalPath: imagePath,
          possuiImagem: true
        });
      } catch {
        resolvedProducts.push({
          ...product,
          imagem_db: imagePayload
        });
      }
    }

    return resolvedProducts;
  }

  private getCatalogStoragePrefix() {
    return buildCatalogStoragePrefix(this.baseUrl, this.idEmpresa);
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

    const storedVersion = Number((await AsyncStorage.getItem(schemaKey)) || 0);
    if (storedVersion !== CATALOG_STORAGE_VERSION) {
      const existingIds = await this.readCachedProductIds();
      const keysToRemove = [
        this.getCatalogCategoriesKey(),
        this.getCatalogProductIdsKey(),
        ...existingIds.map((id) => this.getCatalogProductKey(id))
      ];
      if (keysToRemove.length > 0) {
        await AsyncStorage.multiRemove(keysToRemove);
      }
      await AsyncStorage.setItem(schemaKey, String(CATALOG_STORAGE_VERSION));
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
    await AsyncStorage.setItem(this.getCatalogCategoriesKey(), JSON.stringify(normalized));
  }

  private async loadCachedProducts(): Promise<MenuItem[]> {
    if (this.cachedCatalogProducts) {
      return this.cachedCatalogProducts;
    }

    await this.ensureCatalogStorageSchema();

    try {
      const ids = await this.readCachedProductIds();
      if (!ids.length) {
        this.cachedCatalogProducts = [];
        return this.cachedCatalogProducts;
      }

      const entries = await AsyncStorage.multiGet(ids.map((id) => this.getCatalogProductKey(id)));
      this.cachedCatalogProducts = entries
        .map(([, raw]) => {
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

      return this.cachedCatalogProducts;
    } catch {
      this.cachedCatalogProducts = [];
      return this.cachedCatalogProducts;
    }
  }

  private async saveCachedProducts(products: MenuItem[]) {
    await this.ensureCatalogStorageSchema();

    const uniqueById = new Map<number, MenuItem>();
    products.forEach((item) => {
      const id = Number(item.idProduto || item.id || 0);
      if (id > 0) {
        uniqueById.set(id, {
          ...item,
          imagem_db: extractStoredImagePayload(item.imagem_db || item.imagem)
        });
      }
    });

    const normalized = [...uniqueById.values()].sort((a, b) => (a.idProduto || a.id) - (b.idProduto || b.id));
    const nextIds = normalized.map((item) => Number(item.idProduto || item.id || 0)).filter((item) => item > 0);
    const previousIds = await this.readCachedProductIds();
    const nextIdSet = new Set(nextIds);
    const staleKeys = previousIds.filter((id) => !nextIdSet.has(id)).map((id) => this.getCatalogProductKey(id));
    const pairs: [string, string][] = [
      [this.getCatalogProductIdsKey(), JSON.stringify(nextIds)],
      ...normalized.map((item) => [
        this.getCatalogProductKey(Number(item.idProduto || item.id || 0)),
        JSON.stringify(toStoredMenuItem(item))
      ])
    ];

    await AsyncStorage.multiSet(pairs);
    if (staleKeys.length > 0) {
      await AsyncStorage.multiRemove(staleKeys);
    }

    this.cachedCatalogProducts = normalized;
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
    const payload = await safeJson(response);
    return { response, payload };
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

      const payload = await safeJson(response);
      return { response, payload };
    } finally {
      if (timeout) {
        clearTimeout(timeout);
      }
    }
  }

  private async request(path: string, init: (RequestInit & { timeoutMs?: number }) = {}) {
    const { timeoutMs: customTimeoutMs, ...fetchInit } = init;
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
    const fallbackTimeoutMs = Math.max(1500, Math.floor(timeoutMs / 2));

    if (Platform.OS === 'android' && nativeHttpModule?.request) {
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

  private async requestJson(
    path: string,
    init: (RequestInit & { timeoutMs?: number }) = {}
  ): Promise<unknown> {
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
        timeoutMs: options.timeoutMs
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
      timeoutMs: options.timeoutMs
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

  async listUsers(): Promise<UserProfile[]> {
    try {
      const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/usuario`);
      if (!Array.isArray(payload)) throw new Error('Resposta inválida da API');
      return payload.map(parseUserProfile);
    } catch {
      return [];
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

  async syncPartial(task: string): Promise<SyncTaskResult> {
    const taskCode = String(task || '').toLowerCase();

    try {
      if (taskCode === 'catalogo' || taskCode === 'produtos' || taskCode === 'categorias') {
        this.clearMenuGetCache();
        const [categories, products] = await Promise.all([this.listCategories(), this.listProducts(true)]);
        return {
          key: task,
          status: categories.length > 0 || products.length > 0 ? 'ok' : 'skip',
          message: `Catálogo: ${categories.length} categorias | ${products.length} produtos`
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
        const responsePayload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/usuario`);
        if (!Array.isArray(responsePayload)) {
          throw new Error('Resposta inválida');
        }
        return {
          key: task,
          status: 'ok',
          message: `${responsePayload.length} usuários carregados`
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

  async syncAll(): Promise<SyncResult> {
    const timestamp = new Date().toISOString();
    const tasks = ['catalogo', 'mesas', 'formas', 'configuracoes', 'usuarios'];
    const details: SyncTaskResult[] = [];
    for (const task of tasks) {
      details.push(await this.syncPartial(task));
    }
    const status: SyncResult['status'] =
      details.every((item) => item.status === 'ok') ? 'ok' : 'partial';

    const summary = [
      `Sincronização concluída em ${timestamp}.`,
      ...details.map((item) => item.message)
    ];

    return {
      status,
      timestamp,
      summary,
      details
    };
  }

  async listCategories(): Promise<Category[]> {
    const cachedCategories = await this.loadCachedCategories();
    try {
      const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/categoria`);
      if (!Array.isArray(payload)) throw new Error('Erro na API');
      const categories = payload.map((value: any) => ({
        id: parseNumber((value as any)?.idCategoria, parseNumber((value as any)?.id, 0)),
        descricao: sanitizeText((value as any)?.descricao, `Categoria ${parseNumber((value as any)?.idCategoria, 0)}`),
        PermiteVendaAPP: parseBoolean((value as any)?.PermiteVendaAPP, true)
      }));
      await this.saveCachedCategories(categories);
      return categories;
    } catch {
      return cachedCategories.length ? cachedCategories : fallbackCategories;
    }
  }

  async listProducts(exibirImagem = true): Promise<MenuItem[]> {
    const cachedProducts = await this.loadCachedProducts();
    try {
      const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/produto?exibirImagem=${exibirImagem ? 'true' : 'false'}`, {
        timeoutMs: 60000
      });
      if (!Array.isArray(payload)) throw new Error('Erro na API');
      const remoteProducts = payload.map(parseMenuItem);
      const mergedProducts = exibirImagem ? remoteProducts : mergeProductsWithCachedImages(remoteProducts, cachedProducts);
      const products = await this.materializeProductImages(mergedProducts, cachedProducts);
      await this.saveCachedProducts(products);
      return products;
    } catch {
      return cachedProducts.length ? cachedProducts : fallbackProducts;
    }
  }

  async getProduct(idProduto: number, exibirImagem = true): Promise<MenuItem | null> {
    const cachedProducts = await this.loadCachedProducts();
    const cachedProduct = cachedProducts.find((item) => Number(item.idProduto || item.id || 0) === Number(idProduto || 0)) || null;
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
    const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/mesa`);
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar mesas');
    return payload.map((value) => parseTable(value, 'mesa'));
  }

  async listTablesBySaleStatus(situacaoVenda: string): Promise<TableOrder[]> {
    const payload = await this.requestJson(
      `rpCheff/v1/empresa/${this.idEmpresa}/mesa?situacaoVenda=${encodeURIComponent(situacaoVenda)}`
    );
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar mesas');
    return payload.map((value) => parseTable(value, 'mesa'));
  }

  async listComandas(): Promise<TableOrder[]> {
    const payload = await this.requestJson(`rpCheff/v1/empresa/${this.idEmpresa}/comanda`);
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar comandas');
    return payload.map((value) => parseTable(value, 'comanda'));
  }

  async listComandasBySaleStatus(situacaoVenda: string): Promise<TableOrder[]> {
    const payload = await this.requestJson(
      `rpCheff/v1/empresa/${this.idEmpresa}/comanda?situacaoVenda=${encodeURIComponent(situacaoVenda)}`
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

  async openTable(tableId: number, nomeMesaComanda?: string): Promise<TableOrder> {
    try {
      const terminal = await this.resolveTerminalName();
      const nomeInformado = String(nomeMesaComanda || '').trim();
      const body: Record<string, unknown> = {
        terminalAbertura: terminal
      };
      if (nomeInformado) {
        body.nomeMesaComanda = nomeInformado;
      }
      const { response, payload } = await this.request(
        `rpCheff/v1/empresa/${this.idEmpresa}/mesa/${tableId}/abertura`,
        {
          method: 'POST',
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

  async openComanda(comandaId: number, nomeMesaComanda?: string): Promise<TableOrder> {
    try {
      const terminal = await this.resolveTerminalName();
      const nomeInformado = String(nomeMesaComanda || '').trim();
      const body: Record<string, unknown> = {
        terminal
      };
      if (nomeInformado) {
        body.nomeMesaComanda = nomeInformado;
      }
      const { response, payload } = await this.request(
        `rpCheff/v1/empresa/${this.idEmpresa}/comanda/${comandaId}/abertura`,
        {
          method: 'POST',
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
    mode: 'mesa' | 'comanda' | 'mesaComanda' = 'mesa'
  ): Promise<TableOrder> {
    const nomeInformado = String(nomeMesaComanda || '');
    if (mode === 'comanda') {
      return this.openComanda(tableId, nomeMesaComanda);
    }

    if (mode === 'mesaComanda' && /comanda|c[aã]rd/i.test(nomeInformado)) {
      return this.openComanda(tableId, nomeMesaComanda);
    }

    return this.openTable(tableId, nomeMesaComanda);
  }

  async launchItem(idVenda: number, item: LaunchItemPayload): Promise<LaunchItemPayload> {
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/item`,
      {
        method: 'POST',
        body: JSON.stringify(item)
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
    const { response } = await this.request(
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}/item/lote`,
      {
        method: 'POST',
        body: JSON.stringify(items)
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
      `rpCheff/v1/empresa/${this.idEmpresa}/venda/${idVenda}`,
      {
        headers: {
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


