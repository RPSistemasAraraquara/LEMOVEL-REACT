package com.rpcheff.plugpag;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.IBinder;
import android.os.Handler;
import android.os.Looper;
import android.os.RemoteException;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import com.sunmi.trans.TransBean;

import java.util.Locale;

import woyou.aidlservice.jiuiv5.ICallback;
import woyou.aidlservice.jiuiv5.IWoyouService;

public class RPCheffStoneModule extends ReactContextBaseJavaModule implements ActivityEventListener {
  private static final String RETURN_SCHEME = "stone-rpmobile";
  private static final String RETURN_SCHEME_CANCEL = "stone-rpmobile-cancel";
  private static final String SUNMI_PRINTER_PACKAGE = "woyou.aidlservice.jiuiv5";
  private static final String SUNMI_PRINTER_ACTION = "woyou.aidlservice.jiuiv5.IWoyouService";
  private static final long DEFAULT_TIMEOUT_MS = 180000L;
  private static final String OPERATION_PAYMENT = "payment";
  private static final String OPERATION_PRINT = "print";
  private static final int SUNMI_PAPER_WIDTH = 384;
  private static final int SUNMI_SIDE_PADDING = 12;
  private static final int SUNMI_BITMAP_TYPE_BLACK_AND_WHITE = 1;
  private static final int SUNMI_SEPARATOR_HEIGHT = 1;
  private static final int SUNMI_BLANK_LINE_HEIGHT = 1;
  private static final float FONT_SIZE_SMALL = 20f;
  private static final float FONT_SIZE_MEDIUM = 24f;
  private static final float FONT_SIZE_BIG = 30f;
  private static final byte[] ESC_BOLD_ON = new byte[] {0x1B, 0x45, 0x01};
  private static final byte[] ESC_BOLD_OFF = new byte[] {0x1B, 0x45, 0x00};

  private final Handler timeoutHandler = new Handler(Looper.getMainLooper());
  private Promise pendingPromise;
  private Runnable timeoutRunnable;
  private String pendingOperation;
  private IWoyouService sunmiPrinterService;
  private ServiceConnection sunmiPrinterConnection;
  private boolean lastPrintedSeparator;
  private boolean suppressNextSeparator;
  private boolean pendingWaitersHeader;
  private String pendingSummaryMetricLine;

  public RPCheffStoneModule(ReactApplicationContext reactContext) {
    super(reactContext);
    reactContext.addActivityEventListener(this);
  }

  @NonNull
  @Override
  public String getName() {
    return "RPCheffStone";
  }

  @ReactMethod
  public void executePayment(ReadableMap payload, Promise promise) {
    if (pendingPromise != null) {
      promise.reject("STONE_BUSY", "Existe um pagamento Stone em andamento.");
      return;
    }

    int amount = payload.hasKey("amount") ? payload.getInt("amount") : 0;
    if (amount <= 0) {
      promise.reject("STONE_INVALID_AMOUNT", "Valor de pagamento invalido.");
      return;
    }

    String transactionType = resolveTransactionType(payload);
    if (transactionType == null) {
      promise.reject("STONE_INVALID_TYPE", "Tipo de transacao invalido para Stone.");
      return;
    }

    int installments = payload.hasKey("installments") ? Math.max(1, payload.getInt("installments")) : 1;
    String installmentType = resolveInstallmentType(payload, transactionType, installments);
    String orderId = payload.hasKey("orderId") ? payload.getString("orderId") : String.valueOf(System.currentTimeMillis());

    Uri.Builder uriBuilder = new Uri.Builder()
      .scheme("payment-app")
      .authority("pay")
      .appendQueryParameter("return_scheme", RETURN_SCHEME)
      .appendQueryParameter("transaction_type", transactionType)
      .appendQueryParameter("amount", String.valueOf(amount))
      .appendQueryParameter("editable_amount", "false");

    if ("CREDIT".equals(transactionType)) {
      uriBuilder.appendQueryParameter("installment_type", installmentType);
      if (installments > 1) {
        uriBuilder.appendQueryParameter("installment_count", String.valueOf(installments));
      }
    }

    if (orderId != null && !orderId.trim().isEmpty()) {
      uriBuilder.appendQueryParameter("order_id", orderId.trim());
    }

    Intent intent = new Intent(Intent.ACTION_VIEW, uriBuilder.build());
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

    pendingPromise = promise;
    pendingOperation = OPERATION_PAYMENT;
    scheduleTimeout();

    try {
      Activity activity = getCurrentActivity();
      if (activity != null) {
        activity.startActivity(intent);
      } else {
        getReactApplicationContext().startActivity(intent);
      }
    } catch (Throwable error) {
      rejectAndClear("STONE_START_ERROR", error.getMessage() == null ? "Falha ao iniciar Stone." : error.getMessage(), error);
    }
  }

