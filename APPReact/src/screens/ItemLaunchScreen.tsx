import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Alert, BackHandler, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { CommonActions, RouteProp, useNavigation, useRoute } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { LinkedMesaPickerModal } from '../components/LinkedMesaPickerModal';
import { useApp } from '../context/AppContext';
import { useLinkedMesaBinding } from '../hooks/useLinkedMesaBinding';
import {
  api,
  buildMenuItemRestrictedMessage,
  formatTableStatusLabel,
  getTableOrderDisplayLabel,
  getMenuItemLaunchUnitPrice,
  hasMenuItemHappyHourMetadata,
  hasMenuItemRestrictionMetadata,
  isMenuItemRestrictedToday,
  MenuItem,
  ProductOptional,
  TableOrder
} from '../services/api';
import { Colors, Radius, Shadows, Space, Typography } from '../theme';
import { RootStackParams } from '../navigation/AppNavigator';

type LaunchRoute = RouteProp<RootStackParams, 'Lancamento'>;
type Nav = NativeStackNavigationProp<RootStackParams, 'Lancamento'>;

type SizeOption = {
  code: string;
  label: string;
  value: number;
};
type ReturnTarget = 'Inicial' | 'Cardapio' | 'Gestao';

const EMPTY_MENU_ITEM: MenuItem = {
  id: 0,
  idProduto: 0,
  descricao: '',
  valorVenda: 0,
  valorUnitario: 0,
  opcionais: []
};

const roundTo2 = (value: number) => Number(Number(value || 0).toFixed(2));

const normalizeSizeValue = (value: unknown): number => {
  const asNumber = Number(String(value || 0).replace(',', '.'));
  return Number.isFinite(asNumber) ? asNumber : 0;
};

const getConfiguredSizeOptions = (
  product: MenuItem,
  getPriceBySize: (item: MenuItem, sizeCode: string) => number
): SizeOption[] => {
  const items = [
    { code: 'P', label: String(product.tamanhoP || '').trim(), rawValue: product.valorTamanhoP },
    { code: 'M', label: String(product.tamanhoM || '').trim(), rawValue: product.valorTamanhoM },
    { code: 'G', label: String(product.tamanhoG || '').trim(), rawValue: product.valorTamanhoG },
    { code: 'GG', label: String(product.tamanhoGG || '').trim(), rawValue: product.valorTamanhoGG },
    { code: 'E', label: String(product.tamanhoExtra || '').trim(), rawValue: product.valorTamanhoExtra }
  ];

  return items
    .filter((item) => item.label.length > 0 && normalizeSizeValue(item.rawValue) > 0)
    .map((item) => ({
      code: item.code,
      label: item.label,
      value: getPriceBySize(product, item.code)
    }));
};

function sanitizeQuantity(value: string): number {
  const normalized = value.replace(/[^0-9.,-]/g, '').replace(',', '.');
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : 0;
}

function formatDecimal(value: number, decimals = 3): string {
  const fixed = Number(value.toFixed(decimals));
  return String(fixed).replace('.', ',');
}

function normalizeQuantityInputText(raw: string, allowDecimal: boolean): string {
  const cleaned = raw.replace(/[^0-9.,]/g, '').replace(/\./g, ',');
  if (!allowDecimal) {
    return cleaned.replace(/\D/g, '');
  }

  const hasSeparator = cleaned.includes(',');
  const [integerPartRaw = '', ...decimalParts] = cleaned.split(',');
  const integerPart = integerPartRaw.replace(/\D/g, '');
  const decimalPart = decimalParts.join('').replace(/\D/g, '').slice(0, 3);

  return hasSeparator ? `${integerPart},${decimalPart}` : integerPart;
}

function formatQuantityInputValue(value: number, allowDecimal: boolean): string {
  if (allowDecimal) {
    return formatDecimal(value, 3);
  }
  return String(Math.max(1, Math.round(value)));
}

const goToReturnScreen = (navigation: Nav, returnTo: ReturnTarget, returnCategoryId?: number) => {
  const parent = navigation.getParent();
  const tabParams =
    returnTo === 'Cardapio' && typeof returnCategoryId === 'number'
      ? { screen: 'Cardapio', params: { selectedCategoryId: returnCategoryId } }
      : { screen: returnTo };

  if (returnTo === 'Inicial') {
    const resetToHome = () => {
      const action = CommonActions.reset({
        index: 0,
        routes: [{ name: 'Inicial' } as never]
      });

      if (parent) {
        parent.dispatch(action);
        return;
      }

      navigation.dispatch(action);
    };

    if (navigation.canGoBack() || (parent && parent.canGoBack())) {
      resetToHome();
      return;
    }
    resetToHome();
    return;
  }

  const targetReset = {
    index: 1,
    routes: [
      { name: 'Inicial' } as never,
      { name: 'Tabs', params: tabParams as never } as never
    ]
  };

  try {
    if (parent) {
      parent.dispatch(CommonActions.reset(targetReset));
      return;
    }
  } catch (error: unknown) {
    void error;
  }

  try {
    navigation.dispatch(CommonActions.reset(targetReset));
    return;
  } catch (error: unknown) {
    void error;
  }

  navigation.dispatch(
    CommonActions.reset({
      index: 0,
      routes: [{ name: 'Inicial' } as never]
    })
  );
};

const goToProducts = (navigation: Nav, returnCategoryId?: number) => {
  const tabParams =
    typeof returnCategoryId === 'number'
      ? ({ screen: 'Cardapio', params: { selectedCategoryId: returnCategoryId } } as const)
      : ({ screen: 'Cardapio' } as const);
  const targetReset = {
    index: 1,
    routes: [
      { name: 'Inicial' } as never,
      { name: 'Tabs', params: tabParams as never } as never
    ]
  };

  try {
    navigation.dispatch(CommonActions.reset(targetReset));
    return;
  } catch (error: unknown) {
    void error;
  }

  const parent = navigation.getParent();
  if (parent) {
    try {
      parent.dispatch(CommonActions.reset(targetReset));
      return;
    } catch (error: unknown) {
      void error;
    }
  }

  try {
    navigation.navigate('Tabs', tabParams);
  } catch (error: unknown) {
    void error;
    navigation.navigate('Inicial');
  }
};

const goToReturnWithPending = async (
  navigation: Nav,
  returnTo: ReturnTarget,
  returnCategoryId: number | undefined,
  hasPendingItems: boolean,
  flushPendingItems: () => Promise<boolean>
) => {
  void hasPendingItems;
  void flushPendingItems;
  goToReturnScreen(navigation, returnTo, returnCategoryId);
};

