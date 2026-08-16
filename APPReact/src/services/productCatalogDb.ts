import { Platform } from 'react-native';
import type { SQLiteDatabase } from 'expo-sqlite';

const DATABASE_NAME = 'rpcheff-local.db';
const PRODUCT_TABLE_NAME = 'mobile_catalog_products';
const META_TABLE_NAME = 'mobile_catalog_meta';

type ProductCatalogRow = {
  id_produto: number;
  compact_json: string | null;
  full_json: string | null;
};

export type ProductCatalogSummaryItem = {
  idProduto: number;
  descricao: string | null;
  descricaoCurta: string | null;
  codReferencia: string | null;
  idCategoria: number | null;
  valorVenda: number | null;
  valorUnitario: number | null;
  bVendaMobile: number | null;
  vendaPorTamanho: number | null;
  tamanhoPadrao: string | null;
  tamanhoP: string | null;
  tamanhoM: string | null;
  tamanhoG: string | null;
  tamanhoGG: string | null;
  tamanhoExtra: string | null;
  valorTamanhoP: number | null;
  valorTamanhoM: number | null;
  valorTamanhoG: number | null;
  valorTamanhoGG: number | null;
  valorTamanhoExtra: number | null;
  usaQuantidadeDecimal: number | null;
  permiteFracao: number | null;
  possuiImagem: number | null;
  imagemLocalPath: string | null;
  happyHourAtivar: number | null;
  happyHourJson: string | null;
  restringirVenda: number | null;
  restricaoJson: string | null;
};

type ProductCatalogMetaRow = {
  fingerprint: string | null;
};

export type ProductCatalogPersistItem = {
  id: number;
  sortOrder: number;
  compactJson: string;
  fullJson: string;
  descricao?: string;
  descricaoCurta?: string;
  codReferencia?: string;
  idCategoria?: number;
  valorVenda?: number;
  valorUnitario?: number;
  bVendaMobile?: boolean;
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
  possuiImagem?: boolean;
  imagemLocalPath?: string;
  happyHourAtivar?: boolean;
  happyHourJson?: string;
  restringirVenda?: boolean;
  restricaoJson?: string;
};

let databasePromise: Promise<SQLiteDatabase> | null = null;
let schemaPromise: Promise<void> | null = null;

const PRODUCT_SUMMARY_COLUMNS: Array<[string, string]> = [
  ['descricao', 'TEXT'],
  ['descricao_curta', 'TEXT'],
  ['cod_referencia', 'TEXT'],
  ['id_categoria', 'INTEGER'],
  ['valor_venda', 'REAL'],
  ['valor_unitario', 'REAL'],
  ['b_venda_mobile', 'INTEGER'],
  ['venda_por_tamanho', 'INTEGER'],
  ['tamanho_padrao', 'TEXT'],
  ['tamanho_p', 'TEXT'],
  ['tamanho_m', 'TEXT'],
  ['tamanho_g', 'TEXT'],
  ['tamanho_gg', 'TEXT'],
  ['tamanho_extra', 'TEXT'],
  ['valor_tamanho_p', 'REAL'],
  ['valor_tamanho_m', 'REAL'],
  ['valor_tamanho_g', 'REAL'],
  ['valor_tamanho_gg', 'REAL'],
  ['valor_tamanho_extra', 'REAL'],
  ['usa_quantidade_decimal', 'INTEGER'],
  ['permite_fracao', 'INTEGER'],
  ['possui_imagem', 'INTEGER'],
  ['imagem_local_path', 'TEXT'],
  ['happy_hour_ativar', 'INTEGER'],
  ['happy_hour_json', 'TEXT'],
  ['restringir_venda', 'INTEGER'],
  ['restricao_json', 'TEXT']
];

const PRODUCT_INSERT_COLUMNS = [
  'catalog_key',
  'id_produto',
  'sort_order',
  'compact_json',
  'full_json',
  'descricao',
  'descricao_curta',
  'cod_referencia',
  'id_categoria',
  'valor_venda',
  'valor_unitario',
  'b_venda_mobile',
  'venda_por_tamanho',
  'tamanho_padrao',
  'tamanho_p',
  'tamanho_m',
  'tamanho_g',
  'tamanho_gg',
  'tamanho_extra',
  'valor_tamanho_p',
  'valor_tamanho_m',
  'valor_tamanho_g',
  'valor_tamanho_gg',
  'valor_tamanho_extra',
  'usa_quantidade_decimal',
  'permite_fracao',
  'possui_imagem',
  'imagem_local_path',
  'happy_hour_ativar',
  'happy_hour_json',
  'restringir_venda',
  'restricao_json',
  'atualizado_em'
];

