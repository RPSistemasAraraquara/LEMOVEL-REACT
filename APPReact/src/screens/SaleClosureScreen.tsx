import React, { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Alert, Keyboard, Modal, Pressable, ScrollView, StyleSheet, Switch, Text, TextInput, TouchableOpacity, View, useWindowDimensions } from 'react-native';
import { CommonActions, useFocusEffect, useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useApp } from '../context/AppContext';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { SweetAlert, SweetAlertType } from '../components/SweetAlert';
import { api, normalizeSaleStatus, PaymentMethod, Sale, SalePayment } from '../services/api';
import {
  abortActivePayment,
  executePayment,
  formatPaymentProviderLabel,
  preparePaymentProvider,
  requiresPaymentProcessingAtAdd,
  resolveConfiguredPaymentProvider,
  resolvePaymentProviderForMethod
} from '../services/payment';
import { executeSalePrint, loadSalePrintContent, printSaleContent, resolveMachineType } from '../services/vendaPrint';
import { Colors, Radius, Space } from '../theme';
import { RootStackParams } from '../navigation/AppNavigator';

type Route = RouteProp<RootStackParams, 'Fechamento'>;
type Navigation = NativeStackNavigationProp<RootStackParams>;
type ClosureMode = 'pre' | 'final';
type ReturnTarget = 'Inicial' | 'Cardapio' | 'Gestao' | 'Mesas';
type PaymentLine = {
  codigo: number;
  valor: string;
  processed?: boolean;
  sfiCodigo?: number;
  provider?: string;
  nsu?: string;
};
type DiscountInputMode = 'value' | 'percent';

const parseMoney = (value: string): number => {
  const valueNumber = Number(value.replace(',', '.'));
  return Number.isFinite(valueNumber) ? valueNumber : 0;
};

const parseInteger = (value: string): number => {
  const valueNumber = parseMoney(value);
  const rounded = Math.round(valueNumber);
  return Number.isFinite(rounded) ? Math.max(0, rounded) : 0;
};

const formatMoney = (value?: number): string => `R$ ${(value || 0).toFixed(2)}`;
const formatDiscountInput = (value: number): string => {
  if (!Number.isFinite(value) || value <= 0) {
    return '0';
  }

  return value.toFixed(2);
};
const mergeSalePayments = (...groups: Array<SalePayment[] | undefined>): SalePayment[] => {
  const merged: SalePayment[] = [];
  const seen = new Set<string>();
  groups.forEach((group) => {
    (group || []).forEach((item) => {
      const key = String(
        item.idVendaPagamentoAntecipado ||
        `${Number(item.idFormaPagamento || item.formaPagamento?.codigo || 0)}-${Number(item.valor || 0).toFixed(2)}-${item.dataHora || ''}`
      );
      if (seen.has(key)) {
        return;
      }
      seen.add(key);
      merged.push(item);
    });
  });
  return merged;
};
const normalizeDiscountNumber = (value: number): number => {
  if (!Number.isFinite(value)) {
    return 0;
  }

  return Math.max(0, value);
};
const calculateDiscountValueFromPercent = (total: number, percentInput: string): number => {
  const percentual = normalizeDiscountNumber(parseMoney(percentInput));
  return total > 0 ? (total * percentual) / 100 : 0;
};
const calculateDiscountPercentFromValue = (total: number, valueInput: string): number => {
  const valor = normalizeDiscountNumber(parseMoney(valueInput));
  return total > 0 ? (valor / total) * 100 : 0;
};
const toDisplayStatus = (value?: string): string => {
  const normalized = normalizeSaleStatus(value || '');
  if (normalized.includes('pendente')) return 'Pendente';
  if (normalized.includes('prefechamento')) return 'Pré-fechamento';
  if (normalized.includes('digitacao')) return 'Digitação';
  if (normalized.includes('aberta')) return 'Aberta';
  if (normalized.includes('finalizada')) return 'Finalizada';
  if (normalized.includes('cancelada')) return 'Cancelada';
  if (normalized.includes('reservada')) return 'Reservada';
  return 'Sem situação';
};

const parsePrintCommandsToText = (raw: string): string => {
  const extractLines = (payload: any): string[] => {
    if (!payload) return [];
    if (Array.isArray(payload)) {
      return payload.flatMap((item) => extractLines(item));
    }

    if (typeof payload === 'string') {
      return [payload];
    }

    if (typeof payload !== 'object') {
      return [];
    }

    const command = payload as Record<string, unknown>;
    const type = String(command.type || '').toLowerCase();
    const content = command.content;

    if (type === 'line') {
      return [String(content ?? '--------------------------------')];
    }

    if (type === 'text') {
      return [String(content ?? '')];
    }

    if (Array.isArray(command.commands)) {
      return extractLines(command.commands);
    }

    if (Array.isArray(command.data)) {
      return extractLines(command.data);
    }

    if (content !== undefined && content !== null) {
      return [String(content)];
    }

    return [];
  };

  const normalizeText = (value: string): string =>
    value
      .replace(/\r\n/g, '\n')
      .replace(/\n{3,}/g, '\n\n')
      .trim();

  const tryParse = (value: string): string => {
    const parsed = JSON.parse(value);
    const lines = extractLines(parsed);
    const text = normalizeText(lines.join('\n'));
    return text || value;
  };

  const base = (raw || '').trim();
  if (!base) return '';

  if (base.startsWith('[') || base.startsWith('{')) {
    try {
      return tryParse(base);
    } catch {
      return base;
    }
  }

  if ((base.startsWith('"[') && base.endsWith('"')) || (base.startsWith('"{') && base.endsWith('"'))) {
    try {
      const unquoted = JSON.parse(base);
      if (typeof unquoted === 'string') {
        return parsePrintCommandsToText(unquoted);
      }
      return base;
    } catch {
      return base;
    }
  }

  return base;
};

