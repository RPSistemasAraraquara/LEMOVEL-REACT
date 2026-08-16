package com.rpcheff.plugpag;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

import br.com.uol.pagseguro.plugpag.terminallib.wrapper.TerminalLib;
import br.com.uol.pagseguro.plugpag.terminallib.wrapper.TerminalServiceAppIdentification;
import br.com.uol.pagseguro.plugpag.terminallib.wrapper.results.PrinterResult;
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPag;
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagEventData;
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPaymentData;
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPrintResult;
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagTransactionResult;
import br.com.uol.pagseguro.plugpagservice.wrapper.exception.PlugPagException;
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagPaymentListener;

public class RPCheffPlugPagModule extends ReactContextBaseJavaModule {
  private static final String TAG = "RPCheffPlugPag";
  private static final String EVENT_PROGRESS = "RPCheffPlugPagProgress";
  private static final long ASYNC_PAYMENT_TIMEOUT_MS = 120000L;
  private static final long PAYMENT_LOCK_STALE_MS = ASYNC_PAYMENT_TIMEOUT_MS + 30000L;
  private static final int RECEIPT_WIDTH_PX = 384;
  private static final int RECEIPT_MARGIN_PX = 16;
  private static final int MONOCHROME_THRESHOLD = 232;
  private static final String TERMINAL_APP_NAME = "RPCheffGarcom";
  private static final String TERMINAL_APP_VERSION = "1.0.0";
  private static final String TERMINAL_WRAPPER_VERSION = "1.33.0";
  private static final AtomicBoolean paymentInProgress = new AtomicBoolean(false);
  private static final AtomicLong paymentStartedAtMs = new AtomicLong(0L);
  private static final AtomicReference<PlugPag> currentPlugPag = new AtomicReference<>(null);
  private static final AtomicReference<PlugPag> sharedPlugPag = new AtomicReference<>(null);

  private final Handler mainHandler = new Handler(Looper.getMainLooper());

  public RPCheffPlugPagModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @NonNull
  @Override
  public String getName() {
    return "RPCheffPlugPag";
  }

  @ReactMethod
  public void addListener(String eventName) {
    // Required for NativeEventEmitter
  }

  @ReactMethod
  public void removeListeners(Integer count) {
    // Required for NativeEventEmitter
  }

  @ReactMethod
  public void preparePayment(Promise promise) {
    try {
      mainHandler.post(() -> {
        try {
          getOrCreateSharedPlugPag();
          Log.d(TAG, "PagBank preparada antecipadamente.");
          promise.resolve(true);
        } catch (Throwable error) {
          promise.reject(
            "PAGBANK_PREPARE_ERROR",
            error.getMessage() == null ? "Falha ao preparar PagBank." : error.getMessage(),
            error
          );
        }
      });
    } catch (Throwable error) {
      promise.reject(
        "PAGBANK_PREPARE_ERROR",
        error.getMessage() == null ? "Falha ao preparar PagBank." : error.getMessage(),
        error
      );
    }
  }

  @ReactMethod
  public void executePayment(ReadableMap payload, Promise promise) {
    recoverStalePaymentLock();
    if (!paymentInProgress.compareAndSet(false, true)) {
      Log.w(TAG, "executePayment bloqueado porque ja existe uma transacao em andamento.");
      promise.reject("PAGBANK_BUSY", "Ja existe um pagamento PagBank em andamento. Aguarde a conclusao.");
      return;
    }

    paymentStartedAtMs.set(System.currentTimeMillis());
    Log.d(TAG, "executePayment lock adquirido.");
    emitPaymentProgress("starting", "Inicializando pagamento na PagBank...", null);
    executePaymentInternal(payload, promise);
  }

  @ReactMethod
  public void abortPayment(Promise promise) {
    PlugPag plugPag = currentPlugPag.getAndSet(null);
    if (plugPag == null) {
      releasePaymentLock();
      promise.resolve(false);
      return;
    }

    try {
      plugPag.abort();
      Log.d(TAG, "Pagamento PagBank abortado manualmente.");
      releasePaymentLock();
      promise.resolve(true);
    } catch (Throwable error) {
      releasePaymentLock();
      promise.reject("PAGBANK_ABORT_ERROR", error.getMessage() == null ? "Falha ao abortar pagamento PagBank." : error.getMessage(), error);
    }
  }

