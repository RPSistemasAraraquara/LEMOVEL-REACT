import { Platform } from 'react-native';
import type { SQLiteDatabase } from 'expo-sqlite';

export type StoredMachineIntegration = 'nenhum' | 'vero' | 'stone' | 'pagbank' | 'cielo' | 'getnet';

export type StoredMachineSettings = {
  utilizaMaquininhaStone: boolean;
  tipoIntegracao: StoredMachineIntegration;
  modeloMaquininha: string;
};

export type StoredGetNetTransaction = {
  callerId: string;
  amount: string;
  amountValue: number;
  result: number;
  resultDetails?: string;
  nsu?: string;
  nsuLastSuccessfulMessage?: string;
  cvNumber?: string;
  brand?: string;
  type?: string;
  inputType?: string;
  installments?: string;
  gmtDateTime?: string;
  nsuLocal?: string;
  authorizationCode?: string;
  cardBin?: string;
  cardLastDigits?: string;
  cardholderName?: string;
  extraScreensResult?: string;
  splitPayloadResponse?: string;
  pixPayloadResponse?: string;
  automationSlip?: string;
  refunded?: boolean;
  orderId?: string;
  receiptAlreadyPrinted?: boolean;
  printMerchantPreference?: boolean;
  provider: 'getnet';
  raw: Record<string, unknown>;
  updatedAt: string;
};

export type StoredGetNetSubseller = {
  id: number;
  document: string;
  name: string;
  occupation?: string;
  comissionPercentage?: number;
  comissionValue?: number;
};

export type StoredGetNetSubsellers = {
  marketPlaceId: string;
  subsellers: StoredGetNetSubseller[];
  result: number;
  resultDetails?: string;
  provider: 'getnet';
  raw: Record<string, unknown>;
  updatedAt: string;
};

type MachineSettingsRow = {
  utiliza_maquininha: number | null;
  tipo_integracao: string | null;
  modelo_maquininha: string | null;
  ultima_transacao_getnet_json?: string | null;
  subsellers_getnet_json?: string | null;
};

const DATABASE_NAME = 'rpcheff-local.db';
const TABLE_NAME = 'mobile_machine_settings';

let databasePromise: Promise<SQLiteDatabase> | null = null;
let schemaPromise: Promise<void> | null = null;

function isSupportedPlatform() {
  return Platform.OS === 'android' || Platform.OS === 'ios';
}