  @ReactMethod
  public void printReceipt(ReadableMap payload, Promise promise) {
    if (pendingPromise != null) {
      promise.reject("STONE_BUSY", "Existe um pagamento Stone em andamento.");
      return;
    }

    String content = payload.hasKey("content") ? safe(payload.getString("content")) : "";
    if (content.isEmpty()) {
      promise.reject("STONE_PRINT_EMPTY", "Conteúdo de impressão vazio.");
      return;
    }

    try {
      pendingPromise = promise;
      pendingOperation = OPERATION_PRINT;
      scheduleTimeout();
      if (!startSunmiPrint(content)) {
        startStonePrinterAppFallback(content);
      }
    } catch (Throwable error) {
      rejectAndClear(
        "STONE_PRINT_ERROR",
        error.getMessage() == null ? "Falha ao iniciar impressão na Stone." : error.getMessage(),
        error
      );
    }
  }

  private boolean startSunmiPrint(final String content) {
    final ReactApplicationContext context = getReactApplicationContext();
    final Intent intent = new Intent();
    intent.setPackage(SUNMI_PRINTER_PACKAGE);
    intent.setAction(SUNMI_PRINTER_ACTION);

    unbindSunmiPrinter();
    sunmiPrinterConnection = new ServiceConnection() {
      @Override
      public void onServiceConnected(ComponentName name, IBinder service) {
        sunmiPrinterService = IWoyouService.Stub.asInterface(service);
        try {
          executeSunmiPrint(content);
        } catch (Throwable error) {
          rejectSunmiPrint(
            "STONE_PRINT_ERROR",
            error.getMessage() == null ? "Falha ao imprimir pela impressora interna da Stone." : error.getMessage(),
            error
          );
        }
      }

      @Override
      public void onServiceDisconnected(ComponentName name) {
        sunmiPrinterService = null;
        if (pendingPromise != null && OPERATION_PRINT.equals(pendingOperation)) {
          rejectSunmiPrint(
            "STONE_PRINTER_DISCONNECTED",
            "Serviço da impressora da Stone foi desconectado.",
            null
          );
        }
      }
    };

    try {
      final boolean bound = context.bindService(intent, sunmiPrinterConnection, Context.BIND_AUTO_CREATE);
      if (!bound) {
        unbindSunmiPrinter();
      }
      return bound;
    } catch (Throwable error) {
      unbindSunmiPrinter();
      return false;
    }
  }

  private void startStonePrinterAppFallback(String content) throws Throwable {
    Uri uri = new Uri.Builder()
      .scheme("printer-app")
      .authority("print")
      .appendQueryParameter("SCHEME_RETURN", RETURN_SCHEME)
      .appendQueryParameter("PRINTABLE_CONTENT", content)
      .appendQueryParameter("SHOW_FEEDBACK_SCREEN", "false")
      .build();

    Intent intent = new Intent(Intent.ACTION_VIEW, uri);
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

    Activity activity = getCurrentActivity();
    if (activity != null) {
      activity.startActivity(intent);
    } else {
      getReactApplicationContext().startActivity(intent);
    }
  }

  private void executeSunmiPrint(String content) throws RemoteException, JSONException {
    if (sunmiPrinterService == null) {
      throw new RemoteException("Serviço Sunmi indisponível.");
    }

    int printerState = sunmiPrinterService.updatePrinterState();
    if (printerState != 1 && printerState != 2) {
      throw new RemoteException(resolvePrinterStateMessage(printerState));
    }

    sunmiPrinterService.printerInit(null);
    sunmiPrinterService.enterPrinterBuffer(true);
    printSunmiContent(content);
    sunmiPrinterService.lineWrap(3, null);
    sunmiPrinterService.exitPrinterBufferWithCallback(true, createSunmiPrintCallback());
  }