  @ReactMethod
  public void printReceipt(ReadableMap payload, Promise promise) {
    try {
      String content = payload.hasKey("content") ? safe(payload.getString("content")) : "";
      int columns = payload.hasKey("columns") ? payload.getInt("columns") : 32;
      String title = payload.hasKey("title") ? safe(payload.getString("title")) : "RPCheff";

      if (content.trim().isEmpty()) {
        promise.reject("PAGBANK_PRINT_EMPTY", "Conteúdo de impressão vazio.");
        return;
      }

      emitPaymentProgress("printing", "Enviando impressão para a PagBank...", null);

      final String printContent = content;
      final int printColumns = columns;
      final String printTitle = title;

      new Thread(() -> {
        try {
          // DANFCe da NFC-e: o servidor manda a imagem do cupom fiscal em
          // base64 ({type:'image', imagePath|imageData}) - imprime o bitmap
          // direto em vez de renderizar texto.
          String receiptImageBase64 = extractReceiptImageBase64(printContent);
          File imageFile = receiptImageBase64 != null
            ? buildBase64ImageFile(receiptImageBase64)
            : buildReceiptImage(printContent, printColumns, printTitle);
          TerminalServiceAppIdentification appIdentification = new TerminalServiceAppIdentification(
            TERMINAL_APP_NAME,
            TERMINAL_APP_VERSION,
            TERMINAL_WRAPPER_VERSION
          );
          TerminalLib terminalLib = new TerminalLib(getReactApplicationContext(), appIdentification);
          PrinterResult result = terminalLib.doPrint(imageFile.getAbsolutePath());

          if (result == null) {
            promise.reject("PAGBANK_PRINT_ERROR", "doPrint retornou vazio.");
            return;
          }

          int resultCode = result.getResult();
          String message = safe(result.getMessage());
          String errorCode = safe(result.getErrorCode());
          if (resultCode != 0) {
            String suffix = errorCode.isEmpty() ? "" : " (codigo: " + errorCode + ")";
            promise.reject(
              "PAGBANK_PRINT_ERROR",
              (message.isEmpty() ? "Falha ao imprimir na PagBank." : message) + suffix
            );
            return;
          }

          WritableMap response = Arguments.createMap();
          response.putBoolean("printed", true);
          response.putString("message", message.isEmpty() ? "Impressão enviada para a PagBank." : message);
          response.putString("errorCode", errorCode);
          response.putInt("result", resultCode);
          promise.resolve(response);
        } catch (Throwable error) {
          promise.reject(
            "PAGBANK_PRINT_ERROR",
            error.getMessage() == null ? "Falha ao imprimir na PagBank." : error.getMessage(),
            error
          );
        }
      }).start();
    } catch (Throwable error) {
      promise.reject(
        "PAGBANK_PRINT_ERROR",
        error.getMessage() == null ? "Falha ao preparar impressão PagBank." : error.getMessage(),
        error
      );
    }
  }

  private PlugPag getOrCreateSharedPlugPag() {
    PlugPag plugPag = sharedPlugPag.get();
    if (plugPag != null) {
      return plugPag;
    }

    PlugPag created = new PlugPag(getReactApplicationContext());
    if (sharedPlugPag.compareAndSet(null, created)) {
      return created;
    }

    return sharedPlugPag.get();
  }

