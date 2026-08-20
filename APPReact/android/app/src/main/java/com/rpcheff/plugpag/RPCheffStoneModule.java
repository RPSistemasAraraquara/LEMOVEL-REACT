package com.rpcheff.plugpag;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.net.Uri;
import android.util.Base64;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.os.Handler;
import android.os.Looper;
import android.os.Parcel;
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
import com.facebook.react.modules.core.PermissionAwareActivity;
import com.facebook.react.modules.core.PermissionListener;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import com.sunmi.trans.TransBean;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import woyou.aidlservice.jiuiv5.ICallback;
import woyou.aidlservice.jiuiv5.IWoyouService;

public class RPCheffStoneModule extends ReactContextBaseJavaModule implements ActivityEventListener, PermissionListener {
  private static final String RETURN_SCHEME = "stone-rpmobile";
  private static final String RETURN_SCHEME_CANCEL = "stone-rpmobile-cancel";
  private static final String SUNMI_PRINTER_PACKAGE = "woyou.aidlservice.jiuiv5";
  private static final String SUNMI_PRINTER_ACTION = "woyou.aidlservice.jiuiv5.IWoyouService";
  private static final String POSITIVO_PRINTER_PACKAGE = "com.xcheng.printerservice";
  private static final String POSITIVO_PRINTER_ACTION = "com.xcheng.printerservice.IPrinterService";
  private static final String POSITIVO_PRINTER_PERMISSION = "com.pos.permission.PRINTER";
  private static final String XCHENG_PRINTER_DESCRIPTOR = "com.xcheng.printerservice.IPrinterService";
  private static final String XCHENG_PRINTER_CALLBACK_DESCRIPTOR = "com.xcheng.printerservice.IPrinterCallback";
  private static final int POSITIVO_PRINTER_PERMISSION_REQUEST = 52040;
  private static final int XCHENG_PRINTER_INIT = 4;
  private static final int XCHENG_PRINTER_PRINT_TEXT = 7;
  private static final int XCHENG_PRINTER_PRINT_BITMAP = 10;
  private static final int XCHENG_CALLBACK_ON_EXCEPTION = 1;
  private static final int XCHENG_CALLBACK_ON_LENGTH = 2;
  private static final int XCHENG_CALLBACK_ON_REAL_LENGTH = 3;
  private static final int XCHENG_CALLBACK_ON_COMPLETE = 4;
  private static final long DEFAULT_TIMEOUT_MS = 180000L;
  private static final String OPERATION_PAYMENT = "payment";
  private static final String OPERATION_PRINT = "print";
  private static final int SUNMI_PAPER_WIDTH = 384;
  private static final int SUNMI_SIDE_PADDING = 12;
  private static final int SUNMI_BITMAP_TYPE_BLACK_AND_WHITE = 1;
  private static final int SUNMI_SEPARATOR_HEIGHT = 1;
  private static final int SUNMI_BLANK_LINE_HEIGHT = 1;
  private static final int POSITIVO_BITMAP_CHUNK_MAX_HEIGHT = 600;
  private static final int POSITIVO_BOTTOM_FEED_HEIGHT = 160;
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
  private IBinder positivoPrinterService;
  private ServiceConnection positivoPrinterConnection;
  private String pendingPositivoPrintContent;
  private boolean lastPrintedSeparator;
  private boolean suppressNextSeparator;
  private boolean pendingWaitersHeader;
  private String pendingSummaryMetricLine;

  private static final class ReceiptPrintLine {
    final String text;
    final String align;
    final String size;
    final String style;

    ReceiptPrintLine(String text, String align, String size, String style) {
      this.text = text;
      this.align = align;
      this.size = size;
      this.style = style;
    }
  }

  private interface XchengPrinterCallbackEvents {
    void onComplete();
    void onException(int code, String message);
  }

  private static final class XchengPrinterCallbackBinder extends Binder {
    private final XchengPrinterCallbackEvents events;

    XchengPrinterCallbackBinder(XchengPrinterCallbackEvents events) {
      this.events = events;
      attachInterface(null, XCHENG_PRINTER_CALLBACK_DESCRIPTOR);
    }

