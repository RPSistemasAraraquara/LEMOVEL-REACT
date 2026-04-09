import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Colors, Radius, Shadows, Space, Typography } from '../theme';

export const CategoryChip: React.FC<{ label: string; active?: boolean; onPress: () => void }> = ({
  label,
  active,
  onPress
}) => {
  return (
    <Pressable
      onPress={onPress}
      style={[styles.chip, active ? styles.chipActive : styles.chipIdle]}
    >
      {!active ? <View style={styles.inactiveAccent} /> : null}
      <Text style={active ? styles.textActive : styles.textIdle}>{label}</Text>
      {active && <Text style={styles.dot}>•</Text>}
    </Pressable>
  );
};

const styles = StyleSheet.create({
  chip: {
    paddingVertical: 11,
    paddingHorizontal: 18,
    borderRadius: 999,
    marginRight: Space.sm,
    marginBottom: Space.sm,
    borderWidth: 1,
    marginTop: 0,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    minHeight: 36,
    overflow: 'hidden'
  },
  chipActive: {
    backgroundColor: '#FFFFFF',
    borderColor: Colors.accent,
    ...Shadows.soft
  },
  chipIdle: {
    backgroundColor: '#F8FBFF',
    borderColor: Colors.border,
    shadowColor: 'transparent',
    elevation: 0
  },
  textActive: {
    color: Colors.primary,
    fontWeight: '800',
    fontSize: Typography.caption,
    letterSpacing: 0.2
  },
  textIdle: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: Typography.caption
  },
  inactiveAccent: {
    width: 30,
    height: 3,
    position: 'absolute',
    top: 0,
    left: 18,
    borderRadius: 4,
    backgroundColor: 'rgba(242, 153, 74, 0.34)',
    opacity: 0.9
  },
  dot: { color: Colors.accent, fontSize: 13, marginBottom: 1 }
});