  private void printSunmiContent(String content) throws RemoteException, JSONException {
    String raw = safePreserve(content);
    if (raw.trim().isEmpty()) {
      return;
    }

    lastPrintedSeparator = false;
    suppressNextSeparator = false;
    pendingWaitersHeader = false;
    pendingSummaryMetricLine = null;
    String trimmed = raw.trim();
    if (trimmed.startsWith("[") || trimmed.startsWith("{")) {
      try {
        Object parsed = new JSONTokener(trimmed).nextValue();
        printSunmiJsonPayload(parsed);
        flushPendingSummaryMetric("left", "medium", "");
        return;
      } catch (JSONException ignored) {
      }
    }

    printSunmiPlainText(raw);
    flushPendingSummaryMetric("left", "medium", "");
  }

  private void printSunmiJsonPayload(Object payload) throws RemoteException, JSONException {
    if (payload == null) {
      return;
    }

    if (payload instanceof JSONArray) {
      JSONArray array = (JSONArray) payload;
      for (int index = 0; index < array.length(); index++) {
        printSunmiJsonPayload(array.opt(index));
      }
      return;
    }

    if (payload instanceof JSONObject) {
      JSONObject command = (JSONObject) payload;

      if (command.has("commands")) {
        printSunmiJsonPayload(command.optJSONArray("commands"));
        return;
      }

      if (command.has("data")) {
        printSunmiJsonPayload(command.optJSONArray("data"));
        return;
      }

      String type = safeLower(command.optString("type"));
      String text = safePreserve(command.optString("content"));
      if ("line".equals(type) && text.trim().isEmpty()) {
        text = "--------------------------------";
      }

      printSunmiStyledLine(
        text,
        command.optString("align"),
        command.optString("size"),
        command.optString("style")
      );
      return;
    }

    if (payload instanceof String) {
      printSunmiPlainText((String) payload);
    }
  }

  private void printSunmiPlainText(String content) throws RemoteException {
    String normalized = safePreserve(content).replace("\r\n", "\n").replace('\r', '\n');
    String[] lines = normalized.split("\n", -1);
    for (String line : lines) {
      printSunmiStyledLine(line, "left", "medium", "");
    }
  }

  private void printSunmiStyledLine(String text, String align, String size, String style) throws RemoteException {
    String value = safePreserve(text);
    String trimmedValue = value.trim();

    if (pendingSummaryMetricLine != null) {
      if (isPeopleCountLine(trimmedValue)) {
        printSunmiSingleLine(pendingSummaryMetricLine + "    " + trimmedValue, align, size, style);
        pendingSummaryMetricLine = null;
        lastPrintedSeparator = false;
        return;
      }

      flushPendingSummaryMetric(align, size, style);
    }

    if (value.trim().isEmpty()) {
      return;
    }

    if (isConferenceTypeLine(trimmedValue)) {
      return;
    }

    if ("ITENS".equals(trimmedValue.toUpperCase(Locale.ROOT))) {
      return;
    }

    if (isConferenceLine(trimmedValue)) {
      printSunmiSingleLine(normalizeConferenceLine(trimmedValue), "center", "medium", "bold");
      lastPrintedSeparator = false;
      suppressNextSeparator = true;
      return;
    }

    if (isItemsCountLine(trimmedValue)) {
      pendingSummaryMetricLine = trimmedValue;
      return;
    }

    if (isPendingValueLine(value)) {
      printSunmiSingleLine(normalizePendingValueLine(value), "center", "medium", "bold");
      lastPrintedSeparator = false;
      suppressNextSeparator = true;
      return;
    }

    if (isWaiterHeaderLine(trimmedValue)) {
      pendingWaitersHeader = true;
      lastPrintedSeparator = false;
      suppressNextSeparator = false;
      return;
    }

    if (pendingWaitersHeader) {
      if (looksLikeSeparator(value)) {
        return;
      }
      printSunmiSingleLine("GARCONS: " + trimmedValue, "center", "small", "bold");
      pendingWaitersHeader = false;
      lastPrintedSeparator = false;
      suppressNextSeparator = true;
      return;
    }

    boolean separator = looksLikeSeparator(value);
    if (separator && (lastPrintedSeparator || suppressNextSeparator)) {
      suppressNextSeparator = false;
      return;
    }

    printSunmiSingleLine(value, align, size, style);
    lastPrintedSeparator = separator;
    suppressNextSeparator = !separator && shouldSuppressFollowingSeparator(trimmedValue);
  }