const PRODUCT_INSERT_BATCH_SIZE = 20;

function isSupportedPlatform() {
  return Platform.OS === 'android' || Platform.OS === 'ios';
}

async function getDatabaseAsync(): Promise<SQLiteDatabase | null> {
  if (!isSupportedPlatform()) {
    return null;
  }

  if (!databasePromise) {
    databasePromise = (async () => {
      const expoSqlite = await import('expo-sqlite');
      return expoSqlite.openDatabaseAsync(DATABASE_NAME);
    })();
  }

  return databasePromise;
}

async function ensureProductSummaryColumnsAsync(db: SQLiteDatabase): Promise<void> {
  const columns = await db.getAllAsync<{ name: string }>(`PRAGMA table_info(${PRODUCT_TABLE_NAME})`);
  const existingColumns = new Set(columns.map((column) => String(column.name || '').toLowerCase()));

  for (const [name, type] of PRODUCT_SUMMARY_COLUMNS) {
    if (!existingColumns.has(name.toLowerCase())) {
      await db.execAsync(`ALTER TABLE ${PRODUCT_TABLE_NAME} ADD COLUMN ${name} ${type}`);
    }
  }
}

async function ensureSchemaAsync(): Promise<void> {
  if (!isSupportedPlatform()) {
    return;
  }

  if (!schemaPromise) {
    schemaPromise = (async () => {
      const db = await getDatabaseAsync();
      if (!db) {
        return;
      }

      await db.execAsync(`
        CREATE TABLE IF NOT EXISTS ${PRODUCT_TABLE_NAME} (
          catalog_key TEXT NOT NULL,
          id_produto INTEGER NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          compact_json TEXT NOT NULL,
          full_json TEXT NOT NULL,
          descricao TEXT,
          descricao_curta TEXT,
          cod_referencia TEXT,
          id_categoria INTEGER,
          valor_venda REAL,
          valor_unitario REAL,
          b_venda_mobile INTEGER,
          venda_por_tamanho INTEGER,
          tamanho_padrao TEXT,
          tamanho_p TEXT,
          tamanho_m TEXT,
          tamanho_g TEXT,
          tamanho_gg TEXT,
          tamanho_extra TEXT,
          valor_tamanho_p REAL,
          valor_tamanho_m REAL,
          valor_tamanho_g REAL,
          valor_tamanho_gg REAL,
          valor_tamanho_extra REAL,
          usa_quantidade_decimal INTEGER,
          permite_fracao INTEGER,
          possui_imagem INTEGER,
          imagem_local_path TEXT,
          happy_hour_ativar INTEGER,
          happy_hour_json TEXT,
          restringir_venda INTEGER,
          restricao_json TEXT,
          atualizado_em TEXT,
          PRIMARY KEY (catalog_key, id_produto)
        );
      `);

      await ensureProductSummaryColumnsAsync(db);

      await db.execAsync(`
        CREATE INDEX IF NOT EXISTS idx_${PRODUCT_TABLE_NAME}_catalog_sort
          ON ${PRODUCT_TABLE_NAME} (catalog_key, sort_order);
        CREATE INDEX IF NOT EXISTS idx_${PRODUCT_TABLE_NAME}_catalog_category
          ON ${PRODUCT_TABLE_NAME} (catalog_key, id_categoria, sort_order);
        CREATE INDEX IF NOT EXISTS idx_${PRODUCT_TABLE_NAME}_catalog_code
          ON ${PRODUCT_TABLE_NAME} (catalog_key, cod_referencia);
        CREATE TABLE IF NOT EXISTS ${META_TABLE_NAME} (
          catalog_key TEXT PRIMARY KEY NOT NULL,
          fingerprint TEXT,
          atualizado_em TEXT
        );
      `);
    })().catch((error) => {
      schemaPromise = null;
      throw error;
    });
  }

  await schemaPromise;
}

