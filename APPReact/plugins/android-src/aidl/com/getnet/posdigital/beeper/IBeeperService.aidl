package com.getnet.posdigital.beeper;

interface IBeeperService {
  void success();
  void error();
  void digit();
  void nfc();
  void custom(int value);
}
