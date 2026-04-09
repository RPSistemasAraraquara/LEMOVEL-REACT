import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useRoute } from '@react-navigation/native';
import { Colors } from '../theme';

export const ScreenRouteLabel: React.FC = () => {
  const route = useRoute();
  const screenName = route.name || 'Screen';

  return (
    <View style={styles.pill}>
      <View style={styles.dot} />
      <Text style={styles.text}>{screenName}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  pill: {
    alignSelf: 'flex-start',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    backgroundColor: Colors.accentSoft,
    paddingHorizontal: 11,
    paddingVertical: 6,
    borderRadius: 999,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: 'rgba(242, 153, 74, 0.18)',
    zIndex: 10
  },
  dot: {
    width: 7,
    height: 7,
    borderRadius: 4,
    backgroundColor: Colors.accent
  },
  text: {
    color: Colors.primary,
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0.5,
    textTransform: 'uppercase'
  }
});