  private void executePaymentInternal(ReadableMap payload, Promise promise) {
    try {
      int amount = payload.hasKey("amount") ? payload.getInt("amount") : 0;
      if (amount <= 0) {
        releasePaymentLock();
        promise.reject("PAGBANK_INVALID_AMOUNT", "Valor de pagamento invalido.");
        return;
      }

      int transactionType = resolveTransactionType(payload.hasKey("transactionType") ? payload.getString("transactionType") : null);
      if (transactionType < 0) {
        releasePaymentLock();
        promise.reject("PAGBANK_INVALID_TRANSACTION", "Tipo de transacao invalido para PagBank.");
        return;
      }

      int installments = payload.hasKey("installments") ? Math.max(1, payload.getInt("installments")) : 1;
      int installmentType = resolveInstallmentType(payload, transactionType, installments);

      String userReference = payload.hasKey("userReference") ? payload.getString("userReference") : null;
      if (userReference == null || userReference.trim().isEmpty()) {
        userReference = new SimpleDateFormat("yyyyMMddHHmmssSSS", Locale.US).format(new Date());
      }

      PlugPag plugPag = getOrCreateSharedPlugPag();
      currentPlugPag.set(plugPag);
      PlugPagPaymentData paymentData = new PlugPagPaymentData(
        transactionType,
        amount,
        installmentType,
        installments,
        userReference,
        true,
        false,
        false
      );

      AtomicBoolean settled = new AtomicBoolean(false);
      Runnable timeoutRunnable = new Runnable() {
        @Override
        public void run() {
          if (!settled.compareAndSet(false, true)) {
            return;
          }

          try {
            plugPag.abort();
          } catch (Throwable ignored) {
            // best effort
          }

          currentPlugPag.compareAndSet(plugPag, null);
          emitPaymentProgress("timeout", "Tempo limite ao aguardar retorno da PagBank.", null);
          releasePaymentLock();
          promise.reject("PAGBANK_TIMEOUT", "Tempo limite ao aguardar retorno da PagBank.");
        }
      };

      mainHandler.postDelayed(timeoutRunnable, ASYNC_PAYMENT_TIMEOUT_MS);

      mainHandler.post(() -> {
        try {
          Log.d(TAG, "Iniciando doAsyncPayment com listener.");
          emitPaymentProgress("waiting_card", "Aguardando cartão ou aproximação...", null);
          plugPag.doAsyncPayment(paymentData, new PlugPagPaymentListener() {
            @Override
            public void onSuccess(PlugPagTransactionResult transactionResult) {
              boolean approved =
                transactionResult != null
                  && transactionResult.getResult() != null
                  && transactionResult.getResult() == PlugPag.RET_OK;
              WritableMap response = buildPaymentResponse(transactionResult, approved);
              currentPlugPag.compareAndSet(plugPag, null);
              emitPaymentProgress("approved", safe(response.getString("message")), null);
              finishAsyncResolve(promise, settled, timeoutRunnable, response);
            }

            @Override
            public void onError(PlugPagTransactionResult transactionResult) {
              WritableMap response = buildPaymentResponse(transactionResult, false);
              String message = safe(response.getString("message"));
              currentPlugPag.compareAndSet(plugPag, null);
              emitPaymentProgress("error", message, null);
              finishAsyncReject(
                promise,
                settled,
                timeoutRunnable,
                "PAGBANK_TRANSACTION_ERROR",
                message.isEmpty() ? "Pagamento não aprovado pela PagBank." : message,
                null
              );
            }

            @Override
            public void onPaymentProgress(PlugPagEventData eventData) {
              String message = eventData != null ? safe(eventData.getCustomMessage()) : "";
              Integer eventCode = eventData != null ? eventData.getEventCode() : null;
              if (message.isEmpty()) {
                message = mapProgressMessage(eventCode);
              }
              emitPaymentProgress("progress", message, eventCode);
            }

            @Override
            public void onPrinterSuccess(PlugPagPrintResult printResult) {
              // not used in payment flow
            }

            @Override
            public void onPrinterError(PlugPagPrintResult printResult) {
              // not used in payment flow
            }
          });
        } catch (PlugPagException sdkError) {
          String errorCode = safe(sdkError.getErrorCode());
          String message = safe(sdkError.getMessage());
          String suffix = errorCode.isEmpty() ? "" : " (codigo: " + errorCode + ")";
          emitPaymentProgress("error", (message.isEmpty() ? "Erro no SDK PagBank." : message) + suffix, null);
          finishAsyncReject(
            promise,
            settled,
            timeoutRunnable,
            "PAGBANK_SDK_ERROR",
            (message.isEmpty() ? "Erro no SDK PagBank." : message) + suffix,
            sdkError
          );
        } catch (Throwable asyncError) {
          emitPaymentProgress(
            "error",
            asyncError.getMessage() == null ? "Falha ao iniciar pagamento na PagBank." : asyncError.getMessage(),
            null
          );
          finishAsyncReject(
            promise,
            settled,
            timeoutRunnable,
            "PAGBANK_ERROR",
            asyncError.getMessage() == null ? "Falha ao iniciar pagamento na PagBank." : asyncError.getMessage(),
            asyncError
          );
        }
      });
    } catch (Throwable e) {
      currentPlugPag.set(null);
      emitPaymentProgress("error", e.getMessage() == null ? "Falha ao executar pagamento na maquininha." : e.getMessage(), null);
      releasePaymentLock();
      promise.reject("PAGBANK_ERROR", e.getMessage() == null ? "Falha ao executar pagamento na maquininha." : e.getMessage(), e);
    }
  }

