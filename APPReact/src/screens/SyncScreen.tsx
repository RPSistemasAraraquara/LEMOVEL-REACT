import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Alert, Animated, Easing, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useApp } from '../context/AppContext';
import { api, logSyncDiagnostic, quickConnectionCheckTimeoutMs } from '../services/api';
import type { SyncResult, SyncTaskResult } from '../services/api';
import { SectionHeader } from '../components/SectionHeader';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { Colors, Radius, Shadows, Space } from '../theme';
import { RootStackParams } from '../navigation/AppNavigator';

type SyncTask = {
  label: string;
  key: string;
  subtitle?: string;
};

const tasks: SyncTask[] = [
  { label: 'Catálogo', key: 'catalogo', subtitle: 'Atualiza categorias e produtos' },
  { label: 'Produtos', key: 'produtos', subtitle: 'Atualiza produtos e opcionais' },
  { label: 'Mesas', key: 'mesas', subtitle: 'Atualização específica' },
  { label: 'Formas de pagamento', key: 'formas', subtitle: 'Atualização específica' },
  { label: 'Configurações', key: 'configuracoes', subtitle: 'Atualização específica' },
  { label: 'Usuários', key: 'usuarios', subtitle: 'Atualização específica' }
];

const formatUnavailableMessage = (status?: number, message?: string) => {
  if (status && status > 0) {
    return `API indisponível (${status})`;
  }

  if (message && message.trim().length > 0) {
    return `API indisponível ou resposta interrompida (${message.trim()})`;
  }

  return 'API indisponível';
};

const extractErrorMessage = (error: unknown, fallback: string) => {
  if (error instanceof Error && error.message.trim().length > 0) {
    return error.message.trim();
  }

  if (typeof error === 'string' && error.trim().length > 0) {
    return error.trim();
  }

  if (error && typeof error === 'object' && 'message' in error) {
    const message = (error as { message?: unknown }).message;
    if (typeof message === 'string' && message.trim().length > 0) {
      return message.trim();
    }
  }

  return fallback;
};

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const formatDuration = (durationMs?: number) => {
  if (typeof durationMs !== 'number' || !Number.isFinite(durationMs) || durationMs < 0) {
    return '';
  }

  if (durationMs < 1000) {
    return `${durationMs}ms`;
  }

  return `${(durationMs / 1000).toFixed(1)}s`;
};

