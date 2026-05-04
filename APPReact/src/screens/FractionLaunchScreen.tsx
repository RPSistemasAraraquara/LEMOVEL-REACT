import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Alert, BackHandler, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { CommonActions, RouteProp, useNavigation, useRoute } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { LinkedMesaPickerModal } from '../components/LinkedMesaPickerModal';
import { formatTableStatusLabel, getMenuItemLaunchUnitPrice, getTableOrderDisplayLabel, MenuItem, ProductOptional, TableOrder } from '../services/api';
import { SectionHeader } from '../components/SectionHeader';
import { useApp } from '../context/AppContext';
import { useLinkedMesaBinding } from '../hooks/useLinkedMesaBinding';
import { Colors, Radius, Shadows, Space, Typography } from '../theme';
import { RootStackParams } from '../navigation/AppNavigator';

type LaunchRoute = RouteProp<RootStackParams, 'LancamentoFracionado'>;
type Nav = NativeStackNavigationProp<RootStackParams, 'LancamentoFracionado'>;

type SizeOption = {
  code: string;
  label: string;
  value: number;
};
type ReturnTarget = 'Inicial' | 'Cardapio' | 'Gestao';

const normalizeSizeValue = (value: unknown): number => {
  const asNumber = Number(String(value || 0).replace(',', '.'));
  return Number.isFinite(asNumber) ? asNumber : 0;
};

const roundTo2 = (value: number) => Number(Number(value || 0).toFixed(2));

const getSizeOptions = (
  product: MenuItem,
  getPriceBySize: (item: MenuItem, sizeCode: string) => number
): SizeOption[] => {
  const defaultPrice = getPriceBySize(product, String(product.tamanhoPadrao || ''));
  const hasSizeByFlow = product.vendaPorTamanho;
  if (!hasSizeByFlow) {
    return [{
      code: product.tamanhoPadrao || 'U',
      label: product.tamanhoPadrao || 'Único',
      value: defaultPrice
    }];
  }

  const items = [
    { code: 'P', label: String(product.tamanhoP || '').trim(), rawValue: product.valorTamanhoP },
    { code: 'M', label: String(product.tamanhoM || '').trim(), rawValue: product.valorTamanhoM },
    { code: 'G', label: String(product.tamanhoG || '').trim(), rawValue: product.valorTamanhoG },
    { code: 'GG', label: String(product.tamanhoGG || '').trim(), rawValue: product.valorTamanhoGG },
    { code: 'E', label: String(product.tamanhoExtra || '').trim(), rawValue: product.valorTamanhoExtra }
  ];

  const filtered = items
    .filter((item) => item.label.length > 0 && normalizeSizeValue(item.rawValue) > 0)
    .map((item) => ({
      code: item.code,
      label: item.label,
      value: getPriceBySize(product, item.code)
    }));
  if (filtered.length > 0) {
    return filtered;
  }

  return [{ code: product.tamanhoPadrao || 'M', label: product.tamanhoPadrao || 'M', value: defaultPrice }];
};

const getDefaultSize = (product: MenuItem, sizeOptions: SizeOption[], routeSize?: string) => {
  const route = String(routeSize || '').toUpperCase();
  const direct = sizeOptions.find((item) => item.code.toUpperCase() === route);
  if (direct) {
    return direct.code;
  }

  const first = sizeOptions[0]?.code || 'M';
  const padrao = String(product.tamanhoPadrao || '').toUpperCase();
  if (!padrao) return first;

  const match = sizeOptions.find((item) => item.code.toUpperCase() === padrao || item.code.toUpperCase() === padrao.substring(0, 1));
  return match?.code || first;
};

