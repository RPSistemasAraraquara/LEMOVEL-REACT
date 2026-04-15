package com.getnet.posdigital.mifare;

interface IMifareCallback {
  void onCard(int cardType);
  void onError(String error);
}
