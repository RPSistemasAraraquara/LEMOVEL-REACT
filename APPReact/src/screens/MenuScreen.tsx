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
import { Colors, Radius, Shadows, Space } from '../theme';
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

  const visibleProducts = useMemo(() => products, [products]);

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
        const hasExactCodeMatch = visibleProducts.some((item) => {
          const productCode = String(item.codReferencia || '').trim().toLowerCase();
          return productCode.length > 0 && productCode === normalizedQuery;
        });

        return visibleProducts.filter((item) => {
          const description = String(item.descricao || '').toLowerCase();
          const productCode = String(item.codReferencia || '').trim().toLowerCase();

          if (hasExactCodeMatch) {
            return productCode === normalizedQuery;
          }

          return description.includes(normalizedQuery) || (productCode.length > 0 && productCode.includes(normalizedQuery));
        });
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
  const searchActive = searchQuery.trim().length > 0;
  const activeCategoryLabel = useMemo(() => {
    if (searchActive) {
      return `Busca: ${searchQuery.trim()}`;
    }
    if (!categoriesEnabled) {
      return 'Cardápio completo';
    }
    if (effectiveCategoryId === null) {
      return 'Categorias';
    }
    return realCategories.find((item) => item.id === effectiveCategoryId)?.descricao || 'Categorias';
  }, [categoriesEnabled, effectiveCategoryId, realCategories, searchActive, searchQuery]);
  const statusPalette = canLaunchByStatus
    ? {
        border: '#C7E6D0',
        soft: '#F3FBF5',
        text: '#2F7A4F'
      }
    : {
        border: '#F2D7B1',
        soft: '#FFF5E9',
        text: '#C88738'
      };
  return (
    <View style={styles.container}>
      <ScreenRouteLabel />
      <View pointerEvents="none" style={styles.heroGlowPrimary} />
      <View pointerEvents="none" style={styles.heroGlowSecondary} />

      <View style={styles.heroCard}>
        <View style={styles.heroTopRow}>
          <TouchableOpacity style={styles.backBtn} onPress={goToInitial} activeOpacity={0.9}>
            <Text style={styles.backBtnText}>Voltar</Text>
          </TouchableOpacity>
          <View style={styles.heroTopActions}>
            <TouchableOpacity style={styles.viewBtn} onPress={openPendingItems} activeOpacity={0.9}>
              <Text style={styles.viewBtnText}>Itens</Text>
              <Text style={styles.viewBtnCount}>{cart.length}</Text>
            </TouchableOpacity>
            <View style={[styles.heroStatusBadge, { borderColor: statusPalette.border, backgroundColor: statusPalette.soft }]}>
              <Text style={[styles.heroStatusValue, { color: statusPalette.text }]}>{currentStatusLabel}</Text>
            </View>
          </View>
        </View>

        <View style={styles.heroCopy}>
          <Text style={styles.heroTitle}>{mesaLabel}</Text>
        </View>

        <View style={styles.searchWrap}>
          <Text style={styles.searchIcon}>⌕</Text>
          <TextInput
            value={searchQuery}
            onChangeText={setSearchQuery}
            placeholder="Pesquisar item por descricao ou codigo"
            placeholderTextColor={Colors.textMuted}
            style={styles.searchInput}
          />
          {searchActive ? (
            <TouchableOpacity style={styles.searchClearButton} onPress={() => setSearchQuery('')} activeOpacity={0.85}>
              <Text style={styles.searchClearButtonText}>Limpar</Text>
            </TouchableOpacity>
          ) : null}
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
          <View style={styles.listIntro}>
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
            <View style={styles.categoryPanel}>
              <View style={styles.categoryPanelHeader}>
                <View>
                  <Text style={styles.categoryPanelEyebrow}>NAVEGAÇÃO</Text>
                  <Text style={styles.categoryPanelTitle}>{activeCategoryLabel}</Text>
                </View>
                <Text style={styles.categoryPanelMeta}>{filtered.length} itens</Text>
              </View>
              {categoriesEnabled && realCategories.length > 0 ? (
                <CategorySlider
                  categories={realCategories}
                  selectedCategoryId={effectiveCategoryId}
                  onSelect={handleSelectCategory}
                />
              ) : (
                <Text style={styles.categoryPanelEmpty}>Categorias desativadas. Exibindo todo o cardápio.</Text>
              )}
            </View>
          </View>
        }
        ListHeaderComponentStyle={styles.categoryListHeader}
        contentContainerStyle={styles.listContent}
        renderItem={renderMenuItem}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Text style={styles.emptyTitle}>Nada encontrado por aqui</Text>
            <Text style={styles.emptyText}>Ajuste a busca ou troque a categoria para continuar.</Text>
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
  heroGlowPrimary: {
    position: 'absolute',
    top: -60,
    right: -20,
    width: 220,
    height: 220,
    borderRadius: 110,
    backgroundColor: 'rgba(27, 79, 114, 0.14)'
  },
  heroGlowSecondary: {
    position: 'absolute',
    top: 70,
    left: -36,
    width: 160,
    height: 160,
    borderRadius: 80,
    backgroundColor: 'rgba(242, 153, 74, 0.12)'
  },
  heroCard: {
    borderRadius: Radius.xl,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    padding: 12,
    marginBottom: Space.md,
    gap: 10,
    ...Shadows.card
  },
  heroTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: Space.sm
  },
  heroTopActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8
  },
  backBtn: {
    borderRadius: 18,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 14,
    paddingVertical: 8,
    ...Shadows.soft
  },
  backBtnText: {
    color: Colors.primary,
    fontWeight: '800',
    fontSize: 12
  },
  viewBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: 'rgba(242, 153, 74, 0.18)',
    backgroundColor: Colors.accentSoft,
    paddingHorizontal: 12,
    paddingVertical: 8,
    ...Shadows.soft
  },
  viewBtnText: {
    color: Colors.accent,
    fontWeight: '800',
    fontSize: 12
  },
  viewBtnCount: {
    minWidth: 20,
    textAlign: 'center',
    color: '#D64550',
    fontWeight: '900',
    fontSize: 13
  },
  heroCopy: {
    flex: 1
  },
  heroTitle: {
    color: Colors.text,
    fontWeight: '900',
    fontSize: 17,
    lineHeight: 22
  },
  heroStatusBadge: {
    borderRadius: 18,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
    alignItems: 'flex-start'
  },
  heroStatusValue: {
    fontSize: 12,
    fontWeight: '900'
  },
  searchWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 12,
    ...Shadows.soft
  },
  searchIcon: {
    color: Colors.textMuted,
    fontSize: 15,
    marginRight: 8
  },
  searchInput: {
    flex: 1,
    color: Colors.text,
    paddingVertical: 8
  },
  searchClearButton: {
    borderRadius: 14,
    backgroundColor: Colors.primarySoft,
    paddingHorizontal: 10,
    paddingVertical: 8,
    marginLeft: 8
  },
  searchClearButtonText: {
    color: Colors.primary,
    fontWeight: '800',
    fontSize: 12
  },
  categoryRow: {
    paddingBottom: 6,
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
  listIntro: {
    gap: 10
  },
  categoryPanel: {
    borderRadius: Radius.lg,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    paddingVertical: Space.md,
    paddingHorizontal: Space.md,
    ...Shadows.card
  },
  categoryPanelHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: Space.sm,
    marginBottom: Space.sm
  },
  categoryPanelEyebrow: {
    color: Colors.accent,
    fontSize: 11,
    fontWeight: '900',
    letterSpacing: 0.6,
    marginBottom: 4
  },
  categoryPanelTitle: {
    color: Colors.text,
    fontSize: 18,
    fontWeight: '900'
  },
  categoryPanelMeta: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    paddingTop: 18
  },
  categoryPanelEmpty: {
    color: Colors.textMuted,
    fontSize: 13,
    lineHeight: 18
  },
  warningCard: {
    borderWidth: 1,
    borderColor: Colors.warning,
    borderRadius: 20,
    backgroundColor: Colors.accentSoft,
    paddingHorizontal: 12,
    paddingVertical: 10,
    ...Shadows.soft
  },
  warningText: {
    color: Colors.warning,
    fontWeight: '700',
    fontSize: 12,
    lineHeight: 17
  },
  empty: {
    padding: 24,
    borderRadius: 26,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    ...Shadows.card
  },
  emptyTitle: {
    color: Colors.text,
    fontSize: 18,
    fontWeight: '900',
    marginBottom: 6
  },
  emptyText: {
    color: Colors.textMuted,
    lineHeight: 19
  },
  listContent: {
    paddingBottom: 120
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
