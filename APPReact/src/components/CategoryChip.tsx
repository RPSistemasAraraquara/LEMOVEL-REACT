import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Colors, Radius, Space, Typography } from '../theme';

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
    paddingVertical: 8,
    paddingHorizontal: 16,
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
    backgroundColor: 'rgba(252, 128, 25, 0.12)',
    borderColor: Colors.primary,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.25,
    shadowRadius: 8,
    elevation: 4
  },
  chipIdle: {
    backgroundColor: 'rgba(40, 54, 93, 0.03)',
    borderColor: 'rgba(252, 128, 25, 0.28)',
    shadowColor: 'transparent',
    elevation: 2
  },
  textActive: {
    color: Colors.primary,
    fontWeight: '800',
    fontSize: Typography.caption,
    letterSpacing: 0.1
  },
  textIdle: {
    color: Colors.text,
    fontWeight: '700',
    fontSize: Typography.caption
  },
  inactiveAccent: {
    width: 24,
    height: 2.5,
    position: 'absolute',
    top: 0,
    left: 16,
    borderRadius: 4,
    backgroundColor: 'rgba(252, 128, 25, 0.26)',
    opacity: 0.9
  },
  dot: { color: Colors.primary, fontSize: 13, marginBottom: 1 }
});
