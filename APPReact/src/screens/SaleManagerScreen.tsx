import React, { useEffect, useMemo, useState } from 'react';
import { Alert, FlatList, Image, Pressable, RefreshControl, StyleSheet, Text, TextInput, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { SweetAlert, SweetAlertType } from '../components/SweetAlert';
import { useApp } from '../context/AppContext';
import { api, getProductImageSource, normalizeSaleStatus, resolveImageUri, Sale, SaleLine } from '../services/api';
import { Colors, Radius, Space, Typography } from '../theme';
import { RootStackParams } from '../navigation/AppNavigator';
import { ScreenRouteLabel } from '../components/ScreenRouteLabel';
import { SafeMaterialCommunityIcons } from '../components/SafeExpoIcons';

type StackNav = NativeStackNavigationProp<RootStackParams>;
type VisibleItemGroup = {
  key: string;
  lines: SaleLine[];
  primaryLine: SaleLine;
  isFractionGroup: boolean;
  total: number;
};

const toNumber = (value: string): number => {
  const parsed = Number(value.replace(',', '.'));
  return Number.isFinite(parsed) ? parsed : 0;
};

const adjustCounterValue = (
  value: string,
  setter: React.Dispatch<React.SetStateAction<string>>,
  delta: number
) => {
  const next = Math.max(0, Math.trunc(toNumber(value) + delta));
  setter(String(next));
};

const formatSaleStatus = (value: unknown): string => {
  const status = normalizeSaleStatus(value);
  if (!status) return 'Sem dados';
  if (status.includes('prefechamento')) return 'Pré-fechamento';
  if (status.includes('pendente')) return 'Pendente';
  if (status.includes('digitacao')) return 'Digitação';
  if (status.includes('finalizada')) return 'Finalizada';
  if (status.includes('cancelada')) return 'Cancelada';
  if (status.includes('reservada')) return 'Reservada';
  if (status.includes('aguardando')) return 'Aguardando';
  return String(value || status);
};

const getLineSizeLabel = (line: SaleLine): string | null => {
  if (!line.vendaPorTamanho) {
    return null;
  }

  const sizeLabel = String(line.descricaoTamanho || line.tamanho || '').trim();
  if (!sizeLabel || sizeLabel.toUpperCase() === 'U') {
    return null;
  }

  return sizeLabel;
};

const formatLineLaunchDateTime = (value?: string): string | null => {
  const raw = String(value || '').trim();
  if (!raw) {
    return null;
  }

  const normalized = raw.includes('T') ? raw : raw.replace(' ', 'T');
  const parsed = new Date(normalized);
  if (Number.isNaN(parsed.getTime())) {
    return raw;
  }

  const day = String(parsed.getDate()).padStart(2, '0');
  const month = String(parsed.getMonth() + 1).padStart(2, '0');
  const year = parsed.getFullYear();
  const hours = String(parsed.getHours()).padStart(2, '0');
  const minutes = String(parsed.getMinutes()).padStart(2, '0');

  return `${day}/${month}/${year} ${hours}:${minutes}`;
};

const resolveSafeImageUri = (value?: string): string | undefined => {
  const raw = String(value || '').trim();
  if (!raw) {
    return undefined;
  }

  const dataUriPrefixMatch = raw.match(/^data:image\/[^;]+;base64,/i);
  if (dataUriPrefixMatch) {
    const payload = raw.slice(dataUriPrefixMatch[0].length).replace(/\s+/g, '');
    if (!payload) {
      return undefined;
    }

    return `${dataUriPrefixMatch[0]}${payload}`;
  }

  if (/^(https?:\/\/|file:\/\/|content:\/\/)/i.test(raw)) {
    return raw;
  }

  return resolveImageUri(raw.replace(/\s+/g, ''));
};

const getGroupLaunchDateTime = (lines: SaleLine[]): string | null => {
  for (const line of lines) {
    const formatted = formatLineLaunchDateTime(line.dataHora);
    if (formatted) {
      return formatted;
    }
  }

  return null;
};

const toItemNumber = (value: unknown): number => {
  const parsed = Number(value || 0);
  return Number.isFinite(parsed) ? parsed : 0;
};

const getFractionGroupItemNumbers = (targetLine: SaleLine, items: SaleLine[]): number[] => {
  const visited = new Set<number>();
  const queue = [toItemNumber(targetLine.numeroItem), toItemNumber(targetLine.itemFracionado)];

  while (queue.length > 0) {
    const current = queue.shift() || 0;
    if (!current || visited.has(current)) {
      continue;
    }

    visited.add(current);

    items.forEach((item) => {
      const itemNumber = toItemNumber(item.numeroItem);
      const parentNumber = toItemNumber(item.itemFracionado);

      if (itemNumber === current || parentNumber === current) {
        if (itemNumber > 0 && !visited.has(itemNumber)) {
          queue.push(itemNumber);
        }
        if (parentNumber > 0 && !visited.has(parentNumber)) {
          queue.push(parentNumber);
        }
      }
    });
  }

  if (visited.size === 0) {
    const currentItemNumber = toItemNumber(targetLine.numeroItem);
    if (currentItemNumber > 0) {
      visited.add(currentItemNumber);
    }
  }

  return Array.from(visited).sort((a, b) => a - b);
};

const getFractionRootItemNumber = (targetLine: SaleLine, items: SaleLine[]): number => {
  const groupNumbers = getFractionGroupItemNumbers(targetLine, items);
  const groupSet = new Set(groupNumbers);
  const groupItems = items.filter((item) => groupSet.has(toItemNumber(item.numeroItem)));

  const selfParentItem = groupItems.find((item) => {
    const itemNumber = toItemNumber(item.numeroItem);
    return itemNumber > 0 && toItemNumber(item.itemFracionado) === itemNumber;
  });
  if (selfParentItem) {
    return toItemNumber(selfParentItem.numeroItem);
  }

  const rootCandidate = groupItems.find((item) => {
    const parentNumber = toItemNumber(item.itemFracionado);
    return parentNumber === 0 || !groupSet.has(parentNumber);
  });
  if (rootCandidate) {
    return toItemNumber(rootCandidate.numeroItem);
  }

  return groupNumbers[0] || toItemNumber(targetLine.numeroItem);
};

const FRACTION_OBSERVATION_PATTERN = /^Fracionado\s+\d+(?:[.,]\d+)?\s+de\s+(.+)$/i;

const getFractionObservationDescriptor = (value?: string): string | null => {
  const raw = String(value || '').trim();
  if (!raw) {
    return null;
  }

  const match = raw.match(FRACTION_OBSERVATION_PATTERN);
  if (!match?.[1]) {
    return null;
  }

  return match[1].trim().toUpperCase();
};

const getVisibleLineObservation = (line: SaleLine): string | null => {
  const raw = String(line.observacao || '').trim();
  if (!raw) {
    return null;
  }

  if (getFractionObservationDescriptor(raw)) {
    return null;
  }

  return raw;
};

const getFractionFallbackGroupKey = (line: SaleLine): string | null => {
  const descriptor = getFractionObservationDescriptor(line.observacao);
  if (!descriptor) {
    return null;
  }

  const launchKey = String(line.dataHora || '').trim();
  const waiterKey = String(line.idGarcom || line.nomeGarcom || '').trim();
  const sizeKey = String(line.descricaoTamanho || line.tamanho || '').trim();
  const linkedTableKey = String(line.idMesaVinculada || '').trim();

  return [descriptor, launchKey, waiterKey, sizeKey, linkedTableKey].join('|');
};

const getFractionGroupLines = (targetLine: SaleLine, items: SaleLine[]): SaleLine[] => {
  const explicitNumbers = getFractionGroupItemNumbers(targetLine, items);
  const explicitSet = new Set(explicitNumbers);
  const explicitLines = items.filter((item) => explicitSet.has(toItemNumber(item.numeroItem)));
  if (explicitLines.length > 1) {
    return explicitLines;
  }

  const fallbackKey = getFractionFallbackGroupKey(targetLine);
  if (!fallbackKey) {
    return explicitLines.length ? explicitLines : [targetLine];
  }

  const fallbackLines = items.filter((item) => getFractionFallbackGroupKey(item) === fallbackKey);
  if (fallbackLines.length > 1) {
    return fallbackLines;
  }

  return explicitLines.length ? explicitLines : [targetLine];
};

const getFractionPrimaryLine = (targetLine: SaleLine, lines: SaleLine[]): SaleLine => {
  const explicitNumbers = lines
    .map((item) => toItemNumber(item.numeroItem))
    .filter((itemNumber) => itemNumber > 0);
  const explicitSet = new Set(explicitNumbers);

  const selfParentItem = lines.find((item) => {
    const itemNumber = toItemNumber(item.numeroItem);
    return itemNumber > 0 && toItemNumber(item.itemFracionado) === itemNumber;
  });
  if (selfParentItem) {
    return selfParentItem;
  }

  const rootCandidate = lines.find((item) => {
    const parentNumber = toItemNumber(item.itemFracionado);
    return parentNumber === 0 || !explicitSet.has(parentNumber);
  });
  if (rootCandidate) {
    return rootCandidate;
  }

  return lines[0] || targetLine;
};

export const SaleManagerScreen: React.FC = () => {
  const navigation = useNavigation<StackNav>();
  const { activeTable, user, refreshDashboard, getLinkedTableId, products, appSettings } = useApp();
  const [sale, setSale] = useState<Sale | null>(null);
  const [saleUsers, setSaleUsers] = useState<Record<number, string>>({});
  const [loading, setLoading] = useState(false);
  const [savingCouvert, setSavingCouvert] = useState(false);
  const [sending, setSending] = useState(false);
  const [couvertMasc, setCouvertMasc] = useState('0');
  const [couvertFem, setCouvertFem] = useState('0');
  const [personCount, setPersonCount] = useState('0');
  const [sweetAlert, setSweetAlert] = useState<{
    visible: boolean;
    title: string;
    message: string;
    type: SweetAlertType;
  }>({
    visible: false,
    title: '',
    message: '',
    type: 'warning'
  });

  const productImageUriById = useMemo(() => {
    const map = new Map<number, string>();
    products.forEach((product) => {
      const id = Number(product.idProduto || product.id || 0);
      const imageUri =
        resolveSafeImageUri(product.imagem_db) ||
        resolveSafeImageUri(product.imagemLocalPath || product.imagem);
      if (id > 0 && imageUri) {
        map.set(id, imageUri);
      }
    });
    return map;
  }, [products]);

  const productHasImageById = useMemo(() => {
    const map = new Map<number, boolean>();
    products.forEach((product) => {
      const id = Number(product.idProduto || product.id || 0);
      if (id > 0) {
        map.set(
          id,
          Boolean(
            resolveSafeImageUri(product.imagem_db) ||
            resolveSafeImageUri(product.imagemLocalPath || product.imagem)
          ) ||
            product.possuiImagem !== false
        );
      }
    });
    return map;
  }, [products]);

  useEffect(() => {
    let mounted = true;

    api.listUsers()
      .then((users) => {
        if (!mounted) {
          return;
        }

        const nextUsers = users.reduce<Record<number, string>>((acc, item) => {
          const id = Number(item.idUsuario || 0);
          const name = String(item.nome || '').trim();
          if (id > 0 && name) {
            acc[id] = name;
          }
          return acc;
        }, {});

        setSaleUsers(nextUsers);
      })
      .catch(() => {
        if (mounted) {
          setSaleUsers({});
        }
      });

    return () => {
      mounted = false;
    };
  }, []);

  const resolveLineImageSource = (line: SaleLine) => {
    if (!appSettings.exibirImagem) {
      return undefined;
    }

    const cachedProductImageUri = productImageUriById.get(line.idProduto);
    if (cachedProductImageUri) {
      return { uri: cachedProductImageUri };
    }

    const inlineImageUri = resolveSafeImageUri(line.imagem);
    if (inlineImageUri) {
      return { uri: inlineImageUri };
    }

    if (!productHasImageById.get(line.idProduto)) {
      return undefined;
    }

    return getProductImageSource(appSettings.baseUrl, appSettings.empresaId, line.idProduto);
  };

  const idVenda = activeTable?.idVenda;
  const activeTableCode = getLinkedTableId(activeTable);

  const showSweetAlert = (title: string, message: string, type: SweetAlertType = 'warning') => {
    setSweetAlert({
      visible: true,
      title,
      message,
      type
    });
  };

  const showPermissionDenied = (message: string) => {
    showSweetAlert('Atenção', message, 'warning');
  };

  const loadSale = async () => {
    if (!idVenda) {
      setSale(null);
      return;
    }
    setLoading(true);
    try {
      const data = await api.getSale(idVenda, true);
      if (!data) {
        setSale(null);
        return;
      }
      setSale(data);
      setCouvertMasc(String(data.numeroCouvertMasculino || 0));
      setCouvertFem(String(data.numeroCouvertFeminino || 0));
      setPersonCount(String(data.numeroPessoas || 0));
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível carregar a venda.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSale();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [idVenda]);

  const onSaveCouvert = async () => {
    if (!idVenda) return;
    setSavingCouvert(true);
    try {
      await api.updateCouvert(idVenda, {
        numeroPessoas: toNumber(personCount),
        numeroCouvertMasculino: toNumber(couvertMasc),
        numeroCouvertFeminino: toNumber(couvertFem)
      });
      await loadSale();
      Alert.alert('Concluído', 'Dados de couvert atualizados.');
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível salvar.');
    } finally {
      setSavingCouvert(false);
    }
  };

  const onReopenSale = async () => {
    if (!idVenda) return;
    if (!user?.permiteReabrirMesaComanda) {
      showPermissionDenied('Sem permissão para reabrir mesa.');
      return;
    }
    const currentStatus = normalizeSaleStatus(
      sale?.situacao || activeTable?.venda?.situacao || activeTable?.statusCode || activeTable?.statusOriginal || activeTable?.situacao || ''
    );
    if (!currentStatus.includes('prefechamento')) {
      Alert.alert('Atenção', 'A venda só pode ser reaberta quando estiver em pré-fechamento.');
      return;
    }
    setSending(true);
    try {
      await api.reopenSale(idVenda);
      setSale((prev) => (prev ? { ...prev, situacao: 'svPendente' } : prev));
      await Promise.all([loadSale(), refreshDashboard()]);
      Alert.alert('Concluído', 'Venda reaberta com sucesso.');
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Não foi possível reabrir.');
    } finally {
      setSending(false);
    }
  };

  const onCancelLine = (line: SaleLine) => {
    if (!idVenda) return;
    if (!user?.permiteCancelarItemMobile) {
      showPermissionDenied('Sem permissão para cancelar produto.');
      return;
    }
    const currentStatus = normalizeSaleStatus(
      sale?.situacao || activeTable?.venda?.situacao || activeTable?.statusCode || activeTable?.statusOriginal || activeTable?.situacao || ''
    );
    if (!currentStatus.includes('pendente')) {
      showPermissionDenied('Só é permitido remover produto quando a mesa estiver pendente.');
      return;
    }
    const saleItems = sale?.itens || [];
    const groupLines = getFractionGroupLines(line, saleItems);
    const groupItemNumbers = Array.from(
      new Set(groupLines.map((item) => toItemNumber(item.numeroItem)).filter((itemNumber) => itemNumber > 0))
    );
    const groupItemNumbersSet = new Set(groupItemNumbers);
    const rootItemNumber = getFractionRootItemNumber(line, saleItems);
    const isFractionGroup = groupLines.length > 1;
    const cancelMessage =
      isFractionGroup
        ? 'O item fracionado será removido com todas as frações.'
        : `Item ${rootItemNumber} será removido.`;
    Alert.alert('Cancelar item', cancelMessage , [
      { text: 'Voltar', style: 'cancel' },
      {
        text: 'Confirmar',
        style: 'destructive',
        onPress: async () => {
          try {
            const cancelTargets = isFractionGroup
              ? [...groupItemNumbers].sort((a, b) => b - a)
              : [rootItemNumber];
            const idUsuario = user?.idUsuario || 0;
            let cancelledCount = 0;

            for (const itemNumber of cancelTargets) {
              try {
                await api.cancelSaleItem(idVenda, itemNumber, idUsuario);
                cancelledCount += 1;
              } catch (error: any) {
                const message = String(error?.message || '').toLowerCase();
                const canIgnore =
                  cancelledCount > 0 &&
                  (
                    message.includes('já cancel') ||
                    message.includes('ja cancel') ||
                    message.includes('não encontrado') ||
                    message.includes('nao encontrado') ||
                    message.includes('not found') ||
                    message.includes('inexistente')
                  );

                if (!canIgnore) {
                  throw error;
                }
              }
            }

            setSale((prev) => {
              if (!prev) return prev;
              const nextItems = (prev.itens || []).filter(
                (item) =>
                  !groupItemNumbersSet.has(toItemNumber(item.numeroItem)) &&
                  !groupItemNumbersSet.has(toItemNumber(item.itemFracionado))
              );
              const nextTotal = nextItems.reduce((acc, item) => acc + Number(item.valorTotal || 0), 0);
              return {
                ...prev,
                itens: nextItems,
                valorTotal: nextTotal,
                valor: nextTotal
              };
            });
            refreshDashboard().catch(() => null);
            loadSale().catch(() => null);
            Alert.alert('Sucesso', isFractionGroup ? 'Itens fracionados cancelados.' : 'Item cancelado.');
          } catch (error: any) {
            Alert.alert('Erro', error?.message || 'Não foi possível cancelar.');
          }
        }
      }
    ]);
  };

  const formatMoney = (value?: number) => `R$ ${(value || 0).toFixed(2)}`;
  const formatQuantity = (value?: number) => {
    const numeric = Number(value || 0);
    if (!Number.isFinite(numeric)) return '0';
    return Number.isInteger(numeric) ? numeric.toString() : numeric.toFixed(3);
  };
  const visibleItems = (sale?.itens || []).filter((line) => line.situacao !== 'cancelada');
  const visibleItemGroups = useMemo(() => {
    const consumed = new Set<number>();

    return visibleItems.reduce<VisibleItemGroup[]>((acc, line) => {
      const lineNumber = toItemNumber(line.numeroItem);
      if (lineNumber > 0 && consumed.has(lineNumber)) {
        return acc;
      }

      const lines = getFractionGroupLines(line, visibleItems);
      const isFractionGroup = lines.length > 1;

      lines.forEach((item) => {
        const itemNumber = toItemNumber(item.numeroItem);
        if (itemNumber > 0) {
          consumed.add(itemNumber);
        }
      });

      const rootItemNumber = getFractionRootItemNumber(line, visibleItems);
      const primaryLine = getFractionPrimaryLine(line, lines);
      const fallbackGroupKey = getFractionFallbackGroupKey(primaryLine);

      acc.push({
        key: isFractionGroup
          ? fallbackGroupKey
            ? `fraction-auto-${fallbackGroupKey}`
            : `fraction-${rootItemNumber || lineNumber}`
          : `item-${lineNumber}`,
        lines,
        primaryLine,
        isFractionGroup,
        total: lines.reduce((sum, item) => sum + Number(item.valorTotal || 0), 0)
      });

      return acc;
    }, []);
  }, [visibleItems]);

  const total = sale?.valorTotal || sale?.valor || 0;
  const status = formatSaleStatus(
    sale?.situacao || activeTable?.venda?.situacao || activeTable?.statusCode || activeTable?.statusOriginal || activeTable?.situacao || ''
  );
  const nomeMesa = activeTable?.nomeMesaComanda || sale?.nomeMesaComanda || 'Sem mesa';
  const mesaDisplay = activeTableCode ? String(activeTableCode) : nomeMesa;
  const mesaLabel = activeTable?.tipo === 'comanda' ? 'Comanda' : 'Mesa';

  const goToMenu = () => {
    navigation.navigate('Inicial');
  };

  const openPreClosure = () => {
    if (!idVenda) return;
    if (!user?.permitePreFechamentoMesaComanda) {
      showPermissionDenied('Sem permissão para fazer pré-fechamento.');
      return;
    }
    navigation.navigate('Fechamento', {
      idVenda,
      idUsuario: user?.idUsuario,
      nomeMesaComanda: nomeMesa,
      tableType: activeTable?.tipo,
      mode: 'pre',
      returnTo: 'Gestao'
    });
  };

  const openFinalClosure = () => {
    if (!idVenda) return;
    if (!user?.permiteFechamentoMesaComanda) {
      showPermissionDenied('Sem permissão para fazer fechamento.');
      return;
    }
    navigation.navigate('Fechamento', {
      idVenda,
      idUsuario: user?.idUsuario,
      nomeMesaComanda: nomeMesa,
      tableType: activeTable?.tipo,
      mode: 'final',
      returnTo: 'Gestao'
    });
  };

  const openPartialPayment = () => {
    if (!idVenda) return;
    if (!user?.permitePagamentoParcial) {
      showPermissionDenied('Sem permissão para pagamento parcial.');
      return;
    }
    navigation.navigate('Pagamento', { idVenda });
  };

  const openMergeSales = () => {
    if (!idVenda) return;
    if (!user?.permiteJuntarMesaComanda) {
      showPermissionDenied('Sem permissão para juntar mesas.');
      return;
    }
    navigation.navigate('JuntarMesa', { idVendaDestino: idVenda });
  };

  const getLineWaiterName = (line: SaleLine): string | null => {
    const waiterName = String(line.nomeGarcom || '').trim();
    if (waiterName) {
      return waiterName;
    }

    const lineWaiterId = Number(line.idGarcom || 0);
    if (lineWaiterId > 0) {
      const mappedWaiter = String(saleUsers[lineWaiterId] || '').trim();
      if (mappedWaiter) {
        return mappedWaiter;
      }
    }

    return null;
  };

  const canManageSale = Boolean(activeTable && idVenda);

  const renderVisibleItemGroup = ({ item: group }: { item: VisibleItemGroup }) => {
    const lineImageSource = resolveLineImageSource(group.primaryLine);
    const lineSizeLabel = getLineSizeLabel(group.primaryLine);
    const lineWaiterName = getLineWaiterName(group.primaryLine);
    const lineLaunchDateTime = getGroupLaunchDateTime(group.lines);

    return (
      <View style={styles.lineCard}>
        {lineImageSource ? (
          <View style={styles.lineThumbWrap}>
            <Image source={lineImageSource} style={styles.lineThumb} resizeMode="cover" />
          </View>
        ) : null}
        <View style={styles.lineContent}>
          <Text style={styles.lineTitle}>
            {group.isFractionGroup ? 'Item fracionado' : group.primaryLine.produtoDescricao}
          </Text>
          {group.isFractionGroup ? (
            <>
              <View style={styles.lineMetaRow}>
                <Text style={styles.lineText}>Frações: {group.lines.length}</Text>
                {lineSizeLabel ? <Text style={styles.lineText}>Tamanho: {lineSizeLabel}</Text> : null}
              </View>
              {lineWaiterName ? <Text style={styles.lineText}>Garçom: {lineWaiterName}</Text> : null}
              {lineLaunchDateTime ? <Text style={styles.lineText}>Lançado em: {lineLaunchDateTime}</Text> : null}
              <View style={styles.fractionList}>
                {group.lines.map((fractionLine, index) => (
                  <View
                    key={`${fractionLine.numeroItem}-${fractionLine.idProduto}`}
                    style={index > 0 ? styles.fractionItemDivider : undefined}
                  >
                    <Text style={styles.lineText}>{fractionLine.produtoDescricao}</Text>
                    <View style={styles.lineMetaRow}>
                      <Text style={styles.lineText}>Qtde: {formatQuantity(fractionLine.quantidade)}</Text>
                    </View>
                    {getVisibleLineObservation(fractionLine) ? (
                      <Text style={styles.lineText}>Obs: {getVisibleLineObservation(fractionLine)}</Text>
                    ) : null}
                    <Text style={styles.lineText}>{formatMoney(fractionLine.valorTotal)}</Text>
                  </View>
                ))}
              </View>
              <Text style={styles.linePrice}>{formatMoney(group.total)}</Text>
            </>
          ) : (
            <>
              <View style={styles.lineMetaRow}>
                <Text style={styles.lineText}>Qtde: {formatQuantity(group.primaryLine.quantidade)}</Text>
                {lineSizeLabel ? <Text style={styles.lineText}>Tamanho: {lineSizeLabel}</Text> : null}
              </View>
              {lineWaiterName ? <Text style={styles.lineText}>Garçom: {lineWaiterName}</Text> : null}
              {lineLaunchDateTime ? <Text style={styles.lineText}>Lançado em: {lineLaunchDateTime}</Text> : null}
              {getVisibleLineObservation(group.primaryLine) ? (
                <Text style={styles.lineText}>Obs: {getVisibleLineObservation(group.primaryLine)}</Text>
              ) : null}
              <Text style={styles.linePrice}>{formatMoney(group.primaryLine.valorTotal)}</Text>
            </>
          )}
        </View>
        {user?.permiteCancelarItemMobile ? (
          <Pressable
            style={({ pressed }) => [styles.lineAction, pressed ? styles.lineActionPressed : null]}
            onPress={() => onCancelLine(group.primaryLine)}
          >
            <View style={styles.lineActionIconWrap}>
              <SafeMaterialCommunityIcons name="trash-can-outline" size={20} color="#E11D48" />
            </View>
          </Pressable>
        ) : null}
      </View>
    );
  };

  return (
    <>
      <FlatList
      style={styles.container}
      contentContainerStyle={styles.contentContainer}
      data={canManageSale ? visibleItemGroups : []}
      keyExtractor={(item) => item.key}
      renderItem={renderVisibleItemGroup}
      showsVerticalScrollIndicator={false}
      removeClippedSubviews
      initialNumToRender={8}
      maxToRenderPerBatch={8}
      windowSize={7}
      updateCellsBatchingPeriod={16}
      refreshControl={<RefreshControl refreshing={loading} onRefresh={loadSale} />}
      ListHeaderComponent={
        <>
          <ScreenRouteLabel />

          <Pressable style={styles.secondaryBtn} onPress={goToMenu}>
            <Text style={styles.secondaryText}>Voltar</Text>
          </Pressable>

          {!activeTable ? (
            <View style={styles.infoCard}>
              <Text style={styles.infoTitle}>Fluxo inválido</Text>
              <Text style={styles.infoText}>Selecione uma mesa e abra a venda em Mesas para gerenciar itens e fechamento.</Text>
            </View>
          ) : !idVenda ? (
            <View style={styles.infoCard}>
              <Text style={styles.infoTitle}>Fluxo inválido</Text>
              <Text style={styles.infoText}>Selecione uma mesa e abra a venda em Mesas para gerenciar itens e fechamento.</Text>
            </View>
          ) : (
            <>
              <View style={styles.summaryCard}>
                <View style={styles.summaryRow}>
                  <Text style={styles.summaryInlineLabel}>{mesaLabel}</Text>
                  <Text style={styles.summaryInlineValue}>{mesaDisplay}</Text>
                  <Text style={styles.summaryInlineLabel}>Status</Text>
                  <Text style={styles.summaryInlineValue}>{status}</Text>
                </View>
                <View style={styles.summaryRow}>
                  <Text style={styles.summaryInlineLabel}>Total</Text>
                  <Text style={styles.totalInline}>{formatMoney(total)}</Text>
                </View>
              </View>

              <View style={styles.rowInputs}>
                <View style={styles.singleRowBlock}>
                  <View style={styles.counterInlineRow}>
                    <Text style={styles.fieldLabelInline}>Pessoas</Text>
                    <View style={styles.counterWrap}>
                      <Pressable style={styles.counterButton} onPress={() => adjustCounterValue(personCount, setPersonCount, -1)}>
                        <SafeMaterialCommunityIcons name="minus" size={16} color={Colors.text} />
                      </Pressable>
                      <TextInput
                        style={styles.counterInput}
                        keyboardType="numeric"
                        value={personCount}
                        onChangeText={setPersonCount}
                        placeholder="0"
                      />
                      <Pressable style={styles.counterButton} onPress={() => adjustCounterValue(personCount, setPersonCount, 1)}>
                        <SafeMaterialCommunityIcons name="plus" size={16} color={Colors.text} />
                      </Pressable>
                    </View>
                  </View>
                </View>
                <View style={styles.rowInputsSecondary}>
                  <View style={styles.halfInputBlock}>
                    <Text style={styles.fieldLabel}>Couvert M</Text>
                    <View style={styles.counterWrap}>
                      <Pressable style={styles.counterButton} onPress={() => adjustCounterValue(couvertMasc, setCouvertMasc, -1)}>
                        <SafeMaterialCommunityIcons name="minus" size={16} color={Colors.text} />
                      </Pressable>
                      <TextInput
                        style={styles.counterInput}
                        keyboardType="numeric"
                        value={couvertMasc}
                        onChangeText={setCouvertMasc}
                        placeholder="0"
                      />
                      <Pressable style={styles.counterButton} onPress={() => adjustCounterValue(couvertMasc, setCouvertMasc, 1)}>
                        <SafeMaterialCommunityIcons name="plus" size={16} color={Colors.text} />
                      </Pressable>
                    </View>
                  </View>
                  <View style={styles.halfInputBlock}>
                    <Text style={styles.fieldLabel}>Couvert F</Text>
                    <View style={styles.counterWrap}>
                      <Pressable style={styles.counterButton} onPress={() => adjustCounterValue(couvertFem, setCouvertFem, -1)}>
                        <SafeMaterialCommunityIcons name="minus" size={16} color={Colors.text} />
                      </Pressable>
                      <TextInput
                        style={styles.counterInput}
                        keyboardType="numeric"
                        value={couvertFem}
                        onChangeText={setCouvertFem}
                        placeholder="0"
                      />
                      <Pressable style={styles.counterButton} onPress={() => adjustCounterValue(couvertFem, setCouvertFem, 1)}>
                        <SafeMaterialCommunityIcons name="plus" size={16} color={Colors.text} />
                      </Pressable>
                    </View>
                  </View>
                </View>
              </View>

              <Pressable style={styles.primaryBtn} onPress={onSaveCouvert} disabled={savingCouvert}>
                <Text style={styles.primaryText}>{savingCouvert ? 'Salvando...' : 'Salvar couvert e pessoas'}</Text>
              </Pressable>

              {!!visibleItemGroups.length ? (
                <View style={styles.sectionHeader}>
                  <Text style={styles.sectionTitle}>Itens da venda</Text>
                </View>
              ) : null}
            </>
          )}
        </>
      }
      ListFooterComponent={
        canManageSale ? (
          <View style={styles.actionGrid}>
            <Pressable
              style={styles.actionCard}
              onPress={openPreClosure}
            >
              <Text style={styles.actionTitle}>Pré fechamento</Text>
              <Text style={styles.actionHint}>Atualizar pessoas/couvert e liberar pré-fechamento</Text>
            </Pressable>
            <Pressable
              style={styles.actionCard}
              onPress={openFinalClosure}
            >
              <Text style={styles.actionTitle}>Fechar venda</Text>
              <Text style={styles.actionHint}>Seleciona pagamentos e aplica desconto</Text>
            </Pressable>
            <Pressable
              style={styles.actionCard}
              onPress={openPartialPayment}
            >
              <Text style={styles.actionTitle}>Pagamento parcial</Text>
              <Text style={styles.actionHint}>Registrar entrada antecipada</Text>
            </Pressable>
            <Pressable
              style={styles.actionCard}
              onPress={() =>
                navigation.navigate('Transferencia', {
                  idMesaOrigem:
                    activeTable?.tipo === 'comanda'
                      ? Number(activeTable?.idComanda || activeTable?.idMesa || 0)
                      : Number(activeTable?.idMesa || 0),
                  idVenda
                })
              }
            >
              <Text style={styles.actionTitle}>Transferir</Text>
              <Text style={styles.actionHint}>Mover mesa/carteira para outra mesa</Text>
            </Pressable>
            <Pressable
              style={styles.actionCard}
              onPress={() => navigation.navigate('PagamentoProgresso', { idVenda })}
            >
              <Text style={styles.actionTitle}>Progresso de pagamento</Text>
              <Text style={styles.actionHint}>Acompanhe parcial pago e pendente</Text>
            </Pressable>
            <Pressable
              style={styles.actionCard}
              onPress={openMergeSales}
            >
              <Text style={styles.actionTitle}>Juntar mesas</Text>
              <Text style={styles.actionHint}>Consolide vendas em uma apenas</Text>
            </Pressable>
            <Pressable
              style={styles.actionCard}
              onPress={onReopenSale}
              disabled={sending}
            >
              <Text style={styles.actionTitle}>Reabrir venda</Text>
              <Text style={styles.actionHint}>Reativa venda caso esteja fechada</Text>
            </Pressable>
            <Pressable
              style={styles.actionCard}
              onPress={() => navigation.navigate('ItensPendentes', { idVenda })}
            >
              <Text style={styles.actionTitle}>Itens pendentes</Text>
              <Text style={styles.actionHint}>Cancelar itens e revisar lançamentos</Text>
            </Pressable>
            <Pressable
              style={styles.actionCard}
              onPress={() => navigation.navigate('Couvert', { idVenda })}
            >
              <Text style={styles.actionTitle}>Couvert</Text>
              <Text style={styles.actionHint}>Atualizar pessoas e couvert</Text>
            </Pressable>
          </View>
        ) : null
      }
    />
      <SweetAlert
        visible={sweetAlert.visible}
        title={sweetAlert.title}
        message={sweetAlert.message}
        type={sweetAlert.type}
        onConfirm={() =>
          setSweetAlert((prev) => ({
            ...prev,
            visible: false
          }))
        }
      />
    </>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background
  },
  contentContainer: {
    padding: Space.md,
    paddingBottom: 140
  },
  fractionList: {
    marginTop: 8
  },
  fractionItemDivider: {
    marginTop: 8,
    paddingTop: 8,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: Colors.border
  },
  sectionHeader: {
    marginTop: 8,
    padding: Space.md
  },
  infoCard: {
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Space.md
  },
  infoTitle: {
    color: Colors.warning,
    fontWeight: '700',
    marginBottom: 6
  },
  infoText: {
    color: Colors.textMuted
  },
  summaryCard: {
    borderRadius: Radius.md,
    borderColor: Colors.primary,
    borderWidth: 1,
    backgroundColor: Colors.card,
    padding: Space.md,
    marginBottom: Space.md
  },
  summaryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 6
  },
  summaryInlineLabel: {
    color: Colors.text,
    fontSize: 12,
    fontWeight: '800',
    textTransform: 'uppercase'
  },
  summaryInlineValue: {
    color: Colors.text,
    fontWeight: '700'
  },
  label: {
    color: Colors.textMuted,
    marginTop: 8,
    fontSize: 12
  },
  value: {
    color: Colors.text,
    fontWeight: '700'
  },
  total: {
    color: Colors.primary,
    fontWeight: '900',
    fontSize: 24,
    marginBottom: 4
  },
  totalInline: {
    color: Colors.primary,
    fontWeight: '900',
    fontSize: 22
  },
  rowInputs: {
    gap: Space.sm,
    marginBottom: Space.md
  },
  singleRowBlock: {
    width: '100%'
  },
  rowInputsSecondary: {
    flexDirection: 'row',
    gap: Space.sm,
    width: '100%',
    flexWrap: 'nowrap',
    alignItems: 'flex-start'
  },
  halfInputBlock: {
    flex: 1,
    minWidth: 0
  },
  inputBlock: {
    flex: 1,
    minWidth: '30%'
  },
  counterInlineRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flexWrap: 'nowrap',
    width: '100%'
  },
  fieldLabel: {
    color: Colors.textMuted,
    fontSize: 12,
    marginBottom: 4,
    fontWeight: '700'
  },
  fieldLabelInline: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    width: 56
  },
  input: {
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    borderRadius: Radius.sm,
    padding: 10,
    color: Colors.text
  },
  counterWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.primary,
    backgroundColor: Colors.card,
    borderRadius: Radius.sm,
    overflow: 'hidden',
    flex: 1,
    minWidth: 0
  },
  counterButton: {
    width: 34,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.background
  },
  counterInput: {
    flex: 1,
    minWidth: 44,
    textAlign: 'center',
    color: Colors.text,
    paddingVertical: 10,
    borderLeftWidth: 1,
    borderRightWidth: 1,
    borderColor: Colors.primary
  },
  primaryBtn: {
    backgroundColor: Colors.primary,
    borderRadius: Radius.md,
    padding: 14,
    alignItems: 'center',
    marginBottom: Space.md
  },
  secondaryBtn: {
    backgroundColor: Colors.card,
    borderRadius: Radius.md,
    padding: 12,
    alignItems: 'center',
    marginBottom: Space.md,
    borderWidth: 1,
    borderColor: Colors.primary
  },
  primaryText: {
    color: '#fff',
    fontWeight: '700'
  },
  secondaryText: {
    color: Colors.text,
    fontWeight: '700'
  },
  section: {
    marginTop: 8,
    marginBottom: Space.md
  },
  sectionTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 8
  },
  lineCard: {
    backgroundColor: Colors.card,
    borderColor: Colors.primary,
    borderWidth: 1,
    borderRadius: Radius.md,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: Space.sm,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  lineThumbWrap: {
    width: 62,
    height: 62,
    borderRadius: Radius.sm,
    overflow: 'hidden',
    marginRight: 12,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.primarySoft,
    alignItems: 'center',
    justifyContent: 'center'
  },
  lineThumb: {
    width: '100%',
    height: '100%'
  },
  lineContent: {
    flex: 1,
    marginRight: 12,
    justifyContent: 'center'
  },
  lineTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 2
  },
  lineText: {
    color: Colors.textMuted,
    fontSize: 12,
    marginTop: 2
  },
  lineMetaRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    marginTop: 2
  },
  linePrice: {
    color: Colors.text,
    fontSize: 13,
    fontWeight: '800',
    marginTop: 6
  },
  lineAction: {
    alignSelf: 'center',
    alignItems: 'center',
    justifyContent: 'center',
    width: 42,
    height: 42,
    backgroundColor: '#FFF1F2',
    borderRadius: 21,
    borderWidth: 1,
    borderColor: '#F8B4C0',
    shadowColor: '#E11D48',
    shadowOpacity: 0.12,
    shadowRadius: 6,
    shadowOffset: {
      width: 0,
      height: 2
    },
    elevation: 2
  },
  lineActionIconWrap: {
    width: 20,
    height: 20,
    alignItems: 'center',
    justifyContent: 'center'
  },
  lineActionPressed: {
    opacity: 0.72,
    transform: [{ scale: 0.97 }]
  },
  lineActionText: {
    color: Colors.warning,
    fontWeight: '700',
    fontSize: 12
  },
  actionGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Space.sm
  },
  actionCard: {
    borderWidth: 1,
    borderColor: Colors.primary,
    borderRadius: Radius.md,
    backgroundColor: Colors.card,
    padding: Space.md,
    width: '48%',
    minHeight: 100
  },
  actionTitle: {
    color: Colors.text,
    fontWeight: '700',
    marginBottom: 4
  },
  actionHint: {
    color: Colors.text,
    fontSize: 12
  }
});
