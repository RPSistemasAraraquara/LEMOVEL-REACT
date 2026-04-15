package com.rpcheff.plugpag;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
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
import com.getnet.posdigital.PosDigital;
import com.getnet.posdigital.beeper.IBeeperService;
import com.getnet.posdigital.card.CardResponse;
import com.getnet.posdigital.card.ICardCallback;
import com.getnet.posdigital.card.ICardService;
import com.getnet.posdigital.card.SearchType;
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
  private static final String DEVKIT_PACKAGE = "br.com.getnet.posdigital";
  private static final String REBATEDOR_PACKAGE = "com.getnet.pesquisa.rebatedor";
  private static final String GETNET_PAYMENT_URL = "getnet://pagamento/v3/payment";

  private interface PosDigitalAction {
    void run(PosDigital posDigital, Promise promise) throws Exception;
  }

  private static final class PendingAction {
    private final Promise promise;
    private final PosDigitalAction action;

    private PendingAction(Promise promise, PosDigitalAction action) {
      this.promise = promise;
      this.action = action;
    }
  }

  private final ReactApplicationContext reactContext;
  private final Handler mainHandler = new Handler(Looper.getMainLooper());
  private final Object registerLock = new Object();
  private final List<PendingAction> pendingActions = new ArrayList<>();

  private boolean registering = false;

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
    withPosDigital(promise, new PosDigitalAction() {
      @Override
      public void run(PosDigital posDigital, final Promise localPromise) throws Exception {
        IInfoService infoService = posDigital.getInfo();
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
  public void getPaymentEnvironment(Promise promise) {
    try {
      WritableMap response = Arguments.createMap();
      response.putBoolean("posDigitalInstalled", isPackageInstalled(SERVICE_PACKAGE));
      response.putBoolean("devkitInstalled", isPackageInstalled(DEVKIT_PACKAGE));
      response.putBoolean("rebatedorInstalled", isPackageInstalled(REBATEDOR_PACKAGE));

      ResolveInfo handler = resolvePaymentHandler(GETNET_PAYMENT_URL);
      String packageName = null;
      String className = null;
      if (handler != null && handler.activityInfo != null) {
        packageName = safe(handler.activityInfo.packageName);
        className = safe(handler.activityInfo.name);
      }

      response.putString("paymentHandlerPackage", packageName);
      response.putString("paymentHandlerClassName", className);
      response.putBoolean("simulationMode", REBATEDOR_PACKAGE.equals(packageName));
      resolvePromise(promise, response);
    } catch (Throwable error) {
      rejectPromise(
        promise,
        "GETNET_PAYMENT_ENVIRONMENT_ERROR",
        firstNonEmpty(error.getMessage(), "Falha ao consultar o ambiente de pagamento da GetNet."),
        error
      );
    }
  }

  @ReactMethod
  public void turnOnAllLeds(Promise promise) {
    withPosDigital(promise, new PosDigitalAction() {
      @Override
      public void run(PosDigital posDigital, Promise localPromise) throws Exception {
        ILedService ledService = posDigital.getLed();
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
    withPosDigital(promise, new PosDigitalAction() {
      @Override
      public void run(PosDigital posDigital, Promise localPromise) throws Exception {
        ILedService ledService = posDigital.getLed();
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
    withPosDigital(promise, new PosDigitalAction() {
      @Override
      public void run(PosDigital posDigital, Promise localPromise) throws Exception {
        IBeeperService beeperService = posDigital.getBeeper();
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

    withPosDigital(promise, new PosDigitalAction() {
      @Override
      public void run(PosDigital posDigital, final Promise localPromise) throws Exception {
        ICardService cardService = posDigital.getCard();
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
    withPosDigital(promise, new PosDigitalAction() {
      @Override
      public void run(PosDigital posDigital, Promise localPromise) throws Exception {
        ICardService cardService = posDigital.getCard();
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
    withPosDigital(promise, new PosDigitalAction() {
      @Override
      public void run(PosDigital posDigital, final Promise localPromise) throws Exception {
        IMifareService mifareService = posDigital.getMifare();
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
    withPosDigital(promise, new PosDigitalAction() {
      @Override
      public void run(PosDigital posDigital, final Promise localPromise) throws Exception {
        IMifareService mifareService = posDigital.getMifare();
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
    withPosDigital(promise, new PosDigitalAction() {
      @Override
      public void run(PosDigital posDigital, Promise localPromise) throws Exception {
        IMifareService mifareService = posDigital.getMifare();
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
    unregisterPosDigital();
  }

  @Override
  public void onHostResume() {
  }

  @Override
  public void onHostPause() {
  }

  @Override
  public void onHostDestroy() {
    unregisterPosDigital();
  }

  private void withPosDigital(Promise promise, PosDigitalAction action) {
    if (!isPosDigitalInstalled()) {
      rejectPromise(promise, "GETNET_POSDIGITAL_UNAVAILABLE", "Serviço PosDigital da GetNet não encontrado neste dispositivo.", null);
      return;
    }

    PosDigital posDigital = getPosDigitalIfReady();
    if (isPosDigitalReady(posDigital)) {
      executePosDigitalAction(posDigital, promise, action);
      return;
    }

    synchronized (registerLock) {
      pendingActions.add(new PendingAction(promise, action));
      if (registering) {
        return;
      }
      registering = true;
    }

    try {
      PosDigital.register(reactContext, new PosDigital.BindCallback() {
        @Override
        public void onConnected() {
          PosDigital connected = getPosDigitalIfReady();
          if (!isPosDigitalReady(connected)) {
            failPendingActions("GETNET_BIND_ERROR", "PosDigital conectado, mas não ficou disponível para uso.", null);
            return;
          }
          flushPendingActions(connected);
        }

        @Override
        public void onDisconnected() {
          synchronized (registerLock) {
            registering = false;
          }
        }

        @Override
        public void onError(Exception error) {
          failPendingActions("GETNET_BIND_ERROR", firstNonEmpty(error == null ? null : error.getMessage(), "Falha ao conectar ao serviço PosDigital da GetNet."), error);
        }
      });
    } catch (Throwable error) {
      failPendingActions("GETNET_BIND_ERROR", firstNonEmpty(error.getMessage(), "Falha ao conectar ao serviço PosDigital da GetNet."), error);
    }
  }

  private void flushPendingActions(PosDigital posDigital) {
    List<PendingAction> queued;
    synchronized (registerLock) {
      registering = false;
      queued = new ArrayList<>(pendingActions);
      pendingActions.clear();
    }

    for (PendingAction item : queued) {
      executePosDigitalAction(posDigital, item.promise, item.action);
    }
  }

  private void executePosDigitalAction(final PosDigital posDigital, final Promise promise, final PosDigitalAction action) {
    new Thread(new Runnable() {
      @Override
      public void run() {
        try {
          action.run(posDigital, promise);
        } catch (Throwable error) {
          rejectPromise(promise, "GETNET_POSDIGITAL_ERROR", firstNonEmpty(error.getMessage(), "Falha ao executar operação PosDigital da GetNet."), error);
        }
      }
    }).start();
  }

  private void failPendingActions(String code, String message, Throwable error) {
    List<PendingAction> queued;
    synchronized (registerLock) {
      registering = false;
      queued = new ArrayList<>(pendingActions);
      pendingActions.clear();
    }

    for (PendingAction item : queued) {
      rejectPromise(item.promise, code, message, error);
    }
  }

  private boolean isPosDigitalReady(PosDigital posDigital) {
    return posDigital != null && posDigital.isInitiated();
  }

  private PosDigital getPosDigitalIfReady() {
    try {
      return PosDigital.getInstance();
    } catch (Throwable ignored) {
      return null;
    }
  }

  private void unregisterPosDigital() {
    synchronized (registerLock) {
      registering = false;
      pendingActions.clear();
    }

    try {
      PosDigital.unregister(reactContext);
    } catch (Throwable ignored) {
    }
  }

  private boolean isPosDigitalInstalled() {
    return isPackageInstalled(SERVICE_PACKAGE);
  }

  private boolean isPackageInstalled(String packageName) {
    try {
      reactContext.getPackageManager().getPackageInfo(packageName, PackageManager.GET_SERVICES);
      return true;
    } catch (Throwable ignored) {
      return false;
    }
  }

  private ResolveInfo resolvePaymentHandler(String deeplink) {
    try {
      Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(deeplink));
      intent.addCategory(Intent.CATEGORY_DEFAULT);
      intent.addCategory(Intent.CATEGORY_BROWSABLE);
      return reactContext.getPackageManager().resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
    } catch (Throwable ignored) {
      return null;
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
        if ("mag".equals(current) || SearchType.MAG.equals(current)) {
          normalized.add(SearchType.MAG);
        } else if ("chip".equals(current) || SearchType.CHIP.equals(current)) {
          normalized.add(SearchType.CHIP);
        } else if ("nfc".equals(current) || SearchType.NFC.equals(current)) {
          normalized.add(SearchType.NFC);
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
    return new String[] { SearchType.MAG, SearchType.CHIP, SearchType.NFC };
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