  private void finishAsyncResolve(
    Promise promise,
    AtomicBoolean settled,
    Runnable timeoutRunnable,
    WritableMap response
  ) {
    if (!settled.compareAndSet(false, true)) {
      return;
    }
    mainHandler.removeCallbacks(timeoutRunnable);
    releasePaymentLock();
    promise.resolve(response);
  }

  private void finishAsyncReject(
    Promise promise,
    AtomicBoolean settled,
    Runnable timeoutRunnable,
    String code,
    String message,
    Throwable error
  ) {
    if (!settled.compareAndSet(false, true)) {
      return;
    }
    mainHandler.removeCallbacks(timeoutRunnable);
    releasePaymentLock();
    if (error == null) {
      promise.reject(code, message);
    } else {
      promise.reject(code, message, error);
    }
  }

  private WritableMap buildPaymentResponse(PlugPagTransactionResult result, boolean forceApproved) {
    WritableMap response = Arguments.createMap();
    if (result == null) {
      response.putBoolean("approved", false);
      response.putInt("result", -1);
      response.putString("resultLabel", "EMPTY_RESULT");
      response.putString("errorCode", "");
      response.putString("message", forceApproved ? "Pagamento aprovado." : "Pagamento nao aprovado.");
      response.putString("nsu", "");
      response.putString("transactionCode", "");
      response.putString("transactionId", "");
      response.putString("hostNsu", "");
      response.putString("autoCode", "");
      response.putString("amount", "");
      response.putString("typeTransaction", "");
      response.putString("userReference", "");
      return response;
    }

    Integer resultCode = result.getResult();
    String errorCode = safe(result.getErrorCode());
    String message = safe(result.getMessage());
    boolean approvedByCode = resultCode != null && resultCode == PlugPag.RET_OK;
    boolean approvedByErrorCode = errorCode.isEmpty() || "0000".equals(errorCode);
    boolean approved = forceApproved || (approvedByCode && approvedByErrorCode);

    response.putBoolean("approved", approved);
    response.putInt("result", resultCode == null ? -1 : resultCode);
    response.putString("resultLabel", mapResultCode(resultCode));
    response.putString("errorCode", errorCode);
    response.putString(
      "message",
      message.isEmpty()
        ? (approved ? "Pagamento aprovado." : buildDeniedMessage(resultCode, errorCode, "Pagamento nao aprovado."))
        : message
    );
    response.putString("nsu", safe(result.getNsu()));
    response.putString("transactionCode", safe(result.getTransactionCode()));
    response.putString("transactionId", safe(result.getTransactionId()));
    response.putString("hostNsu", safe(result.getHostNsu()));
    response.putString("autoCode", safe(result.getAutoCode()));
    response.putString("amount", safe(result.getAmount()));
    response.putString("typeTransaction", safe(result.getTypeTransaction()));
    response.putString("userReference", safe(result.getUserReference()));
    return response;
  }

  private void releasePaymentLock() {
    paymentStartedAtMs.set(0L);
    paymentInProgress.set(false);
  }

  private void recoverStalePaymentLock() {
    if (!paymentInProgress.get()) {
      return;
    }

    long startedAt = paymentStartedAtMs.get();
    long age = startedAt > 0L ? System.currentTimeMillis() - startedAt : Long.MAX_VALUE;
    if (startedAt <= 0L || age > PAYMENT_LOCK_STALE_MS) {
      Log.w(TAG, "Bloqueio PagBank antigo detectado. Liberando lock para nova tentativa.");
      releasePaymentLock();
    }
  }

