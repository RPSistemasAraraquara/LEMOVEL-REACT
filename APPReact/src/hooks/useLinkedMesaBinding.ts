import { useCallback, useEffect, useRef, useState } from 'react';
import { api, isTableStatusReserved, normalizeSaleStatus, Sale, TableOrder } from '../services/api';

type UseLinkedMesaBindingParams = {
  enabled: boolean;
  saleTable?: TableOrder | null;
  preferredLinkedMesaId?: number;
};

const buildFallbackMesa = (mesaId: number): TableOrder => ({
  idMesa: mesaId,
  nomeMesaComanda: `Mesa ${mesaId}`,
  situacao: 'Pendente',
  tipo: 'mesa'
});

const normalizeMesa = (table: TableOrder): TableOrder => ({
  ...table,
  tipo: 'mesa',
  nomeMesaComanda: String(table.nomeMesaComanda || '').trim() || `Mesa ${Number(table.idMesa || 0)}`
});

const getMesaStatus = (table: TableOrder) =>
  normalizeSaleStatus(table.venda?.situacao || table.situacao || table.statusOriginal || table.statusCode || '').toLowerCase();

const hasOpenSale = (table: TableOrder) =>
  Boolean(Number(table.idVenda || table.venda?.idVenda || 0) > 0);

const isAllowedLinkedMesa = (table: TableOrder) => {
  const normalized = getMesaStatus(table);
  if ((table.tipo || 'mesa') === 'comanda') {
    return false;
  }

  if (isTableStatusReserved(normalized)) {
    return false;
  }

  if (hasOpenSale(table)) {
    return true;
  }

  if (
    !normalized ||
    normalized.includes('livre') ||
    normalized.includes('dispon') ||
    normalized.includes('digitacao')
  ) {
    return true;
  }

  if (
    normalized.includes('pendente') ||
    normalized.includes('prefechamento') ||
    normalized.includes('pre-fechamento') ||
    normalized.includes('ocup') ||
    normalized.includes('aberta')
  ) {
    return true;
  }

  return false;
};

const dedupeMesas = (tables: TableOrder[], onlyAllowed = true) => {
  const seen = new Set<number>();
  return tables
    .filter((table) => Number(table.idMesa || 0) > 0)
    .map(normalizeMesa)
    .filter((table) => (onlyAllowed ? isAllowedLinkedMesa(table) : true))
    .filter((table) => {
      const mesaId = Number(table.idMesa || 0);
      if (seen.has(mesaId)) {
        return false;
      }
      seen.add(mesaId);
      return true;
    })
    .sort((left, right) => Number(left.idMesa || 0) - Number(right.idMesa || 0));
};

const getLinkedMesaIdFromSale = (sale: Sale | null) => {
  const items = Array.isArray(sale?.itens) ? sale.itens : [];
  for (let index = items.length - 1; index >= 0; index -= 1) {
    const mesaId = Number(items[index]?.idMesaVinculada || 0);
    if (mesaId > 0) {
      return mesaId;
    }
  }
  return 0;
};

