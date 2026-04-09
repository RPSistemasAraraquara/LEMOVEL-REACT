import React, { useMemo, useState } from 'react';
import { Alert, FlatList, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { useApp } from '../context/AppContext';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { Colors, Radius, Shadows, Space } from '../theme';

type LocalCategory = {
  id: number;
  descricao: string;
};

export const CategoryManagerScreen: React.FC = () => {
  const { categories, setSelectedCategoryId, selectedCategoryId } = useApp();
  const [editing, setEditing] = useState<LocalCategory | null>(null);
  const [newLabel, setNewLabel] = useState('');
  const [query, setQuery] = useState('');
  const [list, setList] = useState<LocalCategory[]>([]);

  React.useEffect(() => {
    if (categories.length) {
      setList(categories.map((item) => ({ id: item.id, descricao: item.descricao })));
    }
  }, [categories]);

  const filtered = useMemo(() => {
    const term = query.toLowerCase().trim();
    if (!term) return list;
    return list.filter((item) => item.descricao.toLowerCase().includes(term));
  }, [query, list]);

  const clear = () => {
    setEditing(null);
    setNewLabel('');
  };

  const onAdd = () => {
    const label = newLabel.trim();
    if (!label) {
      Alert.alert('Validação', 'Informe uma descrição.');
      return;
    }
    setList((prev) => [
      {
        id: prev.length > 0 ? Math.max(...prev.map((item) => item.id)) + 1 : 1,
        descricao: label
      },
      ...prev
    ]);
    clear();
  };

  const onSave = () => {
    if (!editing) return;
    const label = newLabel.trim();
    if (!label) {
      Alert.alert('Validação', 'Informe uma descrição.');
      return;
    }
    setList((prev) => prev.map((item) => (item.id === editing.id ? { ...item, descricao: label } : item)));
    clear();
  };

  const onDelete = (id: number) => {
    Alert.alert('Excluir', 'Remover categoria localmente?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Remover',
        style: 'destructive',
        onPress: () => setList((prev) => prev.filter((item) => item.id !== id))
      }
    ]);
  };

  const beginEdit = (item: LocalCategory) => {
    setEditing(item);
    setNewLabel(item.descricao);
  };

  const onSelect = (id: number | null) => {
    setSelectedCategoryId(id);
  };

  return (
    <View style={styles.container}>
      <ScreenRouteLabel />
      <SectionHeader title="Categorias" subtitle="Gerencie grupos do cardápio sem perder a velocidade." />

      <View style={styles.panel}>
        <Text style={styles.label}>Filtro</Text>
        <TextInput
          value={query}
          onChangeText={setQuery}
          style={styles.input}
          placeholder="Buscar categoria..."
          placeholderTextColor={Colors.textMuted}
        />
        <Text style={styles.label}>{editing ? 'Editar categoria' : 'Nova categoria'}</Text>
        <TextInput
          value={newLabel}
          onChangeText={setNewLabel}
          style={styles.input}
          placeholder="Digite a descrição"
          placeholderTextColor={Colors.textMuted}
        />
        <View style={styles.rowActions}>
          <Pressable
            style={[styles.btn, styles.btnPrimary]}
            onPress={editing ? onSave : onAdd}
          >
            <Text style={styles.btnText}>{editing ? 'Salvar' : 'Adicionar'}</Text>
          </Pressable>
	          {!!editing && (
	            <Pressable style={[styles.btn, styles.btnSecondary]} onPress={clear}>
              <Text style={styles.btnTextSecondary}>Cancelar</Text>
	            </Pressable>
	          )}
	        </View>
	      </View>

      <FlatList
        data={filtered}
        contentContainerStyle={styles.list}
        keyExtractor={(item) => String(item.id)}
        ListHeaderComponent={
          <Text style={styles.sectionTitle}>Categorias locais ({filtered.length})</Text>
        }
        renderItem={({ item }) => (
          <View style={styles.item}>
            <View style={styles.itemContent}>
              <Pressable
                style={[styles.status, { borderColor: selectedCategoryId === item.id ? Colors.primary : Colors.border }]}
                onPress={() => onSelect(item.id === selectedCategoryId ? null : item.id)}
              >
                <Text
                  style={[
                    styles.statusText,
                    { color: selectedCategoryId === item.id ? Colors.primary : Colors.textMuted }
                  ]}
                >
                  {selectedCategoryId === item.id ? 'Usando' : 'Selecionar'}
                </Text>
              </Pressable>
              <View>
                <Text style={styles.itemTitle}>{item.descricao}</Text>
                <Text style={styles.itemSub}>ID #{item.id}</Text>
              </View>
            </View>
            <View style={styles.itemActions}>
              <Pressable style={styles.iconBtn} onPress={() => beginEdit(item)}>
                <Text style={styles.iconText}>✏️</Text>
              </Pressable>
              <Pressable style={[styles.iconBtn, styles.removeBtn]} onPress={() => onDelete(item.id)}>
                <Text style={[styles.iconText, { color: Colors.danger }]}>🗑️</Text>
              </Pressable>
            </View>
          </View>
        )}
        ListEmptyComponent={<Text style={styles.empty}>Nenhuma categoria encontrada.</Text>}
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
  panel: {
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
  input: {
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    borderRadius: 18,
    padding: 12,
    marginBottom: 8,
    backgroundColor: Colors.cardSoft,
    color: Colors.text
  },
  rowActions: {
    flexDirection: 'row',
    gap: 8
  },
  btn: {
    flex: 1,
    borderRadius: 18,
    padding: 12,
    alignItems: 'center'
  },
  btnPrimary: {
    backgroundColor: Colors.primary,
    ...Shadows.button
  },
  btnSecondary: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.cardSoft,
    ...Shadows.soft
  },
  btnText: {
    color: '#fff',
    fontWeight: '700'
  },
  btnTextSecondary: {
    color: Colors.text,
    fontWeight: '700'
  },
  list: {
    paddingBottom: 160
  },
  sectionTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 8
  },
  item: {
    borderRadius: 22,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    padding: 12,
    marginBottom: Space.sm,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    ...Shadows.card
  },
  itemContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10
  },
  status: {
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: Colors.card
  },
  statusText: {
    fontWeight: '700',
    fontSize: 12
  },
  itemTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 4
  },
  itemSub: {
    color: Colors.textMuted,
    fontSize: 12
  },
  itemActions: {
    flexDirection: 'row',
    gap: 8
  },
  iconBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.cardSoft,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    ...Shadows.soft
  },
  removeBtn: {
    borderColor: `${Colors.danger}44`
  },
  iconText: {
    fontSize: 14
  },
  empty: {
    color: Colors.textMuted,
    paddingVertical: 12
  }
});
