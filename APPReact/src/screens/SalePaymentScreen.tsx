import React, { useEffect, useMemo, useRef, useState } from 'react';
import { ActivityIndicator, Alert, FlatList, Keyboard, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { RouteProp, useNavigation, useRoute } from '@react-navigation/native';
import { api, logSyncDiagnostic, normalizeSaleStatus, PaymentMethod, SalePayment } from '../services/api';
import { SectionHeader } from '../components/SectionHeader';
import { Colors, Radius, Shadows, Space } from '../theme';
import { RootStackParams } from '../navigation/AppNavigator';
import { useApp } from '../context/AppContext';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import {
  abortActivePayment,
  describeMachinePaymentError,
  executePayment,
  formatPaymentProviderLabel,
  preparePaymentProvider,
  resolveConfiguredPaymentProvider,
  resolvePaymentProviderForMethod
} from '../services/payment';

type Route = RouteProp<RootStackParams, 'Pagamento'>;

type PaymentDraft = {
  codigo: number;
  valor: string;
  processed?: boolean;
  registered?: boolean;
  sfiCodigo?: number;
  provider?: string;
  nsu?: string;
};

type StatusNotice = {
  visible: boolean;
  title: string;
  message: string;
  tone: 'warning' | 'success' | 'error' | 'info';
};

const normalize = (value: string) => Number(value.replace(',', '.'));

export const SalePaymentScreen: React.FC = () => {
  const route = useRoute<Route>();
  const navigation = useNavigation<any>();
  const { activeTable, user, refreshDashboard, appSettings } = useApp();
  const idVenda = route.params?.idVenda || activeTable?.idVenda;

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [methods, setMethods] = useState<PaymentMethod[]>([]);
  const [pagamentos, setPagamentos] = useState<SalePayment[]>([]);
  const [saleTotal, setSaleTotal] = useState(0);
  const [saleStatus, setSaleStatus] = useState('');
  const [drafts, setDrafts] = useState<PaymentDraft[]>([{ codigo: 0, valor: '0' }]);
  const [paymentProcessingVisible, setPaymentProcessingVisible] = useState(false);
  const [paymentProcessingLineIndex, setPaymentProcessingLineIndex] = useState<number | null>(null);
  const [paymentProcessingLabel, setPaymentProcessingLabel] = useState('');
  const [paymentProcessingMessage, setPaymentProcessingMessage] = useState('');
  const [statusNotice, setStatusNotice] = useState<StatusNotice>({
    visible: false,
    title: '',
    message: '',
    tone: 'warning'
  });

  const activePaymentTokenRef = useRef<string | null>(null);
  const paymentSelectionBusyRef = useRef(false);
  const draftsRef = useRef<PaymentDraft[]>([{ codigo: 0, valor: '0' }]);
  const methodsRef = useRef<PaymentMethod[]>([]);
  const pagamentosRef = useRef<SalePayment[]>([]);
  const saleTotalRef = useRef(0);
  const saleStatusRef = useRef('');

  const isMachinePaymentRunning = paymentProcessingVisible || Boolean(activePaymentTokenRef.current);

  const updateDrafts = (updater: (previous: PaymentDraft[]) => PaymentDraft[]) => {
    setDrafts((previous) => {
      const next = updater(previous);
      draftsRef.current = next;
      return next;
    });
  };

  const showStatusNotice = (
    title: string,
    message: string,
    tone: StatusNotice['tone'] = 'warning'
  ) => {
    setStatusNotice({ visible: true, title, message, tone });
  };

  const resetDrafts = (availableMethods: PaymentMethod[]) => {
    const next = [{ codigo: availableMethods[0]?.codigo || 0, valor: '0', processed: false, registered: false }];
    draftsRef.current = next;
    setDrafts(next);
  };

  const removeDraftAndEnsureBlankLine = (lineIndex: number, availableMethods: PaymentMethod[] = methods) => {
    updateDrafts((prev) => {
      const next = prev.filter((_, idx) => idx !== lineIndex);
      if (next.length > 0) {
        return next;
      }

      return [{ codigo: availableMethods[0]?.codigo || 0, valor: '0', processed: false, registered: false }];
    });
  };

  const load = async () => {
    if (!idVenda) return;
    const startedAt = Date.now();
    logSyncDiagnostic(`fluxo pagamento parcial carregar inicio idVenda=${idVenda}`);
    setLoading(true);
    try {
      const [pm, ps, sale] = await Promise.all([
        api.listPaymentMethods(),
        api.listPaymentsBySale(idVenda),
        api.getSale(idVenda, false)
      ]);
      methodsRef.current = pm;
      pagamentosRef.current = ps;
      saleTotalRef.current = sale?.valorTotal || sale?.valor || 0;
      saleStatusRef.current = normalizeSaleStatus(sale?.situacao || '');
      setMethods(pm);
      setPagamentos(ps);
      setSaleTotal(sale?.valorTotal || sale?.valor || 0);
      setSaleStatus(normalizeSaleStatus(sale?.situacao || ''));
      updateDrafts((prev) => {
        if (prev.length > 0) return prev;
        return [{ codigo: pm[0]?.codigo || 0, valor: '0', processed: false, registered: false }];
      });
      logSyncDiagnostic(
        `fluxo pagamento parcial carregar fim idVenda=${idVenda} formas=${pm.length} pagamentos=${ps.length} total=${Number(sale?.valorTotal || sale?.valor || 0).toFixed(2)} em ${Date.now() - startedAt}ms`
      );
    } catch (error: any) {
      logSyncDiagnostic(`fluxo pagamento parcial carregar erro idVenda=${idVenda}: ${error?.message || 'erro desconhecido'}`, 2);
      Alert.alert('Erro', error?.message || 'Não foi possível carregar pagamentos.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [idVenda]);

  useEffect(() => {
    updateDrafts((prev) =>
      prev.map((item) => ({
        ...item,
        codigo: item.codigo || methods[0]?.codigo || 0,
        registered: item.registered ?? false
      }))
    );
  }, [methods]);

  useEffect(() => {
    if (resolveConfiguredPaymentProvider(appSettings) !== 'pagbank') return;
    preparePaymentProvider(appSettings).catch(() => false);
  }, [appSettings]);

  const totalPago = useMemo(() => pagamentos.reduce((acc, item) => acc + (item.valor || 0), 0), [pagamentos]);
  const totalDigitado = useMemo(
    () =>
      drafts.reduce((acc, item) => {
        const valor = normalize(item.valor);
        return acc + (Number.isFinite(valor) && valor > 0 ? valor : 0);
      }, 0),
    [drafts]
  );
  const valorPendente = Math.max(0, saleTotal - totalPago);

  const clearPaymentProcessingUi = () => {
    setPaymentProcessingVisible(false);
    setPaymentProcessingLineIndex(null);
    setPaymentProcessingLabel('');
    setPaymentProcessingMessage('');
  };

  const releaseMachinePaymentFlow = (paymentToken?: string | null) => {
    if (!paymentToken || activePaymentTokenRef.current === paymentToken) {
      activePaymentTokenRef.current = null;
    }
    paymentSelectionBusyRef.current = false;
    clearPaymentProcessingUi();
  };

  const discardDraft = (lineIndex: number) => {
    updateDrafts((prev) => {
      if (!prev[lineIndex]) return prev;
      return prev.filter((_, idx) => idx !== lineIndex);
    });
  };

  const cancelCurrentMachinePayment = async (lineIndex?: number, message?: string) => {
    activePaymentTokenRef.current = null;
    paymentSelectionBusyRef.current = false;
    clearPaymentProcessingUi();
    if (typeof lineIndex === 'number') {
      discardDraft(lineIndex);
    }
    await abortActivePayment(appSettings).catch(() => false);
    if (message) {
      Alert.alert('Atenção', message);
    }
  };

  const setDraftValue = (index: number, value: string) => {
    updateDrafts((prev) => {
      const next = [...prev];
      next[index] = {
        ...next[index],
        valor: value,
        processed: false,
        registered: false,
        provider: undefined,
        sfiCodigo: undefined,
        nsu: undefined
      };
      return next;
    });
  };

  const setDraftMethod = (index: number, methodId: number) => {
    updateDrafts((prev) => {
      const next = [...prev];
      next[index] = {
        ...next[index],
        codigo: methodId,
        processed: false,
        registered: false,
        provider: undefined,
        sfiCodigo: undefined,
        nsu: undefined
      };
      return next;
    });
  };

  const addDraft = () => {
    if (isMachinePaymentRunning || saving) return;
    const firstMethod = methods[0];
    updateDrafts((prev) => [
      ...prev,
      { codigo: firstMethod?.codigo || 0, valor: '0', processed: false, registered: false }
    ]);
  };

  const removeDraft = (index: number) => {
    updateDrafts((prev) => {
      if (!prev[index] || prev[index].processed) return prev;
      return prev.filter((_, idx) => idx !== index);
    });
  };

  const processDraftMachinePayment = async (
    index: number,
    methodId: number,
    options: {
      updateSelection?: boolean;
      showRegisterRetryNotice?: boolean;
    } = {}
  ): Promise<boolean> => {
    const {
      updateSelection = true,
      showRegisterRetryNotice = true
    } = options;

    Keyboard.dismiss();
    if (paymentSelectionBusyRef.current || isMachinePaymentRunning) return false;

    if (updateSelection) {
      setDraftMethod(index, methodId);
    }

    const selectedMethod = methodsRef.current.find((m) => m.codigo === methodId);
    if (!selectedMethod) return false;

    const paymentProvider = resolvePaymentProviderForMethod(appSettings, selectedMethod);
    if (paymentProvider === 'manual') return true;

    paymentSelectionBusyRef.current = true;
    const providerLabel = formatPaymentProviderLabel(paymentProvider);

    if (!idVenda) {
      paymentSelectionBusyRef.current = false;
      Alert.alert('Atenção', `Venda não identificada para processar pagamento na ${providerLabel}.`);
      return false;
    }

    const draft = draftsRef.current[index];
    const valorSelecionado = normalize(draft?.valor || '0');

    if (!Number.isFinite(valorSelecionado) || valorSelecionado <= 0) {
      paymentSelectionBusyRef.current = false;
      Alert.alert('Atenção', `Informe o valor antes de processar na ${providerLabel}.`);
      return false;
    }

    const paymentToken = `${paymentProvider}-${index}-${Date.now()}`;
    activePaymentTokenRef.current = paymentToken;
    setPaymentProcessingLineIndex(index);
    setPaymentProcessingLabel(`${providerLabel} · ${selectedMethod.descricao}`);
    setPaymentProcessingMessage(`Processando pagamento com ${providerLabel}. Aguarde na maquininha.`);
    setPaymentProcessingVisible(true);
    let slowPaymentTimer: ReturnType<typeof setTimeout> | null = null;

    try {
      logSyncDiagnostic(
        `fluxo pagamento parcial terminal inicio idVenda=${idVenda} linha=${index} forma=${selectedMethod.codigo} valor=${valorSelecionado.toFixed(2)} provider=${paymentProvider}`
      );
      const paymentStartedAt = Date.now();
      slowPaymentTimer = setTimeout(() => {
        if (activePaymentTokenRef.current !== paymentToken) {
          return;
        }
        const message = `Aguardando retorno da ${providerLabel}. Não feche o app nem tente registrar de novo.`;
        setPaymentProcessingMessage(message);
        logSyncDiagnostic(
          `fluxo pagamento parcial terminal aguardando idVenda=${idVenda} linha=${index} provider=${paymentProvider} em ${Date.now() - paymentStartedAt}ms`
        );
      }, 15000);
      const result = await executePayment({
        value: valorSelecionado,
        method: selectedMethod,
        availableMethods: methodsRef.current,
        settings: appSettings,
        idVenda,
        onProgress: (msg) => setPaymentProcessingMessage(msg)
      });
      logSyncDiagnostic(
        `fluxo pagamento parcial terminal ok idVenda=${idVenda} linha=${index} forma=${result.method.codigo} provider=${result.provider} em ${Date.now() - paymentStartedAt}ms`
      );

      if (activePaymentTokenRef.current !== paymentToken) return false;

      releaseMachinePaymentFlow(paymentToken);

      const approvedLine: PaymentDraft = {
        codigo: result.method.codigo,
        valor: valorSelecionado.toFixed(2),
        processed: true,
        registered: false,
        provider: result.provider,
        sfiCodigo: result.sfiCodigo ?? result.method.sfiCodigo,
        nsu: result.nsu
      };

      updateDrafts((prev) => {
        if (!prev[index]) return prev;
        const next = [...prev];
        next[index] = {
          ...next[index],
          ...approvedLine
        };
        return next;
      });

      setSaving(true);
      let registeredSuccessfully = false;
      try {
        const registerStartedAt = Date.now();
        logSyncDiagnostic(
          `fluxo pagamento parcial registrar terminal inicio idVenda=${idVenda} forma=${result.method.codigo} valor=${valorSelecionado.toFixed(2)}`
        );
        await api.registerPartialPayment({
          idVenda,
          idFormaPagamento: result.method.codigo,
          valor: valorSelecionado,
          idUsuario: user?.idUsuario
        });
        registeredSuccessfully = true;
        logSyncDiagnostic(
          `fluxo pagamento parcial registrar terminal ok idVenda=${idVenda} forma=${result.method.codigo} em ${Date.now() - registerStartedAt}ms`
        );

        await Promise.all([
          load(),
          refreshDashboard(undefined, { force: true })
        ]);
        removeDraftAndEnsureBlankLine(index);
        showStatusNotice('Aprovado', result.message || `Pagamento aprovado via ${providerLabel}.`, 'success');
      } catch (registerError: any) {
        logSyncDiagnostic(
          `fluxo pagamento parcial registrar terminal erro idVenda=${idVenda}: ${registerError?.message || 'erro desconhecido'}`,
          2
        );
        if (registeredSuccessfully) {
          removeDraftAndEnsureBlankLine(index);
          await load().catch(() => null);
          await refreshDashboard(undefined, { force: true }).catch(() => null);
          showStatusNotice(
            'Pagamento aprovado',
            'O pagamento foi aprovado e registrado, mas a atualização visual da tela falhou. Confira os totais antes de continuar.',
            'warning'
          );
          return true;
        }

        updateDrafts((prev) => {
          if (!prev[index]) return prev;
          const next = [...prev];
          next[index] = {
            ...next[index],
            ...approvedLine,
            registered: false
          };
          return next;
        });
        if (showRegisterRetryNotice) {
          showStatusNotice(
            'Pagamento aprovado',
            registerError?.message ||
              `O pagamento foi aprovado na ${providerLabel}, mas não foi possível atualizar a venda. Toque em "Pagamento Parcial" para tentar registrar novamente.`,
            'warning'
          );
        }
      } finally {
        setSaving(false);
      }

      return true;
    } catch (error: any) {
      if (activePaymentTokenRef.current !== paymentToken) return false;
      const details = describeMachinePaymentError(providerLabel, error);
      logSyncDiagnostic(
        `fluxo pagamento parcial terminal erro idVenda=${idVenda} linha=${index} provider=${paymentProvider} ${details.diagnostic}`,
        2
      );
      releaseMachinePaymentFlow(paymentToken);
      discardDraft(index);
      Alert.alert('Erro', details.message);
      return false;
    } finally {
      if (slowPaymentTimer) {
        clearTimeout(slowPaymentTimer);
      }
      if (activePaymentTokenRef.current === paymentToken || paymentSelectionBusyRef.current) {
        releaseMachinePaymentFlow(paymentToken);
      }
    }
  };

  const onSelectDraftMethod = async (index: number, methodId: number) => {
    if (paymentSelectionBusyRef.current || isMachinePaymentRunning) return;
    await processDraftMachinePayment(index, methodId, { updateSelection: true });
  };

  const register = async () => {
    if (!idVenda) return;
    if (saving || loading) return;

    if (!user?.permitePagamentoParcial) {
      showStatusNotice('Atenção', 'Sem permissão para pagamento parcial.', 'warning');
      return;
    }
    if (!String(saleStatusRef.current || saleStatus).toLowerCase().includes('pendente')) {
      Alert.alert('Atenção', 'Somente vendas pendentes permitem pagamento parcial.');
      return;
    }

    const hasZeroOrInvalidValue = draftsRef.current.some((item) => {
      const hasMethod = Number(item.codigo || 0) > 0;
      const value = normalize(item.valor || '0');
      return hasMethod && (!Number.isFinite(value) || value <= 0);
    });
    if (hasZeroOrInvalidValue) {
      Alert.alert('Atenção', 'Não é permitido inserir pagamento com valor zero.');
      return;
    }

    let autoProcessedMachinePayment = false;
    while (true) {
      const pendingTerminalIndex = draftsRef.current.findIndex((item) => {
        if (!item.processed && Number(item.codigo || 0) > 0) {
          const method = methodsRef.current.find((m) => m.codigo === item.codigo);
          if (method) {
            return resolvePaymentProviderForMethod(appSettings, method) !== 'manual';
          }
        }
        return false;
      });

      if (pendingTerminalIndex < 0) {
        break;
      }

      const pendingTerminal = draftsRef.current[pendingTerminalIndex];
      const handled = await processDraftMachinePayment(pendingTerminalIndex, pendingTerminal.codigo, {
        updateSelection: false,
        showRegisterRetryNotice: false
      });

      if (!handled) {
        return;
      }

      autoProcessedMachinePayment = true;
    }

    const currentTotalPago = pagamentosRef.current.reduce((acc, item) => acc + (item.valor || 0), 0);
    const currentValorPendente = Math.max(0, saleTotalRef.current - currentTotalPago);
    const currentTotalDigitado = draftsRef.current.reduce((acc, item) => {
      const valor = normalize(item.valor);
      return acc + (Number.isFinite(valor) && valor > 0 ? valor : 0);
    }, 0);

    const lines = draftsRef.current
      .map((item, index) => ({
        index,
        codigo: Number(item.codigo || 0),
        valor: normalize(item.valor),
        registered: Boolean(item.registered)
      }))
      .filter((item) => item.codigo > 0 && item.valor > 0 && !item.registered);

    if (lines.length === 0) {
      if (autoProcessedMachinePayment) {
        return;
      }
      Alert.alert('Atenção', 'Informe ao menos um pagamento com valor maior que zero.');
      return;
    }

    if (currentTotalDigitado > currentValorPendente + 0.0001) {
      Alert.alert('Atenção', 'O valor pago não pode ser superior ao valor pendente da venda.');
      return;
    }

    setSaving(true);
    const startedAt = Date.now();
    logSyncDiagnostic(
      `fluxo pagamento parcial registrar inicio idVenda=${idVenda} linhas=${lines.length} total=${lines.reduce((acc, item) => acc + item.valor, 0).toFixed(2)}`
    );
    try {
      let registeredSomePayment = false;
      for (const line of lines) {
        const method = methodsRef.current.find((item) => item.codigo === line.codigo);
        if (!method) {
          throw new Error('Forma de pagamento não encontrada.');
        }

        logSyncDiagnostic(
          `fluxo pagamento parcial registrar linha idVenda=${idVenda} forma=${method.codigo} valor=${line.valor.toFixed(2)}`
        );
        await api.registerPartialPayment({
          idVenda,
          idFormaPagamento: method.codigo,
          valor: line.valor,
          idUsuario: user?.idUsuario
        });
        registeredSomePayment = true;
      }

      try {
        await Promise.all([
          load(),
          refreshDashboard(undefined, { force: true })
        ]);
      } catch (refreshError: any) {
        resetDrafts(methods);
        showStatusNotice(
          'Concluído',
          refreshError?.message || 'Pagamento registrado, mas a tela não atualizou por completo. Confira a venda novamente.',
          registeredSomePayment ? 'warning' : 'success'
        );
        return;
      }

      resetDrafts(methods);
      logSyncDiagnostic(`fluxo pagamento parcial registrar fim ok idVenda=${idVenda} em ${Date.now() - startedAt}ms`);
      showStatusNotice('Concluído', 'Pagamento parcial registrado com sucesso.', 'success');
    } catch (error: any) {
      logSyncDiagnostic(`fluxo pagamento parcial registrar erro idVenda=${idVenda}: ${error?.message || 'erro desconhecido'}`, 2);
      Alert.alert('Erro', error?.message || 'Não foi possível registrar pagamento.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <View style={styles.container}>
      <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
        <ScreenRouteLabel />
        {statusNotice.visible ? (
          <View
            style={[
              styles.noticeCard,
              statusNotice.tone === 'success' ? styles.noticeSuccess : null,
              statusNotice.tone === 'error' ? styles.noticeError : null,
              statusNotice.tone === 'warning' ? styles.noticeWarning : null
            ]}
          >
            <View style={styles.noticeHeaderRow}>
              <Text style={styles.noticeTitle}>{statusNotice.title}</Text>
              <Pressable onPress={() => setStatusNotice((prev) => ({ ...prev, visible: false }))}>
                <Text style={styles.noticeDismiss}>Fechar</Text>
              </Pressable>
            </View>
            <Text style={styles.noticeMessage}>{statusNotice.message}</Text>
          </View>
        ) : null}
        {!idVenda ? (
          <View style={styles.infoCard}>
            <Text style={styles.infoTitle}>Fluxo inválido</Text>
            <Text style={styles.infoText}>Selecione uma mesa e abra a venda em Mesas antes de registrar pagamento.</Text>
            <Pressable style={styles.primaryBtn} onPress={() => navigation.navigate('Tabs', { screen: 'Mesas' })}>
              <Text style={styles.primaryText}>Ir para Mesas</Text>
            </Pressable>
          </View>
        ) : (
          <>
            <SectionHeader title={`Pagamento parcial #${idVenda}`} subtitle="Adicione pagamentos e registre na venda." />

            <View style={styles.card}>
              <Text style={styles.label}>Total da venda</Text>
              <Text style={styles.value}>R$ {saleTotal.toFixed(2)}</Text>
              <Text style={styles.label}>Total já recebido</Text>
              <Text style={styles.value}>R$ {totalPago.toFixed(2)}</Text>
              <Text style={styles.label}>Pendente</Text>
              <Text style={[styles.value, styles.pending]}>R$ {valorPendente.toFixed(2)}</Text>
            </View>

            <View style={styles.card}>
              <Text style={styles.label}>Adicionar pagamentos</Text>
              {drafts.map((line, index) => {
                const selectedMethod = methods.find((method) => method.codigo === line.codigo) || methods[0];
                const isLocked = Boolean(line.processed);
                return (
                  <View key={`draft-${index}`} style={[styles.paymentLine, isLocked ? styles.paymentLineLocked : null]}>
                    <Text style={styles.payLabel}>Método</Text>
                    <Text style={styles.selectedMethod}>{selectedMethod?.descricao || 'Selecionar'}</Text>
                    <View style={styles.methods}>
                      {methods.map((method) => (
                        <Pressable
                          key={`${method.codigo}-${index}`}
                          disabled={isLocked || isMachinePaymentRunning}
                          style={[
                            styles.methodButton,
                            line.codigo === method.codigo ? styles.methodSelected : null,
                            isLocked || isMachinePaymentRunning ? styles.methodButtonDisabled : null
                          ]}
                          onPress={() => onSelectDraftMethod(index, method.codigo)}
                        >
                          <Text style={[styles.methodText, line.codigo === method.codigo ? styles.methodSelectedText : null]}>
                            {method.descricao}
                          </Text>
                        </Pressable>
                      ))}
                    </View>
                    <Text style={styles.payLabel}>Valor (R$)</Text>
                    <TextInput
                      style={[styles.input, isLocked ? styles.inputLocked : null]}
                      keyboardType="numeric"
                      value={line.valor}
                      editable={!isLocked}
                      onChangeText={(value) => setDraftValue(index, value)}
                      placeholder="0,00"
                    />
                    {isLocked ? (
                      <View style={styles.paymentApprovedBox}>
                        <Text style={styles.paymentApprovedTitle}>Pagamento aprovado</Text>
                        {line.provider ? (
                          <Text style={styles.paymentApprovedText}>
                            Integração: {String(line.provider).toUpperCase()}
                          </Text>
                        ) : null}
                        {line.nsu ? <Text style={styles.paymentApprovedText}>NSU: {line.nsu}</Text> : null}
                      </View>
                    ) : null}
                    {drafts.length > 1 && !isLocked ? (
                      <Pressable style={styles.removeBtn} onPress={() => removeDraft(index)}>
                        <Text style={styles.removeText}>Remover</Text>
                      </Pressable>
                    ) : null}
                  </View>
                );
              })}

              <Pressable
                style={[styles.addBtn, saving || isMachinePaymentRunning ? styles.addBtnDisabled : null]}
                disabled={saving || isMachinePaymentRunning}
                onPress={addDraft}
              >
                <Text style={styles.addText}>Adicionar pagamento</Text>
              </Pressable>

              <Text style={styles.label}>Total digitado</Text>
              <Text style={styles.value}>R$ {totalDigitado.toFixed(2)}</Text>

              <Pressable
                style={[styles.primaryBtn, saving || loading || isMachinePaymentRunning ? styles.primaryBtnDisabled : null]}
                onPress={register}
                disabled={saving || loading || isMachinePaymentRunning}
              >
                <Text style={styles.primaryText}>{saving ? 'Salvando...' : 'Pagamento Parcial'}</Text>
              </Pressable>
            </View>

            <Text style={styles.subsectionTitle}>Histórico desta venda</Text>
            <View style={styles.listWrap}>
              {loading ? (
                <Text style={styles.infoText}>Carregando...</Text>
              ) : (
                <FlatList
                  data={pagamentos}
                  keyExtractor={(item) => String(item.idVendaPagamentoAntecipado || `${item.idFormaPagamento || Math.random()}`)}
                  scrollEnabled={false}
                  ListEmptyComponent={<Text style={styles.infoText}>Sem pagamentos registrados.</Text>}
                  renderItem={({ item }) => {
                    const method = item.formaPagamento?.descricao || `Forma ${item.idFormaPagamento || '-'}`;
                    return (
                      <View style={styles.item}>
                        <Text style={styles.itemTitle}>{method}</Text>
                        <Text style={styles.itemValue}>R$ {(item.valor || 0).toFixed(2)}</Text>
                      </View>
                    );
                  }}
                />
              )}
            </View>
          </>
        )}
      </ScrollView>

      {paymentProcessingVisible ? (
        <View style={styles.modalOverlay} pointerEvents="auto">
          <View style={styles.modalCard}>
            <ActivityIndicator size="large" color={Colors.primary} style={{ marginBottom: 16 }} />
            {paymentProcessingLabel ? (
              <Text style={styles.modalLabel}>{paymentProcessingLabel}</Text>
            ) : null}
            <Text style={styles.modalMessage}>{paymentProcessingMessage || 'Aguarde...'}</Text>
            <Pressable
              style={styles.cancelPaymentBtn}
              onPress={() => cancelCurrentMachinePayment(
                paymentProcessingLineIndex ?? undefined,
                'Pagamento cancelado pelo usuário.'
              )}
            >
              <Text style={styles.cancelPaymentText}>Cancelar</Text>
            </Pressable>
          </View>
        </View>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  scrollView: { flex: 1 },
  scrollContent: { padding: Space.md, paddingBottom: 120 },
  noticeCard: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    borderRadius: 20,
    padding: 14,
    marginBottom: Space.md,
    ...Shadows.soft
  },
  noticeWarning: {
    borderColor: Colors.warning
  },
  noticeSuccess: {
    borderColor: Colors.success
  },
  noticeError: {
    borderColor: Colors.danger
  },
  noticeHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
    marginBottom: 6
  },
  noticeTitle: {
    color: Colors.text,
    fontWeight: '800',
    fontSize: 16,
    flex: 1
  },
  noticeDismiss: {
    color: Colors.primary,
    fontWeight: '700',
    fontSize: 12
  },
  noticeMessage: {
    color: Colors.textMuted,
    lineHeight: 20
  },
  card: {
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 24,
    padding: Space.md,
    marginBottom: Space.md,
    ...Shadows.card
  },
  label: {
    color: Colors.textMuted,
    marginBottom: 6,
    fontWeight: '700',
    fontSize: 12
  },
  value: {
    color: Colors.text,
    fontSize: 22,
    fontWeight: '900',
    marginBottom: 10
  },
  pending: {
    color: Colors.warning
  },
  methods: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 12
  },
  methodButton: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 8,
    backgroundColor: Colors.cardSoft
  },
  methodSelected: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft
  },
  methodButtonDisabled: {
    opacity: 0.4
  },
  methodText: {
    color: Colors.textMuted,
    fontWeight: '700',
    fontSize: 12
  },
  methodSelectedText: {
    color: Colors.primary
  },
  input: {
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    borderRadius: 18,
    padding: 12,
    backgroundColor: Colors.cardSoft,
    color: Colors.text,
    marginBottom: Space.sm
  },
  inputLocked: {
    opacity: 0.5,
    backgroundColor: Colors.border
  },
  paymentLine: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    borderRadius: 20,
    padding: 10,
    marginBottom: 10,
    ...Shadows.soft
  },
  paymentLineLocked: {
    borderColor: Colors.success ?? '#22c55e',
    backgroundColor: 'rgba(34,197,94,0.06)'
  },
  paymentApprovedBox: {
    borderWidth: 1,
    borderColor: Colors.success ?? '#22c55e',
    borderRadius: 12,
    padding: 10,
    marginBottom: 8,
    backgroundColor: 'rgba(34,197,94,0.08)'
  },
  paymentApprovedTitle: {
    color: Colors.success ?? '#22c55e',
    fontWeight: '700',
    fontSize: 13,
    marginBottom: 2
  },
  paymentApprovedText: {
    color: Colors.success ?? '#22c55e',
    fontSize: 12
  },
  addBtn: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 18,
    padding: 12,
    alignItems: 'center',
    backgroundColor: Colors.cardSoft,
    marginBottom: 12,
    ...Shadows.soft
  },
  addBtnDisabled: {
    opacity: 0.4
  },
  addText: {
    color: Colors.primary,
    fontWeight: '700'
  },
  primaryBtn: {
    marginTop: 10,
    borderRadius: 18,
    backgroundColor: Colors.primary,
    paddingHorizontal: 14,
    paddingVertical: 10,
    alignItems: 'center',
    ...Shadows.button
  },
  primaryBtnDisabled: {
    opacity: 0.5
  },
  primaryText: {
    color: '#fff',
    fontWeight: '700'
  },
  subsectionTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 8
  },
  listWrap: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 22,
    backgroundColor: Colors.card,
    padding: Space.md,
    marginBottom: Space.md,
    ...Shadows.card
  },
  infoCard: {
    borderWidth: 1,
    borderColor: Colors.warning,
    borderRadius: 22,
    backgroundColor: Colors.accentSoft,
    padding: Space.md,
    marginBottom: Space.md,
    ...Shadows.soft
  },
  infoTitle: {
    color: Colors.warning,
    fontWeight: '700',
    marginBottom: 4
  },
  infoText: {
    color: Colors.textMuted,
    paddingVertical: 4
  },
  item: {
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
    paddingVertical: 10,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  itemTitle: {
    color: Colors.text,
    fontWeight: '700',
    flex: 1,
    paddingRight: 12
  },
  itemValue: {
    color: Colors.text,
    fontWeight: '700'
  },
  payLabel: {
    color: Colors.textMuted,
    marginTop: 4,
    marginBottom: 4
  },
  selectedMethod: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 6
  },
  removeBtn: {
    marginTop: 6,
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
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.55)',
    alignItems: 'center',
    justifyContent: 'center'
  },
  modalCard: {
    backgroundColor: Colors.card,
    borderRadius: 24,
    padding: 28,
    width: '82%',
    alignItems: 'center',
    ...Shadows.card
  },
  modalLabel: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: 15,
    textAlign: 'center',
    marginBottom: 8
  },
  modalMessage: {
    color: Colors.textMuted,
    fontSize: 13,
    textAlign: 'center',
    marginBottom: 20
  },
  cancelPaymentBtn: {
    borderWidth: 1,
    borderColor: Colors.warning,
    borderRadius: 999,
    paddingHorizontal: 24,
    paddingVertical: 10
  },
  cancelPaymentText: {
    color: Colors.warning,
    fontWeight: '700'
  }
});
