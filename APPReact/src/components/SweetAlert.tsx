import React from 'react';
import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { Colors, Radius, Shadows, Space } from '../theme';

export type SweetAlertType = 'info' | 'warning' | 'error' | 'success';

type Props = {
  visible: boolean;
  title: string;
  message: string;
  type?: SweetAlertType;
  confirmText?: string;
  onConfirm: () => void;
  cancelText?: string;
  onCancel?: () => void;
};

const iconByType: Record<SweetAlertType, string> = {
  info: 'i',
  warning: '!',
  error: 'x',
  success: '✓'
};

export const SweetAlert: React.FC<Props> = ({
  visible,
  title,
  message,
  type = 'info',
  confirmText = 'OK',
  onConfirm,
  cancelText,
  onCancel
}) => {
  return (
    <Modal transparent animationType="fade" visible={visible} onRequestClose={onConfirm}>
      <View style={styles.overlay}>
        <View style={styles.card}>
          <View style={[styles.iconWrap, type === 'warning' ? styles.warning : null, type === 'error' ? styles.error : null, type === 'success' ? styles.success : null]}>
            <Text style={styles.iconText}>{iconByType[type]}</Text>
          </View>
          <Text style={styles.title}>{title}</Text>
          <Text style={styles.message}>{message}</Text>

          <View style={styles.actions}>
            {cancelText && onCancel ? (
              <Pressable style={[styles.btn, styles.btnSecondary]} onPress={onCancel}>
                <Text style={styles.btnSecondaryText}>{cancelText}</Text>
              </Pressable>
            ) : null}
            <Pressable style={[styles.btn, styles.btnPrimary]} onPress={onConfirm}>
              <Text style={styles.btnPrimaryText}>{confirmText}</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.38)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: Space.md
  },
  card: {
    width: '100%',
    maxWidth: 360,
    borderRadius: Radius.lg,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 14,
    alignItems: 'center',
    ...Shadows.card
  },
  iconWrap: {
    width: 54,
    height: 54,
    borderRadius: 27,
    backgroundColor: Colors.accentSoft,
    borderWidth: 1,
    borderColor: 'rgba(242, 153, 74, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 10
  },
  warning: {
    backgroundColor: Colors.warning + '22',
    borderColor: Colors.warning
  },
  error: {
    backgroundColor: Colors.danger + '22',
    borderColor: Colors.danger
  },
  success: {
    backgroundColor: Colors.success + '22',
    borderColor: Colors.success
  },
  iconText: {
    color: Colors.primary,
    fontWeight: '900',
    fontSize: 24
  },
  title: {
    color: Colors.text,
    fontWeight: '900',
    fontSize: 18,
    marginBottom: 6,
    textAlign: 'center'
  },
  message: {
    color: Colors.textMuted,
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: 14
  },
  actions: {
    width: '100%',
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8
  },
  btn: {
    minWidth: 104,
    borderRadius: Radius.sm,
    paddingVertical: 12,
    paddingHorizontal: 14,
    alignItems: 'center'
  },
  btnPrimary: {
    backgroundColor: Colors.primary,
    ...Shadows.button
  },
  btnPrimaryText: {
    color: '#fff',
    fontWeight: '800'
  },
  btnSecondary: {
    backgroundColor: Colors.cardSoft,
    borderWidth: 1,
    borderColor: Colors.border
  },
  btnSecondaryText: {
    color: Colors.text,
    fontWeight: '700'
  }
});