export const useLinkedMesaBinding = ({
  enabled,
  saleTable,
  preferredLinkedMesaId = 0
}: UseLinkedMesaBindingParams) => {
  const [linkedMesa, setLinkedMesa] = useState<TableOrder | null>(null);
  const [bindingResolved, setBindingResolved] = useState(false);
  const [pickerVisible, setPickerVisible] = useState(false);
  const [pickerLoading, setPickerLoading] = useState(false);
  const [pickerTables, setPickerTables] = useState<TableOrder[]>([]);
  const pickerTablesRef = useRef<TableOrder[]>([]);

  const syncPickerTables = useCallback((tables: TableOrder[]) => {
    const next = dedupeMesas(tables);
    pickerTablesRef.current = next;
    setPickerTables(next);
    return next;
  }, []);

  const fetchPickerTables = useCallback(
    async (showLoading = true) => {
      if (showLoading) {
        setPickerLoading(true);
      }

      try {
        const mesas = await api.listTables();
        return syncPickerTables(mesas);
      } finally {
        if (showLoading) {
          setPickerLoading(false);
        }
      }
    },
    [syncPickerTables]
  );

  const resolveMesaById = useCallback(
    async (mesaId: number, availableTables?: TableOrder[]) => {
      if (!mesaId) {
        return null;
      }

      const source = availableTables?.length ? availableTables : pickerTablesRef.current;
      const foundInSource = source.find((table) => Number(table.idMesa || 0) === Number(mesaId));
      if (foundInSource) {
        return normalizeMesa(foundInSource);
      }

      try {
        const loadedMesas = await api.listTables();
        const mergedTables = dedupeMesas([...pickerTablesRef.current, ...loadedMesas], false);
        syncPickerTables(loadedMesas);
        const found = mergedTables.find((table) => Number(table.idMesa || 0) === Number(mesaId));
        if (found) {
          return normalizeMesa(found);
        }
      } catch {
        // Mantem fallback local quando nao consegue resolver a mesa no servidor.
      }

      return buildFallbackMesa(mesaId);
    },
    [syncPickerTables]
  );

  useEffect(() => {
    let active = true;

    if (!enabled) {
      setLinkedMesa(null);
      setBindingResolved(true);
      return () => {
        active = false;
      };
    }

    setBindingResolved(false);

    const syncExistingMesa = async () => {
      const preferredId = Number(preferredLinkedMesaId || 0);
      if (preferredId > 0) {
        const availableTables = await fetchPickerTables(false).catch(() => pickerTablesRef.current);
        const resolvedMesa = await resolveMesaById(preferredId, availableTables);
        if (active) {
          setLinkedMesa(resolvedMesa);
          setBindingResolved(true);
        }
        return;
      }

      const saleId = Number(saleTable?.idVenda || 0);
      if (saleId > 0) {
        try {
          const sale = await api.getSale(saleId, true);
          const linkedMesaId = getLinkedMesaIdFromSale(sale);
          if (linkedMesaId > 0) {
            const availableTables = await fetchPickerTables(false).catch(() => pickerTablesRef.current);
            const resolvedMesa = await resolveMesaById(linkedMesaId, availableTables);
            if (active) {
              setLinkedMesa(resolvedMesa);
              setBindingResolved(true);
            }
            return;
          }
        } catch {
          // Se nao conseguir carregar a venda, o usuario ainda pode escolher manualmente a mesa.
        }
      }

      if (active) {
        setLinkedMesa(null);
        setBindingResolved(true);
      }
    };

    void syncExistingMesa();

    return () => {
      active = false;
    };
  }, [
    enabled,
    fetchPickerTables,
    preferredLinkedMesaId,
    resolveMesaById,
    saleTable?.idMesa,
    saleTable?.idVenda,
    saleTable?.tipo
  ]);

  const openPicker = useCallback(async () => {
    setPickerVisible(true);
    await fetchPickerTables(true).catch(() => []);
  }, [fetchPickerTables]);

  const closePicker = useCallback(() => {
    setPickerVisible(false);
  }, []);

  const selectMesa = useCallback((table: TableOrder) => {
    setLinkedMesa(normalizeMesa(table));
    setPickerVisible(false);
  }, []);

  const ensureLinkedMesaSelected = useCallback(async () => {
    if (!enabled) {
      return true;
    }

    if (linkedMesa?.idMesa) {
      return true;
    }

    await openPicker();
    return false;
  }, [enabled, linkedMesa?.idMesa, openPicker]);

  return {
    linkedMesa,
    bindingResolved,
    pickerVisible,
    pickerLoading,
    pickerTables,
    openPicker,
    closePicker,
    selectMesa,
    refreshPickerTables: fetchPickerTables,
    ensureLinkedMesaSelected
  };
};
