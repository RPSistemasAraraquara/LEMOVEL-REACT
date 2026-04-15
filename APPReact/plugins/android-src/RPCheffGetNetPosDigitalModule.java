package com.rpcheff.plugpag;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.RemoteException;
import android.util.Base64;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.getnet.posdigital.IMainService;
import com.getnet.posdigital.beeper.IBeeperService;
import com.getnet.posdigital.card.CardResponse;
import com.getnet.posdigital.card.ICardCallback;
import com.getnet.posdigital.card.ICardService;
import com.getnet.posdigital.info.IInfoCallback;
import com.getnet.posdigital.info.IInfoService;
import com.getnet.posdigital.info.InfoResponse;
import com.getnet.posdigital.led.ILedService;
import com.getnet.posdigital.mifare.IMifareActivateCallback;
import com.getnet.posdigital.mifare.IMifareCallback;
import com.getnet.posdigital.mifare.IMifareService;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

public class RPCheffGetNetPosDigitalModule extends ReactContextBaseJavaModule implements LifecycleEventListener {
  private static final String MODULE_NAME = "RPCheffGetNetPosDigital";
  private static final String SERVICE_PACKAGE = "com.getnet.posdigital.service";
  private static final String SERVICE_CLASS = "com.getnet.posdigital.service.MainService";
  private static final String SERVICE_ACTION = "com.getnet.posdigital.service";
  private static final String DESCRIPTOR_BEEPER = "com.getnet.posdigital.beeper.IBeeperService";
  private static final String DESCRIPTOR_CARD = "com.getnet.posdigital.card.ICardService";
  private static final String DESCRIPTOR_INFO = "com.getnet.posdigital.info.IInfoService";
  private static final String DESCRIPTOR_LED = "com.getnet.posdigital.led.ILedService";
  private static final String DESCRIPTOR_MIFARE = "com.getnet.posdigital.mifare.IMifareService";
  private static final String DESCRIPTOR_PRINTER = "com.getnet.posdigital.printer.IPrinterService";
  private static final String SEARCH_MAG = "1";
  private static final String SEARCH_CHIP = "2";
  private static final String SEARCH_NFC = "3";

  private interface BoundServiceAction {
    void run(IMainService service, Promise promise) throws Exception;
  }

  private static final class PendingAction {
    private final Promise promise;
    private final BoundServiceAction action;

    private PendingAction(Promise promise, BoundServiceAction action) {
      this.promise = promise;
      this.action = action;
    }
  }

  private final ReactApplicationContext reactContext;
  private final Handler mainHandler = new Handler(Looper.getMainLooper());
  private final Object serviceLock = new Object();
  private final List<PendingAction> pendingActions = new ArrayList<>();

  private IMainService mainService;
  private ServiceConnection serviceConnection;
  private boolean bindingInProgress = false;

  public RPCheffGetNetPosDigitalModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    reactContext.addLifecycleEventListener(this);
  }

  @NonNull
  @Override
  public String getName() {
    return MODULE_NAME;
  }

  @ReactMethod
  public void addListener(String eventName) {
  }

  @ReactMethod
  public void removeListeners(Integer count) {
  }

  @ReactMethod
  public void isAvailable(Promise promise) {
    promise.resolve(isPosDigitalInstalled());
  }

  @ReactMethod
  public void getTerminalInfo(Promise promise) {
    withService(promise, new BoundServiceAction() {
      @Override
      public void run(IMainService service, final Promise localPromise) throws Exception {
        IInfoService infoService = resolveInfoService(service);
        if (infoService == null) {
          rejectPromise(localPromise, "GETNET_INFO_UNAVAILABLE", "Serviço de informações da GetNet indisponível.", null);
          return;
        }

        infoService.info(new IInfoCallback.Stub() {
          @Override
          public void onInfo(InfoResponse infoResponse) {
            WritableMap response = Arguments.createMap();
            response.putString("sdkVersion", safe(infoResponse.getSdkVersion()));
            response.putString("bcVersion", safe(infoResponse.getBcVersion()));
            response.putString("osVersion", safe(infoResponse.getOsVersion()));
            response.putString("serialNumber", safe(infoResponse.getSerialNumber()));
            response.putString("androidOSVersion", safe(infoResponse.getAndroidOSVersion()));
            response.putString("androidKernelVersion", safe(infoResponse.getAndroidKernelVersion()));
            response.putString("firmwareVersion", safe(infoResponse.getFirmwareVersion()));
            response.putString("hardwareVersion", safe(infoResponse.getHardwareVersion()));
            response.putString("hardwareSn", safe(infoResponse.getHardWareSn()));
            response.putString("manufacturer", safe(infoResponse.getManufacture()));
            response.putString("model", safe(infoResponse.getModel()));
            response.putString("imei", safe(infoResponse.getImei()));
            response.putString("imsi", safe(infoResponse.getImsi()));
            response.putString("iccid", safe(infoResponse.getIccid()));
            response.putString("romVersion", safe(infoResponse.getRomVersion()));
            response.putString("psamId", safe(infoResponse.getPsamId()));
            resolvePromise(localPromise, response);
          }

          @Override
          public void onError(String message) {
            rejectPromise(localPromise, "GETNET_INFO_ERROR", firstNonEmpty(message, "Falha ao consultar as informações da GetNet."), null);
          }
        });
      }
    });
  }

  @ReactMethod
  public void turnOnAllLeds(Promise promise) {
    withService(promise, new BoundServiceAction() {
      @Override
      public void run(IMainService service, Promise localPromise) throws Exception {
        ILedService ledService = resolveLedService(service);
        if (ledService == null) {
          rejectPromise(localPromise, "GETNET_LED_UNAVAILABLE", "Serviço de LED da GetNet indisponível.", null);
          return;
        }
        ledService.turnOnAll();
        resolveBoolean(localPromise, true);
      }
    });
  }

  @ReactMethod
  public void turnOffAllLeds(Promise promise) {
    withService(promise, new BoundServiceAction() {
      @Override
      public void run(IMainService service, Promise localPromise) throws Exception {
        ILedService ledService = resolveLedService(service);
        if (ledService == null) {
          rejectPromise(localPromise, "GETNET_LED_UNAVAILABLE", "Serviço de LED da GetNet indisponível.", null);
          return;
        }
        ledService.turnOffAll();
        resolveBoolean(localPromise, true);
      }
    });
  }

  @ReactMethod
  public void beepSuccess(Promise promise) {
    withService(promise, new BoundServiceAction() {
      @Override
      public void run(IMainService service, Promise localPromise) throws Exception {
        IBeeperService beeperService = resolveBeeperService(service);
        if (beeperService == null) {
          rejectPromise(localPromise, "GETNET_BEEPER_UNAVAILABLE", "Serviço de beep da GetNet indisponível.", null);
          return;
        }
        beeperService.success();
        resolveBoolean(localPromise, true);
      }
    });
  }

  @ReactMethod
  public void searchCard(ReadableMap options, Promise promise) {
    final long timeoutSeconds = resolveTimeoutSeconds(options);
    final String[] searchTypes = resolveSearchTypes(options);

    withService(promise, new BoundServiceAction() {
      @Override
      public void run(IMainService service, final Promise localPromise) throws Exception {
        ICardService cardService = resolveCardService(service);
        if (cardService == null) {
          rejectPromise(localPromise, "GETNET_CARD_UNAVAILABLE", "Serviço de cartão da GetNet indisponível.", null);
          return;
        }

        final AtomicBoolean settled = new AtomicBoolean(false);
        final AtomicReference<String> lastMessage = new AtomicReference<>("");
        cardService.search(timeoutSeconds, searchTypes, new ICardCallback.Stub() {
          @Override
          public void onCard(CardResponse cardResponse) {
            if (!settled.compareAndSet(false, true)) {
              return;
            }

            WritableMap response = Arguments.createMap();
            response.putString("pan", safe(cardResponse.getPan()));
            response.putString("type", safe(cardResponse.getType()));
            response.putString("track1", safe(cardResponse.getTrack1()));
            response.putString("track2", safe(cardResponse.getTrack2()));
            response.putString("track3", safe(cardResponse.getTrack3()));
            response.putString("serviceCode", safe(cardResponse.getServiceCode()));
            response.putString("expireDate", safe(cardResponse.getExpireDate()));
            response.putString("message", safe(lastMessage.get()));
            resolvePromise(localPromise, response);
          }

          @Override
          public void onError(String error) {
            if (!settled.compareAndSet(false, true)) {
              return;
            }
            rejectPromise(localPromise, "GETNET_CARD_ERROR", firstNonEmpty(error, "Falha ao ler cartão na GetNet."), null);
          }

          @Override
          public void onMessage(String message) {
            lastMessage.set(safe(message));
          }
        });
      }
    });
  }

  @ReactMethod
  public void stopCardReaders(Promise promise) {
    withService(promise, new BoundServiceAction() {
      @Override
      public void run(IMainService service, Promise localPromise) throws Exception {
        ICardService cardService = resolveCardService(service);
        if (cardService == null) {
          rejectPromise(localPromise, "GETNET_CARD_UNAVAILABLE", "Serviço de cartão da GetNet indisponível.", null);
          return;
        }
        cardService.stopAllReaders();
        resolveBoolean(localPromise, true);
      }
    });
  }

  @ReactMethod
  public void searchMifareCard(Promise promise) {
    withService(promise, new BoundServiceAction() {
      @Override
      public void run(IMainService service, final Promise localPromise) throws Exception {
        IMifareService mifareService = resolveMifareService(service);
        if (mifareService == null) {
          rejectPromise(localPromise, "GETNET_MIFARE_UNAVAILABLE", "Serviço Mifare da GetNet indisponível.", null);
          return;
        }

        final AtomicBoolean settled = new AtomicBoolean(false);
        mifareService.searchCard(new IMifareCallback.Stub() {
          @Override
          public void onCard(int cardType) {
            if (!settled.compareAndSet(false, true)) {
              return;
            }

            WritableMap response = Arguments.createMap();
            response.putInt("cardType", cardType);
            resolvePromise(localPromise, response);
          }

          @Override
          public void onError(String message) {
            if (!settled.compareAndSet(false, true)) {
              return;
            }
            rejectPromise(localPromise, "GETNET_MIFARE_ERROR", firstNonEmpty(message, "Falha ao localizar cartão Mifare na GetNet."), null);
          }
        });
      }
    });
  }

  @ReactMethod
  public void searchMifareCardAndActivate(Promise promise) {
    withService(promise, new BoundServiceAction() {
      @Override
      public void run(IMainService service, final Promise localPromise) throws Exception {
        IMifareService mifareService = resolveMifareService(service);
        if (mifareService == null) {
          rejectPromise(localPromise, "GETNET_MIFARE_UNAVAILABLE", "Serviço Mifare da GetNet indisponível.", null);
          return;
        }

        final AtomicBoolean settled = new AtomicBoolean(false);
        mifareService.searchCardAndActivate(new IMifareActivateCallback.Stub() {
          @Override
          public void onActivate(byte[] uidBytes) {
            if (!settled.compareAndSet(false, true)) {
              return;
            }

            WritableMap response = Arguments.createMap();
            response.putString("uidHex", bytesToHex(uidBytes));
            response.putString("uidBase64", bytesToBase64(uidBytes));
            response.putInt("uidLength", uidBytes == null ? 0 : uidBytes.length);
            resolvePromise(localPromise, response);
          }

          @Override
          public void onError(String message) {
            if (!settled.compareAndSet(false, true)) {
              return;
            }
            rejectPromise(localPromise, "GETNET_MIFARE_ERROR", firstNonEmpty(message, "Falha ao ativar cartão Mifare na GetNet."), null);
          }
        });
      }
    });
  }

  @ReactMethod
  public void getMifareCardSerialNo(double cardType, Promise promise) {
    final int resolvedCardType = (int) Math.round(cardType);
    withService(promise, new BoundServiceAction() {
      @Override
      public void run(IMainService service, Promise localPromise) throws Exception {
        IMifareService mifareService = resolveMifareService(service);
        if (mifareService == null) {
          rejectPromise(localPromise, "GETNET_MIFARE_UNAVAILABLE", "Serviço Mifare da GetNet indisponível.", null);
          return;
        }

        WritableMap response = Arguments.createMap();
        response.putInt("cardType", resolvedCardType);
        response.putString("uid", safe(mifareService.getCardSerialNo(resolvedCardType)));
        resolvePromise(localPromise, response);
      }
    });
  }

  @Override
  public void invalidate() {
    super.invalidate();
    unbindPosDigitalService();
  }

  @Override
  public void onHostResume() {
  }

  @Override
  public void onHostPause() {
  }

  @Override
  public void onHostDestroy() {
    unbindPosDigitalService();
  }

  private void withService(Promise promise, BoundServiceAction action) {
    if (!isPosDigitalInstalled()) {
      rejectPromise(promise, "GETNET_POSDIGITAL_UNAVAILABLE", "Serviço PosDigital da GetNet não encontrado neste dispositivo.", null);
      return;
    }

    IMainService connectedService;
    synchronized (serviceLock) {
      connectedService = mainService;
      if (connectedService != null) {
        executeBoundAction(connectedService, promise, action);
        return;
      }

      pendingActions.add(new PendingAction(promise, action));
      if (bindingInProgress) {
        return;
      }
      bindingInProgress = true;
    }

    bindPosDigitalService();
  }

  private void bindPosDigitalService() {
    Intent intent = new Intent(SERVICE_ACTION);
    intent.setPackage(SERVICE_PACKAGE);
    intent.setClassName(SERVICE_PACKAGE, SERVICE_CLASS);

    if (serviceConnection == null) {
      serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
          IMainService connected = IMainService.Stub.asInterface(service);
          List<PendingAction> queued;
          synchronized (serviceLock) {
            mainService = connected;
            bindingInProgress = false;
            queued = new ArrayList<>(pendingActions);
            pendingActions.clear();
          }

          for (PendingAction item : queued) {
            executeBoundAction(connected, item.promise, item.action);
          }
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
          synchronized (serviceLock) {
            mainService = null;
            bindingInProgress = false;
          }
        }
      };
    }

    try {
      boolean bound = reactContext.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
      if (!bound) {
        failPendingActions("GETNET_BIND_ERROR", "Não foi possível conectar ao serviço PosDigital da GetNet.", null);
      }
    } catch (Throwable error) {
      failPendingActions("GETNET_BIND_ERROR", firstNonEmpty(error.getMessage(), "Falha ao conectar ao serviço PosDigital da GetNet."), error);
    }
  }

  private void executeBoundAction(final IMainService service, final Promise promise, final BoundServiceAction action) {
    new Thread(new Runnable() {
      @Override
      public void run() {
        try {
          action.run(service, promise);
        } catch (Throwable error) {
          rejectPromise(promise, "GETNET_POSDIGITAL_ERROR", firstNonEmpty(error.getMessage(), "Falha ao executar operação PosDigital da GetNet."), error);
        }
      }
    }).start();
  }

  private void failPendingActions(String code, String message, Throwable error) {
    List<PendingAction> queued;
    synchronized (serviceLock) {
      bindingInProgress = false;
      queued = new ArrayList<>(pendingActions);
      pendingActions.clear();
    }

    for (PendingAction item : queued) {
      rejectPromise(item.promise, code, message, error);
    }
  }

  private void unbindPosDigitalService() {
    synchronized (serviceLock) {
      mainService = null;
      bindingInProgress = false;
      pendingActions.clear();
    }

    if (serviceConnection != null) {
      try {
        reactContext.unbindService(serviceConnection);
      } catch (Throwable ignored) {
      }
    }
  }

  private boolean isPosDigitalInstalled() {
    try {
      reactContext.getPackageManager().getPackageInfo(SERVICE_PACKAGE, PackageManager.GET_SERVICES);
      return true;
    } catch (Throwable ignored) {
      return false;
    }
  }

  private long resolveTimeoutSeconds(ReadableMap options) {
    if (options == null || !options.hasKey("timeoutSeconds") || options.isNull("timeoutSeconds")) {
      return 30L;
    }

    try {
      return Math.max(1L, Math.round(options.getDouble("timeoutSeconds")));
    } catch (Throwable ignored) {
      try {
        return Math.max(1L, options.getInt("timeoutSeconds"));
      } catch (Throwable ignoredAgain) {
        return 30L;
      }
    }
  }

  private String[] resolveSearchTypes(ReadableMap options) {
    if (options == null || !options.hasKey("searchTypes") || options.isNull("searchTypes")) {
      return defaultSearchTypes();
    }

    try {
      ReadableArray value = options.getArray("searchTypes");
      if (value == null || value.size() == 0) {
        return defaultSearchTypes();
      }

      Set<String> normalized = new LinkedHashSet<>();
      for (int index = 0; index < value.size(); index++) {
        String current = safe(value.getString(index)).toLowerCase(Locale.ROOT);
        if ("mag".equals(current) || SEARCH_MAG.equals(current)) {
          normalized.add(SEARCH_MAG);
        } else if ("chip".equals(current) || SEARCH_CHIP.equals(current)) {
          normalized.add(SEARCH_CHIP);
        } else if ("nfc".equals(current) || SEARCH_NFC.equals(current)) {
          normalized.add(SEARCH_NFC);
        }
      }

      if (normalized.isEmpty()) {
        return defaultSearchTypes();
      }

      return normalized.toArray(new String[0]);
    } catch (Throwable ignored) {
      return defaultSearchTypes();
    }
  }

  private String[] defaultSearchTypes() {
    return new String[] { SEARCH_MAG, SEARCH_CHIP, SEARCH_NFC };
  }

  private IBeeperService resolveBeeperService(IMainService service) throws Exception {
    IBeeperService direct = service.getBeeper();
    IBeeperService resolved = adaptBeeperService(direct == null ? null : direct.asBinder());
    if (resolved != null) {
      return resolved;
    }

    return adaptBeeperService(service.getPrinter() == null ? null : service.getPrinter().asBinder());
  }

  private ICardService resolveCardService(IMainService service) throws Exception {
    ICardService direct = service.getCard();
    ICardService resolved = adaptCardService(direct == null ? null : direct.asBinder());
    if (resolved != null) {
      return resolved;
    }

    return adaptCardService(service.getMifare() == null ? null : service.getMifare().asBinder());
  }

  private IInfoService resolveInfoService(IMainService service) throws Exception {
    IInfoService direct = service.getInfo();
    IInfoService resolved = adaptInfoService(direct == null ? null : direct.asBinder());
    if (resolved != null) {
      return resolved;
    }

    return adaptInfoService(service.getLed() == null ? null : service.getLed().asBinder());
  }

  private ILedService resolveLedService(IMainService service) throws Exception {
    ILedService direct = service.getLed();
    ILedService resolved = adaptLedService(direct == null ? null : direct.asBinder());
    if (resolved != null) {
      return resolved;
    }

    return adaptLedService(service.getInfo() == null ? null : service.getInfo().asBinder());
  }

  private IMifareService resolveMifareService(IMainService service) throws Exception {
    IMifareService direct = service.getMifare();
    IMifareService resolved = adaptMifareService(direct == null ? null : direct.asBinder());
    if (resolved != null) {
      return resolved;
    }

    return adaptMifareService(service.getCard() == null ? null : service.getCard().asBinder());
  }

  private IBeeperService adaptBeeperService(IBinder binder) {
    return hasDescriptor(binder, DESCRIPTOR_BEEPER) ? IBeeperService.Stub.asInterface(binder) : null;
  }

  private ICardService adaptCardService(IBinder binder) {
    return hasDescriptor(binder, DESCRIPTOR_CARD) ? ICardService.Stub.asInterface(binder) : null;
  }

  private IInfoService adaptInfoService(IBinder binder) {
    return hasDescriptor(binder, DESCRIPTOR_INFO) ? IInfoService.Stub.asInterface(binder) : null;
  }

  private ILedService adaptLedService(IBinder binder) {
    return hasDescriptor(binder, DESCRIPTOR_LED) ? ILedService.Stub.asInterface(binder) : null;
  }

  private IMifareService adaptMifareService(IBinder binder) {
    return hasDescriptor(binder, DESCRIPTOR_MIFARE) ? IMifareService.Stub.asInterface(binder) : null;
  }

  private boolean hasDescriptor(IBinder binder, String expectedDescriptor) {
    if (binder == null || expectedDescriptor == null || expectedDescriptor.isEmpty()) {
      return false;
    }

    try {
      return expectedDescriptor.equals(binder.getInterfaceDescriptor());
    } catch (RemoteException ignored) {
      return false;
    } catch (Throwable ignored) {
      return false;
    }
  }

  private void resolveBoolean(final Promise promise, final boolean value) {
    mainHandler.post(new Runnable() {
      @Override
      public void run() {
        promise.resolve(value);
      }
    });
  }

  private void resolvePromise(final Promise promise, final Object value) {
    mainHandler.post(new Runnable() {
      @Override
      public void run() {
        promise.resolve(value);
      }
    });
  }

  private void rejectPromise(final Promise promise, final String code, final String message, final Throwable error) {
    mainHandler.post(new Runnable() {
      @Override
      public void run() {
        if (error != null) {
          promise.reject(code, message, error);
        } else {
          promise.reject(code, message);
        }
      }
    });
  }

  private String bytesToHex(byte[] value) {
    if (value == null || value.length == 0) {
      return "";
    }

    StringBuilder builder = new StringBuilder(value.length * 2);
    for (byte item : value) {
      builder.append(String.format(Locale.US, "%02X", item));
    }
    return builder.toString();
  }

  private String bytesToBase64(byte[] value) {
    if (value == null || value.length == 0) {
      return "";
    }
    return Base64.encodeToString(value, Base64.NO_WRAP);
  }

  private String safe(String value) {
    return value == null ? "" : value.trim();
  }

  private String firstNonEmpty(String... values) {
    if (values == null) {
      return "";
    }

    for (String value : values) {
      String current = safe(value);
      if (!current.isEmpty()) {
        return current;
      }
    }

    return "";
  }
}
