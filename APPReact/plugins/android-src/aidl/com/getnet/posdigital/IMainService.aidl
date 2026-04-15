package com.getnet.posdigital;

import com.getnet.posdigital.beeper.IBeeperService;
import com.getnet.posdigital.camera.ICameraService;
import com.getnet.posdigital.card.ICardService;
import com.getnet.posdigital.info.IInfoService;
import com.getnet.posdigital.led.ILedService;
import com.getnet.posdigital.mifare.IMifareService;
import com.getnet.posdigital.printer.IPrinterService;
import com.getnet.posdigital.stat.IStatService;

interface IMainService {
  IPrinterService getPrinter();
  ICardService getCard();
  IMifareService getMifare();
  ILedService getLed();
  ICameraService getCamera();
  IBeeperService getBeeper();
  IInfoService getInfo();
  IStatService getStatistic();
}
