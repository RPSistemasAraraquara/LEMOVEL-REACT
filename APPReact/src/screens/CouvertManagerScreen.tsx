import React, { useEffect, useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { RouteProp, useRoute } from '@react-navigation/native';
import { useNavigation } from '@react-navigation/native';
import { RootStackParams } from '../navigation/AppNavigator';
import { useApp } from '../context/AppContext';
import { api } from '../services/api';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { Colors, Radius, Shadows, Space } from '../theme';
import {
  adjustCouvertText,
  clampCouvertText,
  normalizeCouvertCount,
  validateCouvertNotReduced
} from '../utils/couvertLock';

type Route = RouteProp<RootStackParams, 'Couvert'>;

const parseNumber = (value: string) => {
  const parsed = Number(value.replace(',', '.'));
  return Number.isFinite(parsed) ? parsed : 0;
};

const parseInteger = (value: string) => {
  const parsed = Math.round(parseNumber(value));
  return Number.isFinite(parsed) ? Math.max(0, parsed) : 0;
};

export const CouvertManagerScreen: React.FC = () => {
  const route = useRoute<Route>();
  const navigation = useNavigation<any>();
  const { activeTable, refreshDashboard } = useApp();
  const [idVenda] = useState<number | undefined>(route.params?.idVenda || undefined);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [numPessoas, setNumPessoas] = useState('0');
  const [masculino, setMasculino] = useState('0');
  const [feminino, setFeminino] = useState('0');
  const [minimumCouvert, setMinimumCouvert] = useState({ masculino: 0, feminino: 0 });
  const vendaAtual = idVenda || activeTable?.idVenda;

  useEffect(() => {
    if (!vendaAtual) return;
    const load = async () => {
      setLoading(true);
      try {
        const sale = await api.getSale(vendaAtual, false);
        if (!sale) return;
        const nextMinimum = {
          masculino: normalizeCouvertCount(sale.numeroCouvertMasculino || 0),
          feminino: normalizeCouvertCount(sale.numeroCouvertFeminino || 0)
        };
        setNumPessoas(String(sale.numeroPessoas || 0));
        setMasculino(String(nextMinimum.masculino));
        setFeminino(String(nextMinimum.feminino));
        setMinimumCouvert(nextMinimum);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [vendaAtual]);

  const changeInteger = (setter: (value: string) => void, current: string, delta: number) => {
    const next = Math.max(0, parseInteger(current) + delta);
    setter(String(next));
  };

  const changeCouvertInteger = (
    setter: (value: string) => void,
    current: string,
    delta: number,
    minimum: number
  ) => {
    setter(adjustCouvertText(current, delta, minimum));
  };

  const save = async () => {
    if (!vendaAtual) return;
    const nextCouvert = {
      masculino: normalizeCouvertCount(masculino),
      feminino: normalizeCouvertCount(feminino)
    };
    const reductionMessage = validateCouvertNotReduced(nextCouvert, minimumCouvert);
    if (reductionMessage) {
      setMasculino(String(minimumCouvert.masculino));
      setFeminino(String(minimumCouvert.feminino));
      Alert.alert('Atenção', reductionMessage);
      return;
    }

    setSaving(true);
    try {
      const numeroPessoas = Math.max(parseInteger(numPessoas), nextCouvert.masculino + nextCouvert.feminino);
      await api.updateCouvert(vendaAtual, {
        numeroPessoas,
        numeroCouvertMasculino: nextCouvert.masculino,
        numeroCouvertFeminino: nextCouvert.feminino
      });
      setNumPessoas(String(numeroPessoas));
      setMinimumCouvert(nextCouvert);
      await refreshDashboard();
      Alert.alert('Concluído', 'Informações de couvert atualizadas.');
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível salvar.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <ScreenRouteLabel />
      <SectionHeader title="Controle de Couvert" subtitle="Pessoas e cobrança de couvert por mesa." />

      {!vendaAtual ? (
        <View style={styles.card}>
          <Text style={styles.title}>Fluxo inválido</Text>
          <Text style={styles.text}>Selecione uma mesa e abra a venda em Mesas para atualizar o couvert.</Text>
          <Pressable style={styles.primaryBtn} onPress={() => navigation.navigate('Tabs', { screen: 'Mesas' })}>
            <Text style={styles.primaryBtnText}>Ir para Mesas</Text>
          </Pressable>
        </View>
      ) : (
        <>
          {loading ? (
            <View style={styles.card}>
              <Text style={styles.title}>Carregando dados da venda...</Text>
            </View>
          ) : null}
          <View style={styles.card}>
            <Text style={styles.label}>Venda</Text>
            <Text style={styles.saleId}>#{vendaAtual}</Text>
          </View>
          <View style={styles.card}>
            <Text style={styles.label}>Número de pessoas</Text>
            <View style={styles.counterRow}>
              <Pressable
                style={styles.counterBtn}
                onPress={() => changeInteger(setNumPessoas, numPessoas, -1)}
              >
                <Text style={styles.counterText}>-</Text>
              </Pressable>
              <TextInput
                style={[styles.input, styles.counterInput]}
                keyboardType="numeric"
                value={numPessoas}
                onChangeText={setNumPessoas}
              />
              <Pressable
                style={styles.counterBtn}
                onPress={() => changeInteger(setNumPessoas, numPessoas, +1)}
              >
                <Text style={styles.counterText}>+</Text>
              </Pressable>
            </View>
            <Text style={styles.label}>Couvert Masculino</Text>
            <View style={styles.counterRow}>
              <Pressable
                style={[styles.counterBtn, parseInteger(masculino) <= minimumCouvert.masculino ? styles.counterBtnDisabled : null]}
                disabled={parseInteger(masculino) <= minimumCouvert.masculino}
                onPress={() => changeCouvertInteger(setMasculino, masculino, -1, minimumCouvert.masculino)}
              >
                <Text style={styles.counterText}>-</Text>
              </Pressable>
              <TextInput
                style={[styles.input, styles.counterInput]}
                keyboardType="numeric"
                value={masculino}
                onChangeText={(value) => setMasculino(clampCouvertText(value, minimumCouvert.masculino))}
              />
              <Pressable
                style={styles.counterBtn}
                onPress={() => changeCouvertInteger(setMasculino, masculino, +1, minimumCouvert.masculino)}
              >
                <Text style={styles.counterText}>+</Text>
              </Pressable>
            </View>
            <Text style={styles.label}>Couvert Feminino</Text>
            <View style={styles.counterRow}>
              <Pressable
                style={[styles.counterBtn, parseInteger(feminino) <= minimumCouvert.feminino ? styles.counterBtnDisabled : null]}
                disabled={parseInteger(feminino) <= minimumCouvert.feminino}
                onPress={() => changeCouvertInteger(setFeminino, feminino, -1, minimumCouvert.feminino)}
              >
                <Text style={styles.counterText}>-</Text>
              </Pressable>
              <TextInput
                style={[styles.input, styles.counterInput]}
                keyboardType="numeric"
                value={feminino}
                onChangeText={(value) => setFeminino(clampCouvertText(value, minimumCouvert.feminino))}
              />
              <Pressable
                style={styles.counterBtn}
                onPress={() => changeCouvertInteger(setFeminino, feminino, +1, minimumCouvert.feminino)}
              >
                <Text style={styles.counterText}>+</Text>
              </Pressable>
            </View>
            <Pressable style={styles.btn} onPress={save} disabled={saving}>
              <Text style={styles.btnText}>{saving ? 'Salvando...' : 'Salvar couvert'}</Text>
            </Pressable>
          </View>
        </>
      )}
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
    paddingBottom: 160
  },
  card: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 24,
    backgroundColor: Colors.card,
    padding: Space.md,
    marginBottom: Space.md,
    ...Shadows.card
  },
  title: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 6
  },
  text: {
    color: Colors.textMuted
  },
  primaryBtn: {
    marginTop: 12,
    borderRadius: 18,
    backgroundColor: Colors.primary,
    paddingVertical: 10,
    paddingHorizontal: 14,
    alignSelf: 'flex-start',
    ...Shadows.button
  },
  primaryBtnText: {
    color: '#fff',
    fontWeight: '700'
  },
  saleId: {
    color: Colors.primary,
    fontWeight: '900',
    fontSize: 22
  },
  label: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 6
  },
  input: {
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    backgroundColor: Colors.cardSoft,
    borderRadius: 18,
    padding: 12,
    color: Colors.text,
    marginBottom: 12
  },
  counterRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Space.sm,
    marginBottom: 12
  },
  counterBtn: {
    width: 42,
    height: 42,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.cardSoft,
    ...Shadows.soft
  },
  counterBtnDisabled: {
    opacity: 0.45
  },
  counterText: {
    color: Colors.primary,
    fontSize: 20,
    fontWeight: '800'
  },
  counterInput: {
    flex: 1,
    marginBottom: 0,
    textAlign: 'center'
  },
  btn: {
    borderRadius: 18,
    backgroundColor: Colors.primary,
    padding: 12,
    alignItems: 'center',
    ...Shadows.button
  },
  btnText: {
    color: '#fff',
    fontWeight: '700'
  }
});
