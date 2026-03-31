import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Image,
  KeyboardAvoidingView,
  Platform,
  Pressable,
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
      await login(user.trim(), senha.trim());
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
      <View style={styles.card}>
        <Image source={require('../../assets/Logo.png')} style={styles.logo} resizeMode="contain" />
        <Text style={styles.title}>RP CHEFF</Text>

        <Text style={styles.label}>Usuário</Text>
        <TextInput
          placeholder="Login"
          value={user}
          onChangeText={setUser}
          autoCapitalize="none"
          style={styles.input}
          placeholderTextColor={Colors.textMuted}
        />
        <Text style={styles.label}>Senha</Text>
        <TextInput
          placeholder="Senha"
          value={senha}
          secureTextEntry
          onChangeText={setSenha}
          style={styles.input}
          placeholderTextColor={Colors.textMuted}
        />

        {!!error && <Text style={styles.error}>{error}</Text>}
        {companyInfo?.utilizaRPMovel === false ? (
          <Text style={styles.error}>Módulo RPMOVEL não ativo.</Text>
        ) : null}
        <Text style={styles.connection}>
          {apiConnection.checking
            ? 'Verificando conexão com API...'
            : apiConnection.ok
            ? `API: conectado (${apiConnection.status || '-'})`
            : `API: sem conexão (${apiConnection.status || '-'}): ${apiConnection.message}`}
        </Text>

        <Pressable onPress={onSubmit} style={styles.button} disabled={loading}>
          {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonLabel}>Entrar</Text>}
        </Pressable>

        <Pressable onPress={goConfig} style={styles.configButton} disabled={loading}>
          <Text style={styles.configButtonLabel}>Configuração</Text>
        </Pressable>

        <Text style={styles.versionLabel}>Versão 8.0.0.1</Text>
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background, justifyContent: 'center', padding: Space.xl },
  card: {
    backgroundColor: Colors.card,
    borderRadius: Radius.xl,
    padding: Space.xl,
    borderColor: Colors.border,
    borderWidth: 1,
    shadowColor: Colors.shadow,
    shadowOpacity: 0.1,
    shadowRadius: 16,
    elevation: 5
  },
  logo: {
    width: 82,
    height: 82,
    alignSelf: 'center',
    marginBottom: 14
  },
  title: { fontSize: 28, color: Colors.text, fontWeight: '800', marginBottom: 8, alignSelf: 'center' },
  label: {
    color: Colors.text,
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 6,
    marginLeft: 2
  },
  input: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    padding: 12,
    marginBottom: Space.sm,
    backgroundColor: Colors.cardSoft,
    color: Colors.text
  },
  button: {
    marginTop: 6,
    borderRadius: Radius.md,
    backgroundColor: Colors.primary,
    paddingVertical: 14,
    alignItems: 'center'
  },
  configButton: {
    marginTop: 10,
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySoft,
    paddingVertical: 12,
    alignItems: 'center'
  },
  buttonLabel: { color: '#fff', fontWeight: '700', fontSize: 16 },
  configButtonLabel: { color: Colors.primary, fontWeight: '700', fontSize: 14 },
  versionLabel: {
    marginTop: 10,
    color: Colors.textMuted,
    fontSize: 12,
    textAlign: 'center'
  },
  error: { color: Colors.danger, marginBottom: 6, marginTop: -2 },
  connection: {
    color: Colors.textMuted,
    fontSize: 12,
    marginBottom: 10,
    marginTop: 2
  }
});