const goToReturnScreen = (navigation: Nav, returnTo: ReturnTarget, returnCategoryId?: number) => {
  const parent = navigation.getParent();
  const tabParams =
    returnTo === 'Cardapio' && typeof returnCategoryId === 'number'
      ? { screen: 'Cardapio', params: { selectedCategoryId: returnCategoryId } }
      : { screen: returnTo };

  if (returnTo === 'Inicial') {
    const resetToHome = CommonActions.reset({
      index: 0,
      routes: [{ name: 'Inicial' } as never]
    });

    if (parent) {
      parent.dispatch(resetToHome);
      return;
    }

    navigation.dispatch(resetToHome);
    return;
  }

  const targetReset = {
    index: 1,
    routes: [
      { name: 'Inicial' } as never,
      { name: 'Tabs', params: tabParams as never } as never
    ]
  };

  if (parent) {
    try {
      parent.dispatch(CommonActions.reset(targetReset));
      return;
    } catch (error: unknown) {
      void error;
    }
  }

  try {
    navigation.dispatch(CommonActions.reset(targetReset));
    return;
  } catch (error: unknown) {
    void error;
  }

  const fallback = CommonActions.reset({
    index: 0,
    routes: [{ name: 'Inicial' } as never]
  });
  navigation.dispatch(fallback);
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

const getPriceBySize = (product: MenuItem, sizeCode: string): number => {
  if (!product.vendaPorTamanho) {
    return Number(product.valorUnitario || product.valorVenda || 0);
  }

  const candidates: Record<string, unknown> = {
    P: product.valorTamanhoP,
    M: product.valorTamanhoM,
    G: product.valorTamanhoG,
    GG: product.valorTamanhoGG,
    E: product.valorTamanhoExtra,
    EXTRA: product.valorTamanhoExtra
  };

  const sizeKey = String(sizeCode || '').toUpperCase();
  const direct = normalizeSizeValue(candidates[sizeKey]);
  if (direct > 0) return direct;

  const fallbackFromPadrao = candidates[(String(product.tamanhoPadrao || '') || sizeOptionsFallback[0]).toUpperCase()] as unknown;
  const fallback = normalizeSizeValue(fallbackFromPadrao);
  if (fallback > 0) return fallback;

  return Number(product.valorUnitario || product.valorVenda || 0);
};

const sizeOptionsFallback = ['P', 'M', 'G', 'GG', 'E', 'U'];

export const FractionLaunchScreen: React.FC = () => {
  const navigation = useNavigation<Nav>();
  const route = useRoute<LaunchRoute>();
  const product = (route.params?.item || ({} as MenuItem)) as MenuItem;
  const routeTableId = Number(route.params?.tableId || 0);
  const routeTableType = route.params?.tableType === 'comanda' ? 'comanda' : 'mesa';
  const routeTableComandaId = Number(route.params?.tableComandaId || 0);
  const routeTableName = route.params?.tableName?.trim() || '';
  const {
    activeTable,
    addToCart,
    appSettings,
    cart,
    products,
    flushPendingItems,
    getLinkedTableId,
    linkedMesaSelection,
    openTableByCard,
    setActiveTable,
    setLinkedMesaSelection,
    pauseAutoRefresh,
    resumeAutoRefresh
  } = useApp();
  const isReturningRef = useRef(false);
  const returnTo = route.params?.returnTo || 'Cardapio';
  const returnCategoryId =
    typeof route.params?.returnCategoryId === 'number' ? route.params.returnCategoryId : undefined;

  const rawQuantity = Number(route.params?.quantity || 0);
  const totalParts = Math.max(2, Math.floor(Math.max(2, rawQuantity)));
  const fractionQuantity = 1 / totalParts;
  const fractionQuantityLabel = fractionQuantity.toFixed(3);
  const selectedSizeFromRoute = route.params?.size;
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
  const [activeVenda, setActiveVenda] = useState<TableOrder | null>(activeTable || routeTable);
  const tableBindingSource = activeVenda || activeTable || routeTable;
  const happyHourSaleType = useMemo<'mesa' | 'comanda'>(
    () => tableBindingSource?.tipo || (appSettings.modoExibicao === 'comanda' ? 'comanda' : 'mesa'),
    [appSettings.modoExibicao, tableBindingSource?.tipo]
  );
  const getPriceBySize = useCallback((item: MenuItem, sizeCode: string) => {
    return getMenuItemLaunchUnitPrice(item, sizeCode, {
      saleType: happyHourSaleType
    });
  }, [happyHourSaleType]);

  const [selectedSize, setSelectedSize] = useState(() => {
    const options = getSizeOptions(product, getPriceBySize);
    return getDefaultSize(product, options, selectedSizeFromRoute);
  });
  const [observacao, setObservacao] = useState('');
  const [fractionSearch, setFractionSearch] = useState('');
  const [selectedIndex, setSelectedIndex] = useState<number | null>(0);
  const [selectedOptionalQty, setSelectedOptionalQty] = useState<Record<number, number>>({});

  const [fractions, setFractions] = useState<Array<number | null>>(() => {
    const result = Array.from({ length: totalParts }, () => null as number | null);
    if (result.length > 0) {
      result[0] = product.idProduto;
    }
    return result;
  });

  useEffect(() => {
    pauseAutoRefresh();
    return () => {
      resumeAutoRefresh();
    };
  }, [pauseAutoRefresh, resumeAutoRefresh]);

  const sizeOptions = useMemo(() => getSizeOptions(product, getPriceBySize), [getPriceBySize, product]);
  const shouldShowSize = product?.vendaPorTamanho && sizeOptions.some((item) => {
    const sizeValues: Record<string, unknown> = {
      P: product.valorTamanhoP,
      M: product.valorTamanhoM,
      G: product.valorTamanhoG,
      GG: product.valorTamanhoGG,
      E: product.valorTamanhoExtra
    };
    return String(item.label || '').trim().length > 0 && normalizeSizeValue(sizeValues[item.code]) > 0;
  });
  const selectedSizeLabel = useMemo(
    () => sizeOptions.find((item) => item.code === selectedSize)?.label || selectedSize,
    [selectedSize, sizeOptions]
  );

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

  const availableById = useMemo(() => {
    const candidates = products.length > 0 ? products : [product];
    const byCategory = candidates.filter((item) => {
      if (!item || item.b_venda_mobile === false) return false;
      if (item.idProduto <= 0) return false;
      if (!appSettings.utilizaCategorias) return true;
      if (!item.idCategoria || !product.idCategoria) return true;
      return item.idCategoria === product.idCategoria;
    });
    const filteredBySize = byCategory.filter((item) => {
      if (!product.vendaPorTamanho) return true;
      return getPriceBySize(item, selectedSize) > 0;
    });

    const map = new Map<number, MenuItem>();
    filteredBySize.forEach((item) => {
      if (!map.has(item.idProduto)) {
        map.set(item.idProduto, item);
      }
    });
    if (!map.has(product.idProduto)) {
      map.set(product.idProduto, product);
    }
    return map;
  }, [appSettings.utilizaCategorias, products, product, selectedSize]);

  const fractionItems = useMemo(() => {
    return fractions.map((value) => (value ? availableById.get(value) : undefined));
  }, [availableById, fractions]);

  const duplicateCount = useMemo(() => {
    const values = fractions.filter((item) => item !== null);
    return values.length !== new Set(values).size;
  }, [fractions]);

  const selectedIds = useMemo(() => new Set(fractions.filter((id) => id !== null) as number[]), [fractions]);
  const availableFractionOptions = useMemo(() => {
    const query = fractionSearch.trim().toLowerCase();
    const options = Array.from(availableById.values());

    if (!query) {
      return options;
    }

    return options.filter((option) => {
      const descricao = option.descricao?.toLowerCase() || '';
      const descricaoCurta = option.descricaoCurta?.toLowerCase() || '';
      return descricao.includes(query) || descricaoCurta.includes(query);
    });
  }, [availableById, fractionSearch]);
  const optionalSource = useMemo(() => {
    const candidates = products.filter(
      (item) =>
        item.idProduto === product?.idProduto ||
        item.id === product?.idProduto ||
        item.idProduto === product?.id ||
        item.id === product?.id
    );
    const withOptionals = candidates.find((item) => Array.isArray(item.opcionais) && item.opcionais.length > 0);
    return withOptionals || product;
  }, [product, products]);

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
    if (selectedSize === 'P' && optional.valorOpcionalP !== undefined) return Number(optional.valorOpcionalP);
    if (selectedSize === 'M' && optional.valorOpcionalM !== undefined) return Number(optional.valorOpcionalM);
    if (selectedSize === 'G' && optional.valorOpcionalG !== undefined) return Number(optional.valorOpcionalG);
    if (selectedSize === 'GG' && optional.valorOpcionalGG !== undefined) return Number(optional.valorOpcionalGG);
    if ((selectedSize === 'E' || selectedSize === 'EXTRA') && optional.valorOpcionalExtra !== undefined) {
      return Number(optional.valorOpcionalExtra);
    }
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

  const optionalItems = (optionalSource?.opcionais || []).filter(
    (item) => item.descricao || item.opcionalP || item.opcionalM || item.opcionalG || item.opcionalGG || item.opcionalExtra
  );
  const selectedOptionals = optionalItems.filter((item) => (selectedOptionalQty[item.idOpcional] || 0) > 0);
  const optionalsTotalQuantity = selectedOptionals.reduce(
    (acc, optional) => acc + (selectedOptionalQty[optional.idOpcional] || 0),
    0
  );

  const maxUnitPrice = useMemo(() => {
    return Math.max(...fractionItems.map((item) => getPriceBySize(item || product, selectedSize)));
  }, [fractionItems, product, selectedSize]);

  const totals = useMemo(() => {
    return fractionItems.map((item) => {
      const unit = getPriceBySize(item || product, selectedSize);
      const chargedUnit = appSettings.cobrarMaiorValorFracionado ? maxUnitPrice : unit;
      const total = chargedUnit * fractionQuantity;
      return {
        unit,
        total
      };
    });
  }, [appSettings.cobrarMaiorValorFracionado, fractionItems, maxUnitPrice, fractionQuantity, selectedSize, product]);

  const listTotal = useMemo(() => totals.reduce((acc, current) => acc + current.total, 0), [totals]);
  const canSave = fractions.every((id) => id !== null) && !duplicateCount;

  const changeFraction = (index: number, nextProductId: number | null) => {
    setFractions((prev) => {
      const next = [...prev];
      next[index] = nextProductId;
      return next;
    });
    setSelectedIndex(null);
  };

  const onSelectFlavor = (index: number, idProduto: number) => {
    const alreadySelectedInAnotherSlot = idProduto !== fractions[index] && selectedIds.has(idProduto);
    if (alreadySelectedInAnotherSlot) {
      Alert.alert('Sabor repetido', 'Cada fração precisa de um sabor diferente.');
      return;
    }
    changeFraction(index, idProduto);
  };

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
  const ensureActiveSale = async () => {
    const seedTable = activeVenda || activeTable || routeTable;
    if (!seedTable) {
      Alert.alert('Fluxo inválido', 'Selecione uma mesa e abra a venda em Mesas antes de lançar itens.');
      return null;
    }

    if (seedTable.idVenda) {
      setActiveVenda(seedTable);
      return seedTable;
    }

    try {
      const opened = await openTableByCard(seedTable.idMesa, seedTable.nomeMesaComanda, seedTable.tipo);
      setActiveTable(opened);
      setActiveVenda(opened);
      return opened;
    } catch (error: unknown) {
      throw error instanceof Error ? error : new Error('Não foi possível abrir a venda para esta mesa.');
    }
  };

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

  const save = async () => {
    try {
      if (!canSave) {
        Alert.alert('Campos pendentes', 'Selecione um sabor diferente para cada fração.');
        return;
      }

      const opened = await ensureActiveSale();
      const tableSource = opened || activeTable || routeTable;
      const tableId = getLinkedTableId(tableSource);
      const shouldBindMesa = appSettings.vincularComandaComMesa && tableSource?.tipo === 'comanda';
      if (!tableSource || !tableSource.idMesa) {
        Alert.alert('Fluxo inválido', 'Selecione uma mesa antes de lançar itens.');
        return;
      }

      if (!tableId) {
        Alert.alert('Fluxo inválido', 'Selecione uma mesa antes de lançar itens.');
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
      const opc = selectedOptionals.flatMap((optional) => {
        const optionalQty = selectedOptionalQty[optional.idOpcional] || 0;
        if (optionalQty <= 0) return [];
        const value = getOptionalPrice(optional);
        return Array.from({ length: optionalQty }, () => ({
          idOpcional: optional.idOpcional,
          descricao: getOptionalDisplay(optional),
          valor: value,
          gratis: Boolean(optional.gratis)
        }));
      });

      const fractionGroupId = `frac-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
      const fractionPayload = fractionItems.flatMap((selected, index) => {
        if (!selected) {
          return [];
        }

        const basePrice = getPriceBySize(selected, selectedSize);
        const unitPrice = appSettings.cobrarMaiorValorFracionado ? maxUnitPrice : basePrice;
        const scaledOptionals = roundTo2(
          opc.reduce((subtotal, optional) => subtotal + (optional.gratis ? 0 : optional.valor * fractionQuantity), 0)
        );

        return [{
          idProduto: selected.idProduto,
          produtoDescricao: selected.descricao,
          quantidade: fractionQuantity,
          valorUnitario: unitPrice,
          valorTotal: roundTo2(unitPrice * fractionQuantity),
          acrescimo: scaledOptionals,
          observacao: observacao.trim() || undefined,
          descricaoTamanho: `${selectedSizeLabel} (${index + 1}/${totalParts})`,
          opcionais: opc
        }];
      });

      addToCart({
        ...product,
        quantidade: 1,
        descricaoTamanho: selectedSizeLabel,
        tamanho: selectedSize,
        desconto: 0,
        acrescimo: 0,
        observacao: observacao.trim() || undefined,
        idMesaVinculada: linkedMesaId,
        fractionGroupId,
        valorUnitario: appSettings.cobrarMaiorValorFracionado ? maxUnitPrice : getPriceBySize(product, selectedSize),
        opcionais: [],
        fracoes: fractionPayload
      });

      goToProducts(navigation, returnCategoryId);
    } catch (error: unknown) {
      Alert.alert('Erro', error instanceof Error ? error.message : 'Não foi possível adicionar fracionado.');
    }
  };

  if (!product || !sizeOptions.length) return null;

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 100 }}> 
      <SectionHeader
        title=""
        subtitle={`Total de frações: ${totalParts} | 1 fração = ${fractionQuantity.toFixed(3)}`}
        showBadge={false}
        showAccentLine={true}
      />

      <View style={styles.topCard}>
        <Text style={styles.productName}>{product.descricao}</Text>
        <Text style={styles.productDesc}>Escolha um sabor por fração. Não repita o mesmo sabor.</Text>
      </View>

      {tableBindingSource ? (
        <View style={styles.tableCard}>
          <Text style={styles.tableTitle}>Venda ativa</Text>
          <Text style={styles.tableValue}>
            {tableBindingSource.nomeMesaComanda || `${tableBindingSource.tipo === 'comanda' ? 'Comanda' : 'Mesa'} ${tableBindingSource.idMesa}`}
            {tableBindingSource.idVenda ? ` | Venda ${tableBindingSource.idVenda}` : ''}
          </Text>
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
            Os itens fracionados desta comanda serao enviados com o vinculo da mesa escolhida.
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
          <Text style={styles.section}>Tamanho</Text>
          {sizeOptions.map((size) => (
            <Pressable
              key={size.code}
              style={[styles.option, selectedSize === size.code && styles.optionActive]}
              onPress={() => setSelectedSize(size.code)}
            >
              <Text style={[styles.optionText, selectedSize === size.code && styles.optionTextActive]}>
                {size.label}
              </Text>
              <Text style={[styles.optionText, selectedSize === size.code && styles.optionTextActive]}>
                R$ {size.value.toFixed(2)}
              </Text>
            </Pressable>
          ))}
        </>
      )}

      <Text style={styles.section}>Pesquisar sabores</Text>
      <View style={styles.fractionSearchWrap}>
        <Text style={styles.fractionSearchIcon}>⌕</Text>
        <TextInput
          value={fractionSearch}
          onChangeText={setFractionSearch}
          placeholder="Pesquisar sabores"
          placeholderTextColor={Colors.textMuted}
          style={styles.fractionSearchInput}
        />
      </View>

      <Text style={styles.section}>Frações</Text>
      <View style={styles.partsWrap}>
        {fractions.map((fraction, index) => {
          const selectedFlavor = fractionItems[index];
          const isSelected = selectedIndex === index;

          return (
            <View key={`fraction-${index}`} style={styles.fractionCard}>
              <Pressable style={styles.fractionHeader} onPress={() => setSelectedIndex(isSelected ? null : index)}>
                <Text style={styles.fractionTitle}>
                  Fração {index + 1}/{totalParts}
                </Text>
                <Text style={styles.fractionValue}>
                  {selectedFlavor ? `R$ ${totals[index]?.total.toFixed(2) || '0,00'}` : 'Selecionar sabor'}
                </Text>
              </Pressable>

              {selectedFlavor ? (
                <Text style={styles.fractionProduct}>
                  {selectedFlavor.descricao} ({selectedFlavor.valorUnitario || selectedFlavor.valorVenda || 0} / fração)
                </Text>
              ) : (
                <Text style={styles.fractionProduct}>Sem sabor definido</Text>
              )}

              {isSelected && (
                <View style={styles.optionsWrap}>
                  {availableFractionOptions
                    .filter((option) => option.idProduto === fraction || !selectedIds.has(option.idProduto))
                    .map((option) => {
                      const price = getPriceBySize(option, selectedSize);
                      return (
                        <Pressable
                          key={`option-${index}-${option.idProduto}`}
                          style={[
                            styles.optionLine,
                            fraction === option.idProduto && styles.optionLineActive
                          ]}
                          onPress={() => onSelectFlavor(index, option.idProduto)}
                        >
                          <Text style={styles.optionLineTitle}>{option.descricao}</Text>
                          <Text style={styles.optionLinePrice}>R$ {price.toFixed(2)}</Text>
                        </Pressable>
                      );
                    })}
                  {availableFractionOptions.length === 0 ? (
                    <Text style={styles.fractionEmptyText}>Nenhum sabor encontrado.</Text>
                  ) : null}
                  <Pressable style={styles.optionClear} onPress={() => changeFraction(index, null)}>
                    <Text style={styles.optionClearText}>Limpar</Text>
                  </Pressable>
                </View>
              )}
            </View>
          );
        })}
      </View>

      <Text style={styles.section}>Observação</Text>
      <TextInput
        value={observacao}
        onChangeText={setObservacao}
        multiline
        placeholder="Sem cebola, sem molho..."
        style={styles.textarea}
      />

      {optionalItems.length > 0 && (
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

      <View style={styles.summary}>
        <Text style={styles.summaryText}>Total estimado</Text>
        <Text style={styles.summaryTextMuted}>Total: R$ {listTotal.toFixed(2)}</Text>
        <Text style={styles.summaryTextMuted}>Unidade por fração: {fractionQuantity.toFixed(3)}</Text>
        {optionalsTotalQuantity > 0 ? (
          <Text style={styles.summaryTextMuted}>Opcionais selecionados: {optionalsTotalQuantity}</Text>
        ) : null}
      </View>

      <Pressable onPress={save} style={styles.primaryBtn}>
        <Text style={styles.primaryText}>Salvar lançamento fracionado</Text>
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
    marginLeft: 14,
    marginBottom: 0,
    alignSelf: 'flex-start'
  },
  backText: {
    color: Colors.primary,
    fontSize: 28,
    lineHeight: 28,
    fontWeight: '700'
  },
  productName: {
    color: Colors.text,
    fontSize: Typography.subtitle,
    fontWeight: '900'
  },
  productDesc: {
    marginTop: 4,
    color: Colors.textMuted
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
    marginTop: 14,
    marginBottom: 8,
    fontWeight: '700',
    color: Colors.text
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
  option: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    borderRadius: 20,
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
    color: Colors.text,
    fontWeight: '600'
  },
  optionTextActive: {
    color: Colors.primary,
    fontWeight: '700'
  },
  partsWrap: {
    gap: 10
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
    justifyContent: 'space-between'
  },
  fractionTitle: {
    fontWeight: '700',
    color: Colors.text
  },
  fractionValue: {
    color: Colors.textMuted
  },
  fractionProduct: {
    marginTop: 8,
    color: Colors.textMuted
  },
  fractionEmptyText: {
    color: Colors.textMuted,
    fontSize: 13
  },
  optionsWrap: {
    marginTop: 10,
    gap: 6
  },
  optionLine: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 18,
    backgroundColor: Colors.surface,
    padding: 10,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  optionLineActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft
  },
  optionLineTitle: {
    color: Colors.text,
    fontWeight: '700',
    flex: 1,
    marginRight: 12
  },
  optionLinePrice: {
    color: Colors.textMuted
  },
  optionClear: {
    borderWidth: 1,
    borderColor: Colors.danger,
    borderRadius: 18,
    padding: 10,
    alignItems: 'center',
    backgroundColor: '#fff5f5',
    ...Shadows.soft
  },
  optionClearText: {
    color: Colors.danger,
    fontWeight: '700'
  },
  textarea: {
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    borderRadius: 18,
    backgroundColor: Colors.cardSoft,
    minHeight: 84,
    color: Colors.text,
    padding: 12
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
  },
  summary: {
    marginTop: 16,
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
    fontWeight: '700'
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
  }
});