  private void flushPendingSummaryMetric(String align, String size, String style) throws RemoteException {
    if (pendingSummaryMetricLine == null) {
      return;
    }
    printSunmiSingleLine(pendingSummaryMetricLine, align, size, style);
    pendingSummaryMetricLine = null;
    lastPrintedSeparator = false;
  }

  private void printSunmiSingleLine(String text, String align, String size, String style) throws RemoteException {
    String value = safePreserve(text);

    Bitmap bitmap = null;
    try {
      bitmap = renderReceiptLineBitmap(value, align, size, style);
      sunmiPrinterService.printBitmapCustom(bitmap, SUNMI_BITMAP_TYPE_BLACK_AND_WHITE, null);
    } catch (Throwable bitmapError) {
      sunmiPrinterService.setAlignment(mapAlignment(align), null);
      sunmiPrinterService.setFontSize(mapFontSize(size), null);
      sunmiPrinterService.sendRAWData(isBold(style) ? ESC_BOLD_ON : ESC_BOLD_OFF, null);
      sunmiPrinterService.printText(value + "\n", null);
      if (isBold(style)) {
        sunmiPrinterService.sendRAWData(ESC_BOLD_OFF, null);
      }
    } finally {
      if (bitmap != null && !bitmap.isRecycled()) {
        bitmap.recycle();
      }
    }
  }

  private Bitmap renderReceiptLineBitmap(String text, String align, String size, String style) {
    final String printableText = safePreserve(text).replace('\t', ' ').trim();
    final float fontSize = mapFontSize(size);
    final boolean bold = isBold(style);
    final boolean separator = looksLikeSeparator(printableText);
    final boolean sectionTitle = isSectionTitle(printableText);
    final boolean compactHeader = isCompactHeaderLine(printableText);
    final boolean compactInfoLine = isCompactInfoLine(printableText);
    final boolean summaryMetric = isSummaryMetricLine(printableText);
    final boolean monetaryHighlight = isMonetaryHighlightLine(printableText);

    Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.DITHER_FLAG);
    paint.setColor(Color.BLACK);
    paint.setTextSize(fontSize);
    paint.setTypeface(bold ? Typeface.create(Typeface.DEFAULT, Typeface.BOLD) : Typeface.create(Typeface.DEFAULT, Typeface.NORMAL));
    paint.setFakeBoldText(true);
    paint.setStyle(Paint.Style.FILL_AND_STROKE);
    paint.setStrokeWidth(bold ? 0.9f : 0.45f);
    paint.setSubpixelText(true);

    if (separator) {
      Bitmap bitmap = Bitmap.createBitmap(SUNMI_PAPER_WIDTH, SUNMI_SEPARATOR_HEIGHT, Bitmap.Config.ARGB_8888);
      Canvas canvas = new Canvas(bitmap);
      canvas.drawColor(Color.WHITE);
      Paint linePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
      linePaint.setColor(Color.BLACK);
      linePaint.setStrokeWidth(3f);
      int y = SUNMI_SEPARATOR_HEIGHT / 2;
      canvas.drawLine(SUNMI_SIDE_PADDING, y, SUNMI_PAPER_WIDTH - SUNMI_SIDE_PADDING, y, linePaint);
      return bitmap;
    }

    Paint.FontMetrics fontMetrics = paint.getFontMetrics();
    int textHeight = (int) Math.ceil(fontMetrics.descent - fontMetrics.ascent);
    int extraVerticalPadding = compactInfoLine ? 2 : 4;
    if (compactHeader) {
      extraVerticalPadding += 0;
    } else if (sectionTitle) {
      extraVerticalPadding += 0;
    }
    if (monetaryHighlight) {
      extraVerticalPadding += 0;
    }
    if (summaryMetric) {
      extraVerticalPadding += 0;
    }
    int minHeight = 16;
    if (compactInfoLine) {
      minHeight = 12;
    } else if (compactHeader) {
      minHeight = 14;
    } else if (sectionTitle || monetaryHighlight) {
      minHeight = 18;
    } else if (summaryMetric) {
      minHeight = 14;
    }
    int bitmapHeight = Math.max(textHeight + extraVerticalPadding, minHeight);

