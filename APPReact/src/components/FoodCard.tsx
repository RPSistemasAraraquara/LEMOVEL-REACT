import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Image, InteractionManager, Pressable, StyleSheet, Text, View } from 'react-native';
import { Colors, Radius, Shadows, Space, Typography } from '../theme';
import {
  cacheProductImageOnDemand,
  getMenuItemLaunchUnitPrice,
  getProductImageSource,
  MenuItem,
  resolveImageUri
} from '../services/api';

type FoodCardProps = {
  item: MenuItem;
  onOpenItem: (item: MenuItem) => void;
  compactLayout: boolean;
  showImageSlot: boolean;
  imageActive?: boolean;
  deferImageLoad?: boolean;
  happyHourSaleType: 'mesa' | 'comanda';
  baseUrl: string;
  empresaId: number;
};

export const FoodCard: React.FC<FoodCardProps> = ({
  item,
  onOpenItem,
  compactLayout,
  showImageSlot,
  imageActive = true,
  deferImageLoad = false,
  happyHourSaleType,
  baseUrl,
  empresaId
}) => {
  const [imageLoadError, setImageLoadError] = useState(false);
  const [remoteImageReady, setRemoteImageReady] = useState(false);
  const [cachedImageUri, setCachedImageUri] = useState<string | undefined>(undefined);
  const label = item.descricaoCurta?.trim() || '';
  const handleOpen = useCallback(() => {
    onOpenItem(item);
  }, [item, onOpenItem]);

  useEffect(() => {
    setImageLoadError(false);
    setCachedImageUri(undefined);
  }, [baseUrl, empresaId, item.idProduto, item.id, item.imagemLocalPath, item.imagem, item.imagem_db]);

  const price = useMemo(
    () => {
      const hasDynamicPrice = Boolean(
        item.happyHourAtivar ||
        item.happyHour ||
        item.vendaPorTamanho ||
        item.permiteFracao
      );

      if (!hasDynamicPrice) {
        return Number(item.valorUnitario || item.valorVenda || 0);
      }

      return getMenuItemLaunchUnitPrice(item, String(item.tamanhoPadrao || ''), {
        saleType: happyHourSaleType
      });
    },
    [happyHourSaleType, item]
  );

  const localImageUri = useMemo(
    () => resolveImageUri(item.imagemLocalPath || item.imagem || item.imagem_db),
    [item.imagemLocalPath, item.imagem, item.imagem_db]
  );

  const imageEligible = showImageSlot && Boolean(item.possuiImagem) && imageActive;

  useEffect(() => {
    if (!imageEligible) {
      setRemoteImageReady(false);
      return undefined;
    }

    if (localImageUri || cachedImageUri) {
      setRemoteImageReady(true);
      return undefined;
    }

    if (deferImageLoad) {
      if (!remoteImageReady) {
        setRemoteImageReady(false);
      }
      return undefined;
    }

    let cancelled = false;
    let delayTimer: ReturnType<typeof setTimeout> | null = null;
    setRemoteImageReady(false);

    const productId = item.idProduto || item.id;
    const interaction = InteractionManager.runAfterInteractions(() => {
      delayTimer = setTimeout(() => {
        cacheProductImageOnDemand(baseUrl, empresaId, productId)
          .then((uri) => {
            if (!cancelled && uri) {
              setCachedImageUri(uri);
            }
          })
          .catch(() => null)
          .finally(() => {
            if (!cancelled) {
              setRemoteImageReady(true);
            }
          });
      }, 120);
    });

    return () => {
      cancelled = true;
      if (delayTimer) {
        clearTimeout(delayTimer);
      }
      interaction.cancel?.();
    };
  }, [
    baseUrl,
    cachedImageUri,
    deferImageLoad,
    empresaId,
    imageEligible,
    item.idProduto,
    item.id,
    item.imagem,
    item.imagem_db,
    item.imagemLocalPath,
    localImageUri,
    remoteImageReady
  ]);

  const remoteImageSource = useMemo(
    () =>
      imageEligible
        ? getProductImageSource(baseUrl, empresaId, item.idProduto || item.id)
        : undefined,
    [baseUrl, empresaId, imageEligible, item.id, item.idProduto]
  );

  const imageSource = useMemo(() => {
    if (!imageEligible) {
      return undefined;
    }

    if (!imageLoadError && localImageUri) {
      return { uri: localImageUri };
    }

    if (!imageLoadError && cachedImageUri) {
      return { uri: cachedImageUri };
    }

    return remoteImageReady ? remoteImageSource : undefined;
  }, [
    cachedImageUri,
    imageLoadError,
    imageEligible,
    localImageUri,
    remoteImageReady,
    remoteImageSource
  ]);

  const handleImageError = useCallback(() => {
    if ((localImageUri || cachedImageUri) && remoteImageSource && !imageLoadError) {
      setImageLoadError(true);
    }
  }, [cachedImageUri, imageLoadError, localImageUri, remoteImageSource]);

  return (
    <Pressable
      style={[
        styles.card,
        showImageSlot ? styles.cardWithImage : styles.cardCompact,
        compactLayout ? styles.cardNarrow : null
      ]}
      onPress={handleOpen}
    >
      <View style={styles.cardAccent} />
      {showImageSlot ? (
        <View style={[styles.imageWrap, compactLayout ? styles.imageWrapNarrow : null]}>
          {imageSource ? (
            <Image
              source={imageSource}
              style={[styles.image, compactLayout ? styles.imageNarrow : null]}
              resizeMode="cover"
              resizeMethod="resize"
              fadeDuration={0}
              onError={handleImageError}
            />
          ) : (
            <View style={[styles.imagePlaceholder, compactLayout ? styles.imageNarrow : null]} />
          )}
        </View>
      ) : null}
      <View style={styles.cardBody}>
        {!showImageSlot ? (
          <View style={[styles.cardMetaRow, compactLayout ? styles.cardMetaRowNarrow : null, styles.cardMetaRowLaunchOnly]}>
            <View style={[styles.launchChip, compactLayout ? styles.launchChipNarrow : null]}>
              <Text style={[styles.launchChipText, compactLayout ? styles.launchChipTextNarrow : null]} numberOfLines={1}>
                LANÇAR
              </Text>
            </View>
          </View>
        ) : null}
        <View style={styles.headStacked}>
          <Text
            style={[styles.titleFull, compactLayout ? styles.titleFullNarrow : null]}
            numberOfLines={showImageSlot ? (compactLayout ? 2 : 3) : (compactLayout ? 3 : 4)}
          >
            {item.descricao}
          </Text>
          <Text style={[styles.desc, !label ? styles.descHidden : null]} numberOfLines={2}>
            {label || ' '}
          </Text>
        </View>
        <View style={[styles.priceRow, compactLayout ? styles.priceRowNarrow : null]}>
          <Text style={[styles.badgeText, compactLayout ? styles.badgeTextNarrow : null]} numberOfLines={1}>
            R$ {price.toFixed(2)}
          </Text>
        </View>
        {showImageSlot || !compactLayout ? (
          <View
            style={[
              styles.footerRow,
              compactLayout ? styles.footerRowNarrow : null,
              !showImageSlot ? styles.footerRowActionOnly : null
            ]}
          >
            <View style={[styles.footerAction, compactLayout ? styles.footerActionNarrow : null]}>
              <Text style={[styles.footerActionText, compactLayout ? styles.footerActionTextNarrow : null]} numberOfLines={1}>
                Abrir
              </Text>
            </View>
          </View>
        ) : null}
      </View>
    </Pressable>
  );
};

