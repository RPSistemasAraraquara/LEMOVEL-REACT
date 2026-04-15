package com.getnet.posdigital.card;

import com.getnet.posdigital.card.CardResponse;

interface ICardCallback {
  void onCard(in CardResponse response);
  void onError(String error);
  void onMessage(String message);
}