export async function loadStoredCatalogProductSummaries(catalogKey: string): Promise<ProductCatalogSummaryItem[]> {
  if (!isSupportedPlatform()) {
    return [];
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return [];
    }

    const rows = await db.getAllAsync<ProductCatalogSummaryItem>(
      `
        SELECT
          id_produto AS idProduto,
          descricao AS descricao,
          descricao_curta AS descricaoCurta,
          cod_referencia AS codReferencia,
          id_categoria AS idCategoria,
          valor_venda AS valorVenda,
          valor_unitario AS valorUnitario,
          b_venda_mobile AS bVendaMobile,
          venda_por_tamanho AS vendaPorTamanho,
          tamanho_padrao AS tamanhoPadrao,
          tamanho_p AS tamanhoP,
          tamanho_m AS tamanhoM,
          tamanho_g AS tamanhoG,
          tamanho_gg AS tamanhoGG,
          tamanho_extra AS tamanhoExtra,
          valor_tamanho_p AS valorTamanhoP,
          valor_tamanho_m AS valorTamanhoM,
          valor_tamanho_g AS valorTamanhoG,
          valor_tamanho_gg AS valorTamanhoGG,
          valor_tamanho_extra AS valorTamanhoExtra,
          usa_quantidade_decimal AS usaQuantidadeDecimal,
          permite_fracao AS permiteFracao,
          possui_imagem AS possuiImagem,
          imagem_local_path AS imagemLocalPath,
          happy_hour_ativar AS happyHourAtivar,
          happy_hour_json AS happyHourJson,
          restringir_venda AS restringirVenda,
          restricao_json AS restricaoJson
        FROM ${PRODUCT_TABLE_NAME}
        WHERE catalog_key = ? AND descricao IS NOT NULL AND descricao <> ''
        ORDER BY sort_order ASC, id_produto ASC
      `,
      catalogKey
    );

    return rows.filter((row) => Math.trunc(Number(row.idProduto || 0)) > 0);
  } catch {
    return [];
  }
}

export async function countStoredCatalogProductSummaries(catalogKey: string): Promise<number> {
  if (!isSupportedPlatform()) {
    return 0;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return 0;
    }

    const row = await db.getFirstAsync<{ count: number }>(
      `
        SELECT COUNT(1) AS count
        FROM ${PRODUCT_TABLE_NAME}
        WHERE catalog_key = ? AND descricao IS NOT NULL AND descricao <> ''
      `,
      catalogKey
    );
    const count = Number(row?.count || 0);
    return Number.isFinite(count) ? count : 0;
  } catch {
    return 0;
  }
}

export async function countProductsMissingImage(catalogKey: string): Promise<number | null> {
  if (!isSupportedPlatform()) {
    return null;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return null;
    }

    // total junto com missing: uma tabela SEM linhas deste catalogo (espelho
    // SQLite nunca populado) devolveria COUNT(*)=0 e habilitaria o fast-path
    // indevidamente - nesse caso respondemos null para o chamador cair no
    // caminho completo (loadCachedProducts + hasMissingCatalogImageCache).
    const row = await db.getFirstAsync<{ total: number; missing: number }>(
      `
        SELECT COUNT(*) AS total,
               SUM(CASE WHEN possui_imagem = 1 AND (imagem_local_path IS NULL OR imagem_local_path = '') THEN 1 ELSE 0 END) AS missing
        FROM ${PRODUCT_TABLE_NAME}
        WHERE catalog_key = ?
      `,
      catalogKey
    );
    if (!row) {
      return null;
    }

    const total = Number(row.total);
    if (!Number.isFinite(total) || total <= 0) {
      return null;
    }

    const missing = Number(row.missing);
    return Number.isFinite(missing) ? missing : null;
  } catch {
    return null;
  }
}

export async function loadStoredCatalogProducts(
  catalogKey: string,
  options: { compact?: boolean } = {}
): Promise<string[]> {
  if (!isSupportedPlatform()) {
    return [];
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return [];
    }

    const rows = await db.getAllAsync<ProductCatalogRow>(
      `
        SELECT id_produto, compact_json, full_json
        FROM ${PRODUCT_TABLE_NAME}
        WHERE catalog_key = ?
        ORDER BY sort_order ASC, id_produto ASC
      `,
      catalogKey
    );

    return rows
      .map((row) => (options.compact ? row.compact_json : row.full_json) || row.full_json || row.compact_json || '')
      .filter((value) => value.length > 0);
  } catch {
    return [];
  }
}

export async function loadStoredCatalogProduct(catalogKey: string, idProduto: number): Promise<string | null> {
  if (!isSupportedPlatform()) {
    return null;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return null;
    }

    const row = await db.getFirstAsync<ProductCatalogRow>(
      `
        SELECT full_json, compact_json
        FROM ${PRODUCT_TABLE_NAME}
        WHERE catalog_key = ? AND id_produto = ?
        LIMIT 1
      `,
      catalogKey,
      Math.trunc(Number(idProduto || 0))
    );

    return row?.full_json || row?.compact_json || null;
  } catch {
    return null;
  }
}