  private String buildDeniedMessage(Integer resultCode, String errorCode, String fallback) {
    StringBuilder builder = new StringBuilder(fallback == null ? "Pagamento nao aprovado." : fallback.trim());
    if (!safe(errorCode).isEmpty()) {
      builder.append(" Codigo: ").append(safe(errorCode)).append(".");
    }
    if (resultCode != null) {
      builder.append(" Resultado: ").append(resultCode).append(" (").append(mapResultCode(resultCode)).append(").");
    }
    return builder.toString().trim();
  }

  private String mapResultCode(Integer code) {
    if (code == null) return "UNKNOWN";
    if (code == PlugPag.RET_OK) return "RET_OK";
    if (code == PlugPag.DOING_TRANSACTION) return "DOING_TRANSACTION";
    if (code == PlugPag.POS_NOT_READY) return "POS_NOT_READY";
    if (code == PlugPag.PINPAD_NOT_INITIALIZED) return "PINPAD_NOT_INITIALIZED";
    if (code == PlugPag.TIMEOUT_REACHED) return "TIMEOUT_REACHED";
    if (code == PlugPag.AUTHENTICATION_FAILED) return "AUTHENTICATION_FAILED";
    if (code == PlugPag.OPERATION_ABORTED) return "OPERATION_ABORTED";
    if (code == PlugPag.TRANSACTION_DENIED) return "TRANSACTION_DENIED";
    if (code == PlugPag.INVALID_PARAMETER) return "INVALID_PARAMETER";
    return "RESULT_" + code;
  }

  private String safe(String value) {
    return value == null ? "" : value;
  }

  private void emitPaymentProgress(String status, String message, Integer eventCode) {
    ReactApplicationContext context = getReactApplicationContext();
    if (context == null || !context.hasActiveReactInstance()) {
      return;
    }

    WritableMap event = Arguments.createMap();
    event.putString("status", safe(status));
    event.putString("message", safe(message));
    if (eventCode != null) {
      event.putInt("eventCode", eventCode);
    }

    context
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
      .emit(EVENT_PROGRESS, event);
  }

  private String mapProgressMessage(Integer eventCode) {
    if (eventCode == null) return "Processando pagamento...";

    switch (eventCode) {
      case 1:
        return "Aguardando cartão ou aproximação...";
      case 2:
        return "Cartão detectado. Aguarde...";
      case 3:
        return "Processando transação...";
      case 4:
        return "Retire o cartão, se necessário.";
      case 5:
        return "Aguardando confirmação da PagBank...";
      case 6:
        return "Finalizando pagamento...";
      case 7:
        return "Retire o cartão.";
      default:
        return "Processando pagamento...";
    }
  }

  // Procura um comando {type:'image', imagePath|imageData} (base64) no
  // conteudo JSON vindo do servidor. Retorna null quando o conteudo e texto.
  private String extractReceiptImageBase64(String content) {
    String trimmed = content == null ? "" : content.trim();
    if (!trimmed.startsWith("[") && !trimmed.startsWith("{")) {
      return null;
    }

    try {
      Object parsed = new JSONTokener(trimmed).nextValue();
      return findImageBase64(parsed);
    } catch (Throwable ignored) {
      return null;
    }
  }

  private String findImageBase64(Object payload) {
    if (payload instanceof JSONArray) {
      JSONArray array = (JSONArray) payload;
      for (int index = 0; index < array.length(); index++) {
        String found = findImageBase64(array.opt(index));
        if (found != null) {
          return found;
        }
      }
      return null;
    }

    if (payload instanceof JSONObject) {
      JSONObject command = (JSONObject) payload;
      if (command.has("commands")) {
        return findImageBase64(command.optJSONArray("commands"));
      }
      if (command.has("data")) {
        return findImageBase64(command.optJSONArray("data"));
      }

      String type = safe(command.optString("type")).toLowerCase(Locale.ROOT);
      if ("image".equals(type)) {
        String base64 = safe(command.optString("imagePath"));
        if (base64.trim().isEmpty()) {
          base64 = safe(command.optString("imageData"));
        }
        return base64.trim().isEmpty() ? null : base64.trim();
      }
    }

    return null;
  }

