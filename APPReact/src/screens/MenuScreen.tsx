import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  FlatList,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  useWindowDimensions,
  ScrollView
} from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { CommonActions, RouteProp, useIsFocused, useNavigation, useRoute } from '@react-navigation/native';
import { CategoryChip } from '../components/CategoryChip';
import { MemoFoodCard } from '../components/FoodCard';
import { useApp } from '../context/AppContext';
import { MenuItem, normalizeSaleStatus } from '../services/api';
import { RootStackParams, TabParams } from '../navigation/AppNavigator';
import { Colors, Radius, Space } from '../theme';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { SweetAlert, SweetAlertType } from '../components/SweetAlert';

type MenuNavigation = NativeStackNavigationProp<RootStackParams>;
type MenuRoute = RouteProp<TabParams, 'Cardapio'>;

let lastLaunchedCategoryContext: { tableKey: string; categoryId: number } | null = null;

export const MenuScreen: React.FC = () => {
  const navigation = useNavigation<MenuNavigation>();
  const route = useRoute<MenuRoute>();
  const isFocused = useIsFocused();
  const { width } = useWindowDimensions();
  const [gridWidth, setGridWidth] = useState(0);
  const [categoryBootstrapped, setCategoryBootstrapped] = useState(false);
  const [selectedMenuCategoryId, setSelectedMenuCategoryId] = useState<number | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const lastTableKeyRef = React.useRef<string | null>(null);
  const lastHandledRouteParamsRef = React.useRef<MenuRoute['params'] | undefined>(undefined);
  const {
    categories,
    products,
    appSettings,
    openTableByCard,
    refreshMenu,
    setActiveTable,
    activeTable,
    cart
  } = useApp();
  const [launchWarning, setLaunchWarning] = React.useState('');
  const [sweetAlert, setSweetAlert] = React.useState<{
    visible: boolean;
    title: string;
    message: string;
    type: SweetAlertType;
  }>({
    visible: false,
    title: '',
    message: '',
    type: 'warning'
  });

  const categoriesEnabled = appSettings.utilizaCategorias;
  const realCategories = useMemo(
    () =>
      categories.filter((item) => {
        const label = item.descricao.trim().toLowerCase();
        return label !== 'todos' && label !== 'todas';
      }),
    [categories]
  );
  const routeSelectedCategoryId =
    typeof route.params?.selectedCategoryId === 'number' ? route.params.selectedCategoryId : null;
  const currentTableKey = activeTable ? `${activeTable.tipo || 'mesa'}-${activeTable.idMesa}` : null;
  const rememberedCategoryId =
    currentTableKey !== null &&
    lastLaunchedCategoryContext?.tableKey === currentTableKey &&
    typeof lastLaunchedCategoryContext.categoryId === 'number'
      ? lastLaunchedCategoryContext.categoryId
      : null;

  const currentStatusNormalized = useMemo(
    () =>
      normalizeSaleStatus(
        activeTable?.venda?.situacao ||
          activeTable?.statusCode ||
          activeTable?.statusOriginal ||
          activeTable?.situacao ||
          ''
      ),
    [activeTable]
  );

  const canLaunchByStatus = useMemo(
    () => currentStatusNormalized.includes('pendente'),
    [currentStatusNormalized]
  );
  const currentStatusLabel = useMemo(() => {
    if (currentStatusNormalized.includes('prefechamento') || currentStatusNormalized.includes('pre-fechamento')) {
      return 'Pré-fechamento';
    }
    if (currentStatusNormalized.includes('pendente')) {
      return 'Pendente';
    }
    if (currentStatusNormalized.includes('finalizada')) {
      return 'Finalizada';
    }
    if (currentStatusNormalized.includes('cancelada')) {
      return 'Cancelada';
    }
    if (currentStatusNormalized.includes('reservada')) {
      return 'Reservada';
    }
    if (currentStatusNormalized.includes('digitacao')) {
      return 'Digitação';
    }
    const raw = (activeTable?.venda?.situacao || activeTable?.situacao || 'desconhecido').toString().trim();
    return raw || 'desconhecido';
  }, [activeTable, currentStatusNormalized]);

  useEffect(() => {
    if (categories.length === 0 || products.length === 0) {
      refreshMenu().catch(() => null);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!categoriesEnabled || !isFocused || routeSelectedCategoryId === null) {
      return;
    }

    if (!realCategories.some((item) => item.id === routeSelectedCategoryId)) {
      return;
    }

    if (route.params !== lastHandledRouteParamsRef.current) {
      lastHandledRouteParamsRef.current = route.params;
      if (currentTableKey !== null) {
        lastLaunchedCategoryContext = {
          tableKey: currentTableKey,
          categoryId: routeSelectedCategoryId
        };
      }
      setSelectedMenuCategoryId(routeSelectedCategoryId);
      setCategoryBootstrapped(true);
    }
  }, [
    categoriesEnabled,
    currentTableKey,
    isFocused,
    realCategories,
    route.params,
    routeSelectedCategoryId,
  ]);

  useEffect(() => {
    if (!categoriesEnabled) {
      setSelectedMenuCategoryId(null);
      setCategoryBootstrapped(true);
      return;
    }

    if (realCategories.length === 0) {
      setSelectedMenuCategoryId(null);
      setCategoryBootstrapped(true);
      return;
    }

    if (!isFocused) {
      return;
    }

    if (!categoryBootstrapped) {
      setSelectedMenuCategoryId((prev) => {
        if (prev !== null && realCategories.some((item) => item.id === prev)) {
          return prev;
        }
        if (
          rememberedCategoryId !== null &&
          realCategories.some((item) => item.id === rememberedCategoryId)
        ) {
          return rememberedCategoryId;
        }
        if (
          routeSelectedCategoryId !== null &&
          realCategories.some((item) => item.id === routeSelectedCategoryId)
        ) {
          return routeSelectedCategoryId;
        }
        return realCategories[0].id;
      });
      setCategoryBootstrapped(true);
      return;
    }

    if (selectedMenuCategoryId !== null && !realCategories.some((item) => item.id === selectedMenuCategoryId)) {
      setSelectedMenuCategoryId(realCategories[0].id);
    }
  }, [
    categoriesEnabled,
    realCategories,
    categoryBootstrapped,
    isFocused,
    rememberedCategoryId,
    routeSelectedCategoryId,
    selectedMenuCategoryId
  ]);

  useEffect(() => {
    if (lastTableKeyRef.current === null) {
      lastTableKeyRef.current = currentTableKey;
      return;
    }

    if (currentTableKey !== lastTableKeyRef.current) {
      lastHandledRouteParamsRef.current = undefined;
      setCategoryBootstrapped(!categoriesEnabled);
      setSelectedMenuCategoryId(null);
      lastTableKeyRef.current = currentTableKey;
    }
  }, [categoriesEnabled, currentTableKey]);

  const visibleProducts = useMemo(
    () => products.filter((item) => item.b_venda_mobile !== false),
    [products]
  );

  const productsByCategory = useMemo(() => {
    const grouped = new Map<number, MenuItem[]>();
    for (const item of visibleProducts) {
      const categoryId = Number(item.idCategoria || 0);
      const current = grouped.get(categoryId);
      if (current) {
        current.push(item);
      } else {
        grouped.set(categoryId, [item]);
      }
    }
    return grouped;
  }, [visibleProducts]);

  const firstCategoryId = realCategories[0]?.id ?? null;
  const effectiveCategoryId = categoriesEnabled
    ? (categoryBootstrapped ? (selectedMenuCategoryId ?? firstCategoryId) : firstCategoryId)
    : null;

  const handleSelectCategory = useCallback((id: number | null) => {
    const nextCategoryId = categoriesEnabled ? (id ?? firstCategoryId) : id;
    if (currentTableKey !== null && typeof nextCategoryId === 'number') {
      lastLaunchedCategoryContext = {
        tableKey: currentTableKey,
        categoryId: nextCategoryId
      };
    }
    setSelectedMenuCategoryId(nextCategoryId);
    setCategoryBootstrapped(true);
  }, [categoriesEnabled, currentTableKey, firstCategoryId]);

  const filtered = useMemo(
    () => {
      if (visibleProducts.length === 0) {
        return [];
      }

      const normalizedQuery = searchQuery.trim().toLowerCase();
      if (normalizedQuery) {
        return visibleProducts.filter((item) => (item.descricao || '').toLowerCase().includes(normalizedQuery));
      }

      if (!categoriesEnabled) {
        return visibleProducts;
      }

      if (realCategories.length === 0) {
        return visibleProducts;
      }

      if (effectiveCategoryId === null) {
        return [];
      }

      const categoryItems = productsByCategory.get(effectiveCategoryId) || [];
      return categoryItems;
    },
    [categoriesEnabled, effectiveCategoryId, productsByCategory, realCategories.length, searchQuery, visibleProducts]
  );

  const menuColumns = useMemo(() => {
    const availableWidth =
      gridWidth > 0 ? gridWidth : Math.max(0, width - Space.md * 2);
    const minCardWidth =
      availableWidth >= 1200 ? 220 :
      availableWidth >= 920 ? 205 :
      availableWidth >= 700 ? 190 :
      availableWidth >= 520 ? 175 :
      160;
    const maxColumns = Math.max(1, Math.floor((availableWidth + Space.sm) / (minCardWidth + Space.sm)));
    return Math.max(1, Math.min(6, maxColumns));
  }, [gridWidth, width]);

  const cardWidth = useMemo(() => {
    const availableWidth =
      gridWidth > 0 ? gridWidth : Math.max(0, width - Space.md * 2);
    const spacing = Space.sm * (menuColumns - 1);
    return Math.max(140, Math.floor((availableWidth - spacing) / menuColumns));
  }, [gridWidth, width, menuColumns]);

  const openLaunchScreen = useCallback((item: MenuItem) => {
    const showSweetAlert = (title: string, message: string, type: SweetAlertType = 'warning') => {
      setSweetAlert({
        visible: true,
        title,
        message,
        type
      });
    };

    if (!activeTable) {
      const msg = 'Selecione uma mesa antes de lançar itens.';
      setLaunchWarning(msg);
      showSweetAlert('Fluxo inválido', msg, 'error');
      return;
    }

    if (!canLaunchByStatus) {
      const msg = `Só é permitido lançar itens quando a mesa estiver pendente. Status atual: ${currentStatusLabel}.`;
      setLaunchWarning(msg);
      showSweetAlert('Atenção', msg, 'warning');
      return;
    }

    setLaunchWarning('');

    void (async () => {
      let currentTable = activeTable;
      try {
        if (!activeTable.idVenda) {
          const refreshed = await openTableByCard(activeTable.idMesa, activeTable.nomeMesaComanda, activeTable.tipo);
          currentTable = refreshed;
          setActiveTable(refreshed);
        }
      } catch {
        // Mantém compatibilidade com fluxo antigo.
      }

      const itemCategoryId = Number(item.idCategoria || 0);
      const returnCategoryId =
        itemCategoryId > 0 && realCategories.some((category) => category.id === itemCategoryId)
          ? itemCategoryId
          : effectiveCategoryId ?? realCategories[0]?.id;

      if (currentTableKey !== null && typeof returnCategoryId === 'number') {
        lastLaunchedCategoryContext = {
          tableKey: currentTableKey,
          categoryId: returnCategoryId
        };
      }

      const launchParams = {
        item,
        origin: 'cardapio' as const,
        tableId: currentTable.idMesa,
        tableComandaId: currentTable.idComanda,
        tableType: currentTable.tipo || 'mesa',
        tableName: currentTable.nomeMesaComanda,
        returnTo: 'Cardapio' as const,
        returnCategoryId
      };
      const parent = navigation.getParent<NativeStackNavigationProp<RootStackParams>>();
      if (parent) {
        parent.navigate('Lancamento', launchParams);
        return;
      }

      navigation.navigate('Lancamento', launchParams);
    })();
  }, [
    activeTable,
    canLaunchByStatus,
    currentTableKey,
    currentStatusLabel,
    effectiveCategoryId,
    navigation,
    openTableByCard,
    realCategories,
    setActiveTable
  ]);

  const keyExtractor = useCallback((item: MenuItem) => String(item.idProduto), []);

  const renderMenuItem = useCallback(
    ({ item, index }: { item: MenuItem; index: number }) => (
      <View
        style={[
          styles.menuCell,
          { width: cardWidth },
          index % menuColumns !== menuColumns - 1 ? styles.menuCellSpacing : null
        ]}
      >
        <MemoFoodCard item={item} onOpen={() => openLaunchScreen(item)} />
      </View>
    ),
    [cardWidth, menuColumns, openLaunchScreen]
  );

  const goToInitial = async () => {
    lastLaunchedCategoryContext = null;
    lastHandledRouteParamsRef.current = undefined;
    setCategoryBootstrapped(false);
    setSelectedMenuCategoryId(null);

    const navigateToInitial = () => {
      const parent = navigation.getParent<NativeStackNavigationProp<RootStackParams>>();

      try {
        if (parent) {
          parent.navigate('Inicial', { autoSendPending: true });
          return;
        }
      } catch (error: unknown) {
        void error;
      }

      try {
        navigation.navigate('Inicial', { autoSendPending: true });
        return;
      } catch (error: unknown) {
        void error;
      }

      const resetAction = CommonActions.reset({
        index: 0,
        routes: [{ name: 'Inicial', params: { autoSendPending: true } } as never]
      });

      if (parent) {
        parent.dispatch(resetAction);
        return;
      }
      navigation.dispatch(resetAction);
    };

    try {
      navigateToInitial();
    } catch (error: unknown) {
      const pendingErrorMessage = error instanceof Error ? error.message : 'Não foi possível voltar para a tela inicial.';
      setSweetAlert({
        visible: true,
        title: 'Aviso',
        message: pendingErrorMessage,
        type: 'warning'
      });
    } finally {
      // sem envio nesta tela; envio ocorre apenas na Inicial.
    }
  };

  const openPendingItems = () => {
    const params = activeTable?.idVenda ? { idVenda: activeTable.idVenda } : undefined;
    const parent = navigation.getParent<NativeStackNavigationProp<RootStackParams>>();
    if (parent) {
      parent.navigate('ItensPendentes', params as never);
      return;
    }
    navigation.navigate('ItensPendentes', params as never);
  };

  const mesaLabel = activeTable
    ? `${activeTable.tipo === 'comanda' ? 'Comanda' : 'Mesa'} ${activeTable.idMesa}`
    : 'Mesa --';

  return (
    <View style={styles.container}>
      <ScreenRouteLabel />
      <View style={styles.topRow}>
        <View style={styles.topActions}>
          <TouchableOpacity style={styles.backBtn} onPress={goToInitial} activeOpacity={0.85}>
            <Text style={styles.backBtnText}>Voltar</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.viewBtn} onPress={openPendingItems} activeOpacity={0.85}>
            <Text style={styles.viewBtnText}>(<Text style={styles.viewBtnCount}>{cart.length}</Text>)</Text>
          </TouchableOpacity>
          <View style={styles.searchWrap}>
            <Text style={styles.searchIcon}>⌕</Text>
            <TextInput
              value={searchQuery}
              onChangeText={setSearchQuery}
              placeholder="Pesquisar item"
              placeholderTextColor={Colors.textMuted}
              style={styles.searchInput}
            />
          </View>
        </View>
        <View style={styles.tableBadge}>
          <Text style={styles.tableBadgeText}>{mesaLabel}</Text>
        </View>
      </View>
      <FlatList
        onLayout={(event) => {
          const nextWidth = Math.floor(event.nativeEvent.layout.width);
          setGridWidth((prev) => (prev === nextWidth ? prev : nextWidth));
        }}
        data={filtered}
        keyExtractor={keyExtractor}
        numColumns={menuColumns}
        key={`menu-grid-${menuColumns}`}
        columnWrapperStyle={menuColumns > 1 ? styles.menuColumnWrapper : undefined}
        initialNumToRender={6}
        maxToRenderPerBatch={Math.max(menuColumns * 2, 8)}
        updateCellsBatchingPeriod={45}
        windowSize={5}
        removeClippedSubviews={true}
        ListHeaderComponent={
          <>
            {!canLaunchByStatus ? (
              <View style={styles.warningCard}>
                <Text style={styles.warningText}>
                  Lançamento bloqueado. A mesa precisa estar com status pendente.
                </Text>
              </View>
            ) : null}
            {launchWarning ? (
              <View style={styles.warningCard}>
                <Text style={styles.warningText}>{launchWarning}</Text>
              </View>
            ) : null}
            {categoriesEnabled && realCategories.length > 0 ? (
              <CategorySlider
                categories={realCategories}
                selectedCategoryId={effectiveCategoryId}
                onSelect={handleSelectCategory}
              />
            ) : null}
          </>
        }
        ListHeaderComponentStyle={styles.categoryListHeader}
        contentContainerStyle={{ paddingBottom: 120 }}
        renderItem={renderMenuItem}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Text style={styles.emptyText}>Nenhum item para essa categoria.</Text>
          </View>
        }
      />
      <SweetAlert
        visible={sweetAlert.visible}
        title={sweetAlert.title}
        message={sweetAlert.message}
        type={sweetAlert.type}
        onConfirm={() =>
          setSweetAlert((prev) => ({
            ...prev,
            visible: false
          }))
        }
      />
    </View>
  );
};

