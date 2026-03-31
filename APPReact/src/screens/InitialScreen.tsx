import React, { useMemo } from 'react';
import {
  Alert,
  FlatList,
  Modal,
  PermissionsAndroid,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  useWindowDimensions,
  View,
  Platform
} from 'react-native';
import { RouteProp, useIsFocused, useNavigation, useRoute } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useApp } from '../context/AppContext';
import { RootStackParams } from '../navigation/AppNavigator';
import { Colors, Radius, Space, Typography } from '../theme';
import { isTableStatusQuickLaunch, isTableStatusReserved, normalizeSaleStatus, TableOrder } from '../services/api';
import { TableCard } from '../components/TableCard';
import { OpenTableNameModal } from '../components/OpenTableNameModal';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { SafeIonicons } from '../components/SafeExpoIcons';

type StackNav = NativeStackNavigationProp<RootStackParams>;
type InitialRoute = RouteProp<RootStackParams, 'Inicial'>;

type TableStatusGroup = 'todas' | 'ocupadas' | 'livres' | 'reservadas';
type FilterItem = {
  key: TableStatusGroup;
  title: string;
};

type BarcodeScanningResult = {
  data?: string | null;
};

const getCameraViewComponent = (): React.ComponentType<any> | null => {
  try {
    const module = require('expo-camera') as { CameraView?: React.ComponentType<any> };
    return module.CameraView || null;
  } catch {
    return null;
  }
};

const VISIBLE_DASHBOARD_REFRESH_MS = 3000;

const statusText = (value: unknown): string => normalizeSaleStatus(value).toLowerCase();

const getFilterPalette = (key: TableStatusGroup) => {
  switch (key) {
    case 'ocupadas':
      return {
        border: '#D8DDF5',
        soft: '#F5F7FF',
        text: '#6D78C7'
      };
    case 'livres':
      return {
        border: '#C7E6D0',
        soft: '#F3FBF5',
        text: '#4B9B69'
      };
    case 'reservadas':
      return {
        border: '#F1D1DB',
        soft: '#FFF6F8',
        text: '#C06A86'
      };
    default:
      return {
        border: '#F3D8B8',
        soft: '#FFF9F2',
        text: '#C88738'
      };
  }
};

const getTableSaleStatus = (table: TableOrder): string =>
  statusText(table.venda?.situacao || table.statusCode || table.statusOriginal || table.situacao || '');

const getTableBaseStatus = (table: TableOrder): string => statusText(table.situacao);

const hasOpenSale = (table: TableOrder): boolean => Boolean(table.idVenda && table.idVenda > 0);

const isQuickLaunchTable = (table: TableOrder) => isTableStatusQuickLaunch(getTableSaleStatus(table));

  const isReservedTable = (table: TableOrder) => {
  const saleStatus = getTableSaleStatus(table);
  const baseStatus = getTableBaseStatus(table);
  return isTableStatusReserved(saleStatus) || isTableStatusReserved(baseStatus);
};

const resolveGroup = (table: TableOrder): TableStatusGroup => {
  const saleStatus = getTableSaleStatus(table);
  if (hasOpenSale(table) && !isTableStatusReserved(saleStatus)) return 'ocupadas';
  const isOpen = saleStatus.includes('pendente') || saleStatus.includes('prefechamento') || saleStatus.includes('pre-fechamento');

  if (isReservedTable(table)) return 'reservadas';
  if (isOpen) return 'ocupadas';
  if (isTableStatusQuickLaunch(saleStatus)) return 'livres';
  return 'livres';
};

const statusLabel = (table: TableOrder): string => {
  const saleStatus = getTableSaleStatus(table);
  if (isTableStatusReserved(saleStatus)) {
    return 'Reservada';
  }
  if (saleStatus.includes('prefechamento') || saleStatus.includes('pre-fechamento')) {
    return 'Pré-fechamento';
  }
  if (saleStatus.includes('pendente')) {
    return 'Pendente';
  }
  if (hasOpenSale(table)) {
    return 'Ocupada';
  }
  if (isTableStatusQuickLaunch(saleStatus)) {
    if (saleStatus.includes('pendente') || saleStatus.includes('prefechamento') || saleStatus.includes('pre-fechamento')) {
      return 'Ocupada';
    }
    return 'Livre';
  }

  return table.situacao || table.venda?.situacao || 'Livre';
};

