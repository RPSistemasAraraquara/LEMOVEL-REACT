import React, { useMemo, useState } from 'react';
import { Alert, FlatList, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useApp } from '../context/AppContext';
import { MenuItem } from '../services/api';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { Colors, Radius, Shadows, Space } from '../theme';

type ProductForm = {
  descricao: string;
  descricaoCurta: string;
  valorVenda: string;
  tamanhoPadrao: string;
};

export const ProductManagerScreen: React.FC = () => {
  const { categories, products } = useApp();
  const [query, setQuery] = useState('');
  const [editingId, setEditingId] = useState<number | null>(null);
  const [form, setForm] = useState<ProductForm>({
    descricao: '',
    descricaoCurta: '',
    valorVenda: '',
    tamanhoPadrao: 'U'
  });
  const [activeItems, setActiveItems] = useState<MenuItem[]>([]);

  React.useEffect(() => {
    if (products.length) {
      setActiveItems(products);
    }
  }, [products]);

  const selectedCategory = useMemo(() => {
    return categories.map((item) => item.descricao);
  }, [categories]);

  const filtered = useMemo(() => {
    const term = query.toLowerCase().trim();
    if (!term) return activeItems;
    return activeItems.filter((product) =>
      `${product.descricao} ${product.descricaoCurta ?? ''}`.toLowerCase().includes(term)
    );
  }, [activeItems, query]);

  const onReset = () => {
    setEditingId(null);
    setForm({
      descricao: '',
      descricaoCurta: '',
      valorVenda: '',
      tamanhoPadrao: 'U'
    });
  };

  const onBeginEdit = (product: MenuItem) => {
    setEditingId(product.idProduto);
    setForm({
      descricao: product.descricao,
      descricaoCurta: product.descricaoCurta || '',
      valorVenda: String(product.valorVenda || 0),
      tamanhoPadrao: product.tamanhoPadrao || 'U'
    });
  };

  const onSave = () => {
    const data = {
      ...form,
      valorVenda: Number(form.valorVenda.replace(',', '.'))
    };
    if (!data.descricao.trim() || !Number.isFinite(data.valorVenda) || data.valorVenda < 0) {
      Alert.alert('Validação', 'Descrição e valor devem ser informados.');
      return;
    }

    setActiveItems((prev) => {
      if (editingId) {
        return prev.map((item) =>
          item.idProduto === editingId
            ? {
                ...item,
                descricao: data.descricao.trim(),
                descricaoCurta: data.descricaoCurta.trim(),
                valorVenda: data.valorVenda,
                tamanhoPadrao: data.tamanhoPadrao
              }
            : item
        );
      }
      return [
        {
          id: activeItems.length + 1000,
          idProduto: activeItems.length + 1000,
          descricao: data.descricao.trim(),
          descricaoCurta: data.descricaoCurta.trim(),
          valorVenda: data.valorVenda,
          valorUnitario: data.valorVenda,
          idCategoria: categories[0]?.id,
          b_venda_mobile: true,
          vendaPorTamanho: data.tamanhoPadrao !== 'U',
          tamanhoPadrao: data.tamanhoPadrao
        } as MenuItem,
        ...prev
      ];
    });

    onReset();
  };

  const onDelete = (idProduto: number) => {
    Alert.alert('Confirmação', 'Deseja remover o produto localmente?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Remover',
        style: 'destructive',
        onPress: () => setActiveItems((prev) => prev.filter((item) => item.idProduto !== idProduto))
      }
    ]);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <ScreenRouteLabel />
      <SectionHeader title="Gestão de Produtos" subtitle="Visual moderno para cadastro de itens e preços." />

      <View style={styles.card}>
        <Text style={styles.label}>Buscar produto</Text>
        <TextInput
          style={styles.input}
          value={query}
          onChangeText={setQuery}
          placeholder="Digite nome ou parte do texto"
          placeholderTextColor={Colors.textMuted}
        />
      </View>

      <View style={styles.card}>
        <Text style={styles.label}>{editingId ? 'Editar produto selecionado' : 'Novo produto'}</Text>
        <TextInput
          style={styles.input}
          value={form.descricao}
          onChangeText={(value) => setForm((prev) => ({ ...prev, descricao: value }))}
          placeholder="Nome do produto"
          placeholderTextColor={Colors.textMuted}
        />
        <TextInput
          style={styles.input}
          value={form.descricaoCurta}
          onChangeText={(value) => setForm((prev) => ({ ...prev, descricaoCurta: value }))}
          placeholder="Descrição curta"
          placeholderTextColor={Colors.textMuted}
        />
        <TextInput
          style={styles.input}
          value={form.valorVenda}
          keyboardType="decimal-pad"
          onChangeText={(value) => setForm((prev) => ({ ...prev, valorVenda: value }))}
          placeholder="Preço base (ex.: 12,90)"
          placeholderTextColor={Colors.textMuted}
        />
        <View style={styles.sizeRow}>
          <Text style={styles.sizeTitle}>Tamanho padrão</Text>
          <Pressable
            style={[styles.sizeChip, form.tamanhoPadrao === 'U' && styles.sizeChipActive]}
            onPress={() => setForm((prev) => ({ ...prev, tamanhoPadrao: 'U' }))}
          >
            <Text style={styles.sizeChipText}>Único</Text>
          </Pressable>
          <Pressable
            style={[styles.sizeChip, form.tamanhoPadrao === 'P' && styles.sizeChipActive]}
            onPress={() => setForm((prev) => ({ ...prev, tamanhoPadrao: 'P' }))}
          >
            <Text style={styles.sizeChipText}>P</Text>
          </Pressable>
          <Pressable
            style={[styles.sizeChip, form.tamanhoPadrao === 'M' && styles.sizeChipActive]}
            onPress={() => setForm((prev) => ({ ...prev, tamanhoPadrao: 'M' }))}
          >
            <Text style={styles.sizeChipText}>M</Text>
          </Pressable>
          <Pressable
            style={[styles.sizeChip, form.tamanhoPadrao === 'G' && styles.sizeChipActive]}
            onPress={() => setForm((prev) => ({ ...prev, tamanhoPadrao: 'G' }))}
          >
            <Text style={styles.sizeChipText}>G</Text>
          </Pressable>
        </View>
        <View style={styles.rowActions}>
          <Pressable style={styles.btnPrimary} onPress={onSave}>
            <Text style={styles.btnText}>{editingId ? 'Salvar alterações' : 'Adicionar produto'}</Text>
          </Pressable>
          {!!editingId && (
            <Pressable style={styles.btnSecondary} onPress={onReset}>
              <Text style={styles.btnTextDark}>Cancelar</Text>
            </Pressable>
          )}
        </View>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Lista de produtos ({filtered.length})</Text>
        <FlatList
          data={filtered}
          keyExtractor={(item) => String(item.idProduto)}
          scrollEnabled={false}
          ListHeaderComponent={<Text style={styles.tip}>Categorias disponíveis: {selectedCategory.join(', ') || '-'}</Text>}
          renderItem={({ item }) => (
            <View style={styles.item}>
              <View style={{ flex: 1 }}>
                <Text style={styles.itemTitle}>{item.descricao}</Text>
                {!!item.descricaoCurta && <Text style={styles.itemDesc}>{item.descricaoCurta}</Text>}
                <Text style={styles.itemValue}>Preço: R$ {(item.valorVenda || 0).toFixed(2)} | Tamanho: {item.tamanhoPadrao || 'U'}</Text>
              </View>
              <View style={styles.itemActions}>
                <Pressable style={styles.smallBtn} onPress={() => onBeginEdit(item)}>
                  <Text style={styles.smallText}>Editar</Text>
                </Pressable>
                <Pressable style={[styles.smallBtn, styles.deleteBtn]} onPress={() => onDelete(item.idProduto)}>
                  <Text style={styles.smallText}>Remover</Text>
                </Pressable>
              </View>
            </View>
          )}
          ListEmptyComponent={<Text style={styles.empty}>Nenhum item encontrado.</Text>}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
    padding: Space.md
  },
  content: {
    paddingBottom: 180
  },
  card: {
    marginBottom: Space.md,
    backgroundColor: Colors.card,
    borderColor: Colors.border,
    borderWidth: 1,
    borderRadius: 24,
    padding: Space.md,
    ...Shadows.card
  },
  label: {
    color: Colors.textMuted,
    marginBottom: 6,
    fontWeight: '700'
  },
  input: {
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    borderRadius: 18,
    padding: 12,
    backgroundColor: Colors.cardSoft,
    color: Colors.text,
    marginBottom: 10
  },
  sizeRow: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
    marginBottom: 10,
    flexWrap: 'wrap'
  },
  sizeTitle: {
    color: Colors.textMuted,
    marginRight: 8,
    fontWeight: '700',
    fontSize: 12
  },
  sizeChip: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: Colors.cardSoft
  },
  sizeChipActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft
  },
  sizeChipText: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: 12
  },
  rowActions: {
    flexDirection: 'row',
    gap: 8
  },
  btnPrimary: {
    backgroundColor: Colors.primary,
    borderRadius: 18,
    paddingVertical: 12,
    paddingHorizontal: 14,
    alignItems: 'center',
    flex: 1,
    ...Shadows.button
  },
  btnSecondary: {
    backgroundColor: Colors.cardSoft,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: 12,
    paddingHorizontal: 14,
    alignItems: 'center',
    flex: 1,
    ...Shadows.soft
  },
  btnText: {
    color: '#fff',
    fontWeight: '700'
  },
  btnTextDark: {
    color: Colors.primary,
    fontWeight: '700'
  },
  cardTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 10
  },
  tip: {
    color: Colors.textMuted,
    fontSize: 12,
    marginBottom: 10
  },
  item: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 22,
    padding: 12,
    marginBottom: 8,
    backgroundColor: Colors.cardSoft,
    flexDirection: 'row',
    justifyContent: 'space-between',
    ...Shadows.soft
  },
  itemTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 6
  },
  itemDesc: {
    color: Colors.textMuted,
    marginBottom: 4
  },
  itemValue: {
    color: Colors.textMuted,
    fontSize: 12
  },
  itemActions: {
    marginLeft: 12,
    alignItems: 'flex-end',
    justifyContent: 'center',
    gap: 8
  },
  smallBtn: {
    borderRadius: 14,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: 10,
    paddingVertical: 8,
    backgroundColor: Colors.card,
    ...Shadows.soft
  },
  smallText: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: 12
  },
  deleteBtn: {
    borderColor: Colors.danger
  },
  empty: {
    color: Colors.textMuted
  }
});