  // Decodifica a imagem base64, redimensiona para a largura do papel e grava
  // como PNG para o doPrint da PagBank.
  private File buildBase64ImageFile(String imageBase64) throws IOException {
    byte[] bytes;
    try {
      bytes = Base64.decode(imageBase64, Base64.DEFAULT);
    } catch (Throwable error) {
      throw new IOException("Imagem de impressão inválida (base64).");
    }

    Bitmap source = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
    if (source == null || source.getWidth() <= 0 || source.getHeight() <= 0) {
      throw new IOException("Imagem de impressão inválida.");
    }

    Bitmap scaled = source;
    if (source.getWidth() != RECEIPT_WIDTH_PX) {
      int targetHeight = Math.max(1, Math.round(source.getHeight() * (RECEIPT_WIDTH_PX / (float) source.getWidth())));
      scaled = Bitmap.createScaledBitmap(source, RECEIPT_WIDTH_PX, targetHeight, true);
    }

    File baseDir = getReactApplicationContext().getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS);
    if (baseDir == null) {
      baseDir = getReactApplicationContext().getFilesDir();
    }

    File printDir = new File(baseDir, "print");
    if (!printDir.exists() && !printDir.mkdirs()) {
      throw new IOException("Não foi possível criar a pasta de impressão.");
    }

    File imageFile = new File(printDir, "print-" + System.currentTimeMillis() + ".png");
    try (FileOutputStream outputStream = new FileOutputStream(imageFile)) {
      scaled.compress(Bitmap.CompressFormat.PNG, 100, outputStream);
      outputStream.flush();
    } finally {
      if (scaled != source && !scaled.isRecycled()) {
        scaled.recycle();
      }
      if (!source.isRecycled()) {
        source.recycle();
      }
    }

