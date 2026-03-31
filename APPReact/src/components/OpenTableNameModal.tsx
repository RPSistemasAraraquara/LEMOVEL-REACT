import React, { useCallback, useEffect, useRef } from 'react';
import { InteractionManager, Keyboard, Modal, Platform, Pressable, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { Colors, Radius, Space } from '../theme';

type OpenTableNameModalProps = {
  visible: boolean;
  value: string;
  loading?: boolean;
  title?: string;
  description?: string;
  placeholder?: string;
  onChangeText: (value: string) => void;
  onCancel: () => void;
  onConfirm: () => void;
};

export const OpenTableNameModal: React.FC<OpenTableNameModalProps> = ({
  visible,
  value,
  loading = false,
  title = 'Nome da mesa/comanda',
  description = 'Informe o nome para abrir a nova mesa/comanda.',
  placeholder = 'Digite o nome',
  onChangeText,
  onCancel,
  onConfirm
}) => {
  const inputRef = useRef<TextInput | null>(null);
  const interactionRef = useRef<{ cancel?: () => void } | null>(null);
  const focusTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const animationFrameRef = useRef<number | null>(null);

  const clearPendingFocus = useCallback(() => {
    interactionRef.current?.cancel?.();
    interactionRef.current = null;

    if (animationFrameRef.current !== null) {
      cancelAnimationFrame(animationFrameRef.current);
      animationFrameRef.current = null;
    }

    if (focusTimeoutRef.current) {
      clearTimeout(focusTimeoutRef.current);
      focusTimeoutRef.current = null;
    }
  }, []);

  const focusInput = useCallback(() => {
    clearPendingFocus();
    interactionRef.current = InteractionManager.runAfterInteractions(() => {
      animationFrameRef.current = requestAnimationFrame(() => {
        animationFrameRef.current = null;
        inputRef.current?.focus();
        if (Platform.OS === 'android') {
          focusTimeoutRef.current = setTimeout(() => {
            focusTimeoutRef.current = null;
            inputRef.current?.focus();
          }, 180);
        }
      });
    });
  }, [clearPendingFocus]);

  useEffect(() => {
    if (!visible) {
      clearPendingFocus();
      Keyboard.dismiss();
      return;
    }
    focusInput();
    return clearPendingFocus;
  }, [clearPendingFocus, focusInput, visible]);

  return (
  <Modal
    visible={visible}
    transparent
    animationType="fade"
    hardwareAccelerated
    statusBarTranslucent
    onShow={focusInput}
    onRequestClose={loading ? undefined : onCancel}
  >
    <View style={styles.overlay}>
      <Pressable style={styles.backdrop} onPress={loading ? undefined : onCancel} />
      <View style={styles.panel}>
        <Text style={styles.title}>{title}</Text>
        <Text style={styles.description}>{description}</Text>
        <TextInput
          ref={inputRef}
          style={styles.input}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={Colors.textMuted}
          autoCapitalize="words"
          autoCorrect={false}
          autoFocus
          showSoftInputOnFocus
          editable={!loading}
          returnKeyType="done"
          onSubmitEditing={onConfirm}
        />
        <View style={styles.actions}>
          <TouchableOpacity
            style={styles.secondaryButton}
            onPress={onCancel}
            activeOpacity={0.8}
            disabled={loading}
          >
            <Text style={styles.secondaryButtonText}>Cancelar</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.primaryButton, loading ? styles.primaryButtonDisabled : null]}
            onPress={onConfirm}
            activeOpacity={0.85}
            disabled={loading}
          >
            <Text style={styles.primaryButtonText}>{loading ? 'Abrindo...' : 'Confirmar'}</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Space.lg,
    backgroundColor: 'rgba(15, 23, 42, 0.28)'
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject
  },
  panel: {
    width: '100%',
    maxWidth: 420,
    borderRadius: Radius.lg,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Space.lg,
    gap: Space.md
  },
  title: {
    color: Colors.text,
    fontSize: 18,
    fontWeight: '800'
  },
  description: {
    color: Colors.textMuted,
    lineHeight: 20
  },
  input: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    backgroundColor: Colors.cardSoft,
    color: Colors.text,
    paddingHorizontal: 14,
    paddingVertical: 12
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: Space.sm
  },
  secondaryButton: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: Radius.md,
    paddingHorizontal: 16,
    paddingVertical: 11,
    backgroundColor: Colors.cardSoft
  },
  secondaryButtonText: {
    color: Colors.text,
    fontWeight: '700'
  },
  primaryButton: {
    borderRadius: Radius.md,
    paddingHorizontal: 16,
    paddingVertical: 11,
    backgroundColor: Colors.primary
  },
  primaryButtonDisabled: {
    opacity: 0.7
  },
  primaryButtonText: {
    color: '#fff',
    fontWeight: '800'
  }
});
