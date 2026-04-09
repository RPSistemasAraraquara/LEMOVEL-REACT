import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Animated,
  Easing,
  Modal,
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
  OPENING_SETTINGS_CONFLICT_MESSAGE
} from '../services/api';
import { RootStackParams } from '../navigation/AppNavigator';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';

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
  tipoIntegracao: 'nenhum' | 'vero' | 'stone' | 'pagbank' | 'cielo';
  modeloMaquininha: string;
};

const IMPRESSORA_MODELOS = ['Padrão ESC/POS', 'POS-58', 'POS-80', 'Termica TSP100', 'Outro'];
const IMPRESSAO_PAGINAS = ['CP437', 'Windows-1252', 'ISO-8859-1', 'UTF-8'];
const BLUETOOTH_LIST = ['Nenhuma', 'BT: Impressora Sala', 'BT: Impressora Cozinha', 'BT: Impressora Entrada'];
type IntegrationValue = 'nenhum' | 'vero' | 'stone' | 'pagbank' | 'cielo';

const INTEGRACAO_OPTIONS: Array<{ label: string; value: IntegrationValue }> = [
  { label: 'Vero', value: 'vero' },
  { label: 'Stone', value: 'stone' },
  { label: 'PagBank', value: 'pagbank' },
  { label: 'Cielo', value: 'cielo' }
];

const toNumberString = (value: number, fallback: string) => (Number.isFinite(value) ? String(value) : fallback);

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
  modeloMaquininha: settings.modeloMaquininha
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
  modeloMaquininha: values.modeloMaquininha
});

export const SettingsScreen: React.FC = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParams, 'Configuracoes'>>();
  const { appSettings, setBaseUrl, setEmpresaId, saveAppSettings } = useApp();
  const [empresa, setEmpresa] = useState('1');
  const [salvando, setSalvando] = useState(false);
  const [status, setStatus] = useState('');
  const [showSavedAlert, setShowSavedAlert] = useState(false);
  const [overlayOpacity] = useState(() => new Animated.Value(0));
  const [cardScale] = useState(() => new Animated.Value(0.92));
  const [settings, setSettings] = useState<SettingsState>(() => toSettingsState(appSettings));
  const [companyInfo, setCompanyInfo] = useState<CompanyInfo | null>(null);

  useEffect(() => {
    setEmpresa(String(appSettings.empresaId || 1));
    setSettings(toSettingsState(appSettings));
  }, [appSettings]);

  useEffect(() => {
    let active = true;

    const loadCompanyInfo = async () => {
      try {
        const company = await api.getCompanyInfo();
        if (!active) {
          return;
        }
        setCompanyInfo(company);
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
        return true;
      }),
    [companyInfo]
  );

  const setValue = <K extends keyof SettingsState>(key: K, value: SettingsState[K]) => {
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
    setSettings((prev) => ({ ...prev, [key]: value } as SettingsState));
  };

  const setMaquininhaEnabled = (value: boolean) => {
    setSettings((prev) => ({
      ...prev,
      utilizaMaquininhaStone: value,
      sincronizarAposLogin: value ? true : prev.sincronizarAposLogin,
      tipoIntegracao: value ? (prev.tipoIntegracao === 'nenhum' ? 'stone' : prev.tipoIntegracao) : 'nenhum',
      modeloMaquininha: value
        ? !prev.modeloMaquininha || prev.modeloMaquininha === 'false'
          ? 'Stone'
          : prev.modeloMaquininha
        : 'false'
    }));
  };

  const setIntegracao = (value: IntegrationValue) => {
    setValue('tipoIntegracao', value);
  };

  const save = async () => {
    const next = toMobileAppSettings(settingMemo, empresa, appSettings);
    if (hasConflictingOpeningSettings(next)) {
      setStatus(OPENING_SETTINGS_CONFLICT_MESSAGE);
      Alert.alert('Aviso', OPENING_SETTINGS_CONFLICT_MESSAGE);
      return;
    }

    setSalvando(true);
    setStatus('Salvando configurações...');
    try {
      setBaseUrl(next.baseUrl);
      setEmpresaId(next.empresaId);
      await saveAppSettings(next);
      setStatus('Configurações salvas com sucesso.');
      openSavedAlert();
    } catch (error: any) {
      const message = error?.message || 'Não foi possível salvar. Tente novamente.';
      setStatus(message);
      Alert.alert('Aviso', message);
    } finally {
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

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <ScreenRouteLabel />
      <SectionHeader title="Configurações" subtitle="Todos os campos do formulário RPCheff.View.Configuracoes." />

      <Section title="Servidor e Login">
        <FieldInput
          label="Servidor (API)"
          value={settingMemo.servidor}
          onChangeText={(text) => setValue('servidor', text)}
          placeholder="http://192.168.x.x:9000/"
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
          onChangeText={setEmpresa}
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
  saveWrap: {
    borderRadius: 20,
    overflow: 'hidden',
    marginBottom: 24
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
  },
  disabledBtn: {
    opacity: 0.7
  }
});
