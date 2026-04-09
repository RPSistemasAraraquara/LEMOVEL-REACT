import React, { useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View
} from 'react-native';
import { formatTableStatusLabel, normalizeSaleStatus, TableOrder } from '../services/api';
import { Colors, Radius, Shadows, Space } from '../theme';

type LinkedMesaPickerModalProps = {
  visible: boolean;
  tables: TableOrder[];
  loading?: boolean;
  selectedTableId?: number;
  title?: string;
  description?: string;
  onClose: () => void;
  onRefresh?: () => void;
  onSelect: (table: TableOrder) => void;
};

const getTableLabel = (table: TableOrder) => {
  const customName = String(table.nomeMesaComanda || '').trim();
  if (customName) {
    return customName;
  }
  return `Mesa ${Number(table.idMesa || 0)}`;
};

type MesaVisualState = 'free' | 'open';

const getTableVisualState = (table: TableOrder): MesaVisualState => {
  const normalized = normalizeSaleStatus(
    table.venda?.situacao || table.situacao || table.statusOriginal || table.statusCode || ''
  ).toLowerCase();
  const hasOpenSale = Boolean(Number(table.idVenda || table.venda?.idVenda || 0) > 0);

  if (
    hasOpenSale ||
    normalized.includes('pendente') ||
    normalized.includes('prefechamento') ||
    normalized.includes('pre-fechamento') ||
    normalized.includes('ocup') ||
    normalized.includes('aberta')
  ) {
    return 'open';
  }

  return 'free';
};

const getTableVisualPalette = (state: MesaVisualState) => {
  if (state === 'open') {
    return {
      border: '#D8DDF5',
      soft: '#F5F7FF',
      text: '#4E5FB0',
      badgeSoft: '#E8EDFF'
    };
  }

  return {
    border: '#C7E6D0',
    soft: '#F3FBF5',
    text: '#3C8A5C',
    badgeSoft: '#E5F6EA'
  };
};

