import type {
  CartItem,
  Category,
  CompanyStatus,
  LaunchItemFractionPayload,
  LaunchItemPayload,
  LaunchOptionalPayload,
  MenuItem,
  ProductOptional,
  ProductSizeOption,
  Sale,
  SaleLine,
  SaleLineFraction,
  SaleLineOptional,
  TableOrder,
  WaiterProfile
} from '../types';
import { normalizeApiBaseUrl } from './network';

const AUTH_USERNAME = 'RP515TEMAS_CH3FF';
const AUTH_PASSWORD = 'RP515TEMAS';
const DEFAULT_TIMEOUT_MS = 20000;
const PRODUCT_TIMEOUT_MS = 60000;
const NO_CACHE_HEADERS = {
  'Cache-Control': 'no-cache',
  Pragma: 'no-cache'
};

function toBase64(input: string): string {
  const globalBtoa = (globalThis as { btoa?: (value: string) => string }).btoa;
  if (typeof globalBtoa === 'function') {
    return globalBtoa(input);
  }

  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  let output = '';
  let i = 0;

  while (i < input.length) {
    const chr1 = input.charCodeAt(i++);
    const chr2 = input.charCodeAt(i++);
    const chr3 = input.charCodeAt(i++);
    const enc1 = chr1 >> 2;
    const enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
    let enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
    let enc4 = chr3 & 63;

    if (Number.isNaN(chr2)) {
      enc3 = 64;
      enc4 = 64;
    } else if (Number.isNaN(chr3)) {
      enc4 = 64;
    }

    output += alphabet.charAt(enc1) + alphabet.charAt(enc2) + alphabet.charAt(enc3) + alphabet.charAt(enc4);
  }

  return output;
}

function authorizationHeader(): string {
  return `Basic ${toBase64(`${AUTH_USERNAME}:${AUTH_PASSWORD}`)}`;
}

function normalizeHeaders(headers?: Record<string, string>): Record<string, string> {
  return Object.entries(headers || {}).reduce<Record<string, string>>((acc, [key, value]) => {
    if (value !== undefined && value !== null) {
      acc[key] = String(value);
    }
    return acc;
  }, {});
}

export function parseNumber(value: unknown, fallback = 0): number {
  if (typeof value === 'number') return Number.isFinite(value) ? value : fallback;
  if (typeof value === 'string') {
    const cleaned = value.replace(/[^\d,.-]/g, '').replace(',', '.');
    const numeric = Number(cleaned);
    return Number.isFinite(numeric) ? numeric : fallback;
  }
  return fallback;
}

function parseBoolean(value: unknown, fallback = false): boolean {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    return ['1', 'true', 'sim', 's', 'y', 'yes'].includes(value.trim().toLowerCase());
  }
  return fallback;
}