export const SyncScreen: React.FC = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParams, 'Sincronizar'>>();
  const {
    refreshMenu,
    refreshDashboard,
    refreshCurrentUserPermissions,
    appSettings,
    checkApiConnection,
    pauseAutoRefresh,
    resumeAutoRefresh
  } = useApp();
  const [busyOperation, setBusyOperation] = useState<'full' | 'single' | 'test' | null>(null);
  const [log, setLog] = useState<string[]>(['Pronto para sincronizar']);
  const progressAnim = useRef(new Animated.Value(0)).current;
  const isBusy = busyOperation !== null;

  const append = (text: string) => {
    logSyncDiagnostic(`ui ${text}`);
    setLog((prev) => [text, ...prev.slice(0, 31)]);
  };
  const progressTranslate = useMemo(
    () =>
      progressAnim.interpolate({
        inputRange: [0, 1],
        outputRange: [-220, 220]
      }),
    [progressAnim]
  );

  useEffect(() => {
    pauseAutoRefresh();
    return () => {
      resumeAutoRefresh();
    };
  }, [pauseAutoRefresh, resumeAutoRefresh]);

  useEffect(() => {
    if (!isBusy) {
      progressAnim.stopAnimation();
      progressAnim.setValue(0);
      return;
    }

    const loop = Animated.loop(
      Animated.timing(progressAnim, {
        toValue: 1,
        duration: 1100,
        easing: Easing.inOut(Easing.ease),
        useNativeDriver: true
      })
    );

    progressAnim.setValue(0);
    loop.start();

    return () => {
      loop.stop();
      progressAnim.stopAnimation();
      progressAnim.setValue(0);
    };
  }, [isBusy, progressAnim]);

  const runPostSyncRefresh = async (
    includePermissions = false,
    options: {
      preferCachedMenu?: boolean;
      preferCachedPermissions?: boolean;
      includeDashboard?: boolean;
      includeMenu?: boolean;
    } = {}
  ) => {
    const refreshTasks: Array<{ label: string; execute: () => Promise<unknown> }> = [
      ...(includePermissions
        ? [
            {
              label: 'Permissões do usuário',
              execute: () => refreshCurrentUserPermissions({ preferCache: options.preferCachedPermissions })
            }
          ]
        : []),
      ...(options.includeMenu === false
        ? []
        : [{ label: 'Cardápio', execute: () => refreshMenu({ preferCache: options.preferCachedMenu }) }]),
      ...(options.includeDashboard === false
        ? []
        : [{ label: 'Painel', execute: () => refreshDashboard(undefined, { force: true }) }])
    ];

    const executeRefreshTask = async (item: { label: string; execute: () => Promise<unknown> }) => {
      const startedAt = Date.now();
      try {
        const result = await item.execute();
        append(`Atualização ${item.label} em ${formatDuration(Date.now() - startedAt)}`);
        return result;
      } catch (error) {
        const message = extractErrorMessage(error, '');
        if (message.toLowerCase().includes('sincronização interrompida')) {
          await wait(250);
          const result = await item.execute();
          append(`Atualização ${item.label} em ${formatDuration(Date.now() - startedAt)}`);
          return result;
        }
        throw error;
      }
    };

    const settled = await Promise.allSettled(refreshTasks.map((item) => executeRefreshTask(item)));
    return settled.flatMap((result, index) => {
      if (result.status === 'fulfilled') {
        return [];
      }

      const reason = extractErrorMessage(result.reason, 'Falha ao atualizar a tela.');
      return [`${refreshTasks[index].label}: ${reason}`];
      });
  };

  const refreshMenuInBackground = (preferCache = true) => {
    const startedAt = Date.now();
    void refreshMenu({ preferCache })
      .then(() => {
        logSyncDiagnostic(`ui Atualização Cardápio em segundo plano em ${formatDuration(Date.now() - startedAt)}`);
      })
      .catch((error) => {
        logSyncDiagnostic(`ui Atualização Cardápio em segundo plano falhou: ${extractErrorMessage(error, 'falha')}`, 2);
      });
  };

  const refreshDashboardInBackground = () => {
    const startedAt = Date.now();
    void refreshDashboard(undefined, { force: true })
      .then(() => {
        logSyncDiagnostic(`ui Atualização Painel em segundo plano em ${formatDuration(Date.now() - startedAt)}`);
      })
      .catch((error) => {
        logSyncDiagnostic(`ui Atualização Painel em segundo plano falhou: ${extractErrorMessage(error, 'falha')}`, 2);
      });
  };

  const formatTaskLogLine = (item: SyncTaskResult) => {
    const marker = item.status === 'ok' ? '✓' : item.status === 'skip' ? '•' : '✗';
    const duration = formatDuration(item.durationMs);
    return `${marker} ${item.key}${duration ? ` (${duration})` : ''}: ${item.message}`;
  };

  const getSyncTaskIssues = (items?: SyncTaskResult[]) =>
    (items || []).filter((item) => item.status !== 'ok').map((item) => `${item.key}: ${item.message}`);

  const appendSyncSummary = (result: SyncResult) => {
    append(`Sincronização concluída em ${result.timestamp || 'agora'} | status: ${result.status}`);

    if (!result.details?.length && result.summary?.length) {
      result.summary.forEach((item) => append(item));
    }
  };

  const executeFull = async () => {
    if (isBusy) {
      return;
    }

    setBusyOperation('full');
    try {
      append(`Verificando disponibilidade da API: ${appSettings.baseUrl}`);
      const connection = await checkApiConnection(quickConnectionCheckTimeoutMs);
      if (!connection.ok) {
        const unavailableMessage = formatUnavailableMessage(connection.status, connection.message);
        append(`Sincronização bloqueada: ${unavailableMessage}`);
        Alert.alert('Atenção', unavailableMessage);
        return;
      }

      append('Iniciando sincronização completa...');
      if (api.isSyncAllRunning()) {
        append('Já existe uma sincronização completa em andamento. Aguardando a execução atual terminar...');
      }
      const result = await api.syncAll({
        onTaskStart: (task) => append(`Sincronizando etapa: ${task}`),
        onTaskFinish: (taskResult) => append(formatTaskLogLine(taskResult))
      });
      const refreshIssues = await runPostSyncRefresh(true, {
        preferCachedMenu: true,
        preferCachedPermissions: true,
        includeDashboard: false,
        includeMenu: false
      });
      refreshMenuInBackground(true);
      refreshDashboardInBackground();
      appendSyncSummary(result);
      const syncIssues = getSyncTaskIssues(result.details);
      syncIssues.forEach((item) => append(`Pendência de sincronização: ${item}`));
      refreshIssues.forEach((item) => append(`Atualização pendente: ${item}`));

      if (syncIssues.length === 0 && refreshIssues.length === 0) {
        Alert.alert('Concluído', 'Sincronização completa concluída.');
        navigation.reset({
          index: 0,
          routes: [{ name: 'Inicial' }]
        });
        return;
      }

      const issuePreview = [...syncIssues, ...refreshIssues.map((item) => `Atualização: ${item}`)]
        .slice(0, 3)
        .join('\n');
      Alert.alert(
        'Atenção',
        issuePreview
          ? `Sincronização concluída com pendências:\n${issuePreview}`
          : 'Sincronização concluída com pendências. Consulte o log.'
      );
    } catch (error: any) {
      const message = extractErrorMessage(error, 'Não foi possível sincronizar.');
      append(`Falha: ${message}`);
      Alert.alert('Erro', message);
    } finally {
      setBusyOperation(null);
    }
  };

  const executeSingle = async (key: string) => {
    if (isBusy) {
      return;
    }

    setBusyOperation('single');
    try {
      append(`Verificando disponibilidade da API: ${appSettings.baseUrl}`);
      const connection = await checkApiConnection(quickConnectionCheckTimeoutMs);
      if (!connection.ok) {
        const unavailableMessage = formatUnavailableMessage(connection.status, connection.message);
        append(`Sincronização bloqueada: ${unavailableMessage}`);
        Alert.alert('Atenção', unavailableMessage);
        return;
      }

      append(`Sincronizando ${key}...`);
      const result = await api.syncPartial(key);
      if (result.status === 'error') {
        append(`✗ ${key} falhou: ${result.message}`);
        Alert.alert('Atenção', result.message);
        return;
      }

      const normalizedKey = String(key).toLowerCase();
      const shouldPreferCachedMenu =
        normalizedKey === 'catalogo' ||
        normalizedKey === 'produtos' ||
        normalizedKey === 'produto' ||
        normalizedKey === 'categorias' ||
        normalizedKey === 'categoria';
      const refreshIssues = await runPostSyncRefresh(normalizedKey === 'usuarios', {
        preferCachedMenu: shouldPreferCachedMenu,
        preferCachedPermissions: normalizedKey === 'usuarios'
      });
      const marker = result.status === 'skip' ? '•' : '✓';
      append(`${marker} ${result.message}`);
      refreshIssues.forEach((item) => append(`Atualização pendente: ${item}`));

      if (refreshIssues.length > 0) {
        Alert.alert('Atenção', `${result.message} Houve pendências ao atualizar a tela. Consulte o log.`);
        return;
      }

      const title = result.status === 'skip' ? 'Atenção' : 'Concluído';
      Alert.alert(title, result.message);
    } catch (error: any) {
      const message = extractErrorMessage(error, `${key} não sincronizou`);
      append(`✗ ${key} falhou: ${message}`);
      Alert.alert('Erro', message);
    } finally {
      setBusyOperation(null);
    }
  };

  const testConnection = async () => {
    if (isBusy) {
      return;
    }

    setBusyOperation('test');
    append(`Testando API: ${appSettings.baseUrl}`);
    try {
      const test = await api.testApiConnection({ timeoutMs: quickConnectionCheckTimeoutMs });
      append(`Teste finalizado: ${test.ok ? 'Conectado' : 'Sem resposta OK'} (status ${test.status} / ${test.payloadType})`);
      if (!test.ok) {
        append(`Detalhe da resposta: ${test.message}`);
      }
      Alert.alert('Teste de conexão', test.ok ? `API alcançada com sucesso (${test.status}).` : `Falha (status ${test.status}): ${test.message}`);
    } catch (error: any) {
      const message = extractErrorMessage(error, 'Erro desconhecido');
      append(`Teste falhou: ${message}`);
      Alert.alert('Teste de conexão', `Falha: ${message}`);
    } finally {
      setBusyOperation(null);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <ScreenRouteLabel />
      <SectionHeader title="Sincronização" subtitle="Atualiza dados entre API Horse e aplicativo." />

      <Pressable
        onPress={executeFull}
        disabled={isBusy}
        style={[styles.primary, isBusy ? styles.disabled : null]}
      >
        <Text style={styles.primaryText}>{isBusy ? 'Processando...' : 'Sincronizar tudo'}</Text>
      </Pressable>

      {isBusy ? (
        <View style={styles.progressWrap}>
          <View style={styles.progressTrack}>
            <Animated.View
              style={[
                styles.progressBar,
                {
                  transform: [{ translateX: progressTranslate }]
                }
              ]}
            />
          </View>
          <Text style={styles.progressText}>
            {busyOperation === 'test' ? 'Verificando conectividade com a API...' : 'Sincronizando dados do aplicativo...'}
          </Text>
        </View>
      ) : null}

      <Pressable onPress={testConnection} disabled={isBusy} style={[styles.primary, styles.testButton, isBusy ? styles.disabled : null]}>
        <Text style={styles.primaryText}>Testar conexão da API</Text>
      </Pressable>

      <View style={styles.grid}>
        {tasks.map((task) => (
          <Pressable
            key={task.key}
            style={[styles.card, isBusy ? styles.disabled : null]}
            onPress={() => executeSingle(task.key)}
            disabled={isBusy}
          >
            <View style={styles.cardBody}>
              <Text style={styles.cardTitle}>{task.label}</Text>
              <Text style={styles.cardSub}>{task.subtitle || 'Atualização específica'}</Text>
            </View>
          </Pressable>
        ))}
      </View>

      <View style={styles.logWrap}>
        <Text style={styles.logTitle}>Log de operação</Text>
        {log.map((line, index) => (
          <Text key={`${line}-${index}`} style={styles.logLine}>
            • {line}
          </Text>
        ))}
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
    paddingBottom: 120
  },
  primary: {
    borderRadius: 20,
    backgroundColor: Colors.primary,
    padding: 15,
    alignItems: 'center',
    marginBottom: Space.md,
    ...Shadows.button
  },
  disabled: {
    opacity: 0.7
  },
  primaryText: {
    color: '#fff',
    fontWeight: '700'
  },
  testButton: {
    backgroundColor: Colors.primary,
    marginBottom: Space.md
  },
  progressWrap: {
    marginTop: -4,
    marginBottom: Space.md,
    paddingHorizontal: 4
  },
  progressTrack: {
    height: 8,
    borderRadius: 999,
    backgroundColor: Colors.primarySoft,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Colors.border
  },
  progressBar: {
    width: 140,
    height: '100%',
    borderRadius: 999,
    backgroundColor: Colors.primary
  },
  progressText: {
    marginTop: 8,
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700'
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: Space.md
  },
  card: {
    flexGrow: 1,
    minWidth: '48%',
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    borderRadius: 22,
    padding: 14,
    minHeight: 84,
    ...Shadows.card
  },
  cardBody: {
    minHeight: 54,
    justifyContent: 'space-between'
  },
  cardTitle: {
    color: Colors.text,
    fontWeight: '700',
    lineHeight: 24,
    minHeight: 24
  },
  cardSub: {
    color: Colors.textMuted,
    fontSize: 12,
    lineHeight: 18,
    minHeight: 18
  },
  logWrap: {
    backgroundColor: Colors.card,
    borderColor: Colors.border,
    borderWidth: 1,
    borderRadius: 24,
    padding: Space.md,
    ...Shadows.card
  },
  logTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 10
  },
  logLine: {
    color: Colors.textMuted,
    marginBottom: 4,
    lineHeight: 18,
    fontSize: 12
  }
});