export const LinkedMesaPickerModal: React.FC<LinkedMesaPickerModalProps> = ({
  visible,
  tables,
  loading = false,
  selectedTableId = 0,
  title = 'Selecionar mesa vinculada',
  description = 'Escolha a mesa que deve receber o vínculo dos itens lançados nesta comanda.',
  onClose,
  onRefresh,
  onSelect
}) => {
  const [search, setSearch] = useState('');

  useEffect(() => {
    if (!visible) {
      setSearch('');
    }
  }, [visible]);

  const filteredTables = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) {
      return tables;
    }

    return tables.filter((table) => {
      const id = String(table.idMesa || '').trim().toLowerCase();
      const name = getTableLabel(table).toLowerCase();
      const rawStatus = table.venda?.situacao || table.situacao || '';
      const status = String(rawStatus).trim().toLowerCase();
      const displayStatus = formatTableStatusLabel(rawStatus).toLowerCase();
      return id.includes(query) || name.includes(query) || status.includes(query) || displayStatus.includes(query);
    });
  }, [search, tables]);

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      statusBarTranslucent
      onRequestClose={loading ? undefined : onClose}
    >
      <View style={styles.overlay}>
        <Pressable style={styles.backdrop} onPress={loading ? undefined : onClose} />
        <View style={styles.panel}>
          <View style={styles.header}>
            <View style={styles.copyWrap}>
              <Text style={styles.title}>{title}</Text>
              <Text style={styles.description}>{description}</Text>
            </View>
            {onRefresh ? (
              <Pressable style={styles.refreshButton} onPress={onRefresh} disabled={loading}>
                <Text style={styles.refreshButtonText}>Atualizar</Text>
              </Pressable>
            ) : null}
          </View>

          <TextInput
            value={search}
            onChangeText={setSearch}
            placeholder="Filtrar mesa..."
            placeholderTextColor={Colors.textMuted}
            style={styles.input}
            editable={!loading}
          />

          <View style={styles.listCard}>
            {loading ? (
              <View style={styles.stateWrap}>
                <ActivityIndicator color={Colors.primary} />
                <Text style={styles.stateText}>Carregando mesas...</Text>
              </View>
            ) : filteredTables.length > 0 ? (
              <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={styles.listContent}>
                {filteredTables.map((table) => {
                  const isSelected = Number(table.idMesa || 0) === Number(selectedTableId || 0);
                  const visualState = getTableVisualState(table);
                  const palette = getTableVisualPalette(visualState);
                  const status = formatTableStatusLabel(table.venda?.situacao || table.situacao);
                  const displayStatus = status || (visualState === 'open' ? 'Em aberto' : 'Disponível');

                  return (
                    <Pressable
                      key={`linked-mesa-${table.idMesa}`}
                      style={[
                        styles.item,
                        {
                          borderColor: palette.border,
                          backgroundColor: palette.soft
                        },
                        isSelected && styles.itemSelected
                      ]}
                      onPress={() => onSelect(table)}
                    >
                      <View style={styles.itemCopy}>
                        <Text style={styles.itemTitle}>{getTableLabel(table)}</Text>
                        <Text style={styles.itemMeta}>
                          Mesa {Number(table.idMesa || 0)}
                          {displayStatus ? ` | ${displayStatus}` : ''}
                        </Text>
                      </View>
                      <View style={styles.itemActions}>
                        <View
                          style={[
                            styles.itemStatusBadge,
                            { borderColor: palette.border, backgroundColor: palette.badgeSoft }
                          ]}
                        >
                          <Text style={[styles.itemStatusBadgeText, { color: palette.text }]}>
                            {visualState === 'open' ? 'Em aberto' : 'Livre'}
                          </Text>
                        </View>
                        <Text
                          style={[
                            styles.itemAction,
                            { color: isSelected ? Colors.text : palette.text },
                            isSelected && styles.itemActionSelected
                          ]}
                        >
                          {isSelected ? 'Selecionada' : 'Usar'}
                        </Text>
                      </View>
                    </Pressable>
                  );
                })}
              </ScrollView>
            ) : (
              <View style={styles.stateWrap}>
                <Text style={styles.stateText}>Nenhuma mesa livre ou em aberto para vincular.</Text>
              </View>
            )}
          </View>

          <View style={styles.actions}>
            <Pressable style={styles.secondaryButton} onPress={onClose} disabled={loading}>
              <Text style={styles.secondaryButtonText}>Fechar</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Space.lg,
    backgroundColor: 'rgba(15, 23, 42, 0.34)'
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject
  },
  panel: {
    width: '100%',
    maxWidth: 460,
    borderRadius: Radius.lg,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Space.lg,
    gap: Space.md,
    ...Shadows.card
  },
  header: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: Space.sm
  },
  copyWrap: {
    flex: 1,
    gap: 4
  },
  title: {
    color: Colors.text,
    fontSize: 18,
    fontWeight: '800'
  },
  description: {
    color: Colors.textMuted,
    lineHeight: 20
  },
  refreshButton: {
    borderRadius: 14,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    paddingHorizontal: 12,
    paddingVertical: 10
  },
  refreshButtonText: {
    color: Colors.text,
    fontWeight: '700'
  },
  input: {
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    borderRadius: 16,
    backgroundColor: Colors.cardSoft,
    color: Colors.text,
    paddingHorizontal: 14,
    paddingVertical: 12
  },
  listCard: {
    minHeight: 220,
    maxHeight: 360,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    overflow: 'hidden'
  },
  listContent: {
    padding: Space.sm,
    gap: Space.sm
  },
  stateWrap: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: Space.sm,
    padding: Space.lg
  },
  stateText: {
    color: Colors.textMuted,
    textAlign: 'center'
  },
  item: {
    borderRadius: 16,
    borderWidth: 1,
    paddingHorizontal: 14,
    paddingVertical: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: Space.sm
  },
  itemSelected: {
    borderWidth: 2
  },
  itemCopy: {
    flex: 1,
    gap: 4
  },
  itemTitle: {
    color: Colors.text,
    fontSize: 15,
    fontWeight: '800'
  },
  itemMeta: {
    color: Colors.textMuted,
    fontSize: 13
  },
  itemActions: {
    alignItems: 'flex-end',
    gap: 8
  },
  itemStatusBadge: {
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 10,
    paddingVertical: 5
  },
  itemStatusBadgeText: {
    fontSize: 11,
    fontWeight: '800'
  },
  itemAction: {
    color: Colors.primary,
    fontWeight: '800'
  },
  itemActionSelected: {
    color: Colors.text
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end'
  },
  secondaryButton: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 13,
    backgroundColor: Colors.cardSoft
  },
  secondaryButtonText: {
    color: Colors.text,
    fontWeight: '700'
  }
});
