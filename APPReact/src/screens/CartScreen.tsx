import React, { useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useApp } from '../context/AppContext';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { RootStackParams } from '../navigation/AppNavigator';
import { Colors, Radius, Shadows, Space, Typography } from '../theme';

type AppNav = NativeStackNavigationProp<RootStackParams>;

export const CartScreen: React.FC = () => {
  const { cart, removeFromCart, clearCart, activeTable, getLineTotal, getCartTotal } = useApp();
  const navigation = useNavigation<AppNav>();
  const [sending, setSending] = useState(false);

  const total = getCartTotal();
  const totalItems = cart.reduce((acc, it) => acc + it.quantidade, 0);
  const hasOpenSale = Boolean(activeTable?.idVenda && activeTable.idVenda !== 0);

  const formatQuantity = (value: number) => (Number.isInteger(value) ? value.toString() : value.toFixed(3));
  const formatFractions = (value: typeof cart[number]) =>
    value.fracoes?.length
      ? value.fracoes
          .map((fraction, index) => `${index + 1}/${value.fracoes?.length} ${fraction.produtoDescricao}`)
          .join(' | ')
      : '';

  const sendOrder = async () => {
    if (sending) return;
    setSending(true);
    const parent = navigation.getParent<NativeStackNavigationProp<RootStackParams>>();
    Alert.alert('Enviar pedido', 'Vamos abrir a tela Inicial para concluir o envio.');
    if (parent) {
      parent.navigate('Inicial' as never);
      setSending(false);
      return;
    }
    navigation.navigate('Inicial' as never);
    setSending(false);
  };

  const goBackToMenu = () => {
    navigation.goBack();
  };

  const goToMesas = () => {
    const parent = navigation.getParent<NativeStackNavigationProp<RootStackParams>>();
    if (parent) {
      parent.navigate('Tabs', { screen: 'Mesas' });
      return;
    }

    navigation.navigate('Tabs', { screen: 'Mesas' });
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 140 }}>
      <ScreenRouteLabel />
      <View style={styles.topRow}>
        <Pressable style={styles.backButton} onPress={goBackToMenu}>
          <Text style={styles.backButtonText}>‹</Text>
          <Text style={styles.backButtonLabel}>Voltar</Text>
        </Pressable>
      </View>
      <SectionHeader title="Pedido" subtitle="Revise os itens antes de enviar" />

      {!activeTable && (
        <View style={styles.alertCard}>
          <Text style={styles.alertTitle}>Mesa não aberta</Text>
          <Text style={styles.alertText}>Selecione uma mesa e abra a venda em Mesas antes de enviar itens.</Text>
        </View>
      )}

      {activeTable && !activeTable.idVenda && (
        <View style={styles.alertCard}>
          <Text style={styles.alertTitle}>Mesa não aberta</Text>
          <Text style={styles.alertText}>Selecione uma mesa e abra a venda em Mesas antes de enviar itens.</Text>
        </View>
      )}

      {!hasOpenSale && (
        <View style={styles.flowCard}>
          <Text style={styles.flowTitle}>Mesa não aberta</Text>
          <Text style={styles.flowText}>Abra uma mesa em Mesas para carregar o pedido antes de enviar o carrinho.</Text>
          <Pressable style={styles.primaryBtn} onPress={goToMesas}>
            <Text style={styles.primaryBtnText}>Ir para Mesas</Text>
          </Pressable>
        </View>
      )}

      {cart.length === 0 ? (
        <View style={styles.empty}>
          <Text style={styles.emptyTitle}>Seu carrinho está vazio</Text>
          <Text style={styles.emptyText}>Volte para o cardápio e abra o item para adicionar.</Text>
        </View>
      ) : (
        <>
          {cart.map((item) => (
            <View key={item.lineId} style={styles.line}>
              <View style={{ maxWidth: '72%' }}>
                <Text style={styles.name}>{item.descricao}</Text>
                <Text style={styles.desc}>Qtd: {formatQuantity(item.quantidade)}</Text>
                {!!item.vendaPorTamanho && <Text style={styles.desc}>Tamanho: {item.descricaoTamanho || item.tamanho}</Text>}
                {!!item.fracoes?.length && <Text style={styles.desc}>Frações: {formatFractions(item)}</Text>}
                {!!item.observacao && <Text style={styles.desc}>Obs.: {item.observacao}</Text>}
                {item.opcionais.length > 0 && (
                  <Text style={styles.desc}>Opcionais: {item.opcionais.map((op) => `${op.descricao}${op.valor > 0 ? ` (+R$ ${op.valor.toFixed(2)})` : ''}`).join(', ') || '-'}</Text>
                )}
                {(item.desconto > 0 || item.acrescimo > 0) && (
                  <Text style={styles.adjustLine}>
                    {item.desconto > 0 ? `Desconto: -R$ ${item.desconto.toFixed(2)} ` : ''}
                    {item.acrescimo > 0 ? `Acréscimo: +R$ ${item.acrescimo.toFixed(2)}` : ''}
                  </Text>
                )}
              </View>
              <View style={{ alignItems: 'flex-end' }}>
                <Text style={styles.price}>R$ {getLineTotal(item).toFixed(2)}</Text>
                <Pressable style={styles.removeBtn} onPress={() => removeFromCart(item.lineId)}>
                  <Text style={styles.remove}>Remover</Text>
                </Pressable>
              </View>
            </View>
          ))}

          <View style={styles.totalCard}>
            <Text style={styles.totalLabel}>Total ({totalItems} itens)</Text>
            <Text style={styles.totalValue}>R$ {total.toFixed(2)}</Text>
          </View>

          <Pressable style={styles.primaryBtn} onPress={sendOrder} disabled={sending || !activeTable?.idVenda}>
            <Text style={styles.btnText}>
              {sending ? 'Abrindo...' : 'Enviar pedido'}
            </Text>
          </Pressable>

          <Pressable style={styles.secondaryBtn} onPress={clearCart}>
            <Text style={styles.btnTextSecondary}>Limpar pedido</Text>
          </Pressable>
        </>
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background, padding: Space.md },
  topRow: {
    marginBottom: 8
  },
  backButton: {
    alignSelf: 'flex-start',
    backgroundColor: Colors.card,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: 14,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    ...Shadows.soft
  },
  backButtonText: {
    color: Colors.primary,
    fontWeight: '800',
    fontSize: 18,
    lineHeight: 18
  },
  backButtonLabel: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: 13
  },
  empty: {
    padding: Space.md,
    borderRadius: Radius.lg,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    ...Shadows.card
  },
  emptyTitle: { fontSize: Typography.subtitle, fontWeight: '700', marginBottom: 4 },
  emptyText: { color: Colors.textMuted },
  alertCard: {
    borderWidth: 1,
    borderColor: Colors.warning,
    backgroundColor: Colors.accentSoft,
    borderRadius: Radius.lg,
    padding: Space.md,
    marginBottom: Space.md,
    ...Shadows.soft
  },
  alertTitle: {
    color: Colors.warning,
    fontWeight: '700',
    marginBottom: 4
  },
  alertText: {
    color: Colors.textMuted
  },
  flowCard: {
    marginTop: 12,
    borderWidth: 1,
    borderColor: Colors.warning,
    backgroundColor: Colors.accentSoft,
    borderRadius: Radius.lg,
    padding: 12,
    marginBottom: Space.md,
    ...Shadows.soft
  },
  flowTitle: {
    color: Colors.warning,
    fontWeight: '700',
    marginBottom: 4
  },
  flowText: {
    color: Colors.textMuted,
    marginBottom: 12
  },
  line: {
    backgroundColor: Colors.card,
    borderColor: Colors.border,
    borderWidth: 1,
    borderRadius: Radius.lg,
    padding: Space.md,
    marginBottom: Space.sm,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    ...Shadows.card
  },
  name: { fontWeight: '700', color: Colors.text },
  desc: { color: Colors.textMuted, marginTop: 4 },
  adjustLine: {
    color: Colors.primary,
    marginTop: 6,
    fontSize: 12,
    fontWeight: '700'
  },
  price: { color: Colors.primary, fontWeight: '800', fontSize: 16 },
  removeBtn: { marginTop: 10 },
  remove: { color: Colors.danger, fontWeight: '700', fontSize: 12 },
  totalCard: {
    marginTop: Space.md,
    backgroundColor: Colors.card,
    borderRadius: Radius.lg,
    borderColor: Colors.border,
    borderWidth: 1,
    padding: Space.md,
    flexDirection: 'row',
    justifyContent: 'space-between',
    ...Shadows.card
  },
  totalLabel: { color: Colors.textMuted },
  totalValue: { color: Colors.text, fontWeight: '800', fontSize: 20 },
  primaryBtn: {
    marginTop: 12,
    borderRadius: Radius.lg,
    padding: 14,
    alignItems: 'center',
    backgroundColor: Colors.primary,
    ...Shadows.button
  },
  btnText: { color: '#fff', fontWeight: '700' },
  primaryBtnText: {
    color: '#fff',
    fontWeight: '700'
  },
  secondaryBtn: {
    marginTop: 8,
    borderRadius: Radius.lg,
    padding: 14,
    alignItems: 'center',
    backgroundColor: Colors.cardSoft,
    borderWidth: 1,
    borderColor: Colors.border,
    ...Shadows.soft
  },
  btnTextSecondary: { color: Colors.primary, fontWeight: '700' }
});
