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
    marginBottom: Space.md,
    position: 'relative'
  },
  card: {
    borderRadius: Radius.lg,
    paddingHorizontal: Space.lg,
    paddingVertical: Space.md,
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
    paddingHorizontal: 9,
    paddingVertical: 5,
    borderRadius: Radius.sm,
    backgroundColor: Colors.accentSoft,
    marginBottom: 8
  },
  badge: {
    color: Colors.accent,
    fontSize: 11,
    letterSpacing: 0,
    fontWeight: '900',
    textTransform: 'uppercase'
  },
  title: {
    fontSize: Typography.subtitle,
    color: Colors.text,
    fontWeight: '900',
    letterSpacing: 0
  },
  subtitle: {
    marginTop: 4,
    color: Colors.textMuted,
    fontSize: Typography.body,
    lineHeight: 21
  }
});