export const InitialScreen: React.FC = () => {
  const navigation = useNavigation<StackNav>();
  const route = useRoute<InitialRoute>();
  const isFocused = useIsFocused();
  const {
    tables,
    appSettings,
    refreshDashboard,
    flushPendingItems,
    cart,
    user,
    logout,
    openTableByCard,
    setActiveTable
  } = useApp();

  const [menuOpen, setMenuOpen] = React.useState(false);
  const [filterVisible, setFilterVisible] = React.useState(false);
  const [filterText, setFilterText] = React.useState('');
  const [readerOpen, setReaderOpen] = React.useState(false);
  const [readerText, setReaderText] = React.useState('');
  const [readerLoading, setReaderLoading] = React.useState(false);
  const [openNameModalVisible, setOpenNameModalVisible] = React.useState(false);
  const [openNameText, setOpenNameText] = React.useState('');
  const [pendingOpenTable, setPendingOpenTable] = React.useState<{
    table: TableOrder;
    route: 'Gestao' | 'Cardapio';
  } | null>(null);
  const [readerCameraOpen, setReaderCameraOpen] = React.useState(false);
  const [CameraViewComponent, setCameraViewComponent] = React.useState<React.ComponentType<any> | null>(null);
  const [gridWidth, setGridWidth] = React.useState(0);
  const [selectedFilter, setSelectedFilter] = React.useState<TableStatusGroup>('ocupadas');
  const autoSendRunningRef = React.useRef(false);
  const autoSendEnabledRef = React.useRef(false);
  const autoSendTimerRef = React.useRef<ReturnType<typeof setTimeout> | null>(null);
  const cartCountRef = React.useRef(0);
  const tableOpenLockRef = React.useRef(false);
  const lastWarningRef = React.useRef<{ message: string; at: number }>({ message: '', at: 0 });
  const filterInputRef = React.useRef<TextInput>(null);
  const canUseCamera = Platform.OS !== 'web' && Boolean(CameraViewComponent);
  const cameraBusyRef = React.useRef(false);
  const dashboardRefreshInFlightRef = React.useRef(false);
  const configuredDisplayMode = appSettings.modoExibicao || 'mesa';
  const [visibleMode, setVisibleMode] = React.useState<'mesa' | 'comanda'>(
    configuredDisplayMode === 'comanda' ? 'comanda' : 'mesa'
  );
  const isComandaMode = visibleMode === 'comanda';
  const canToggleDisplayMode = configuredDisplayMode === 'mesaComanda';

  React.useEffect(() => {
    if (configuredDisplayMode === 'comanda') {
      setVisibleMode('comanda');
      return;
    }
    if (configuredDisplayMode === 'mesa') {
      setVisibleMode('mesa');
      return;
    }
    setVisibleMode((current) => (current === 'comanda' ? 'comanda' : 'mesa'));
  }, [configuredDisplayMode]);

  const menuItems: FilterItem[] = React.useMemo(() => {
    const base: FilterItem[] = [
      { key: 'ocupadas', title: 'Ocupadas' },
      { key: 'livres', title: 'Livres' },
      { key: 'todas', title: 'Todas' }
    ];

    if (!isComandaMode) {
      base.push({ key: 'reservadas', title: 'Reservadas' });
    }

    return base;
  }, [isComandaMode]);

  const { width: winWidth } = useWindowDimensions();
  const tableColumns = useMemo(() => {
    const availableWidth =
      gridWidth > 0 ? gridWidth : Math.max(0, winWidth - Space.md * 2);
    const minCardWidth =
      availableWidth >= 1200 ? 220 :
      availableWidth >= 920 ? 200 :
      availableWidth >= 700 ? 180 :
      availableWidth >= 520 ? 162 :
      148;
    const maxColumns = Math.max(1, Math.floor((availableWidth + Space.sm) / (minCardWidth + Space.sm)));
    return Math.max(1, Math.min(isComandaMode ? 6 : 5, maxColumns));
  }, [gridWidth, isComandaMode, winWidth]);

  const cardWidth = useMemo(() => {
    const availableWidth =
      gridWidth > 0 ? gridWidth : Math.max(0, winWidth - Space.md * 2);
    const spacing = Space.sm * (tableColumns - 1);
    return Math.max(142, Math.floor((availableWidth - spacing) / tableColumns));
  }, [gridWidth, winWidth, tableColumns]);

  const visibleTables = useMemo(() => {
    if (configuredDisplayMode === 'comanda') {
      return tables.filter((item) => item.tipo === 'comanda');
    }
    if (configuredDisplayMode === 'mesa') {
      return tables.filter((item) => item.tipo !== 'comanda');
    }
    return tables.filter((item) => (visibleMode === 'comanda' ? item.tipo === 'comanda' : item.tipo !== 'comanda'));
  }, [configuredDisplayMode, tables, visibleMode]);

  const { groupTotals, groupedTables } = useMemo(() => {
    const totals = {
      todas: 0,
      ocupadas: 0,
      livres: 0,
      reservadas: 0
    };
    const grouped = {
      todas: [] as TableOrder[],
      ocupadas: [] as TableOrder[],
      livres: [] as TableOrder[],
      reservadas: [] as TableOrder[]
    };

    const sorted = [...visibleTables].sort((left, right) => left.idMesa - right.idMesa);
    for (const table of sorted) {
      const group = resolveGroup(table);
      totals.todas += 1;
      totals[group] += 1;
      grouped.todas.push(table);
      grouped[group].push(table);
    }

    return {
      groupTotals: totals,
      groupedTables: grouped
    };
  }, [visibleTables]);

  React.useEffect(() => {
    if (!menuItems.some((item) => item.key === selectedFilter)) {
      setSelectedFilter(menuItems[0]?.key || 'ocupadas');
    }
  }, [menuItems, selectedFilter]);

  const filteredTables = useMemo(() => {
    const search = filterText.trim().toLowerCase();
    const baseList = groupedTables[selectedFilter] || groupedTables.todas;

    if (!search) {
      return baseList;
    }

    return baseList.filter((item) => {
      return (
        String(item.idMesa).toLowerCase().includes(search) ||
        statusLabel(item).toLowerCase().includes(search) ||
        (item.nomeMesaComanda || '').toLowerCase().includes(search)
      );
    });
  }, [filterText, groupedTables, selectedFilter]);

  const keyExtractor = React.useCallback(
    (item: TableOrder) => `${item.tipo || 'mesa'}-${item.idComanda || 0}-${item.idMesa}`,
    []
  );

  const renderTableItem = React.useCallback(
    ({ item, index }: { item: TableOrder; index: number }) => (
      <View style={[styles.tableCell, { width: cardWidth }, index % tableColumns !== tableColumns - 1 ? styles.tableCellSpacing : null]}>
        <TableCard
          table={item}
          displayMode={visibleMode}
          paletteMode={selectedFilter}
          onPress={() => openByTable(item, false)}
          onLongPress={() => openByTable(item, true)}
        />
      </View>
    ),
    [cardWidth, openByTable, selectedFilter, tableColumns, visibleMode]
  );

  const parseQrText = (value: string) => {
    const normalized = value.trim();
    const withoutPrefix = normalized
      .replace(/^\s*(mesa|comanda)\s*=/i, '')
      .replace(/[^\d]/g, ' ')
      .trim()
      .split(/\s+/)[0];
    const raw = Number(withoutPrefix);
    if (!withoutPrefix || Number.isNaN(raw)) {
      return null;
    }

    return raw;
  };

  const showDedupWarning = React.useCallback((title: string, message: string) => {
    const now = Date.now();
    const last = lastWarningRef.current;
    if (last.message === message && now - last.at < 1500) {
      return;
    }
    lastWarningRef.current = { message, at: now };
    Alert.alert(title, message);
  }, []);

  const closeOpenNameModal = React.useCallback(() => {
    setOpenNameModalVisible(false);
    setOpenNameText('');
    setPendingOpenTable(null);
  }, []);

  const requestOpenName = React.useCallback((table: TableOrder, route: 'Gestao' | 'Cardapio') => {
    setPendingOpenTable({ table, route });
    setOpenNameText('');
    setReaderOpen(false);
    setReaderCameraOpen(false);
    setOpenNameModalVisible(true);
  }, []);

  const openNewTable = React.useCallback(
    async (item: TableOrder, route: 'Gestao' | 'Cardapio', customName?: string) => {
      if (tableOpenLockRef.current) {
        return;
      }
      tableOpenLockRef.current = true;

      try {
        const effectiveName = customName?.trim() || undefined;
        const opened = await openTableByCard(item.idMesa, effectiveName, item.tipo);
        setActiveTable(opened || item);
        navigation.navigate('Tabs', { screen: route } as never);
      } catch {
        setActiveTable(item);
        navigation.navigate('Tabs', { screen: route } as never);
        showDedupWarning('Atenção', 'Não foi possível abrir a venda agora. Você ainda pode selecionar itens no cardápio.');
      } finally {
        setTimeout(() => {
          tableOpenLockRef.current = false;
        }, 350);
      }
    },
    [navigation, openTableByCard, setActiveTable, showDedupWarning]
  );

  const confirmOpenWithName = React.useCallback(async () => {
    const pending = pendingOpenTable;
    const nome = openNameText.trim();
    if (!pending) {
      return;
    }
    if (!nome) {
      Alert.alert('Atenção', 'Informe o nome para abrir a mesa/comanda.');
      return;
    }

    closeOpenNameModal();
    await openNewTable(pending.table, pending.route, nome);
  }, [closeOpenNameModal, openNameText, openNewTable, pendingOpenTable]);

  const openByTable = React.useCallback(async (item: TableOrder, forceManagement = false) => {
    const route = forceManagement ? 'Gestao' : 'Cardapio';
    const tableHasOpenSale = Boolean(item.idVenda && Number(item.idVenda) > 0);

    if (tableHasOpenSale) {
      setActiveTable(item);
      navigation.navigate('Tabs', { screen: route } as never);
      return;
    }

    if (appSettings.exigeNomeAbertura) {
      requestOpenName(item, route);
      return;
    }

    await openNewTable(item, route);
  }, [appSettings.exigeNomeAbertura, navigation, openNewTable, requestOpenName, setActiveTable]);

  const openTableByCode = async (raw: string) => {
    const id = parseQrText(raw);
    if (!id) {
      Alert.alert('Atenção', 'QR/código inválido. Informe um número válido.');
      return;
    }

    setReaderLoading(true);
    try {
      const target = tables.find((item) => item.idMesa === id);
      if (!target) {
        throw new Error('Mesa não encontrada.');
      }
      const tableMode = target?.tipo === 'comanda' ? 'comanda' : visibleMode;
      if (!target.idVenda && appSettings.exigeNomeAbertura) {
        setReaderOpen(false);
        setReaderCameraOpen(false);
        setReaderText('');
        requestOpenName(target, isQuickLaunchTable(target) ? 'Cardapio' : 'Gestao');
        return;
      }
      const opened = await openTableByCard(
        id,
        target?.idVenda ? target?.nomeMesaComanda : undefined,
        tableMode
      );
      setActiveTable(opened);
      const route = isQuickLaunchTable(opened) ? 'Cardapio' : 'Gestao';
      setReaderOpen(false);
      setReaderCameraOpen(false);
      setReaderText('');
      navigation.navigate('Tabs', { screen: route } as never);
    } catch {
      const fallback = tables.find((item) => item.idMesa === id);
      const fallbackTable: TableOrder = fallback
        ? {
            ...fallback
          }
        : {
            idMesa: id,
            nomeMesaComanda: `Mesa ${id}`,
            situacao: 'Livre',
            valorTotal: 0
          };
      setActiveTable(fallbackTable);
      const route = isQuickLaunchTable(fallbackTable) ? 'Cardapio' : 'Gestao';
      setReaderOpen(false);
      setReaderCameraOpen(false);
      setReaderText('');
      navigation.navigate('Tabs', { screen: route } as never);
      Alert.alert('Atenção', 'Não foi possível abrir a venda agora. Você ainda pode selecionar itens no cardápio.');
    } finally {
      setReaderLoading(false);
    }
  };

  const onOpenByReader = async () => {
    const normalized = readerText.trim();
    await openTableByCode(normalized);
  };

  const onOpenByScanner = async (result: BarcodeScanningResult) => {
    if (cameraBusyRef.current) return;
    const qrValue = result?.data?.trim();
    if (!qrValue) return;
    cameraBusyRef.current = true;
    setReaderLoading(true);
    try {
      await openTableByCode(qrValue);
    } finally {
      cameraBusyRef.current = false;
      setReaderLoading(false);
    }
  };

  const onCameraTop = async () => {
    const loadedCameraView = CameraViewComponent || getCameraViewComponent();
    if (!loadedCameraView || Platform.OS === 'web') {
      Alert.alert(
        'Leitor por câmera indisponível',
        'Este build não possui o módulo da câmera. Use o botão Digitar código.'
      );
      return;
    }
    if (!CameraViewComponent) {
      setCameraViewComponent(() => loadedCameraView);
    }

    try {
      if (Platform.OS === 'android') {
        const granted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.CAMERA);
        if (granted !== PermissionsAndroid.RESULTS.GRANTED) {
          Alert.alert(
            'Permissão de câmera',
            'A câmera não foi autorizada. Use o campo de código para abrir mesa.',
            [
              { text: 'Digitar código', onPress: () => setReaderOpen(true) },
              { text: 'Cancelar', style: 'cancel' }
            ]
          );
          return;
        }
      }
    } catch {
      Alert.alert('Erro', 'Não foi possível solicitar permissão da câmera.');
      return;
    }

    setReaderText('');
    setReaderLoading(false);
    setReaderOpen(false);
    setReaderCameraOpen(true);
  };

  const onFilterTop = () => {
    const next = !filterVisible;
    setFilterVisible(next);
    if (next) {
      setTimeout(() => filterInputRef.current?.focus(), 80);
      return;
    }
    setFilterText('');
  };

  React.useEffect(() => {
    cartCountRef.current = cart.length;
  }, [cart.length]);

  const clearAutoSendTimer = React.useCallback(() => {
    if (autoSendTimerRef.current) {
      clearTimeout(autoSendTimerRef.current);
      autoSendTimerRef.current = null;
    }
  }, []);

  const stopAutoSendMode = React.useCallback(() => {
    autoSendEnabledRef.current = false;
    clearAutoSendTimer();
    navigation.setParams({ autoSendPending: undefined });
  }, [clearAutoSendTimer, navigation]);

  const scheduleAutoSendRetry = React.useCallback(
    (delayMs = 0) => {
      clearAutoSendTimer();
      autoSendTimerRef.current = setTimeout(async () => {
        if (!autoSendEnabledRef.current) return;
        if (autoSendRunningRef.current) {
          scheduleAutoSendRetry(1500);
          return;
        }
        if (cartCountRef.current <= 0) {
          stopAutoSendMode();
          return;
        }

        autoSendRunningRef.current = true;
        try {
          const sent = await flushPendingItems();
          if (sent || cartCountRef.current <= 0) {
            stopAutoSendMode();
            return;
          }
        } catch {
          // API offline: mantém retry automático
        } finally {
          autoSendRunningRef.current = false;
        }

        if (autoSendEnabledRef.current) {
          scheduleAutoSendRetry(3000);
        }
      }, delayMs);
    },
    [clearAutoSendTimer, flushPendingItems, stopAutoSendMode]
  );

  React.useEffect(() => {
    if (!route.params?.autoSendPending) return;
    autoSendEnabledRef.current = true;
    scheduleAutoSendRetry(120);
  }, [route.params?.autoSendPending, scheduleAutoSendRetry]);

  React.useEffect(() => {
    return () => {
      autoSendEnabledRef.current = false;
      clearAutoSendTimer();
    };
  }, [clearAutoSendTimer]);

  const refreshVisibleDashboard = React.useCallback(async () => {
    if (dashboardRefreshInFlightRef.current) {
      return;
    }

    dashboardRefreshInFlightRef.current = true;
    try {
      await refreshDashboard(configuredDisplayMode === 'mesaComanda' ? 'mesaComanda' : configuredDisplayMode);
    } catch {
      // ignora falha temporaria e tenta novamente no proximo ciclo
    } finally {
      dashboardRefreshInFlightRef.current = false;
    }
  }, [configuredDisplayMode, refreshDashboard]);

  React.useEffect(() => {
    if (!isFocused) {
      return;
    }

    refreshVisibleDashboard();
    const refreshInterval = setInterval(() => {
      refreshVisibleDashboard();
    }, VISIBLE_DASHBOARD_REFRESH_MS);

    return () => {
      clearInterval(refreshInterval);
    };
  }, [isFocused, refreshVisibleDashboard]);

  const onToggleDisplayMode = async () => {
    if (!canToggleDisplayMode) {
      return;
    }
    const nextMode = isComandaMode ? 'mesa' : 'comanda';
    setVisibleMode(nextMode);
    setActiveTable(null);
    setSelectedFilter('todas');
    setFilterText('');
    await refreshDashboard('mesaComanda');
  };

  const onOpenMenu = (route: 'Sincronizar' | 'Configuracoes') => {
    setMenuOpen(false);
    navigation.navigate(route);
  };

  const onLogout = () => {
    logout();
    setMenuOpen(false);
    navigation.reset({
      index: 0,
      routes: [{ name: 'Login' }]
    });
  };

  return (
    <View style={styles.container}>
      <ScreenRouteLabel />
      <View style={styles.menuHeaderRow}>
        <TouchableOpacity style={styles.menuToggle} onPress={() => setMenuOpen(true)} activeOpacity={0.9}>
          <Text style={styles.menuToggleText}>☰</Text>
        </TouchableOpacity>

        <View style={styles.topActions}>
          {canToggleDisplayMode ? (
            <TouchableOpacity
              style={[styles.topActionBtn, styles.modeActionBtn]}
              onPress={onToggleDisplayMode}
              activeOpacity={0.85}
            >
              <Text style={styles.modeActionText}>{isComandaMode ? 'Mesa' : 'Comanda'}</Text>
            </TouchableOpacity>
          ) : null}
          <TouchableOpacity style={styles.topActionBtn} onPress={onCameraTop} activeOpacity={0.85}>
            <SafeIonicons name="camera" size={20} color="#C88738" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.topActionBtn} onPress={onFilterTop} activeOpacity={0.85}>
            <SafeIonicons name="search" size={20} color="#C88738" />
          </TouchableOpacity>
        </View>
      </View>

      {filterVisible ? (
        <View style={styles.filterWrap}>
          <TextInput
            ref={filterInputRef}
            style={styles.filterInput}
            placeholder="Filtrar mesa..."
            placeholderTextColor={Colors.textMuted}
            value={filterText}
            onChangeText={setFilterText}
            returnKeyType="search"
            autoCapitalize="none"
          />
          <TouchableOpacity
            style={styles.filterClear}
            onPress={() => {
              setFilterText('');
              setFilterVisible(false);
            }}
            activeOpacity={0.8}
          >
            <Text style={styles.filterClearText}>✕</Text>
          </TouchableOpacity>
        </View>
      ) : null}

      <Modal visible={menuOpen} transparent animationType="fade" onRequestClose={() => setMenuOpen(false)}>
        <View style={styles.menuOverlay}>
          <Pressable style={styles.menuBackdrop} onPress={() => setMenuOpen(false)} />
          <View style={styles.menuPanel}>
            <View style={styles.menuPanelHeader}>
              <Text style={styles.menuBrand}>RP CHEFF</Text>
              <TouchableOpacity style={styles.closeButton} onPress={() => setMenuOpen(false)} activeOpacity={0.8}>
                <Text style={styles.closeButtonText}>✕</Text>
              </TouchableOpacity>
            </View>
            <Text style={styles.menuUser}>Olá, {user?.nome || user?.login || 'usuário'}</Text>

            <Pressable style={styles.menuItem} onPress={() => onOpenMenu('Configuracoes')}>
              <Text style={styles.menuItemIcon}>⚙️</Text>
              <Text style={styles.menuItemText}>Configurações</Text>
            </Pressable>
            <Pressable style={styles.menuItem} onPress={() => onOpenMenu('Sincronizar')}>
              <Text style={styles.menuItemIcon}>🔁</Text>
              <Text style={styles.menuItemText}>Sincronizar</Text>
            </Pressable>
            <Pressable style={[styles.menuItem, styles.menuItemDanger]} onPress={onLogout}>
              <Text style={styles.menuItemIcon}>🚪</Text>
              <Text style={[styles.menuItemText, styles.menuItemDangerText]}>Sair</Text>
            </Pressable>
          </View>
        </View>
      </Modal>

      <Modal visible={readerCameraOpen} transparent animationType="fade" onRequestClose={() => setReaderCameraOpen(false)}>
        <View style={styles.readerOverlay}>
          <View style={styles.readerPanel}>
            <Text style={styles.readerTitle}>Leitor por câmera</Text>
            <Text style={styles.readerDesc}>Aponte para o QR/código.</Text>
            <View style={styles.cameraFrame}>
              {CameraViewComponent ? (
                <CameraViewComponent style={styles.cameraView} onBarcodeScanned={readerLoading ? undefined : onOpenByScanner} />
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
                onPress={() => setReaderCameraOpen(false)}
                activeOpacity={0.8}
              >
                <Text style={styles.readerButtonText}>Fechar</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.readerButton, styles.readerButtonPrimary]}
                onPress={() => {
                  setReaderCameraOpen(false);
                  setReaderOpen(true);
                }}
                activeOpacity={0.8}
              >
                <Text style={styles.readerButtonTextPrimary}>Digitar código</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <Modal visible={readerOpen} transparent animationType="slide" onRequestClose={() => setReaderOpen(false)}>
        <View style={styles.readerOverlay}>
          <View style={styles.readerPanel}>
            <Text style={styles.readerTitle}>Leitor de mesa</Text>
            <Text style={styles.readerDesc}>Digite o número/código da mesa/comanda.</Text>
            <TextInput
              style={styles.readerInput}
              value={readerText}
              onChangeText={setReaderText}
              placeholder="Ex: Mesa 12"
              placeholderTextColor={Colors.textMuted}
              autoCapitalize="none"
              autoCorrect={false}
              returnKeyType="done"
              onSubmitEditing={onOpenByReader}
            />
            <View style={styles.readerActions}>
              <TouchableOpacity
                style={styles.readerButton}
                disabled={readerLoading}
                onPress={() => setReaderOpen(false)}
                activeOpacity={0.8}
              >
                <Text style={styles.readerButtonText}>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.readerButton, styles.readerButtonPrimary]}
                disabled={readerLoading}
                onPress={onOpenByReader}
                activeOpacity={0.8}
              >
                <Text style={styles.readerButtonTextPrimary}>
                  {readerLoading ? 'Abrindo...' : 'Abrir'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <OpenTableNameModal
        visible={openNameModalVisible}
        value={openNameText}
        onChangeText={setOpenNameText}
        onCancel={closeOpenNameModal}
        onConfirm={confirmOpenWithName}
      />

      <View style={styles.filtersPanel}>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.filtersRow}
          keyboardShouldPersistTaps="handled"
        >
        {menuItems.map((item) => {
          const active = selectedFilter === item.key;
          const palette = getFilterPalette(item.key);
          return (
            <TouchableOpacity
              key={item.key}
              onPress={() => setSelectedFilter(item.key)}
              style={[
                styles.filterBadge,
                styles.filterBadgeSlider,
                {
                  borderColor: active ? palette.text : palette.border,
                  backgroundColor: palette.soft
                },
                active ? styles.filterBadgeActive : null
              ]}
              activeOpacity={0.85}
            >
              <View style={[styles.filterBadgeCountWrap, { borderColor: active ? palette.text : palette.border }]}>
                <Text style={[styles.filterBadgeValue, { color: palette.text }]}>{groupTotals[item.key]}</Text>
              </View>
              <Text style={[styles.filterBadgeTitle, { color: palette.text }]}>{item.title}</Text>
            </TouchableOpacity>
          );
        })}
        </ScrollView>
      </View>

      <FlatList
        onLayout={(event) => {
          const nextWidth = Math.floor(event.nativeEvent.layout.width);
          setGridWidth((prev) => (prev === nextWidth ? prev : nextWidth));
        }}
        style={styles.tableList}
        data={filteredTables}
        keyExtractor={keyExtractor}
        numColumns={tableColumns}
        key={`table-grid-${tableColumns}`}
        columnWrapperStyle={tableColumns > 1 ? styles.tableColumnWrapper : undefined}
        renderItem={renderTableItem}
        ListHeaderComponent={<View style={styles.listHeaderSpacer} />}
        initialNumToRender={Math.max(tableColumns * 2, 8)}
        maxToRenderPerBatch={Math.max(tableColumns * 3, 12)}
        updateCellsBatchingPeriod={30}
        windowSize={5}
        removeClippedSubviews={true}
        ListEmptyComponent={
          <View style={styles.emptyCard}>
            <Text style={styles.emptyTitle}>Sem itens para esse filtro</Text>
            <Text style={styles.emptyText}>Ajuste o filtro ou atualize para carregar a lista.</Text>
          </View>
        }
        contentContainerStyle={styles.list}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
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
  menuHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: Space.sm,
    gap: Space.sm
  },
  menuToggle: {
    backgroundColor: Colors.primary,
    borderRadius: 10,
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center'
  },
  menuToggleText: {
    color: '#ffffff',
    fontWeight: '800',
    fontSize: 20,
    lineHeight: 20
  },
  topActions: {
    flexDirection: 'row',
    alignItems: 'center',
    marginLeft: 'auto',
    gap: 8
  },
  topActionBtn: {
    width: 46,
    height: 46,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#F0CFA4',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFF8EF',
    shadowColor: '#C88738',
    shadowOpacity: 0.08,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 1
  },
  modeActionBtn: {
    width: 92,
    backgroundColor: '#FFF8EF',
    borderColor: '#F0CFA4',
    paddingHorizontal: 6
  },
  modeActionText: {
    color: '#C88738',
    fontSize: 11,
    fontWeight: '800'
  },
  topActionIcon: {
    fontSize: 20
  },
  connectionRow: {
    marginBottom: Space.md,
    backgroundColor: '#FFFCF8',
    borderWidth: 1,
    borderColor: '#EEE3D5',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 8
  },
  connectionText: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700'
  },
  filterWrap: {
    position: 'relative',
    marginBottom: Space.md,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8
  },
  filterInput: {
    flex: 1,
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.border,
    color: Colors.text,
    backgroundColor: Colors.card,
    paddingHorizontal: 12,
    paddingVertical: 10
  },
  filterClear: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center'
  },
  filterClearText: {
    color: Colors.text,
    fontWeight: '800'
  },
  menuOverlay: {
    flex: 1,
    backgroundColor: 'rgba(10, 20, 30, 0.45)',
    justifyContent: 'flex-start',
    alignItems: 'flex-start'
  },
  menuBackdrop: {
    position: 'absolute',
    left: 0,
    top: 0,
    right: 0,
    bottom: 0
  },
  menuPanel: {
    width: '72%',
    maxWidth: 300,
    backgroundColor: Colors.card,
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Space.md,
    gap: Space.sm
  },
  menuPanelHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  menuBrand: {
    color: Colors.primary,
    fontWeight: '900',
    fontSize: 20
  },
  closeButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.background
  },
  closeButtonText: {
    color: Colors.text,
    fontWeight: '800',
    lineHeight: 16
  },
  menuUser: {
    color: Colors.text,
    fontWeight: '800'
  },
  menuItem: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.sm,
    paddingVertical: 10,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.background,
    gap: 8
  },
  menuItemIcon: {
    marginRight: 4
  },
  menuItemText: {
    color: Colors.text,
    fontWeight: '700'
  },
  menuItemDanger: {
    borderColor: Colors.warning,
    backgroundColor: '#fff7ed'
  },
  menuItemDangerText: {
    color: Colors.warning
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
    gap: Space.md
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
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.background,
    color: Colors.text,
    paddingHorizontal: 12,
    paddingVertical: 10
  },
  readerActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10
  },
  readerButton: {
    flex: 1,
    backgroundColor: Colors.background,
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: 10,
    alignItems: 'center'
  },
  readerButtonText: {
    color: Colors.text,
    fontWeight: '700'
  },
  readerButtonPrimary: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary
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
  filtersPanel: {
    marginBottom: Space.md,
    backgroundColor: '#FFFCF8',
    borderRadius: 18,
    borderWidth: 1,
    borderColor: '#EEE3D5',
    paddingVertical: 12,
    paddingHorizontal: 9,
    shadowColor: '#000',
    shadowOpacity: 0.03,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 1
  },
  filtersRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.background,
    gap: 8,
    paddingHorizontal: 2,
    paddingVertical: 2
  },
  filterBadge: {
    minWidth: 98,
    minHeight: 74,
    borderWidth: 1,
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    paddingVertical: 12,
    paddingHorizontal: 10,
    alignItems: 'center',
    justifyContent: 'center'
  },
  filterBadgeSlider: {
    width: 122
  },
  filterBadgeActive: {
    borderWidth: 1.5
  },
  filterBadgeTitle: {
    fontWeight: '700',
    marginTop: 4,
    fontSize: 11
  },
  filterBadgeCountWrap: {
    minWidth: 36,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 6,
    backgroundColor: '#FFFFFF',
    borderWidth: 1
  },
  filterBadgeValue: {
    fontWeight: '900',
    fontSize: 16,
    lineHeight: 18
  },
  tableList: {
    marginTop: 0,
    zIndex: 0
  },
  activeWrap: {
    borderRadius: Radius.md,
    backgroundColor: '#FFFCF8',
    borderColor: '#EEE3D5',
    borderWidth: 1,
    padding: Space.md,
    marginBottom: Space.md
  },
  activeTitle: {
    color: '#8A5B27',
    fontWeight: '700',
    marginBottom: 4
  },
  activeText: {
    color: Colors.text,
    fontSize: 13,
    marginBottom: 2
  },
  list: {
    paddingBottom: 140,
    paddingTop: Space.xs
  },
  tableColumnWrapper: {
    justifyContent: 'flex-start'
  },
  tableCell: {
    marginBottom: Space.md
  },
  tableCellSpacing: {
    marginRight: Space.sm
  },
  listHeaderSpacer: {
    height: Space.lg
  },
  emptyCard: {
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Space.md
  },
  emptyTitle: {
    fontSize: Typography.subtitle,
    fontWeight: '700',
    marginBottom: 6
  },
  emptyText: {
    color: Colors.textMuted
  },
  statusText: {
    marginBottom: Space.md
  }
});


