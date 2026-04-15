package com.getnet.posdigital.info;

import com.getnet.posdigital.info.InfoResponse;

interface IInfoCallback {
  void onError(String error);
  void onInfo(in InfoResponse infoResponse);
}
