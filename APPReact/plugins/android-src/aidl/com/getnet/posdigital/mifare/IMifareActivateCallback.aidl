package com.getnet.posdigital.mifare;

interface IMifareActivateCallback {
  void onActivate(in byte[] uid);
  void onError(String error);
}