export const SaleClosureScreen: React.FC = () => {
  const { height: screenHeight } = useWindowDimensions();
  const route = useRoute<Route>();
  const navigation = useNavigation<Navigation>();
  const routeVenda = route.params?.idVenda;
  const routeUsuario = route.params?.idUsuario;
  const routeMode = route.params?.mode || 'final';
  const routeTableType = route.params?.tableType;
  const routeReturnTo = route.params?.returnTo || 'Cardapio';
  const { user, refreshDashboard, activeTable, appSettings } = useApp();
  const tableType = routeTableType === 'mesa' || routeTableType === 'comanda' ? routeTableType : activeTable?.tipo;
  const idVenda = routeVenda || activeTable?.idVenda;
  const idUsuario = routeUsuario || user?.idUsuario || 1;
  const mode: ClosureMode = routeMode === 'pre' ? 'pre' : 'final';
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [sale, setSale] = useState<Sale | null>(null);
  const [methods, setMethods] = useState<PaymentMethod[]>([]);
  const [descontoValor, setDescontoValor] = useState('0');
  const [descontoPercentual, setDescontoPercentual] = useState('0');
  const [discountInputMode, setDiscountInputMode] = useState<DiscountInputMode>('value');
  const [masc, setMasc] = useState('0');
  const [fem, setFem] = useState('0');
  const [numPessoas, setNumPessoas] = useState('0');
  const [pagamentos, setPagamentos] = useState<PaymentLine[]>([]);
  const [partialPayments, setPartialPayments] = useState<SalePayment[]>([]);
  const [previewBeforePrint, setPreviewBeforePrint] = useState(false);
  const [previewText, setPreviewText] = useState('');
  const [previewRawPrintContent, setPreviewRawPrintContent] = useState('');
  const [showPreview, setShowPreview] = useState(false);
  const [printProcessingVisible, setPrintProcessingVisible] = useState(false);
  const [printProcessingMessage, setPrintProcessingMessage] = useState('');
  const [paymentPickerVisible, setPaymentPickerVisible] = useState(false);
  const [paymentPickerLineIndex, setPaymentPickerLineIndex] = useState<number | null>(null);
  const [paymentProcessingVisible, setPaymentProcessingVisible] = useState(false);
  const [paymentProcessingLineIndex, setPaymentProcessingLineIndex] = useState<number | null>(null);
  const [paymentProcessingLabel, setPaymentProcessingLabel] = useState('');
  const [paymentProcessingMessage, setPaymentProcessingMessage] = useState('');
  const [actionStatus, setActionStatus] = useState<{
    kind: 'idle' | 'info' | 'success' | 'error';
    message: string;
  }>({ kind: 'idle', message: '' });
  const [sweetAlert, setSweetAlert] = useState<{
    visible: boolean;
    title: string;
    message: string;
    type: SweetAlertType;
  }>({
    visible: false,
    title: '',
    message: '',
    type: 'info'
  });
  const [companyCouvertConfig, setCompanyCouvertConfig] = useState({
    valorCouvertMasculino: 0,
    valorCouvertFeminino: 0
  });
  const activePaymentTokenRef = useRef<string | null>(null);
  const paymentSelectionBusyRef = useRef(false);

  const returnTo = routeReturnTo as ReturnTarget;
  const canPreviewPreClosure = Boolean(user?.permitePreFechamentoMesaComanda);
  const canApplyDiscount = Boolean(user?.permiteDescontoFechamento);

  const loadData = async () => {
    if (!idVenda) return;
    setLoading(true);
    try {
      const [saleResult, methodsResult, partialPaymentsResult, companyConfigResult] = await Promise.allSettled([
        api.getSale(idVenda, true),
        mode === 'final' ? api.listPaymentMethods() : Promise.resolve([] as PaymentMethod[]),
        mode === 'final' ? api.listPaymentsBySale(idVenda) : Promise.resolve([] as SalePayment[]),
        api.getCompanyConfig()
      ]);
      const saleLoaded = saleResult.status === 'fulfilled' ? saleResult.value : null;
      const methodsLoaded = methodsResult.status === 'fulfilled' ? methodsResult.value : [];
      const partialLoaded = partialPaymentsResult.status === 'fulfilled' ? partialPaymentsResult.value : [];
      const companyConfigLoaded = companyConfigResult.status === 'fulfilled' ? companyConfigResult.value : null;
      const currentCompanyConfig =
        tableType === 'comanda' ? companyConfigLoaded?.comanda ?? null : companyConfigLoaded?.mesa ?? null;
      const mergedPartialPayments = mergeSalePayments(saleLoaded?.pagamentos, partialLoaded);
      setSale(saleLoaded);
      setMethods(methodsLoaded);
      setPartialPayments(mode === 'final' ? mergedPartialPayments : []);
      setCompanyCouvertConfig({
        valorCouvertMasculino: Number(currentCompanyConfig?.valorCouvertMasculino || 0),
        valorCouvertFeminino: Number(currentCompanyConfig?.valorCouvertFeminino || 0)
      });
      if (saleLoaded) {
        const totalVenda = saleLoaded.valorTotal ?? saleLoaded.valor ?? 0;
        const valorDesconto = saleLoaded.valorDesconto || 0;
        const percentualDesconto = totalVenda > 0 ? (valorDesconto / totalVenda) * 100 : 0;
        setMasc(String(saleLoaded.numeroCouvertMasculino || 0));
        setFem(String(saleLoaded.numeroCouvertFeminino || 0));
        setNumPessoas(String(saleLoaded.numeroPessoas || 0));
        setDescontoValor(formatDiscountInput(valorDesconto));
        setDescontoPercentual(formatDiscountInput(percentualDesconto));
        setDiscountInputMode('value');
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [idVenda, mode]);

  useFocusEffect(
    React.useCallback(() => {
      loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [idVenda, mode, tableType])
  );

  useEffect(() => () => {
    activePaymentTokenRef.current = null;
    paymentSelectionBusyRef.current = false;
  }, []);

  useEffect(() => {
    if (!canPreviewPreClosure && previewBeforePrint) {
      setPreviewBeforePrint(false);
    }
  }, [canPreviewPreClosure, previewBeforePrint]);

  const countsAsCommittedPayment = (item: PaymentLine): boolean => {
    const methodId = Number(item.codigo || 0);
    if (methodId <= 0) {
      return false;
    }

    const method = methods.find((entry) => entry.codigo === methodId);
    if (!method) {
      return false;
    }

    const provider = resolvePaymentProviderForMethod(appSettings, method);
    return provider === 'manual' || Boolean(item.processed);
  };

  const saleTotal = sale?.valorTotal ?? sale?.valor ?? 0;
  const originalMascCount = Number(sale?.numeroCouvertMasculino || 0);
  const originalFemCount = Number(sale?.numeroCouvertFeminino || 0);
  const originalMascCouvertTotal = Number(sale?.valorCouvertMasculino || 0);
  const originalFemCouvertTotal = Number(sale?.valorCouvertFeminino || 0);
  const unitMascCouvert =
    Number(companyCouvertConfig.valorCouvertMasculino || 0) > 0
      ? Number(companyCouvertConfig.valorCouvertMasculino || 0)
      : originalMascCount > 0
        ? originalMascCouvertTotal / originalMascCount
        : 0;
  const unitFemCouvert =
    Number(companyCouvertConfig.valorCouvertFeminino || 0) > 0
      ? Number(companyCouvertConfig.valorCouvertFeminino || 0)
      : originalFemCount > 0
        ? originalFemCouvertTotal / originalFemCount
        : 0;
  const originalCouvertTotal = originalMascCouvertTotal + originalFemCouvertTotal;
  const currentCouvertTotal =
    parseInteger(masc) * unitMascCouvert +
    parseInteger(fem) * unitFemCouvert;
  const total = Math.max(0, saleTotal - originalCouvertTotal + currentCouvertTotal);
  const partialPaid = partialPayments.reduce((acc, item) => acc + Number(item.valor || 0), 0);
  const descontoNum = discountInputMode === 'percent'
    ? calculateDiscountValueFromPercent(total, descontoPercentual)
    : normalizeDiscountNumber(parseMoney(descontoValor));
  const paid = partialPaid + pagamentos.reduce(
    (acc, item) => acc + (countsAsCommittedPayment(item) ? parseMoney(item.valor) : 0),
    0
  );
  const saldo = total - descontoNum - paid;
  const saldoRestante = Math.max(0, saldo);
  const hasAppliedDiscount = descontoNum > 0.009;
  const showDiscountControls = canApplyDiscount || hasAppliedDiscount;
  const shouldShowAddPaymentButton = mode === 'final' && saldoRestante > 0.009;
  const coupledCount = parseInteger(masc) + parseInteger(fem);
  const normalizedPeople = parseInteger(numPessoas);
  const adjustedPeople = Math.max(normalizedPeople, coupledCount);
  const configuredPaymentProvider = resolveConfiguredPaymentProvider(appSettings);
  const usePagBankPrinter = configuredPaymentProvider === 'pagbank';
  const useStoneOrCieloPrinter =
    configuredPaymentProvider === 'stone' || configuredPaymentProvider === 'cielo';
  const printOnlyAtClose = tableType === 'mesa'
    ? Boolean(appSettings.imprimirMesaAposFechamento)
    : tableType === 'comanda'
      ? Boolean(appSettings.imprimirComandaAposFechamento)
      : false;
  const shouldPrintPreClosure = !printOnlyAtClose;
  const preClosureInternalPrint = (appSettings.utilizaImpressoraInterna || usePagBankPrinter) && shouldPrintPreClosure;
  const closeInternalPrint = (appSettings.utilizaImpressoraInterna || usePagBankPrinter) && printOnlyAtClose;

  const statusText = normalizeSaleStatus(sale?.situacao || '');
  const hasSaleItems = (sale?.itens?.length || 0) > 0;
  const isAlreadyPreClosed = statusText.includes('prefechamento') || statusText.includes('pre-fechamento');
  const isPreCloseAllowed =
    hasSaleItems &&
    !statusText.includes('finalizada') &&
    !statusText.includes('cancelada') &&
    !isAlreadyPreClosed;
  const isFinalCloseAllowed = statusText.includes('pendente') || statusText.includes('prefechamento');
  const allowSave = mode === 'pre' ? isPreCloseAllowed : isFinalCloseAllowed;
  const isMachinePaymentRunning = paymentProcessingVisible || Boolean(activePaymentTokenRef.current);

  useEffect(() => {
    if (configuredPaymentProvider !== 'pagbank') {
      return;
    }

    preparePaymentProvider(appSettings).catch(() => false);
  }, [configuredPaymentProvider, appSettings]);

  const ensurePaymentMethodsLoaded = async (): Promise<PaymentMethod[]> => {
    if (methods.length > 0) {
      return methods;
    }

    const loadedMethods = await api.listPaymentMethods();
    setMethods(loadedMethods);
    return loadedMethods;
  };

  const clearPaymentProcessingUi = () => {
    setPaymentProcessingVisible(false);
    setPaymentProcessingLineIndex(null);
    setPaymentProcessingLabel('');
    setPaymentProcessingMessage('');
  };

  const showPrintProcessing = (message = 'Enviando impressão para a maquininha...') => {
    setPrintProcessingMessage(message);
    setPrintProcessingVisible(true);
  };

  const hidePrintProcessing = () => {
    setPrintProcessingVisible(false);
    setPrintProcessingMessage('');
  };

  const showSweetAlert = (
    title: string,
    message: string,
    type: SweetAlertType = 'info'
  ) => {
    setSweetAlert({
      visible: true,
      title,
      message,
      type
    });
  };

  const releaseMachinePaymentFlow = (paymentToken?: string | null) => {
    if (!paymentToken || activePaymentTokenRef.current === paymentToken) {
      activePaymentTokenRef.current = null;
    }
    paymentSelectionBusyRef.current = false;
    clearPaymentProcessingUi();
  };

  const discardPaymentLine = (lineIndex: number) => {
    setPagamentos((prev) => {
      if (!prev[lineIndex]) return prev;
      return prev.filter((_, idx) => idx !== lineIndex);
    });
  };

  const cancelCurrentMachinePayment = async (lineIndex?: number, message?: string) => {
    activePaymentTokenRef.current = null;
    paymentSelectionBusyRef.current = false;
    clearPaymentProcessingUi();
    if (typeof lineIndex === 'number') {
      discardPaymentLine(lineIndex);
    }
    await abortActivePayment(appSettings).catch(() => false);
    if (message) {
      setActionStatus({ kind: 'error', message });
      Alert.alert('Atenção', message);
    }
  };

  const changeInteger = (setter: (value: string) => void, current: string, delta: number) => {
    const next = Math.max(0, parseInteger(current) + delta);
    setter(String(next));
  };

  const goToReturn = () => {
    if (returnTo === 'Inicial') {
      navigation.navigate('Inicial');
      return;
    }

    if (returnTo === 'Cardapio' || returnTo === 'Gestao' || returnTo === 'Mesas') {
      navigation.navigate('Tabs', { screen: returnTo } as never);
      return;
    }

    navigation.navigate('Cardapio' as never);
  };

  const goToInitial = () => {
    const resetAction = CommonActions.reset({
      index: 0,
      routes: [{ name: 'Inicial' } as never]
    });

    const parent = navigation.getParent();
    if (parent) {
      try {
        parent.dispatch(resetAction);
        return;
      } catch (error: unknown) {
        void error;
      }
    }

    try {
      navigation.dispatch(resetAction);
      return;
    } catch (error: unknown) {
      void error;
    }

    navigation.navigate('Inicial');
  };

  const handleDiscountValueChange = (value: string) => {
    if (!canApplyDiscount) {
      return;
    }

    setDiscountInputMode('value');
    setDescontoValor(value);
    const percentual = calculateDiscountPercentFromValue(total, value);
    setDescontoPercentual(formatDiscountInput(percentual));
  };

  const handleDiscountPercentChange = (value: string) => {
    if (!canApplyDiscount) {
      return;
    }

    setDiscountInputMode('percent');
    setDescontoPercentual(value);
    const valorDesconto = calculateDiscountValueFromPercent(total, value);
    setDescontoValor(formatDiscountInput(valorDesconto));
  };

  const setLineValue = (index: number, valor: string) => {
    setPagamentos((prev) => {
      if (!prev[index] || prev[index].processed) return prev;
      const next = [...prev];
      next[index] = {
        ...next[index],
        valor,
        processed: false,
        provider: undefined,
        sfiCodigo: undefined,
        nsu: undefined
      };
      return next;
    });
  };

  const setLineMethod = (index: number, methodId: number) => {
    setPagamentos((prev) => {
      if (!prev[index] || prev[index].processed) return prev;
      const next = [...prev];
      next[index] = {
        ...next[index],
        codigo: methodId,
        processed: false,
        provider: undefined,
        sfiCodigo: undefined,
        nsu: undefined
      };
      return next;
    });
  };

  const addLine = async () => {
    Keyboard.dismiss();
    let availableMethods = methods;
    if (availableMethods.length === 0) {
      try {
        availableMethods = await ensurePaymentMethodsLoaded();
      } catch (error: any) {
        showSweetAlert('Erro', error?.message || 'Não foi possível carregar as formas de pagamento.', 'error');
        return;
      }
    }

    if (availableMethods.length === 0) {
      showSweetAlert('Atenção', 'Nenhuma forma de pagamento disponível.', 'warning');
      return;
    }

    setPagamentos((prev) => {
      const totalPagoAtual = prev.reduce(
        (acc, item) => (countsAsCommittedPayment(item) ? acc + parseMoney(item.valor) : acc),
        0
      );
      const totalLiquidoAtual = Math.max(0, total - descontoNum);
      const pendingValue = Math.max(0, totalLiquidoAtual - partialPaid - totalPagoAtual).toFixed(2);
      const next = [...prev, { codigo: 0, valor: pendingValue, processed: false }];
      setPaymentPickerLineIndex(next.length - 1);
      setPaymentPickerVisible(true);
      return next;
    });
  };

  const removeLine = (index: number) => {
    setPagamentos((prev) => {
      if (!prev[index] || prev[index].processed) return prev;
      return prev.filter((_, idx) => idx !== index);
    });
  };

  const onPreviewOnly = async () => {
    if (!canPreviewPreClosure) {
      const message = 'Seu usuário não possui permissão para pré-visualizar o pré-fechamento.';
      setActionStatus({ kind: 'error', message });
      showSweetAlert('Permissão negada', message, 'warning');
      return;
    }
    if (!idVenda) {
      setActionStatus({ kind: 'error', message: 'Venda não identificada para pré-visualizar.' });
      return;
    }
    if (!hasSaleItems) {
      setActionStatus({ kind: 'error', message: 'Não é possível pré-fechar sem produtos lançados.' });
      Alert.alert('Atenção', 'Não é possível pré-fechar sem produtos lançados.');
      return;
    }
    try {
      setSaving(true);
      setActionStatus({ kind: 'info', message: 'Gerando pré-visualização da impressão...' });
      const numeroPessoas = Math.max(parseInteger(numPessoas), parseInteger(masc) + parseInteger(fem));
      if (numPessoas !== String(numeroPessoas)) {
        setNumPessoas(String(numeroPessoas));
      }

      let content = '';
      try {
        const previewResponse = await api.preCloseSale(
          idVenda,
          {
            idUsuario,
            numeroPessoas,
            numeroCouvertMasculino: parseInteger(masc),
            numeroCouvertFeminino: parseInteger(fem),
            imprimirPreFechamentoMobile: false,
            preFechamentoMobileImpressaoInterna: false
          },
          {
            accept: 'text/plain',
            numeroColunas: appSettings.impressaoColunas,
            impressaoInterna: false,
            tipoMaquina: resolveMachineType(appSettings, true)
          }
        );
        content = typeof previewResponse === 'string' ? previewResponse : '';
      } catch {
        content = '';
      }

      if (!content || !content.trim()) {
        content = await loadSalePrintContent({
          idVenda,
          appSettings,
          usarRotaMaquininha: true
        }).catch(() => '');
      }

      if (!content || !content.trim()) {
        throw new Error('Servidor não retornou conteúdo para a pré-visualização desta venda.');
      }

      setPreviewRawPrintContent(content);
      setPreviewText(parsePrintCommandsToText(content));
      setShowPreview(true);
      refreshDashboard().catch(() => null);
      setActionStatus({ kind: 'success', message: 'Pré-visualização carregada com sucesso.' });
    } catch (error: any) {
      setActionStatus({ kind: 'error', message: error?.message || 'Não foi possível carregar a pré-visualização.' });
      Alert.alert('Erro', error?.message || 'Não foi possível carregar a pré-visualização.');
    } finally {
      setSaving(false);
    }
  };

  const onSave = async () => {
    if (!idVenda) {
      setActionStatus({ kind: 'error', message: 'Venda não identificada para salvar pré-fechamento.' });
      return;
    }

    if (mode === 'pre' && !user?.permitePreFechamentoMesaComanda) {
      const message = 'Sem permissão para fazer pré-fechamento.';
      setActionStatus({ kind: 'error', message });
      showSweetAlert('Atenção', message, 'warning');
      return;
    }

    if (mode === 'final' && !user?.permiteFechamentoMesaComanda) {
      const message = 'Sem permissão para fazer fechamento.';
      setActionStatus({ kind: 'error', message });
      showSweetAlert('Atenção', message, 'warning');
      return;
    }

    if (!allowSave) {
      setActionStatus({
        kind: 'error',
        message:
          mode === 'pre'
            ? !hasSaleItems
              ? 'Não é possível pré-fechar sem produtos lançados.'
              : isAlreadyPreClosed
                ? 'Venda já está em pré-fechamento. Não é permitido pré-fechar novamente.'
                : 'Pré-fechamento indisponível para a situação atual da venda.'
            : 'Fechamento indisponível para a situação atual da venda.'
      });
      Alert.alert(
        'Atenção',
        mode === 'pre'
          ? !hasSaleItems
            ? 'Não é possível pré-fechar sem produtos lançados.'
            : isAlreadyPreClosed
              ? 'Venda já está em pré-fechamento. Não é permitido pré-fechar novamente.'
              : 'Pré-fechamento indisponível para a situação atual da venda.'
          : 'Fechamento só pode ser executado com venda pendente ou em pré-fechamento.'
      );
      return;
    }

    setSaving(true);
    setActionStatus({ kind: 'info', message: mode === 'pre' ? 'Salvando pré-fechamento...' : 'Fechando venda...' });
    try {
    if (mode === 'pre') {
      if (!idUsuario || idUsuario <= 0) {
        setActionStatus({ kind: 'error', message: 'Usuário não identificado para executar pré-fechamento.' });
        Alert.alert('Atenção', 'Usuário não identificado para executar pré-fechamento.');
        return;
      }

      const numeroPessoas = adjustedPeople;
      if (numPessoas !== String(numeroPessoas)) {
        setNumPessoas(String(numeroPessoas));
      }

      const previewRequested = previewBeforePrint && shouldPrintPreClosure;
      const shouldUseLocalPagBankPrint = usePagBankPrinter && preClosureInternalPrint && !previewRequested;
      const shouldUseLocalStoneOrCieloPrint = useStoneOrCieloPrinter && shouldPrintPreClosure && !previewRequested;
      const shouldUseLocalTerminalPrint = shouldUseLocalPagBankPrint || shouldUseLocalStoneOrCieloPrint;
      const shouldRequestPreClosePrintContent = previewRequested || shouldUseLocalTerminalPrint;
      const previewResponse = await api.preCloseSale(idVenda, {
        idUsuario,
        numeroPessoas,
        numeroCouvertMasculino: parseInteger(masc),
        numeroCouvertFeminino: parseInteger(fem),
        imprimirPreFechamentoMobile: previewRequested
          ? false
          : shouldUseLocalTerminalPrint
            ? false
            : shouldPrintPreClosure && (appSettings.utilizaImpressoraInterna || usePagBankPrinter),
        preFechamentoMobileImpressaoInterna: previewRequested || shouldUseLocalTerminalPrint ? false : preClosureInternalPrint
      },
      shouldRequestPreClosePrintContent
        ? {
            accept: 'text/plain',
            numeroColunas: appSettings.impressaoColunas,
            impressaoInterna: previewRequested || shouldUseLocalTerminalPrint ? false : preClosureInternalPrint,
            tipoMaquina: resolveMachineType(appSettings, true)
          }
        : {}
      );

        let printPreviewMessage = '';
        let previewLoaded = false;
        if (previewRequested) {
          let printContent = typeof previewResponse === 'string' ? previewResponse : '';
          if (!printContent || !printContent.trim()) {
            try {
              printContent = await loadSalePrintContent({
                idVenda,
                appSettings,
                usarRotaMaquininha: true
              });
            } catch {
              printContent = '';
            }
          }
          if (!printContent || !printContent.trim()) {
            throw new Error('Servidor não retornou conteúdo para a pré-visualização desta venda.');
          }
          const contentRaw = printContent;
          const content = parsePrintCommandsToText(contentRaw);
          setPreviewRawPrintContent(contentRaw);
          setPreviewText(content);
          setShowPreview(true);
          previewLoaded = true;
          printPreviewMessage = '\nPré-visualização carregada abaixo.';
        } else {
          setPreviewRawPrintContent('');
          setPreviewText('');
          setShowPreview(false);
        }

        let printExecutionMessage = '';
        if (!previewRequested && shouldUseLocalTerminalPrint) {
          let printContent = typeof previewResponse === 'string' ? previewResponse : '';
          if (!printContent || !printContent.trim()) {
            try {
              printContent = await loadSalePrintContent({
                idVenda,
                appSettings,
                usarRotaMaquininha: true
              });
            } catch {
              printContent = '';
            }
          }
          try {
            showPrintProcessing('Processando impressão do pré-fechamento...');
            await printSaleContent({
              content: printContent,
              appSettings,
              usarRotaMaquininha: true
            });
            printExecutionMessage = '\nImpressão enviada para a maquininha.';
          } catch (printError: any) {
            printExecutionMessage = `\nPré-fechamento salvo, mas a impressão falhou: ${printError?.message || 'Falha ao imprimir.'}`;
          } finally {
            hidePrintProcessing();
          }
        }

        if (previewBeforePrint && !shouldPrintPreClosure) {
          printPreviewMessage = '\nPré-visualização desativada pela configuração "imprimir apenas no fechamento".';
        }

        refreshDashboard().catch(() => null);
        loadData().catch(() => null);
        setActionStatus({
          kind: 'success',
          message: previewLoaded
            ? 'Pré-fechamento salvo e pré-visualização carregada.'
            : printExecutionMessage
              ? `Pré-fechamento salvo com sucesso. ${printExecutionMessage.trim()}`
              : 'Pré-fechamento salvo com sucesso.'
        });
        Alert.alert('Concluído', `Pré-fechamento salvo com sucesso.${printPreviewMessage}${printExecutionMessage}`);
        goToInitial();
        return;
      }

      const linhasBase = pagamentos
        .map((item, index) => ({
          index,
          codigo: Number(item.codigo || 0),
          valor: parseMoney(item.valor),
          processed: Boolean(item.processed),
          sfiCodigo: item.sfiCodigo
        }))
        .filter((item) => item.codigo > 0 && item.valor > 0);

      if (!idUsuario || idUsuario <= 0) {
        setActionStatus({ kind: 'error', message: 'Usuário não identificado para executar fechamento.' });
        Alert.alert('Atenção', 'Usuário não identificado para executar fechamento.');
        setSaving(false);
        return;
      }

      const hasMachinePaymentInProgress =
        paymentProcessingVisible || Boolean(activePaymentTokenRef.current) || paymentSelectionBusyRef.current;

      if (hasMachinePaymentInProgress) {
        setActionStatus({ kind: 'info', message: 'Aguarde a conclusão do pagamento na maquininha antes de finalizar.' });
        Alert.alert('Atenção', 'Aguarde a conclusão do pagamento na maquininha antes de finalizar a venda.');
        setSaving(false);
        return;
      }

      const totalLiquido = Math.max(0, total - descontoNum);
      if (linhasBase.length === 0 && partialPaid + 0.0001 < totalLiquido) {
        setActionStatus({ kind: 'error', message: 'Informe ao menos uma forma de pagamento.' });
        Alert.alert('Atenção', 'Informe ao menos uma forma de pagamento.');
        setSaving(false);
        return;
      }

      const aprovados: Array<{ idFormaPgto: number; valor: number; sfiCodigo?: number }> = [];
      for (const linha of linhasBase) {
        const formaSelecionada = methods.find((item) => item.codigo === linha.codigo);
        if (!formaSelecionada) {
          throw new Error('Forma de pagamento não encontrada para um dos itens.');
        }

        const paymentProvider = resolvePaymentProviderForMethod(appSettings, formaSelecionada);
        const requireMachinePaymentAtAdd = requiresPaymentProcessingAtAdd(appSettings, formaSelecionada);
        const providerLabel = formatPaymentProviderLabel(paymentProvider);

        if (requireMachinePaymentAtAdd && !linha.processed) {
          throw new Error(
            `A forma "${formaSelecionada.descricao}" precisa ser processada na ${providerLabel} ao adicionar o pagamento.`
          );
        }

        if (requireMachinePaymentAtAdd && linha.processed) {
          aprovados.push({
            idFormaPgto: linha.codigo,
            valor: linha.valor,
            sfiCodigo: linha.sfiCodigo ?? formaSelecionada.sfiCodigo
          });
          continue;
        }

        const pagamentoProcessado = await executePayment({
          value: linha.valor,
          method: formaSelecionada,
          availableMethods: methods,
          settings: appSettings,
          idVenda
        });

        aprovados.push({
          idFormaPgto: pagamentoProcessado.method.codigo,
          valor: linha.valor,
          sfiCodigo: pagamentoProcessado.sfiCodigo ?? pagamentoProcessado.method.sfiCodigo
        });
      }

      const totalPagoNovo = aprovados.reduce((acc, item) => acc + item.valor, 0);
      const totalDinheiroParcial = partialPayments.reduce((acc, item) => {
        const method =
          item.formaPagamento ||
          methods.find((entry) => entry.codigo === Number(item.idFormaPagamento || 0));
        return Number(method?.sfiCodigo || 0) === 1 ? acc + Number(item.valor || 0) : acc;
      }, 0);
      const totalPago = partialPaid + totalPagoNovo;
      const totalDinheiro = totalDinheiroParcial + aprovados
        .filter((item) => Number(item.sfiCodigo || 0) === 1)
        .reduce((acc, item) => acc + item.valor, 0);
      const troco = totalPago - totalLiquido;
      const totalPrePago = Math.max(Number(sale?.valorEntrada || 0), partialPaid);

      if (totalPrePago <= 0 && troco > totalDinheiro + 0.0001) {
        setActionStatus({ kind: 'error', message: 'Troco maior que o valor em dinheiro.' });
        Alert.alert(
          'Atenção',
          'Não é possível devolver troco maior que o valor recebido em dinheiro.'
        );
        setSaving(false);
        return;
      }

      const totalPorForma = new Map<number, number>();
      aprovados.forEach((item) => {
        const current = totalPorForma.get(item.idFormaPgto) || 0;
        totalPorForma.set(item.idFormaPgto, current + item.valor);
      });

      const linhas = Array.from(totalPorForma.entries()).map(([idFormaPgto, valor]) => ({
        idFormaPgto,
        valor
      }));

      const closePrintInternal = closeInternalPrint;
      const valorTaxaServico = Number(sale?.valorTaxaServico || 0);
      const cobrarTaxaGarcom = valorTaxaServico > 0;

      const shouldRequestClosePrintContent = usePagBankPrinter && closePrintInternal;
      const closeResponse = await api.closeSale({
        idVenda,
        idUsuario,
        numeroCouvertMasculino: parseInteger(masc),
        numeroCouvertFeminino: parseInteger(fem),
        numeroPessoas: Math.max(parseInteger(numPessoas), coupledCount),
        valorDesconto: descontoNum,
        tipoDesconto: 0,
        valorTaxaServico,
        CobrarTaxaGarcom: cobrarTaxaGarcom,
        pagamentos: linhas,
        impressoraInterna: closePrintInternal,
        imprimirPreFechamentoMobile: printOnlyAtClose
      }, {
        accept: shouldRequestClosePrintContent ? 'text/plain' : 'application/json',
        numeroColunas: appSettings.impressaoColunas,
        tipoMaquina: resolveMachineType(appSettings, true)
      });

      let closePrintMessage = '';
      if (closePrintInternal && usePagBankPrinter) {
        let printContent = typeof closeResponse === 'string' ? closeResponse : '';
        if (!printContent || !printContent.trim()) {
          try {
            printContent = await loadSalePrintContent({
              idVenda,
              appSettings,
              usarRotaMaquininha: true
            });
          } catch {
            printContent = '';
          }
        }
        try {
          showPrintProcessing('Processando impressão do fechamento...');
          await printSaleContent({
            content: printContent,
            appSettings,
            usarRotaMaquininha: true
          });
          closePrintMessage = ' Impressão enviada para a maquininha.';
        } catch (printError: any) {
          closePrintMessage = ` Venda fechada, mas a impressão falhou: ${printError?.message || 'Falha ao imprimir.'}`;
        } finally {
          hidePrintProcessing();
        }
      }

      refreshDashboard().catch(() => null);
      setActionStatus({
        kind: 'success',
        message: closePrintMessage
          ? `Venda fechada com sucesso.${closePrintMessage}`
          : 'Venda fechada com sucesso.'
      });
      goToInitial();
    } catch (error: any) {
      setActionStatus({ kind: 'error', message: error?.message || 'Não foi possível concluir a operação.' });
      Alert.alert('Erro', error?.message || 'Não foi possível concluir a operação.');
    } finally {
      setSaving(false);
    }
  };

  const title = mode === 'pre' ? 'Pré Fechamento' : 'Fechamento';
  const description = mode === 'pre'
    ? 'Ajuste pessoas e couvert antes de marcar a venda como pré-fechamento.'
    : canApplyDiscount
      ? 'Informe pagamento, desconto e finalize a venda.'
      : 'Informe pagamento e finalize a venda.';
  const buttonText = mode === 'pre'
    ? (!allowSave ? 'Pré Fechamento indisponível' : (saving ? 'Salvando...' : 'Salvar Pré Fechamento'))
    : (saving ? 'Fechando...' : 'Fechar venda');

  const openPaymentPicker = async (index: number) => {
    Keyboard.dismiss();
    if (isMachinePaymentRunning || saving) {
      return;
    }
    if (methods.length === 0) {
      try {
        const loadedMethods = await ensurePaymentMethodsLoaded();
        if (loadedMethods.length === 0) {
          showSweetAlert('Atenção', 'Nenhuma forma de pagamento disponível.', 'warning');
          return;
        }
      } catch (error: any) {
        showSweetAlert('Erro', error?.message || 'Não foi possível carregar as formas de pagamento.', 'error');
        return;
      }
    }
    setPaymentPickerLineIndex(index);
    setPaymentPickerVisible(true);
  };

  const selectPaymentMethod = async (methodId: number) => {
    Keyboard.dismiss();
    if (paymentSelectionBusyRef.current || isMachinePaymentRunning) {
      return;
    }

    if (paymentPickerLineIndex === null || paymentPickerLineIndex < 0) {
      setPaymentPickerVisible(false);
      return;
    }
    const lineIndex = paymentPickerLineIndex;
    setLineMethod(lineIndex, methodId);
    setPaymentPickerVisible(false);
    setPaymentPickerLineIndex(null);

    if (mode !== 'final') {
      return;
    }

    const selectedMethod = methods.find((method) => method.codigo === methodId);
    if (!selectedMethod) {
      return;
    }

    const paymentProvider = resolvePaymentProviderForMethod(appSettings, selectedMethod);
    if (paymentProvider === 'manual') {
      return;
    }
    paymentSelectionBusyRef.current = true;
    const providerLabel = formatPaymentProviderLabel(paymentProvider);

    if (!idVenda) {
      paymentSelectionBusyRef.current = false;
      Alert.alert('Atenção', `Venda não identificada para processar pagamento na ${providerLabel}.`);
      return;
    }

    const linha = pagamentos[lineIndex];
    let valorSelecionado = parseMoney(linha?.valor || '0');

    if (!Number.isFinite(valorSelecionado) || valorSelecionado <= 0) {
      const totalOutrasLinhas = pagamentos.reduce(
        (acc, item, idx) =>
          idx === lineIndex || !countsAsCommittedPayment(item) ? acc : acc + parseMoney(item.valor || '0'),
        0
      );
      const fallbackValor = Math.max(0, total - descontoNum - partialPaid - totalOutrasLinhas);
      if (fallbackValor <= 0) {
        paymentSelectionBusyRef.current = false;
        setActionStatus({ kind: 'info', message: `Não há saldo pendente a processar na ${providerLabel}.` });
        Alert.alert('Atenção', `Não há saldo pendente a processar na ${providerLabel}.`);
        return;
      }

      valorSelecionado = fallbackValor;
      setPagamentos((prev) => {
        if (!prev[lineIndex]) return prev;
        const next = [...prev];
        next[lineIndex] = {
          ...next[lineIndex],
          valor: fallbackValor.toFixed(2),
          processed: false,
          provider: undefined,
          sfiCodigo: undefined,
          nsu: undefined
        };
        return next;
      });
    }

    const paymentToken = `${paymentProvider}-${lineIndex}-${Date.now()}`;
    activePaymentTokenRef.current = paymentToken;
    setPaymentProcessingLineIndex(lineIndex);
    setPaymentProcessingLabel(`${providerLabel} · ${selectedMethod.descricao}`);
    setPaymentProcessingMessage(`Processando venda com ${providerLabel}. Aguarde na maquininha.`);
    setPaymentProcessingVisible(true);

    try {
      setActionStatus({ kind: 'info', message: `Processando venda com ${providerLabel}...` });

      const pagamentoProcessado = await executePayment({
        value: valorSelecionado,
        method: selectedMethod,
        availableMethods: methods,
        settings: appSettings,
        idVenda,
        onProgress: (message) => {
          setPaymentProcessingMessage(message);
        }
      });

      if (activePaymentTokenRef.current !== paymentToken) {
        return;
      }

      const processedSfiCodigo = pagamentoProcessado.sfiCodigo ?? pagamentoProcessado.method.sfiCodigo;
      releaseMachinePaymentFlow(paymentToken);

      setPagamentos((prev) => {
        if (!prev[lineIndex]) return prev;
        const current = prev[lineIndex];
        const next = [...prev];
        next[lineIndex] = {
          ...next[lineIndex],
          codigo: pagamentoProcessado.method.codigo,
          valor: valorSelecionado.toFixed(2),
          processed: paymentProvider !== 'manual',
          provider: pagamentoProcessado.provider,
          sfiCodigo: processedSfiCodigo,
          nsu: pagamentoProcessado.nsu
        };
        const duplicateProcessedIndex = next.findIndex(
          (item, idx) =>
            idx !== lineIndex &&
            Boolean(item.processed) &&
            Number(item.codigo || 0) === Number(pagamentoProcessado.method.codigo) &&
            Number(parseMoney(item.valor || '0').toFixed(2)) === Number(valorSelecionado.toFixed(2)) &&
            (item.nsu || '') === (pagamentoProcessado.nsu || '')
        );
        if (duplicateProcessedIndex >= 0 && current && !current.processed) {
          return next.filter((_, idx) => idx !== duplicateProcessedIndex);
        }
        return next;
      });

      setActionStatus({
        kind: 'success',
        message: pagamentoProcessado.message || `Pagamento aprovado e vinculado via ${providerLabel}.`
      });
    } catch (error: any) {
      if (activePaymentTokenRef.current !== paymentToken) {
        return;
      }
      releaseMachinePaymentFlow(paymentToken);
      discardPaymentLine(lineIndex);
      setActionStatus({
        kind: 'error',
        message: error?.message || `Falha ao processar pagamento na ${providerLabel}.`
      });
      Alert.alert('Erro', error?.message || `Falha ao processar pagamento na ${providerLabel}.`);
    } finally {
      if (activePaymentTokenRef.current === paymentToken || paymentSelectionBusyRef.current) {
        releaseMachinePaymentFlow(paymentToken);
      }
    }
  };

  if (!idVenda) {
    return (
      <ScrollView style={styles.container} contentContainerStyle={styles.warningContainer}>
        <ScreenRouteLabel />
        <View style={styles.warningCard}>
          <Text style={styles.warningTitle}>Venda não disponível</Text>
          <Text style={styles.warningText}>Selecione uma mesa e abra a venda em Mesas antes de fechar.</Text>
          <Pressable
            style={styles.primaryBtn}
            onPress={() => {
              navigation.navigate('Tabs', { screen: 'Mesas' } as never);
            }}
          >
            <Text style={styles.primaryText}>Ir para Mesas</Text>
          </Pressable>
        </View>
      </ScrollView>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 120 }}>
      {mode !== 'pre' ? <ScreenRouteLabel /> : null}
      {mode !== 'pre' ? (
        <SectionHeader
          title={`${title} da venda #${idVenda}`}
          subtitle={sale ? `Mesa: ${sale.nomeMesaComanda || 'Sem identificador'}` : undefined}
        />
      ) : null}

      <View style={styles.summaryCard}>
        <Text style={styles.summaryLabel}>Total da venda</Text>
        <Text style={styles.summaryValue}>{formatMoney(total)}</Text>
        {mode === 'final' && partialPaid > 0 ? (
          <>
            <Text style={styles.summaryLabel}>Pagamentos parciais</Text>
            <Text style={styles.summaryValue}>{formatMoney(partialPaid)}</Text>
          </>
        ) : null}
        <Text style={styles.summaryLabel}>Situação atual</Text>
        <Text style={styles.summaryValue}>{toDisplayStatus(sale?.situacao)}</Text>
        {!allowSave ? (
          <Text style={styles.alertText}>
            {mode === 'pre'
              ? !hasSaleItems
                ? 'Venda sem produtos lançados.'
                : isAlreadyPreClosed
                  ? 'Venda já está em pré-fechamento.'
                  : 'Pré-fechamento indisponível para esta situação.'
              : 'Fechamento indisponível para esta situação.'}
          </Text>
        ) : null}
      </View>

      <View style={styles.summaryCard}>
        <Text style={styles.summaryLabel}>Pessoas</Text>
        <View style={styles.counterRow}>
          <Pressable
            style={styles.counterBtn}
            onPress={() => changeInteger(setNumPessoas, numPessoas, -1)}
          >
            <Text style={styles.counterText}>-</Text>
          </Pressable>
          <TextInput style={[styles.input, styles.counterInput]} keyboardType="numeric" value={numPessoas} onChangeText={setNumPessoas} />
          <Pressable
            style={styles.counterBtn}
            onPress={() => changeInteger(setNumPessoas, numPessoas, +1)}
          >
            <Text style={styles.counterText}>+</Text>
          </Pressable>
        </View>
      </View>

      <View style={styles.summaryCard}>
        <Text style={styles.summaryLabel}>Couvert M/F</Text>
        <View style={styles.couvertLine}>
          <Text style={styles.payLabel}>Masculino</Text>
          <View style={styles.counterRow}>
            <Pressable
              style={styles.counterBtn}
              onPress={() => changeInteger(setMasc, masc, -1)}
            >
              <Text style={styles.counterText}>-</Text>
            </Pressable>
            <TextInput style={[styles.input, styles.counterInput]} keyboardType="numeric" value={masc} onChangeText={setMasc} />
            <Pressable
              style={styles.counterBtn}
              onPress={() => changeInteger(setMasc, masc, +1)}
            >
              <Text style={styles.counterText}>+</Text>
            </Pressable>
          </View>
        </View>
        <View style={styles.couvertLine}>
          <Text style={styles.payLabel}>Feminino</Text>
          <View style={styles.counterRow}>
            <Pressable
              style={styles.counterBtn}
              onPress={() => changeInteger(setFem, fem, -1)}
            >
              <Text style={styles.counterText}>-</Text>
            </Pressable>
            <TextInput style={[styles.input, styles.counterInput]} keyboardType="numeric" value={fem} onChangeText={setFem} />
            <Pressable
              style={styles.counterBtn}
              onPress={() => changeInteger(setFem, fem, +1)}
            >
              <Text style={styles.counterText}>+</Text>
            </Pressable>
          </View>
        </View>
      </View>

      {mode === 'pre' ? (
        <View style={styles.summaryCard}>
          <View style={styles.switchRow}>
            <Text style={styles.infoTitle}>Pré-visualizar impressão</Text>
            <Switch
              value={canPreviewPreClosure && previewBeforePrint}
              onValueChange={(value) => {
                if (!canPreviewPreClosure) return;
                setPreviewBeforePrint(value);
              }}
              disabled={!canPreviewPreClosure}
            />
          </View>
          {!canPreviewPreClosure ? (
            <Text style={styles.permissionHint}>
              Seu usuário não possui permissão para usar a pré-visualização.
            </Text>
          ) : null}
          <TouchableOpacity
            style={[
              styles.previewBtn,
              { marginTop: 10 },
              saving || !allowSave || !canPreviewPreClosure ? styles.primaryBtnDisabled : null
            ]}
            onPress={onPreviewOnly}
            activeOpacity={0.85}
            disabled={saving || !allowSave || !canPreviewPreClosure}
          >
            <Text style={styles.previewBtnText}>{saving ? 'Carregando...' : 'Pré-visualizar'}</Text>
          </TouchableOpacity>
          {showPreview && previewText ? (
            <View style={[styles.previewBox, { minHeight: Math.max(560, screenHeight * 0.86) }]}>
              <Text style={styles.previewTitle}>TextImpressao</Text>
              <ScrollView style={[styles.previewScroll, { maxHeight: Math.max(520, screenHeight * 0.78) }]}> 
                <Text style={styles.previewText}>{previewText}</Text>
              </ScrollView>
              <View style={styles.previewActions}>
                <Pressable
                  style={styles.previewBtn}
                  onPress={async () => {
                    try {
                      setActionStatus({ kind: 'info', message: 'Enviando impressão...' });
                      if (usePagBankPrinter || useStoneOrCieloPrinter) {
                        showPrintProcessing('Processando impressão...');
                        await printSaleContent({
                          content: previewRawPrintContent || previewText,
                          appSettings,
                          usarRotaMaquininha: true
                        });
                      } else {
                        await executeSalePrint({
                          idVenda: idVenda || 0,
                          appSettings,
                          usarRotaMaquininha: true
                        });
                      }
                      setActionStatus({ kind: 'success', message: 'Impressão enviada com sucesso.' });
                      showSweetAlert('Concluído', 'Impressão enviada.', 'success');
                      setShowPreview(false);
                    } catch (error: any) {
                      setActionStatus({ kind: 'error', message: error?.message || 'Falha ao imprimir.' });
                      showSweetAlert('Erro', error?.message || 'Falha ao imprimir.', 'error');
                    } finally {
                      hidePrintProcessing();
                    }
                  }}
                >
                  <Text style={styles.previewBtnText}>Imprimir</Text>
                </Pressable>
                <Pressable
                  style={[styles.previewBtn, styles.previewBtnSecondary]}
                  onPress={() => {
                    setShowPreview(false);
                    goToReturn();
                  }}
                >
                  <Text style={styles.previewBtnText}>Voltar</Text>
                </Pressable>
              </View>
            </View>
          ) : null}
        </View>
      ) : null}

      {mode === 'final' ? (
        <>
          {showDiscountControls ? (
            <View style={[styles.summaryCard, !canApplyDiscount ? styles.summaryCardDisabled : null]}>
              <Text style={styles.summaryLabel}>Desconto (R$)</Text>
              <TextInput
                style={[styles.input, !canApplyDiscount ? styles.inputDisabled : null]}
                keyboardType="numeric"
                value={descontoValor}
                onChangeText={handleDiscountValueChange}
                editable={canApplyDiscount}
              />
              <Text style={styles.summaryLabel}>Desconto (%)</Text>
              <TextInput
                style={[styles.input, !canApplyDiscount ? styles.inputDisabled : null]}
                keyboardType="numeric"
                value={descontoPercentual}
                onChangeText={handleDiscountPercentChange}
                editable={canApplyDiscount}
              />
              {!canApplyDiscount ? (
                <Text style={styles.permissionHint}>Desconto indisponível para este usuário.</Text>
              ) : null}
              <Text style={styles.summaryLabel}>Saldo estimado</Text>
              <Text style={[styles.summaryValue, saldo < 0 ? styles.warning : null]}>R$ {saldo.toFixed(2)}</Text>
            </View>
          ) : null}

          <View style={styles.summaryCard}>
            <Text style={styles.summaryLabel}>Pagamentos</Text>
            {pagamentos.map((linha, index) => {
              const selectedMethod = methods.find((m) => m.codigo === linha.codigo);
              const isLocked = Boolean(linha.processed);
              return (
                <View key={`pay-${index}`} style={[styles.paymentLine, isLocked ? styles.paymentLineLocked : null]}>
                  <Text style={styles.payLabel}>Método</Text>
                  <Pressable
                    style={[styles.selectMethodBtn, isLocked ? styles.selectMethodBtnLocked : null]}
                    disabled={isLocked}
                    onPress={() => openPaymentPicker(index)}
                  >
                    <Text style={styles.selectMethodText}>{selectedMethod?.descricao || 'Selecionar forma de pagamento'}</Text>
                  </Pressable>
                  <Text style={styles.payLabel}>Valor</Text>
                  <TextInput
                    style={[styles.input, isLocked ? styles.inputLocked : null]}
                    keyboardType="numeric"
                    value={linha.valor}
                    editable={!isLocked}
                    onChangeText={(value) => setLineValue(index, value)}
                  />
                  {isLocked ? (
                    <View style={styles.paymentApprovedBox}>
                      <Text style={styles.paymentApprovedTitle}>Pagamento aprovado</Text>
                      <Text style={styles.paymentApprovedText}>
                        {linha.provider ? `Integração: ${String(linha.provider).toUpperCase()}` : 'Integração eletrônica confirmada'}
                      </Text>
                      {linha.nsu ? <Text style={styles.paymentApprovedText}>NSU: {linha.nsu}</Text> : null}
                    </View>
                  ) : null}
                  {!isLocked ? (
                    <Pressable style={styles.removeBtn} onPress={() => removeLine(index)}>
                      <Text style={styles.removeText}>Remover</Text>
                    </Pressable>
                  ) : null}
                </View>
              );
            })}
            {shouldShowAddPaymentButton ? (
              <Pressable
                style={[styles.addBtn, saving || isMachinePaymentRunning ? styles.primaryBtnDisabled : null]}
                onPress={addLine}
                disabled={saving || isMachinePaymentRunning}
              >
                <Text style={styles.addText}>
                  {pagamentos.length === 0 ? 'Inserir pagamento' : 'Adicionar outra forma'}
                </Text>
              </Pressable>
            ) : null}
          </View>
        </>
      ) : null}

      <View style={styles.summaryCard}>
        <Text style={styles.infoTitle}>{title}</Text>
        <Text style={styles.infoText}>{description}</Text>
      </View>

      {actionStatus.message ? (
        <View
          style={[
            styles.statusBox,
            actionStatus.kind === 'error'
              ? styles.statusError
              : actionStatus.kind === 'success'
                ? styles.statusSuccess
                : styles.statusInfo
          ]}
        >
          <Text
            style={[
              styles.statusText,
              actionStatus.kind === 'error'
                ? styles.statusTextError
                : actionStatus.kind === 'success'
                  ? styles.statusTextSuccess
                  : styles.statusTextInfo
            ]}
          >
            {actionStatus.message}
          </Text>
        </View>
      ) : null}

      <TouchableOpacity
        style={[styles.primaryBtn, saving || !allowSave || isMachinePaymentRunning ? styles.primaryBtnDisabled : null]}
        disabled={saving || !allowSave || isMachinePaymentRunning}
        onPress={onSave}
        activeOpacity={0.85}
      >
        <Text style={styles.primaryText}>{buttonText}</Text>
      </TouchableOpacity>

      <Modal
        transparent
        visible={paymentPickerVisible}
        animationType="fade"
        onRequestClose={() => {
          setPaymentPickerVisible(false);
          setPaymentPickerLineIndex(null);
        }}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Selecionar pagamento</Text>
            {methods.map((method) => (
              <Pressable
                key={`method-${method.codigo}`}
                style={styles.modalOption}
                onPress={() => selectPaymentMethod(method.codigo)}
              >
                <Text style={styles.modalOptionText}>{method.descricao}</Text>
              </Pressable>
            ))}
            <Pressable
              style={[styles.modalOption, styles.modalCancel]}
              onPress={() => {
                setPaymentPickerVisible(false);
                setPaymentPickerLineIndex(null);
              }}
            >
              <Text style={styles.modalCancelText}>Cancelar</Text>
            </Pressable>
          </View>
        </View>
      </Modal>

      <Modal
        transparent
        visible={paymentProcessingVisible}
        animationType="fade"
        onRequestClose={() => {
          cancelCurrentMachinePayment(paymentProcessingLineIndex ?? undefined, 'Pagamento cancelado pelo operador.').catch(() => null);
        }}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.processingCard}>
            <ActivityIndicator size="large" color={Colors.primary} />
            <Text style={styles.processingTitle}>Processando pagamento</Text>
            <Text style={styles.processingLabel}>{paymentProcessingLabel || 'Cartão'}</Text>
            <Text style={styles.processingText}>{paymentProcessingMessage || 'Aguardando confirmação da maquininha.'}</Text>
            <Pressable
              style={[styles.modalOption, styles.modalCancel, { marginTop: 12 }]}
              onPress={() => {
                cancelCurrentMachinePayment(paymentProcessingLineIndex ?? undefined, 'Pagamento cancelado pelo operador.').catch(() => null);
              }}
            >
              <Text style={styles.modalCancelText}>Cancelar pagamento</Text>
            </Pressable>
          </View>
        </View>
      </Modal>

      <Modal
        transparent
        visible={printProcessingVisible}
        animationType="fade"
      >
        <View style={styles.modalOverlay}>
          <View style={styles.processingCard}>
            <ActivityIndicator size="large" color={Colors.primary} />
            <Text style={styles.processingTitle}>Processando impressão</Text>
            <Text style={styles.processingText}>
              {printProcessingMessage || 'Enviando impressão para a maquininha. Aguarde...'}
            </Text>
          </View>
        </View>
      </Modal>

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
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background, padding: Space.md },
  summaryCard: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    padding: Space.md,
    marginBottom: Space.md
  },
  summaryCardDisabled: {
    opacity: 0.75
  },
  summaryLabel: {
    color: Colors.textMuted,
    fontWeight: '700',
    fontSize: 12,
    marginBottom: 4
  },
  summaryValue: {
    color: Colors.primary,
    fontSize: 22,
    fontWeight: '900',
    marginBottom: 12
  },
  warning: {
    color: Colors.danger
  },
  row: {
    flexDirection: 'row',
    gap: Space.sm
  },
  counterRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10
  },
  counterBtn: {
    width: 38,
    height: 38,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    alignItems: 'center',
    justifyContent: 'center'
  },
  counterText: {
    color: Colors.text,
    fontWeight: '900',
    fontSize: 18
  },
  input: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    color: Colors.text,
    borderRadius: Radius.sm,
    padding: 10,
    marginBottom: 10
  },
  inputDisabled: {
    backgroundColor: '#F1F3F6',
    color: Colors.textMuted
  },
  halfInput: {
    flex: 1
  },
  counterInput: {
    flex: 1,
    textAlign: 'center',
    marginBottom: 0
  },
  couvertLine: {
    marginBottom: 10
  },
  switchRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  previewBox: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.sm,
    marginTop: 10,
    padding: 14,
    backgroundColor: Colors.cardSoft
  },
  previewScroll: {
    maxHeight: 520
  },
  previewTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 6
  },
  previewText: {
    color: Colors.textMuted,
    fontFamily: 'monospace'
  },
  previewActions: {
    marginTop: 10,
    flexDirection: 'row',
    gap: 8
  },
  previewBtn: {
    flex: 1,
    borderRadius: Radius.sm,
    paddingVertical: 10,
    alignItems: 'center',
    backgroundColor: Colors.primary
  },
  previewBtnSecondary: {
    backgroundColor: Colors.textMuted
  },
  previewBtnText: {
    color: '#fff',
    fontWeight: '700'
  },
  paymentLine: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    borderRadius: Radius.md,
    padding: 10,
    marginBottom: 8
  },
  payLabel: {
    color: Colors.textMuted,
    marginTop: 4,
    marginBottom: 4
  },
  selectedMethod: {
    color: Colors.text,
    fontWeight: '700'
  },
  selectMethodBtn: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.sm,
    backgroundColor: Colors.card,
    paddingVertical: 10,
    paddingHorizontal: 12,
    marginBottom: 8
  },
  selectMethodText: {
    color: Colors.text,
    fontWeight: '700'
  },
  methodList: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginVertical: 8
  },
  methodBtn: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 8,
    backgroundColor: Colors.card
  },
  methodBtnActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft
  },
  methodBtnText: {
    color: Colors.textMuted,
    fontWeight: '700',
    fontSize: 12
  },
  methodBtnTextActive: {
    color: Colors.primary
  },
  addBtn: {
    borderWidth: 1,
    borderColor: Colors.primary,
    borderRadius: Radius.md,
    padding: 10,
    alignItems: 'center',
    backgroundColor: Colors.primarySoft
  },
  addText: {
    color: Colors.primary,
    fontWeight: '700'
  },
  removeBtn: {
    marginTop: 8,
    alignSelf: 'flex-start',
    borderWidth: 1,
    borderColor: Colors.warning,
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8
  },
  removeText: {
    color: Colors.warning,
    fontWeight: '700',
    fontSize: 12
  },
  paymentLineLocked: {
    borderColor: '#3BA55D',
    backgroundColor: '#EEF9F1'
  },
  selectMethodBtnLocked: {
    backgroundColor: '#E5F6EA',
    borderColor: '#9ED3AB'
  },
  inputLocked: {
    backgroundColor: '#E5F6EA',
    color: '#255B34'
  },
  paymentApprovedBox: {
    marginTop: 8,
    borderRadius: Radius.sm,
    backgroundColor: '#DFF3E5',
    padding: 10
  },
  paymentApprovedTitle: {
    color: '#215732',
    fontWeight: '900',
    marginBottom: 4
  },
  paymentApprovedText: {
    color: '#2F6B42',
    fontSize: 12
  },
  primaryBtn: {
    borderRadius: Radius.md,
    backgroundColor: Colors.primary,
    padding: 14,
    alignItems: 'center'
  },
  primaryBtnDisabled: {
    opacity: 0.7
  },
  primaryText: {
    color: '#fff',
    fontWeight: '700'
  },
  warningContainer: {
    paddingBottom: 120,
    paddingHorizontal: Space.md,
    paddingTop: Space.md
  },
  warningCard: {
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.warning,
    backgroundColor: Colors.card,
    padding: Space.md
  },
  warningTitle: {
    color: Colors.warning,
    fontWeight: '700',
    marginBottom: 6
  },
  warningText: {
    color: Colors.textMuted
  },
  alertText: {
    color: Colors.warning,
    marginBottom: 4,
    fontWeight: '700'
  },
  infoTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 4
  },
  infoText: {
    color: Colors.textMuted
  },
  permissionHint: {
    color: Colors.warning,
    marginTop: 10,
    fontWeight: '700'
  },
  statusBox: {
    borderRadius: Radius.sm,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: 10
  },
  statusInfo: {
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft
  },
  statusSuccess: {
    borderColor: '#B8E6C7',
    backgroundColor: '#ECFDF3'
  },
  statusError: {
    borderColor: '#F3B9B9',
    backgroundColor: '#FFF1F1'
  },
  statusText: {
    fontSize: 13,
    fontWeight: '700'
  },
  statusTextInfo: {
    color: Colors.textMuted
  },
  statusTextSuccess: {
    color: '#197A3E'
  },
  statusTextError: {
    color: Colors.danger
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.35)',
    justifyContent: 'center',
    padding: Space.md
  },
  modalCard: {
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    padding: Space.md
  },
  modalTitle: {
    color: Colors.text,
    fontWeight: '800',
    marginBottom: 10
  },
  modalOption: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.sm,
    paddingVertical: 10,
    paddingHorizontal: 12,
    marginBottom: 8,
    backgroundColor: Colors.cardSoft
  },
  modalOptionText: {
    color: Colors.text,
    fontWeight: '700'
  },
  modalCancel: {
    backgroundColor: Colors.warning + '12',
    borderColor: Colors.warning
  },
  modalCancelText: {
    color: Colors.warning,
    fontWeight: '700'
  },
  processingCard: {
    width: '84%',
    maxWidth: 360,
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    padding: Space.lg,
    alignSelf: 'center',
    alignItems: 'center'
  },
  processingTitle: {
    color: Colors.text,
    fontSize: 18,
    fontWeight: '900',
    marginTop: 14,
    marginBottom: 6
  },
  processingLabel: {
    color: Colors.primary,
    fontWeight: '800',
    marginBottom: 8
  },
  processingText: {
    color: Colors.textMuted,
    textAlign: 'center'
  }
});


