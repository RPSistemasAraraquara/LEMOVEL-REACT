import React from 'react';
import { Alert, AlertButton, AlertOptions } from 'react-native';
import { SweetAlert, SweetAlertType } from './SweetAlert';

type AlertState = {
  visible: boolean;
  title: string;
  message: string;
  type: SweetAlertType;
  confirmText?: string;
  cancelText?: string;
  onConfirm?: (() => void) | null;
  onCancel?: (() => void) | null;
};

const initialState: AlertState = {
  visible: false,
  title: '',
  message: '',
  type: 'info',
  confirmText: 'OK',
  cancelText: undefined,
  onConfirm: null,
  onCancel: null
};

let installed = false;
let originalAlert: typeof Alert.alert | null = null;
let showGlobalAlert: ((state: AlertState) => void) | null = null;

const resolveType = (title?: string): SweetAlertType => {
  const normalized = String(title || '').trim().toLowerCase();
  if (normalized.includes('erro')) return 'error';
  if (normalized.includes('aten') || normalized.includes('aviso') || normalized.includes('valida')) return 'warning';
  if (normalized.includes('conclu') || normalized.includes('sucesso')) return 'success';
  return 'info';
};

const resolveButtons = (buttons?: AlertButton[]) => {
  if (!buttons || buttons.length === 0) {
    return {
      confirmText: 'OK',
      cancelText: undefined,
      onConfirm: null,
      onCancel: null
    };
  }

  if (buttons.length === 1) {
    return {
      confirmText: buttons[0]?.text || 'OK',
      cancelText: undefined,
      onConfirm: buttons[0]?.onPress ? () => buttons[0].onPress?.() : null,
      onCancel: null
    };
  }

  const cancelButton = buttons.find((button) => button.style === 'cancel') || buttons[0];
  const confirmButton = [...buttons].reverse().find((button) => button !== cancelButton) || buttons[buttons.length - 1];

  return {
    confirmText: confirmButton?.text || 'OK',
    cancelText: cancelButton?.text || 'Cancelar',
    onConfirm: confirmButton?.onPress ? () => confirmButton.onPress?.() : null,
    onCancel: cancelButton?.onPress ? () => cancelButton.onPress?.() : null
  };
};

export const installGlobalSweetAlert = () => {
  if (installed) {
    return;
  }

  installed = true;
  originalAlert = originalAlert || Alert.alert.bind(Alert);

  Alert.alert = ((title?: string, message?: string, buttons?: AlertButton[], options?: AlertOptions) => {
    if (!showGlobalAlert) {
      return originalAlert?.(title || '', message, buttons, options);
    }

    const resolvedButtons = resolveButtons(buttons);

    showGlobalAlert({
      visible: true,
      title: title || 'Atenção',
      message: message || '',
      type: resolveType(title),
      confirmText: resolvedButtons.confirmText,
      cancelText: resolvedButtons.cancelText,
      onConfirm: resolvedButtons.onConfirm,
      onCancel: resolvedButtons.onCancel
    });
  }) as typeof Alert.alert;
};

export const GlobalSweetAlertHost: React.FC = () => {
  const [state, setState] = React.useState<AlertState>(initialState);

  React.useEffect(() => {
    installGlobalSweetAlert();

    const handler = (nextState: AlertState) => {
      setState(nextState);
    };

    showGlobalAlert = handler;

    return () => {
      if (showGlobalAlert === handler) {
        showGlobalAlert = null;
      }
    };
  }, []);

  const closeAlert = () => {
    setState(initialState);
  };

  const handleConfirm = () => {
    const callback = state.onConfirm;
    closeAlert();
    callback?.();
  };

  const handleCancel = () => {
    const callback = state.onCancel;
    closeAlert();
    callback?.();
  };

  return (
    <SweetAlert
      visible={state.visible}
      title={state.title}
      message={state.message}
      type={state.type}
      confirmText={state.confirmText}
      cancelText={state.cancelText}
      onConfirm={handleConfirm}
      onCancel={state.cancelText ? handleCancel : undefined}
    />
  );
};
