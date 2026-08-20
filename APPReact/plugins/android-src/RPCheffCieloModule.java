package com.rpcheff.plugpag;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.util.Base64;

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

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class RPCheffCieloModule extends ReactContextBaseJavaModule implements ActivityEventListener {
  private static final String ORDERPAY_CALLBACK = "orderpay://response";
  private static final String PRINT_CALLBACK = "print://response";
  private static final String DEFAULT_ACCESS_TOKEN = "u8JCKBRu0lCQ5Bmf33qll9G3bqMe1PUKEVPIVXrN6j3ASG5Lho";
  private static final String DEFAULT_CLIENT_ID = "gN5rjqQSVx77WLk8Y3lnIh5e1D81Znft2wPoHmfcbSzOtPwgUp";
  private static final String DEFAULT_EMAIL = "rafael@rpsistema.com.br";
  private static final long DEFAULT_TIMEOUT_MS = 180000L;
  private static final int RECEIPT_WIDTH_PX = 384;
  private static final int RECEIPT_MARGIN_PX = 16;
  private static final int MONOCHROME_THRESHOLD = 250;
  private static final int RECEIPT_WORK_HEIGHT_PX = 8000;
  private static final int STRUCTURED_RECEIPT_MARGIN_PX = 8;
  private static final int STRUCTURED_RECEIPT_LINE_SPACING_PX = 6;
  private static final int STRUCTURED_RECEIPT_BOTTOM_PADDING_PX = 180;
  private static final float STRUCTURED_IMAGE_MAX_WIDTH_RATIO = 0.95f;
  private static final int RECEIPT_SIDE_PADDING_PX = 8;
  private static final int RECEIPT_SEPARATOR_HEIGHT_PX = 14;
  private static final float RECEIPT_FONT_SIZE_SMALL = 24f;
  private static final float RECEIPT_FONT_SIZE_MEDIUM = 32f;
  private static final float RECEIPT_FONT_SIZE_BIG = 40f;

  private final Handler timeoutHandler = new Handler(Looper.getMainLooper());
  private Promise pendingPromise;
  private Runnable timeoutRunnable;
  private String lastPaymentCode = "CREDITO_AVISTA";
  private boolean lastStructuredSeparator = false;
  private boolean suppressNextStructuredSeparator = false;
  private boolean pendingStructuredWaitersHeader = false;
  private String pendingStructuredSummaryMetricLine = null;

  private static final class ReceiptElement {
    private final String type;
    private final String content;
    private final String align;
    private final String size;
    private final String style;
    private final String imageData;

    private ReceiptElement(String type, String content, String align, String size, String style, String imageData) {
      this.type = type;
      this.content = content;
      this.align = align;
      this.size = size;
      this.style = style;
      this.imageData = imageData;
    }
  }

  public RPCheffCieloModule(ReactApplicationContext reactContext) {
    super(reactContext);
    reactContext.addActivityEventListener(this);
  }

  @NonNull
  @Override
  public String getName() {
    return "RPCheffCielo";
  }

  @ReactMethod
  public void executePayment(ReadableMap payload, Promise promise) {
    if (pendingPromise != null) {
      promise.reject("CIELO_BUSY", "Existe um pagamento Cielo em andamento.");
      return;
    }

    int amount = payload.hasKey("amount") ? payload.getInt("amount") : 0;
    if (amount <= 0) {
      promise.reject("CIELO_INVALID_AMOUNT", "Valor de pagamento invalido.");
      return;
    }

    String paymentCode = resolvePaymentCode(payload);
    if (paymentCode == null || paymentCode.isEmpty()) {
      promise.reject("CIELO_INVALID_TYPE", "Tipo de pagamento invalido para Cielo.");
      return;
    }
    lastPaymentCode = paymentCode;

    int installments = payload.hasKey("installments") ? Math.max(0, payload.getInt("installments")) : 0;
    int quantity = payload.hasKey("quantity") ? Math.max(1, payload.getInt("quantity")) : 1;
    String reference = resolvePayloadString(payload, "reference", "orderId", String.valueOf(System.currentTimeMillis()));
    String itemName = resolvePayloadString(payload, "itemName", "methodDescription", "Geral");
    String itemDescription = resolvePayloadString(payload, "itemDescription", "methodDescription", itemName);
    String unitOfMeasure = resolvePayloadString(payload, "unitOfMeasure", "unitMeasure", "unidade");
    String itemSku = resolvePayloadMethodCode(payload, "sku", "methodCode", "1");
    int unitPrice = Math.max(1, amount / Math.max(1, quantity));

    try {
      JSONObject request = new JSONObject();
      request.put("accessToken", resolvePayloadString(payload, "accessToken", null, DEFAULT_ACCESS_TOKEN));
      request.put("clientID", resolvePayloadString(payload, "clientID", "clientId", DEFAULT_CLIENT_ID));
      request.put("reference", reference);
      request.put("email", resolvePayloadString(payload, "email", null, DEFAULT_EMAIL));
      request.put("installments", installments);
      request.put("paymentCode", paymentCode);
      request.put("value", String.valueOf(amount));

      JSONArray items = new JSONArray();
      JSONObject item = new JSONObject();
      item.put("name", itemName);
      item.put("description", itemDescription);
      item.put("sku", itemSku);
      item.put("reference", reference);
      item.put("quantity", quantity);
      item.put("unitOfMeasure", unitOfMeasure);
      item.put("unitPrice", unitPrice);
      items.put(item);
      request.put("items", items);

      String encoded = Base64.encodeToString(request.toString().getBytes(StandardCharsets.UTF_8), Base64.NO_WRAP);
      Uri uri = new Uri.Builder()
        .scheme("lio")
        .authority("payment")
        .appendQueryParameter("request", encoded)
        .appendQueryParameter("urlCallback", ORDERPAY_CALLBACK)
        .build();

      Intent intent = new Intent(Intent.ACTION_VIEW, uri);
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

      pendingPromise = promise;
      scheduleTimeout();

      Activity activity = getCurrentActivity();
      if (activity != null) {
        activity.startActivity(intent);
      } else {
        getReactApplicationContext().startActivity(intent);
      }
    } catch (Throwable error) {
      rejectAndClear("CIELO_START_ERROR", error.getMessage() == null ? "Falha ao iniciar Cielo." : error.getMessage(), error);
    }
  }

  @ReactMethod
  public void printReceipt(ReadableMap payload, Promise promise) {
    String content = payload.hasKey("content") ? safe(payload.getString("content")) : "";
    if (content.isEmpty()) {
      promise.reject("CIELO_PRINT_EMPTY", "Conteúdo de impressão vazio.");
      return;
    }

    int columns = payload.hasKey("columns") ? payload.getInt("columns") : 32;
    String title = payload.hasKey("title") ? safe(payload.getString("title")) : "RPCheff";

    try {
      File imageFile = buildReceiptImage(content, columns, title);

      JSONObject request = new JSONObject();
      request.put("operation", "PRINT_IMAGE");
      JSONArray styles = new JSONArray();
      styles.put(new JSONObject());
      request.put("styles", styles);
      JSONArray values = new JSONArray();
      values.put(imageFile.getAbsolutePath());
      request.put("value", values);

      String encoded = Base64.encodeToString(request.toString().getBytes(StandardCharsets.UTF_8), Base64.NO_WRAP);
      Uri uri = new Uri.Builder()
        .scheme("lio")
        .authority("print")
        .appendQueryParameter("request", encoded)
        .appendQueryParameter("urlCallback", PRINT_CALLBACK)
        .build();

      Intent intent = new Intent(Intent.ACTION_VIEW, uri);
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

      Activity activity = getCurrentActivity();
      if (activity != null) {
        activity.startActivity(intent);
      } else {
        getReactApplicationContext().startActivity(intent);
      }

      WritableMap response = Arguments.createMap();
      response.putBoolean("printed", true);
      response.putString("message", "Impressão enviada para a Cielo.");
      response.putString("path", imageFile.getAbsolutePath());
      promise.resolve(response);
    } catch (Throwable error) {
      promise.reject(
        "CIELO_PRINT_ERROR",
        error.getMessage() == null ? "Falha ao iniciar impressão na Cielo." : error.getMessage(),
        error
      );
    }
  }

  @Override
  public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
  }

  @Override
  public void onNewIntent(Intent intent) {
    handleCieloIntent(intent);
  }

  private void handleCieloIntent(Intent intent) {
    if (pendingPromise == null || intent == null || intent.getData() == null) {
      return;
    }

    Uri data = intent.getData();
    String scheme = safeLower(data.getScheme());
    if (!scheme.equals("orderpay") && !scheme.equals("ordercancel")) {
      return;
    }

    if (scheme.equals("ordercancel")) {
      rejectAndClear("CIELO_CANCELLED", "Operacao cancelada na Cielo.", null);
      return;
    }

    try {
      String responseParam = data.getQueryParameter("response");
      if (responseParam == null || responseParam.trim().isEmpty()) {
        rejectAndClear("CIELO_INVALID_RESPONSE", "Retorno da Cielo invalido.", null);
        return;
      }

      String decoded = new String(Base64.decode(responseParam, Base64.DEFAULT), StandardCharsets.UTF_8);
      JSONObject payload = new JSONObject(decoded);

      if (payload.has("code")) {
        int code = payload.optInt("code", -1);
        String reason = payload.optString("reason", "Pagamento negado pela Cielo.");
        rejectAndClear("CIELO_DENIED_" + code, reason, null);
        return;
      }

      WritableMap response = Arguments.createMap();
      response.putBoolean("approved", true);
      response.putString("message", "Pagamento aprovado via Cielo.");
      response.putString("nsu", extractNsu(payload));
      response.putString("paymentCode", lastPaymentCode);
      response.putInt("sfiCodigo", mapPaymentCodeToSfi(lastPaymentCode));
      response.putString("raw", payload.toString());
      resolveAndClear(response);
    } catch (Throwable error) {
      rejectAndClear("CIELO_PARSE_ERROR", error.getMessage() == null ? "Falha ao processar retorno da Cielo." : error.getMessage(), error);
    }
  }

  private String extractNsu(JSONObject payload) {
    String direct = firstNonEmpty(
      payload.optString("nsu", ""),
      payload.optString("authCode", ""),
      payload.optString("cieloCode", ""),
      payload.optString("id", "")
    );
    if (!direct.isEmpty()) return direct;

    JSONArray payments = payload.optJSONArray("payments");
    if (payments != null && payments.length() > 0) {
      JSONObject payment = payments.optJSONObject(0);
      if (payment != null) {
        String nested = firstNonEmpty(
          payment.optString("nsu", ""),
          payment.optString("authCode", ""),
          payment.optString("cieloCode", ""),
          payment.optString("id", "")
        );
        if (!nested.isEmpty()) return nested;
      }
    }

    return "CIELO-" + System.currentTimeMillis();
  }

  private String resolvePaymentCode(ReadableMap payload) {
    if (payload.hasKey("paymentCode")) {
      String code = safeUpper(payload.getString("paymentCode"));
      if (!code.isEmpty()) {
        return code;
      }
    }

    if (payload.hasKey("transactionType")) {
      String type = safeLower(payload.getString("transactionType"));
      if (type.equals("credit") || type.equals("credito")) return "CREDITO_AVISTA";
      if (type.equals("debit") || type.equals("debito")) return "DEBITO_AVISTA";
      if (type.equals("pix")) return "PIX";
      if (type.equals("voucher") || type.equals("refeicao") || type.equals("alimentacao")) return "VOUCHER_REFEICAO";
    }

    if (payload.hasKey("sfiCodigo")) {
      int sfi = payload.getInt("sfiCodigo");
      if (sfi == 4) return "DEBITO_AVISTA";
      if (sfi == 17) return "PIX";
      if (sfi == 6 || sfi == 11) return "VOUCHER_REFEICAO";
      return "CREDITO_AVISTA";
    }

    return "CREDITO_AVISTA";
  }

  private int mapPaymentCodeToSfi(String paymentCode) {
    String normalized = safeUpper(paymentCode);
    if (normalized.startsWith("DEBITO")) return 4;
    if (normalized.startsWith("PIX")) return 17;
    if (normalized.startsWith("VOUCHER")) return 6;
    return 3;
  }

  private void scheduleTimeout() {
    clearTimeout();
    timeoutRunnable = new Runnable() {
      @Override
      public void run() {
        rejectAndClear("CIELO_TIMEOUT", "Tempo esgotado aguardando retorno da Cielo.", null);
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
    clearTimeout();
    if (local != null) {
      local.resolve(result);
    }
  }

  private void rejectAndClear(String code, String message, Throwable error) {
    Promise local = pendingPromise;
    pendingPromise = null;
    clearTimeout();
    if (local != null) {
      if (error != null) {
        local.reject(code, message, error);
      } else {
        local.reject(code, message);
      }
    }
  }

  private String safe(String value) {
    return value == null ? "" : value.trim();
  }

  private File buildReceiptImage(String content, int columns, String title) throws IOException {
    File baseDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
    if (baseDir == null) {
      baseDir = getReactApplicationContext().getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS);
    }
    if (baseDir == null) {
      baseDir = getReactApplicationContext().getFilesDir();
    }

    File printDir = new File(baseDir, "print");
    if (!printDir.exists() && !printDir.mkdirs()) {
      throw new IOException("Não foi possível criar a pasta de impressão da Cielo.");
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
    try {
      List<ReceiptElement> elements = parseReceiptElements(content, columns);
      if (!elements.isEmpty()) {
        return renderStructuredReceiptBitmap(elements, columns);
      }
    } catch (Throwable ignored) {
    }

    return renderPlainReceiptBitmap(content, columns, title);
  }

  private Bitmap renderPlainReceiptBitmap(String content, int columns, String title) {
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
    List<String> lines = wrapPlainReceiptLines(content, paint, availableWidth);
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

  private Bitmap renderStructuredReceiptBitmap(List<ReceiptElement> elements, int columns) {
    int receiptWidth = resolveStructuredReceiptWidth(columns);
    Bitmap workBitmap = Bitmap.createBitmap(receiptWidth, RECEIPT_WORK_HEIGHT_PX, Bitmap.Config.ARGB_8888);
    Canvas canvas = new Canvas(workBitmap);
    canvas.drawColor(Color.WHITE);

    List<ReceiptElement> layout = buildStructuredReceiptLayout(elements);
    int currentY = STRUCTURED_RECEIPT_MARGIN_PX;
    for (ReceiptElement element : layout) {
      if (element == null) {
        continue;
      }

      if ("image".equals(element.type)) {
        currentY += renderStructuredReceiptImage(canvas, element.imageData, currentY, receiptWidth);
        continue;
      }

      Bitmap lineBitmap = null;
      try {
        lineBitmap = renderStructuredReceiptLineBitmap(
          element.content,
          element.align,
          element.size,
          element.style,
          receiptWidth
        );
        canvas.drawBitmap(lineBitmap, 0f, currentY, null);
        currentY += lineBitmap.getHeight();
      } finally {
        if (lineBitmap != null && !lineBitmap.isRecycled()) {
          lineBitmap.recycle();
        }
      }
    }

    int finalHeight = Math.max(currentY + STRUCTURED_RECEIPT_BOTTOM_PADDING_PX, STRUCTURED_RECEIPT_BOTTOM_PADDING_PX * 2);
    finalHeight = Math.min(finalHeight, workBitmap.getHeight());

    Bitmap cropped = Bitmap.createBitmap(workBitmap, 0, 0, receiptWidth, finalHeight);
    workBitmap.recycle();
    return toMonochrome(cropped);
  }

  private List<ReceiptElement> buildStructuredReceiptLayout(List<ReceiptElement> elements) {
    List<ReceiptElement> layout = new ArrayList<>();
    lastStructuredSeparator = false;
    suppressNextStructuredSeparator = false;
    pendingStructuredWaitersHeader = false;
    pendingStructuredSummaryMetricLine = null;

    for (ReceiptElement element : elements) {
      appendStructuredReceiptElement(layout, element);
    }

    flushPendingStructuredSummaryMetric(layout, "left", "medium", "");
    return layout;
  }

  private void appendStructuredReceiptElement(List<ReceiptElement> layout, ReceiptElement element) {
    if (element == null) {
      return;
    }

    if ("image".equals(element.type)) {
      flushPendingStructuredSummaryMetric(layout, "left", "medium", "");
      layout.add(element);
      lastStructuredSeparator = false;
      suppressNextStructuredSeparator = false;
      return;
    }

    String type = safeLower(element.type);
    String align = firstNonEmpty(element.align, "left");
    String size = firstNonEmpty(element.size, "medium");
    String style = safePreserve(element.style);
    String value = safePreserve(element.content);
    if ("line".equals(type) && value.trim().isEmpty()) {
      value = "--------------------------------";
    }

    String normalized = value.replace("\r\n", "\n").replace('\r', '\n');
    String[] sourceLines = normalized.split("\n", -1);
    for (String line : sourceLines) {
      appendStructuredStyledLine(layout, line, align, size, style);
    }
  }

  private void appendStructuredStyledLine(List<ReceiptElement> layout, String text, String align, String size, String style) {
    String value = safePreserve(text);
    String trimmedValue = value.trim();

    if (pendingStructuredSummaryMetricLine != null) {
      if (isPeopleCountLine(trimmedValue)) {
        appendStructuredSingleLine(layout, pendingStructuredSummaryMetricLine + "    " + trimmedValue, align, size, style);
        pendingStructuredSummaryMetricLine = null;
        lastStructuredSeparator = false;
        return;
      }

      flushPendingStructuredSummaryMetric(layout, align, size, style);
    }

    if (trimmedValue.isEmpty()) {
      return;
    }

    if (isConferenceTypeLine(trimmedValue)) {
      return;
    }

    if ("ITENS".equals(trimmedValue.toUpperCase(Locale.ROOT))) {
      return;
    }

    if (isConferenceLine(trimmedValue)) {
      appendStructuredSingleLine(layout, normalizeConferenceLine(trimmedValue), "center", "medium", "bold");
      lastStructuredSeparator = false;
      suppressNextStructuredSeparator = true;
      return;
    }

    if (isItemsCountLine(trimmedValue)) {
      pendingStructuredSummaryMetricLine = trimmedValue;
      return;
    }

    if (isPendingValueLine(value)) {
      appendStructuredSingleLine(layout, normalizePendingValueLine(value), "center", "medium", "bold");
      lastStructuredSeparator = false;
      suppressNextStructuredSeparator = true;
      return;
    }

    if (isWaiterHeaderLine(trimmedValue)) {
      pendingStructuredWaitersHeader = true;
      lastStructuredSeparator = false;
      suppressNextStructuredSeparator = false;
      return;
    }

    if (pendingStructuredWaitersHeader) {
      if (looksLikeSeparator(value)) {
        return;
      }
      appendStructuredSingleLine(layout, "GARCONS: " + trimmedValue, "center", "small", "bold");
      pendingStructuredWaitersHeader = false;
      lastStructuredSeparator = false;
      suppressNextStructuredSeparator = true;
      return;
    }

    boolean separator = looksLikeSeparator(value);
    if (separator && (lastStructuredSeparator || suppressNextStructuredSeparator)) {
      suppressNextStructuredSeparator = false;
      return;
    }

    appendStructuredSingleLine(layout, value, align, size, style);
    if (shouldInsertSeparatorAfterLine(trimmedValue)) {
      appendStructuredSeparator(layout);
      lastStructuredSeparator = true;
      suppressNextStructuredSeparator = true;
      return;
    }
    lastStructuredSeparator = separator;
    suppressNextStructuredSeparator = !separator && shouldSuppressFollowingSeparator(trimmedValue);
  }

  private void flushPendingStructuredSummaryMetric(List<ReceiptElement> layout, String align, String size, String style) {
    if (pendingStructuredSummaryMetricLine == null) {
      return;
    }

    appendStructuredSingleLine(layout, pendingStructuredSummaryMetricLine, align, size, style);
    pendingStructuredSummaryMetricLine = null;
    lastStructuredSeparator = false;
  }

  private void appendStructuredSingleLine(List<ReceiptElement> layout, String text, String align, String size, String style) {
    String value = safePreserve(text);
    if (value.trim().isEmpty()) {
      return;
    }

    layout.add(new ReceiptElement("text", value, align, size, style, ""));
  }

  private void appendStructuredSeparator(List<ReceiptElement> layout) {
    layout.add(new ReceiptElement("line", repeatCharacter('-', 48), "left", "small", "bold", ""));
  }

  private int renderStructuredReceiptElement(
    Canvas canvas,
    ReceiptElement element,
    int currentY,
    int receiptWidth,
    int contentWidth
  ) {
    if (element == null) {
      return 0;
    }

    if ("image".equals(element.type)) {
      return renderStructuredReceiptImage(canvas, element.imageData, currentY, receiptWidth);
    }

    Paint paint = createStructuredReceiptPaint(
      "line".equals(element.type) ? "small" : element.size,
      "line".equals(element.type) ? "bold" : element.style
    );
    List<String> lines = wrapStructuredReceiptLines(
      "line".equals(element.type) ? firstNonEmpty(element.content, "--------------------------------") : element.content,
      paint,
      contentWidth
    );
    if (lines.isEmpty()) {
      lines.add("");
    }

    Paint.FontMetrics metrics = paint.getFontMetrics();
    int lineHeight = Math.max(24, (int) Math.ceil((metrics.descent - metrics.ascent) + STRUCTURED_RECEIPT_LINE_SPACING_PX));
    int renderedHeight = 0;

    for (String line : lines) {
      float x = STRUCTURED_RECEIPT_MARGIN_PX + resolveAlignedOffset(line, paint, contentWidth, element.align);
      float baseline = currentY - metrics.ascent;
      canvas.drawText(line, x, baseline, paint);
      currentY += lineHeight;
      renderedHeight += lineHeight;
    }

    return renderedHeight;
  }

  private int renderStructuredReceiptImage(Canvas canvas, String imageData, int currentY, int receiptWidth) {
    Bitmap image = decodeBase64Bitmap(imageData);
    if (image == null) {
      return 0;
    }

    try {
      if (image.getWidth() <= 0 || image.getHeight() <= 0) {
        return 0;
      }

      float maxWidth = receiptWidth * STRUCTURED_IMAGE_MAX_WIDTH_RATIO;
      float scale = maxWidth / (float) image.getWidth();
      float scaledWidth = image.getWidth() * scale;
      float scaledHeight = image.getHeight() * scale;
      float left = (receiptWidth - scaledWidth) / 2f;
      Paint imagePaint = new Paint(Paint.FILTER_BITMAP_FLAG | Paint.DITHER_FLAG);
      imagePaint.setAntiAlias(false);

      canvas.drawBitmap(
        image,
        null,
        new RectF(left, currentY, left + scaledWidth, currentY + scaledHeight),
        imagePaint
      );

      return Math.max(1, Math.round(scaledHeight + STRUCTURED_RECEIPT_LINE_SPACING_PX));
    } finally {
      if (!image.isRecycled()) {
        image.recycle();
      }
    }
  }

  private Bitmap renderStructuredReceiptLineBitmap(String text, String align, String size, String style, int receiptWidth) {
    final String printableText = safePreserve(text).replace('\t', ' ').trim();
    final float fontSize = mapReceiptFontSize(size);
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
    paint.setStrokeWidth(bold ? 1.3f : 0.85f);
    paint.setSubpixelText(true);

    if (separator) {
      Bitmap bitmap = Bitmap.createBitmap(receiptWidth, RECEIPT_SEPARATOR_HEIGHT_PX, Bitmap.Config.ARGB_8888);
      Canvas canvas = new Canvas(bitmap);
      canvas.drawColor(Color.WHITE);
      Paint linePaint = new Paint();
      linePaint.setColor(Color.BLACK);
      linePaint.setAntiAlias(false);
      linePaint.setStyle(Paint.Style.FILL);
      int top = Math.max(4, (RECEIPT_SEPARATOR_HEIGHT_PX / 2) - 2);
      int bottom = Math.min(RECEIPT_SEPARATOR_HEIGHT_PX - 3, top + 4);
      canvas.drawRect(
        RECEIPT_SIDE_PADDING_PX,
        top,
        receiptWidth - RECEIPT_SIDE_PADDING_PX,
        bottom,
        linePaint
      );
      return bitmap;
    }

    Paint.FontMetrics fontMetrics = paint.getFontMetrics();
    int textHeight = (int) Math.ceil(fontMetrics.descent - fontMetrics.ascent);
    int extraVerticalPadding = compactInfoLine ? 6 : 12;
    int minHeight = 24;
    if (compactInfoLine) {
      minHeight = 22;
    } else if (compactHeader) {
      minHeight = 24;
    } else if (sectionTitle || monetaryHighlight) {
      minHeight = 32;
    } else if (summaryMetric) {
      minHeight = 24;
    }

    int bitmapHeight = Math.max(textHeight + extraVerticalPadding, minHeight);
    Bitmap bitmap = Bitmap.createBitmap(receiptWidth, bitmapHeight, Bitmap.Config.ARGB_8888);
    Canvas canvas = new Canvas(bitmap);
    canvas.drawColor(Color.WHITE);

    float textWidth = paint.measureText(printableText);
    float x = RECEIPT_SIDE_PADDING_PX;
    if (mapAlignment(align) == 1) {
      x = Math.max(RECEIPT_SIDE_PADDING_PX, (receiptWidth - textWidth) / 2f);
    } else if (mapAlignment(align) == 2) {
      x = Math.max(RECEIPT_SIDE_PADDING_PX, receiptWidth - RECEIPT_SIDE_PADDING_PX - textWidth);
    }

    float baseline = ((bitmapHeight - (fontMetrics.descent - fontMetrics.ascent)) / 2f) - fontMetrics.ascent;
    canvas.drawText(printableText, x, baseline, paint);
    canvas.drawText(printableText, x + 0.35f, baseline, paint);
    return bitmap;
  }

  private List<ReceiptElement> parseReceiptElements(String content, int columns) throws JSONException {
    List<ReceiptElement> elements = new ArrayList<>();
    Object payload = parseReceiptPayload(content);
    appendReceiptElements(payload, elements, columns);
    return elements;
  }

  private Object parseReceiptPayload(String content) throws JSONException {
    String raw = safePreserve(content).trim();
    if (raw.isEmpty()) {
      return null;
    }

    Object parsed = new JSONTokener(raw).nextValue();
    if (parsed instanceof String) {
      String nested = safePreserve((String) parsed).trim();
      if (nested.startsWith("[") || nested.startsWith("{")) {
        return parseReceiptPayload(nested);
      }
    }
    return parsed;
  }

  private void appendReceiptElements(Object payload, List<ReceiptElement> elements, int columns) throws JSONException {
    if (payload == null) {
      return;
    }

    if (payload instanceof JSONArray) {
      JSONArray array = (JSONArray) payload;
      for (int index = 0; index < array.length(); index++) {
        appendReceiptElements(array.opt(index), elements, columns);
      }
      return;
    }

    if (payload instanceof JSONObject) {
      JSONObject command = (JSONObject) payload;
      if (command.has("commands")) {
        appendReceiptElements(command.opt("commands"), elements, columns);
        return;
      }

      if (command.has("data")) {
        appendReceiptElements(command.opt("data"), elements, columns);
        return;
      }

      String type = safeLower(command.optString("type"));
      String text = safePreserve(command.optString("content"));
      if (type.isEmpty()) {
        type = text.isEmpty() ? "" : "text";
      }

      if ("line".equals(type) && text.trim().isEmpty()) {
        text = repeatCharacter('-', Math.max(32, Math.min(columns, 64)));
      }

      if ("text".equals(type) || "line".equals(type) || "image".equals(type)) {
        elements.add(
          new ReceiptElement(
            type,
            text,
            command.optString("align"),
            command.optString("size"),
            command.optString("style"),
            firstNonEmpty(
              safePreserve(command.optString("imagePath")),
              safePreserve(command.optString("imageData"))
            )
          )
        );
      }
      return;
    }

    if (payload instanceof String) {
      String text = safePreserve((String) payload);
      if (!text.trim().isEmpty()) {
        elements.add(new ReceiptElement("text", text, "left", "medium", "", ""));
      }
    }
  }

  private Paint createStructuredReceiptPaint(String size, String style) {
    Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.DITHER_FLAG);
    paint.setColor(Color.BLACK);
    paint.setStyle(Paint.Style.FILL);
    paint.setTextSize(mapStructuredReceiptFontSize(size));

    int typefaceStyle = Typeface.BOLD;
    if (safeLower(style).contains("italic")) {
      typefaceStyle = Typeface.BOLD_ITALIC;
    }
    if (!safeLower(style).contains("bold") && !safeLower(style).contains("italic")) {
      typefaceStyle = Typeface.BOLD;
    }

    paint.setTypeface(Typeface.create(Typeface.MONOSPACE, typefaceStyle));
    return paint;
  }

  private List<String> wrapPlainReceiptLines(String content, Paint paint, int maxWidth) {
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

  private List<String> wrapStructuredReceiptLines(String content, Paint paint, int maxWidth) {
    List<String> lines = new ArrayList<>();
    String normalized = safePreserve(content).replace("\r\n", "\n").replace('\r', '\n');
    String[] sourceLines = normalized.split("\n", -1);

    for (String sourceLine : sourceLines) {
      String current = sourceLine == null ? "" : sourceLine;
      if (current.trim().isEmpty()) {
        lines.add("");
        continue;
      }

      String[] words = current.split(" ");
      StringBuilder builder = new StringBuilder();
      for (String word : words) {
        String candidate = builder.length() == 0 ? word : builder + " " + word;
        if (paint.measureText(candidate) <= maxWidth) {
          builder.setLength(0);
          builder.append(candidate);
        } else if (builder.length() > 0) {
          lines.add(builder.toString().trim());
          builder.setLength(0);
          builder.append(word);
        } else {
          String remaining = word;
          while (!remaining.isEmpty()) {
            int count = paint.breakText(remaining, true, maxWidth, null);
            if (count <= 0 || count >= remaining.length()) {
              lines.add(remaining);
              remaining = "";
            } else {
              lines.add(remaining.substring(0, count));
              remaining = remaining.substring(count);
            }
          }
        }
      }

      if (builder.length() > 0) {
        lines.add(builder.toString().trim());
      }
    }

    if (lines.isEmpty()) {
      lines.add("");
    }

    return lines;
  }

  private float resolveAlignedOffset(String text, Paint paint, int maxWidth, String align) {
    float textWidth = paint.measureText(firstNonEmpty(text, ""));
    int alignment = mapAlignment(align);
    if (alignment == 1) {
      return Math.max(0f, (maxWidth - textWidth) / 2f);
    }
    if (alignment == 2) {
      return Math.max(0f, maxWidth - textWidth);
    }
    return 0f;
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
      || upper.startsWith("FONE ")
      || upper.startsWith("FONE(")
      || upper.startsWith("CONFERENCIA ")
      || upper.startsWith("FECHAMENTO:")
      || upper.startsWith("SUB TOTAL")
      || upper.startsWith("SUBTOTAL")
      || upper.startsWith("TOTAL R$")
      || upper.startsWith("TOTAL/PESSOA:")
      || upper.startsWith("PENDENTE ")
      || upper.startsWith("GARCONS:")
      || upper.startsWith("GARÇONS:")
      || upper.startsWith("SOLICITADO POR:");
  }

  private boolean shouldInsertSeparatorAfterLine(String text) {
    String upper = safePreserve(text).trim().toUpperCase(Locale.ROOT);
    return upper.startsWith("FONE:")
      || upper.startsWith("FONE ")
      || upper.startsWith("FONE(")
      || upper.startsWith("FECHAMENTO:")
      || upper.startsWith("SUB TOTAL")
      || upper.startsWith("SUBTOTAL")
      || upper.startsWith("TOTAL/PESSOA:");
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

  private float mapReceiptFontSize(String size) {
    String normalized = safeLower(size);
    if ("big".equals(normalized) || "large".equals(normalized) || "extrabig".equals(normalized)) {
      return RECEIPT_FONT_SIZE_BIG;
    }
    if ("small".equals(normalized)) {
      return RECEIPT_FONT_SIZE_SMALL;
    }
    return RECEIPT_FONT_SIZE_MEDIUM;
  }

  private boolean isBold(String style) {
    return safeLower(style).contains("bold");
  }

  private Bitmap decodeBase64Bitmap(String value) {
    String raw = safePreserve(value).trim();
    if (raw.isEmpty()) {
      return null;
    }

    try {
      byte[] bytes = Base64.decode(raw, Base64.DEFAULT);
      return BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
    } catch (Throwable ignored) {
      return null;
    }
  }

  private int resolveStructuredReceiptWidth(int columns) {
    return Math.max(RECEIPT_WIDTH_PX, Math.max(32, columns) * 12);
  }

  private float mapStructuredReceiptFontSize(String size) {
    String normalized = safeLower(size);
    if ("extrabig".equals(normalized)) {
      return 38f;
    }
    if ("big".equals(normalized) || "large".equals(normalized)) {
      return 32f;
    }
    if ("small".equals(normalized)) {
      return 20f;
    }
    return 26f;
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

  private String resolvePayloadString(ReadableMap payload, String primaryKey, String secondaryKey, String defaultValue) {
    String primary = readPayloadString(payload, primaryKey);
    if (!primary.isEmpty()) {
      return primary;
    }

    String secondary = readPayloadString(payload, secondaryKey);
    if (!secondary.isEmpty()) {
      return secondary;
    }

    return defaultValue;
  }

  private String resolvePayloadMethodCode(ReadableMap payload, String primaryKey, String secondaryKey, String defaultValue) {
    String primary = readPayloadString(payload, primaryKey);
    if (!primary.isEmpty()) {
      return primary;
    }

    if (
      payload != null
      && secondaryKey != null
      && !secondaryKey.isEmpty()
      && payload.hasKey(secondaryKey)
      && !payload.isNull(secondaryKey)
    ) {
      try {
        return String.valueOf(payload.getInt(secondaryKey));
      } catch (Throwable ignored) {
      }

      try {
        return safe(payload.getString(secondaryKey));
      } catch (Throwable ignored) {
      }
    }

    return defaultValue;
  }

  private String readPayloadString(ReadableMap payload, String key) {
    if (payload == null || key == null || key.isEmpty() || !payload.hasKey(key) || payload.isNull(key)) {
      return "";
    }
    return safe(payload.getString(key));
  }

  private String repeatCharacter(char value, int count) {
    if (count <= 0) {
      return "";
    }

    StringBuilder builder = new StringBuilder(count);
    for (int index = 0; index < count; index++) {
      builder.append(value);
    }
    return builder.toString();
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