    Bitmap bitmap = Bitmap.createBitmap(SUNMI_PAPER_WIDTH, bitmapHeight, Bitmap.Config.ARGB_8888);
    Canvas canvas = new Canvas(bitmap);
    canvas.drawColor(Color.WHITE);

    float textWidth = paint.measureText(printableText);
    float x = SUNMI_SIDE_PADDING;
    if (mapAlignment(align) == 1) {
      x = Math.max(SUNMI_SIDE_PADDING, (SUNMI_PAPER_WIDTH - textWidth) / 2f);
    } else if (mapAlignment(align) == 2) {
      x = Math.max(SUNMI_SIDE_PADDING, SUNMI_PAPER_WIDTH - SUNMI_SIDE_PADDING - textWidth);
    }

    float baseline = ((bitmapHeight - (fontMetrics.descent - fontMetrics.ascent)) / 2f) - fontMetrics.ascent;
    canvas.drawText(printableText, x, baseline, paint);
    return bitmap;
  }

  private boolean looksLikeSeparator(String text) {
    String trimmed = safePreserve(text).trim();
    if (trimmed.length() < 10) {
      return false;
    }
    return trimmed.matches("^[=\\-]{10,}$");
  }

  private boolean isPendingValueLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return upper.startsWith("VALOR PENDENTE:");
  }

  private String[] splitPendingValueLine(String text) {
    String trimmed = safePreserve(text).trim();
    int separatorIndex = trimmed.indexOf(':');
    if (separatorIndex < 0) {
      return new String[] { trimmed, "" };
    }
    return new String[] {
      trimmed.substring(0, separatorIndex).trim(),
      trimmed.substring(separatorIndex + 1).trim()
    };
  }

  private String normalizePendingValueLine(String text) {
    String[] pendingParts = splitPendingValueLine(text);
    String value = pendingParts[1].trim();
    if (value.isEmpty()) {
      return "PENDENTE";
    }
    return "PENDENTE " + value;
  }

  private boolean isWaiterHeaderLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return "GARÇONS".equals(upper) || "GARCONS".equals(upper);
  }

  private boolean shouldSuppressFollowingSeparator(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return upper.startsWith("FONE:")
      || upper.startsWith("CONFERENCIA ")
      || upper.startsWith("FECHAMENTO:")
      || upper.startsWith("TOTAL R$")
      || upper.startsWith("TOTAL/PESSOA:")
      || upper.startsWith("PENDENTE ")
      || upper.startsWith("GARCONS:")
      || upper.startsWith("GARÇONS:")
      || upper.startsWith("SOLICITADO POR:");
  }

  private boolean isSectionTitle(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return "ITENS".equals(upper)
      || "GARÇONS".equals(upper)
      || upper.startsWith("CONFERENCIA ")
      || upper.startsWith("TOTAL R$")
      || upper.startsWith("MESA ")
      || upper.startsWith("COMANDA ");
  }

  private boolean isCompactHeaderLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return "ITENS".equals(upper)
      || "GARÇONS".equals(upper)
      || upper.startsWith("CONFERENCIA ")
      || upper.startsWith("MESA ")
      || upper.startsWith("COMANDA ");
  }

  private boolean isCompactInfoLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return upper.startsWith("PENDENTE ")
      || upper.startsWith("SOLICITADO POR:");
  }

  private boolean isConferenceLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return upper.startsWith("MESA ")
      || upper.startsWith("COMANDA ");
  }

  private boolean isConferenceTypeLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return upper.startsWith("CONF.");
  }

  private String normalizeConferenceLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    String[] parts = upper.split("\\s+");
    if (parts.length >= 2) {
      if (upper.startsWith("MESA ")) {
        return "CONFERENCIA MESA " + parts[1];
      }
      if (upper.startsWith("COMANDA ")) {
        return "CONFERENCIA COMANDA " + parts[1];
      }
    }
    return "CONFERENCIA";
  }

  private boolean isSummaryMetricLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return upper.startsWith("QTDE ")
      || upper.startsWith("TOTAL/PESSOA");
  }

  private boolean isItemsCountLine(String text) {
    return safePreserve(text).trim().toUpperCase(Locale.ROOT).startsWith("QTDE ITENS");
  }

  private boolean isPeopleCountLine(String text) {
    return safePreserve(text).trim().toUpperCase(Locale.ROOT).startsWith("QTDE PESSOAS");
  }

  private boolean isMonetaryHighlightLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return upper.startsWith("SUB TOTAL")
      || upper.startsWith("SUBTOTAL")
      || upper.startsWith("TAXA SERVIÇO")
      || upper.startsWith("TAXA SERVICO")
      || upper.startsWith("TOTAL R$")
      || upper.startsWith("PENDENTE ")
      || upper.startsWith("VALOR PENDENTE");
  }

  private ICallback createSunmiPrintCallback() {
    return new ICallback.Stub() {
      @Override
      public void onRunResult(boolean isSuccess) {
      }

      @Override
      public void onReturnString(String result) {
      }

      @Override
      public void onRaiseException(int code, String msg) {
        rejectSunmiPrint(
          "STONE_PRINT_ERROR",
          firstNonEmpty(msg, "Falha na impressão da Stone. Código " + code + "."),
          null
        );
      }

      @Override
      public void onPrintResult(int code, String msg) {
        if (code == 0) {
          resolveSunmiPrint(firstNonEmpty(msg, "Impressão concluída na Stone."));
        } else {
          rejectSunmiPrint(
            "STONE_PRINT_ERROR",
            firstNonEmpty(msg, "Falha na impressão da Stone."),
            null
          );
        }
      }
    };
  }

  private void resolveSunmiPrint(final String message) {
    timeoutHandler.post(new Runnable() {
      @Override
      public void run() {
        unbindSunmiPrinter();
        if (pendingPromise == null || !OPERATION_PRINT.equals(pendingOperation)) {
          return;
        }

        WritableMap response = Arguments.createMap();
        response.putBoolean("printed", true);
        response.putString("message", firstNonEmpty(message, "Impressão concluída na Stone."));
        response.putString("operation", "sunmi");
        resolveAndClear(response);
      }
    });
  }

  private void rejectSunmiPrint(final String code, final String message, final Throwable error) {
    timeoutHandler.post(new Runnable() {
      @Override
      public void run() {
        unbindSunmiPrinter();
        if (pendingPromise == null || !OPERATION_PRINT.equals(pendingOperation)) {
          return;
        }
        rejectAndClear(code, message, error);
      }
    });
  }

  private void unbindSunmiPrinter() {
    ReactApplicationContext context = getReactApplicationContext();
    if (sunmiPrinterConnection != null) {
      try {
        context.unbindService(sunmiPrinterConnection);
      } catch (Throwable ignored) {
      }
    }
    sunmiPrinterConnection = null;
    sunmiPrinterService = null;
  }

  private int mapAlignment(String align) {
    String normalized = safeLower(align);
    if ("center".equals(normalized) || "centre".equals(normalized)) {
      return 1;
    }
    if ("right".equals(normalized)) {
      return 2;
    }
    return 0;
  }

  private float mapFontSize(String size) {
    String normalized = safeLower(size);
    if ("big".equals(normalized) || "large".equals(normalized)) {
      return FONT_SIZE_BIG;
    }
    if ("small".equals(normalized)) {
      return FONT_SIZE_SMALL;
    }
    return FONT_SIZE_MEDIUM;
  }

  private boolean isBold(String style) {
    return safeLower(style).contains("bold");
  }

  private String resolvePrinterStateMessage(int state) {
    if (state == 1) return "Impressora pronta.";
    if (state == 2) return "Impressora preparando.";
    if (state == 3) return "Erro de comunicação com a impressora.";
    if (state == 4) return "Impressora sem papel.";
    if (state == 5) return "Impressora superaquecida.";
    if (state == 6) return "Tampa da impressora aberta.";
    if (state == 7) return "Erro no cortador da impressora.";
    if (state == 8) return "Cortador da impressora restaurado.";
    if (state == 9) return "Marca preta não detectada.";
    if (state == 505) return "Nenhuma impressora detectada na Stone.";
    if (state == 507) return "Falha ao atualizar firmware da impressora.";
    return "Estado desconhecido da impressora Stone: " + state + ".";
  }

  @Override
  public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
  }

  @Override
  public void onNewIntent(Intent intent) {
    handleStoneIntent(intent);
  }

  private void handleStoneIntent(Intent intent) {
    if (intent == null || intent.getData() == null) {
      return;
    }

    Uri data = intent.getData();
    String scheme = safeLower(data.getScheme());
    if (!RETURN_SCHEME.equalsIgnoreCase(scheme) && !RETURN_SCHEME_CANCEL.equalsIgnoreCase(scheme)) {
      return;
    }

    String host = safeLower(data.getHost());
    if ("pay-response".equals(host)) {
      if (pendingPromise == null || !OPERATION_PAYMENT.equals(pendingOperation)) {
        return;
      }

      String code = safe(data.getQueryParameter("code"));
      if ("0".equals(code)) {
        WritableMap response = Arguments.createMap();
        response.putBoolean("approved", true);
        response.putString("code", code);
        response.putMap("raw", buildQueryParameterMap(data));

        String transType = safeUpper(firstNonEmpty(
          data.getQueryParameter("type"),
          data.getQueryParameter("transaction_type")
        ));
        response.putString("typeTransaction", transType);
        response.putInt("sfiCodigo", mapStoneTypeToSfi(transType));

        String message = safe(data.getQueryParameter("message"));
        if (message.isEmpty()) {
          message = "Pagamento aprovado via Stone.";
        }
        response.putString("message", message);
        response.putString("nsu", firstNonEmpty(
          data.getQueryParameter("atk"),
          data.getQueryParameter("authorization_code"),
          data.getQueryParameter("authorizationcode"),
          String.valueOf(System.currentTimeMillis())
        ));
        response.putString("authorizationCode", firstNonEmpty(
          data.getQueryParameter("authorization_code"),
          data.getQueryParameter("authorizationcode"),
          ""
        ));
        response.putString("hash_terminal", firstNonEmpty(
          data.getQueryParameter("hash_terminal"),
          data.getQueryParameter("terminal"),
          data.getQueryParameter("terminal_name"),
          data.getQueryParameter("terminalName"),
          data.getQueryParameter("stoneid"),
          data.getQueryParameter("stone_id"),
          ""
        ));
        response.putString("acquirerdocument", firstNonEmpty(
          data.getQueryParameter("acquirerdocument"),
          data.getQueryParameter("acquirerDocument"),
          data.getQueryParameter("acquirer_document"),
          data.getQueryParameter("acquirerDocumentNumber"),
          data.getQueryParameter("acquirer_document_number"),
          data.getQueryParameter("cnpj"),
          data.getQueryParameter("cnpj_credenciadora"),
          data.getQueryParameter("cnpjCredenciadora"),
          data.getQueryParameter("cnpjEC"),
          data.getQueryParameter("cnpj_ec"),
          data.getQueryParameter("merchantDocument"),
          data.getQueryParameter("merchant_document"),
          data.getQueryParameter("merchantCnpj"),
          data.getQueryParameter("merchant_cnpj"),
          data.getQueryParameter("establishmentDocument"),
          data.getQueryParameter("establishment_document"),
          data.getQueryParameter("establishmentCnpj"),
          data.getQueryParameter("establishment_cnpj"),
          data.getQueryParameter("document"),
          data.getQueryParameter("documento"),
          data.getQueryParameter("documentNumber"),
          data.getQueryParameter("document_number"),
          data.getQueryParameter("cpfCnpj"),
          data.getQueryParameter("cpf_cnpj"),
          ""
        ));
        resolveAndClear(response);
      } else {
        rejectAndClear(
          "STONE_DENIED",
          firstNonEmpty(
            data.getQueryParameter("message"),
            data.getQueryParameter("reason"),
            "Pagamento negado pela maquininha Stone."
          ),
          null
        );
      }
      return;
    }

    if ("cancel".equals(host)) {
      if (pendingPromise == null || !OPERATION_PAYMENT.equals(pendingOperation)) {
        return;
      }

      rejectAndClear(
        "STONE_CANCELLED",
        firstNonEmpty(
          data.getQueryParameter("reason"),
          "Operacao cancelada na maquininha Stone."
        ),
        null
      );
      return;
    }

    if ("print".equals(host) || "reprint".equals(host)) {
      if (pendingPromise == null || !OPERATION_PRINT.equals(pendingOperation)) {
        return;
      }

      WritableMap response = Arguments.createMap();
      response.putBoolean("printed", true);
      response.putString(
        "message",
        firstNonEmpty(
          data.getQueryParameter("DEEPLINK_RETURN"),
          data.getQueryParameter("message"),
          "Impressão concluída na Stone."
        )
      );
      response.putString("operation", host);
      resolveAndClear(response);
      return;
    }

  }

  private void scheduleTimeout() {
    clearTimeout();
    timeoutRunnable = new Runnable() {
      @Override
      public void run() {
        rejectAndClear("STONE_TIMEOUT", "Tempo esgotado aguardando retorno da Stone.", null);
      }
    };
    timeoutHandler.postDelayed(timeoutRunnable, DEFAULT_TIMEOUT_MS);
  }

  private void clearTimeout() {
    if (timeoutRunnable != null) {
      timeoutHandler.removeCallbacks(timeoutRunnable);
      timeoutRunnable = null;
    }
  }

  private void resolveAndClear(WritableMap result) {
    Promise local = pendingPromise;
    pendingPromise = null;
    pendingOperation = null;
    clearTimeout();
    if (local != null) {
      local.resolve(result);
    }
  }

  private void rejectAndClear(String code, String message, Throwable error) {
    Promise local = pendingPromise;
    pendingPromise = null;
    pendingOperation = null;
    clearTimeout();
    if (local != null) {
      if (error != null) {
        local.reject(code, message, error);
      } else {
        local.reject(code, message);
      }
    }
  }

  private String resolveTransactionType(ReadableMap payload) {
    if (payload.hasKey("transactionType")) {
      String value = safeLower(payload.getString("transactionType"));
      if (value.equals("credit") || value.equals("credito")) return "CREDIT";
      if (value.equals("debit") || value.equals("debito")) return "DEBIT";
      if (value.equals("pix")) return "PIX";
      if (value.equals("voucher") || value.equals("refeicao") || value.equals("alimentacao")) return "VOUCHER";
    }

    if (payload.hasKey("sfiCodigo")) {
      int sfi = payload.getInt("sfiCodigo");
      if (sfi == 4) return "DEBIT";
      if (sfi == 17) return "PIX";
      if (sfi == 6 || sfi == 11) return "VOUCHER";
      return "CREDIT";
    }

    return "CREDIT";
  }

  private String resolveInstallmentType(ReadableMap payload, String transactionType, int installments) {
    if (!"CREDIT".equals(transactionType) || installments <= 1) {
      return "NONE";
    }

    if (payload.hasKey("installmentType")) {
      String value = safeLower(payload.getString("installmentType"));
      if (value.equals("issuer") || value.equals("comprador") || value.equals("buyer")) {
        return "ISSUER";
      }
    }

    return "MERCHANT";
  }

  private int mapStoneTypeToSfi(String type) {
    if ("DEBIT".equals(type)) return 4;
    if ("PIX".equals(type)) return 17;
    if ("VOUCHER".equals(type)) return 6;
    return 3;
  }

  private String safe(String value) {
    return value == null ? "" : value.trim();
  }

  private WritableMap buildQueryParameterMap(Uri data) {
    WritableMap result = Arguments.createMap();
    if (data == null) return result;

    try {
      for (String key : data.getQueryParameterNames()) {
        result.putString(key, safe(data.getQueryParameter(key)));
      }
    } catch (UnsupportedOperationException ignored) {
      return result;
    }

    return result;
  }

  private String safePreserve(String value) {
    return value == null ? "" : value;
  }

  private String safeLower(String value) {
    return safe(value).toLowerCase();
  }

  private String safeUpper(String value) {
    return safe(value).toUpperCase();
  }

  private String firstNonEmpty(String... values) {
    if (values == null) return "";
    for (String value : values) {
      String current = safe(value);
      if (!current.isEmpty()) {
        return current;
      }
    }
    return "";
  }
}
