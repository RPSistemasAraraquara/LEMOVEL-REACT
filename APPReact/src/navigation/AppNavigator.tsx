import React from 'react';
import { DefaultTheme, NavigationContainer } from '@react-navigation/native';
import type { NavigatorScreenParams } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Text, View, Pressable, StyleSheet } from 'react-native';
import type { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useApp } from '../context/AppContext';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { HomeScreen } from '../screens/HomeScreen';
import { MenuScreen } from '../screens/MenuScreen';
import { CartScreen } from '../screens/CartScreen';
import { LoginScreen } from '../screens/LoginScreen';
import { InitialScreen } from '../screens/InitialScreen';
import { CategoryManagerScreen } from '../screens/CategoryManagerScreen';
import { ProductManagerScreen } from '../screens/ProductManagerScreen';
import { SettingsScreen } from '../screens/SettingsScreen';
import { SyncScreen } from '../screens/SyncScreen';
import { PendingItemsScreen } from '../screens/PendingItemsScreen';
import { CouvertManagerScreen } from '../screens/CouvertManagerScreen';
import { ItemLaunchScreen } from '../screens/ItemLaunchScreen';
import { FractionLaunchScreen } from '../screens/FractionLaunchScreen';
import { SaleManagerScreen } from '../screens/SaleManagerScreen';
import { SaleClosureScreen } from '../screens/SaleClosureScreen';
import { SalePaymentScreen } from '../screens/SalePaymentScreen';
import { PaymentProgressScreen } from '../screens/PaymentProgressScreen';
import { TransferMergeScreen } from '../screens/TransferMergeScreen';
import { Colors, Radius, Shadows, Space } from '../theme';
import { MenuItem, normalizeSaleStatus, api } from '../services/api';
import { SweetAlert, SweetAlertType } from '../components/SweetAlert';
import { GlobalSweetAlertHost } from '../components/GlobalSweetAlertHost';

export type RootStackParams = {
  Login: undefined;
  Tabs: NavigatorScreenParams<TabParams> | undefined;
  Inicial: { autoSendPending?: boolean } | undefined;
  Produtos: undefined;
  Categorias: undefined;
  Configuracoes: undefined;
  Sincronizar: undefined;
  ItensPendentes: { idVenda?: number };
  Couvert: { idVenda?: number };
  Lancamento: {
    item: MenuItem;
    origin?: 'cardapio';
    quantity?: number;
    size?: string;
    tableId?: number;
    tableComandaId?: number;
    tableType?: 'mesa' | 'comanda';
    tableName?: string;
    returnTo?: 'Inicial' | 'Cardapio' | 'Gestao';
    returnCategoryId?: number;
  };
  LancamentoFracionado: {
    item: MenuItem;
    quantity: number;
    size?: string;
    origin?: 'cardapio';
    tableId?: number;
    tableComandaId?: number;
    tableType?: 'mesa' | 'comanda';
    tableName?: string;
    returnTo?: 'Inicial' | 'Cardapio' | 'Gestao';
    returnCategoryId?: number;
  };
  Fechamento: {
    idVenda: number;
    idUsuario?: number;
    nomeMesaComanda?: string;
    tableType?: 'mesa' | 'comanda';
    mode?: 'pre' | 'final';
    returnTo?: 'Inicial' | 'Cardapio' | 'Gestao' | 'Mesas';
  };
  Pagamento: { idVenda: number };
  PagamentoProgresso: { idVenda: number };
  Transferencia: { idMesaOrigem: number; idVenda?: number; tableType?: 'mesa' | 'comanda' };
  JuntarMesa: { idVendaDestino?: number; tableType?: 'mesa' | 'comanda' };
  Carrinho: undefined;
};

export type TabParams = {
  Mesas: undefined;
  Cardapio: { selectedCategoryId?: number } | undefined;
  Gestao: undefined;
};

const Stack = createNativeStackNavigator<RootStackParams>();
const Tabs = createBottomTabNavigator<TabParams>();
const navTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: Colors.background,
    card: Colors.card,
    text: Colors.text,
    primary: Colors.primary,
    border: Colors.border,
    notification: Colors.accent
  }
};

