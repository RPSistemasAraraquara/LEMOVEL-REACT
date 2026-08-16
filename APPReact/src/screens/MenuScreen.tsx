import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  BackHandler,
  FlatList,
  Modal,
  PermissionsAndroid,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  useWindowDimensions,
  ScrollView
} from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { CommonActions, RouteProp, useFocusEffect, useIsFocused, useNavigation, useRoute } from '@react-navigation/native';
import { CategoryChip } from '../components/CategoryChip';
import { MemoFoodCard } from '../components/FoodCard';
import { useApp } from '../context/AppContext';
import {
  api,
  buildMenuItemRestrictedMessage,
  formatTableStatusLabel,
  getTableOrderDisplayLabel,
  isMenuItemRestrictedToday,
  logSyncDiagnostic,
  MenuItem,
  normalizeSaleStatus,
  TableOrder
} from '../services/api';
import { RootStackParams, TabParams } from '../navigation/AppNavigator';
import { Colors, Radius, Shadows, Space } from '../theme';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { SweetAlert, SweetAlertType } from '../components/SweetAlert';

type MenuNavigation = NativeStackNavigationProp<RootStackParams>;
type MenuRoute = RouteProp<TabParams, 'Cardapio'>;

type BarcodeScanningResult = {
  data?: string | null;
  type?: string | null;
};

const PRODUCT_CAMERA_BARCODE_TYPES = ['ean13', 'ean8'] as const;

const getCameraViewComponent = (): React.ComponentType<any> | null => {
  try {
    const module = require('expo-camera') as { CameraView?: React.ComponentType<any> };
    return module.CameraView || null;
  } catch {
    return null;
  }
};

const normalizeBarcodeReference = (value: unknown): string => {
  const normalized = String(value ?? '').trim().toLowerCase();
  if (!normalized) {
    return '';
  }

  if (/^\d+$/.test(normalized)) {
    return normalized.replace(/^0+/, '') || '0';
  }

  return normalized;
};

const normalizeProductCameraBarcode = (result: BarcodeScanningResult): string => {
  const rawValue = String(result?.data ?? '').trim();
  if (!rawValue) {
    return '';
  }

  const barcodeType = String(result?.type ?? '').trim().toLowerCase();
  const normalizedValue = rawValue.replace(/\s+/g, '');
  if (!normalizedValue) {
    return '';
  }

  if (barcodeType && !PRODUCT_CAMERA_BARCODE_TYPES.includes(barcodeType as (typeof PRODUCT_CAMERA_BARCODE_TYPES)[number])) {
    return '';
  }

  if (/^\d+$/.test(normalizedValue) && ![8, 13].includes(normalizedValue.length)) {
    return '';
  }

  return normalizedValue;
};

const findProductByBarcodeInList = (items: MenuItem[], rawCode: string) => {
  const normalizedCode = normalizeBarcodeReference(rawCode);
  if (!normalizedCode) {
    return null;
  }

  return items.find(
    (item) =>
      item.b_venda_mobile !== false &&
      normalizeBarcodeReference(item.codReferencia) === normalizedCode
  ) || null;
};

const getMenuItemIdentity = (item: MenuItem) => Number(item.idProduto || item.id || 0);

const getLogErrorMessage = (error: unknown) =>
  error instanceof Error ? error.message : String(error || 'erro desconhecido');

let lastLaunchedCategoryContext: { tableKey: string; categoryId: number } | null = null;

const MENU_IMAGE_RESUME_DELAY_MS = 120;

const getMenuCardHeight = (showImageSlot: boolean, compactLayout: boolean) => {
  if (showImageSlot) {
    return compactLayout ? 250 : 316;
  }

  return compactLayout ? 166 : 206;
};

