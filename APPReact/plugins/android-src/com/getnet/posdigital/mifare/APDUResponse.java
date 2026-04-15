package com.getnet.posdigital.mifare;

import android.os.Parcel;
import android.os.Parcelable;

public class APDUResponse implements Parcelable {
  public static final Creator<APDUResponse> CREATOR = new Creator<APDUResponse>() {
    @Override
    public APDUResponse createFromParcel(Parcel source) {
      return new APDUResponse(source);
    }

    @Override
    public APDUResponse[] newArray(int size) {
      return new APDUResponse[size];
    }
  };

  private int apduRet;
  private byte[] data;
  private byte sw1;
  private byte sw2;

  public APDUResponse() {
  }

  public APDUResponse(Parcel in) {
    this.apduRet = in.readInt();
    this.data = in.createByteArray();
    this.sw1 = in.readByte();
    this.sw2 = in.readByte();
  }

  public int getApduRet() {
    return apduRet;
  }

  public byte[] getData() {
    return data;
  }

  public byte getSw1() {
    return sw1;
  }

  public byte getSw2() {
    return sw2;
  }

  @Override
  public int describeContents() {
    return 0;
  }

  @Override
  public void writeToParcel(Parcel dest, int flags) {
    dest.writeInt(apduRet);
    dest.writeByteArray(data);
    dest.writeByte(sw1);
    dest.writeByte(sw2);
  }
}
