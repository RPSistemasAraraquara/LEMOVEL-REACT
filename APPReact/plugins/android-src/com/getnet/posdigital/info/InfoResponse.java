package com.getnet.posdigital.info;

import android.os.Parcel;
import android.os.Parcelable;

public class InfoResponse implements Parcelable {
  public static final Creator<InfoResponse> CREATOR = new Creator<InfoResponse>() {
    @Override
    public InfoResponse createFromParcel(Parcel source) {
      return new InfoResponse(source);
    }

    @Override
    public InfoResponse[] newArray(int size) {
      return new InfoResponse[size];
    }
  };

  private String sdkVersion;
  private String bcVersion;
  private String osVersion;
  private String serialNumber;
  private String psamId;
  private String model;
  private String manufacture;
  private String imsi;
  private String imei;
  private String iccid;
  private String romVersion;
  private String androidKernelVersion;
  private String androidOSVersion;
  private String hardwareVersion;
  private String firmwareVersion;
  private String hardWareSn;

  public InfoResponse() {
  }

  public InfoResponse(Parcel in) {
    this.sdkVersion = in.readString();
    this.bcVersion = in.readString();
    this.osVersion = in.readString();
    this.serialNumber = in.readString();
    this.psamId = in.readString();
    this.model = in.readString();
    this.manufacture = in.readString();
    this.imsi = in.readString();
    this.imei = in.readString();
    this.iccid = in.readString();
    this.romVersion = in.readString();
    this.androidKernelVersion = in.readString();
    this.androidOSVersion = in.readString();
    this.hardwareVersion = in.readString();
    this.firmwareVersion = in.readString();
    this.hardWareSn = in.readString();
  }

  public String getSdkVersion() {
    return sdkVersion;
  }

  public String getBcVersion() {
    return bcVersion;
  }

  public String getOsVersion() {
    return osVersion;
  }

  public String getSerialNumber() {
    return serialNumber;
  }

  public String getPsamId() {
    return psamId;
  }

  public String getModel() {
    return model;
  }

  public String getManufacture() {
    return manufacture;
  }

  public String getImsi() {
    return imsi;
  }

  public String getImei() {
    return imei;
  }

  public String getIccid() {
    return iccid;
  }

  public String getRomVersion() {
    return romVersion;
  }

  public String getAndroidKernelVersion() {
    return androidKernelVersion;
  }

  public String getAndroidOSVersion() {
    return androidOSVersion;
  }

  public String getHardwareVersion() {
    return hardwareVersion;
  }

  public String getFirmwareVersion() {
    return firmwareVersion;
  }

  public String getHardWareSn() {
    return hardWareSn;
  }

  @Override
  public int describeContents() {
    return 0;
  }

  @Override
  public void writeToParcel(Parcel dest, int flags) {
    dest.writeString(sdkVersion);
    dest.writeString(bcVersion);
    dest.writeString(osVersion);
    dest.writeString(serialNumber);
    dest.writeString(psamId);
    dest.writeString(model);
    dest.writeString(manufacture);
    dest.writeString(imsi);
    dest.writeString(imei);
    dest.writeString(iccid);
    dest.writeString(romVersion);
    dest.writeString(androidKernelVersion);
    dest.writeString(androidOSVersion);
    dest.writeString(hardwareVersion);
    dest.writeString(firmwareVersion);
    dest.writeString(hardWareSn);
  }
}