    @Override
    public boolean onTransact(int code, Parcel data, Parcel reply, int flags) throws RemoteException {
      if (code == INTERFACE_TRANSACTION) {
        if (reply != null) {
          reply.writeString(XCHENG_PRINTER_CALLBACK_DESCRIPTOR);
        }
        return true;
      }

      switch (code) {
        case XCHENG_CALLBACK_ON_EXCEPTION: {
          data.enforceInterface(XCHENG_PRINTER_CALLBACK_DESCRIPTOR);
          int errorCode = data.readInt();
          String message = data.readString();
          if (reply != null) {
            reply.writeNoException();
          }
          if (events != null) {
            events.onException(errorCode, message);
          }
          return true;
        }
        case XCHENG_CALLBACK_ON_LENGTH: {
          data.enforceInterface(XCHENG_PRINTER_CALLBACK_DESCRIPTOR);
          data.readLong();
          data.readLong();
          if (reply != null) {
            reply.writeNoException();
          }
          return true;
        }
        case XCHENG_CALLBACK_ON_REAL_LENGTH: {
          data.enforceInterface(XCHENG_PRINTER_CALLBACK_DESCRIPTOR);
          data.readDouble();
          data.readDouble();
          if (reply != null) {
            reply.writeNoException();
          }
          return true;
        }
        case XCHENG_CALLBACK_ON_COMPLETE: {
          data.enforceInterface(XCHENG_PRINTER_CALLBACK_DESCRIPTOR);
          if (reply != null) {
            reply.writeNoException();
          }
          if (events != null) {
            events.onComplete();
          }
          return true;
        }
        default:
          return super.onTransact(code, data, reply, flags);
      }
    }
  }

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
    String model = payload.hasKey("model") ? safe(payload.getString("model")) : "";
    if (content.isEmpty()) {
      promise.reject("STONE_PRINT_EMPTY", "Conteúdo de impressão vazio.");
      return;
    }

