package com.getnet.posdigital.card;

import com.getnet.posdigital.card.ICardCallback;

interface ICardService {
  void searchMag(long timeout, ICardCallback callback);
  void searchChip(long timeout, ICardCallback callback);
  void searchNFC(long timeout, ICardCallback callback);
  void search(long timeout, in String[] searchTypes, ICardCallback callback);
  void stopAllReaders();
}