export async function loadStoredCatalogFingerprint(catalogKey: string): Promise<string | null> {
  if (!isSupportedPlatform()) {
    return null;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return null;
    }

    const row = await db.getFirstAsync<ProductCatalogMetaRow>(
      `SELECT fingerprint FROM ${META_TABLE_NAME} WHERE catalog_key = ? LIMIT 1`,
      catalogKey
    );
    return row?.fingerprint || null;
  } catch {
    return null;
  }
}

function normalizeText(value: unknown): string | null {
  const text = String(value || '').trim();
  return text || null;
}

function normalizeNumber(value: unknown): number | null {
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : null;
}

function normalizeFlag(value: unknown): number | null {
  if (typeof value !== 'boolean') {
    return null;
  }
  return value ? 1 : 0;
}

function buildProductInsertValues(
  catalogKey: string,
  item: ProductCatalogPersistItem,
  now: string
): Array<string | number | null> {
  return [
    catalogKey,
    Math.trunc(Number(item.id || 0)),
    item.sortOrder,
    item.compactJson,
    item.fullJson,
    normalizeText(item.descricao),
    normalizeText(item.descricaoCurta),
    normalizeText(item.codReferencia),
    normalizeNumber(item.idCategoria),
    normalizeNumber(item.valorVenda),
    normalizeNumber(item.valorUnitario),
    normalizeFlag(item.bVendaMobile),
    normalizeFlag(item.vendaPorTamanho),
    normalizeText(item.tamanhoPadrao),
    normalizeText(item.tamanhoP),
    normalizeText(item.tamanhoM),
    normalizeText(item.tamanhoG),
    normalizeText(item.tamanhoGG),
    normalizeText(item.tamanhoExtra),
    normalizeNumber(item.valorTamanhoP),
    normalizeNumber(item.valorTamanhoM),
    normalizeNumber(item.valorTamanhoG),
    normalizeNumber(item.valorTamanhoGG),
    normalizeNumber(item.valorTamanhoExtra),
    normalizeFlag(item.usaQuantidadeDecimal),
    normalizeFlag(item.permiteFracao),
    normalizeFlag(item.possuiImagem),
    normalizeText(item.imagemLocalPath),
    normalizeFlag(item.happyHourAtivar),
    normalizeText(item.happyHourJson),
    normalizeFlag(item.restringirVenda),
    normalizeText(item.restricaoJson),
    now
  ];
}

export async function saveStoredCatalogProducts(
  catalogKey: string,
  products: ProductCatalogPersistItem[],
  fingerprint: string
): Promise<void> {
  if (!isSupportedPlatform()) {
    return;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return;
    }

    const now = new Date().toISOString();
    await db.withExclusiveTransactionAsync(async (txn) => {
      await txn.runAsync(`DELETE FROM ${PRODUCT_TABLE_NAME} WHERE catalog_key = ?`, catalogKey);

      const insertColumnsSql = PRODUCT_INSERT_COLUMNS.join(', ');
      const rowPlaceholder = `(${PRODUCT_INSERT_COLUMNS.map(() => '?').join(', ')})`;
      for (let index = 0; index < products.length; index += PRODUCT_INSERT_BATCH_SIZE) {
        const batch = products.slice(index, index + PRODUCT_INSERT_BATCH_SIZE);
        if (!batch.length) {
          continue;
        }

        const placeholders = batch.map(() => rowPlaceholder).join(', ');
        const values = batch.flatMap((item) => buildProductInsertValues(catalogKey, item, now));
        await txn.runAsync(
          `
            INSERT INTO ${PRODUCT_TABLE_NAME} (${insertColumnsSql})
            VALUES ${placeholders}
          `,
          values
        );
      }

      await txn.runAsync(
        `
          INSERT INTO ${META_TABLE_NAME} (catalog_key, fingerprint, atualizado_em)
          VALUES (?, ?, ?)
          ON CONFLICT(catalog_key) DO UPDATE SET
            fingerprint = excluded.fingerprint,
            atualizado_em = excluded.atualizado_em
        `,
        catalogKey,
        fingerprint,
        now
      );
    });
  } catch {
    // AsyncStorage segue como fallback quando o espelho SQLite estiver indisponivel.
  }
}