    return imageFile;
  }

  private File buildReceiptImage(String content, int columns, String title) throws IOException {
    File baseDir = getReactApplicationContext().getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS);
    if (baseDir == null) {
      baseDir = getReactApplicationContext().getFilesDir();
    }

    File printDir = new File(baseDir, "print");
    if (!printDir.exists() && !printDir.mkdirs()) {
      throw new IOException("Não foi possível criar a pasta de impressão.");
    }

    Bitmap bitmap = renderReceiptBitmap(content, columns, title);
    File imageFile = new File(printDir, "print-" + System.currentTimeMillis() + ".png");
    try (FileOutputStream outputStream = new FileOutputStream(imageFile)) {
      bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream);
      outputStream.flush();
    } finally {
      bitmap.recycle();
    }

    return imageFile;
  }

  private Bitmap renderReceiptBitmap(String content, int columns, String title) {
    Paint paint = new Paint();
    paint.setColor(Color.BLACK);
    paint.setAntiAlias(false);
    paint.setDither(false);
    paint.setFilterBitmap(false);
    paint.setSubpixelText(false);
    paint.setLinearText(false);
    paint.setFakeBoldText(true);
    paint.setStyle(Paint.Style.FILL_AND_STROKE);
    paint.setStrokeWidth(0.9f);
    paint.setTypeface(Typeface.create(Typeface.MONOSPACE, Typeface.BOLD));
    paint.setTextSize(resolveReceiptTextSize(columns));

    Paint titlePaint = new Paint();
    titlePaint.setColor(Color.BLACK);
    titlePaint.setAntiAlias(false);
    titlePaint.setDither(false);
    titlePaint.setFilterBitmap(false);
    titlePaint.setSubpixelText(false);
    titlePaint.setLinearText(false);
    titlePaint.setFakeBoldText(true);
    titlePaint.setStyle(Paint.Style.FILL_AND_STROKE);
    titlePaint.setStrokeWidth(1.1f);
    titlePaint.setTypeface(Typeface.create(Typeface.MONOSPACE, Typeface.BOLD));
    titlePaint.setTextSize(paint.getTextSize() + 6f);

    int availableWidth = RECEIPT_WIDTH_PX - (RECEIPT_MARGIN_PX * 2);
    List<String> lines = wrapReceiptLines(content, paint, availableWidth);
    Paint.FontMetrics textMetrics = paint.getFontMetrics();
    Paint.FontMetrics titleMetrics = titlePaint.getFontMetrics();
    int lineHeight = Math.max(30, (int) Math.ceil((textMetrics.descent - textMetrics.ascent) + 10f));
    int titleHeight = Math.max(38, (int) Math.ceil((titleMetrics.descent - titleMetrics.ascent) + 14f));
    int height = (RECEIPT_MARGIN_PX * 2) + titleHeight + (Math.max(1, lines.size()) * lineHeight);

    Bitmap bitmap = Bitmap.createBitmap(RECEIPT_WIDTH_PX, height, Bitmap.Config.ARGB_8888);
    Canvas canvas = new Canvas(bitmap);
    canvas.drawColor(Color.WHITE);

    float currentY = RECEIPT_MARGIN_PX - titleMetrics.ascent;
    drawReceiptText(canvas, safe(title).isEmpty() ? "RPCheff" : safe(title), RECEIPT_MARGIN_PX, currentY, titlePaint);
    currentY += titleHeight;

    for (String line : lines) {
      drawReceiptText(canvas, line, RECEIPT_MARGIN_PX, currentY - textMetrics.ascent, paint);
      currentY += lineHeight;
    }

    return toMonochrome(bitmap);
  }

  private List<String> wrapReceiptLines(String content, Paint paint, int maxWidth) {
    List<String> lines = new ArrayList<>();
    String normalized = safe(content).replace("\r\n", "\n").replace('\r', '\n');
    String[] sourceLines = normalized.split("\n", -1);

    for (String sourceLine : sourceLines) {
      String current = sourceLine == null ? "" : sourceLine;
      if (current.isEmpty()) {
        lines.add(" ");
        continue;
      }

      while (!current.isEmpty()) {
        int count = paint.breakText(current, true, maxWidth, null);
        if (count <= 0 || count >= current.length()) {
          lines.add(current);
          current = "";
        } else {
          lines.add(current.substring(0, count));
          current = current.substring(count);
        }
      }
    }

    if (lines.isEmpty()) {
      lines.add(" ");
    }

    return lines;
  }

  private float resolveReceiptTextSize(int columns) {
    if (columns >= 48) {
      return 24f;
    }
    if (columns >= 40) {
      return 26f;
    }
    return 30f;
  }

  private Bitmap toMonochrome(Bitmap source) {
    Bitmap output = Bitmap.createBitmap(source.getWidth(), source.getHeight(), Bitmap.Config.ARGB_8888);

    for (int y = 0; y < source.getHeight(); y++) {
      for (int x = 0; x < source.getWidth(); x++) {
        int pixel = source.getPixel(x, y);
        int red = Color.red(pixel);
        int green = Color.green(pixel);
        int blue = Color.blue(pixel);
        int luminance = (red * 299 + green * 587 + blue * 114) / 1000;
        output.setPixel(x, y, luminance < MONOCHROME_THRESHOLD ? Color.BLACK : Color.WHITE);
      }
    }

    source.recycle();
    return output;
  }

  private void drawReceiptText(Canvas canvas, String text, float x, float baseline, Paint paint) {
    canvas.drawText(text, x, baseline, paint);
    canvas.drawText(text, x + 0.8f, baseline, paint);
  }

  private int resolveTransactionType(String transactionType) {
    if (transactionType == null) return PlugPag.TYPE_DEBITO;
    String normalized = transactionType.trim().toLowerCase(Locale.US);
    switch (normalized) {
      case "credit":
      case "credito":
        return PlugPag.TYPE_CREDITO;
      case "debit":
      case "debito":
        return PlugPag.TYPE_DEBITO;
      case "pix":
        return PlugPag.TYPE_PIX;
      case "voucher":
      case "refeicao":
      case "alimentacao":
        return PlugPag.TYPE_VOUCHER;
      default:
        return -1;
    }
  }

  private int resolveInstallmentType(ReadableMap payload, int transactionType, int installments) {
    if (transactionType != PlugPag.TYPE_CREDITO || installments <= 1) {
      return PlugPag.INSTALLMENT_TYPE_A_VISTA;
    }

    if (payload.hasKey("installmentType")) {
      String value = payload.getString("installmentType");
      if (value != null) {
        String normalized = value.trim().toLowerCase(Locale.US);
        if (normalized.equals("buyer") || normalized.equals("comprador")) {
          return PlugPag.INSTALLMENT_TYPE_PARC_COMPRADOR;
        }
      }
    }

    return PlugPag.INSTALLMENT_TYPE_PARC_VENDEDOR;
  }
}
