import { NativeModules, Platform } from 'react-native';

type NativeGetNetPosDigitalInfo = {
  sdkVersion?: string;
  bcVersion?: string;
  osVersion?: string;
  serialNumber?: string;
  androidOSVersion?: string;
  androidKernelVersion?: string;
  firmwareVersion?: string;
  hardwareVersion?: string;
  hardwareSn?: string;
  manufacturer?: string;
  model?: string;
  imei?: string;
  imsi?: string;
  iccid?: string;
  romVersion?: string;
  psamId?: string;
};

type NativeGetNetPosDigitalCardResult = {
  pan?: string;
  type?: string;
  track1?: string;
  track2?: string;
  track3?: string;
  serviceCode?: string;
  expireDate?: string;
  message?: string;
};

type NativeGetNetPosDigitalMifareResult = {
  cardType?: number;
  uid?: string;
  uidHex?: string;
  uidBase64?: string;
  uidLength?: number;
};

type NativeGetNetPaymentEnvironment = {
  posDigitalInstalled?: boolean;
  devkitInstalled?: boolean;
  rebatedorInstalled?: boolean;
  paymentHandlerPackage?: string;
  paymentHandlerClassName?: string;
  simulationMode?: boolean;
};

type NativeGetNetPosDigitalModule = {
  isAvailable?: () => Promise<boolean>;
  getTerminalInfo?: () => Promise<NativeGetNetPosDigitalInfo>;
  getPaymentEnvironment?: () => Promise<NativeGetNetPaymentEnvironment>;
  turnOnAllLeds?: () => Promise<boolean>;
  turnOffAllLeds?: () => Promise<boolean>;
  beepSuccess?: () => Promise<boolean>;
  searchCard?: (options: { timeoutSeconds?: number; searchTypes?: string[] }) => Promise<NativeGetNetPosDigitalCardResult>;
  stopCardReaders?: () => Promise<boolean>;
  searchMifareCard?: () => Promise<NativeGetNetPosDigitalMifareResult>;
  searchMifareCardAndActivate?: () => Promise<NativeGetNetPosDigitalMifareResult>;
  getMifareCardSerialNo?: (cardType: number) => Promise<NativeGetNetPosDigitalMifareResult>;
};

export type GetNetPosDigitalInfo = NativeGetNetPosDigitalInfo;
export type GetNetPosDigitalCardResult = NativeGetNetPosDigitalCardResult;
export type GetNetPosDigitalMifareResult = NativeGetNetPosDigitalMifareResult;
export type GetNetPaymentEnvironment = NativeGetNetPaymentEnvironment;
export type GetNetPosDigitalSearchType = 'mag' | 'chip' | 'nfc';

const getModule = (): NativeGetNetPosDigitalModule | null => {
  const native = (NativeModules || {}) as Record<string, unknown>;
  const candidates = ['RPCheffGetNetPosDigital'];

  for (const key of candidates) {
    const module = native[key] as NativeGetNetPosDigitalModule | undefined;
    if (module && typeof module.isAvailable === 'function') {
      return module;
    }
  }

  return null;
};

const ensureAndroid = () => {
  if (Platform.OS !== 'android') {
    throw new Error('Integração PosDigital da GetNet disponível somente no Android.');
  }
};

const ensureModule = (): NativeGetNetPosDigitalModule => {
  ensureAndroid();
  const module = getModule();
  if (!module) {
    throw new Error('Módulo nativo PosDigital da GetNet não encontrado neste build.');
  }
  return module;
};

export const isGetNetPosDigitalAvailable = async (): Promise<boolean> => {
  if (Platform.OS !== 'android') {
    return false;
  }

  const module = getModule();
  if (!module?.isAvailable) {
    return false;
  }

  try {
    return !!(await module.isAvailable());
  } catch {
    return false;
  }
};

export const getGetNetPosDigitalInfo = async (): Promise<GetNetPosDigitalInfo> => {
  const module = ensureModule();
  if (!module.getTerminalInfo) {
    throw new Error('Consulta PosDigital da GetNet não disponível neste build.');
  }
  return module.getTerminalInfo();
};

export const getGetNetPaymentEnvironment = async (): Promise<GetNetPaymentEnvironment> => {
  const module = ensureModule();
  if (!module.getPaymentEnvironment) {
    throw new Error('Consulta do ambiente de pagamento da GetNet não disponível neste build.');
  }
  return module.getPaymentEnvironment();
};

export const turnOnGetNetPosDigitalLeds = async (): Promise<boolean> => {
  const module = ensureModule();
  if (!module.turnOnAllLeds) {
    throw new Error('Controle de LED da GetNet não disponível neste build.');
  }
  return !!(await module.turnOnAllLeds());
};

export const turnOffGetNetPosDigitalLeds = async (): Promise<boolean> => {
  const module = ensureModule();
  if (!module.turnOffAllLeds) {
    throw new Error('Controle de LED da GetNet não disponível neste build.');
  }
  return !!(await module.turnOffAllLeds());
};

export const beepGetNetPosDigitalSuccess = async (): Promise<boolean> => {
  const module = ensureModule();
  if (!module.beepSuccess) {
    throw new Error('Controle de beep da GetNet não disponível neste build.');
  }
  return !!(await module.beepSuccess());
};

export const searchGetNetPosDigitalCard = async ({
  timeoutSeconds = 30,
  searchTypes = ['mag', 'chip', 'nfc']
}: {
  timeoutSeconds?: number;
  searchTypes?: GetNetPosDigitalSearchType[];
} = {}): Promise<GetNetPosDigitalCardResult> => {
  const module = ensureModule();
  if (!module.searchCard) {
    throw new Error('Leitura de cartão da GetNet não disponível neste build.');
  }

  return module.searchCard({
    timeoutSeconds,
    searchTypes
  });
};

export const stopGetNetPosDigitalCardReaders = async (): Promise<boolean> => {
  const module = ensureModule();
  if (!module.stopCardReaders) {
    return false;
  }
  return !!(await module.stopCardReaders());
};

export const searchGetNetPosDigitalMifareCard = async (): Promise<GetNetPosDigitalMifareResult> => {
  const module = ensureModule();
  if (!module.searchMifareCard) {
    throw new Error('Leitura Mifare da GetNet não disponível neste build.');
  }
  return module.searchMifareCard();
};

export const searchGetNetPosDigitalMifareUid = async (): Promise<GetNetPosDigitalMifareResult> => {
  const module = ensureModule();
  if (module.searchMifareCardAndActivate) {
    return module.searchMifareCardAndActivate();
  }

  if (!module.searchMifareCard || !module.getMifareCardSerialNo) {
    throw new Error('Leitura Mifare da GetNet não disponível neste build.');
  }

  const card = await module.searchMifareCard();
  const cardType = Number(card.cardType || 0);
  if (!Number.isFinite(cardType) || cardType <= 0) {
    throw new Error('Tipo do cartão Mifare não retornado pela GetNet.');
  }

  const serial = await module.getMifareCardSerialNo(cardType);
  return {
    ...card,
    ...serial
  };
};