const CategorySlider = ({
  categories,
  selectedCategoryId,
  onSelect
}: {
  categories: { id: number; descricao: string }[];
  selectedCategoryId: number | null;
  onSelect: (id: number | null) => void;
}) => {
  const scrollRef = React.useRef<ScrollView | null>(null);
  const itemLayoutsRef = React.useRef<Record<string, { x: number; width: number }>>({});
  const [viewportWidth, setViewportWidth] = useState(0);
  const [contentWidth, setContentWidth] = useState(0);
  const items = useMemo(
    () => [...categories, { id: null as number | null, descricao: 'Todos' }],
    [categories]
  );
  const selectedKey = `${selectedCategoryId ?? 'all'}`;

  useEffect(() => {
    const layout = itemLayoutsRef.current[selectedKey];
    if (!layout || viewportWidth <= 0 || !scrollRef.current) {
      return;
    }

    const rawTargetX = layout.x - Math.max(0, (viewportWidth - layout.width) / 2);
    const maxScrollX = Math.max(0, contentWidth - viewportWidth);
    const targetX = Math.max(0, Math.min(rawTargetX, maxScrollX));

    scrollRef.current.scrollTo({ x: targetX, animated: true });
  }, [contentWidth, selectedKey, viewportWidth]);

  return (
    <View style={styles.categorySliderWrapper}>
      <ScrollView
        ref={scrollRef}
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.categorySlider}
        contentContainerStyle={styles.categoryRow}
        onLayout={(event) => setViewportWidth(event.nativeEvent.layout.width)}
        onContentSizeChange={(width) => setContentWidth(width)}
      >
        {items.map((item) => {
          const key = `${item.id ?? 'all'}`;
          return (
            <View
              key={key}
              onLayout={(event) => {
                const { x, width } = event.nativeEvent.layout;
                itemLayoutsRef.current[key] = { x, width };
              }}
            >
              <CategoryChip
                label={item.descricao}
                active={selectedCategoryId === item.id}
                onPress={() => onSelect(item.id)}
              />
            </View>
          );
        })}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
    padding: Space.md
  },
  topRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 10
  },
  topActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
    marginRight: 8
  },
  backBtn: {
    borderRadius: Radius.sm,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    paddingHorizontal: 14,
    paddingVertical: 9
  },
  backBtnText: {
    color: Colors.text,
    fontWeight: '800'
  },
  viewBtn: {
    borderRadius: Radius.sm,
    borderWidth: 1,
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft,
    paddingHorizontal: 10,
    paddingVertical: 9
  },
  viewBtnText: {
    color: Colors.primary,
    fontWeight: '800'
  },
  viewBtnCount: {
    color: '#D32F2F',
    fontWeight: '900'
  },
  searchWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: Radius.sm,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    paddingHorizontal: 10,
    flex: 1,
    minWidth: 150,
    maxWidth: 280
  },
  searchIcon: {
    color: Colors.textMuted,
    fontSize: 14,
    marginRight: 6
  },
  searchInput: {
    flex: 1,
    color: Colors.text,
    paddingVertical: 9
  },
  tableBadge: {
    borderRadius: Radius.sm,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginLeft: 8
  },
  tableBadgeText: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: 12
  },
  categoryRow: {
    paddingBottom: 8,
    paddingRight: Space.sm
  },
  categorySliderWrapper: {
    width: '100%'
  },
  categorySlider: {
    zIndex: 2,
    paddingBottom: 0
  },
  categoryListHeader: {
    marginBottom: 12
  },
  warningCard: {
    borderWidth: 1,
    borderColor: Colors.warning,
    borderRadius: Radius.md,
    backgroundColor: Colors.warning + '12',
    paddingHorizontal: 10,
    paddingVertical: 8,
    marginBottom: 8
  },
  warningText: {
    color: Colors.warning,
    fontWeight: '700',
    fontSize: 12
  },
  empty: {
    padding: 24,
    borderRadius: 12,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border
  },
  emptyText: {
    color: Colors.textMuted
  },
  menuColumnWrapper: {
    justifyContent: 'flex-start',
    alignItems: 'stretch'
  },
  menuCell: {
    marginBottom: Space.sm,
    alignSelf: 'stretch'
  },
  menuCellSpacing: {
    marginRight: Space.sm
  }
});
