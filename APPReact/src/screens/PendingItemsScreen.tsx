import React, { useMemo } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useNavigation } from '@react-navigation/native';
import { RootStackParams } from '../navigation/AppNavigator';
import { useApp } from '../context/AppContext';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { Colors, Radius, Shadows, Space } from '../theme';

type Navigation = NativeStackNavigationProp<RootStackParams>;

const formatQty = (value: number) => {
  const numeric = Number(String(value).replace(',', '.'));
  if (!Number.isFinite(numeric)) return '0';
  return Number.isInteger(numeric) ? String(numeric) : numeric.toFixed(3);
};

export const PendingItemsScreen: React.FC = () => {
  const navigation = useNavigation<Navigation>();
  const { cart, activeTable, getLineTotal, getCartTotal, removeFromCart } = useApp();

  const tableLabel = activeTable
    ? `${activeTable.tipo === 'comanda' ? 'Comanda' : 'Mesa'} ${activeTable.idMesa}`
    : 'Mesa não selecionada';

  const summaryLabel = useMemo(
    () => `Itens pendentes: ${cart.length} | Total: R$ ${getCartTotal().toFixed(2)}`,
    [cart.length, getCartTotal]
  );

  const goToMenu = () => {
    const parent = navigation.getParent<NativeStackNavigationProp<RootStackParams>>();
    if (parent) {
      parent.navigate('Tabs', { screen: 'Cardapio' } as never);
      return;
    }
    navigation.navigate('Tabs', { screen: 'Cardapio' } as never);
  };

  return (
    <View style={styles.container}>
      <ScreenRouteLabel />

      <View style={styles.topRow}>
        <Pressable style={styles.backBtn} onPress={goToMenu}>
          <Text style={styles.backBtnText}>Voltar ao Cardápio</Text>
        </Pressable>
      </View>

      <SectionHeader
        title="Itens não enviados"
        subtitle={`${tableLabel}${activeTable?.idVenda ? ` | Venda ${activeTable.idVenda}` : ''}`}
      />

      <View style={styles.summaryCard}>
        <Text style={styles.summaryText}>{summaryLabel}</Text>
      </View>

      <FlatList
        data={cart}
        keyExtractor={(item) => item.lineId}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={
          <View style={styles.emptyCard}>
            <Text style={styles.emptyTitle}>Sem itens pendentes</Text>
            <Text style={styles.emptyText}>Todos os produtos já foram enviados para a API.</Text>
            <Pressable style={styles.emptyBtn} onPress={goToMenu}>
              <Text style={styles.emptyBtnText}>Voltar ao Cardápio</Text>
            </Pressable>
          </View>
        }
        renderItem={({ item }) => (
          <View style={styles.itemCard}>
            <View style={styles.itemInfo}>
              <Text style={styles.itemTitle}>{item.descricao}</Text>
              <Text style={styles.itemMeta}>Qtd: {formatQty(item.quantidade)}</Text>
              <Text style={styles.itemMeta}>Tamanho: {item.descricaoTamanho || item.tamanho || 'Padrão'}</Text>
              {item.observacao ? <Text style={styles.itemMeta}>Obs.: {item.observacao}</Text> : null}
              {item.opcionais?.length ? (
                <View style={styles.optionalsWrap}>
                  {item.opcionais.map((optional, index) => (
                    <Text key={`${item.lineId}-opc-${optional.idOpcional}-${index}`} style={styles.optionalText}>
                      OPC:{optional.descricao}
                    </Text>
                  ))}
                </View>
              ) : null}
              <Text style={styles.itemValue}>R$ {getLineTotal(item).toFixed(2)}</Text>
            </View>
            <Pressable style={styles.removeBtn} onPress={() => removeFromCart(item.lineId)}>
              <Text style={styles.removeBtnText}>Remover</Text>
            </Pressable>
          </View>
        )}
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
  topRow: {
    flexDirection: 'row',
    justifyContent: 'flex-start',
    marginBottom: 8
  },
  backBtn: {
    borderRadius: 18,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    paddingHorizontal: 14,
    paddingVertical: 9,
    ...Shadows.soft
  },
  backBtnText: {
    color: Colors.text,
    fontWeight: '800'
  },
  summaryCard: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 22,
    backgroundColor: Colors.card,
    padding: 10,
    marginBottom: Space.sm,
    ...Shadows.card
  },
  summaryText: {
    color: Colors.text,
    fontWeight: '700'
  },
  listContent: {
    paddingBottom: 120
  },
  emptyCard: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 22,
    backgroundColor: Colors.card,
    padding: Space.md,
    ...Shadows.card
  },
  emptyTitle: {
    color: Colors.text,
    fontWeight: '800',
    marginBottom: 6
  },
  emptyText: {
    color: Colors.textMuted,
    marginBottom: 10
  },
  emptyBtn: {
    borderRadius: 18,
    backgroundColor: Colors.primary,
    alignSelf: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 8,
    ...Shadows.button
  },
  emptyBtnText: {
    color: '#fff',
    fontWeight: '700'
  },
  itemCard: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 22,
    backgroundColor: Colors.card,
    padding: 12,
    marginBottom: 8,
    flexDirection: 'row',
    alignItems: 'center',
    ...Shadows.card
  },
  itemInfo: {
    flex: 1
  },
  itemTitle: {
    color: Colors.text,
    fontWeight: '800',
    marginBottom: 4
  },
  itemMeta: {
    color: Colors.textMuted,
    fontSize: 12,
    marginBottom: 2
  },
  itemValue: {
    color: Colors.primary,
    fontWeight: '800',
    marginTop: 6
  },
  optionalsWrap: {
    marginTop: 2
  },
  optionalText: {
    color: '#4A4A4A',
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 2
  },
  removeBtn: {
    marginLeft: 12,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.warning,
    backgroundColor: Colors.accentSoft,
    paddingHorizontal: 10,
    paddingVertical: 10,
    ...Shadows.soft
  },
  removeBtnText: {
    color: Colors.warning,
    fontWeight: '700',
    fontSize: 12
  }
});
