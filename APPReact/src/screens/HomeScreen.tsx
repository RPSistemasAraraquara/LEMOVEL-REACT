import React, { useEffect } from 'react';
import {
  Alert,
  FlatList,
  Pressable,
  RefreshControl,
  StyleSheet,
  Text,
  View,
  useWindowDimensions
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { TableCard } from '../components/TableCard';
import { OpenTableNameModal } from '../components/OpenTableNameModal';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { useApp } from '../context/AppContext';
import { isTableStatusReserved, normalizeSaleStatus, TableOrder } from '../services/api';
import { Colors, Radius, Space, Typography } from '../theme';

type TabsNav = BottomTabNavigationProp<{
  Mesas: undefined;
  Cardapio: undefined;
  Gestao: undefined;
}>;

export const HomeScreen: React.FC = () => {
  const { tables, refreshDashboard, openTableByCard, setActiveTable, activeTable, hasOpenSale, appSettings } = useApp();
  const [refreshing, setRefreshing] = React.useState(false);
  const [openNameModalVisible, setOpenNameModalVisible] = React.useState(false);
  const [openNameText, setOpenNameText] = React.useState('');
  const [pendingOpenTable, setPendingOpenTable] = React.useState<{
    table: TableOrder;
    route: 'Gestao' | 'Cardapio';
  } | null>(null);
  const navigation = useNavigation<TabsNav>();
  const { width } = useWindowDimensions();
  const abertas = tables.filter((t) => t.situacao === 'Aberta').length;
  const total = tables.reduce((acc, t) => acc + (t.valorTotal || 0), 0);
  const tableColumns = React.useMemo(() => {
    const availableWidth = Math.max(0, width - Space.md * 2);
    const maxColumns = Math.max(1, Math.floor(availableWidth / 180));
    return Math.max(1, Math.min(8, maxColumns));
  }, [width]);

  const cardWidth = React.useMemo(() => {
    const availableWidth = Math.max(0, width - Space.md * 2);
    const spacing = Space.sm * (tableColumns - 1);
    return Math.max(120, Math.floor((availableWidth - spacing) / tableColumns));
  }, [width, tableColumns]);

  useEffect(() => {
    refreshDashboard();
  }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await refreshDashboard();
    setRefreshing(false);
  };

  const isQuickLaunch = (item: TableOrder): boolean => {
    const status = normalizeSaleStatus(item.situacao || item.venda?.situacao || item.statusOriginal || item.statusCode || '');

    if (isTableStatusReserved(status)) {
      return false;
    }

    return (
      status.includes('digitacao') ||
      status.includes('pendente') ||
      status.includes('prefechamento') ||
      status.includes('pre-fechamento') ||
      status.includes('aberta') ||
      status.includes('livre') ||
      status.includes('dispon')
    );
  };

  const openMesa = async (table: TableOrder, forceManager = false) => {
    const route: 'Gestao' | 'Cardapio' = forceManager || !isQuickLaunch(table) ? 'Gestao' : 'Cardapio';
    const tableHasOpenSale = Boolean(table.idVenda && Number(table.idVenda) > 0);

    if (tableHasOpenSale) {
      setActiveTable(table);
      navigation.navigate(route);
      return;
    }

    if (appSettings.exigeNomeAbertura) {
      setPendingOpenTable({ table, route });
      setOpenNameText('');
      setOpenNameModalVisible(true);
      return;
    }

    try {
      const opened = await openTableByCard(
        table.idMesa,
        undefined,
        table.tipo
      );
      setActiveTable(opened);
      navigation.navigate(route);
    } catch {
      Alert.alert('Erro', 'Não foi possível abrir a mesa. Tente novamente.');
    }
  };

  const confirmOpenWithName = async () => {
    const pending = pendingOpenTable;
    const nome = openNameText.trim();
    if (!pending) {
      return;
    }
    if (!nome) {
      Alert.alert('Atenção', 'Informe o nome para abrir a mesa/comanda.');
      return;
    }

    setOpenNameModalVisible(false);
    setPendingOpenTable(null);
    setOpenNameText('');

    try {
      const opened = await openTableByCard(pending.table.idMesa, nome, pending.table.tipo);
      setActiveTable(opened);
      navigation.navigate(pending.route);
    } catch {
      Alert.alert('Erro', 'Não foi possível abrir a mesa. Tente novamente.');
    }
  };

  return (
    <View style={styles.container}>
      <ScreenRouteLabel />
      <SectionHeader title="Mesas em andamento" subtitle="Acompanhe pedidos abertos" />
      {!!activeTable && (
        <View style={styles.active}>
          <Text style={styles.activeText}>
            Mesa ativa: {activeTable.nomeMesaComanda || `${activeTable.tipo === 'comanda' ? 'Comanda' : 'Mesa'} ${activeTable.idMesa}`}
          </Text>
          <Pressable
            style={styles.actionBtn}
            onPress={() => {
              if (!hasOpenSale) {
                Alert.alert('Fluxo inválido', 'Abra a venda na Mesa antes de entrar na gestão.');
                return;
              }
              navigation.navigate('Gestao');
            }}
          >
            <Text style={styles.actionBtnText}>Abrir gestão da comanda</Text>
          </Pressable>
        </View>
      )}
      {!!activeTable && !hasOpenSale && (
        <View style={styles.actionWarning}>
          <Text style={styles.actionWarningText}>Venda ainda sem abrir. Abra a mesa no cardápio para operar.</Text>
        </View>
      )}
      <View style={styles.hero}>
        <View style={styles.heroCard}>
          <Text style={styles.heroLabel}>Mesas</Text>
          <Text style={styles.heroValue}>{tables.length}</Text>
        </View>
        <View style={styles.heroCard}>
          <Text style={styles.heroLabel}>Abertas</Text>
          <Text style={styles.heroValue}>{abertas}</Text>
        </View>
        <View style={styles.heroCard}>
          <Text style={styles.heroLabel}>Faturamento</Text>
          <Text style={styles.heroValue}>R$ {total.toFixed(2)}</Text>
        </View>
      </View>
      {!activeTable ? (
        <View style={styles.instructionCard}>
          <Text style={styles.instructionTitle}>Abra uma mesa para iniciar</Text>
          <Text style={styles.instructionText}>Toque em uma mesa para abrir e ir direto para o cardápio.</Text>
        </View>
      ) : null}
      <FlatList
        data={tables}
        keyExtractor={(item) => `${item.tipo || 'mesa'}-${item.idComanda || 0}-${item.idMesa}`}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        numColumns={tableColumns}
        key={`home-grid-${tableColumns}`}
        columnWrapperStyle={tableColumns > 1 ? styles.tableColumnWrapper : undefined}
        ListEmptyComponent={
          <View style={styles.emptyCard}>
            <Text style={styles.emptyTitle}>Sem mesas agora</Text>
            <Text style={styles.emptyText}>Abra a mesa pelo toque da tela de comanda no balcão quando começar um pedido.</Text>
          </View>
        }
        contentContainerStyle={styles.list}
        renderItem={({ item, index }) => (
          <View
            style={[
              styles.tableCell,
              { width: cardWidth },
              index % tableColumns !== tableColumns - 1 ? styles.tableCellSpacing : null
            ]}
          >
            <TableCard
              table={item}
              displayMode={appSettings?.modoExibicao || 'mesa'}
              onPress={() => openMesa(item)}
              onLongPress={() => openMesa(item, true)}
            />
          </View>
        )}
      />
      <OpenTableNameModal
        visible={openNameModalVisible}
        value={openNameText}
        onChangeText={setOpenNameText}
        onCancel={() => {
          setOpenNameModalVisible(false);
          setPendingOpenTable(null);
          setOpenNameText('');
        }}
        onConfirm={confirmOpenWithName}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
    padding: Space.md
  },
  list: { paddingBottom: 120 },
  tableColumnWrapper: {
    justifyContent: 'flex-start'
  },
  tableCell: {
    marginBottom: Space.md
  },
  tableCellSpacing: {
    marginRight: Space.sm
  },
  hero: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Space.sm,
    marginBottom: Space.md
  },
  heroCard: {
    backgroundColor: Colors.card,
    borderRadius: Radius.md,
    paddingVertical: Space.md,
    paddingHorizontal: Space.md,
    borderWidth: 1,
    borderColor: Colors.border,
    minWidth: '30%',
    flex: 1
  },
  heroLabel: {
    color: Colors.textMuted,
    fontSize: Typography.caption,
    marginBottom: 6
  },
  heroValue: {
    color: Colors.text,
    fontWeight: '900',
    fontSize: 17
  },
  emptyCard: {
    marginTop: 20,
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Space.lg
  },
  emptyTitle: {
    fontSize: Typography.subtitle,
    fontWeight: '700',
    marginBottom: 6
  },
  emptyText: {
    color: Colors.textMuted
  },
  active: {
    marginBottom: 12,
    backgroundColor: Colors.primarySoft,
    borderColor: Colors.primary,
    borderWidth: 1,
    borderRadius: 12,
    padding: 10
  },
  instructionCard: {
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.primary,
    padding: Space.md,
    marginBottom: Space.md
  },
  instructionTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 4
  },
  instructionText: {
    color: Colors.textMuted,
    fontSize: 12
  },
  activeText: {
    color: Colors.primary,
    fontWeight: '700'
  },
  actionBtn: {
    marginTop: 8,
    backgroundColor: Colors.primary,
    paddingVertical: 8,
    borderRadius: Radius.sm,
    alignItems: 'center'
  },
  actionBtnText: {
    color: '#fff',
    fontWeight: '700'
  },
  actionWarning: {
    marginTop: 8,
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.warning,
    backgroundColor: '#fff4e6',
    padding: 10
  },
  actionWarningText: {
    color: Colors.warning,
    fontWeight: '700'
  }
});