export const ItemLaunchScreen: React.FC = () => {
  const navigation = useNavigation<Nav>();
  const route = useRoute<LaunchRoute>();
  const routeProduct = route.params?.item as MenuItem;
  const routeProductId = Number(routeProduct?.idProduto || routeProduct?.id || 0);
  const routeTableId = Number(route.params?.tableId || 0);
  const routeTableType = route.params?.tableType === 'comanda' ? 'comanda' : 'mesa';
  const routeTableComandaId = Number(route.params?.tableComandaId || 0);
  const routeTableName = route.params?.tableName?.trim() || '';
  const {
    addToCart,
    appSettings,
    activeTable,
    cart,
    getLinkedTableId,
    linkedMesaSelection,
    openTableByCard,
    products,
    setActiveTable,
    setLinkedMesaSelection,
    flushPendingItems,
    pauseAutoRefresh,
    resumeAutoRefresh
  } = useApp();
  const isReturningRef = useRef(false);
  const skipNextQuantityConfirmRef = useRef(false);
  const quantityFromRoute = Number(route.params?.quantity);
  const sizeFromRoute = route.params?.size;
  const [quantidade, setQuantidade] = useState(Math.max(1, Number.isFinite(quantityFromRoute) && quantityFromRoute > 0 ? quantityFromRoute : 1));
  const [quantidadeInput, setQuantidadeInput] = useState('1');
  const [flavorCount, setFlavorCount] = useState(1);
  const [observacao, setObservacao] = useState('');
  const [fractionSearchByIndex, setFractionSearchByIndex] = useState<Record<number, string>>({});
  const [selectedOptionalQty, setSelectedOptionalQty] = useState<Record<number, number>>({});
  const [selectedFractionObservation, setSelectedFractionObservation] = useState<Record<number, string>>({});
  const [selectedFractionOptionalQty, setSelectedFractionOptionalQty] = useState<Record<string, number>>({});
  const [loadedProduct, setLoadedProduct] = useState<MenuItem | null>(routeProduct || null);
  const [loadedFractionProducts, setLoadedFractionProducts] = useState<Record<number, MenuItem>>({});
  const [fractions, setFractions] = useState<Array<number | null>>([]);
  const [selectedFractionIndex, setSelectedFractionIndex] = useState<number | null>(null);
  const loadedFractionProductIdsRef = useRef<Record<number, true>>({});
  const routeTable = useMemo<TableOrder | null>(() => {
    if (!routeTableId) return null;
    return {
      idMesa: routeTableId,
      idComanda: routeTableComandaId || undefined,
      nomeMesaComanda: routeTableName || `${routeTableType === 'comanda' ? 'Comanda' : 'Mesa'} ${routeTableId}`,
      situacao: 'Aberta',
      tipo: routeTableType
    };
  }, [routeTableId, routeTableComandaId, routeTableName, routeTableType]);
  const syncedRouteProduct = useMemo<MenuItem | null>(() => {
    if (!routeProduct) return null;

    const candidates = products.filter(
      (item) =>
        item.idProduto === routeProduct.idProduto ||
        item.id === routeProduct.idProduto ||
        item.idProduto === routeProduct.id ||
        item.id === routeProduct.id
    );

    const withOptionals = candidates.find((item) => Array.isArray(item.opcionais) && item.opcionais.length > 0);
    return withOptionals || candidates[0] || null;
  }, [products, routeProduct]);
  const [activeVenda, setActiveVenda] = useState<TableOrder | null>(activeTable);
  const [isOpeningSale, setIsOpeningSale] = useState(false);
  const saleOpenKeyRef = useRef<string>('');
  const returnTo = route.params?.returnTo || 'Cardapio';
  const returnCategoryId =
    typeof route.params?.returnCategoryId === 'number' ? route.params.returnCategoryId : undefined;
  const tableBindingSource = activeVenda || activeTable || routeTable;
  const happyHourSaleType = useMemo<'mesa' | 'comanda'>(
    () => tableBindingSource?.tipo || (appSettings.modoExibicao === 'comanda' ? 'comanda' : 'mesa'),
    [appSettings.modoExibicao, tableBindingSource?.tipo]
  );
  const requiresLinkedMesa = appSettings.vincularComandaComMesa && tableBindingSource?.tipo === 'comanda';
  const preferredLinkedMesaId = useMemo(() => {
    const storedMesaId = Number(linkedMesaSelection?.idMesa || 0);
    if (storedMesaId > 0) {
      return storedMesaId;
    }
    for (let index = cart.length - 1; index >= 0; index -= 1) {
      const mesaId = Number(cart[index]?.idMesaVinculada || 0);
      if (mesaId > 0) {
        return mesaId;
      }
    }
    return 0;
  }, [cart, linkedMesaSelection?.idMesa]);
  const {
    linkedMesa,
    pickerVisible: linkedMesaPickerVisible,
    pickerLoading: linkedMesaPickerLoading,
    pickerTables: linkedMesaPickerTables,
    openPicker: openLinkedMesaPicker,
    closePicker: closeLinkedMesaPicker,
    selectMesa: selectLinkedMesa,
    refreshPickerTables: refreshLinkedMesaPickerTables,
    ensureLinkedMesaSelected
  } = useLinkedMesaBinding({
    enabled: requiresLinkedMesa,
    saleTable: tableBindingSource,
    preferredLinkedMesaId
  });
  const product = useMemo<MenuItem | null>(() => {
    if (!routeProduct) return null;
    if (!loadedProduct) return routeProduct;
    return {
      ...routeProduct,
      ...loadedProduct,
      opcionais:
        loadedProduct.opcionais && loadedProduct.opcionais.length > 0
          ? loadedProduct.opcionais
      : routeProduct.opcionais || []
    };
  }, [loadedProduct, routeProduct]);
  const resolvedProduct = product || routeProduct || EMPTY_MENU_ITEM;

  useEffect(() => {
    setLoadedProduct(syncedRouteProduct || routeProduct || null);
  }, [routeProduct, syncedRouteProduct]);

  useEffect(() => {
    let active = true;
    const shouldRefreshProductRules =
      !hasMenuItemHappyHourMetadata(syncedRouteProduct || routeProduct || null) ||
      !hasMenuItemRestrictionMetadata(syncedRouteProduct || routeProduct || null);

    if (!routeProduct?.idProduto) {
      return () => {
        active = false;
      };
    }

    const hasLocalOptionals =
      (Array.isArray(routeProduct?.opcionais) && routeProduct.opcionais.length > 0) ||
      (Array.isArray(syncedRouteProduct?.opcionais) && syncedRouteProduct.opcionais.length > 0);
    const routeNeedsFullProduct = Boolean(routeProduct?.catalogCompact || syncedRouteProduct?.catalogCompact);

    if (hasLocalOptionals && !shouldRefreshProductRules && !routeNeedsFullProduct) {
      return () => {
        active = false;
      };
    }

    void (async () => {
      try {
        const fetchedProduct = await api.getProduct(routeProduct.idProduto, false);
        if (!active || !fetchedProduct) {
          return;
        }
        setLoadedProduct(fetchedProduct);
      } catch {
        // Mantém o produto já carregado no catálogo.
      }
    })();

    return () => {
      active = false;
    };
  }, [routeProduct?.idProduto, routeProduct?.opcionais, routeProduct?.catalogCompact, syncedRouteProduct]);

  const getPriceBySize = useCallback((item: MenuItem, sizeCode: string) => {
    return getMenuItemLaunchUnitPrice(item, sizeCode, {
      saleType: happyHourSaleType
    });
  }, [happyHourSaleType]);
  const resolveOptionalSource = useCallback((target: MenuItem | null | undefined) => {
    const source = target || product;
    if (!source) return product;

    const candidates = products.filter(
      (item) =>
        item.idProduto === source?.idProduto ||
        item.id === source?.idProduto ||
        item.idProduto === source?.id ||
        item.id === source?.id
    );
    const withOptionals = candidates.find((item) => Array.isArray(item.opcionais) && item.opcionais.length > 0);
    return withOptionals || source;
  }, [product, products]);

  const optionalSource = useMemo(() => resolveOptionalSource(product), [product, resolveOptionalSource]);

  useEffect(() => {
    if (!routeProduct) {
      navigation.goBack();
      return;
    }

    const nextQuantity = Math.max(1, quantityFromRoute > 0 ? quantityFromRoute : 1);

    setQuantidade(nextQuantity);
    setQuantidadeInput(formatQuantityInputValue(nextQuantity, Boolean(routeProduct?.usaQuantidadeDecimal)));
    setFlavorCount(1);
    setObservacao('');
    setFractionSearchByIndex({});
    setSelectedFractionObservation({});
    setSelectedOptionalQty({});
    setSelectedFractionOptionalQty({});
    setLoadedFractionProducts({});
    loadedFractionProductIdsRef.current = {};
    setFractions([]);
    setSelectedFractionIndex(null);
  }, [navigation, quantityFromRoute, routeProductId]);

  useEffect(() => {
    let active = true;

    void (async () => {
      const tableSource = activeTable || routeTable;
      if (!tableSource) return;

      setActiveVenda(tableSource);
      if (tableSource.idVenda) return;

      const openKey = `${tableSource.tipo || 'mesa'}-${tableSource.idMesa}-${tableSource.idVenda || 0}`;
      if (saleOpenKeyRef.current === openKey) return;

      saleOpenKeyRef.current = openKey;
      setIsOpeningSale(true);
      try {
        const opened = await openTableByCard(
          tableSource.idMesa,
          tableSource.nomeMesaComanda,
          tableSource.tipo
        );
        if (!active) return;
        setActiveTable(opened);
        setActiveVenda(opened);
      } catch {
        // A abertura sera tentada novamente ao adicionar o item.
      } finally {
        if (active) {
          setIsOpeningSale(false);
        }
      }
    })();

    return () => {
      active = false;
    };
  }, [activeTable, openTableByCard, routeTable, setActiveTable]);

  useEffect(() => {
    pauseAutoRefresh();
    return () => {
      resumeAutoRefresh();
    };
  }, [pauseAutoRefresh, resumeAutoRefresh]);

  useEffect(() => {
    if (!requiresLinkedMesa || !linkedMesa?.idMesa) {
      return;
    }

    if (Number(linkedMesaSelection?.idMesa || 0) === Number(linkedMesa.idMesa || 0)) {
      return;
    }

    setLinkedMesaSelection(linkedMesa);
  }, [linkedMesa, linkedMesaSelection?.idMesa, requiresLinkedMesa, setLinkedMesaSelection]);

  const handleLinkedMesaSelect = useCallback((table: TableOrder) => {
    selectLinkedMesa(table);
    setLinkedMesaSelection(table);
  }, [selectLinkedMesa, setLinkedMesaSelection]);

  useEffect(() => {
    const handleBack = () => {
      if (isReturningRef.current) {
        return true;
      }
      isReturningRef.current = true;
      void goToReturnWithPending(
        navigation,
        returnTo,
        returnCategoryId,
        cart.length > 0,
        flushPendingItems
      ).finally(() => {
        isReturningRef.current = false;
      });
      return true;
    };

    const backSubscription = BackHandler.addEventListener('hardwareBackPress', handleBack);

      return () => {
        backSubscription.remove();
      };
  }, [navigation, returnTo, returnCategoryId, cart.length, flushPendingItems]);

  useEffect(() => {
    navigation.setOptions({
      title: '',
      headerTitle: () => null,
      headerLeft: () => (
        <Pressable
          onPress={() => {
            if (isReturningRef.current) {
              return;
            }
            isReturningRef.current = true;
            void goToReturnWithPending(
              navigation,
              returnTo,
              returnCategoryId,
              cart.length > 0,
              flushPendingItems
            ).finally(() => {
              isReturningRef.current = false;
            });
          }}
          style={styles.backButton}
        >
          <Text style={styles.backText}>‹</Text>
        </Pressable>
      )
    });
  }, [navigation, returnTo, returnCategoryId, cart.length, flushPendingItems]);

  const ensureActiveSale = async () => {
    const seedTable = activeVenda || activeTable || routeTable;
    if (!seedTable || !seedTable.idMesa) return null;

    if (seedTable.idVenda) {
      setActiveVenda(seedTable);
      return seedTable;
    }

    try {
      setIsOpeningSale(true);
      const opened = await openTableByCard(seedTable.idMesa, seedTable.nomeMesaComanda, seedTable.tipo);
      setActiveTable(opened);
      setActiveVenda(opened);
      return opened;
    } finally {
      setIsOpeningSale(false);
    }
  };

  const sizeOptions = useMemo<SizeOption[]>(() => {
    const defaultPrice = getPriceBySize(resolvedProduct, String(resolvedProduct.tamanhoPadrao || ''));
    const hasSizeByFlow = resolvedProduct.vendaPorTamanho;

    if (!hasSizeByFlow) {
      return [{
        code: resolvedProduct.tamanhoPadrao || 'U',
        label: resolvedProduct.tamanhoPadrao || 'Único',
        value: defaultPrice
      }];
    }

    const filtered = getConfiguredSizeOptions(resolvedProduct, getPriceBySize);
    if (filtered.length > 0) {
      return filtered;
    }

    return [{ code: resolvedProduct.tamanhoPadrao || 'M', label: resolvedProduct.tamanhoPadrao || 'M', value: defaultPrice }];
  }, [getPriceBySize, resolvedProduct]);

  const hasConfiguredSizeOptions = useMemo(() => {
    if (!resolvedProduct.vendaPorTamanho) {
      return false;
    }

    return getConfiguredSizeOptions(resolvedProduct, getPriceBySize).length > 0;
  }, [getPriceBySize, resolvedProduct]);

  const defaultSelectedSize = useMemo(() => {
    const routeSize = String(sizeFromRoute || '').toUpperCase();
    const directMatch = sizeOptions.find((item) => item.code.toUpperCase() === routeSize);
    if (directMatch) {
      return directMatch.code;
    }

    const first = sizeOptions[0]?.code || 'M';
    const padrao = String(resolvedProduct.tamanhoPadrao || '').toUpperCase();
    if (!padrao) return first;
    const match = sizeOptions.find((item) => item.code.toUpperCase() === padrao || item.code.toUpperCase() === padrao.substring(0, 1));
    return match?.code || first;
  }, [resolvedProduct.tamanhoPadrao, sizeFromRoute, sizeOptions]);

  const [selectedSize, setSelectedSize] = useState(defaultSelectedSize);

  const selectedSizeLabel = sizeOptions.find((item) => item.code === selectedSize)?.label || '';
  const selectedPrice = sizeOptions.find((item) => item.code === selectedSize)?.value || 0;
  const productSupportLabel = resolvedProduct.descricaoCurta?.trim() || '';
  const currentObservationLabel = observacao.trim();
  const shouldShowSize = hasConfiguredSizeOptions;
  const currentSizeLabel = shouldShowSize ? selectedSizeLabel || selectedSize || resolvedProduct.tamanhoPadrao || 'Padrão' : '';
  const sizePayloadLabel = shouldShowSize ? selectedSizeLabel || selectedSize : '';
  const sizePayloadCode = shouldShowSize ? selectedSize : '';

  const getOptionalDisplay = (optional: ProductOptional): string => {
    if (!product?.vendaPorTamanho) {
      return String(optional.descricao || '');
    }
    if (selectedSize === 'P' && optional.opcionalP) return optional.opcionalP;
    if (selectedSize === 'M' && optional.opcionalM) return optional.opcionalM;
    if (selectedSize === 'G' && optional.opcionalG) return optional.opcionalG;
    if (selectedSize === 'GG' && optional.opcionalGG) return optional.opcionalGG;
    if ((selectedSize === 'E' || selectedSize === 'EXTRA') && optional.opcionalExtra) return optional.opcionalExtra;
    return String(optional.descricao || '');
  };

  const getOptionalPrice = (optional: ProductOptional): number => {
    if ((selectedSize === 'EXTRA') && optional.valorOpcionalExtra !== undefined) return Number(optional.valorOpcionalExtra);
    if (selectedSize === 'P' && optional.valorOpcionalP !== undefined) return Number(optional.valorOpcionalP);
    if (selectedSize === 'M' && optional.valorOpcionalM !== undefined) return Number(optional.valorOpcionalM);
    if (selectedSize === 'G' && optional.valorOpcionalG !== undefined) return Number(optional.valorOpcionalG);
    if (selectedSize === 'GG' && optional.valorOpcionalGG !== undefined) return Number(optional.valorOpcionalGG);
    if ((selectedSize === 'E' || selectedSize === 'EXTRA') && optional.valorOpcionalExtra !== undefined) return Number(optional.valorOpcionalExtra);
    return Number(optional.valor || 0);
  };

  const changeOptionalQuantity = (optional: ProductOptional, delta: number) => {
    setSelectedOptionalQty((prev) => {
      const current = prev[optional.idOpcional] || 0;
      const next = Math.max(0, current + delta);
      if (next <= 0) {
        const nextMap = { ...prev };
        delete nextMap[optional.idOpcional];
        return nextMap;
      }
      return {
        ...prev,
        [optional.idOpcional]: next
      };
    });
  };

  const changeFractionObservation = (index: number, value: string) => {
    setSelectedFractionObservation((prev) => ({
      ...prev,
      [index]: value
    }));
  };

  const getFractionOptionalKey = (index: number, optionalId: number) => `${index}:${optionalId}`;

  const getFractionOptionalQuantity = (index: number, optionalId: number) =>
    selectedFractionOptionalQty[getFractionOptionalKey(index, optionalId)] || 0;

  const changeFractionOptionalQuantity = (index: number, optional: ProductOptional, delta: number) => {
    const key = getFractionOptionalKey(index, optional.idOpcional);
    setSelectedFractionOptionalQty((prev) => {
      const current = prev[key] || 0;
      const next = Math.max(0, current + delta);
      if (next <= 0) {
        const nextMap = { ...prev };
        delete nextMap[key];
        return nextMap;
      }
      return {
        ...prev,
        [key]: next
      };
    });
  };

  const clearFractionOptionals = (index: number) => {
    setSelectedFractionOptionalQty((prev) => Object.fromEntries(
      Object.entries(prev).filter(([key]) => !key.startsWith(`${index}:`))
    ));
  };

  const optionalItems = (optionalSource?.opcionais || []).filter(
    (item) => item.descricao || item.opcionalP || item.opcionalM || item.opcionalG || item.opcionalGG || item.opcionalExtra
  );
  const selectedOptionals = optionalItems.filter((item) => (selectedOptionalQty[item.idOpcional] || 0) > 0);
  const optionalsTotalQuantity = selectedOptionals.reduce((acc, optional) => acc + (selectedOptionalQty[optional.idOpcional] || 0), 0);

  const optionalTotal = selectedOptionals.reduce((acc, optional) => {
    const value = getOptionalPrice(optional);
    const optionalQty = selectedOptionalQty[optional.idOpcional] || 0;
    if (!Number.isFinite(value) || value < 0 || optionalQty <= 0) return acc;
    return acc + value * optionalQty * quantidade;
  }, 0);

  const lineTotal = (selectedPrice * quantidade + optionalTotal);
  const shouldShowFlavorCount = Boolean(resolvedProduct.permiteFracao);
  const selectedFlavorCount = shouldShowFlavorCount ? flavorCount : 1;
  const fractionMode = shouldShowFlavorCount && selectedFlavorCount > 1;

  useEffect(() => {
    if (!fractionMode) {
      setFractions([]);
      setSelectedFractionIndex(null);
      setSelectedFractionOptionalQty({});
      return;
    }

    setFractions((prev) => {
      const next = Array.from({ length: selectedFlavorCount }, (_, index) => prev[index] ?? null);
      if (!next[0]) {
        next[0] = resolvedProduct.idProduto;
      }
      return next;
    });
  }, [fractionMode, resolvedProduct.idProduto, selectedFlavorCount]);

  const availableById = useMemo(() => {
    const candidates = products.length > 0 ? products : [resolvedProduct];
    const byCategory = candidates.filter((item) => {
      if (!item || item.b_venda_mobile === false) return false;
      if (item.idProduto <= 0) return false;
      if (!appSettings.utilizaCategorias) return true;
      if (!item.idCategoria || !resolvedProduct.idCategoria) return true;
      return item.idCategoria === resolvedProduct.idCategoria;
    });
    const filteredBySize = byCategory.filter((item) => {
      if (!resolvedProduct.vendaPorTamanho) return true;
      return getPriceBySize(item, selectedSize) > 0;
    });

    const map = new Map<number, MenuItem>();
    filteredBySize.forEach((item) => {
      if (!map.has(item.idProduto)) {
        map.set(item.idProduto, item);
      }
    });
    if (!map.has(resolvedProduct.idProduto)) {
      map.set(resolvedProduct.idProduto, resolvedProduct);
    }
    return map;
  }, [appSettings.utilizaCategorias, getPriceBySize, products, resolvedProduct, selectedSize]);

  const mergeFractionProductDetails = useCallback((nextProduct: MenuItem) => {
    setLoadedFractionProducts((prev) => {
      const current = prev[nextProduct.idProduto];
      const baseProduct = availableById.get(nextProduct.idProduto);
      return {
        ...prev,
        [nextProduct.idProduto]: {
          ...(baseProduct || {}),
          ...(current || {}),
          ...nextProduct,
          opcionais:
            nextProduct.opcionais && nextProduct.opcionais.length > 0
              ? nextProduct.opcionais
              : current?.opcionais || baseProduct?.opcionais || []
        }
      };
    });
  }, [availableById]);

  const loadFractionProductDetails = useCallback(async (idProduto: number) => {
    if (loadedFractionProductIdsRef.current[idProduto]) {
      return;
    }

    const cached = loadedFractionProducts[idProduto];
    const baseProduct = availableById.get(idProduto);
    const shouldRefreshProductRules =
      !hasMenuItemHappyHourMetadata(cached || baseProduct || null) ||
      !hasMenuItemRestrictionMetadata(cached || baseProduct || null);

    if (cached?.opcionais && cached.opcionais.length > 0 && !shouldRefreshProductRules && !cached.catalogCompact) {
      loadedFractionProductIdsRef.current[idProduto] = true;
      return;
    }

    if (baseProduct?.opcionais && baseProduct.opcionais.length > 0 && !shouldRefreshProductRules && !baseProduct.catalogCompact) {
      loadedFractionProductIdsRef.current[idProduto] = true;
      mergeFractionProductDetails(baseProduct);
      return;
    }

    loadedFractionProductIdsRef.current[idProduto] = true;

    try {
      const fetchedProduct = await api.getProduct(idProduto, false);
      if (fetchedProduct) {
        mergeFractionProductDetails(fetchedProduct);
      }
    } catch {
      // Mantém o melhor dado já disponível para a fração.
    }
  }, [availableById, loadedFractionProducts, mergeFractionProductDetails]);

  useEffect(() => {
    const selectedIds = fractions.filter((id): id is number => id !== null && id !== resolvedProduct.idProduto);
    selectedIds.forEach((id) => {
      void loadFractionProductDetails(id);
    });
  }, [fractions, loadFractionProductDetails, resolvedProduct.idProduto]);

  const availableFractionOptions = useMemo(() => {
    return Array.from(availableById.values());
  }, [availableById]);

  const fractionItems = useMemo(
    () => fractions.map((value) => (value ? availableById.get(value) : undefined)),
    [availableById, fractions]
  );
  const findRestrictedLaunchProduct = useCallback(() => {
    if (isMenuItemRestrictedToday(resolvedProduct)) {
      return resolvedProduct;
    }

    if (!fractionMode) {
      return null;
    }

    return fractionItems.find((item): item is MenuItem => Boolean(item && isMenuItemRestrictedToday(item))) || null;
  }, [fractionItems, fractionMode, resolvedProduct]);
  const fractionOptionalItemsByIndex = fractionItems.map((item) => {
    const source = item ? loadedFractionProducts[item.idProduto] || resolveOptionalSource(item) : null;
    return (source?.opcionais || []).filter(
      (optional) =>
        optional.descricao ||
        optional.opcionalP ||
        optional.opcionalM ||
        optional.opcionalG ||
        optional.opcionalGG ||
        optional.opcionalExtra
    );
  });
  const hasDuplicateFractions = useMemo(() => {
    const values = fractions.filter((item): item is number => item !== null);
    return values.length !== new Set(values).size;
  }, [fractions]);
  const fractionOrderCount = fractionMode ? Math.max(1, Math.round(quantidade)) : 1;
  const fractionQuantity = selectedFlavorCount > 0 ? Number((1 / selectedFlavorCount).toFixed(3)) : 0;
  const fractionOptionalsTotalQuantity = fractionOptionalItemsByIndex.reduce((acc, optionals, index) => {
    return acc + optionals.reduce((subtotal, optional) => subtotal + getFractionOptionalQuantity(index, optional.idOpcional), 0);
  }, 0);
  const fractionOptionalTotal = fractionOptionalItemsByIndex.reduce((acc, optionals, index) => {
    return acc + optionals.reduce((subtotal, optional) => {
      const value = getOptionalPrice(optional);
      const optionalQty = getFractionOptionalQuantity(index, optional.idOpcional);
      if (!Number.isFinite(value) || value < 0 || optionalQty <= 0) return subtotal;
      return subtotal + value * optionalQty * fractionQuantity * fractionOrderCount;
    }, 0);
  }, 0);
  const maxFractionUnitPrice = useMemo(() => {
    const values = fractionItems
      .map((item) => getPriceBySize(item || resolvedProduct, selectedSize))
      .filter((price) => Number.isFinite(price) && price > 0);
    if (!values.length) return getPriceBySize(resolvedProduct, selectedSize);
    return Math.max(...values);
  }, [fractionItems, getPriceBySize, resolvedProduct, selectedSize]);
  const fractionEstimatedTotal = useMemo(() => {
    if (!fractionMode) return lineTotal;
    const total = fractionItems.reduce((acc, item) => {
      if (!item) return acc;
      const baseUnit = getPriceBySize(item, selectedSize);
      const unit = appSettings.cobrarMaiorValorFracionado ? maxFractionUnitPrice : baseUnit;
      return acc + unit * fractionQuantity;
    }, 0);
    return total * fractionOrderCount + fractionOptionalTotal;
  }, [
    appSettings.cobrarMaiorValorFracionado,
    fractionItems,
    fractionMode,
    fractionOptionalTotal,
    fractionOrderCount,
    fractionQuantity,
    lineTotal,
    maxFractionUnitPrice,
    selectedSize
  ]);

  const buildOptionalsPayload = (items: ProductOptional[], getQuantity: (optionalId: number) => number) => {
    return items.flatMap((optional) => {
      const optionalQty = getQuantity(optional.idOpcional);
      if (optionalQty <= 0) return [] as Array<{
        idOpcional: number;
        descricao: string;
        valor: number;
        gratis: boolean;
      }>;
      return Array.from({ length: optionalQty }, () => ({
        idOpcional: optional.idOpcional,
        descricao: getOptionalDisplay(optional) || optional.descricao,
        valor: getOptionalPrice(optional),
        gratis: Boolean(optional.gratis)
      }));
    });
  };

  const onSelectFractionFlavor = (index: number, idProduto: number) => {
    if (index === 0) {
      return;
    }

    const selectedProduct = availableById.get(idProduto);
    if (selectedProduct && isMenuItemRestrictedToday(selectedProduct)) {
      Alert.alert('Item restrito', buildMenuItemRestrictedMessage(selectedProduct));
      return;
    }

    const next = [...fractions];
    const currentValue = next[index] ?? null;
    const duplicateIndex = next.findIndex((value, currentIndex) => currentIndex !== index && value === idProduto);

    if (duplicateIndex === 0) {
      return;
    }

    next[index] = idProduto;
    if (duplicateIndex >= 0) {
      next[duplicateIndex] = currentValue;
    }

    setFractions(next);
    void loadFractionProductDetails(idProduto);
    if (duplicateIndex >= 0 && currentValue && currentValue !== resolvedProduct.idProduto) {
      void loadFractionProductDetails(currentValue);
    }
    clearFractionOptionals(index);
    if (duplicateIndex >= 0) {
      clearFractionOptionals(duplicateIndex);
    }
    setFractionSearchByIndex((prev) => {
      const nextSearch = { ...prev };
      delete nextSearch[index];
      if (duplicateIndex >= 0) {
        delete nextSearch[duplicateIndex];
      }
      return nextSearch;
    });
    setSelectedFractionIndex(null);
  };

  const clearFractionFlavor = (index: number) => {
    setFractions((prev) => {
      const next = [...prev];
      next[index] = index === 0 ? resolvedProduct.idProduto : null;
      return next;
    });
    clearFractionOptionals(index);
    setFractionSearchByIndex((prev) => {
      const nextSearch = { ...prev };
      delete nextSearch[index];
      return nextSearch;
    });
  };

  const allowDecimalQuantity = Boolean(resolvedProduct.usaQuantidadeDecimal);
  const step = allowDecimalQuantity ? 0.25 : 1;

  const changeQuantity = (next: number) => {
    if (allowDecimalQuantity) {
      const normalized = Math.max(step, Number(next.toFixed(3)));
      setQuantidade(normalized);
      setQuantidadeInput(formatQuantityInputValue(normalized, true));
      return;
    }

    const normalized = Math.max(1, Math.round(next));
    setQuantidade(normalized);
    setQuantidadeInput(String(Math.max(1, Math.round(next))));
  };

  const changeQuantityByStep = (delta: number) => {
    skipNextQuantityConfirmRef.current = true;
    changeQuantity(quantidade + delta);
  };

  const setQuantityByText = (raw: string) => {
    const normalizedInput = normalizeQuantityInputText(raw, allowDecimalQuantity);
    setQuantidadeInput(normalizedInput);
    const next = sanitizeQuantity(normalizedInput);
    const lower = allowDecimalQuantity ? next : Math.max(1, Math.floor(next));
    const normalized = allowDecimalQuantity ? Number(lower.toFixed(3)) : Math.max(1, Math.round(lower));
    setQuantidade(normalized <= 0 ? (allowDecimalQuantity ? step : 1) : normalized);
  };

  const confirmQuantity = () => {
    if (skipNextQuantityConfirmRef.current) {
      skipNextQuantityConfirmRef.current = false;
      return;
    }
    if (allowDecimalQuantity) {
      const next = sanitizeQuantity(quantidadeInput);
      changeQuantity(Math.max(step, next || step));
      return;
    }
    const next = parseInt(quantidadeInput, 10);
    changeQuantity(Number.isFinite(next) ? next : 1);
  };

  const onAdd = async () => {
    try {
      const restrictedProduct = findRestrictedLaunchProduct();
      if (restrictedProduct) {
        Alert.alert('Item restrito', buildMenuItemRestrictedMessage(restrictedProduct));
        return;
      }

      const opened = await ensureActiveSale();
      const tableSource = opened || activeVenda || activeTable || routeTable;
      const tableId = getLinkedTableId(tableSource);
      const shouldBindMesa = appSettings.vincularComandaComMesa && tableSource?.tipo === 'comanda';

      if (!tableSource || !tableSource.idMesa) {
        Alert.alert('Fluxo inválido', 'Selecione uma mesa antes de lançar itens.');
        return;
      }

      if (!tableId) {
        Alert.alert('Fluxo inválido', 'Mesa ativa inválida.');
        return;
      }

      if (shouldBindMesa) {
        const hasLinkedMesa = await ensureLinkedMesaSelected();
        if (!hasLinkedMesa) {
          Alert.alert('Mesa vinculada', 'Selecione a mesa vinculada antes de lançar itens nesta comanda.');
          return;
        }
      }

      const linkedMesaId = shouldBindMesa ? Number(linkedMesa?.idMesa || 0) : 0;
      const opc = buildOptionalsPayload(selectedOptionals, (optionalId) => selectedOptionalQty[optionalId] || 0);

      const shouldLaunchFraction = shouldShowFlavorCount &&
        selectedFlavorCount > 1 &&
        Number.isInteger(selectedFlavorCount) &&
        (resolvedProduct.vendaPorTamanho || resolvedProduct.permiteFracao);
      if (shouldLaunchFraction) {
        if (
          fractions.length !== selectedFlavorCount ||
          fractions.some((id) => id === null) ||
          hasDuplicateFractions
        ) {
          Alert.alert('Campos pendentes', 'Selecione um sabor para cada fração antes de adicionar.');
          return;
        }

        const maxUnitPrice = Math.max(
          ...fractions.map((id) => {
            const selected = id ? availableById.get(id) : undefined;
            return getPriceBySize(selected || resolvedProduct, selectedSize);
          })
        );

        const buildFractionPayload = () =>
          fractions.flatMap((selectedId, index) => {
            if (!selectedId) {
              return [];
            }

            const selectedProduct = availableById.get(selectedId) || resolvedProduct;
            const baseUnit = getPriceBySize(selectedProduct, selectedSize);
            const unitPrice = appSettings.cobrarMaiorValorFracionado ? maxUnitPrice : baseUnit;
            const fractionOpc = buildOptionalsPayload(
              fractionOptionalItemsByIndex[index] || [],
              (optionalId) => getFractionOptionalQuantity(index, optionalId)
            );
            const fractionObservation = (selectedFractionObservation[index] || '').trim();
            const scaledAddition = roundTo2(
              fractionOpc.reduce(
                (subtotal, optional) => subtotal + (optional.gratis ? 0 : optional.valor * fractionQuantity),
                0
              )
            );

            return [{
              idProduto: selectedProduct.idProduto,
              produtoDescricao: selectedProduct.descricao,
              quantidade: fractionQuantity,
              valorUnitario: unitPrice,
              valorTotal: roundTo2(unitPrice * fractionQuantity),
              acrescimo: scaledAddition,
              observacao: fractionObservation || undefined,
              descricaoTamanho: sizePayloadLabel ? `${sizePayloadLabel} (${index + 1}/${selectedFlavorCount})` : '',
              opcionais: fractionOpc
            }];
          });

        for (let launchIndex = 0; launchIndex < fractionOrderCount; launchIndex += 1) {
          const fractionGroupId = `frac-${Date.now()}-${launchIndex}-${Math.random().toString(36).slice(2, 10)}`;
          addToCart({
            ...resolvedProduct,
            quantidade: 1,
            descricaoTamanho: sizePayloadLabel,
            tamanho: sizePayloadCode,
            desconto: 0,
            acrescimo: 0,
            observacao: currentObservationLabel || undefined,
            idMesaVinculada: linkedMesaId,
            fractionGroupId,
            valorUnitario: appSettings.cobrarMaiorValorFracionado ? maxUnitPrice : selectedPrice,
            opcionais: [],
            fracoes: buildFractionPayload()
          });
        }

        setFractions([]);
        setSelectedFractionIndex(null);
        setFlavorCount(1);
        setFractionSearchByIndex({});
        goToProducts(navigation, returnCategoryId);
        return;
      }

      addToCart({
        ...resolvedProduct,
        quantidade,
        descricaoTamanho: sizePayloadLabel,
        tamanho: sizePayloadCode,
        desconto: 0,
        acrescimo: 0,
        observacao: currentObservationLabel || undefined,
        idMesaVinculada: linkedMesaId,
        valorUnitario: selectedPrice,
        opcionais: opc
      });

      goToProducts(navigation, returnCategoryId);
    } catch (error: unknown) {
      Alert.alert('Erro', error instanceof Error ? error.message : 'Não foi possível adicionar o item.');
    }
  };

  const priceLineItems = useMemo(() => {
    const totalOptionals = fractionMode ? fractionOptionalTotal : optionalTotal;
    const totalOptionalsQty = fractionMode ? fractionOptionalsTotalQuantity : optionalsTotalQuantity;
    return [
      { label: 'Preço unitário', value: selectedPrice },
      { label: `Qtd. ${quantidade}`, value: selectedPrice * quantidade },
      { label: `Opcionais (${totalOptionalsQty})`, value: totalOptionals }
    ];
  }, [selectedPrice, quantidade, fractionMode, optionalTotal, optionalsTotalQuantity, fractionOptionalTotal, fractionOptionalsTotalQuantity]);


  const hasActiveSale = Boolean(activeVenda?.idVenda) || Boolean(activeTable?.idVenda);
  if (!product) return null;

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 100 }} keyboardShouldPersistTaps="handled">
      <View style={styles.topCard}>
        <Text style={styles.productName}>{product.descricao}</Text>
        {productSupportLabel ? <Text style={styles.productDesc}>{productSupportLabel}</Text> : null}
        {currentObservationLabel ? (
          <View style={styles.productPreviewBox}>
            <Text style={styles.productPreviewLabel}>Observação atual</Text>
            <Text style={styles.productPreviewValue}>{currentObservationLabel}</Text>
          </View>
        ) : null}
        <View style={styles.productPreviewRow}>
          {shouldShowSize ? (
            <View style={styles.productPreviewPill}>
              <Text style={styles.productPreviewLabel}>Tamanho base</Text>
              <Text style={styles.productPreviewValue}>{currentSizeLabel}</Text>
            </View>
          ) : null}
          <View style={styles.productPreviewPill}>
            <Text style={styles.productPreviewLabel}>Valor de lista</Text>
            <Text style={styles.productPreviewValue}>R$ {selectedPrice.toFixed(2)}</Text>
          </View>
        </View>
      </View>

      {tableBindingSource && (
        <View style={styles.tableCard}>
          <Text style={styles.tableTitle}>Venda ativa</Text>
          <Text style={styles.tableValue}>
            {tableBindingSource.nomeMesaComanda || `${tableBindingSource.tipo === 'comanda' ? 'Comanda' : 'Mesa'} ${tableBindingSource.idMesa}`}
            {tableBindingSource.idVenda ? ` | Venda ${tableBindingSource.idVenda}` : ''}
          </Text>
        </View>
      )}

      {!hasActiveSale && isOpeningSale ? (
        <View style={styles.tableCard}>
          <Text style={styles.tableTitle}>Abrindo venda</Text>
          <Text style={styles.tableValue}>Aguarde, iniciando venda da mesa...</Text>
        </View>
      ) : null}

      {requiresLinkedMesa ? (
        <View style={styles.tableCard}>
          <Text style={styles.tableTitle}>Mesa vinculada aos itens</Text>
          <Text style={styles.tableValue}>
            {linkedMesa
              ? `${getTableOrderDisplayLabel(linkedMesa)}${formatTableStatusLabel(linkedMesa.situacao) ? ` | ${formatTableStatusLabel(linkedMesa.situacao)}` : ''}`
              : 'Nenhuma mesa selecionada para esta comanda.'}
          </Text>
          <Text style={styles.tableHint}>
            Os itens lancados nesta comanda serao enviados com o vinculo da mesa escolhida.
          </Text>
          <View style={styles.tableActionRow}>
            <Pressable style={styles.tableActionButton} onPress={() => void openLinkedMesaPicker()}>
              <Text style={styles.tableActionButtonText}>{linkedMesa ? 'Trocar mesa' : 'Escolher mesa'}</Text>
            </Pressable>
          </View>
        </View>
      ) : null}

      {shouldShowSize && (
        <>
          <Text style={styles.section}>{fractionMode ? 'Tamanho do sabor principal' : 'Escolha o tamanho'}</Text>
          {fractionMode ? <Text style={styles.summaryTextMuted}>As demais frações usam o mesmo tamanho do principal.</Text> : null}
          {sizeOptions.map((size) => {
            const active = size.code === selectedSize;
            return (
              <Pressable
                key={size.code}
                style={[styles.option, active && styles.optionActive]}
                onPress={() => setSelectedSize(size.code)}
              >
                <Text style={[styles.optionText, active && styles.optionTextActive]}>{size.label}</Text>
                <Text style={[styles.optionText, active && styles.optionTextActive]}>R$ {size.value.toFixed(2)}</Text>
              </Pressable>
            );
          })}
        </>
      )}

      <Text style={styles.section}>Quantidade</Text>
      <View style={styles.quantityWrap}>
        <Pressable style={styles.qtyBtn} onPress={() => changeQuantityByStep(-step)}>
          <Text style={styles.qtyBtnText}>-</Text>
        </Pressable>
        <TextInput
          value={quantidadeInput}
          onChangeText={setQuantityByText}
          onEndEditing={confirmQuantity}
          onBlur={confirmQuantity}
          keyboardType={allowDecimalQuantity ? 'decimal-pad' : 'number-pad'}
          style={styles.qtyInput}
        />
        <Pressable style={styles.qtyBtn} onPress={() => changeQuantityByStep(step)}>
          <Text style={styles.qtyBtnText}>+</Text>
        </Pressable>
      </View>

      {!fractionMode ? (
        <>
          <Text style={styles.section}>Observação</Text>
          <TextInput
            value={observacao}
            onChangeText={setObservacao}
            placeholder="Sem cebola, sem molho..."
            multiline
            style={styles.textarea}
          />
        </>
      ) : null}

      {!fractionMode && optionalItems.length > 0 && (
        <>
          <Text style={styles.section}>Opcionais</Text>
          {optionalItems.map((optional) => {
            const optionalQty = selectedOptionalQty[optional.idOpcional] || 0;
            return (
              <View key={optional.idOpcional} style={styles.optionalRow}>
                <View>
                  <Text style={styles.optionalLabel}>{getOptionalDisplay(optional) || optional.descricao}</Text>
                  <Text style={styles.optionalPrice}>R$ {getOptionalPrice(optional).toFixed(2)}</Text>
                </View>
                <View style={styles.qtyControl}>
                  <Pressable style={styles.qtyBtnSmall} onPress={() => changeOptionalQuantity(optional, -1)}>
                    <Text style={styles.qtyBtnSmallText}>-</Text>
                  </Pressable>
                  <Text style={styles.optionalQty}>{optionalQty}</Text>
                  <Pressable style={styles.qtyBtnSmall} onPress={() => changeOptionalQuantity(optional, 1)}>
                    <Text style={styles.qtyBtnSmallText}>+</Text>
                  </Pressable>
                </View>
              </View>
            );
          })}
        </>
      )}

      {shouldShowFlavorCount && (
        <>
          <Text style={styles.section}>Quantos sabores?</Text>
          <View style={styles.flavorCountWrap}>
            {Array.from({ length: 4 }).map((_, index) => {
              const value = index + 1;
              const active = value === flavorCount;
              return (
                <Pressable
                  key={`flavor-${value}`}
                  style={[styles.flavorOption, active && styles.flavorOptionActive]}
                  onPress={() => setFlavorCount(value)}
                >
                  <Text style={[styles.flavorOptionText, active && styles.flavorOptionTextActive]}>{value}</Text>
                </Pressable>
              );
            })}
          </View>
        </>
      )}

      {fractionMode && (
        <>
          <Text style={styles.section}>Selecione os sabores por fração</Text>
          <View style={styles.fractionWrap}>
            {fractions.map((fraction, index) => {
              const selectedFlavor = fractionItems[index];
              const isPrincipalFraction = index === 0;
              const showFlavorOptions = !isPrincipalFraction && selectedFractionIndex === index;
              const fractionSearch = fractionSearchByIndex[index] || '';
              const fractionOptions = availableFractionOptions.filter((option) => {
                if (option.idProduto === product.idProduto) {
                  return false;
                }
                const query = fractionSearch.trim().toLowerCase();
                if (!query) {
                  return true;
                }
                const descricao = option.descricao?.toLowerCase() || '';
                return descricao.includes(query);
              });
              const baseUnit = getPriceBySize(selectedFlavor || product, selectedSize);
              const chargedUnit = appSettings.cobrarMaiorValorFracionado ? maxFractionUnitPrice : baseUnit;
              const fractionTotal = chargedUnit * fractionQuantity;
              const fractionOptionals = fractionOptionalItemsByIndex[index] || [];
              const fractionObservation = selectedFractionObservation[index] || '';

              return (
                <View key={`fraction-${index}`} style={styles.fractionCard}>
                  <Pressable
                    style={styles.fractionHeader}
                    disabled
                  >
                    <Text style={styles.fractionTitle}>
                      {isPrincipalFraction ? `Fração ${index + 1}/${selectedFlavorCount} • Principal` : `Fração ${index + 1}/${selectedFlavorCount}`}
                    </Text>
                    <Text style={styles.fractionValue}>
                      {selectedFlavor ? `R$ ${fractionTotal.toFixed(2)}` : 'Selecionar sabor'}
                    </Text>
                  </Pressable>

                  <Text style={styles.fractionFlavor}>
                    {selectedFlavor ? selectedFlavor.descricao : 'Sem sabor definido'}
                  </Text>

                  {!isPrincipalFraction ? (
                    <Pressable
                      style={styles.fractionClearBtn}
                      onPress={() => {
                        setSelectedFractionIndex((current) => current === index ? null : index);
                      }}
                    >
                      <Text style={styles.fractionClearText}>
                        {showFlavorOptions ? 'Fechar sabores' : selectedFlavor ? 'Trocar sabor' : 'Selecionar sabor'}
                      </Text>
                    </Pressable>
                  ) : null}

                  {showFlavorOptions && (
                    <View style={styles.fractionOptionsWrap}>
                      <View style={styles.fractionSearchWrap}>
                        <Text style={styles.fractionSearchIcon}>⌕</Text>
                        <TextInput
                          value={fractionSearch}
                          onChangeText={(value) =>
                            setFractionSearchByIndex((prev) => ({
                              ...prev,
                              [index]: value
                            }))
                          }
                          placeholder="Pesquisar sabor pelo nome"
                          placeholderTextColor={Colors.textMuted}
                          style={styles.fractionSearchInput}
                        />
                      </View>
                      {fractionOptions.map((option) => (
                        <Pressable
                          key={`fraction-option-${index}-${option.idProduto}`}
                          style={[
                            styles.fractionOption,
                            fraction === option.idProduto ? styles.fractionOptionActive : null
                          ]}
                          onPress={() => onSelectFractionFlavor(index, option.idProduto)}
                        >
                          <Text style={styles.fractionOptionText}>{option.descricao}</Text>
                          <Text style={styles.fractionOptionPrice}>R$ {getPriceBySize(option, selectedSize).toFixed(2)}</Text>
                        </Pressable>
                      ))}
                      {fractionOptions.length === 0 ? (
                        <Text style={styles.fractionEmptyText}>Nenhum sabor encontrado.</Text>
                      ) : null}
                      {index > 0 ? (
                        <Pressable style={styles.fractionClearBtn} onPress={() => clearFractionFlavor(index)}>
                          <Text style={styles.fractionClearText}>Limpar</Text>
                        </Pressable>
                      ) : null}
                    </View>
                  )}

                  {fractionOptionals.length > 0 ? (
                    <>
                      <Text style={styles.summaryTextMuted}>Opcionais desta fração</Text>
                      {fractionOptionals.map((optional) => {
                        const optionalQty = getFractionOptionalQuantity(index, optional.idOpcional);
                        return (
                          <View key={`fraction-optional-${index}-${optional.idOpcional}`} style={styles.optionalRow}>
                            <View>
                              <Text style={styles.optionalLabel}>{getOptionalDisplay(optional) || optional.descricao}</Text>
                              <Text style={styles.optionalPrice}>R$ {(getOptionalPrice(optional) * fractionQuantity).toFixed(2)}</Text>
                            </View>
                            <View style={styles.qtyControl}>
                              <Pressable style={styles.qtyBtnSmall} onPress={() => changeFractionOptionalQuantity(index, optional, -1)}>
                                <Text style={styles.qtyBtnSmallText}>-</Text>
                              </Pressable>
                              <Text style={styles.optionalQty}>{optionalQty}</Text>
                              <Pressable style={styles.qtyBtnSmall} onPress={() => changeFractionOptionalQuantity(index, optional, 1)}>
                                <Text style={styles.qtyBtnSmallText}>+</Text>
                              </Pressable>
                            </View>
                          </View>
                        );
                      })}
                    </>
                  ) : null}

                  <Text style={styles.summaryTextMuted}>Observação da fração</Text>
                  <TextInput
                    value={fractionObservation}
                    onChangeText={(value) => changeFractionObservation(index, value)}
                    placeholder="Sem cebola, sem molho..."
                    multiline
                    style={styles.textarea}
                  />
                </View>
              );
            })}
          </View>
        </>
      )}

      {fractionMode && fractionOptionalsTotalQuantity > 0 ? (
        <Text style={styles.summaryTextMuted}>Opcionais selecionados nas frações: {fractionOptionalsTotalQuantity}</Text>
      ) : null}

          <View style={styles.summary}>
            <Text style={styles.summaryText}>Subtotal: R$ {(fractionMode ? fractionEstimatedTotal : lineTotal).toFixed(2)}</Text>
            {priceLineItems.map((item) => (
              <View key={item.label} style={styles.summaryRow}>
                <Text style={styles.summaryTextMuted}>{item.label}</Text>
                <Text style={styles.summaryTextMuted}>R$ {item.value.toFixed(2)}</Text>
              </View>
            ))}
          </View>

      <Pressable onPress={onAdd} style={styles.primaryBtn}>
        <Text style={styles.primaryText}>Adicionar ao carrinho</Text>
      </Pressable>

      <LinkedMesaPickerModal
        visible={linkedMesaPickerVisible}
        tables={linkedMesaPickerTables}
        loading={linkedMesaPickerLoading}
        selectedTableId={Number(linkedMesa?.idMesa || preferredLinkedMesaId || 0)}
        onClose={closeLinkedMesaPicker}
        onRefresh={() => {
          void refreshLinkedMesaPickerTables(true);
        }}
        onSelect={handleLinkedMesaSelect}
      />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: Space.md,
    backgroundColor: Colors.background
  },
  topCard: {
    backgroundColor: Colors.card,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Space.md,
    marginBottom: Space.md,
    ...Shadows.card
  },
  backButton: {
    marginLeft: 4,
    marginRight: 10,
    marginBottom: 0,
    alignSelf: 'flex-start',
    width: 34,
    height: 34,
    alignItems: 'center',
    justifyContent: 'center'
  },
  backText: {
    color: Colors.primary,
    fontSize: 34,
    lineHeight: 34,
    fontWeight: '800'
  },
  productName: {
    fontSize: Typography.subtitle,
    color: Colors.text,
    fontWeight: '900'
  },
  productDesc: {
    color: Colors.textMuted,
    marginTop: 4,
    marginBottom: 14
  },
  productPreviewBox: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    borderRadius: 18,
    padding: 12
  },
  productPreviewRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Space.sm,
    marginTop: Space.sm
  },
  productPreviewPill: {
    flexGrow: 1,
    minWidth: 150,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    borderRadius: 18,
    padding: 12
  },
  productPreviewLabel: {
    color: Colors.textMuted,
    fontSize: Typography.caption,
    fontWeight: '700',
    marginBottom: 4,
    textTransform: 'uppercase'
  },
  productPreviewValue: {
    color: Colors.text,
    fontWeight: '700'
  },
  tableCard: {
    borderRadius: 22,
    padding: Space.md,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    marginBottom: Space.md,
    ...Shadows.card
  },
  tableTitle: {
    color: Colors.text,
    fontSize: 12,
    textTransform: 'uppercase',
    fontWeight: '700',
    letterSpacing: 0.3
  },
  tableValue: {
    color: Colors.text,
    marginTop: 4,
    fontWeight: '700'
  },
  tableHint: {
    color: Colors.textMuted,
    marginTop: 8,
    lineHeight: 20
  },
  tableActionRow: {
    flexDirection: 'row',
    marginTop: Space.sm
  },
  tableActionButton: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    paddingHorizontal: 14,
    paddingVertical: 12
  },
  tableActionButtonText: {
    color: Colors.text,
    fontWeight: '800'
  },
  section: {
    marginTop: 12,
    marginBottom: 8,
    color: Colors.text,
    fontWeight: '700'
  },
  option: {
    borderRadius: 20,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    padding: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
    ...Shadows.soft
  },
  optionActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft
  },
  optionText: {
    color: Colors.text
  },
  optionTextActive: {
    color: Colors.primary,
    fontWeight: '700'
  },
  quantityWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 14
  },
  qtyBtn: {
    width: 42,
    height: 40,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.border,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Colors.cardSoft,
    ...Shadows.soft
  },
  qtyBtnText: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: 18
  },
  qtyValue: {
    minWidth: 72,
    textAlign: 'center',
    color: Colors.text,
    fontWeight: '700'
  },
  qtyInput: {
    flex: 1,
    textAlign: 'center',
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    backgroundColor: Colors.cardSoft,
    color: Colors.text,
    borderRadius: 18,
    marginHorizontal: 8,
    fontWeight: '700',
    paddingVertical: 10
  },
  textarea: {
    backgroundColor: Colors.cardSoft,
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    borderRadius: 18,
    padding: 12,
    minHeight: 80,
    color: Colors.text
  },
  row: {
    flexDirection: 'row',
    gap: 10
  },
  input: {
    flex: 1,
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    backgroundColor: Colors.cardSoft,
    borderRadius: 18,
    padding: 12,
    color: Colors.text
  },
  optionalRow: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    borderRadius: 20,
    padding: 10,
    marginBottom: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    ...Shadows.soft
  },
  optionalLabel: {
    color: Colors.text,
    fontWeight: '700'
  },
  optionalPrice: {
    color: Colors.textMuted,
    marginTop: 4,
    fontSize: 12
  },
  optionalCounter: {
    color: Colors.textMuted,
    marginTop: 4,
    fontSize: 11
  },
  flavorCountWrap: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 14,
    flexWrap: 'nowrap'
  },
  flavorOption: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    borderRadius: 20,
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
    ...Shadows.soft
  },
  flavorOptionActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary
  },
  flavorOptionText: {
    color: Colors.text,
    fontWeight: '700'
  },
  flavorOptionTextActive: {
    color: '#fff'
  },
  fractionWrap: {
    gap: 10,
    marginBottom: 8
  },
  fractionSearchWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 18,
    backgroundColor: Colors.card,
    paddingHorizontal: 12,
    marginBottom: 12,
    ...Shadows.soft
  },
  fractionSearchIcon: {
    fontSize: 18,
    color: Colors.primary,
    marginRight: 8
  },
  fractionSearchInput: {
    flex: 1,
    color: Colors.text,
    paddingVertical: 11
  },
  fractionCard: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 20,
    backgroundColor: Colors.card,
    padding: 12,
    ...Shadows.soft
  },
  fractionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  fractionTitle: {
    color: Colors.text,
    fontWeight: '700'
  },
  fractionValue: {
    color: Colors.textMuted,
    fontWeight: '700',
    fontSize: 12
  },
  fractionFlavor: {
    marginTop: 6,
    color: Colors.textMuted
  },
  fractionOptionsWrap: {
    marginTop: 10,
    gap: 6
  },
  fractionEmptyText: {
    color: Colors.textMuted,
    fontSize: 13
  },
  fractionOption: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.sm,
    backgroundColor: Colors.cardSoft,
    padding: 10,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 10
  },
  fractionOptionActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft
  },
  fractionOptionText: {
    color: Colors.text,
    fontWeight: '700',
    flex: 1
  },
  fractionOptionPrice: {
    color: Colors.textMuted,
    fontSize: 12
  },
  fractionClearBtn: {
    marginTop: 6,
    borderWidth: 1,
    borderColor: Colors.warning,
    borderRadius: Radius.sm,
    paddingVertical: 8,
    alignItems: 'center',
    backgroundColor: Colors.warning + '15'
  },
  fractionClearText: {
    color: Colors.warning,
    fontWeight: '700'
  },
  summary: {
    marginTop: 20,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 22,
    backgroundColor: Colors.card,
    padding: 12,
    gap: 4,
    ...Shadows.card
  },
  summaryText: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: 18
  },
  summaryTextMuted: {
    color: Colors.textMuted,
    fontSize: 12
  },
  primaryBtn: {
    marginTop: 14,
    marginBottom: 0,
    backgroundColor: Colors.primary,
    borderRadius: 18,
    padding: 14,
    alignItems: 'center',
    ...Shadows.button
  },
  primaryText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 16,
    lineHeight: 20
  },
  summaryRow: {
    borderTopWidth: 1,
    borderTopColor: '#F5DEC0',
    marginTop: 6,
    paddingTop: 6,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  qtyControl: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8
  },
  qtyBtnSmall: {
    width: 32,
    height: 32,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.cardSoft
  },
  qtyBtnSmallText: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: 18
  },
  optionalQty: {
    minWidth: 20,
    textAlign: 'center',
    color: Colors.text,
    fontWeight: '700'
  }
});
