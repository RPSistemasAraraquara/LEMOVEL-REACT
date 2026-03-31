import React from 'react';
import { Text, TextStyle } from 'react-native';

type BaseIconProps = {
  size?: number;
  color?: string;
  style?: TextStyle;
};

type NamedIconProps = BaseIconProps & {
  name: string;
};

type ExpoIconComponent = React.ComponentType<NamedIconProps>;

let IoniconsComponent: ExpoIconComponent | null = null;
let MaterialCommunityIconsComponent: ExpoIconComponent | null = null;

try {
  const expoIcons = require('@expo/vector-icons') as {
    Ionicons?: ExpoIconComponent;
    MaterialCommunityIcons?: ExpoIconComponent;
  };
  IoniconsComponent = expoIcons.Ionicons || null;
  MaterialCommunityIconsComponent = expoIcons.MaterialCommunityIcons || null;
} catch (error: unknown) {
  void error;
}

const fallbackGlyph = (name: string): string => {
  switch (name) {
    case 'camera':
      return '📷';
    case 'search':
      return '⌕';
    case 'table-furniture':
      return '⌸';
    case 'receipt':
      return '≣';
    case 'minus':
      return '-';
    case 'plus':
      return '+';
    case 'trash-can-outline':
      return '🗑';
    default:
      return '•';
  }
};

const FallbackIcon: React.FC<NamedIconProps> = ({ name, size = 18, color = '#000', style }) => (
  <Text style={[{ fontSize: size, color, fontWeight: '700', textAlign: 'center' }, style]}>
    {fallbackGlyph(name)}
  </Text>
);

export const SafeIonicons: React.FC<NamedIconProps> = (props) => {
  if (IoniconsComponent) {
    return <IoniconsComponent {...props} />;
  }
  return <FallbackIcon {...props} />;
};

export const SafeMaterialCommunityIcons: React.FC<NamedIconProps> = (props) => {
  if (MaterialCommunityIconsComponent) {
    return <MaterialCommunityIconsComponent {...props} />;
  }
  return <FallbackIcon {...props} />;
};