function BottomButtonBar({ state, descriptors, navigation }: BottomTabBarProps) {
  const { activeTable, user, refreshDashboard } = useApp();
  const insets = useSafeAreaInsets();
  const stackNavigation = navigation.getParent<NativeStackNavigationProp<RootStackParams>>();
  const activeTab = ((state.routes[state.index]?.name || 'Cardapio') as 'Mesas' | 'Cardapio' | 'Gestao');
  const canShowPreClosureButton = Boolean(user?.permitePreFechamentoMesaComanda);
  const canShowFinalClosureButton = Boolean(user?.permiteFechamentoMesaComanda);
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

  const showSweetAlert = (title: string, message: string, type: SweetAlertType = 'warning') => {
    setSweetAlert({
      visible: true,
      title,
      message,
      type
    });
  };

  const openClosure = async (mode: 'pre' | 'final') => {
    if (!activeTable?.idVenda) {
      showSweetAlert('Fluxo inválido', 'Abra uma mesa com venda ativa antes de fechar.', 'error');
      return;
    }

    if (mode === 'pre' && !user?.permitePreFechamentoMesaComanda) {
      showSweetAlert('Atenção', 'Sem permissão para fazer pré-fechamento.');
      return;
    }

    if (mode === 'final' && !user?.permiteFechamentoMesaComanda) {
      showSweetAlert('Atenção', 'Sem permissão para fazer fechamento.');
      return;
    }

    let saleStatus = normalizeSaleStatus(
      activeTable.venda?.situacao || activeTable.statusCode || activeTable.statusOriginal || activeTable.situacao || ''
    );
    if (mode === 'pre') {
      try {
        const freshSale = await api.getSale(activeTable.idVenda, false);
        if (freshSale?.situacao) {
          saleStatus = normalizeSaleStatus(freshSale.situacao);
        }
      } catch (error: unknown) {
        void error;
      }
    }
    const isAlreadyPreClosed = saleStatus.includes('prefechamento') || saleStatus.includes('pre-fechamento');

    if (mode === 'pre' && isAlreadyPreClosed) {
      showSweetAlert('Atenção', 'A venda já está em pré-fechamento.');
      return;
    }

    if (!stackNavigation) {
      showSweetAlert('Erro', 'Não foi possível abrir a ação no momento.', 'error');
      return;
    }

    const returnTo = activeTab;

    stackNavigation.navigate('Fechamento', {
      idVenda: activeTable.idVenda,
      idUsuario: user?.idUsuario,
      nomeMesaComanda: activeTable.nomeMesaComanda,
      tableType: activeTable?.tipo,
      mode,
      returnTo
    });
    refreshDashboard();
  };

  return (
    <>
      <View style={[styles.tabBarSafeArea, { paddingBottom: Math.max(insets.bottom, Space.xs) + 6 }]}>
        <View style={styles.tabBarContainer}>
          {state.routes.map((route, index) => {
            const shouldShowButton =
              route.name === 'Mesas'
                ? canShowPreClosureButton
                : route.name === 'Cardapio'
                  ? canShowFinalClosureButton
                  : true;

            if (!shouldShowButton) {
              return null;
            }

            const { options } = descriptors[route.key];
            const isFocused = state.index === index;
            const label = (typeof options.tabBarLabel === 'string'
              ? options.tabBarLabel
              : options.title || route.name);
            const onPress = () => {
              if (route.name === 'Mesas') {
                void openClosure('pre');
                return;
              }

              if (route.name === 'Cardapio') {
                void openClosure('final');
                return;
              }

              const event = navigation.emit({
                type: 'tabPress',
                target: route.key,
                canPreventDefault: true
              });
              if (!isFocused && !event.defaultPrevented) {
                navigation.navigate(route.name);
              }
            };

            return (
              <Pressable
                key={route.key}
                onPress={onPress}
                style={({ pressed }) => [
                  styles.tabBarButton,
                  isFocused ? styles.tabBarButtonActive : styles.tabBarButtonInactive,
                  pressed ? styles.tabBarButtonPressed : null
                ]}
              >
                <Text style={isFocused ? styles.tabBarTextActive : styles.tabBarTextInactive}>
                  {label}
                </Text>
              </Pressable>
            );
          })}
        </View>
      </View>
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
    </>
  );
}

function TabsRoutes() {
  return (
      <Tabs.Navigator
        screenOptions={{
          headerShown: false,
          tabBarShowLabel: false,
          tabBarStyle: {
            backgroundColor: 'transparent'
          }
        }}
        tabBar={(props) => <BottomButtonBar {...props} />}
      >
      <Tabs.Screen
        name="Mesas"
        component={HomeScreen}
          options={{
          tabBarLabel: 'Pré Fechamento',
          tabBarIcon: () => <Text>🍽️</Text>
        }}
      />
      <Tabs.Screen
        name="Cardapio"
        component={MenuScreen}
        options={{
          tabBarLabel: 'Fechamento',
          tabBarIcon: () => <Text>🍔</Text>
        }}
      />
      <Tabs.Screen
        name="Gestao"
        component={SaleManagerScreen}
        options={{
          tabBarLabel: 'Opções',
          tabBarIcon: () => <Text>⚙️</Text>
        }}
      />
    </Tabs.Navigator>
  );
}