    try {
      pendingPromise = promise;
      pendingOperation = OPERATION_PRINT;
      scheduleTimeout();
      if (isStoneL400Model(model)) {
        if (!startPositivoPrintWithPermission(content)) {
          startStonePrinterAppFallback(content);
        }
      } else if (!startSunmiPrint(content)) {
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

  private boolean isStoneL400Model(String model) {
    String normalized = safeLower(model).replace("-", "").replace(" ", "");
    return normalized.contains("l400") || normalized.contains("positivo");
  }

  private boolean startPositivoPrintWithPermission(final String content) {
    if (hasPositivoPrinterPermission()) {
      return startPositivoPrint(content);
    }

    Activity activity = getCurrentActivity();
    if (!(activity instanceof PermissionAwareActivity)) {
      return false;
    }

    pendingPositivoPrintContent = content;
    ((PermissionAwareActivity) activity).requestPermissions(
      new String[] { POSITIVO_PRINTER_PERMISSION },
      POSITIVO_PRINTER_PERMISSION_REQUEST,
      this
    );
    return true;
  }

  private boolean hasPositivoPrinterPermission() {
    return Build.VERSION.SDK_INT < Build.VERSION_CODES.M
      || getReactApplicationContext().checkSelfPermission(POSITIVO_PRINTER_PERMISSION) == PackageManager.PERMISSION_GRANTED;
  }

  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
    if (requestCode != POSITIVO_PRINTER_PERMISSION_REQUEST) {
      return false;
    }

    String content = pendingPositivoPrintContent;
    pendingPositivoPrintContent = null;

    if (pendingPromise == null || !OPERATION_PRINT.equals(pendingOperation)) {
      return true;
    }

    boolean granted = grantResults != null
      && grantResults.length > 0
      && grantResults[0] == PackageManager.PERMISSION_GRANTED;

    if (!granted) {
      rejectAndClear(
        "STONE_L400_PERMISSION_DENIED",
        "Permissão da impressora Stone L400 negada.",
        null
      );
      return true;
    }

    try {
      if (!startPositivoPrint(content)) {
        startStonePrinterAppFallback(content);
      }
    } catch (Throwable error) {
      rejectAndClear(
        "STONE_L400_PRINT_ERROR",
        error.getMessage() == null ? "Falha ao iniciar impressão na Stone L400." : error.getMessage(),
        error
      );
    }
    return true;
  }

  private boolean startPositivoPrint(final String content) {
    final ReactApplicationContext context = getReactApplicationContext();
    final Intent intent = new Intent();
    intent.setPackage(POSITIVO_PRINTER_PACKAGE);
    intent.setAction(POSITIVO_PRINTER_ACTION);

    unbindPositivoPrinter();
    positivoPrinterConnection = new ServiceConnection() {
      @Override
      public void onServiceConnected(ComponentName name, IBinder service) {
        positivoPrinterService = service;
        try {
          executePositivoPrint(content);
        } catch (Throwable error) {
          rejectPositivoPrint(
            "STONE_L400_PRINT_ERROR",
            error.getMessage() == null ? "Falha ao imprimir pela Stone L400." : error.getMessage(),
            error
          );
        }
      }

      @Override
      public void onServiceDisconnected(ComponentName name) {
        positivoPrinterService = null;
        if (pendingPromise != null && OPERATION_PRINT.equals(pendingOperation)) {
          rejectPositivoPrint(
            "STONE_L400_PRINTER_DISCONNECTED",
            "Serviço da impressora Stone L400 foi desconectado.",
            null
          );
        }
      }
    };

    try {
      final boolean bound = context.bindService(intent, positivoPrinterConnection, Context.BIND_AUTO_CREATE);
      if (!bound) {
        unbindPositivoPrinter();
      }
      return bound;
    } catch (Throwable error) {
      unbindPositivoPrinter();
      return false;
    }
  }

  private void executePositivoPrint(String content) throws RemoteException, JSONException {
    if (positivoPrinterService == null) {
      throw new RemoteException("Serviço Positivo indisponível.");
    }

    String receiptImageBase64 = extractReceiptImageBase64(content);
    if (!receiptImageBase64.trim().isEmpty()) {
      printPositivoImageReceipt(receiptImageBase64);
      return;
    }

    try {
      printPositivoBitmapReceipt(content);
    } catch (Throwable bitmapError) {
      printPositivoTextReceipt(content);
    }
  }

  private String extractReceiptImageBase64(String content) {
    String raw = safePreserve(content).trim();
    if (!raw.startsWith("[") && !raw.startsWith("{")) {
      return "";
    }

    try {
      Object parsed = new JSONTokener(raw).nextValue();
      return findReceiptImageBase64(parsed);
    } catch (JSONException ignored) {
      return "";
    }
  }

  private String findReceiptImageBase64(Object payload) throws JSONException {
    if (payload == null || payload == JSONObject.NULL) {
      return "";
    }

    if (payload instanceof JSONArray) {
      JSONArray array = (JSONArray) payload;
      for (int index = 0; index < array.length(); index++) {
        String found = findReceiptImageBase64(array.opt(index));
        if (!found.trim().isEmpty()) {
          return found;
        }
      }
      return "";
    }

    if (payload instanceof JSONObject) {
      JSONObject command = (JSONObject) payload;
      if (command.has("commands")) {
        return findReceiptImageBase64(command.optJSONArray("commands"));
      }
      if (command.has("data")) {
        return findReceiptImageBase64(command.optJSONArray("data"));
      }

      if ("image".equals(safeLower(command.optString("type")))) {
        String imageBase64 = safePreserve(command.optString("imagePath"));
        if (imageBase64.trim().isEmpty()) {
          imageBase64 = safePreserve(command.optString("imageData"));
        }
        return imageBase64;
      }
    }

    return "";
  }

  private void printPositivoImageReceipt(String imageBase64) throws RemoteException {
    List<Bitmap> bitmaps = buildPositivoImageBitmapChunks(imageBase64);
    if (bitmaps.isEmpty()) {
      throw new RemoteException("Imagem de impressão vazia para Stone L400.");
    }

    try {
      callXchengPrinterInit(positivoPrinterService, new XchengPrinterCallbackBinder(null));
      printNextPositivoBitmapChunk(bitmaps, 0);
    } catch (Throwable error) {
      recycleBitmaps(bitmaps);
      if (error instanceof RemoteException) {
        throw (RemoteException) error;
      }
      throw new RemoteException(error.getMessage() == null ? "Falha ao imprimir NFC-e na Stone L400." : error.getMessage());
    }
  }

  private List<Bitmap> buildPositivoImageBitmapChunks(String imageBase64) throws RemoteException {
    List<Bitmap> chunks = new ArrayList<>();
    Bitmap source = null;
    Bitmap scaled = null;

    try {
      String raw = normalizeBase64Image(imageBase64);
      if (raw.isEmpty()) {
        throw new RemoteException("Imagem de impressão vazia para Stone L400.");
      }

      byte[] bytes = Base64.decode(raw, Base64.DEFAULT);
      source = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
      if (source == null || source.getWidth() <= 0 || source.getHeight() <= 0) {
        throw new RemoteException("Imagem de impressão inválida para Stone L400.");
      }

      int targetWidth = SUNMI_PAPER_WIDTH;
      int targetHeight = Math.max(1, Math.round(source.getHeight() * (targetWidth / (float) source.getWidth())));
      if (source.getWidth() == targetWidth && source.getHeight() == targetHeight) {
        scaled = source.copy(Bitmap.Config.ARGB_8888, false);
      } else {
        scaled = Bitmap.createScaledBitmap(source, targetWidth, targetHeight, true);
      }
      if (scaled == null || scaled.getWidth() <= 0 || scaled.getHeight() <= 0) {
        throw new RemoteException("Falha ao preparar imagem da NFC-e para Stone L400.");
      }

      int offsetY = 0;
      while (offsetY < scaled.getHeight()) {
        int chunkHeight = Math.min(POSITIVO_BITMAP_CHUNK_MAX_HEIGHT, scaled.getHeight() - offsetY);
        chunks.add(Bitmap.createBitmap(scaled, 0, offsetY, targetWidth, chunkHeight));
        offsetY += chunkHeight;
      }
      chunks.add(renderBlankReceiptBitmap(POSITIVO_BOTTOM_FEED_HEIGHT));
      return chunks;
    } catch (RemoteException error) {
      recycleBitmaps(chunks);
      throw error;
    } catch (Throwable error) {
      recycleBitmaps(chunks);
      throw new RemoteException(error.getMessage() == null ? "Imagem de impressão inválida para Stone L400." : error.getMessage());
    } finally {
      recycleBitmap(scaled);
      recycleBitmap(source);
    }
  }

  private String normalizeBase64Image(String value) {
    String normalized = safePreserve(value).trim();
    int markerIndex = safeLower(normalized).indexOf("base64,");
    if (markerIndex >= 0) {
      return normalized.substring(markerIndex + "base64,".length()).trim();
    }
    return normalized;
  }

  private void printPositivoBitmapReceipt(String content) throws RemoteException, JSONException {
    List<ReceiptPrintLine> lines = collectReceiptPrintLines(content);
    if (lines.isEmpty()) {
      throw new RemoteException("Conteúdo de impressão vazio para Stone L400.");
    }

    List<Bitmap> bitmaps = renderPositivoReceiptBitmapChunks(lines);
    if (bitmaps.isEmpty()) {
      throw new RemoteException("Falha ao renderizar impressão Stone L400.");
    }

    try {
      callXchengPrinterInit(positivoPrinterService, new XchengPrinterCallbackBinder(null));
      printNextPositivoBitmapChunk(bitmaps, 0);
    } catch (Throwable error) {
      recycleBitmaps(bitmaps);
      if (error instanceof RemoteException) {
        throw (RemoteException) error;
      }
      throw new RemoteException(error.getMessage() == null ? "Falha ao imprimir imagem na Stone L400." : error.getMessage());
    }
  }

  private void printNextPositivoBitmapChunk(final List<Bitmap> bitmaps, final int index) {
    if (index >= bitmaps.size()) {
      recycleBitmaps(bitmaps);
      resolvePositivoPrint("Impressão concluída na Stone L400.");
      return;
    }

    final Bitmap bitmap = bitmaps.get(index);
    try {
      callXchengPrinterPrintBitmap(positivoPrinterService, bitmap, new XchengPrinterCallbackBinder(new XchengPrinterCallbackEvents() {
        @Override
        public void onComplete() {
          timeoutHandler.post(new Runnable() {
            @Override
            public void run() {
              recycleBitmap(bitmap);
              printNextPositivoBitmapChunk(bitmaps, index + 1);
            }
          });
        }

        @Override
        public void onException(final int code, final String message) {
          timeoutHandler.post(new Runnable() {
            @Override
            public void run() {
              recycleBitmaps(bitmaps);
              rejectPositivoPrint(
                "STONE_L400_PRINT_ERROR",
                resolveXchengPrinterErrorMessage(code, message),
                null
              );
            }
          });
        }
      }));
    } catch (Throwable error) {
      recycleBitmaps(bitmaps);
      rejectPositivoPrint(
        "STONE_L400_PRINT_ERROR",
        error.getMessage() == null ? "Falha ao enviar imagem para Stone L400." : error.getMessage(),
        error
      );
    }
  }

  private void printPositivoTextReceipt(String content) throws RemoteException, JSONException {
    String printableText = buildPositivoPrintableText(content);
    if (printableText.trim().isEmpty()) {
      throw new RemoteException("Conteúdo de impressão vazio para Stone L400.");
    }

    callXchengPrinterInit(positivoPrinterService, new XchengPrinterCallbackBinder(null));
    callXchengPrinterPrintText(positivoPrinterService, ensurePositivoFeed(printableText), new XchengPrinterCallbackBinder(new XchengPrinterCallbackEvents() {
      @Override
      public void onComplete() {
        resolvePositivoPrint("Impressão concluída na Stone L400.");
      }

      @Override
      public void onException(final int code, final String message) {
        rejectPositivoPrint(
          "STONE_L400_PRINT_ERROR",
          resolveXchengPrinterErrorMessage(code, message),
          null
        );
      }
    }));
  }

  private void callXchengPrinterInit(IBinder service, IBinder callback) throws RemoteException {
    Parcel data = Parcel.obtain();
    Parcel reply = Parcel.obtain();
    try {
      data.writeInterfaceToken(XCHENG_PRINTER_DESCRIPTOR);
      data.writeStrongBinder(callback);
      if (!service.transact(XCHENG_PRINTER_INIT, data, reply, 0)) {
        throw new RemoteException("Serviço Stone L400 não aceitou inicialização da impressora.");
      }
      reply.readException();
    } finally {
      reply.recycle();
      data.recycle();
    }
  }

  private void callXchengPrinterPrintText(IBinder service, String text, IBinder callback) throws RemoteException {
    Parcel data = Parcel.obtain();
    Parcel reply = Parcel.obtain();
    try {
      data.writeInterfaceToken(XCHENG_PRINTER_DESCRIPTOR);
      data.writeString(text);
      data.writeStrongBinder(callback);
      if (!service.transact(XCHENG_PRINTER_PRINT_TEXT, data, reply, 0)) {
        throw new RemoteException("Serviço Stone L400 não aceitou texto da impressão.");
      }
      reply.readException();
    } finally {
      reply.recycle();
      data.recycle();
    }
  }

  private void callXchengPrinterPrintBitmap(IBinder service, Bitmap bitmap, IBinder callback) throws RemoteException {
    if (service == null) {
      throw new RemoteException("Serviço Positivo indisponível.");
    }
    if (bitmap == null || bitmap.isRecycled()) {
      throw new RemoteException("Bitmap inválido para impressão Stone L400.");
    }

    Parcel data = Parcel.obtain();
    Parcel reply = Parcel.obtain();
    try {
      data.writeInterfaceToken(XCHENG_PRINTER_DESCRIPTOR);
      data.writeInt(1);
      bitmap.writeToParcel(data, 0);
      data.writeStrongBinder(callback);
      if (!service.transact(XCHENG_PRINTER_PRINT_BITMAP, data, reply, 0)) {
        throw new RemoteException("Serviço Stone L400 não aceitou imagem da impressão.");
      }
      reply.readException();
    } finally {
      reply.recycle();
      data.recycle();
    }
  }

  private List<ReceiptPrintLine> collectReceiptPrintLines(String content) throws JSONException {
    List<ReceiptPrintLine> lines = new ArrayList<>();
    String raw = safePreserve(content);
    if (raw.trim().isEmpty()) {
      return lines;
    }

    lastPrintedSeparator = false;
    suppressNextSeparator = false;
    pendingWaitersHeader = false;
    pendingSummaryMetricLine = null;

    String trimmed = raw.trim();
    if (trimmed.startsWith("[") || trimmed.startsWith("{")) {
      try {
        Object parsed = new JSONTokener(trimmed).nextValue();
        collectReceiptJsonPayload(lines, parsed);
        flushPendingSummaryMetricLine(lines, "left", "medium", "");
        return lines;
      } catch (JSONException ignored) {
      }
    }

    collectReceiptPlainText(lines, raw);
    flushPendingSummaryMetricLine(lines, "left", "medium", "");
    return lines;
  }

  private void collectReceiptJsonPayload(List<ReceiptPrintLine> lines, Object payload) throws JSONException {
    if (payload == null) {
      return;
    }

    if (payload instanceof JSONArray) {
      JSONArray array = (JSONArray) payload;
      for (int index = 0; index < array.length(); index++) {
        collectReceiptJsonPayload(lines, array.opt(index));
      }
      return;
    }

    if (payload instanceof JSONObject) {
      JSONObject command = (JSONObject) payload;

      if (command.has("commands")) {
        collectReceiptJsonPayload(lines, command.optJSONArray("commands"));
        return;
      }

      if (command.has("data")) {
        collectReceiptJsonPayload(lines, command.optJSONArray("data"));
        return;
      }

      String type = safeLower(command.optString("type"));
      String text = safePreserve(command.optString("content"));
      if ("line".equals(type) && text.trim().isEmpty()) {
        text = "--------------------------------";
      }

      collectReceiptStyledLine(
        lines,
        text,
        command.optString("align"),
        command.optString("size"),
        command.optString("style")
      );
      return;
    }

    if (payload instanceof String) {
      collectReceiptPlainText(lines, (String) payload);
    }
  }

  private void collectReceiptPlainText(List<ReceiptPrintLine> lines, String content) {
    String normalized = safePreserve(content).replace("\r\n", "\n").replace('\r', '\n');
    String[] rawLines = normalized.split("\n", -1);
    for (String line : rawLines) {
      collectReceiptStyledLine(lines, line, "left", "medium", "");
    }
  }

  private void collectReceiptStyledLine(
    List<ReceiptPrintLine> lines,
    String text,
    String align,
    String size,
    String style
  ) {
    String value = safePreserve(text);
    String trimmedValue = value.trim();

    if (pendingSummaryMetricLine != null) {
      if (isPeopleCountLine(trimmedValue)) {
        collectReceiptSingleLine(lines, pendingSummaryMetricLine + "    " + trimmedValue, align, size, style);
        pendingSummaryMetricLine = null;
        lastPrintedSeparator = false;
        return;
      }

      flushPendingSummaryMetricLine(lines, align, size, style);
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
      collectReceiptSingleLine(lines, normalizeConferenceLine(trimmedValue), "center", "medium", "bold");
      lastPrintedSeparator = false;
      suppressNextSeparator = true;
      return;
    }

    if (isItemsCountLine(trimmedValue)) {
      pendingSummaryMetricLine = trimmedValue;
      return;
    }

    if (isPendingValueLine(value)) {
      collectReceiptSingleLine(lines, normalizePendingValueLine(value), "center", "medium", "bold");
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
      collectReceiptSingleLine(lines, "GARCONS: " + trimmedValue, "center", "small", "bold");
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

    collectReceiptSingleLine(lines, value, align, size, style);
    lastPrintedSeparator = separator;
    suppressNextSeparator = !separator && shouldSuppressFollowingSeparator(trimmedValue);
  }

  private void flushPendingSummaryMetricLine(List<ReceiptPrintLine> lines, String align, String size, String style) {
    if (pendingSummaryMetricLine == null) {
      return;
    }
    collectReceiptSingleLine(lines, pendingSummaryMetricLine, align, size, style);
    pendingSummaryMetricLine = null;
    lastPrintedSeparator = false;
  }

  private void collectReceiptSingleLine(
    List<ReceiptPrintLine> lines,
    String text,
    String align,
    String size,
    String style
  ) {
    lines.add(new ReceiptPrintLine(text, align, size, style));
  }

  private List<Bitmap> renderPositivoReceiptBitmapChunks(List<ReceiptPrintLine> lines) {
    List<Bitmap> chunks = new ArrayList<>();
    List<Bitmap> chunk = new ArrayList<>();
    int chunkHeight = 0;

    try {
      for (ReceiptPrintLine line : lines) {
        Bitmap bitmap = renderReceiptLineBitmap(line.text, line.align, line.size, line.style);
        if (chunkHeight > 0 && chunkHeight + bitmap.getHeight() > POSITIVO_BITMAP_CHUNK_MAX_HEIGHT) {
          chunks.add(combineReceiptBitmapChunk(chunk, chunkHeight));
          recycleBitmaps(chunk);
          chunk = new ArrayList<>();
          chunkHeight = 0;
        }
        chunk.add(bitmap);
        chunkHeight += bitmap.getHeight();
      }

      Bitmap feed = renderBlankReceiptBitmap(POSITIVO_BOTTOM_FEED_HEIGHT);
      if (chunkHeight > 0 && chunkHeight + feed.getHeight() > POSITIVO_BITMAP_CHUNK_MAX_HEIGHT) {
        chunks.add(combineReceiptBitmapChunk(chunk, chunkHeight));
        recycleBitmaps(chunk);
        chunk = new ArrayList<>();
        chunkHeight = 0;
      }
      chunk.add(feed);
      chunkHeight += feed.getHeight();

      if (!chunk.isEmpty()) {
        chunks.add(combineReceiptBitmapChunk(chunk, chunkHeight));
      }
    } finally {
      recycleBitmaps(chunk);
    }

    return chunks;
  }

  private Bitmap combineReceiptBitmapChunk(List<Bitmap> bitmaps, int height) {
    int bitmapHeight = Math.max(height, 1);
    Bitmap combined = Bitmap.createBitmap(SUNMI_PAPER_WIDTH, bitmapHeight, Bitmap.Config.ARGB_8888);
    Canvas canvas = new Canvas(combined);
    canvas.drawColor(Color.WHITE);

    int y = 0;
    for (Bitmap bitmap : bitmaps) {
      if (bitmap != null && !bitmap.isRecycled()) {
        canvas.drawBitmap(bitmap, 0, y, null);
        y += bitmap.getHeight();
      }
    }

    return combined;
  }

  private Bitmap renderBlankReceiptBitmap(int height) {
    Bitmap bitmap = Bitmap.createBitmap(SUNMI_PAPER_WIDTH, Math.max(1, height), Bitmap.Config.ARGB_8888);
    Canvas canvas = new Canvas(bitmap);
    canvas.drawColor(Color.WHITE);
    return bitmap;
  }

  private void recycleBitmap(Bitmap bitmap) {
    if (bitmap != null && !bitmap.isRecycled()) {
      bitmap.recycle();
    }
  }

  private void recycleBitmaps(List<Bitmap> bitmaps) {
    if (bitmaps == null) {
      return;
    }

    for (Bitmap bitmap : bitmaps) {
      recycleBitmap(bitmap);
    }
    bitmaps.clear();
  }

  private String buildPositivoPrintableText(String content) throws JSONException {
    String raw = safePreserve(content).replace("\r\n", "\n").replace('\r', '\n');
    String trimmed = raw.trim();
    if (trimmed.startsWith("[") || trimmed.startsWith("{")) {
      Object parsed = new JSONTokener(trimmed).nextValue();
      StringBuilder builder = new StringBuilder();
      appendPositivoPrintableText(builder, parsed);
      return stripPrinterMarkup(builder.toString());
    }
    return stripPrinterMarkup(raw);
  }

  private void appendPositivoPrintableText(StringBuilder builder, Object payload) throws JSONException {
    if (payload == null || payload == JSONObject.NULL) {
      return;
    }

    if (payload instanceof JSONArray) {
      JSONArray array = (JSONArray) payload;
      for (int index = 0; index < array.length(); index++) {
        appendPositivoPrintableText(builder, array.opt(index));
      }
      return;
    }

    if (payload instanceof JSONObject) {
      JSONObject command = (JSONObject) payload;
      if (command.has("commands")) {
        appendPositivoPrintableText(builder, command.optJSONArray("commands"));
        return;
      }
      if (command.has("data")) {
        appendPositivoPrintableText(builder, command.optJSONArray("data"));
        return;
      }

      String type = safeLower(command.optString("type"));
      String text = safePreserve(command.optString("content"));
      if ("line".equals(type) && text.trim().isEmpty()) {
        text = "--------------------------------";
      }
      if (!text.isEmpty() || "text".equals(type) || "line".equals(type)) {
        builder.append(text).append('\n');
      }
      return;
    }

    if (payload instanceof String) {
      builder.append((String) payload).append('\n');
    }
  }

  private String stripPrinterMarkup(String value) {
    return safePreserve(value)
      .replaceAll("<[^>\\n]+>", "")
      .replaceAll("\\n[ \\t]+", "\n")
      .replaceAll("[ \\t]+\\n", "\n")
      .replaceAll("\\n{3,}", "\n\n")
      .trim();
  }

  private String ensurePositivoFeed(String text) {
    String normalized = safePreserve(text).replace("\r\n", "\n").replace('\r', '\n').trim();
    return normalized + "\n\n\n";
  }

  private void resolvePositivoPrint(final String message) {
    timeoutHandler.post(new Runnable() {
      @Override
      public void run() {
        unbindPositivoPrinter();
        if (pendingPromise == null || !OPERATION_PRINT.equals(pendingOperation)) {
          return;
        }

        WritableMap response = Arguments.createMap();
        response.putBoolean("printed", true);
        response.putString("message", firstNonEmpty(message, "Impressão concluída na Stone L400."));
        response.putString("operation", "positivo");
        resolveAndClear(response);
      }
    });
  }

  private void rejectPositivoPrint(final String code, final String message, final Throwable error) {
    timeoutHandler.post(new Runnable() {
      @Override
      public void run() {
        unbindPositivoPrinter();
        if (pendingPromise == null || !OPERATION_PRINT.equals(pendingOperation)) {
          return;
        }
        rejectAndClear(code, message, error);
      }
    });
  }

  private void unbindPositivoPrinter() {
    ReactApplicationContext context = getReactApplicationContext();
    if (positivoPrinterConnection != null) {
      try {
        context.unbindService(positivoPrinterConnection);
      } catch (Throwable ignored) {
      }
    }
    positivoPrinterConnection = null;
    positivoPrinterService = null;
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

      // DANFCe da NFC-e: o servidor manda a imagem do cupom fiscal em base64
      // ({type:'image', imagePath|imageData}) - imprime como bitmap.
      if ("image".equals(type)) {
        String imageBase64 = safePreserve(command.optString("imagePath"));
        if (imageBase64.trim().isEmpty()) {
          imageBase64 = safePreserve(command.optString("imageData"));
        }
        printSunmiImage(imageBase64);
        return;
      }

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

  // Imprime uma imagem base64 (ex.: DANFCe) na impressora Sunmi da Stone,
  // redimensionada para a largura do papel e fatiada em blocos para nao
  // estourar o limite de altura de bitmap do servico.
  private void printSunmiImage(String imageBase64) throws RemoteException {
    String raw = safePreserve(imageBase64).trim();
    if (raw.isEmpty()) {
      return;
    }

    Bitmap source = null;
    Bitmap scaled = null;
    try {
      byte[] bytes = Base64.decode(raw, Base64.DEFAULT);
      source = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
      if (source == null || source.getWidth() <= 0 || source.getHeight() <= 0) {
        return;
      }

      int targetWidth = SUNMI_PAPER_WIDTH;
      int targetHeight = Math.max(1, Math.round(source.getHeight() * (targetWidth / (float) source.getWidth())));
      scaled = Bitmap.createScaledBitmap(source, targetWidth, targetHeight, true);

      final int chunkMaxHeight = 512;
      int offsetY = 0;
      while (offsetY < scaled.getHeight()) {
        int chunkHeight = Math.min(chunkMaxHeight, scaled.getHeight() - offsetY);
        Bitmap chunk = Bitmap.createBitmap(scaled, 0, offsetY, targetWidth, chunkHeight);
        try {
          sunmiPrinterService.printBitmapCustom(chunk, SUNMI_BITMAP_TYPE_BLACK_AND_WHITE, null);
        } finally {
          if (!chunk.isRecycled()) {
            chunk.recycle();
          }
        }
        offsetY += chunkHeight;
      }
    } catch (RemoteException error) {
      throw error;
    } catch (Throwable ignored) {
      // Imagem invalida: segue sem interromper o restante da impressao.
    } finally {
      if (scaled != null && !scaled.isRecycled()) {
        scaled.recycle();
      }
      if (source != null && !source.isRecycled() && source != scaled) {
        source.recycle();
      }
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

  private String resolveXchengPrinterErrorMessage(int code, String message) {
    String normalizedMessage = safe(message).trim();
    if (!normalizedMessage.isEmpty() && !"null".equalsIgnoreCase(normalizedMessage)) {
      return normalizedMessage;
    }
    if (code == -40001) return "Erro de comunicação com a impressora Stone L400.";
    if (code == -40002) return "Impressora Stone L400 sem papel.";
    if (code == -40003) return "Impressora Stone L400 superaquecida.";
    if (code == -40004) return "Imagem da impressão Stone L400 não encontrada.";
    if (code == -40005) return "Falha genérica na impressora Stone L400.";
    if (code == -40006) return "Parâmetro inválido para impressão Stone L400.";
    if (code == -60009) return "Bitmap inválido para impressão Stone L400.";
    if (code == -60010) return "Largura de bitmap inválida para Stone L400.";
    if (code == -60011) return "Cor de bitmap inválida para Stone L400.";
    if (code == -60012) return "Falha ao abrir arquivo de impressão Stone L400.";
    if (code == -60013) return "Parâmetro inválido para impressão Stone L400.";
    if (code == -60014) return "Arquivo de impressão Stone L400 não existe.";
    if (code == -60015) return "Impressora Stone L400 ocupada.";
    if (code == -60016) return "Buffer de impressão Stone L400 excedido.";
    if (code == -60017) return "Impressão Stone L400 interrompida.";
    return "Falha na impressão Stone L400. Código " + code + ".";
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
        if (OPERATION_PRINT.equals(pendingOperation)) {
          unbindSunmiPrinter();
          unbindPositivoPrinter();
        }
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
    pendingPositivoPrintContent = null;
    clearTimeout();
    if (local != null) {
      local.resolve(result);
    }
  }

  private void rejectAndClear(String code, String message, Throwable error) {
    Promise local = pendingPromise;
    pendingPromise = null;
    pendingOperation = null;
    pendingPositivoPrintContent = null;
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
