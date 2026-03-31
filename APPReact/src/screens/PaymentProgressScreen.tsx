import React, { useEffect, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { RouteProp, useRoute } from '@react-navigation/native';
import { useNavigation } from '@react-navigation/native';
import { RootStackParams } from '../navigation/AppNavigator';
import { useApp } from '../context/AppContext';
import { api, SalePayment } from '../services/api';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { Colors, Radius, Space } from '../theme';

type Route = RouteProp<RootStackParams, 'PagamentoProgresso'>;

export const PaymentProgressScreen: React.FC = () => {
  const route = useRoute<Route>();
  const navigation = useNavigation();
  const { activeTable } = useApp();
  const [loading, setLoading] = useState(false);
  const [payments, setPayments] = useState<SalePayment[]>([]);
  const idVenda = route.params?.idVenda || activeTable?.idVenda;
  const [valorTotal, setValorTotal] = useState(0);

  const load = async () => {
    if (!idVenda) return;
    setLoading(true);
    try {
      const sale = await api.getSale(idVenda, false);
      setValorTotal(sale?.valorTotal || sale?.valor || 0);
      const list = await api.listPaymentsBySale(idVenda);
      setPayments(list);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, [idVenda]);

  const recebido = useMemo(() => payments.reduce((acc, item) => acc + (item.valor || 0), 0), [payments]);
  const percentual = valorTotal > 0 ? Math.min(100, (recebido / valorTotal) * 100) : 0;
  const restante = Math.max(0, valorTotal - recebido);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <ScreenRouteLabel />
      <SectionHeader
        title="Progresso de Pagamento"
        subtitle={idVenda ? `Venda #${idVenda}` : 'Selecione uma mesa e abra a venda em Mesas'}
      />

      {!idVenda ? (
        <View style={styles.card}>
          <Text style={styles.warning}>Fluxo inválido</Text>
          <Text style={styles.text}>Selecione uma mesa e abra a venda em Mesas para acompanhar pagamentos.</Text>
          <Pressable style={styles.primaryBtn} onPress={() => navigation.navigate('Tabs', { screen: 'Mesas' })}>
            <Text style={styles.primaryText}>Ir para Mesas</Text>
          </Pressable>
        </View>
      ) : (
        <>
          <View style={styles.card}>
            <Text style={styles.label}>Total da venda</Text>
            <Text style={styles.money}>R$ {valorTotal.toFixed(2)}</Text>
          </View>
          <View style={styles.card}>
            <Text style={styles.label}>Recebido</Text>
            <Text style={styles.money}>R$ {recebido.toFixed(2)}</Text>
            <View style={styles.barBg}>
              <View style={[styles.barFill, { width: `${percentual}%` }]} />
            </View>
            <Text style={styles.text}>{percentual.toFixed(0)}% pago</Text>
            <Text style={styles.warning}>Restante: R$ {restante.toFixed(2)}</Text>
          </View>
          <View style={styles.card}>
            <Text style={styles.label}>Histórico</Text>
            {loading ? (
              <Text style={styles.text}>Carregando...</Text>
            ) : payments.length === 0 ? (
              <Text style={styles.text}>Sem pagamentos registrados.</Text>
            ) : (
              payments.map((payment, index) => (
                <View key={`${payment.idFormaPagamento}-${index}`} style={styles.item}>
                  <Text style={styles.itemMethod}>{payment.formaPagamento?.descricao || `Forma ${payment.idFormaPagamento || '-'}`}</Text>
                  <Text style={styles.money}>{payment.valor.toFixed(2)}</Text>
                </View>
              ))
            )}
          </View>
        </>
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background, padding: Space.md },
  content: { paddingBottom: 160 },
  card: {
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    padding: Space.md,
    marginBottom: Space.md
  },
  warning: { color: Colors.warning, fontWeight: '700', marginBottom: 4 },
  text: { color: Colors.textMuted },
  label: { color: Colors.textMuted, marginBottom: 4, fontWeight: '700', fontSize: 12 },
  money: { color: Colors.text, fontWeight: '900', fontSize: 28, marginBottom: 12 },
  barBg: {
    width: '100%',
    height: 10,
    borderRadius: 99,
    backgroundColor: Colors.cardSoft,
    marginBottom: 8
  },
  barFill: {
    height: 10,
    borderRadius: 99,
    backgroundColor: Colors.primary
  },
  item: {
    borderTopWidth: 1,
    borderTopColor: Colors.border,
    paddingTop: 8,
    paddingBottom: 8,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  primaryBtn: {
    marginTop: 10,
    alignSelf: 'flex-start',
    borderRadius: 10,
    backgroundColor: Colors.primary,
    paddingHorizontal: 14,
    paddingVertical: 10
  },
  primaryText: {
    color: '#fff',
    fontWeight: '700'
  },
  itemMethod: {
    color: Colors.text,
    fontWeight: '700'
  }
});
