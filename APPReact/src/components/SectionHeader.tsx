import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { Colors, Space, Typography } from '../theme';

type SectionHeaderProps = {
  title: string;
  subtitle?: string;
  showBadge?: boolean;
  showAccentLine?: boolean;
};

export const SectionHeader: React.FC<SectionHeaderProps> = ({
  title,
  subtitle,
  showBadge = true,
  showAccentLine = true
}) => {
  return (
    <View style={s.wrap}>
      {showAccentLine ? <View style={s.gradient} /> : null}
      {showBadge ? <Text style={s.badge}>GARÇOM</Text> : null}
      <Text style={s.title}>{title}</Text>
      {!!subtitle && <Text style={s.subtitle}>{subtitle}</Text>}
    </View>
  );
};

const s = StyleSheet.create({
  wrap: {
    marginBottom: Space.lg,
    paddingHorizontal: 2,
    position: 'relative',
    paddingTop: 2
  },
  gradient: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: 0,
    height: 4,
    borderRadius: 999,
    backgroundColor: Colors.primary
  },
  badge: {
    color: Colors.primary,
    fontSize: 11,
    letterSpacing: 2,
    marginBottom: 6,
    fontWeight: '900'
  },
  title: {
    fontSize: Typography.subtitle,
    color: Colors.text,
    fontWeight: '900',
    letterSpacing: 0.2
  },
  subtitle: {
    marginTop: 4,
    color: Colors.textMuted,
    fontSize: Typography.caption,
    lineHeight: 18
  }
});
