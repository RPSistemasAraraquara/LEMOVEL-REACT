import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Alert,
  Animated,
  Easing,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useApp } from '../context/AppContext';
import { SectionHeader } from '../components/SectionHeader';
import { Colors, Radius, Shadows, Space } from '../theme';
import {
  api,
  applyCompanyPolicyToSettings,
  CompanyInfo,
  hasConflictingOpeningSettings,
  MobileAppSettings,
  normalizeMobileBaseUrl,
  OPENING_SETTINGS_CONFLICT_MESSAGE
} from '../services/api';
import { RootStackParams } from '../navigation/AppNavigator';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import {
  executeGetNetCheckSubsellers,
  executeGetNetRefund,
  executeGetNetStatus,
  executeGetNetTerminalInfo,
  loadLastGetNetSubsellers,
  loadLastGetNetTransaction
} from '../services/payment';
import {
  beepGetNetPosDigitalSuccess,
  getGetNetPaymentEnvironment,
  getGetNetPosDigitalInfo,
  searchGetNetPosDigitalCard,
  searchGetNetPosDigitalMifareUid,
  turnOffGetNetPosDigitalLeds,
  turnOnGetNetPosDigitalLeds
} from '../services/getnetPosDigital';
import type { StoredGetNetSubsellers, StoredGetNetTransaction } from '../services/machineSettingsDb';

type DisplayMode = 'mesa' | 'comanda' | 'mesaComanda';

type SettingsState = {
  servidor: string;
  terminalImpressao: string;
  salvarLoginSenha: boolean;
  utilizaCatraca: boolean;
  cobrarMaiorValorFracionado: boolean;
  vincularComandaComMesa: boolean;
  imprimirMesaAposFechamento: boolean;
  imprimirComandaAposFechamento: boolean;
  controleHappyHour: boolean;
  controlePromocao: boolean;
  pesquisaCodigoProduto: boolean;
  controleProximoGratis: boolean;
  utilizaCategorias: boolean;
  exibirImagem: boolean;
  exigeNomeAbertura: boolean;
  utilizaImpressoraInterna: boolean;
  imprimirFichaIndividualProdutos: boolean;
  imprimirModelo: string;
  impressoraPaginaCodigo: string;
  impressoraControlePorta: boolean;
  impressoraBluetooth: string;
  impressaoColunas: string;
  impressaoEspaco: string;
  impressaoLinhasPulo: string;
  sincronizarAposLogin: boolean;
  modoExibicao: DisplayMode;
  utilizaMaquininhaStone: boolean;
  tipoIntegracao: 'nenhum' | 'vero' | 'stone' | 'pagbank' | 'cielo' | 'getnet';
  modeloMaquininha: string;
};

const IMPRESSORA_MODELOS = ['Padrão ESC/POS', 'POS-58', 'POS-80', 'Termica TSP100', 'Outro'];
const IMPRESSAO_PAGINAS = ['CP437', 'Windows-1252', 'ISO-8859-1', 'UTF-8'];
const BLUETOOTH_LIST = ['Nenhuma', 'BT: Impressora Sala', 'BT: Impressora Cozinha', 'BT: Impressora Entrada'];
type IntegrationValue = 'nenhum' | 'vero' | 'stone' | 'pagbank' | 'cielo' | 'getnet';
type GetNetModelValue = 'DX8000' | 'P2' | 'P3' | 'P4' | 'N910' | 'APOSA8';
type StoneModelValue = 'P2' | 'L400';

const INTEGRACAO_OPTIONS: Array<{ label: string; value: IntegrationValue }> = [
  { label: 'Vero', value: 'vero' },
  { label: 'Stone', value: 'stone' },
  { label: 'PagBank', value: 'pagbank' },
  { label: 'Cielo', value: 'cielo' },
  { label: 'GetNet', value: 'getnet' }
];

const GETNET_MODEL_OPTIONS: GetNetModelValue[] = ['DX8000', 'P2', 'P3', 'P4', 'N910', 'APOSA8'];
const STONE_MODEL_OPTIONS: StoneModelValue[] = ['P2', 'L400'];
const CONNECTION_CHECK_TIMEOUT_MS = 5000;
const IPV4_ADDRESS_PATTERN = /^(\d{1,3}\.){3}\d{1,3}$/;

type ConnectionCheckSummary = {
  ok: boolean;
  status?: number;
  message: string;
};

const normalizeStoneModel = (value: unknown, fallback: StoneModelValue = 'P2'): StoneModelValue => {
  const normalized = String(value || '')
    .trim()
    .toUpperCase();

  if (normalized === 'L400' || normalized === 'POSITIVO' || normalized === 'POSITIVO L400') {
    return 'L400';
  }

  if (normalized === 'P2' || normalized === 'P2-B' || normalized === 'SUNMI' || normalized === 'STONE') {
    return 'P2';
  }

  return fallback;
};

const normalizeGetNetModel = (value: unknown, fallback: GetNetModelValue = 'P2'): GetNetModelValue => {
  const normalized = String(value || '')
    .trim()
    .toUpperCase();

  if (
    normalized === 'DX8000' ||
    normalized === 'INGENICO DX8000' ||
    normalized === 'INGENICO-DX8000' ||
    normalized === 'DX 8000'
  ) {
    return 'DX8000';
  }
  if (normalized === 'P2' || normalized === 'P3' || normalized === 'P4') return normalized;
  if (normalized === 'N910' || normalized === 'NEWLAND N910' || normalized === 'NEWLAND-N910') return 'N910';
  if (
    normalized === 'APOSA8' ||
    normalized === 'APOS A8' ||
    normalized === 'INGENICO APOS A8' ||
    normalized === 'A8'
  ) {
    return 'APOSA8';
  }

  return fallback;
};

const getMachineModelLabel = (value: IntegrationValue): string => {
  if (value === 'stone') return 'P2';
  if (value === 'pagbank') return 'PagBank';
  if (value === 'cielo') return 'Cielo';
  if (value === 'getnet') return 'P2';
  if (value === 'vero') return 'Vero';
  return 'false';
};

const toNumberString = (value: number, fallback: string) => (Number.isFinite(value) ? String(value) : fallback);

const normalizeServerUrl = (value: string) => {
  const trimmed = String(value || '').trim();
  if (!trimmed) {
    return '';
  }

  return normalizeMobileBaseUrl(trimmed);
};