export function AppNavigator() {
  const { user } = useApp();

  return (
    <NavigationContainer theme={navTheme}>
      <>
        <Stack.Navigator
          screenOptions={{
            headerShown: false,
            headerStyle: { backgroundColor: Colors.background },
            headerShadowVisible: false,
            headerTintColor: Colors.primary,
            headerTitleStyle: { fontWeight: '900', color: Colors.text }
          }}
        >
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen
            name="Configuracoes"
            component={SettingsScreen}
            options={{
              headerShown: true,
              headerTitle: 'Configurações'
            }}
          />

          {user ? (
            <>
              <Stack.Screen
                name="Inicial"
                component={InitialScreen}
                options={{ headerShown: false }}
              />
              <Stack.Screen name="Tabs" component={TabsRoutes} />
              <Stack.Screen
                name="Produtos"
                component={ProductManagerScreen}
                options={{ headerShown: true, headerTitle: 'Produtos' }}
              />
              <Stack.Screen
                name="Categorias"
                component={CategoryManagerScreen}
                options={{ headerShown: true, headerTitle: 'Categorias' }}
              />
              <Stack.Screen
                name="Sincronizar"
                component={SyncScreen}
                options={{ headerShown: true, headerTitle: 'Sincronização' }}
              />
              <Stack.Screen
                name="ItensPendentes"
                component={PendingItemsScreen}
                options={{ headerShown: true, headerTitle: 'Itens Pendentes' }}
              />
              <Stack.Screen
                name="Couvert"
                component={CouvertManagerScreen}
                options={{ headerShown: true, headerTitle: 'Couvert' }}
              />
              <Stack.Screen
                name="Lancamento"
                component={ItemLaunchScreen}
                options={{ headerShown: true, title: '', headerTitle: () => null }}
              />
              <Stack.Screen
                name="LancamentoFracionado"
                component={FractionLaunchScreen}
                options={{ headerShown: true, title: '', headerTitle: () => null }}
              />
              <Stack.Screen
                name="Carrinho"
                component={CartScreen}
                options={{ headerShown: true, headerTitle: 'Carrinho' }}
              />
              <Stack.Screen
                name="Fechamento"
                component={SaleClosureScreen}
                options={{ headerShown: true, headerTitle: 'Fechamento' }}
              />
              <Stack.Screen
                name="JuntarMesa"
                component={TransferMergeScreen}
                options={{ headerShown: true, headerTitle: 'Juntar Mesas' }}
              />
              <Stack.Screen
                name="Pagamento"
                component={SalePaymentScreen}
                options={{ headerShown: true, headerTitle: 'Pagamento', animation: 'none' }}
              />
              <Stack.Screen
                name="PagamentoProgresso"
                component={PaymentProgressScreen}
                options={{ headerShown: true, headerTitle: 'Progresso de pagamento', animation: 'none' }}
              />
              <Stack.Screen
                name="Transferencia"
                component={TransferMergeScreen}
                options={{ headerShown: true, headerTitle: 'Transferência' }}
              />
            </>
          ) : null}
        </Stack.Navigator>
        <GlobalSweetAlertHost />
      </>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  tabBarSafeArea: {
    paddingHorizontal: 10,
    paddingTop: 8,
    backgroundColor: 'transparent'
  },
  tabBarContainer: {
    borderRadius: Radius.xl,
    backgroundColor: 'rgba(255, 253, 249, 0.98)',
    borderWidth: 1,
    borderColor: Colors.border,
    padding: 7,
    flexDirection: 'row',
    gap: 6,
    ...Shadows.card,
    zIndex: 9999,
    elevation: 16
  },
  tabBarButton: {
    flex: 1,
    borderRadius: 18,
    minHeight: 48,
    paddingHorizontal: 8,
    paddingVertical: 10,
    alignItems: 'center',
    justifyContent: 'center'
  },
  tabBarButtonActive: {
    backgroundColor: Colors.primary,
    ...Shadows.button
  },
  tabBarButtonInactive: {
    backgroundColor: Colors.cardSoft,
    borderWidth: 1,
    borderColor: Colors.border
  },
  tabBarButtonPressed: {
    opacity: 0.75
  },
  tabBarTextActive: {
    color: '#ffffff',
    fontWeight: '800',
    fontSize: 12,
    textAlign: 'center'
  },
  tabBarTextInactive: {
    color: Colors.text,
    fontWeight: '800',
    fontSize: 12,
    textAlign: 'center'
  }
});
