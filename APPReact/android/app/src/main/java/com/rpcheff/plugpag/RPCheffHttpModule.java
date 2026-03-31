package com.rpcheff.plugpag;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.WritableMap;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

public class RPCheffHttpModule extends ReactContextBaseJavaModule {
  public RPCheffHttpModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  public String getName() {
    return "RPCheffHttp";
  }

  @ReactMethod
  public void request(
    String urlString,
    String method,
    ReadableMap headers,
    String body,
    int timeoutMs,
    Promise promise
  ) {
    HttpURLConnection connection = null;

    try {
      URL url = new URL(urlString);
      connection = (HttpURLConnection) url.openConnection();

      String requestMethod = method == null ? "GET" : method.toUpperCase();
      int resolvedTimeoutMs = timeoutMs > 0 ? timeoutMs : 15000;

      connection.setRequestMethod(requestMethod);
      connection.setConnectTimeout(resolvedTimeoutMs);
      connection.setReadTimeout(resolvedTimeoutMs);
      connection.setUseCaches(false);
      connection.setInstanceFollowRedirects(true);

      if (headers != null) {
        ReadableMapKeySetIterator iterator = headers.keySetIterator();
        while (iterator.hasNextKey()) {
          String key = iterator.nextKey();
          if (headers.isNull(key)) {
            continue;
          }
          connection.setRequestProperty(key, headers.getString(key));
        }
      }

      boolean hasBody =
        body != null &&
        !body.isEmpty() &&
        !"GET".equals(requestMethod) &&
        !"HEAD".equals(requestMethod);

      if (hasBody) {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        connection.setDoOutput(true);
        connection.setFixedLengthStreamingMode(bytes.length);
        try (OutputStream outputStream = connection.getOutputStream()) {
          outputStream.write(bytes);
          outputStream.flush();
        }
      }

      int status = connection.getResponseCode();
      InputStream stream = status >= 400 ? connection.getErrorStream() : connection.getInputStream();

      WritableMap result = Arguments.createMap();
      result.putInt("status", status);
      result.putString("statusText", connection.getResponseMessage());
      result.putString("body", readStream(stream));
      promise.resolve(result);
    } catch (Exception exception) {
      promise.reject("RPCHEFF_HTTP_ERROR", exception);
    } finally {
      if (connection != null) {
        connection.disconnect();
      }
    }
  }

  private String readStream(InputStream stream) throws Exception {
    if (stream == null) {
      return "";
    }

    try (InputStream inputStream = stream; ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
      byte[] buffer = new byte[4096];
      int read;
      while ((read = inputStream.read(buffer)) != -1) {
        outputStream.write(buffer, 0, read);
      }
      return outputStream.toString(StandardCharsets.UTF_8.name());
    }
  }
}