function normalizeIntegration(value: unknown): StoredMachineIntegration {
  const normalized = String(value || '')
    .trim()
    .toLowerCase();

  if (
    normalized === 'vero' ||
    normalized === 'stone' ||
    normalized === 'pagbank' ||
    normalized === 'cielo' ||
    normalized === 'getnet'
  ) {
    return normalized;
  }

  return 'nenhum';
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
        CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
          id INTEGER PRIMARY KEY NOT NULL CHECK (id = 1),
          utiliza_maquininha INTEGER NOT NULL DEFAULT 0,
          tipo_integracao TEXT NOT NULL DEFAULT 'nenhum',
          modelo_maquininha TEXT NOT NULL DEFAULT 'false',
          ultima_transacao_getnet_json TEXT,
          subsellers_getnet_json TEXT,
          atualizado_em TEXT
        );
      `);

      try {
        await db.execAsync(`ALTER TABLE ${TABLE_NAME} ADD COLUMN ultima_transacao_getnet_json TEXT;`);
      } catch {
        // Coluna já existente em bases atualizadas.
      }
      try {
        await db.execAsync(`ALTER TABLE ${TABLE_NAME} ADD COLUMN subsellers_getnet_json TEXT;`);
      } catch {
        // Coluna já existente em bases atualizadas.
      }
    })().catch((error) => {
      schemaPromise = null;
      throw error;
    });
  }

  await schemaPromise;
}

export async function loadStoredMachineSettings(): Promise<StoredMachineSettings | null> {
  if (!isSupportedPlatform()) {
    return null;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return null;
    }

    const row = await db.getFirstAsync<MachineSettingsRow>(
      `SELECT utiliza_maquininha, tipo_integracao, modelo_maquininha, ultima_transacao_getnet_json FROM ${TABLE_NAME} WHERE id = 1`
    );

    if (!row) {
      return null;
    }

    const tipoIntegracao = normalizeIntegration(row.tipo_integracao);
    const utilizaMaquininhaStone = Number(row.utiliza_maquininha || 0) === 1 || tipoIntegracao !== 'nenhum';

    return {
      utilizaMaquininhaStone,
      tipoIntegracao,
      modeloMaquininha: String(row.modelo_maquininha || (utilizaMaquininhaStone ? tipoIntegracao : 'false'))
    };
  } catch {
    return null;
  }
}

export async function loadStoredGetNetTransaction(): Promise<StoredGetNetTransaction | null> {
  if (!isSupportedPlatform()) {
    return null;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return null;
    }

    const row = await db.getFirstAsync<MachineSettingsRow>(
      `SELECT ultima_transacao_getnet_json FROM ${TABLE_NAME} WHERE id = 1`
    );

    const raw = String(row?.ultima_transacao_getnet_json || '').trim();
    if (!raw) {
      return null;
    }

    const parsed = JSON.parse(raw) as StoredGetNetTransaction;
    if (!parsed || typeof parsed !== 'object' || String(parsed.callerId || '').trim().length === 0) {
      return null;
    }

    return parsed;
  } catch {
    return null;
  }
}

export async function loadStoredGetNetSubsellers(): Promise<StoredGetNetSubsellers | null> {
  if (!isSupportedPlatform()) {
    return null;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return null;
    }

    const row = await db.getFirstAsync<MachineSettingsRow>(
      `SELECT subsellers_getnet_json FROM ${TABLE_NAME} WHERE id = 1`
    );

    const raw = String(row?.subsellers_getnet_json || '').trim();
    if (!raw) {
      return null;
    }

    const parsed = JSON.parse(raw) as StoredGetNetSubsellers;
    if (!parsed || typeof parsed !== 'object' || String(parsed.marketPlaceId || '').trim().length === 0) {
      return null;
    }

    return parsed;
  } catch {
    return null;
  }
}

export async function saveStoredMachineSettings(settings: StoredMachineSettings): Promise<void> {
  if (!isSupportedPlatform()) {
    return;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return;
    }

    await db.runAsync(
      `
        INSERT INTO ${TABLE_NAME} (
          id,
          utiliza_maquininha,
          tipo_integracao,
          modelo_maquininha,
          atualizado_em
        ) VALUES (1, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          utiliza_maquininha = excluded.utiliza_maquininha,
          tipo_integracao = excluded.tipo_integracao,
          modelo_maquininha = excluded.modelo_maquininha,
          atualizado_em = excluded.atualizado_em
      `,
      settings.utilizaMaquininhaStone ? 1 : 0,
      normalizeIntegration(settings.tipoIntegracao),
      String(settings.modeloMaquininha || 'false'),
      new Date().toISOString()
    );
  } catch {
    // Mantém a experiência do app mesmo se o espelho SQLite falhar.
  }
}

export async function saveStoredGetNetTransaction(transaction: StoredGetNetTransaction | null): Promise<void> {
  if (!isSupportedPlatform()) {
    return;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return;
    }

    const current = (await loadStoredMachineSettings()) || {
      utilizaMaquininhaStone: false,
      tipoIntegracao: 'nenhum' as StoredMachineIntegration,
      modeloMaquininha: 'false'
    };

    await db.runAsync(
      `
        INSERT INTO ${TABLE_NAME} (
          id,
          utiliza_maquininha,
          tipo_integracao,
          modelo_maquininha,
          ultima_transacao_getnet_json,
          atualizado_em
        ) VALUES (1, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          utiliza_maquininha = excluded.utiliza_maquininha,
          tipo_integracao = excluded.tipo_integracao,
          modelo_maquininha = excluded.modelo_maquininha,
          ultima_transacao_getnet_json = excluded.ultima_transacao_getnet_json,
          atualizado_em = excluded.atualizado_em
      `,
      current.utilizaMaquininhaStone ? 1 : 0,
      normalizeIntegration(current.tipoIntegracao),
      String(current.modeloMaquininha || 'false'),
      transaction ? JSON.stringify(transaction) : null,
      new Date().toISOString()
    );
  } catch {
    // Mantém a experiência do app mesmo se o espelho SQLite falhar.
  }
}

export async function saveStoredGetNetSubsellers(payload: StoredGetNetSubsellers | null): Promise<void> {
  if (!isSupportedPlatform()) {
    return;
  }

  try {
    await ensureSchemaAsync();
    const db = await getDatabaseAsync();
    if (!db) {
      return;
    }

    const current = (await loadStoredMachineSettings()) || {
      utilizaMaquininhaStone: false,
      tipoIntegracao: 'nenhum' as StoredMachineIntegration,
      modeloMaquininha: 'false'
    };

    const currentTx = await loadStoredGetNetTransaction();

    await db.runAsync(
      `
        INSERT INTO ${TABLE_NAME} (
          id,
          utiliza_maquininha,
          tipo_integracao,
          modelo_maquininha,
          ultima_transacao_getnet_json,
          subsellers_getnet_json,
          atualizado_em
        ) VALUES (1, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          utiliza_maquininha = excluded.utiliza_maquininha,
          tipo_integracao = excluded.tipo_integracao,
          modelo_maquininha = excluded.modelo_maquininha,
          ultima_transacao_getnet_json = excluded.ultima_transacao_getnet_json,
          subsellers_getnet_json = excluded.subsellers_getnet_json,
          atualizado_em = excluded.atualizado_em
      `,
      current.utilizaMaquininhaStone ? 1 : 0,
      normalizeIntegration(current.tipoIntegracao),
      String(current.modeloMaquininha || 'false'),
      currentTx ? JSON.stringify(currentTx) : null,
      payload ? JSON.stringify(payload) : null,
      new Date().toISOString()
    );
  } catch {
    // Mantém a experiência do app mesmo se o espelho SQLite falhar.
  }
}