const validateServerUrl = (value: string): string | null => {
  const normalized = normalizeServerUrl(value);

  if (!normalized) {
    return 'Informe o endereço do servidor. Exemplo: 192.168.15.30 ou https://mobile.rpfood.com.br';
  }

  const match = normalized.match(/^https?:\/\/([^/:?#]+)(?::(\d+))?(?:[/?#].*)?$/i);
  if (!match) {
    return 'Servidor inválido. Informe um IP local ou domínio HTTPS, por exemplo 192.168.15.30 ou https://mobile.rpfood.com.br';
  }

  const host = String(match[1] || '').trim();
  const port = match[2] ? Number(match[2]) : 0;

  if (!host) {
    return 'Servidor inválido. Informe o IP ou domínio da API.';
  }

  if (IPV4_ADDRESS_PATTERN.test(host)) {
    const hasInvalidOctet = host
      .split('.')
      .some((part) => Number(part) < 0 || Number(part) > 255);

    if (hasInvalidOctet) {
      return 'IP inválido. Cada parte do IP deve ficar entre 0 e 255.';
    }
  } else if (/^\d+(?:\.\d+)*$/.test(host)) {
    return 'IP inválido. Use quatro partes, por exemplo 192.168.15.30.';
  }

  if (match[2] && (!Number.isFinite(port) || port < 1 || port > 65535)) {
    return 'Porta inválida. Informe uma porta entre 1 e 65535.';
  }

  return null;
};

const buildConnectionWarning = (status?: number, message?: string) => {
  const detail = [status ? `Status ${status}` : '', message || 'sem resposta da API']
    .filter(Boolean)
    .join(' - ');

  return `Configuração salva no aparelho. Não foi possível conectar na API agora. Verifique o endereço do servidor (IP local ou domínio HTTPS).${detail ? `\n\nRetorno: ${detail}` : ''}`;
};

const withConnectionCheckTimeout = (
  checkConnection: (timeoutMs?: number) => Promise<ConnectionCheckSummary>
): Promise<ConnectionCheckSummary> => {
  let timeout: ReturnType<typeof setTimeout> | null = null;

  const timeoutPromise = new Promise<ConnectionCheckSummary>((resolve) => {
    timeout = setTimeout(() => {
      resolve({
        ok: false,
        status: 0,
        message: 'Tempo limite ao testar a conexão com a API.'
      });
    }, CONNECTION_CHECK_TIMEOUT_MS);
  });

  return Promise.race([
    checkConnection(CONNECTION_CHECK_TIMEOUT_MS),
    timeoutPromise
  ]).finally(() => {
    if (timeout) {
      clearTimeout(timeout);
    }
  });
};

const toSettingsState = (settings: MobileAppSettings): SettingsState => ({
  servidor: settings.baseUrl,
  terminalImpressao: settings.terminalImpressao,
  salvarLoginSenha: settings.salvarLoginSenha,
  utilizaCatraca: settings.utilizaCatraca,
  cobrarMaiorValorFracionado: settings.cobrarMaiorValorFracionado,
  vincularComandaComMesa: settings.vincularComandaComMesa,
  imprimirMesaAposFechamento: settings.imprimirMesaAposFechamento,
  imprimirComandaAposFechamento: settings.imprimirComandaAposFechamento,
  controleHappyHour: settings.controleHappyHour,
  controlePromocao: settings.controlePromocao,
  pesquisaCodigoProduto: settings.pesquisaCodigoProduto,
  controleProximoGratis: settings.controleProximoGratis,
  utilizaCategorias: settings.utilizaCategorias,
  exibirImagem: settings.exibirImagem,
  exigeNomeAbertura: settings.exigeNomeAbertura,
  utilizaImpressoraInterna: settings.utilizaImpressoraInterna,
  imprimirFichaIndividualProdutos: settings.imprimirFichaIndividualProdutos,
  imprimirModelo: settings.imprimirModelo,
  impressoraPaginaCodigo: settings.impressoraPaginaCodigo,
  impressoraControlePorta: settings.impressoraControlePorta,
  impressoraBluetooth: settings.impressoraBluetooth,
  impressaoColunas: toNumberString(settings.impressaoColunas, '48'),
  impressaoEspaco: toNumberString(settings.impressaoEspaco, '0'),
  impressaoLinhasPulo: toNumberString(settings.impressaoLinhasPulo, '1'),
  sincronizarAposLogin: settings.sincronizarAposLogin,
  modoExibicao: settings.modoExibicao,
  utilizaMaquininhaStone: settings.utilizaMaquininhaStone,
  tipoIntegracao: settings.tipoIntegracao,
  modeloMaquininha:
    settings.tipoIntegracao === 'stone'
      ? normalizeStoneModel(settings.modeloMaquininha)
      : settings.tipoIntegracao === 'getnet'
      ? normalizeGetNetModel(settings.modeloMaquininha)
      : settings.modeloMaquininha
});

const toMobileAppSettings = (
  values: SettingsState,
  empresa: string,
  existing: MobileAppSettings
): MobileAppSettings => ({
  ...existing,
  baseUrl: values.servidor.trim(),
  empresaId: parseInt(empresa, 10) || existing.empresaId,
  terminalImpressao: values.terminalImpressao.trim(),
  salvarLoginSenha: values.salvarLoginSenha,
  utilizaCatraca: values.utilizaCatraca,
  cobrarMaiorValorFracionado: values.cobrarMaiorValorFracionado,
  vincularComandaComMesa: values.vincularComandaComMesa,
  imprimirMesaAposFechamento: values.imprimirMesaAposFechamento,
  imprimirComandaAposFechamento: values.imprimirComandaAposFechamento,
  controleHappyHour: values.controleHappyHour,
  controlePromocao: values.controlePromocao,
  pesquisaCodigoProduto: values.pesquisaCodigoProduto,
  controleProximoGratis: values.controleProximoGratis,
  utilizaCategorias: values.utilizaCategorias,
  exibirImagem: values.exibirImagem,
  exigeNomeAbertura: values.exigeNomeAbertura,
  utilizaImpressoraInterna: values.utilizaImpressoraInterna,
  imprimirFichaIndividualProdutos: values.imprimirFichaIndividualProdutos,
  imprimirModelo: values.imprimirModelo,
  impressoraPaginaCodigo: values.impressoraPaginaCodigo,
  impressoraControlePorta: values.impressoraControlePorta,
  impressoraBluetooth: values.impressoraBluetooth,
  impressaoColunas: parseInt(values.impressaoColunas, 10) || 0,
  impressaoEspaco: parseInt(values.impressaoEspaco, 10) || 0,
  impressaoLinhasPulo: parseInt(values.impressaoLinhasPulo, 10) || 0,
  sincronizarAposLogin: values.sincronizarAposLogin,
  modoExibicao: values.modoExibicao,
  utilizaMaquininhaStone: values.utilizaMaquininhaStone || values.tipoIntegracao !== 'nenhum',
  tipoIntegracao: values.tipoIntegracao,
  modeloMaquininha:
    values.tipoIntegracao === 'stone'
      ? normalizeStoneModel(values.modeloMaquininha)
      : values.tipoIntegracao === 'getnet'
      ? normalizeGetNetModel(values.modeloMaquininha)
      : values.modeloMaquininha
});

export const SettingsScreen: React.FC = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParams, 'Configuracoes'>>();
  const { appSettings, saveAppSettings, checkApiConnection } = useApp();
  const [empresa, setEmpresa] = useState('1');
  const [salvando, setSalvando] = useState(false);
  const [status, setStatus] = useState('');
  const [showSavedAlert, setShowSavedAlert] = useState(false);
  const [overlayOpacity] = useState(() => new Animated.Value(0));
  const [cardScale] = useState(() => new Animated.Value(0.92));
  const [settings, setSettings] = useState<SettingsState>(() => toSettingsState(appSettings));
  const [companyInfo, setCompanyInfo] = useState<CompanyInfo | null>(null);
  const [consultandoGetNet, setConsultandoGetNet] = useState(false);
  const [executandoGetNetAcao, setExecutandoGetNetAcao] = useState<'status' | 'refund' | 'subsellers' | null>(null);
  const [executandoPosDigitalAcao, setExecutandoPosDigitalAcao] = useState<
    'sdk' | 'environment' | 'ledOn' | 'ledOff' | 'beep' | 'card' | 'mifare' | null
  >(null);
  const [ultimaGetNet, setUltimaGetNet] = useState<StoredGetNetTransaction | null>(null);
  const [ultimoGetNetSubsellers, setUltimoGetNetSubsellers] = useState<StoredGetNetSubsellers | null>(null);
  const hasLocalChangesRef = useRef(false);
  const savingRef = useRef(false);

  useEffect(() => {
    if (savingRef.current || hasLocalChangesRef.current) {
      return;
    }
    setEmpresa(String(appSettings.empresaId || 1));
    setSettings(toSettingsState(appSettings));
  }, [appSettings]);

  useEffect(() => {
    let active = true;

    const loadLastTransaction = async () => {
      const [stored, storedSubsellers] = await Promise.all([
        loadLastGetNetTransaction(),
        loadLastGetNetSubsellers()
      ]);
      if (active) {
        setUltimaGetNet(stored);
        setUltimoGetNetSubsellers(storedSubsellers);
      }
    };

    loadLastTransaction().catch(() => {
      if (active) {
        setUltimaGetNet(null);
        setUltimoGetNetSubsellers(null);
      }
    });

    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    let active = true;

    const loadCompanyInfo = async () => {
      try {
        const company = await api.getCompanyInfo();
        if (!active) {
          return;
        }
        setCompanyInfo(company);
        if (savingRef.current || hasLocalChangesRef.current) {
          return;
        }
        setSettings((prev) => {
          const normalized = applyCompanyPolicyToSettings(
            toMobileAppSettings(prev, empresa, appSettings),
            company
          );
          return toSettingsState(normalized);
        });
      } catch {
        if (!active) {
          return;
        }
        setCompanyInfo(null);
      }
    };

    loadCompanyInfo().catch(() => null);

    return () => {
      active = false;
    };
  }, [appSettings]);

  const settingMemo = useMemo(() => settings, [settings]);
  const integrationOptions = useMemo(
    () =>
      INTEGRACAO_OPTIONS.filter((option) => {
        if (option.value === 'stone') return companyInfo?.utilizaIntegracaoStone !== false;
        if (option.value === 'pagbank') return companyInfo?.utilizaIntegracaoPagBank !== false;
        if (option.value === 'cielo') return companyInfo?.utilizaIntegracaoCielo !== false;
        if (option.value === 'getnet') return companyInfo?.utilizaIntegracaoGetNet !== false;
        return true;
      }),
    [companyInfo]
  );

  const setValue = <K extends keyof SettingsState>(key: K, value: SettingsState[K]) => {
    hasLocalChangesRef.current = true;
    setSettings((prev) => ({
      ...prev,
      [key]: value
    }));
  };

  const setOpeningRuleValue = (
    key: 'vincularComandaComMesa' | 'exigeNomeAbertura',
    value: boolean
  ) => {
    if (!value) {
      setValue(key, false);
      return;
    }

    const nextState =
      key === 'vincularComandaComMesa'
        ? {
            vincularComandaComMesa: true,
            exigeNomeAbertura: settingMemo.exigeNomeAbertura
          }
        : {
            vincularComandaComMesa: settingMemo.vincularComandaComMesa,
            exigeNomeAbertura: true
          };

    if (hasConflictingOpeningSettings(nextState)) {
      Alert.alert('Aviso', OPENING_SETTINGS_CONFLICT_MESSAGE);
      return;
    }

    setValue(key, true);
  };

  const setComboValue = (key: keyof SettingsState, value: string) => {
    hasLocalChangesRef.current = true;
    setSettings((prev) => ({ ...prev, [key]: value } as SettingsState));
  };

  const setMaquininhaEnabled = (value: boolean) => {
    hasLocalChangesRef.current = true;
    setSettings((prev) => ({
      ...prev,
      utilizaMaquininhaStone: value,
      sincronizarAposLogin: value ? true : prev.sincronizarAposLogin,
      tipoIntegracao: value
        ? (prev.tipoIntegracao === 'nenhum' ? (integrationOptions[0]?.value || 'stone') : prev.tipoIntegracao)
        : 'nenhum',
      modeloMaquininha: value
        ? !prev.modeloMaquininha || prev.modeloMaquininha === 'false'
          ? getMachineModelLabel(prev.tipoIntegracao === 'nenhum' ? (integrationOptions[0]?.value || 'stone') : prev.tipoIntegracao)
          : prev.modeloMaquininha
        : 'false'
    }));
  };

  const setIntegracao = (value: IntegrationValue) => {
    hasLocalChangesRef.current = true;
    setSettings((prev) => ({
      ...prev,
      tipoIntegracao: value,
      modeloMaquininha:
        value === 'stone'
          ? normalizeStoneModel(prev.modeloMaquininha)
          : value === 'getnet'
          ? normalizeGetNetModel(prev.modeloMaquininha)
          : getMachineModelLabel(value)
    }));
  };

  const setEmpresaValue = (value: string) => {
    hasLocalChangesRef.current = true;
    setEmpresa(value);
  };

  const save = async () => {
    const next = {
      ...toMobileAppSettings(settingMemo, empresa, appSettings),
      baseUrl: normalizeServerUrl(settingMemo.servidor)
    };

    const serverValidationMessage = validateServerUrl(next.baseUrl);
    if (serverValidationMessage) {
      setStatus(serverValidationMessage);
      Alert.alert('Servidor inválido', serverValidationMessage);
      return;
    }

    if (hasConflictingOpeningSettings(next)) {
      setStatus(OPENING_SETTINGS_CONFLICT_MESSAGE);
      Alert.alert('Aviso', OPENING_SETTINGS_CONFLICT_MESSAGE);
      return;
    }

    savingRef.current = true;
    setSalvando(true);
    setStatus('Salvando configurações...');
    try {
      await saveAppSettings(next);
      setEmpresa(String(next.empresaId || 1));
      setSettings(toSettingsState(next));
      hasLocalChangesRef.current = false;
      const connection = await withConnectionCheckTimeout(checkApiConnection);
      if (!connection.ok) {
        const warning = buildConnectionWarning(connection.status, connection.message);
        setStatus(warning);
        Alert.alert('Configuração salva', warning);
        return;
      }

      setStatus('Configurações salvas e API conectada com sucesso.');
      openSavedAlert();
    } catch (error: any) {
      const message = error?.message || 'Não foi possível salvar. Tente novamente.';
      setStatus(message);
      Alert.alert('Aviso', message);
    } finally {
      savingRef.current = false;
      setSalvando(false);
    }
  };

  const closeSavedAlert = () => {
    Animated.parallel([
      Animated.timing(overlayOpacity, {
        toValue: 0,
        duration: 150,
        useNativeDriver: true,
        easing: Easing.out(Easing.ease)
      }),
      Animated.timing(cardScale, {
        toValue: 0.92,
        duration: 150,
        useNativeDriver: true,
        easing: Easing.out(Easing.ease)
      })
    ]).start(() => {
      setShowSavedAlert(false);
      const state = navigation.getState();
      const hasInicial = state.routeNames.includes('Inicial');
      if (hasInicial) {
        navigation.navigate('Inicial' as never);
      } else if (navigation.canGoBack()) {
        navigation.goBack();
      } else {
        navigation.reset({
          index: 0,
          routes: [{ name: 'Login' }]
        });
      }
    });
  };

  const openSavedAlert = () => {
    overlayOpacity.setValue(0);
    cardScale.setValue(0.92);
    setShowSavedAlert(true);
    Animated.parallel([
      Animated.timing(overlayOpacity, {
        toValue: 1,
        duration: 180,
        useNativeDriver: true,
        easing: Easing.out(Easing.ease)
      }),
      Animated.spring(cardScale, {
        toValue: 1,
        useNativeDriver: true,
        damping: 16,
        stiffness: 160,
        mass: 0.9
      })
    ]).start();
  };

  const testPrinter = () => {
    Alert.alert('Teste de impressão', 'Simulação de impressão enviada com sucesso.');
  };

  const testGetNetTerminalInfo = async () => {
    if (Platform.OS !== 'android') {
      Alert.alert('Aviso', 'A consulta da GetNet está disponível somente no Android.');
      return;
    }

    const currentSettings = toMobileAppSettings(settingMemo, empresa, appSettings);
    setConsultandoGetNet(true);
    try {
      const terminalInfo = await executeGetNetTerminalInfo({
        settings: currentSettings
      });

      const lines = [
        `EC: ${terminalInfo.ec || '-'}`,
        `Número de série: ${terminalInfo.numSerie || '-'}`,
        `Número lógico: ${terminalInfo.numLogic || '-'}`,
        `Versão: ${terminalInfo.version || '-'}`,
        `CNPJ: ${terminalInfo.cnpj || '-'}`,
        `Razão social: ${terminalInfo.razaoSocial || '-'}`,
        `Cidade: ${terminalInfo.cidade || '-'}`,
        terminalInfo.nome ? `Nome EC: ${terminalInfo.nome}` : ''
      ].filter(Boolean);

      Alert.alert('Dados do terminal GetNet', lines.join('\n'));
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível consultar os dados do terminal GetNet.');
    } finally {
      setConsultandoGetNet(false);
    }
  };

  const consultLastGetNetStatus = async () => {
    if (Platform.OS !== 'android') {
      Alert.alert('Aviso', 'A consulta da GetNet está disponível somente no Android.');
      return;
    }

    const currentSettings = toMobileAppSettings(settingMemo, empresa, appSettings);
    setExecutandoGetNetAcao('status');
    try {
      const result = await executeGetNetStatus({
        settings: currentSettings
      });
      setUltimaGetNet(result.transaction);

      const lines = [
        `Mensagem: ${result.message || '-'}`,
        `CallerId: ${result.transaction.callerId || '-'}`,
        `Valor: ${result.transaction.amount || '-'}`,
        `NSU: ${result.transaction.nsu || '-'}`,
        `CV: ${result.transaction.cvNumber || '-'}`,
        `Bandeira: ${result.transaction.brand || '-'}`,
        `Tipo: ${result.transaction.type || '-'}`,
        `Entrada: ${result.transaction.inputType || '-'}`,
        `Status: ${result.pending ? 'Pendente' : result.approved ? 'Aprovado' : result.cancelled ? 'Cancelado' : result.denied ? 'Negado' : 'Sem confirmação'}`,
        `Estornada: ${result.refunded ? 'Sim' : 'Nao'}`
      ];

      Alert.alert('Status da última transação GetNet', lines.join('\n'));
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível consultar o status da última transação GetNet.');
    } finally {
      setExecutandoGetNetAcao(null);
    }
  };

  const refundLastGetNetTransaction = async () => {
    if (Platform.OS !== 'android') {
      Alert.alert('Aviso', 'O estorno da GetNet está disponível somente no Android.');
      return;
    }

    const currentSettings = toMobileAppSettings(settingMemo, empresa, appSettings);
    setExecutandoGetNetAcao('refund');
    try {
      const result = await executeGetNetRefund({
        settings: currentSettings
      });
      if (result.transaction) {
        setUltimaGetNet(result.transaction);
      }

      Alert.alert(
        'Estorno GetNet',
        [`Mensagem: ${result.message || '-'}`, `Valor: ${result.amount || '-'}`].join('\n')
      );
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível estornar a última transação GetNet.');
    } finally {
      setExecutandoGetNetAcao(null);
    }
  };

  const refreshGetNetSubsellers = async () => {
    if (Platform.OS !== 'android') {
      Alert.alert('Aviso', 'A consulta de Subsellers da GetNet está disponível somente no Android.');
      return;
    }

    const currentSettings = toMobileAppSettings(settingMemo, empresa, appSettings);
    setExecutandoGetNetAcao('subsellers');
    try {
      const result = await executeGetNetCheckSubsellers({
        settings: currentSettings
      });
      setUltimoGetNetSubsellers(result.payload);

      Alert.alert(
        'Subsellers GetNet',
        [
          `Marketplace: ${result.payload.marketPlaceId || '-'}`,
          `Qtd. Subsellers: ${result.payload.subsellers.length}`
        ].join('\n')
      );
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível consultar os Subsellers da GetNet.');
    } finally {
      setExecutandoGetNetAcao(null);
    }
  };

  const consultGetNetPosDigitalInfo = async () => {
    if (Platform.OS !== 'android') {
      Alert.alert('Aviso', 'A consulta PosDigital da GetNet está disponível somente no Android.');
      return;
    }

    setExecutandoPosDigitalAcao('sdk');
    try {
      const info = await getGetNetPosDigitalInfo();
      const lines = [
        `SDK: ${info.sdkVersion || '-'}`,
        `BC: ${info.bcVersion || '-'}`,
        `SO: ${info.osVersion || '-'}`,
        `Android: ${info.androidOSVersion || '-'}`,
        `Serial: ${info.serialNumber || '-'}`,
        `Modelo: ${info.model || '-'}`,
        `Fabricante: ${info.manufacturer || '-'}`,
        `IMEI: ${info.imei || '-'}`,
        `ICCID: ${info.iccid || '-'}`
      ];
      Alert.alert('PosDigital GetNet', lines.join('\n'));
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível consultar a PosDigital da GetNet.');
    } finally {
      setExecutandoPosDigitalAcao(null);
    }
  };

  const inspectGetNetPaymentEnvironment = async () => {
    if (Platform.OS !== 'android') {
      Alert.alert('Aviso', 'A verificação do ambiente de pagamento GetNet está disponível somente no Android.');
      return;
    }

    setExecutandoPosDigitalAcao('environment');
    try {
      const environment = await getGetNetPaymentEnvironment();
      const handler = environment.paymentHandlerPackage
        ? `${environment.paymentHandlerPackage}${environment.paymentHandlerClassName ? ` / ${environment.paymentHandlerClassName}` : ''}`
        : '-';
      const lines = [
        `Modo: ${environment.simulationMode ? 'SIMULACAO (Rebatedor)' : 'Sem simulacao detectada'}`,
        `Handler atual: ${handler}`,
        `PosDigital: ${environment.posDigitalInstalled ? 'Instalado' : 'Nao instalado'}`,
        `Devkit: ${environment.devkitInstalled ? 'Instalado' : 'Nao instalado'}`,
        `Rebatedor: ${environment.rebatedorInstalled ? 'Instalado' : 'Nao instalado'}`
      ];
      if (environment.simulationMode) {
        lines.push('O pagamento real fica bloqueado neste app enquanto o Rebatedor for o responsavel pelo deeplink GetNet.');
      }
      Alert.alert('Ambiente de pagamento GetNet', lines.join('\n'));
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível verificar o ambiente de pagamento GetNet.');
    } finally {
      setExecutandoPosDigitalAcao(null);
    }
  };

  const turnOnGetNetLeds = async () => {
    setExecutandoPosDigitalAcao('ledOn');
    try {
      await turnOnGetNetPosDigitalLeds();
      Alert.alert('GetNet', 'LEDs ligados com sucesso.');
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível ligar os LEDs da GetNet.');
    } finally {
      setExecutandoPosDigitalAcao(null);
    }
  };

  const turnOffGetNetLeds = async () => {
    setExecutandoPosDigitalAcao('ledOff');
    try {
      await turnOffGetNetPosDigitalLeds();
      Alert.alert('GetNet', 'LEDs desligados com sucesso.');
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível desligar os LEDs da GetNet.');
    } finally {
      setExecutandoPosDigitalAcao(null);
    }
  };

  const beepGetNet = async () => {
    setExecutandoPosDigitalAcao('beep');
    try {
      await beepGetNetPosDigitalSuccess();
      Alert.alert('GetNet', 'Beep executado com sucesso.');
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível executar o beep da GetNet.');
    } finally {
      setExecutandoPosDigitalAcao(null);
    }
  };

  const searchGetNetCard = async () => {
    setExecutandoPosDigitalAcao('card');
    try {
      const result = await searchGetNetPosDigitalCard();
      const lines = [
        `Tipo: ${result.type || '-'}`,
        `PAN: ${result.pan || '-'}`,
        `Track2: ${result.track2 || '-'}`,
        `Validade: ${result.expireDate || '-'}`,
        result.message ? `Mensagem: ${result.message}` : ''
      ].filter(Boolean);
      Alert.alert('Leitura de cartão GetNet', lines.join('\n'));
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível ler o cartão na GetNet.');
    } finally {
      setExecutandoPosDigitalAcao(null);
    }
  };

  const searchGetNetMifare = async () => {
    setExecutandoPosDigitalAcao('mifare');
    try {
      const result = await searchGetNetPosDigitalMifareUid();
      const lines = [
        `UID: ${result.uid || result.uidHex || '-'}`,
        result.uidBase64 ? `UID Base64: ${result.uidBase64}` : '',
        typeof result.cardType === 'number' ? `Tipo: ${result.cardType}` : ''
      ].filter(Boolean);
      Alert.alert('Leitura Mifare GetNet', lines.join('\n'));
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível ler o cartão Mifare na GetNet.');
    } finally {
      setExecutandoPosDigitalAcao(null);
    }
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      keyboardShouldPersistTaps="handled"
      keyboardDismissMode={Platform.OS === 'ios' ? 'interactive' : 'on-drag'}
    >
      <ScreenRouteLabel />
      <SectionHeader title="Configurações" />

      <Section title="Servidor e Login">
        <FieldInput
          label="Servidor (API)"
          value={settingMemo.servidor}
          onChangeText={(text) => setValue('servidor', text)}
          placeholder="192.168.15.30 ou https://mobile.rpfood.com.br"
        />
        <FieldInput
          label="Terminal de impressão"
          value={settingMemo.terminalImpressao}
          onChangeText={(text) => setValue('terminalImpressao', text)}
          placeholder="Terminal/porta da impressão"
        />
        <FieldInput
          label="Empresa"
          value={empresa}
          onChangeText={setEmpresaValue}
          placeholder="1"
          keyboardType="numeric"
        />

        <SettingSwitch
          label="Salvar login e senha"
          description="Grava usuário/senha da sessão atual para nova abertura."
          value={settingMemo.salvarLoginSenha}
          onValueChange={(value) => setValue('salvarLoginSenha', value)}
        />
        <SettingSwitch
          label="Sincronizar após login"
          description="Executa sincronização automaticamente ao entrar."
          value={settingMemo.sincronizarAposLogin}
          onValueChange={(value) => setValue('sincronizarAposLogin', value)}
        />
        <SettingSwitch
          label="Utiliza catraca"
          description="Ativa fluxo de leitura por catraca (quando disponível)."
          value={settingMemo.utilizaCatraca}
          onValueChange={(value) => setValue('utilizaCatraca', value)}
        />
      </Section>

      <Section title="Comandas, mesas e fluxo de lançamento">
        <SettingSwitch
          label="Cobrar maior valor fracionado"
          description="Ajusta cálculo para valores fracionários de produtos."
          value={settingMemo.cobrarMaiorValorFracionado}
          onValueChange={(value) => setValue('cobrarMaiorValorFracionado', value)}
        />
        <SettingSwitch
          label="Vincular comanda com mesa"
          description="Ativa vínculo entre abertura de comanda e mesa."
          value={settingMemo.vincularComandaComMesa}
          onValueChange={(value) => setOpeningRuleValue('vincularComandaComMesa', value)}
        />
        <SettingSwitch
          label="Impressão de mesa no fechamento"
          description="Imprime o cupom de mesa ao fechar."
          value={settingMemo.imprimirMesaAposFechamento}
          onValueChange={(value) => setValue('imprimirMesaAposFechamento', value)}
        />
        <SettingSwitch
          label="Impressão de comanda no fechamento"
          description="Imprime o cupom de comanda ao fechar."
          value={settingMemo.imprimirComandaAposFechamento}
          onValueChange={(value) => setValue('imprimirComandaAposFechamento', value)}
        />
        <SettingSwitch
          label="Utiliza controle Happy Hour"
          description="Exibe regras de preço por período."
          value={settingMemo.controleHappyHour}
          onValueChange={(value) => setValue('controleHappyHour', value)}
        />
        <SettingSwitch
          label="Utiliza controle de promoção"
          description="Respeita validações de campanhas e promoções."
          value={settingMemo.controlePromocao}
          onValueChange={(value) => setValue('controlePromocao', value)}
        />
        <SettingSwitch
          label="Pesquisa padrão por código"
          description="Usa código do produto como padrão de busca."
          value={settingMemo.pesquisaCodigoProduto}
          onValueChange={(value) => setValue('pesquisaCodigoProduto', value)}
        />
        <SettingSwitch
          label="Controle de próximo grátis"
          description="Ativa regras de brinde automático."
          value={settingMemo.controleProximoGratis}
          onValueChange={(value) => setValue('controleProximoGratis', value)}
        />
        <SettingSwitch
          label="Não utilizar categoria"
          description="Quando ligado, a tela de lançamento carrega todos os produtos sem filtrar por categoria."
          value={!settingMemo.utilizaCategorias}
          onValueChange={(value) => setValue('utilizaCategorias', !value)}
        />
        <SettingSwitch
          label="Exibir imagem dos itens"
          description="Quando desligado, o app oculta e evita buscar imagens do catálogo para ficar mais leve."
          value={settingMemo.exibirImagem}
          onValueChange={(value) => setValue('exibirImagem', value)}
        />
        <SettingSwitch
          label="Exige nome na abertura da mesa/comanda"
          description="Solicita identificação antes de abrir."
          value={settingMemo.exigeNomeAbertura}
          onValueChange={(value) => setOpeningRuleValue('exigeNomeAbertura', value)}
        />
      </Section>

      <Section title="Modo da tela inicial">
        <Text style={styles.label}>Modo de exibição</Text>
        <View style={styles.radioRow}>
          <Pressable
            style={[styles.chip, settingMemo.modoExibicao === 'mesa' && styles.chipActive]}
            onPress={() => setValue('modoExibicao', 'mesa')}
          >
            <Text style={[styles.chipText, settingMemo.modoExibicao === 'mesa' && styles.chipTextActive]}>Mesa</Text>
          </Pressable>
          <Pressable
            style={[styles.chip, settingMemo.modoExibicao === 'comanda' && styles.chipActive]}
            onPress={() => setValue('modoExibicao', 'comanda')}
          >
            <Text style={[styles.chipText, settingMemo.modoExibicao === 'comanda' && styles.chipTextActive]}>Comanda</Text>
          </Pressable>
          <Pressable
            style={[styles.chip, settingMemo.modoExibicao === 'mesaComanda' && styles.chipActive]}
            onPress={() => setValue('modoExibicao', 'mesaComanda')}
          >
            <Text style={[styles.chipText, settingMemo.modoExibicao === 'mesaComanda' && styles.chipTextActive]}>
              Mesa + Comanda
            </Text>
          </Pressable>
        </View>
      </Section>

      <Section title="Impressora">
        <SettingSwitch
          label="Utiliza impressora interna"
          description="Emissão de impressão via dispositivo local."
          value={settingMemo.utilizaImpressoraInterna}
          onValueChange={(value) => setValue('utilizaImpressoraInterna', value)}
        />
        <SettingSwitch
          label="Imprimir ficha individual do produto"
          description="Cada produto pode gerar linha de ficha separada."
          value={settingMemo.imprimirFichaIndividualProdutos}
          onValueChange={(value) => setValue('imprimirFichaIndividualProdutos', value)}
        />
        <FieldSelect
          label="Modelo da impressora"
          value={settingMemo.imprimirModelo}
          options={IMPRESSORA_MODELOS}
          onChange={(value) => setComboValue('imprimirModelo', value)}
        />
        <FieldSelect
          label="Página de código"
          value={settingMemo.impressoraPaginaCodigo}
          options={IMPRESSAO_PAGINAS}
          onChange={(value) => setComboValue('impressoraPaginaCodigo', value)}
        />
        <SettingSwitch
          label="Controle de porta"
          description="Lê impressora como recurso de controle de porta."
          value={settingMemo.impressoraControlePorta}
          onValueChange={(value) => setValue('impressoraControlePorta', value)}
        />
        <FieldSelect
          label="Impressora Bluetooth"
          value={settingMemo.impressoraBluetooth}
          options={BLUETOOTH_LIST}
          onChange={(value) => setComboValue('impressoraBluetooth', value)}
        />
        <Pressable onPress={() => setComboValue('impressoraBluetooth', BLUETOOTH_LIST[1])} style={styles.secondaryBtn}>
          <Text style={styles.secondaryBtnText}>Buscar Bluetooth</Text>
        </Pressable>
        <FieldInput
          label="Impressão - colunas"
          value={settingMemo.impressaoColunas}
          onChangeText={(value) => setComboValue('impressaoColunas', value.replace(/\D/g, ''))}
          keyboardType="number-pad"
          placeholder="48"
        />
        <FieldInput
          label="Impressão - espaços"
          value={settingMemo.impressaoEspaco}
          onChangeText={(value) => setComboValue('impressaoEspaco', value.replace(/\D/g, ''))}
          keyboardType="number-pad"
          placeholder="0"
        />
        <FieldInput
          label="Linhas de pulo"
          value={settingMemo.impressaoLinhasPulo}
          onChangeText={(value) => setComboValue('impressaoLinhasPulo', value.replace(/\D/g, ''))}
          keyboardType="number-pad"
          placeholder="1"
        />
        <Pressable onPress={testPrinter} style={styles.secondaryBtn}>
          <Text style={styles.secondaryBtnText}>Testar impressão</Text>
        </Pressable>
      </Section>

      <Section title="Maquininha de cartão">
        <SettingSwitch
          label="Utiliza maquininhas"
          description="Libera painel de integração de cartão."
          value={settingMemo.utilizaMaquininhaStone}
          onValueChange={(value) => setMaquininhaEnabled(value)}
        />
        {settingMemo.utilizaMaquininhaStone ? (
          <View style={styles.field}>
            <Text style={styles.label}>Tipo de integração</Text>
            <View style={styles.radioRow}>
              {integrationOptions.map((option) => (
                <Pressable
                  key={option.value}
                  onPress={() => setIntegracao(option.value)}
                  style={[styles.chip, settingMemo.tipoIntegracao === option.value && styles.chipActive]}
                >
                  <Text style={[styles.chipText, settingMemo.tipoIntegracao === option.value && styles.chipTextActive]}>
                    {option.label}
                  </Text>
                </Pressable>
              ))}
            </View>
            {settingMemo.tipoIntegracao === 'stone' ? (
              <FieldSelect
                label="Modelo Stone"
                value={normalizeStoneModel(settingMemo.modeloMaquininha)}
                options={STONE_MODEL_OPTIONS}
                onChange={(value) => setComboValue('modeloMaquininha', normalizeStoneModel(value))}
              />
            ) : null}
            {settingMemo.tipoIntegracao === 'getnet' ? (
              <>
                <FieldSelect
                  label="Modelo GetNet"
                  value={normalizeGetNetModel(settingMemo.modeloMaquininha)}
                  options={GETNET_MODEL_OPTIONS}
                  onChange={(value) => setComboValue('modeloMaquininha', normalizeGetNetModel(value))}
                />
                <Pressable
                  onPress={testGetNetTerminalInfo}
                  style={[styles.secondaryBtn, consultandoGetNet ? styles.disabledBtn : null]}
                  disabled={consultandoGetNet}
                >
                  <Text style={styles.secondaryBtnText}>
                    {consultandoGetNet ? 'Consultando terminal GetNet...' : 'Consultar dados do terminal GetNet'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={consultGetNetPosDigitalInfo}
                  style={[styles.secondaryBtn, executandoPosDigitalAcao === 'sdk' ? styles.disabledBtn : null]}
                  disabled={executandoPosDigitalAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoPosDigitalAcao === 'sdk'
                      ? 'Consultando PosDigital GetNet...'
                      : 'Consultar SDK PosDigital GetNet'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={inspectGetNetPaymentEnvironment}
                  style={[styles.secondaryBtn, executandoPosDigitalAcao === 'environment' ? styles.disabledBtn : null]}
                  disabled={executandoPosDigitalAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoPosDigitalAcao === 'environment'
                      ? 'Verificando ambiente de pagamento GetNet...'
                      : 'Verificar ambiente de pagamento GetNet'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={turnOnGetNetLeds}
                  style={[styles.secondaryBtn, executandoPosDigitalAcao === 'ledOn' ? styles.disabledBtn : null]}
                  disabled={executandoPosDigitalAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoPosDigitalAcao === 'ledOn' ? 'Ligando LEDs GetNet...' : 'Ligar LEDs GetNet'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={turnOffGetNetLeds}
                  style={[styles.secondaryBtn, executandoPosDigitalAcao === 'ledOff' ? styles.disabledBtn : null]}
                  disabled={executandoPosDigitalAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoPosDigitalAcao === 'ledOff' ? 'Desligando LEDs GetNet...' : 'Desligar LEDs GetNet'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={beepGetNet}
                  style={[styles.secondaryBtn, executandoPosDigitalAcao === 'beep' ? styles.disabledBtn : null]}
                  disabled={executandoPosDigitalAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoPosDigitalAcao === 'beep' ? 'Executando beep GetNet...' : 'Beep de sucesso GetNet'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={searchGetNetCard}
                  style={[styles.secondaryBtn, executandoPosDigitalAcao === 'card' ? styles.disabledBtn : null]}
                  disabled={executandoPosDigitalAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoPosDigitalAcao === 'card' ? 'Lendo cartão GetNet...' : 'Ler cartão GetNet'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={searchGetNetMifare}
                  style={[styles.secondaryBtn, executandoPosDigitalAcao === 'mifare' ? styles.disabledBtn : null]}
                  disabled={executandoPosDigitalAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoPosDigitalAcao === 'mifare' ? 'Lendo Mifare GetNet...' : 'Ler cartão Mifare GetNet'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={consultLastGetNetStatus}
                  style={[styles.secondaryBtn, executandoGetNetAcao === 'status' ? styles.disabledBtn : null]}
                  disabled={executandoGetNetAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoGetNetAcao === 'status'
                      ? 'Consultando status da GetNet...'
                      : 'Consultar status da última transação'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={refreshGetNetSubsellers}
                  style={[styles.secondaryBtn, executandoGetNetAcao === 'subsellers' ? styles.disabledBtn : null]}
                  disabled={executandoGetNetAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoGetNetAcao === 'subsellers'
                      ? 'Consultando Subsellers GetNet...'
                      : 'Atualizar Subsellers GetNet'}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={refundLastGetNetTransaction}
                  style={[styles.secondaryBtn, executandoGetNetAcao === 'refund' ? styles.disabledBtn : null]}
                  disabled={executandoGetNetAcao !== null}
                >
                  <Text style={styles.secondaryBtnText}>
                    {executandoGetNetAcao === 'refund' ? 'Solicitando estorno na GetNet...' : 'Estornar última transação GetNet'}
                  </Text>
                </Pressable>
                {ultimaGetNet ? (
                  <View style={styles.machineInfoCard}>
                    <Text style={styles.machineInfoTitle}>Última transação GetNet</Text>
                    <Text style={styles.machineInfoText}>CallerId: {ultimaGetNet.callerId || '-'}</Text>
                    <Text style={styles.machineInfoText}>Valor: {ultimaGetNet.amount || '-'}</Text>
                    <Text style={styles.machineInfoText}>NSU: {ultimaGetNet.nsu || '-'}</Text>
                    <Text style={styles.machineInfoText}>CV: {ultimaGetNet.cvNumber || '-'}</Text>
                    <Text style={styles.machineInfoText}>Bandeira: {ultimaGetNet.brand || '-'}</Text>
                    <Text style={styles.machineInfoText}>Atualizado em: {ultimaGetNet.updatedAt || '-'}</Text>
                  </View>
                ) : null}
                {ultimoGetNetSubsellers ? (
                  <View style={styles.machineInfoCard}>
                    <Text style={styles.machineInfoTitle}>Subsellers GetNet</Text>
                    <Text style={styles.machineInfoText}>Marketplace: {ultimoGetNetSubsellers.marketPlaceId || '-'}</Text>
                    <Text style={styles.machineInfoText}>Qtd. subsellers: {ultimoGetNetSubsellers.subsellers.length}</Text>
                    <Text style={styles.machineInfoText}>Atualizado em: {ultimoGetNetSubsellers.updatedAt || '-'}</Text>
                    {ultimoGetNetSubsellers.subsellers.slice(0, 3).map((item) => (
                      <Text key={`subs-${item.id}-${item.document}`} style={styles.machineInfoText}>
                        {item.name || 'Sem nome'} · {item.document || 'Sem documento'}
                      </Text>
                    ))}
                  </View>
                ) : null}
              </>
            ) : null}
          </View>
        ) : null}
      </Section>

      <Pressable
        style={[styles.saveWrap, salvando ? styles.disabledBtn : null]}
        onPress={save}
        disabled={salvando}
      >
        <Text style={styles.saveButton}>{salvando ? 'Salvando...' : 'Salvar configurações'}</Text>
      </Pressable>
      {!!status && <Text style={styles.saveStatus}>{status}</Text>}
      <Modal
        visible={showSavedAlert}
        transparent
        animationType="fade"
        onRequestClose={closeSavedAlert}
      >
        <Animated.View style={[styles.alertOverlay, { opacity: overlayOpacity }]}>
          <Pressable style={styles.alertOverlayPress} onPress={closeSavedAlert}>
        <Animated.View style={[styles.alertCard, { transform: [{ scale: cardScale }] }]}>
              <Pressable onPress={() => {}}>
                <View style={styles.alertIconWrap}>
                  <Text style={styles.alertIcon}>✓</Text>
                </View>
                <Text style={styles.alertText}>Salvo com sucesso.</Text>
                <Pressable style={styles.alertBtn} onPress={closeSavedAlert}>
                  <Text style={styles.alertBtnText}>OK</Text>
                </Pressable>
              </Pressable>
            </Animated.View>
          </Pressable>
        </Animated.View>
      </Modal>
    </ScrollView>
  );
};

const Section: React.FC<{ title: string; children: React.ReactNode }> = ({ title, children }) => (
  <View style={styles.card}>
    <Text style={styles.sectionTitle}>{title}</Text>
    {children}
  </View>
);

const FieldInput: React.FC<{
  label: string;
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'numeric' | 'number-pad';
}> = ({ label, value, onChangeText, placeholder, keyboardType = 'default' }) => (
  <View style={styles.field}>
    <Text style={styles.label}>{label}</Text>
    <TextInput
      style={styles.input}
      value={value}
      onChangeText={onChangeText}
      placeholder={placeholder}
      placeholderTextColor={Colors.textMuted}
      keyboardType={keyboardType}
    />
  </View>
);

const FieldSelect: React.FC<{
  label: string;
  value: string;
  options: string[];
  onChange: (value: string) => void;
}> = ({ label, value, options, onChange }) => (
  <View style={styles.field}>
    <Text style={styles.label}>{label}</Text>
    <View style={styles.selectWrap}>
      {options.map((option) => (
        <Pressable
          key={option}
          onPress={() => onChange(option)}
          style={[styles.optionChip, value === option && styles.optionChipActive]}
        >
          <Text style={[styles.optionText, value === option && styles.optionTextActive]}>{option}</Text>
        </Pressable>
      ))}
    </View>
  </View>
);

const SettingSwitch = ({
  label,
  description,
  value,
  onValueChange
}: {
  label: string;
  description: string;
  value: boolean;
  onValueChange: (value: boolean) => void;
}) => {
  return (
    <View style={styles.settingRow}>
      <View style={{ flex: 1 }}>
        <Text style={styles.settingTitle}>{label}</Text>
        <Text style={styles.settingDesc}>{description}</Text>
      </View>
      <Switch value={value} onValueChange={onValueChange} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background, padding: Space.md },
  content: { paddingBottom: 120 },
  card: {
    backgroundColor: Colors.card,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Space.md,
    marginBottom: Space.md,
    ...Shadows.card
  },
  sectionTitle: {
    fontSize: 16,
    color: Colors.text,
    fontWeight: '800',
    marginBottom: 12
  },
  field: {
    marginBottom: 10
  },
  label: {
    color: Colors.textMuted,
    marginBottom: 6,
    fontWeight: '700',
    fontSize: 12
  },
  input: {
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    backgroundColor: Colors.cardSoft,
    color: Colors.text,
    borderRadius: 18,
    padding: 12
  },
  selectWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8
  },
  optionChip: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 999,
    marginBottom: 8
  },
  optionChipActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft
  },
  optionText: {
    color: Colors.textMuted,
    fontWeight: '700'
  },
  optionTextActive: {
    color: Colors.primary
  },
  settingRow: {
    marginBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
    paddingBottom: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10
  },
  settingTitle: {
    color: Colors.text,
    fontWeight: '700'
  },
  settingDesc: {
    color: Colors.textMuted,
    fontSize: 11,
    marginTop: 4
  },
  radioRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    borderRadius: 999,
    paddingVertical: 10,
    paddingHorizontal: 14,
    marginBottom: 4
  },
  chipActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft
  },
  chipText: {
    color: Colors.textMuted,
    fontWeight: '700'
  },
  chipTextActive: {
    color: Colors.primary
  },
  secondaryBtn: {
    borderRadius: 18,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: 13,
    paddingHorizontal: 14,
    marginBottom: 8,
    alignItems: 'center',
    backgroundColor: Colors.cardSoft,
    ...Shadows.soft
  },
  secondaryBtnText: {
    fontWeight: '700',
    color: Colors.primary
  },
  machineInfoCard: {
    marginTop: 8,
    padding: 12,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft
  },
  machineInfoTitle: {
    color: Colors.text,
    fontWeight: '800',
    marginBottom: 8
  },
  machineInfoText: {
    color: Colors.textMuted,
    fontSize: 12,
    marginBottom: 4
  },
  saveWrap: {
    borderRadius: 20,
    overflow: 'hidden',
    marginBottom: 24
  },
  disabledBtn: {
    opacity: 0.65
  },
  saveButton: {
    backgroundColor: Colors.primary,
    color: '#fff',
    paddingVertical: 16,
    textAlign: 'center',
    fontWeight: '700'
  },
  saveStatus: {
    color: Colors.text,
    marginTop: 8,
    fontSize: 12,
    textAlign: 'center'
  },
  alertOverlay: {
    flex: 1,
    backgroundColor: 'rgba(7, 12, 26, 0.72)',
    justifyContent: 'center',
    alignItems: 'center'
  },
  alertOverlayPress: {
    flex: 1,
    width: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    padding: Space.md
  },
  alertCard: {
    width: '88%',
    backgroundColor: Colors.card,
    borderRadius: Radius.lg,
    padding: Space.lg,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.border,
    shadowColor: '#0b1020',
    shadowOffset: { width: 0, height: 14 },
    shadowOpacity: 0.25,
    shadowRadius: 18,
    elevation: 12,
    overflow: 'hidden'
  },
  alertIconWrap: {
    width: 58,
    height: 58,
    borderRadius: 999,
    marginBottom: 10,
    backgroundColor: '#22c55e',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#16a34a',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.45,
    shadowRadius: 12,
    elevation: 8
  },
  alertIcon: {
    color: '#fff',
    fontSize: 30,
    fontWeight: '900'
  },
  alertText: {
    color: Colors.textMuted,
    textAlign: 'center',
    marginBottom: 18,
    lineHeight: 20
  },
  alertBtn: {
    backgroundColor: Colors.primary,
    borderRadius: Radius.md,
    paddingHorizontal: 24,
    paddingVertical: 11,
    width: '100%',
    alignItems: 'center'
  },
  alertBtnText: {
    color: '#fff',
    fontWeight: '700'
  }
});
