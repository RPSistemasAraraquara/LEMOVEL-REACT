import React, { useEffect, useMemo, useState } from 'react';
import { Alert, FlatList, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { RouteProp, useNavigation, useRoute } from '@react-navigation/native';
import { api, normalizeSaleStatus, PaymentMethod, SalePayment } from '../services/api';
import { SectionHeader } from '../components/SectionHeader';
import { SweetAlert, SweetAlertType } from '../components/SweetAlert';
import { Colors, Radius, Shadows, Space } from '../theme';
import { RootStackParams } from '../navigation/AppNavigator';
import { useApp } from '../context/AppContext';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';

type Route = RouteProp<RootStackParams, 'Pagamento'>;

type PaymentDraft = {
  codigo: number;
  valor: string;
  processed?: boolean;
  sfiCodigo?: number;
  provider?: string;
  nsu?: string;
};

const normalize = (value: string) => Number(value.replace(',', '.'));

export const SalePaymentScreen: React.FC = () => {
  const route = useRoute<Route>();
  const navigation = useNavigation();
  const { activeTable, user, refreshDashboard } = useApp();
  const idVenda = route.params?.idVenda || activeTable?.idVenda;

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [methods, setMethods] = useState<PaymentMethod[]>([]);
  const [pagamentos, setPagamentos] = useState<SalePayment[]>([]);
  const [saleTotal, setSaleTotal] = useState(0);
  const [saleStatus, setSaleStatus] = useState('');
  const [drafts, setDrafts] = useState<PaymentDraft[]>([{ codigo: 0, valor: '0' }]);
  const [sweetAlert, setSweetAlert] = useState<{
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

  const resetDrafts = (availableMethods: PaymentMethod[]) => {
    setDrafts([{ codigo: availableMethods[0]?.codigo || 0, valor: '0' }]);
  };

  const load = async () => {
    if (!idVenda) return;
    setLoading(true);
    try {
      const [pm, ps, sale] = await Promise.all([
        api.listPaymentMethods(),
        api.listPaymentsBySale(idVenda),
        api.getSale(idVenda, false)
      ]);
      setMethods(pm);
      setPagamentos(ps);
      setSaleTotal(sale?.valorTotal || sale?.valor || 0);
      setSaleStatus(normalizeSaleStatus(sale?.situacao || ''));
      setDrafts((prev) => {
        if (prev.length > 0) return prev;
        return [{ codigo: pm[0]?.codigo || 0, valor: '0' }];
      });
    } catch (error: any) {
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
    setDrafts((prev) =>
      prev.map((item) => ({
        ...item,
        codigo: item.codigo || methods[0]?.codigo || 0
      }))
    );
  }, [methods]);

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

  const setDraftValue = (index: number, value: string) => {
    setDrafts((prev) => {
      const next = [...prev];
      next[index] = {
        ...next[index],
        valor: value,
        processed: false,
        provider: undefined,
        sfiCodigo: undefined,
        nsu: undefined
      };
      return next;
    });
  };

  const setDraftMethod = (index: number, methodId: number) => {
    setDrafts((prev) => {
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

  const addDraft = () => {
    const firstMethod = methods[0];
    setDrafts((prev) => [...prev, { codigo: firstMethod?.codigo || 0, valor: '0', processed: false }]);
  };

  const removeDraft = (index: number) => {
    setDrafts((prev) => prev.filter((_, idx) => idx !== index));
  };

  const onSelectDraftMethod = (index: number, methodId: number) => {
    setDraftMethod(index, methodId);
  };

  const register = async () => {
    if (!idVenda) return;
    if (saving || loading) return;

    if (!user?.permitePagamentoParcial) {
      showSweetAlert('Atenção', 'Sem permissão para pagamento parcial.', 'warning');
      return;
    }
    if (!saleStatus.toLowerCase().includes('pendente')) {
      Alert.alert('Atenção', 'Somente vendas pendentes permitem pagamento parcial.');
      return;
    }

    const hasZeroOrInvalidValue = drafts.some((item) => {
      const hasMethod = Number(item.codigo || 0) > 0;
      const value = normalize(item.valor || '0');
      return hasMethod && (!Number.isFinite(value) || value <= 0);
    });
    if (hasZeroOrInvalidValue) {
      Alert.alert('Atenção', 'Não é permitido inserir pagamento com valor zero.');
      return;
    }

    const lines = drafts
      .map((item, index) => ({
        index,
        codigo: Number(item.codigo || 0),
        valor: normalize(item.valor)
      }))
      .filter((item) => item.codigo > 0 && item.valor > 0);

    if (lines.length === 0) {
      Alert.alert('Atenção', 'Informe ao menos um pagamento com valor maior que zero.');
      return;
    }

    if (totalDigitado > valorPendente + 0.0001) {
      Alert.alert('Atenção', 'O valor pago não pode ser superior ao valor pendente da venda.');
      return;
    }

    setSaving(true);
    try {
      for (const line of lines) {
        const method = methods.find((item) => item.codigo === line.codigo);
        if (!method) {
          throw new Error('Forma de pagamento não encontrada.');
        }

        await api.registerPartialPayment({
          idVenda,
          idFormaPagamento: method.codigo,
          valor: line.valor,
          idUsuario: user?.idUsuario
        });
      }

      await Promise.all([
        load(),
        refreshDashboard(undefined, { force: true })
      ]);
      resetDrafts(methods);
      Alert.alert('Concluído', 'Pagamento parcial registrado com sucesso.', [
        {
          text: 'OK',
          onPress: () => navigation.goBack()
        }
      ]);
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível registrar pagamento.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 120 }}>
      <ScreenRouteLabel />
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
              return (
                <View key={`draft-${index}`} style={styles.paymentLine}>
                  <Text style={styles.payLabel}>Método</Text>
                  <Text style={styles.selectedMethod}>{selectedMethod?.descricao || 'Selecionar'}</Text>
                  <View style={styles.methods}>
                    {methods.map((method) => (
                      <Pressable
                        key={`${method.codigo}-${index}`}
                        style={[styles.methodButton, line.codigo === method.codigo ? styles.methodSelected : null]}
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
                    style={styles.input}
                    keyboardType="numeric"
                    value={line.valor}
                    onChangeText={(value) => setDraftValue(index, value)}
                    placeholder="0,00"
                  />
                  {drafts.length > 1 ? (
                    <Pressable style={styles.removeBtn} onPress={() => removeDraft(index)}>
                      <Text style={styles.removeText}>Remover</Text>
                    </Pressable>
                  ) : null}
                </View>
              );
            })}

            <Pressable style={styles.addBtn} onPress={addDraft}>
              <Text style={styles.addText}>Adicionar pagamento</Text>
            </Pressable>

            <Text style={styles.label}>Total digitado</Text>
            <Text style={styles.value}>R$ {totalDigitado.toFixed(2)}</Text>

            <Pressable style={styles.primaryBtn} onPress={register} disabled={saving || loading}>
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
  paymentLine: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    borderRadius: 20,
    padding: 10,
    marginBottom: 10,
    ...Shadows.soft
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
  }
});
