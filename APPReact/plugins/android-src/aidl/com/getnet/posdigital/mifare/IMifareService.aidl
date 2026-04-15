package com.getnet.posdigital.mifare;

import com.getnet.posdigital.mifare.APDUResponse;
import com.getnet.posdigital.mifare.IMifareActivateCallback;
import com.getnet.posdigital.mifare.IMifareCallback;

interface IMifareService {
  void searchCard(IMifareCallback callback);
  void searchCardAndActivate(IMifareActivateCallback callback);
  int activate(int cardType);
  void halt();
  String getCardSerialNo(int cardType);
  int authenticateSectorWithKeyA(int index, in byte[] key);
  int authenticateBlockWithKeyA(int index, in byte[] key);
  int authenticateSectorWithKeyB(int index, in byte[] key);
  int authenticateBlockWithKeyB(int index, in byte[] key);
  void close();
  int decrement(int index, int value);
  int increment(int index, int value);
  boolean isExist();
  String readBlock(int index);
  int restore(int index);
  int transfer(int index);
  int writeBlock(int index, String data);
  APDUResponse exchangeAPDU(in byte[] apduIn);
}
