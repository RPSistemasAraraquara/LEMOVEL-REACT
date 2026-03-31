import React, { useEffect, useMemo, useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { RouteProp, useNavigation, useRoute } from '@react-navigation/native';
import { useApp } from '../context/AppContext';
import { api, normalizeSaleStatus } from '../services/api';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { Colors, Radius, Space } from '../theme';
import { RootStackParams } from '../navigation/AppNavigator';

type Route = RouteProp<RootStackParams, 'Transferencia' | 'JuntarMesa'>;

export const TransferMergeScreen: React.FC = () => {
  const route = useRoute<Route>();
  const navigation = useNavigation();
  const routeMesaOrigem = route.name === 'Transferencia' ? route.params.idMesaOrigem : 0;
  const routeVendaDestino = route.name === 'JuntarMesa' ? route.params.idVendaDestino : undefined;
  const { tables, refreshDashboard, activeTable, user } = useApp();
  const [filterText, setFilterText] = useState('');
  const [selectedTargetIds, setSelectedTargetIds] = useState<number[]>([]);
  const [selectedOriginSaleIds, setSelectedOriginSaleIds] = useState<number[]>([]);
  const [loading, setLoading] = useState(false);
  const [availableTransferTargets, setAvailableTransferTargets] = useState<(typeof tables)>([]);
  const [availableMergeTargets, setAvailableMergeTargets] = useState<(typeof tables)>([]);

  const isTransferMode = route.name === 'Transferencia';
  const sourceTableId = Number(
    routeMesaOrigem ||
      (activeTable?.tipo === 'comanda'
        ? activeTable?.idComanda || activeTable?.idMesa || 0
        : activeTable?.idMesa || 0)
  );
  const destinationSaleId = Number(activeTable?.idVenda || routeVendaDestino || 0);
  const currentTable =
    activeTable ||
    tables.find((table) => Number(table.idVenda || 0) === destinationSaleId) ||
    tables.find((table) => Number(table.idMesa || 0) === sourceTableId) ||
    null;
  const currentType = currentTable?.tipo;
  const getTransferId = (table: (typeof tables)[number]) =>
    Number(table.tipo === 'comanda' ? table.idComanda || table.idMesa || 0 : table.idMesa || 0);

  const resolveStatus = (table: (typeof tables)[number] | null | undefined) =>
    normalizeSaleStatus(table?.venda?.situacao || table?.situacao || table?.statusCode || table?.statusOriginal || '');

  const formatStatusLabel = (table: (typeof tables)[number]) => {
    if (isTransferMode) {
      return 'Disponível';
    }
    const status = resolveStatus(table);
    if (
      !table.idVenda ||
      status.includes('digitacao') ||
      status.includes('livre') ||
      status.includes('aberta') ||
      status.includes('dispon')
    ) {
      return 'Disponível';
    }
    if (status.includes('prefechamento') || status.includes('pre-fechamento')) {
      return 'Pré-fechamento';
    }
    if (status.includes('pendente')) {
      return 'Pendente';
    }
    if (status.includes('reserv')) {
      return 'Reservada';
    }
    if (status.includes('aguard')) {
      return 'Aguardando';
    }
    return 'Ocupada';
  };

  const isPendingSale = (table: (typeof tables)[number] | null | undefined) => resolveStatus(table).includes('pendente');

  useEffect(() => {
    let mounted = true;

    const loadTransferTargets = async () => {
      if (!isTransferMode) {
        if (mounted) setAvailableTransferTargets([]);
        return;
      }

      try {
        const list =
          currentType === 'comanda'
            ? await api.listComandasBySaleStatus('svDigitacao')
            : await api.listTablesBySaleStatus('svDigitacao');

        if (!mounted) return;

        setAvailableTransferTargets(
          list.filter((table) => getTransferId(table) !== sourceTableId)
        );
      } catch {
        if (!mounted) return;
        setAvailableTransferTargets([]);
      }
    };

    void loadTransferTargets();

    return () => {
      mounted = false;
    };
  }, [currentType, isTransferMode, sourceTableId]);

  useEffect(() => {
    let mounted = true;

    const loadMergeTargets = async () => {
      if (isTransferMode) {
        if (mounted) setAvailableMergeTargets([]);
        return;
      }

      try {
        const list =
          currentType === 'comanda'
            ? await api.listComandasBySaleStatus('svPendente')
            : await api.listTablesBySaleStatus('svPendente');

        if (!mounted) return;

        setAvailableMergeTargets(
          list.filter((table) => {
            if (currentType && table.tipo && table.tipo !== currentType) return false;
            if (!isPendingSale(table)) return false;
            return Number(table.idVenda || 0) > 0 && Number(table.idVenda || 0) !== destinationSaleId;
          })
        );
      } catch {
        if (!mounted) return;
        setAvailableMergeTargets([]);
      }
    };

    void loadMergeTargets();

    return () => {
      mounted = false;
    };
  }, [currentType, destinationSaleId, isTransferMode]);

  const filteredTransferTargets = useMemo(() => {
    const search = filterText.trim().toLowerCase();
    return availableTransferTargets.filter((table) => {
      if (!search) return true;
      return (
        String(getTransferId(table)).includes(search) ||
        String(table.nomeMesaComanda || '').toLowerCase().includes(search)
      );
    });
  }, [availableTransferTargets, filterText]);

  const filteredMergeTargets = useMemo(() => {
    const search = filterText.trim().toLowerCase();
    return availableMergeTargets.filter((table) => {
      if (!search) return true;
      return (
        String(table.idVenda || 0).includes(search) ||
        String(table.idMesa || 0).includes(search) ||
        String(table.nomeMesaComanda || '').toLowerCase().includes(search)
      );
    });
  }, [availableMergeTargets, filterText]);

  const toggleTransferTarget = (idDestino: number) => {
    if (!idDestino || idDestino === sourceTableId) {
      Alert.alert('Atenção', 'Não é possível transferir para a mesma mesa de origem.');
      return;
    }

    setSelectedTargetIds((prev) =>
      prev.includes(idDestino) ? [] : [idDestino]
    );
  };

  const toggleMergeTarget = (idVenda: number) => {
    if (!idVenda || idVenda === destinationSaleId) {
      Alert.alert('Atenção', 'Não é possível juntar a venda com ela mesma.');
      return;
    }

    setSelectedOriginSaleIds((prev) =>
      prev.includes(idVenda) ? prev.filter((item) => item !== idVenda) : [...prev, idVenda]
    );
  };

  const executeTransfer = async () => {
    if (!user?.permiteJuntarMesaComanda) {
      Alert.alert('Atenção', 'Sem permissão para transferir mesa/comanda.');
      return;
    }
    if (!currentTable?.idVenda) {
      Alert.alert('Fluxo inválido', 'Selecione uma mesa com venda ativa antes de transferir.');
      return;
    }
    if (!sourceTableId) {
      Alert.alert('Atenção', 'Mesa origem inválida.');
      return;
    }
    if (!isPendingSale(currentTable)) {
      Alert.alert('Atenção', 'Somente vendas pendentes podem ser transferidas.');
      return;
    }
    if (selectedTargetIds.length !== 1) {
      Alert.alert('Atenção', 'Selecione uma única mesa/comanda aberta para transferir.');
      return;
    }

    Alert.alert(
      'Confirmar Transferência',
      `Deseja transferir os itens da mesa ${sourceTableId} para a mesa/comanda selecionada?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Transferir',
          onPress: async () => {
            setLoading(true);
            try {
              for (const idMesaDestino of selectedTargetIds) {
                await api.transferTable(
                  sourceTableId,
                  idMesaDestino,
                  currentType === 'comanda' ? 'comanda' : 'mesa',
                  Number(user?.idUsuario || 0)
                );
              }
              await refreshDashboard(undefined, { force: true });
              Alert.alert('Concluído', 'Transferido com sucesso.', [
                { text: 'OK', onPress: () => navigation.navigate('Inicial' as never) }
              ]);
            } catch (error: any) {
              Alert.alert('Erro', error?.message || 'Não foi possível transferir.');
            } finally {
              setLoading(false);
            }
          }
        }
      ]
    );
  };

  const executeMerge = async () => {
    if (!user?.permiteJuntarMesaComanda) {
      Alert.alert('Atenção', 'Sem permissão para juntar mesas.');
      return;
    }
    if (!destinationSaleId) {
      Alert.alert('Atenção', 'Venda destino inválida.');
      return;
    }
    if (!currentTable?.idVenda || !isPendingSale(currentTable)) {
      Alert.alert('Atenção', 'Somente vendas pendentes podem ser juntadas.');
      return;
    }
    if (selectedOriginSaleIds.length === 0) {
      Alert.alert('Atenção', 'Selecione ao menos uma mesa/comanda para juntar.');
      return;
    }

    Alert.alert(
      'Confirmar Junção',
      `Deseja juntar ${selectedOriginSaleIds.length} mesa(s)/comanda(s) selecionada(s)?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Juntar',
          onPress: async () => {
            setLoading(true);
            try {
              await api.joinSales(destinationSaleId, selectedOriginSaleIds);
              await refreshDashboard(undefined, { force: true });
              Alert.alert('Concluído', 'Mesas juntadas com sucesso.', [
                { text: 'OK', onPress: () => navigation.goBack() }
              ]);
            } catch (error: any) {
              Alert.alert('Erro', error?.message || 'Não foi possível juntar as vendas.');
            } finally {
              setLoading(false);
            }
          }
        }
      ]
    );
  };

  const candidates = isTransferMode ? filteredTransferTargets : filteredMergeTargets;
  const selectedCount = isTransferMode ? selectedTargetIds.length : selectedOriginSaleIds.length;
  const sourceTitle = currentTable?.nomeMesaComanda || (isTransferMode ? `Mesa ${sourceTableId}` : `Venda ${destinationSaleId}`);
  const sourceSubtitle = isTransferMode
    ? 'Origem selecionada'
    : `Venda ${destinationSaleId}`;

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 120 }}>
      <ScreenRouteLabel />
      <SectionHeader
        title={isTransferMode ? 'Transferir mesa/comanda' : 'Juntar mesas/comandas'}
        subtitle={isTransferMode ? 'Selecione os destinos para transferir.' : 'Selecione as origens para juntar na venda atual.'}
      />

      <View style={styles.sourceCard}>
        <Text style={styles.sourceLabel}>{isTransferMode ? 'Origem' : 'Destino'}</Text>
        <Text style={styles.sourceTitle}>{sourceTitle}</Text>
        <Text style={styles.sourceSub}>{sourceSubtitle}</Text>
      </View>

      <View style={styles.filterCard}>
        <Text style={styles.filterLabel}>Filtrar</Text>
        <TextInput
          style={styles.input}
          value={filterText}
          onChangeText={setFilterText}
          placeholder={isTransferMode ? 'Digite a mesa/comanda' : 'Digite a venda ou mesa'}
          placeholderTextColor={Colors.textMuted}
        />
      </View>

      <View style={styles.selectionBar}>
        <Text style={styles.selectionText}>
          {selectedCount === 0 ? 'Nenhuma selecionada' : `${selectedCount} selecionada(s)`}
        </Text>
      </View>

      <View style={styles.grid}>
        {candidates.map((table) => {
          const saleId = Number(table.idVenda || 0);
          const transferId = getTransferId(table);
          const tableKey = `${table.tipo || 'mesa'}-${table.idComanda || 0}-${table.idMesa}-${saleId || 0}`;
          const isSelected = isTransferMode
            ? selectedTargetIds.includes(transferId)
            : selectedOriginSaleIds.includes(saleId);

          return (
            <Pressable
              key={tableKey}
              style={[styles.optionCard, isSelected ? styles.optionCardSelected : null]}
              onPress={() =>
                isTransferMode
                  ? toggleTransferTarget(transferId)
                  : toggleMergeTarget(saleId)
              }
            >
              <Text style={styles.optionTitle}>{table.nomeMesaComanda || `Mesa ${table.idMesa}`}</Text>
              {!isTransferMode ? (
                <Text style={styles.optionSub}>{`Venda ${saleId}`}</Text>
              ) : null}
              <Text style={styles.optionSub}>Status: {formatStatusLabel(table)}</Text>
            </Pressable>
          );
        })}
      </View>

      {candidates.length === 0 ? (
        <View style={styles.emptyCard}>
          <Text style={styles.emptyTitle}>Nenhum registro disponível</Text>
          <Text style={styles.emptyText}>
            {isTransferMode
              ? 'Não há mesas/comandas abertas disponíveis para receber transferência.'
              : 'Não há mesas/comandas pendentes disponíveis para junção.'}
          </Text>
        </View>
      ) : null}

      <Pressable
        style={[styles.primaryBtn, selectedCount === 0 ? styles.primaryBtnDisabled : null]}
        onPress={isTransferMode ? executeTransfer : executeMerge}
        disabled={loading || selectedCount === 0}
      >
        <Text style={styles.primaryText}>
          {loading
            ? 'Processando...'
            : isTransferMode
              ? 'Transferir selecionadas'
              : 'Juntar selecionadas'}
        </Text>
      </Pressable>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
    padding: Space.md
  },
  sourceCard: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    padding: Space.md,
    marginBottom: Space.md
  },
  sourceLabel: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 6
  },
  sourceTitle: {
    color: Colors.text,
    fontWeight: '800',
    fontSize: 18
  },
  sourceSub: {
    color: Colors.textMuted,
    marginTop: 4
  },
  filterCard: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    padding: Space.md,
    marginBottom: Space.md
  },
  filterLabel: {
    color: Colors.textMuted,
    marginBottom: 6,
    fontWeight: '700',
    fontSize: 12
  },
  input: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    padding: 10,
    color: Colors.text,
    backgroundColor: Colors.cardSoft
  },
  selectionBar: {
    marginBottom: 8
  },
  selectionText: {
    color: Colors.primary,
    fontWeight: '700'
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8
  },
  optionCard: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    padding: 10,
    backgroundColor: Colors.card,
    minWidth: '47%',
    flexGrow: 1,
    flexBasis: '47%'
  },
  optionCardSelected: {
    borderColor: '#FC8019',
    borderWidth: 2
  },
  optionTitle: {
    color: Colors.text,
    fontWeight: '800'
  },
  optionSub: {
    color: Colors.textMuted,
    fontSize: 12,
    marginTop: 4
  },
  emptyCard: {
    marginTop: Space.md,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    padding: Space.md
  },
  emptyTitle: {
    color: Colors.text,
    fontWeight: '800',
    marginBottom: 4
  },
  emptyText: {
    color: Colors.textMuted
  },
  primaryBtn: {
    marginTop: 14,
    backgroundColor: Colors.primary,
    borderRadius: Radius.md,
    padding: 14,
    alignItems: 'center'
  },
  primaryBtnDisabled: {
    opacity: 0.5
  },
  primaryText: {
    color: '#fff',
    fontWeight: '800'
  }
});
