import React from 'react';
import { Text, View } from 'react-native';
import { useRoute } from '@react-navigation/native';
import { Colors } from '../theme';

export const ScreenRouteLabel: React.FC = () => {
  const route = useRoute();
  const screenName = route.name || 'Screen';

  return (
    <View
      style={{
        alignSelf: 'flex-start',
        backgroundColor: Colors.primary,
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 10,
        marginBottom: 10,
        zIndex: 10
      }}
    >
      <Text style={{ color: '#fff', fontSize: 11, fontWeight: '700' }}>{screenName}</Text>
    </View>
  );
};

