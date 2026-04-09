import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { Colors, Radius, Shadows, Space, Typography } from '../theme';

type SectionHeaderProps = {
  title: string;
  subtitle?: string;
  showBadge?: boolean;
  showAccentLine?: boolean;
  badgeLabel?: string;
};

export const SectionHeader: React.FC<SectionHeaderProps> = ({
  title,
  subtitle,
  showBadge = true,
  showAccentLine = true,
  badgeLabel = 'RP MOVEL'
}) => {
  return (
    <View style={s.wrap}>
      {showAccentLine ? <View pointerEvents="none" style={s.glow} /> : null}
      <View style={[s.card, !showAccentLine ? s.cardWithoutGlow : null]}>
        {showAccentLine ? <View style={s.accentLine} /> : null}
        {showBadge ? (
          <View style={s.badgeWrap}>
            <Text style={s.badge}>{badgeLabel}</Text>
          </View>
        ) : null}
        <Text style={s.title}>{title}</Text>
        {!!subtitle && <Text style={s.subtitle}>{subtitle}</Text>}
      </View>
    </View>
  );
};

const s = StyleSheet.create({
  wrap: {
    marginBottom: Space.lg,
    position: 'relative'
  },
  glow: {
    position: 'absolute',
    top: -18,
    right: 24,
    width: 148,
    height: 148,
    borderRadius: 74,
    backgroundColor: 'rgba(242, 153, 74, 0.14)'
  },
  card: {
    borderRadius: Radius.xl,
    paddingHorizontal: Space.lg,
    paddingVertical: Space.lg,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.card,
    overflow: 'hidden',
    ...Shadows.card
  },
  cardWithoutGlow: {
    marginTop: 0
  },
  accentLine: {
    position: 'absolute',
    left: 0,
    top: 0,
    width: '100%',
    height: 5,
    backgroundColor: Colors.accent
  },
  badgeWrap: {
    alignSelf: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
    backgroundColor: Colors.accentSoft,
    marginBottom: 12
  },
  badge: {
    color: Colors.accent,
    fontSize: 11,
    letterSpacing: 0.8,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  title: {
    fontSize: Typography.subtitle,
    color: Colors.text,
    fontWeight: '900',
    letterSpacing: 0.1
  },
  subtitle: {
    marginTop: 6,
    color: Colors.textMuted,
    fontSize: Typography.body,
    lineHeight: 21
  }
});
