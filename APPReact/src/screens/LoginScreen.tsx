import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Image,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useApp } from '../context/AppContext';
import { RootStackParams } from '../navigation/AppNavigator';
import { Colors, Radius, Space } from '../theme';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { api, applyCompanyPolicyToSettings, CompanyInfo } from '../services/api';

export const LoginScreen: React.FC = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParams, 'Login'>>();
  const { appSettings, login, loading, apiConnection, checkApiConnection, saveAppSettings, user: loggedUser } = useApp();
  const [user, setUser] = useState(appSettings.usuario || '1');
  const [senha, setSenha] = useState(appSettings.senha || '1');
  const [error, setError] = useState('');
  const [companyInfo, setCompanyInfo] = useState<CompanyInfo | null>(null);

  useEffect(() => {
    setUser(appSettings.usuario || '1');
    setSenha(appSettings.senha || '1');
  }, [appSettings.usuario, appSettings.senha]);

  useEffect(() => {
    setError('');
  }, [appSettings.baseUrl, appSettings.empresaId]);

  useEffect(() => {
    let active = true;

    const loadCompanyInfo = async () => {
      try {
        const company = await api.getCompanyInfo();
        if (!active) {
          return;
        }
        setCompanyInfo(company);

        const normalizedSettings = applyCompanyPolicyToSettings(appSettings, company);
        if (
          normalizedSettings.tipoIntegracao !== appSettings.tipoIntegracao ||
          normalizedSettings.utilizaMaquininhaStone !== appSettings.utilizaMaquininhaStone
        ) {
          await saveAppSettings(normalizedSettings);
        }
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
  }, [appSettings, saveAppSettings]);

  useEffect(() => {
    if (loggedUser) {
      navigation.reset({
        index: 0,
        routes: [{ name: 'Inicial' }]
      });
    }
  }, [loggedUser, navigation]);

  const onSubmit = async () => {
    setError('');
    const normalizedUser = user.trim();
    const normalizedPassword = senha.trim();

    if (!normalizedUser || !normalizedPassword) {
      setError('Informe usuário e senha.');
      return;
    }

    try {
      const connection = await checkApiConnection();
      if (!connection.ok && connection.status === 401) {
        setError('Autenticação da API indisponível (401). Verifique as credenciais do servidor.');
        return;
      }
      if (!connection.ok) {
        setError('API sem conexão. Corrija o Servidor nas configurações.');
        return;
      }
      const currentCompanyInfo = companyInfo ?? (await api.getCompanyInfo().catch(() => null));
      if (currentCompanyInfo && currentCompanyInfo.utilizaRPMovel === false) {
        setCompanyInfo(currentCompanyInfo);
        setError('Módulo RPMOVEL não ativo.');
        return;
      }
      await login(normalizedUser, normalizedPassword);
    } catch (e: any) {
      if (e?.message) {
        setError(String(e.message));
        return;
      }
      setError('Não foi possível entrar. Verifique API / usuário / senha.');
    }
  };

  const goConfig = () => {
    navigation.navigate('Configuracoes');
  };

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScreenRouteLabel />
      <View pointerEvents="none" style={styles.backgroundGlowTop} />
      <View pointerEvents="none" style={styles.backgroundGlowMiddle} />
      <View pointerEvents="none" style={styles.backgroundGlowBottom} />
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.heroCard}>
          <View style={styles.heroBadge}>
            <Text style={styles.heroBadgeText}>Acesso RP MOVEL</Text>
          </View>
          <Image source={require('../../assets/Logo.png')} style={styles.logo} resizeMode="contain" />
          <Text style={styles.title}>RP MOVEL</Text>
          <Text style={styles.versionLabel}>Versão 18.0.3</Text>
        </View>

        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardEyebrow}>Login do operador</Text>
          </View>

          <View style={styles.fieldGroup}>
            <Text style={styles.label}>Usuário</Text>
            <View style={styles.inputShell}>
              <TextInput
                placeholder="Digite seu login"
                value={user}
                onChangeText={setUser}
                autoCapitalize="none"
                style={styles.input}
                placeholderTextColor={Colors.textMuted}
              />
            </View>
          </View>

          <View style={styles.fieldGroup}>
            <Text style={styles.label}>Senha</Text>
            <View style={styles.inputShell}>
              <TextInput
                placeholder="Digite sua senha"
                value={senha}
                secureTextEntry
                onChangeText={setSenha}
                style={styles.input}
                placeholderTextColor={Colors.textMuted}
              />
            </View>
          </View>

          {!!error && <Text style={styles.error}>{error}</Text>}
          {companyInfo?.utilizaRPMovel === false ? (
            <Text style={styles.error}>Módulo RPMOVEL não ativo.</Text>
          ) : null}

          <View style={[styles.connectionCard, apiConnection.ok ? styles.connectionCardOk : styles.connectionCardOffline]}>
            <Text style={styles.connectionEyebrow}>Status da API</Text>
            <Text style={styles.connection}>
              {apiConnection.checking
                ? 'Verificando conexão com API...'
                : apiConnection.ok
                ? `Conectado (${apiConnection.status || '-'})`
                : `Sem conexão (${apiConnection.status || '-'}): ${apiConnection.message}`}
            </Text>
          </View>

          <Pressable onPress={onSubmit} style={styles.button} disabled={loading}>
            {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonLabel}>Entrar no sistema</Text>}
          </Pressable>

          <Pressable onPress={goConfig} style={styles.configButton} disabled={loading}>
            <Text style={styles.configButtonLabel}>Configurar servidor</Text>
          </Pressable>

        </View>
      </ScrollView>
      <Text style={styles.footer}>www.sistemalechef.com.br</Text>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
    paddingHorizontal: Space.xl,
    paddingTop: Space.xl,
    paddingBottom: Space.lg
  },
  backgroundGlowTop: {
    position: 'absolute',
    top: -90,
    right: -40,
    width: 220,
    height: 220,
    borderRadius: 110,
    backgroundColor: 'rgba(242, 153, 74, 0.08)'
  },
  backgroundGlowMiddle: {
    position: 'absolute',
    top: 180,
    left: -60,
    width: 180,
    height: 180,
    borderRadius: 90,
    backgroundColor: 'rgba(46, 134, 193, 0.06)'
  },
  backgroundGlowBottom: {
    position: 'absolute',
    bottom: 40,
    right: -30,
    width: 160,
    height: 160,
    borderRadius: 80,
    backgroundColor: 'rgba(27, 79, 114, 0.04)'
  },
  scroll: {
    flex: 1
  },
  content: {
    flexGrow: 1,
    justifyContent: 'center',
    gap: Space.md,
    paddingVertical: Space.md
  },
  heroCard: {
    borderRadius: Radius.xl,
    paddingHorizontal: Space.lg,
    paddingVertical: Space.md,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    shadowColor: '#684327',
    shadowOpacity: 0.04,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2
  },
  heroBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: Radius.sm,
    backgroundColor: 'rgba(242, 153, 74, 0.14)',
    marginBottom: 10
  },
  heroBadgeText: {
    color: '#d46c15',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0,
    textTransform: 'uppercase'
  },
  card: {
    backgroundColor: 'rgba(255,255,255,0.98)',
    borderRadius: Radius.xl,
    padding: Space.lg,
    borderColor: 'rgba(217, 228, 239, 0.96)',
    borderWidth: 1,
    shadowColor: '#0f172a',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2
  },
  cardHeader: {
    marginBottom: Space.lg
  },
  cardEyebrow: {
    color: '#1b4f72',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0,
    textTransform: 'uppercase',
    marginBottom: 0
  },
  logo: {
    width: 70,
    height: 70,
    alignSelf: 'center',
    marginBottom: 10
  },
  title: {
    fontSize: 26,
    color: '#23314d',
    fontWeight: '900',
    alignSelf: 'center'
  },
  fieldGroup: {
    marginBottom: Space.md
  },
  label: {
    color: '#23314d',
    fontSize: 12,
    fontWeight: '800',
    marginBottom: 6,
    marginLeft: 2
  },
  inputShell: {
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.12)',
    borderRadius: Radius.lg,
    backgroundColor: '#f8fbff',
    paddingHorizontal: 4
  },
  input: {
    borderRadius: Radius.md,
    paddingHorizontal: 12,
    paddingVertical: 14,
    color: Colors.text
  },
  connectionCard: {
    borderWidth: 1,
    borderRadius: Radius.lg,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 12
  },
  connectionCardOk: {
    borderColor: 'rgba(22, 163, 74, 0.16)',
    backgroundColor: '#f1fbf4'
  },
  connectionCardOffline: {
    borderColor: 'rgba(249, 115, 22, 0.18)',
    backgroundColor: '#fff7ef'
  },
  connectionEyebrow: {
    color: '#1b4f72',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0,
    textTransform: 'uppercase',
    marginBottom: 4
  },
  button: {
    marginTop: 4,
    borderRadius: Radius.lg,
    backgroundColor: '#1b4f72',
    paddingVertical: 16,
    alignItems: 'center',
    shadowColor: '#1b4f72',
    shadowOpacity: 0.2,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 10 },
    elevation: 4
  },
  configButton: {
    marginTop: 10,
    borderRadius: Radius.lg,
    borderWidth: 1,
    borderColor: 'rgba(27, 79, 114, 0.14)',
    backgroundColor: '#f6f9fc',
    paddingVertical: 14,
    alignItems: 'center'
  },
  buttonLabel: { color: '#fff', fontWeight: '800', fontSize: 16 },
  configButtonLabel: { color: '#1b4f72', fontWeight: '800', fontSize: 14 },
  versionLabel: {
    marginTop: 14,
    color: Colors.textMuted,
    fontSize: 12,
    textAlign: 'center'
  },
  footer: {
    color: Colors.textMuted,
    fontSize: 12,
    textAlign: 'center',
    marginTop: Space.md
  },
  error: { color: Colors.danger, marginBottom: 6, marginTop: -2 },
  connection: {
    color: Colors.textMuted,
    fontSize: 12,
    lineHeight: 18
  }
});