export const MemoFoodCard = React.memo(
  FoodCard,
  (prev, next) =>
    prev.item === next.item &&
    prev.onOpenItem === next.onOpenItem &&
    prev.compactLayout === next.compactLayout &&
    prev.showImageSlot === next.showImageSlot &&
    prev.imageActive === next.imageActive &&
    prev.deferImageLoad === next.deferImageLoad &&
    prev.happyHourSaleType === next.happyHourSaleType &&
    prev.baseUrl === next.baseUrl &&
    prev.empresaId === next.empresaId
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
  cardNarrow: {
    padding: 10,
    borderRadius: Radius.md
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
  imageWrapNarrow: {
    marginBottom: 8,
    borderRadius: 10
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
  imageNarrow: {
    height: 90
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
  cardMetaRowNarrow: {
    gap: 4,
    marginBottom: 8
  },
  cardMetaRowLaunchOnly: {
    justifyContent: 'flex-end'
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
  titleFullNarrow: {
    fontSize: 14,
    lineHeight: 18
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
  badgeInlineNarrow: {
    maxWidth: '52%',
    borderRadius: 10,
    paddingHorizontal: 7,
    paddingVertical: 4
  },
  badgeText: { color: Colors.accent, fontWeight: '800', fontSize: 12 },
  badgeTextNarrow: {
    fontSize: 10
  },
  priceRow: {
    alignSelf: 'flex-start',
    backgroundColor: Colors.accentSoft,
    borderRadius: Radius.sm,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderWidth: 1,
    borderColor: 'rgba(242, 153, 74, 0.18)',
    marginTop: 10
  },
  priceRowNarrow: {
    borderRadius: 10,
    paddingHorizontal: 7,
    paddingVertical: 4,
    marginTop: 8
  },
  launchChip: {
    alignSelf: 'flex-start',
    borderRadius: 999,
    backgroundColor: Colors.primarySoft,
    paddingHorizontal: 10,
    paddingVertical: 6
  },
  launchChipNarrow: {
    maxWidth: '48%',
    paddingHorizontal: 7,
    paddingVertical: 5
  },
  launchChipText: {
    color: Colors.primary,
    fontWeight: '900',
    fontSize: 11,
    letterSpacing: 0.4
  },
  launchChipTextNarrow: {
    fontSize: 10,
    letterSpacing: 0
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
  footerRowNarrow: {
    marginTop: 10,
    gap: 4
  },
  footerRowActionOnly: {
    justifyContent: 'flex-end'
  },
  footerAction: {
    borderRadius: 16,
    backgroundColor: Colors.primary,
    paddingHorizontal: 12,
    paddingVertical: 8,
    ...Shadows.button
  },
  footerActionNarrow: {
    borderRadius: 12,
    paddingHorizontal: 8,
    paddingVertical: 6
  },
  footerActionText: {
    color: '#FFFFFF',
    fontWeight: '800',
    fontSize: 12
  },
  footerActionTextNarrow: {
    fontSize: 11
  }
});