export const MenuScreen: React.FC = () => {
  const navigation = useNavigation<MenuNavigation>();
  const route = useRoute<MenuRoute>();
  const isFocused = useIsFocused();
  const { width } = useWindowDimensions();
  const compactLayout = width <= 380;
  const [gridWidth, setGridWidth] = useState(0);
  const [categoryBootstrapped, setCategoryBootstrapped] = useState(false);
  const [selectedMenuCategoryId, setSelectedMenuCategoryId] = useState<number | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [debouncedSearchQuery, setDebouncedSearchQuery] = useState('');
  const [productCameraOpen, setProductCameraOpen] = useState(false);
  const [productCameraLoading, setProductCameraLoading] = useState(false);
  const [productManualOpen, setProductManualOpen] = useState(false);
  const [productManualText, setProductManualText] = useState('');
  const [deferCardImages, setDeferCardImages] = useState(false);
  const [CameraViewComponent, setCameraViewComponent] = useState<React.ComponentType<any> | null>(null);
  const lastTableKeyRef = React.useRef<string | null>(null);
  const lastHandledRouteParamsRef = React.useRef<MenuRoute['params'] | undefined>(undefined);
  const productCameraBusyRef = React.useRef(false);
  const cardImageResumeTimerRef = React.useRef<ReturnType<typeof setTimeout> | null>(null);
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
  const showSweetAlert = useCallback((title: string, message: string, type: SweetAlertType = 'warning') => {
    setSweetAlert({
      visible: true,
      title,
      message,
      type
    });
  }, []);

  useEffect(
    () => () => {
      if (cardImageResumeTimerRef.current) {
        clearTimeout(cardImageResumeTimerRef.current);
        cardImageResumeTimerRef.current = null;
      }
    },
    []
  );

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

  const hasConfirmedSale = Boolean(activeTable?.idVenda && Number(activeTable.idVenda) > 0);
  const canLaunchByStatus = useMemo(
    () => !hasConfirmedSale || currentStatusNormalized.includes('pendente'),
    [currentStatusNormalized, hasConfirmedSale]
  );
  const happyHourSaleType = useMemo<'mesa' | 'comanda'>(
    () => activeTable?.tipo || (appSettings.modoExibicao === 'comanda' ? 'comanda' : 'mesa'),
    [activeTable?.tipo, appSettings.modoExibicao]
  );
  const currentStatusLabel = useMemo(() => {
    if (!hasConfirmedSale) {
      return 'Venda não aberta';
    }
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
  }, [activeTable, currentStatusNormalized, hasConfirmedSale]);

  const showLaunchBlocked = useCallback((title: string, message: string, type: SweetAlertType = 'warning') => {
    setLaunchWarning(message);
    showSweetAlert(title, message, type);
  }, [showSweetAlert]);

  const buildBlockedStatusMessage = useCallback((statusLabel = currentStatusLabel) => (
    `Só é permitido lançar itens quando a mesa estiver pendente. Status atual: ${statusLabel}.`
  ), [currentStatusLabel]);

  const buildConfirmedPendingTable = useCallback((
    table: TableOrder,
    saleStatus: string,
    saleTotal: number,
    saleName?: string
  ): TableOrder => ({
    ...table,
    nomeMesaComanda: saleName || table.nomeMesaComanda,
    valorTotal: Number.isFinite(saleTotal) ? saleTotal : Number(table.valorTotal || 0),
    venda: {
      ...(table.venda || {}),
      idVenda: Number(table.idVenda || table.venda?.idVenda || 0),
      situacao: saleStatus,
      nomeMesaComanda: saleName || table.venda?.nomeMesaComanda,
      valorTotal: Number.isFinite(saleTotal) ? saleTotal : Number(table.venda?.valorTotal || table.valorTotal || 0),
      valorPagamentoAntecipado: Number(table.venda?.valorPagamentoAntecipado || 0)
    }
  }), []);

  const confirmLaunchTable = useCallback(async (): Promise<TableOrder | null> => {
    if (!activeTable) {
      showLaunchBlocked('Fluxo inválido', 'Selecione uma mesa antes de lançar itens.', 'error');
      return null;
    }

    if (!hasConfirmedSale || canLaunchByStatus) {
      setLaunchWarning('');
      return activeTable;
    }

    const localLooksLikeOpeningState = currentStatusNormalized.includes('digitacao') || currentStatusNormalized.length === 0;
    if (localLooksLikeOpeningState) {
      try {
        const freshSale = await api.getSale(Number(activeTable.idVenda), false);
        const freshStatus = normalizeSaleStatus(freshSale?.situacao || '');
        if (freshSale?.idVenda && freshStatus.includes('pendente')) {
          const refreshedTable = buildConfirmedPendingTable(
            activeTable,
            freshSale.situacao || 'Pendente',
            Number(freshSale.valorTotal || activeTable.valorTotal || 0),
            freshSale.nomeMesaComanda
          );
          setActiveTable(refreshedTable);
          setLaunchWarning('');
          return refreshedTable;
        }

        if (freshSale?.situacao) {
          showLaunchBlocked('Atenção', buildBlockedStatusMessage(formatTableStatusLabel(freshSale.situacao)));
          return null;
        }
      } catch (error: unknown) {
        logSyncDiagnostic(`menu confirmar status venda falhou: ${getLogErrorMessage(error)}`, 2);
      }

      showLaunchBlocked(
        'Conexão instável',
        'Não foi possível confirmar a abertura da venda na API. Verifique a conexão e tente novamente.',
        'warning'
      );
      return null;
    }

    showLaunchBlocked('Atenção', buildBlockedStatusMessage());
    return null;
  }, [
    activeTable,
    buildBlockedStatusMessage,
    buildConfirmedPendingTable,
    canLaunchByStatus,
    currentStatusNormalized,
    hasConfirmedSale,
    setActiveTable,
    showLaunchBlocked
  ]);

  useEffect(() => {
    if (categories.length === 0 || products.length === 0) {
      const startedAt = Date.now();
      logSyncDiagnostic(`menu tela carga inicial cache cats=${categories.length} produtos=${products.length}`);
      refreshMenu({ preferCache: true })
        .then(() => {
          logSyncDiagnostic(`menu tela cache pronto em ${Date.now() - startedAt}ms`);
        })
        .catch((error) => {
          logSyncDiagnostic(`menu tela cache falhou: ${getLogErrorMessage(error)}`, 2);
          return refreshMenu().catch((remoteError) => {
            logSyncDiagnostic(`menu tela remoto falhou: ${getLogErrorMessage(remoteError)}`, 2);
          });
        });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearchQuery(searchQuery);
    }, Platform.OS === 'android' ? 140 : 90);

    return () => clearTimeout(timer);
  }, [searchQuery]);

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

  const { productSearchIndex, productsByCategory } = useMemo(() => {
    const grouped = new Map<number, MenuItem[]>();
    const searchIndex = new Map<number, { description: string; code: string }>();
    for (const item of products) {
      const productId = getMenuItemIdentity(item);
      const categoryId = Number(item.idCategoria || 0);
      const current = grouped.get(categoryId);
      if (current) {
        current.push(item);
      } else {
        grouped.set(categoryId, [item]);
      }

      searchIndex.set(productId, {
        description: String(item.descricao || '').toLowerCase(),
        code: normalizeBarcodeReference(item.codReferencia)
      });
    }
    return {
      productSearchIndex: searchIndex,
      productsByCategory: grouped
    };
  }, [products]);

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
      if (products.length === 0) {
        return [];
      }

      const trimmedQuery = debouncedSearchQuery.trim();
      const normalizedQuery = trimmedQuery.toLowerCase();
      const normalizedCodeQuery = normalizeBarcodeReference(trimmedQuery);
      if (normalizedQuery) {
        let hasExactCodeMatch = false;
        for (const item of products) {
          const indexed = productSearchIndex.get(getMenuItemIdentity(item));
          if (indexed?.code && indexed.code === normalizedCodeQuery) {
            hasExactCodeMatch = true;
            break;
          }
        }

        const result: MenuItem[] = [];
        for (const item of products) {
          const indexed = productSearchIndex.get(getMenuItemIdentity(item));
          const productCode = indexed?.code || '';
          const description = indexed?.description || '';
          const matched = hasExactCodeMatch
            ? productCode === normalizedCodeQuery
            : description.includes(normalizedQuery) ||
              (productCode.length > 0 && productCode.includes(normalizedCodeQuery));

          if (matched) {
            result.push(item);
          }
        }
        return result;
      }

      if (!categoriesEnabled) {
        return products;
      }

      if (realCategories.length === 0) {
        return products;
      }

      if (effectiveCategoryId === null) {
        return [];
      }

      const categoryItems = productsByCategory.get(effectiveCategoryId) || [];
      return categoryItems;
    },
    [categoriesEnabled, debouncedSearchQuery, effectiveCategoryId, productSearchIndex, products, productsByCategory, realCategories.length]
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

  const cardHeight = useMemo(
    () => getMenuCardHeight(appSettings.exibirImagem, compactLayout),
    [appSettings.exibirImagem, compactLayout]
  );
  const menuRowHeight = useMemo(() => cardHeight + Space.sm, [cardHeight]);
  const getMenuItemLayout = useCallback(
    (_data: ArrayLike<MenuItem[]> | null | undefined, index: number) => ({
      length: menuRowHeight,
      offset: menuRowHeight * index,
      index
    }),
    [menuRowHeight]
  );

  const menuRows = useMemo(() => {
    const rows: MenuItem[][] = [];
    for (let index = 0; index < filtered.length; index += menuColumns) {
      rows.push(filtered.slice(index, index + menuColumns));
    }
    return rows;
  }, [filtered, menuColumns]);

  const pauseCardImages = useCallback(() => {
    if (cardImageResumeTimerRef.current) {
      clearTimeout(cardImageResumeTimerRef.current);
      cardImageResumeTimerRef.current = null;
    }
    setDeferCardImages((prev) => (prev ? prev : true));
  }, []);

  const resumeCardImages = useCallback(() => {
    if (cardImageResumeTimerRef.current) {
      clearTimeout(cardImageResumeTimerRef.current);
    }

    cardImageResumeTimerRef.current = setTimeout(() => {
      cardImageResumeTimerRef.current = null;
      setDeferCardImages((prev) => (prev ? false : prev));
    }, Platform.OS === 'android' ? MENU_IMAGE_RESUME_DELAY_MS : 0);
  }, []);

  const findProductByBarcode = useCallback((rawCode: string) => {
    return findProductByBarcodeInList(products, rawCode);
  }, [products]);

  const openLaunchScreen = useCallback((item: MenuItem) => {
    void (async () => {
      if (isMenuItemRestrictedToday(item)) {
        showLaunchBlocked('Item restrito', buildMenuItemRestrictedMessage(item), 'warning');
        return;
      }

      const launchTable = await confirmLaunchTable();
      if (!launchTable) {
        return;
      }

      const currentTable = launchTable;
      // Performance: nao espera a abertura da venda aqui - so AQUECE a
      // request (deduplicada no AppContext): a tela de lancamento dispara a
      // abertura dela e compartilha esta mesma promise. Quem escreve o
      // activeTable e SO o caminho guardado do ItemLaunchScreen - escrever
      // aqui podia chegar atrasado e apontar o lancamento para a mesa errada.
      if (!currentTable.idVenda) {
        void openTableByCard(currentTable.idMesa, currentTable.nomeMesaComanda, currentTable.tipo)
          .catch((error: unknown) => {
            logSyncDiagnostic(`menu abrir venda antes do lancamento falhou: ${getLogErrorMessage(error)}`, 2);
          });
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
    confirmLaunchTable,
    currentTableKey,
    effectiveCategoryId,
    navigation,
    openTableByCard,
    realCategories,
    setActiveTable,
    showLaunchBlocked
  ]);

  const openProductByBarcode = useCallback(async (code: string) => {
    const normalized = normalizeBarcodeReference(code);
    if (!normalized) {
      return;
    }

    const launchTable = await confirmLaunchTable();
    if (!launchTable) {
      return;
    }

    let found = findProductByBarcode(normalized);
    if (!found) {
      setProductCameraLoading(true);
      try {
        const latestProducts = await api.listProducts(false, { requireRemote: true, forceRemote: true, compact: true });
        found = findProductByBarcodeInList(latestProducts, normalized);
        await refreshMenu({ preferCache: true }).catch(() => null);
      } catch {
        // Mantem a mensagem padrao quando a API nao confirma o produto no catalogo.
      } finally {
        setProductCameraLoading(false);
      }
    }

    if (!found) {
      showSweetAlert('Produto não encontrado', `Não existe produto cadastrado com o código de barras: ${normalized}`);
      return;
    }

    setProductCameraOpen(false);
    setProductManualOpen(false);
    setProductManualText('');
    openLaunchScreen(found);
  }, [confirmLaunchTable, findProductByBarcode, openLaunchScreen, refreshMenu, showSweetAlert]);

  const menuRowKeyExtractor = useCallback((row: MenuItem[], index: number) => {
    const rowKey = row.map((item) => getMenuItemIdentity(item)).join(':');
    return rowKey || `row-${index}`;
  }, []);

  const renderMenuRow = useCallback(
    ({ item: row }: { item: MenuItem[]; index: number }) => {
      return (
        <View style={[styles.menuRow, { height: cardHeight }]}>
          {row.map((item, columnIndex) => (
            <View
              key={`${getMenuItemIdentity(item)}-${columnIndex}`}
              style={[
                styles.menuCell,
                { width: cardWidth, height: cardHeight },
                columnIndex < menuColumns - 1 ? styles.menuCellSpacing : null
              ]}
            >
              <MemoFoodCard
                item={item}
                onOpenItem={openLaunchScreen}
                compactLayout={compactLayout}
                showImageSlot={appSettings.exibirImagem}
                deferImageLoad={deferCardImages}
                happyHourSaleType={happyHourSaleType}
                baseUrl={appSettings.baseUrl}
                empresaId={appSettings.empresaId}
              />
            </View>
          ))}
        </View>
      );
    },
    [
      appSettings.baseUrl,
      appSettings.empresaId,
      appSettings.exibirImagem,
      cardHeight,
      cardWidth,
      compactLayout,
      deferCardImages,
      happyHourSaleType,
      menuColumns,
      openLaunchScreen
    ]
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

  // Botao voltar do Android no Cardapio: vai direto para a tela principal
  // (Inicial), como o botao "Voltar" da tela, em vez do comportamento padrao
  // das abas (que trocaria para a primeira aba, "Mesas em andamento").
  useFocusEffect(
    useCallback(() => {
      const onHardwareBack = () => {
        void goToInitial();
        return true;
      };
      const subscription = BackHandler.addEventListener('hardwareBackPress', onHardwareBack);
      return () => subscription.remove();
    }, [])
  );

  const openPendingItems = () => {
    const params = activeTable?.idVenda ? { idVenda: activeTable.idVenda } : undefined;
    const parent = navigation.getParent<NativeStackNavigationProp<RootStackParams>>();
    if (parent) {
      parent.navigate('ItensPendentes', params as never);
      return;
    }
    navigation.navigate('ItensPendentes', params as never);
  };

  const onProductScanner = useCallback(async (result: BarcodeScanningResult) => {
    if (productCameraBusyRef.current) {
      return;
    }

    const value = normalizeProductCameraBarcode(result);
    if (!value) {
      return;
    }

    productCameraBusyRef.current = true;
    setProductCameraLoading(true);
    try {
      await openProductByBarcode(value);
    } finally {
      productCameraBusyRef.current = false;
      setProductCameraLoading(false);
    }
  }, [openProductByBarcode]);

  const onCameraProduct = useCallback(async () => {
    const launchTable = await confirmLaunchTable();
    if (!launchTable) {
      return;
    }

    const loadedCameraView = CameraViewComponent || getCameraViewComponent();
    if (!loadedCameraView || Platform.OS === 'web') {
      setProductManualText('');
      setProductManualOpen(true);
      return;
    }

    if (!CameraViewComponent) {
      setCameraViewComponent(() => loadedCameraView);
    }

    try {
      if (Platform.OS === 'android') {
        const granted = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.CAMERA,
          {
            title: 'Permitir acesso à câmera',
            message: 'Necessário para ler o código de barras do produto.',
            buttonPositive: 'Permitir',
            buttonNegative: 'Cancelar'
          }
        );

        if (granted !== PermissionsAndroid.RESULTS.GRANTED) {
          setProductManualText('');
          setProductManualOpen(true);
          return;
        }
      }
    } catch {
      setProductManualText('');
      setProductManualOpen(true);
      return;
    }

    productCameraBusyRef.current = false;
    setProductCameraLoading(false);
    setProductCameraOpen(true);
  }, [CameraViewComponent, confirmLaunchTable]);

  const mesaLabel = activeTable ? getTableOrderDisplayLabel(activeTable) : 'Mesa --';
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
    <View style={[styles.container, compactLayout ? styles.containerCompact : null]}>
      <ScreenRouteLabel />
      <View pointerEvents="none" style={styles.heroGlowPrimary} />
      <View pointerEvents="none" style={styles.heroGlowSecondary} />

      <View style={[styles.heroCard, compactLayout ? styles.heroCardCompact : null]}>
        <View style={[styles.heroTopRow, compactLayout ? styles.heroTopRowCompact : null]}>
          <TouchableOpacity
            style={[styles.backBtn, compactLayout ? styles.heroButtonCompact : null]}
            onPress={goToInitial}
            activeOpacity={0.9}
          >
            <Text style={styles.backBtnText}>Voltar</Text>
          </TouchableOpacity>
          <View style={[styles.heroTopActions, compactLayout ? styles.heroTopActionsCompact : null]}>
            <TouchableOpacity
              style={[styles.viewBtn, compactLayout ? styles.heroButtonCompact : null]}
              onPress={openPendingItems}
              activeOpacity={0.9}
            >
              <Text style={styles.viewBtnText}>Itens</Text>
              <Text style={styles.viewBtnCount}>{cart.length}</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.barcodeBtn, compactLayout ? styles.heroButtonCompact : null]}
              onPress={() => void onCameraProduct()}
              activeOpacity={0.9}
            >
              <Text style={styles.barcodeBtnText}>Cod Barra</Text>
            </TouchableOpacity>
            <View
              style={[
                styles.heroStatusBadge,
                compactLayout ? styles.heroButtonCompact : null,
                { borderColor: statusPalette.border, backgroundColor: statusPalette.soft }
              ]}
            >
              <Text style={[styles.heroStatusValue, { color: statusPalette.text }]}>{currentStatusLabel}</Text>
            </View>
          </View>
        </View>

        <View style={styles.heroCopy}>
          <Text style={styles.heroTitle}>{mesaLabel}</Text>
        </View>

        <View style={[styles.searchWrap, compactLayout ? styles.searchWrapCompact : null]}>
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

      <Modal visible={productCameraOpen} transparent animationType="fade" onRequestClose={() => setProductCameraOpen(false)}>
        <View style={styles.readerOverlay}>
          <View style={styles.readerPanel}>
            <Text style={styles.readerTitle}>Leitor de produto</Text>
            <Text style={styles.readerDesc}>Aponte para o código de barras do produto.</Text>
            <View style={styles.cameraFrame}>
              {CameraViewComponent ? (
                <CameraViewComponent
                  style={styles.cameraView}
                  barcodeScannerSettings={{ barcodeTypes: [...PRODUCT_CAMERA_BARCODE_TYPES] }}
                  onBarcodeScanned={productCameraLoading ? undefined : onProductScanner}
                />
              ) : (
                <View style={styles.cameraDisabledWrap}>
                  <Text style={styles.cameraDisabledText}>Leitor por câmera indisponível.</Text>
                  <Text style={styles.cameraDisabledText}>Use o botão Digitar código.</Text>
                </View>
              )}
            </View>
            <View style={styles.readerActions}>
              <TouchableOpacity
                style={styles.readerButton}
                onPress={() => setProductCameraOpen(false)}
                activeOpacity={0.8}
              >
                <Text style={styles.readerButtonText}>Fechar</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.readerButton, styles.readerButtonPrimary]}
                onPress={() => {
                  setProductCameraOpen(false);
                  setProductManualText('');
                  setProductManualOpen(true);
                }}
                activeOpacity={0.8}
              >
                <Text style={styles.readerButtonTextPrimary}>Digitar código</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <Modal visible={productManualOpen} transparent animationType="slide" onRequestClose={() => setProductManualOpen(false)}>
        <View style={styles.readerOverlay}>
          <View style={styles.readerPanel}>
            <Text style={styles.readerTitle}>Código do produto</Text>
            <Text style={styles.readerDesc}>Digite o código do produto para lançar.</Text>
            <TextInput
              style={styles.readerInput}
              value={productManualText}
              onChangeText={setProductManualText}
              placeholder="Ex: 123 ou REF001"
              placeholderTextColor={Colors.textMuted}
              autoCapitalize="none"
              autoCorrect={false}
              returnKeyType="done"
              onSubmitEditing={() => void openProductByBarcode(productManualText)}
            />
            <View style={styles.readerActions}>
              <TouchableOpacity
                style={styles.readerButton}
                onPress={() => setProductManualOpen(false)}
                activeOpacity={0.8}
              >
                <Text style={styles.readerButtonText}>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.readerButton, styles.readerButtonPrimary]}
                onPress={() => void openProductByBarcode(productManualText)}
                activeOpacity={0.8}
              >
                <Text style={styles.readerButtonTextPrimary}>Lançar</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <FlatList
        onLayout={(event) => {
          const nextWidth = Math.floor(event.nativeEvent.layout.width);
          setGridWidth((prev) => (prev === nextWidth ? prev : nextWidth));
        }}
        data={menuRows}
        keyExtractor={menuRowKeyExtractor}
        key={`menu-grid-${menuColumns}`}
        getItemLayout={getMenuItemLayout}
        initialNumToRender={Platform.OS === 'android' ? 3 : 4}
        maxToRenderPerBatch={Platform.OS === 'android' ? 3 : 6}
        updateCellsBatchingPeriod={Platform.OS === 'android' ? 70 : 45}
        windowSize={Platform.OS === 'android' ? 3 : 5}
        removeClippedSubviews={true}
        onScrollBeginDrag={pauseCardImages}
        onMomentumScrollBegin={pauseCardImages}
        onScrollEndDrag={resumeCardImages}
        onMomentumScrollEnd={resumeCardImages}
        scrollEventThrottle={32}
        keyboardShouldPersistTaps="handled"
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
            <View style={[styles.categoryPanel, compactLayout ? styles.categoryPanelCompact : null]}>
              <View style={[styles.categoryPanelHeader, compactLayout ? styles.categoryPanelHeaderCompact : null]}>
                <View>
                  <Text style={[styles.categoryPanelEyebrow, compactLayout ? styles.categoryPanelEyebrowCompact : null]}>
                    NAVEGAÇÃO
                  </Text>
                  <Text style={[styles.categoryPanelTitle, compactLayout ? styles.categoryPanelTitleCompact : null]}>
                    {activeCategoryLabel}
                  </Text>
                </View>
                <Text style={[styles.categoryPanelMeta, compactLayout ? styles.categoryPanelMetaCompact : null]}>
                  {filtered.length} itens
                </Text>
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
        renderItem={renderMenuRow}
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
  containerCompact: {
    paddingHorizontal: 8,
    paddingTop: 8
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
  heroCardCompact: {
    borderRadius: 22,
    padding: 10,
    marginBottom: 10,
    gap: 8
  },
  heroTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: Space.sm
  },
  heroTopRowCompact: {
    alignItems: 'flex-start',
    gap: 6
  },
  heroTopActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8
  },
  heroTopActionsCompact: {
    flex: 1,
    flexWrap: 'wrap',
    justifyContent: 'flex-end',
    gap: 6
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
  barcodeBtn: {
    borderRadius: 18,
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.18)',
    backgroundColor: '#F3F8FC',
    paddingHorizontal: 12,
    paddingVertical: 8,
    ...Shadows.soft
  },
  heroButtonCompact: {
    borderRadius: 14,
    paddingHorizontal: 9,
    paddingVertical: 7
  },
  barcodeBtnText: {
    color: Colors.primary,
    fontWeight: '800',
    fontSize: 12
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
  searchWrapCompact: {
    borderRadius: 14,
    paddingHorizontal: 10
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
  categoryPanelCompact: {
    borderRadius: 20,
    paddingVertical: 10,
    paddingHorizontal: 10
  },
  categoryPanelHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: Space.sm,
    marginBottom: Space.sm
  },
  categoryPanelHeaderCompact: {
    marginBottom: 8
  },
  categoryPanelEyebrow: {
    color: Colors.accent,
    fontSize: 11,
    fontWeight: '900',
    letterSpacing: 0.6,
    marginBottom: 4
  },
  categoryPanelEyebrowCompact: {
    fontSize: 10,
    marginBottom: 2
  },
  categoryPanelTitle: {
    color: Colors.text,
    fontSize: 18,
    fontWeight: '900'
  },
  categoryPanelTitleCompact: {
    fontSize: 16
  },
  categoryPanelMeta: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    paddingTop: 18
  },
  categoryPanelMetaCompact: {
    paddingTop: 14,
    fontSize: 11
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
  readerOverlay: {
    flex: 1,
    backgroundColor: 'rgba(10, 20, 30, 0.65)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: Space.md
  },
  readerPanel: {
    width: '100%',
    maxWidth: 460,
    backgroundColor: Colors.card,
    borderRadius: Radius.lg,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Space.md,
    gap: Space.md,
    ...Shadows.card
  },
  readerTitle: {
    color: Colors.text,
    fontWeight: '900',
    fontSize: 17
  },
  readerDesc: {
    color: Colors.textMuted,
    fontSize: 13
  },
  readerInput: {
    borderRadius: 18,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    color: Colors.text,
    paddingHorizontal: 14,
    paddingVertical: 12
  },
  readerActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10
  },
  readerButton: {
    flex: 1,
    backgroundColor: Colors.cardSoft,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: 12,
    alignItems: 'center'
  },
  readerButtonText: {
    color: Colors.text,
    fontWeight: '700'
  },
  readerButtonPrimary: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
    ...Shadows.button
  },
  readerButtonTextPrimary: {
    color: '#ffffff',
    fontWeight: '800'
  },
  cameraFrame: {
    width: '100%',
    aspectRatio: 1,
    borderRadius: Radius.md,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: '#000'
  },
  cameraView: {
    width: '100%',
    height: '100%'
  },
  cameraDisabledWrap: {
    flex: 1,
    backgroundColor: Colors.background,
    alignItems: 'center',
    justifyContent: 'center',
    padding: Space.md,
    gap: 6
  },
  cameraDisabledText: {
    color: Colors.text,
    textAlign: 'center'
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
  menuRow: {
    flexDirection: 'row',
    alignItems: 'stretch',
    marginBottom: Space.sm
  },
  menuColumnWrapper: {
    justifyContent: 'flex-start',
    alignItems: 'stretch'
  },
  menuCell: {
    alignSelf: 'stretch'
  },
  menuCellSpacing: {
    marginRight: Space.sm
  }
});
