import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Colors, Radius, Shadows, Space } from '../theme';
import { getTableOrderDisplayNumber, isTableStatusReserved, normalizeSaleStatus, TableOrder } from '../services/api';
import { SafeMaterialCommunityIcons } from './SafeExpoIcons';

type DisplayMode = 'mesa' | 'comanda' | 'mesaComanda';
type PaletteMode = 'ocupadas' | 'livres' | 'todas' | 'reservadas';

type CardStatus = {
  label: string;
};

type CardPalette = {
  border: string;
  soft: string;
  accent: string;
  title: string;
  highlight: string;
};

const normalizeStatus = (value: string): string => normalizeSaleStatus(value).toLowerCase();
const normalizeNameLabel = (value: string): string =>
  value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();

const resolveStatus = (table: TableOrder): CardStatus => {
  const normalized = normalizeStatus(table.venda?.situacao || table.situacao || '');
  const hasOpenSale = Boolean(table.idVenda && table.idVenda > 0);
  if (normalized.includes('prefechamento') || normalized.includes('pre-fechamento')) {
    return { label: 'Pré-fechamento' };
  }

  if (hasOpenSale) {
    return { label: 'Ocupada' };
  }

  if (
    !normalized ||
    normalized.includes('digitacao') ||
    normalized.includes('livre') ||
    normalized.includes('dispon') ||
    normalized.includes('aberta')
  ) {
    return { label: 'Livre' };
  }

  if (
    isTableStatusReserved(normalized) ||
    normalized.includes('aguard') ||
    normalized.includes('smreservada')
  ) {
    return { label: 'Reservada' };
  }

  if (
    normalized.includes('pendente') ||
    normalized.includes('prefechamento') ||
    normalized.includes('pre-fechamento')
  ) {
    return { label: 'Ocupada' };
  }

  return { label: 'Ocupada' };
};

const resolvePalette = (table: TableOrder, paletteMode?: PaletteMode): CardPalette => {
  const normalized = normalizeStatus(table.venda?.situacao || table.situacao || '');
  const hasOpenSale = Boolean(table.idVenda && table.idVenda > 0);
  const key: PaletteMode =
    paletteMode ||
    (isTableStatusReserved(normalized)
      ? 'reservadas'
      : (!normalized ||
          normalized.includes('digitacao') ||
          normalized.includes('livre') ||
          normalized.includes('dispon') ||
          normalized.includes('aberta'))
        ? 'livres'
        : hasOpenSale || normalized.includes('pendente') || normalized.includes('prefechamento') || normalized.includes('pre-fechamento')
          ? 'ocupadas'
          : 'ocupadas');

  switch (key) {
    case 'livres':
      return {
        border: '#C7E6D0',
        soft: '#F3FBF5',
        accent: '#4B9B69',
        title: '#2F4F3D',
        highlight: '#FFFFFF'
      };
    case 'reservadas':
      return {
        border: '#F1D1DB',
        soft: '#FFF6F8',
        accent: '#C06A86',
        title: '#5A3E48',
        highlight: '#FFFFFF'
      };
    case 'todas':
      return {
        border: '#F3D8B8',
        soft: '#FFF9F2',
        accent: '#C88738',
        title: '#594A36',
        highlight: '#FFFFFF'
      };
    default:
      return {
        border: '#D8DDF5',
        soft: '#F5F7FF',
        accent: '#6D78C7',
        title: '#39435D',
        highlight: '#FFFFFF'
      };
  }
};

type TableCardProps = {
  table: TableOrder;
  displayMode?: DisplayMode;
  paletteMode?: PaletteMode;
  onPress?: () => void;
  onLongPress?: () => void;
};

