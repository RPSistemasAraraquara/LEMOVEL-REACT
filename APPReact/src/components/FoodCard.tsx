import React from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { useApp } from '../context/AppContext';
import { Colors, Radius, Space, Typography } from '../theme';
import { getProductImageSource, MenuItem, resolveImageUri } from '../services/api';

export const FoodCard: React.FC<{
  item: MenuItem;
  onOpen: () => void;
}> = ({ item, onOpen }) => {
  const { appSettings } = useApp();
  const label = item.descricaoCurta?.trim() || '';
  const price = item.valorVenda || item.valorUnitario || 0;
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
      <View style={styles.headStacked}>
        <Text style={styles.titleFull}>
          {item.descricao}
        </Text>
        <View style={styles.badgeInline}>
          <Text style={styles.badgeText}>R$ {price.toFixed(2)}</Text>
        </View>
      </View>
      <Text style={[styles.desc, !label ? styles.descHidden : null]} numberOfLines={2}>
        {label || ' '}
      </Text>
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
    prev.item.idCategoria === next.item.idCategoria
);

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.card,
    borderRadius: Radius.md,
    padding: 12,
    marginBottom: Space.sm,
    borderWidth: 1,
    borderColor: Colors.primary,
    shadowColor: Colors.shadow,
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 1,
    flex: 1,
    justifyContent: 'space-between',
    overflow: 'hidden'
  },
  cardCompact: {
    minHeight: 124
  },
  cardWithImage: {
    minHeight: 0
  },
  imageWrap: {
    marginBottom: Space.sm,
    borderRadius: Radius.sm,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.primarySoft
  },
  image: {
    width: '100%',
    height: 108
  },
  imagePlaceholder: {
    width: '100%',
    height: 108,
    backgroundColor: Colors.primarySoft
  },
  headStacked: {
    gap: 8,
    justifyContent: 'flex-start'
  },
  titleFull: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.text,
    lineHeight: 21,
    flexShrink: 1
  },
  badgeInline: {
    alignSelf: 'flex-start',
    backgroundColor: Colors.primarySoft,
    borderRadius: Radius.sm,
    paddingHorizontal: 9,
    paddingVertical: 3
  },
  badgeText: { color: Colors.primary, fontWeight: '800', fontSize: 12 },
  desc: {
    marginTop: 6,
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
  }
});
