import React from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { useApp } from '../context/AppContext';
import { Colors, Radius, Shadows, Space, Typography } from '../theme';
import { getMenuItemLaunchUnitPrice, getProductImageSource, MenuItem, resolveImageUri } from '../services/api';

export const FoodCard: React.FC<{
  item: MenuItem;
  onOpen: () => void;
}> = ({ item, onOpen }) => {
  const { appSettings, activeTable } = useApp();
  const label = item.descricaoCurta?.trim() || '';
  const happyHourSaleType =
    activeTable?.tipo || (appSettings.modoExibicao === 'comanda' ? 'comanda' : 'mesa');
  const price = getMenuItemLaunchUnitPrice(item, String(item.tamanhoPadrao || ''), {
    saleType: happyHourSaleType
  });
  const showImageSlot = appSettings.exibirImagem;
  const localImageUri = resolveImageUri(item.imagemLocalPath || item.imagem || item.imagem_db);
  const imageSource =
    appSettings.exibirImagem && item.possuiImagem
      ? localImageUri
        ? { uri: localImageUri }
        : getProductImageSource(appSettings.baseUrl, appSettings.empresaId, item.idProduto || item.id)
      : undefined;

  return (
    <Pressable style={[styles.card, showImageSlot ? styles.cardWithImage : styles.cardCompact]} onPress={onOpen}>
      <View style={styles.cardAccent} />
      {showImageSlot ? (
        <View style={styles.imageWrap}>
          {imageSource ? (
            <Image
              source={imageSource}
              style={styles.image}
              resizeMode="cover"
              resizeMethod="resize"
              fadeDuration={0}
            />
          ) : (
            <View style={styles.imagePlaceholder} />
          )}
        </View>
      ) : null}
      <View style={styles.cardBody}>
        {!showImageSlot ? (
          <View style={styles.cardMetaRow}>
            <View style={styles.badgeInline}>
              <Text style={styles.badgeText}>R$ {price.toFixed(2)}</Text>
            </View>
            <View style={styles.launchChip}>
              <Text style={styles.launchChipText}>LANÇAR</Text>
            </View>
          </View>
        ) : null}
        <View style={styles.headStacked}>
          <Text style={styles.titleFull}>
            {item.descricao}
          </Text>
          <Text style={[styles.desc, !label ? styles.descHidden : null]} numberOfLines={2}>
            {label || ' '}
          </Text>
        </View>
        <View style={styles.footerRow}>
          {showImageSlot ? (
            <View style={styles.badgeInline}>
              <Text style={styles.badgeText}>R$ {price.toFixed(2)}</Text>
            </View>
          ) : (
            <Text style={styles.footerHint}>Toque para lançar</Text>
          )}
          <View style={styles.footerAction}>
            <Text style={styles.footerActionText}>Abrir</Text>
          </View>
        </View>
      </View>
    </Pressable>
  );
};

export const MemoFoodCard = React.memo(
  FoodCard,
  (prev, next) =>
    prev.item.idProduto === next.item.idProduto &&
    prev.item.descricao === next.item.descricao &&
    prev.item.descricaoCurta === next.item.descricaoCurta &&
    prev.item.valorVenda === next.item.valorVenda &&
    prev.item.valorUnitario === next.item.valorUnitario &&
    prev.item.possuiImagem === next.item.possuiImagem &&
    (prev.item.imagem?.length || 0) === (next.item.imagem?.length || 0) &&
    (prev.item.imagem_db?.length || 0) === (next.item.imagem_db?.length || 0) &&
    (prev.item.imagemLocalPath?.length || 0) === (next.item.imagemLocalPath?.length || 0) &&
    prev.item.idCategoria === next.item.idCategoria &&
    prev.item.happyHourAtivar === next.item.happyHourAtivar &&
    (prev.item.happyHour?.valor || 0) === (next.item.happyHour?.valor || 0) &&
    String(prev.item.happyHour?.horaInicial || '') === String(next.item.happyHour?.horaInicial || '') &&
    String(prev.item.happyHour?.horaFinal || '') === String(next.item.happyHour?.horaFinal || '') &&
    Boolean(prev.item.happyHour?.segundaFeira) === Boolean(next.item.happyHour?.segundaFeira) &&
    Boolean(prev.item.happyHour?.tercaFeira) === Boolean(next.item.happyHour?.tercaFeira) &&
    Boolean(prev.item.happyHour?.quartaFeira) === Boolean(next.item.happyHour?.quartaFeira) &&
    Boolean(prev.item.happyHour?.quintaFeira) === Boolean(next.item.happyHour?.quintaFeira) &&
    Boolean(prev.item.happyHour?.sextaFeira) === Boolean(next.item.happyHour?.sextaFeira) &&
    Boolean(prev.item.happyHour?.sabado) === Boolean(next.item.happyHour?.sabado) &&
    Boolean(prev.item.happyHour?.domingo) === Boolean(next.item.happyHour?.domingo)
);

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.card,
    borderRadius: Radius.lg,
    padding: 14,
    marginBottom: Space.sm,
    borderWidth: 1,
    borderColor: Colors.border,
    ...Shadows.card,
    flex: 1,
    justifyContent: 'space-between',
    overflow: 'hidden'
  },
  cardCompact: {
    minHeight: 158
  },
  cardWithImage: {
    minHeight: 0
  },
  cardAccent: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 4,
    backgroundColor: Colors.accent
  },
  imageWrap: {
    marginBottom: Space.sm,
    borderRadius: Radius.sm,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.primarySoft,
    position: 'relative'
  },
  image: {
    width: '100%',
    height: 122
  },
  imagePlaceholder: {
    width: '100%',
    height: 122,
    backgroundColor: Colors.primarySoft
  },
  cardBody: {
    flex: 1,
    justifyContent: 'space-between'
  },
  cardMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: Space.sm,
    marginBottom: 10
  },
  headStacked: {
    gap: 8,
    justifyContent: 'flex-start'
  },
  titleFull: {
    fontSize: 16,
    fontWeight: '800',
    color: Colors.text,
    lineHeight: 21,
    flexShrink: 1
  },
  badgeInline: {
    alignSelf: 'flex-start',
    backgroundColor: Colors.accentSoft,
    borderRadius: Radius.sm,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderWidth: 1,
    borderColor: 'rgba(242, 153, 74, 0.18)'
  },
  badgeText: { color: Colors.accent, fontWeight: '800', fontSize: 12 },
  launchChip: {
    alignSelf: 'flex-start',
    borderRadius: 999,
    backgroundColor: Colors.primarySoft,
    paddingHorizontal: 10,
    paddingVertical: 6
  },
  launchChipText: {
    color: Colors.primary,
    fontWeight: '900',
    fontSize: 11,
    letterSpacing: 0.4
  },
  desc: {
    marginTop: 8,
    color: Colors.textMuted,
    fontSize: Typography.caption,
    lineHeight: 18,
    minHeight: 36
  },
  descHidden: {
    height: 0,
    minHeight: 0,
    marginTop: 0,
    opacity: 0
  },
  footerRow: {
    marginTop: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: Space.sm
  },
  footerHint: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700'
  },
  footerAction: {
    borderRadius: 16,
    backgroundColor: Colors.primary,
    paddingHorizontal: 12,
    paddingVertical: 8,
    ...Shadows.button
  },
  footerActionText: {
    color: '#FFFFFF',
    fontWeight: '800',
    fontSize: 12
  }
});