function sanitizeText(value: unknown, fallback = ''): string {
  if (typeof value === 'string') return value.trim();
  if (typeof value === 'number' && Number.isFinite(value)) return String(value);
  if (typeof value === 'boolean') return value ? 'true' : 'false';
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

function stripAccents(value: string): string {
  return value.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
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
  if (typeof value === 'number') {
    return mapStatusCode(value);
  }

  const raw = sanitizeText(value, '');
  if (!raw && typeof value !== 'number') return '';
  if (/^-?\d+$/.test(raw)) return mapStatusCode(Number(raw));
  return stripAccents(raw.toLowerCase());
}

function normalizeImageValue(value: unknown): string | undefined {
  const raw = sanitizeText(value, '');
  if (!raw) return undefined;
  if (/^(https?:|file:|data:image\/)/i.test(raw)) return raw;
  if (/^[a-z0-9+/=\r\n]+$/i.test(raw) && raw.length > 80) {
    return `data:image/jpeg;base64,${raw.replace(/\s/g, '')}`;
  }
  return raw;
}

function readObject(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' ? (value as Record<string, unknown>) : {};
}

function parseOptional(value: unknown): ProductOptional {
  const source = readObject(value);
  return {
    idOpcional: parseNumber(resolveField(source, ['idOpcional', 'id_opcional', 'id', 'opc_001']), 0),
    descricao: sanitizeText(resolveField(source, ['descricao', 'nome', 'opc_002']), ''),
    valor: parseNumber(resolveField(source, ['valor', 'valorVenda', 'valor_venda', 'opc_003']), 0),
    gratis: parseBoolean(resolveField(source, ['gratis', 'b_gratis']), false),
    opcionalP: sanitizeText(resolveField(source, ['opcionalP', 'opcional_p']), ''),
    opcionalM: sanitizeText(resolveField(source, ['opcionalM', 'opcional_m']), ''),
    opcionalG: sanitizeText(resolveField(source, ['opcionalG', 'opcional_g']), ''),
    opcionalGG: sanitizeText(resolveField(source, ['opcionalGG', 'opcional_gg']), ''),
    opcionalExtra: sanitizeText(resolveField(source, ['opcionalExtra', 'opcional_extra']), ''),
    valorOpcionalP: parseNumber(resolveField(source, ['valorOpcionalP', 'valor_opcional_p']), 0),
    valorOpcionalM: parseNumber(resolveField(source, ['valorOpcionalM', 'valor_opcional_m']), 0),
    valorOpcionalG: parseNumber(resolveField(source, ['valorOpcionalG', 'valor_opcional_g']), 0),
    valorOpcionalGG: parseNumber(resolveField(source, ['valorOpcionalGG', 'valor_opcional_gg']), 0),
    valorOpcionalExtra: parseNumber(resolveField(source, ['valorOpcionalExtra', 'valor_opcional_extra']), 0)
  };
}

function parseMenuItem(value: unknown): MenuItem {
  const source = readObject(value);
  const rawOptionals = resolveField(source, [
    'opcionais',
    'opcionaisProduto',
    'produtoOpcional',
    'produtoOpcionais',
    'opcionais_produto',
    'opcional'
  ]);
  const optionals = Array.isArray(rawOptionals)
    ? rawOptionals
    : rawOptionals && typeof rawOptionals === 'object'
      ? [rawOptionals]
      : [];
  const idProduto = parseNumber(resolveField(source, ['idProduto', 'id', 'mat_001']), 0);

  return {
    id: idProduto,
    idProduto,
    descricao: sanitizeText(resolveField(source, ['descricao', 'mat_003']), 'Produto'),
    descricaoCurta: sanitizeText(resolveField(source, ['descricaoCurta', 'descricao_curta']), '') || undefined,
    codReferencia: sanitizeText(resolveField(source, ['codReferencia', 'cod_referencia', 'codigoReferencia', 'mat_004']), '') || undefined,
    imagem: normalizeImageValue(resolveField(source, ['imagemLocalPath', 'imagem_local_path', 'imagem', 'imagem_db', 'imagemDb'])),
    valorVenda: parseNumber(resolveField(source, ['valorVenda', 'valor_venda']), parseNumber(resolveField(source, ['valorUnitario', 'valor_unitario']), 0)),
    valorUnitario: parseNumber(resolveField(source, ['valorUnitario', 'valor_unitario']), parseNumber(resolveField(source, ['valorVenda', 'valor_venda']), 0)),
    idCategoria: parseNumber(resolveField(source, ['idCategoria', 'idcategoria', 'cat_001']), 0) || undefined,
    b_venda_mobile: parseBoolean(
      resolveField(source, ['b_venda_mobile', 'bVendaMobile', 'permiteVendaMobile', 'PermiteVendaAPP', 'permiteVendaAPP']),
      true
    ),
    vendaPorTamanho: parseBoolean(
      resolveField(source, ['vendaPorTamanho', 'VendaPorTamanho', 'venda_por_tamanho', 'b_venda_tamanho', 'vendaTamanho']),
      false
    ),
    tamanhoPadrao: sanitizeText(resolveField(source, ['tamanhoPadrao', 'tamanho_padrao']), ''),
    tamanhoP: sanitizeText(resolveField(source, ['tamanhoP', 'tamanho_p']), ''),
    tamanhoM: sanitizeText(resolveField(source, ['tamanhoM', 'tamanho_m']), ''),
    tamanhoG: sanitizeText(resolveField(source, ['tamanhoG', 'tamanho_g']), ''),
    tamanhoGG: sanitizeText(resolveField(source, ['tamanhoGG', 'tamanho_gg']), ''),
    tamanhoExtra: sanitizeText(resolveField(source, ['tamanhoExtra', 'tamanho_extra']), ''),
    valorTamanhoP: parseNumber(resolveField(source, ['valorTamanhoP', 'valor_tamanho_p', 'valorP']), 0),
    valorTamanhoM: parseNumber(resolveField(source, ['valorTamanhoM', 'valor_tamanho_m', 'valorM']), 0),
    valorTamanhoG: parseNumber(resolveField(source, ['valorTamanhoG', 'valor_tamanho_g', 'valorG']), 0),
    valorTamanhoGG: parseNumber(resolveField(source, ['valorTamanhoGG', 'valor_tamanho_gg', 'valorGG']), 0),
    valorTamanhoExtra: parseNumber(resolveField(source, ['valorTamanhoExtra', 'valor_tamanho_extra', 'valorExtra']), 0),
    usaQuantidadeDecimal: parseBoolean(resolveField(source, ['usaQuantidadeDecimal', 'usa_quantidade_decimal']), false),
    permiteFracao: parseBoolean(
      resolveField(source, ['permiteFracao', 'permite_fracao', 'permiteFracionado', 'b_permite_fracao']),
      false
    ),
    opcionais: optionals.map(parseOptional).filter((optional) => optional.idOpcional > 0 || optional.descricao.trim())
  };
}

function parseCategory(value: unknown): Category {
  const source = readObject(value);
  const id = parseNumber(resolveField(source, ['idCategoria', 'id', 'cat_001']), 0);
  return {
    id,
    descricao: sanitizeText(resolveField(source, ['descricao', 'cat_002']), `Categoria ${id}`),
    permiteVendaApp: parseBoolean(resolveField(source, ['PermiteVendaAPP', 'permiteVendaAPP', 'permite_venda_app']), true)
  };
}

function parseCompanyStatus(value: unknown): CompanyStatus {
  const source = readObject(value);
  const idEmpresa = parseNumber(resolveField(source, ['idEmpresa', 'emp_001', 'id']), 0);

  return {
    idEmpresa,
    nome: sanitizeText(resolveField(source, ['nome', 'emp_003', 'razaoSocial']), '') || undefined,
    utilizaCardapioTablet: parseBoolean(
      resolveField(source, ['utilizaCardapioTablet', 'utiliza_cardapiotablet', 'UtilizaCardapioTablet']),
      false
    )
  };
}

function parseUserProfile(value: unknown): WaiterProfile {
  const source = readObject(value);
  return {
    idUsuario: parseNumber(resolveField(source, ['idUsuario', 'id', 'usu_001']), 0),
    nome: sanitizeText(resolveField(source, ['nome', 'name', 'usu_002']), 'Garcom'),
    login: sanitizeText(resolveField(source, ['login', 'usuario', 'usu_003']), '')
  };
}

function normalizeTableName(idMesa: number, numeroMesa: number, informed: string): string {
  const name = informed.trim();
  if (name) return name;
  const displayNumber = numeroMesa || idMesa;
  return `Mesa ${String(displayNumber).padStart(2, '0')}`;
}

function parseTable(value: unknown): TableOrder {
  const source = readObject(value);
  const venda = readObject(source.venda);
  const tableNumero = parseNumber(
    resolveField(source, ['numero', 'numeroMesa', 'numero_mesa', 'mes_003']),
    parseNumber(resolveField(source, ['idMesa', 'id_mesa', 'id', 'idTabela']), 0)
  );
  const numeroMesa = tableNumero || parseNumber(resolveField(venda, ['numeroMesa', 'numero_mesa', 'numero']), 0);
  const idMesa = parseNumber(
    resolveField(source, ['idMesa', 'id_mesa', 'id', 'idTabela']),
    numeroMesa || parseNumber(resolveField(venda, ['idMesa', 'id_mesa']), 0)
  );
  const nomeInformado = sanitizeText(
    resolveField(source, ['nomeMesaComanda', 'descricao', 'mesaNome']) ??
      resolveField(venda, ['nomeMesaComanda', 'descricao']),
    ''
  );
  const situacao = sanitizeText(source.situacao ?? venda.situacao, '');
  const idVenda = parseNumber(source.idVenda, parseNumber(venda.idVenda, 0));
  const vendaValorTotal = parseNumber(resolveField(venda, ['valorTotal', 'valor_total', 'valor']), 0);

  return {
    idMesa,
    numeroMesa: numeroMesa || undefined,
    nomeMesaComanda: normalizeTableName(idMesa, numeroMesa, nomeInformado),
    situacao,
    statusOriginal: sanitizeText(source.situacao ?? venda.situacao, ''),
    statusCode: sanitizeText(source.statusCode ?? source.status, ''),
    valorTotal: parseNumber(source.valorTotal, parseNumber(source.valor, vendaValorTotal)),
    idVenda,
    venda:
      Object.keys(venda).length > 0
        ? {
            idVenda: parseNumber(venda.idVenda, 0),
            situacao: sanitizeText(venda.situacao, '') || undefined,
            nomeMesaComanda: sanitizeText(venda.nomeMesaComanda, '') || undefined,
            valorTotal: vendaValorTotal
          }
        : undefined
  };
}

function parseSale(value: unknown): Sale {
  const source = readObject(value);
  const rawItems = resolveField(source, ['itens', 'items', 'linhas', 'itensVenda', 'vendaItens']);

  return {
    idVenda: parseNumber(source.idVenda, 0),
    valor: parseNumber(source.valor, 0),
    valorTotal: parseNumber(source.valorTotal, parseNumber(source.valor, 0)),
    situacao: sanitizeText(source.situacao, '') || undefined,
    numeroMesa: parseNumber(source.numeroMesa, 0),
    nomeMesaComanda: sanitizeText(source.nomeMesaComanda, '') || undefined,
    itens: Array.isArray(rawItems) ? rawItems.map(parseSaleLine) : []
  };
}

function parseSaleLineOptional(value: unknown): SaleLineOptional {
  const source = readObject(value);
  return {
    idOpcional: parseNumber(resolveField(source, ['idOpcional', 'id_opcional', 'id', 'opc_001']), 0),
    descricao: sanitizeText(resolveField(source, ['descricao', 'nome', 'opc_002']), ''),
    valor: parseNumber(resolveField(source, ['valor', 'valorVenda', 'valor_venda', 'opc_003']), 0),
    gratis: parseBoolean(resolveField(source, ['gratis', 'b_gratis']), false)
  };
}

function parseSaleLineFraction(value: unknown): SaleLineFraction {
  const source = readObject(value);
  const descricaoTamanho = resolveField(source, ['descricaoTamanho', 'DescricaoTamanho', 'descricao_tamanho']);
  return {
    idProduto: parseNumber(resolveField(source, ['idProduto', 'id_produto', 'mat_001']), 0),
    produtoDescricao: sanitizeText(resolveField(source, ['produtoDescricao', 'descricao', 'mat_003']), ''),
    numeroItem: parseNumber(resolveField(source, ['numeroItem', 'ite_001']), 0),
    quantidade: parseNumber(resolveField(source, ['quantidade', 'qtd', 'ite_003']), 0),
    valorUnitario: parseNumber(resolveField(source, ['valorUnitario', 'valor_unitario', 'valorVenda']), 0),
    valorTotal: parseNumber(resolveField(source, ['valorTotal', 'valor_total', 'total']), 0),
    acrescimo: parseNumber(resolveField(source, ['acrescimo', 'valorAcrescimo']), 0),
    observacao: sanitizeText(resolveField(source, ['observacao', 'obs']), '') || undefined,
    descricaoTamanho: descricaoTamanho ? sanitizeText(descricaoTamanho, '') : undefined,
    opcionais: Array.isArray(source.opcionais) ? source.opcionais.map(parseSaleLineOptional) : []
  };
}

function parseSaleLine(value: unknown): SaleLine {
  const source = readObject(value);
  const normalizedStatus = normalizeSaleStatus(resolveField(source, ['situacao', 'sit_001', 'status']));
  const rawFractions = resolveField(source, ['fracoes', 'fracao']);
  const rawOptionals = resolveField(source, ['opcionais', 'opcional', 'adicionais']);
  const rawWaiterName = sanitizeText(resolveField(source, ['nomeGarcom', 'nome_garcom', 'garcom']), '');

  return {
    idProduto: parseNumber(resolveField(source, ['idProduto', 'id_produto', 'mat_001']), 0),
    produtoDescricao: sanitizeText(resolveField(source, ['produtoDescricao', 'descricao', 'mat_003']), 'Produto'),
    imagem: normalizeImageValue(resolveField(source, ['imagem', 'imagem_db', 'imagemDb'])),
    numeroItem: parseNumber(resolveField(source, ['numeroItem', 'ite_001']), 0),
    itemFracionado: parseNumber(resolveField(source, ['itemFracionado', 'item_fracionado']), 0),
    situacao: normalizedStatus.includes('cancel') ? 'cancelada' : normalizedStatus || undefined,
    quantidade: parseNumber(resolveField(source, ['quantidade', 'qtd', 'ite_003']), 0),
    valorUnitario: parseNumber(resolveField(source, ['valorUnitario', 'valor_unitario', 'valorVenda']), 0),
    valorTotal: parseNumber(resolveField(source, ['valorTotal', 'valor_total', 'total']), 0),
    desconto: parseNumber(resolveField(source, ['desconto', 'valorDesconto']), 0),
    acrescimo: parseNumber(resolveField(source, ['acrescimo', 'valorAcrescimo']), 0),
    idGarcom: parseNumber(resolveField(source, ['idGarcom', 'gar_001']), 0),
    nomeGarcom: rawWaiterName || undefined,
    tamanho: sanitizeText(resolveField(source, ['tamanho', 'tam']), 'U'),
    descricaoTamanho: sanitizeText(resolveField(source, ['descricaoTamanho', 'DescricaoTamanho', 'descricao_tamanho']), '') || undefined,
    dataHora: sanitizeText(resolveField(source, ['dataHora', 'data_hora', 'dataLancamento', 'data_lancamento']), '') || undefined,
    observacao: sanitizeText(resolveField(source, ['observacao', 'obs']), '') || undefined,
    vendaPorTamanho: parseBoolean(resolveField(source, ['vendaPorTamanho', 'venda_por_tamanho']), false),
    idMesaVinculada: parseNumber(resolveField(source, ['idMesaVinculada', 'id_mesa_vinculada']), 0),
    opcionais: Array.isArray(rawOptionals) ? rawOptionals.map(parseSaleLineOptional) : [],
    fracoes: Array.isArray(rawFractions) ? rawFractions.map(parseSaleLineFraction) : []
  };
}

function extractApiErrorMessage(payload: unknown, fallback: string): string {
  if (!payload) return fallback;
  if (typeof payload === 'string') return payload.trim() || fallback;
  if (typeof payload !== 'object') return fallback;
  const source = payload as Record<string, unknown>;
  const direct = sanitizeText(source.message ?? source.mensagem ?? source.error ?? source.erro, '');
  return direct || fallback;
}

async function readJsonResponse(response: Response): Promise<{ payload: unknown; rawText: string }> {
  const rawText = await response.text();
  if (!rawText) return { payload: null, rawText };
  try {
    return { payload: JSON.parse(rawText), rawText };
  } catch {
    return { payload: rawText, rawText };
  }
}

export function roundMoney(value: number): number {
  return Math.round((Number(value || 0) + Number.EPSILON) * 100) / 100;
}

export function getCartItemTotal(
  item: Pick<CartItem, 'quantidade' | 'valorUnitario' | 'opcionais' | 'fracoes'>
): number {
  const baseTotal = item.fracoes?.length
    ? item.fracoes.reduce(
        (total, fraction) => total + Number(fraction.valorTotal || 0) + Number(fraction.acrescimo || 0),
        0
      )
    : Number(item.valorUnitario || 0) * Number(item.quantidade || 0);
  const optionalTotal = item.opcionais.reduce(
    (total, optional) => total + (optional.gratis ? 0 : Number(optional.valor || 0) * Number(item.quantidade || 0)),
    0
  );
  return roundMoney(baseTotal + optionalTotal);
}

export function getCartTotal(items: CartItem[]): number {
  return roundMoney(items.reduce((total, item) => total + getCartItemTotal(item), 0));
}

export function buildLaunchPayload(item: CartItem, idMesa: number, idGarcom: number, terminalName: string): LaunchItemPayload {
  return {
    mobileLaunchId: item.lineId,
    MobileLaunchId: item.lineId,
    idProduto: item.product.idProduto,
    quantidade: item.quantidade,
    valorUnitario: item.valorUnitario,
    valorTotal: getCartItemTotal(item),
    desconto: 0,
    acrescimo: 0,
    tamanho: item.tamanho,
    vendaPorTamanho: Boolean(item.product.vendaPorTamanho),
    descricaoTamanho: item.descricaoTamanho,
    observacao: item.observacao,
    idMesaVinculada: idMesa,
    idGarcom,
    terminalImpressao: terminalName,
    TerminalImpressao: terminalName,
    opcionais: item.opcionais,
    fracoes: item.fracoes?.map((fraction, index): LaunchItemFractionPayload => {
      const mobileLaunchId = fraction.mobileLaunchId || `${item.lineId}:F${index + 1}`;
      return {
        ...fraction,
        mobileLaunchId,
        MobileLaunchId: mobileLaunchId
      };
    })
  };
}

export function getProductSizeOptions(product: MenuItem): ProductSizeOption[] {
  if (!product.vendaPorTamanho) {
    return [
      {
        code: 'U',
        label: 'Unico',
        value: Number(product.valorUnitario || product.valorVenda || 0)
      }
    ];
  }

  const candidates: ProductSizeOption[] = [
    { code: 'P', label: product.tamanhoP || 'P', value: Number(product.valorTamanhoP || 0) },
    { code: 'M', label: product.tamanhoM || 'M', value: Number(product.valorTamanhoM || 0) },
    { code: 'G', label: product.tamanhoG || 'G', value: Number(product.valorTamanhoG || 0) },
    { code: 'GG', label: product.tamanhoGG || 'GG', value: Number(product.valorTamanhoGG || 0) },
    { code: 'E', label: product.tamanhoExtra || 'Extra', value: Number(product.valorTamanhoExtra || 0) }
  ];

  const valid = candidates.filter((item) => item.value > 0 || item.label.trim().length > 0);
  if (valid.length > 0) return valid;

  return [
    {
      code: product.tamanhoPadrao || 'U',
      label: product.tamanhoPadrao || 'Unico',
      value: Number(product.valorUnitario || product.valorVenda || 0)
    }
  ];
}

export function getDefaultSizeCode(product: MenuItem): string {
  const sizes = getProductSizeOptions(product);
  const preferred = sanitizeText(product.tamanhoPadrao, '').toUpperCase();
  return sizes.find((item) => item.code.toUpperCase() === preferred)?.code || sizes[0]?.code || 'U';
}

export function getProductUnitPrice(product: MenuItem, sizeCode: string): number {
  const selected = getProductSizeOptions(product).find((item) => item.code === sizeCode);
  return Number(selected?.value || product.valorUnitario || product.valorVenda || 0);
}

export function getProductSizeLabel(product: MenuItem, sizeCode: string): string {
  return getProductSizeOptions(product).find((item) => item.code === sizeCode)?.label || sizeCode || 'Unico';
}

export function getOptionalDisplay(optional: ProductOptional, sizeCode: string): string {
  if (sizeCode === 'P' && optional.opcionalP) return optional.opcionalP;
  if (sizeCode === 'M' && optional.opcionalM) return optional.opcionalM;
  if (sizeCode === 'G' && optional.opcionalG) return optional.opcionalG;
  if (sizeCode === 'GG' && optional.opcionalGG) return optional.opcionalGG;
  if ((sizeCode === 'E' || sizeCode === 'EXTRA') && optional.opcionalExtra) return optional.opcionalExtra;
  return optional.descricao;
}

export function getOptionalPrice(optional: ProductOptional, sizeCode: string): number {
  if (sizeCode === 'P' && optional.valorOpcionalP !== undefined) return Number(optional.valorOpcionalP || 0);
  if (sizeCode === 'M' && optional.valorOpcionalM !== undefined) return Number(optional.valorOpcionalM || 0);
  if (sizeCode === 'G' && optional.valorOpcionalG !== undefined) return Number(optional.valorOpcionalG || 0);
  if (sizeCode === 'GG' && optional.valorOpcionalGG !== undefined) return Number(optional.valorOpcionalGG || 0);
  if ((sizeCode === 'E' || sizeCode === 'EXTRA') && optional.valorOpcionalExtra !== undefined) {
    return Number(optional.valorOpcionalExtra || 0);
  }
  return Number(optional.valor || 0);
}

export function isTableOpenForTablet(table: TableOrder | null | undefined): boolean {
  if (!table || Number(table.idVenda || table.venda?.idVenda || 0) <= 0) return false;
  const status = normalizeSaleStatus(table.venda?.situacao || table.situacao || table.statusOriginal || table.statusCode);
  if (!status) return true;
  return (
    status.includes('pendente') ||
    status.includes('digitacao') ||
    status.includes('aberta') ||
    status.includes('aberto')
  );
}

export function findTableByNumber(tables: TableOrder[], mesaNumero: number, idMesa?: number): TableOrder | null {
  const desiredNumber = Number(mesaNumero || 0);
  const desiredId = Number(idMesa || 0);
  return (
    tables.find((table) => desiredId > 0 && Number(table.idMesa || 0) === desiredId) ||
    tables.find((table) => Number(table.numeroMesa || 0) === desiredNumber) ||
    tables.find((table) => Number(table.idMesa || 0) === desiredNumber) ||
    null
  );
}

type RequestOptions = {
  method?: string;
  headers?: Record<string, string>;
  body?: string;
  timeoutMs?: number;
};

export class TabletApi {
  constructor(
    private readonly baseUrl: string,
    private readonly empresaId: number
  ) {}

  private buildUrl(path: string): string {
    const base = normalizeApiBaseUrl(this.baseUrl);
    const normalizedPath = path.replace(/^\/+/, '');
    return `${base}/${normalizedPath}`;
  }

  private async request(path: string, options: RequestOptions = {}) {
    const controller = typeof AbortController !== 'undefined' ? new AbortController() : null;
    const timeoutMs = options.timeoutMs || DEFAULT_TIMEOUT_MS;
    const timeout = controller ? setTimeout(() => controller.abort(), timeoutMs) : null;
    const headers = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      Authorization: authorizationHeader(),
      ...normalizeHeaders(options.headers)
    };

    try {
      const response = await fetch(this.buildUrl(path), {
        method: options.method || 'GET',
        headers,
        body: options.body,
        ...(controller ? { signal: controller.signal } : {})
      });
      const { payload, rawText } = await readJsonResponse(response);
      return { response, payload, rawText };
    } finally {
      if (timeout) clearTimeout(timeout);
    }
  }

  private async requestJson(path: string, options: RequestOptions = {}): Promise<unknown> {
    const { response, payload } = await this.request(path, options);
    if (!response.ok) {
      throw new Error(extractApiErrorMessage(payload, `Falha ao consultar ${path}: ${response.status}`));
    }
    return payload;
  }

  async ping(): Promise<boolean> {
    const { response } = await this.request('rpCheff/v1/ping', { timeoutMs: 8000 });
    return response.ok;
  }

  async getCompanyStatus(): Promise<CompanyStatus> {
    const payload = await this.requestJson(`rpCheff/v1/empresa/${this.empresaId}?_=${Date.now()}`, {
      headers: NO_CACHE_HEADERS,
      timeoutMs: 10000
    });
    const status = parseCompanyStatus(payload);
    if (Number(status.idEmpresa || 0) <= 0) {
      throw new Error('Empresa nao encontrada.');
    }
    return status;
  }

  async login(login: string, senha: string): Promise<WaiterProfile> {
    const normalizedLogin = login.trim();
    const normalizedPassword = senha.trim();
    if (!normalizedLogin || !normalizedPassword) {
      throw new Error('Informe usuario e senha.');
    }

    const { response, payload } = await this.request(`rpCheff/v1/empresa/${this.empresaId}/usuario/login`, {
      method: 'POST',
      body: JSON.stringify({ login: normalizedLogin, senha: normalizedPassword })
    });

    if (!response.ok) {
      throw new Error(extractApiErrorMessage(payload, 'Usuario ou senha invalidos.'));
    }

    const user = parseUserProfile(payload);
    if (Number(user.idUsuario || 0) <= 0) {
      throw new Error('Usuario ou senha invalidos.');
    }
    return user;
  }

  async listCategories(): Promise<Category[]> {
    const payload = await this.requestJson(`rpCheff/v1/empresa/${this.empresaId}/categoria`);
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar categorias.');
    return payload.map(parseCategory).filter((item) => item.id > 0 && item.permiteVendaApp !== false);
  }

  async listProducts(exibirImagem = true): Promise<MenuItem[]> {
    const payload = await this.requestJson(
      `rpCheff/v1/empresa/${this.empresaId}/produto?exibirImagem=${exibirImagem ? 'true' : 'false'}`,
      { timeoutMs: PRODUCT_TIMEOUT_MS }
    );
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar produtos.');
    return payload.map(parseMenuItem).filter((item) => item.idProduto > 0 && item.b_venda_mobile !== false);
  }

  async listTables(): Promise<TableOrder[]> {
    const payload = await this.requestJson(`rpCheff/v1/empresa/${this.empresaId}/mesa?_=${Date.now()}`, {
      headers: NO_CACHE_HEADERS
    });
    if (!Array.isArray(payload)) throw new Error('Erro na API ao carregar mesas.');
    return payload.map(parseTable);
  }

  async openTable(tableId: number, terminalName: string, idUsuario: number, nomeMesaComanda?: string): Promise<TableOrder> {
    const body: Record<string, unknown> = {
      terminalAbertura: terminalName
    };
    const name = sanitizeText(nomeMesaComanda, '');
    if (name) {
      body.nomeMesaComanda = name;
    }

    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.empresaId}/mesa/${tableId}/abertura`,
      {
        method: 'POST',
        headers: {
          idUsuario: String(Math.trunc(Number(idUsuario || 0)))
        },
        body: JSON.stringify(body)
      }
    );

    if (!response.ok) {
      throw new Error(extractApiErrorMessage(payload, `Nao foi possivel abrir a mesa ${tableId}.`));
    }

    const table = parseTable(payload);
    if (!table.idVenda) {
      throw new Error(`Nao foi possivel iniciar a venda para a mesa ${tableId}.`);
    }
    return table;
  }

  async getSale(idVenda: number, listarItens = false): Promise<Sale | null> {
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.empresaId}/venda/${idVenda}?_=${Date.now()}`,
      {
        headers: {
          ...NO_CACHE_HEADERS,
          listarItens: listarItens ? 'true' : 'false'
        }
      }
    );
    if (!response.ok || !payload) return null;
    return parseSale(payload);
  }

  async launchItemsBatch(idVenda: number, items: LaunchItemPayload[]): Promise<void> {
    const { response, payload } = await this.request(
      `rpCheff/v1/empresa/${this.empresaId}/venda/${idVenda}/item/lote`,
      {
        method: 'POST',
        body: JSON.stringify(items)
      }
    );

    if (!response.ok) {
      throw new Error(extractApiErrorMessage(payload, 'Falha ao enviar itens para a venda.'));
    }
  }
}