const TableCardComponent: React.FC<TableCardProps> = ({
  table,
  displayMode = 'mesa',
  paletteMode,
  onPress,
  onLongPress
}) => {
  const status = resolveStatus(table);
  const palette = resolvePalette(table, paletteMode);
  const isComanda = displayMode === 'comanda' || table.tipo === 'comanda';
  const numero = getTableOrderDisplayNumber(table) || '';
  const title = `${isComanda ? 'COMANDA' : 'MESA'} ${numero}`.trim();
  const rawDisplayName = String(table.venda?.nomeMesaComanda || table.nomeMesaComanda || '').trim();
  const displayPrefix = `${isComanda ? 'Comanda' : 'Mesa'} ${numero}`.trim();
  const secondaryName = React.useMemo(() => {
    if (!rawDisplayName) {
      return '';
    }

    const normalizedRaw = normalizeNameLabel(rawDisplayName);
    const normalizedPrefix = normalizeNameLabel(displayPrefix);
    if (!normalizedRaw || normalizedRaw === normalizedPrefix) {
      return '';
    }

    const prefixPattern = numero
      ? new RegExp(`^${isComanda ? 'comanda' : 'mesa'}\\s*0*${numero}\\s*[-:|]?\\s*`, 'i')
      : null;
    const trimmed = prefixPattern ? rawDisplayName.replace(prefixPattern, '').trim() : rawDisplayName;
    if (!trimmed || normalizeNameLabel(trimmed) === normalizedPrefix) {
      return '';
    }

    return trimmed;
  }, [displayPrefix, isComanda, numero, rawDisplayName]);
  const iconName = isComanda ? ('receipt' as const) : ('table-furniture' as const);
  const valorPagamentoAntecipado = Number(table.venda?.valorPagamentoAntecipado || 0);
  const valorBruto = Number(table.valorTotal || table.venda?.valorTotal || 0);
  const valorPendente = Math.max(0, valorBruto - valorPagamentoAntecipado);

  return (
    <Pressable
      style={[styles.card, { borderColor: palette.border, backgroundColor: palette.soft }]}
      onPress={onPress}
      onLongPress={onLongPress}
    >
      <View style={[styles.topAccent, { backgroundColor: palette.accent }]} />

      <View style={[styles.contentWrap, { backgroundColor: palette.highlight }]}>
        <View style={styles.topLine}>
          <View style={styles.headerTopRow}>
            <View style={[styles.iconWrap, { backgroundColor: '#FFFFFF', borderColor: palette.border }]}>
              <SafeMaterialCommunityIcons name={iconName} size={18} color={palette.accent} />
            </View>
            <Text numberOfLines={1} ellipsizeMode="tail" style={[styles.tableTitle, { color: palette.title }]}>
              {title}
            </Text>
          </View>
          <Text
            numberOfLines={1}
            ellipsizeMode="tail"
            style={[styles.tableSubtitle, !secondaryName ? styles.tableSubtitleHidden : null]}
          >
            {secondaryName || ' '}
          </Text>

          <View style={styles.statusRow}>
            <View style={[styles.statusBadge, { borderColor: palette.border, backgroundColor: palette.soft }]}>
              <Text numberOfLines={1} ellipsizeMode="clip" style={[styles.statusText, { color: palette.accent }]}>
                {status.label}
              </Text>
            </View>
          </View>
        </View>

        <View style={[styles.valueCard, { borderColor: palette.border, backgroundColor: '#FFFFFF' }]}>
          <Text style={styles.valueLabel}>Valor pendente</Text>
          <Text style={styles.valueAmount}>R$ {valorPendente.toFixed(2)}</Text>
        </View>
      </View>
    </Pressable>
  );
};

const areEqual = (prev: Readonly<TableCardProps>, next: Readonly<TableCardProps>) => {
  return (
    prev.displayMode === next.displayMode &&
    prev.paletteMode === next.paletteMode &&
    prev.table.idMesa === next.table.idMesa &&
    prev.table.idComanda === next.table.idComanda &&
    prev.table.nomeMesaComanda === next.table.nomeMesaComanda &&
    prev.table.situacao === next.table.situacao &&
    prev.table.statusCode === next.table.statusCode &&
    prev.table.statusOriginal === next.table.statusOriginal &&
    prev.table.valorTotal === next.table.valorTotal &&
    prev.table.idVenda === next.table.idVenda &&
    prev.table.venda?.situacao === next.table.venda?.situacao &&
    prev.table.venda?.valorTotal === next.table.venda?.valorTotal &&
    prev.table.venda?.valorPagamentoAntecipado === next.table.venda?.valorPagamentoAntecipado &&
    prev.table.venda?.nomeMesaComanda === next.table.venda?.nomeMesaComanda
  );
};

export const TableCard = React.memo(TableCardComponent, areEqual);

const styles = StyleSheet.create({
  card: {
    borderRadius: Radius.lg,
    borderWidth: 1,
    borderColor: '#E6DDD3',
    overflow: 'hidden',
    height: 154,
    marginBottom: Space.sm,
    ...Shadows.card
  },
  topAccent: {
    height: 3,
    width: '100%'
  },
  contentWrap: {
    padding: 12,
    gap: 8,
    flex: 1,
    justifyContent: 'space-between'
  },
  topLine: {
    width: '100%',
    gap: 6,
    minHeight: 82
  },
  headerTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    minHeight: 32
  },
  iconWrap: {
    width: 32,
    height: 32,
    borderRadius: Radius.sm,
    backgroundColor: '#E8E0D8',
    borderWidth: 1,
    borderColor: '#E6DDD3',
    alignItems: 'center',
    justifyContent: 'center'
  },
  statusBadge: {
    borderWidth: 1,
    borderRadius: Radius.sm,
    alignSelf: 'center',
    flexShrink: 0,
    minWidth: 108,
    maxWidth: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 10,
    paddingVertical: 3
  },
  statusText: {
    fontWeight: '800',
    fontSize: 10,
    textAlign: 'center'
  },
  tableTitle: {
    flex: 1,
    fontWeight: '900',
    fontSize: 16
  },
  tableSubtitle: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    marginTop: -2,
    minHeight: 16
  },
  tableSubtitleHidden: {
    opacity: 0
  },
  statusRow: {
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 24
  },
  valueCard: {
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: '#FFF0E5',
    backgroundColor: '#FFF0E5',
    paddingVertical: 7,
    paddingHorizontal: 8,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 44
  },
  valueLabel: {
    color: '#6B7280',
    fontSize: 8,
    fontWeight: '700',
    marginBottom: 1,
    textAlign: 'center',
    textTransform: 'uppercase',
    letterSpacing: 0
  },
  valueAmount: {
    color: Colors.primary,
    fontWeight: '800',
    fontSize: 15,
    lineHeight: 18,
    textAlign: 'center'
  }
});
