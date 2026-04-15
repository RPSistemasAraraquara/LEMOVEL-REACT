package com.getnet.posdigital.card;

import android.os.Parcel;
import android.os.Parcelable;

public class CardResponse implements Parcelable {
  public static final Creator<CardResponse> CREATOR = new Creator<CardResponse>() {
    @Override
    public CardResponse createFromParcel(Parcel source) {
      return new CardResponse(source);
    }

    @Override
    public CardResponse[] newArray(int size) {
      return new CardResponse[size];
    }
  };

  private String pan;
  private String type;
  private String track1;
  private String track2;
  private String track3;
  private String serviceCode;
  private String expireDate;

  public CardResponse() {
  }

  public CardResponse(Parcel in) {
    this.pan = in.readString();
    this.type = in.readString();
    this.track1 = in.readString();
    this.track2 = in.readString();
    this.track3 = in.readString();
    this.serviceCode = in.readString();
    this.expireDate = in.readString();
  }

  public String getPan() {
    return pan;
  }

  public String getType() {
    return type;
  }

  public String getTrack1() {
    return track1;
  }

  public String getTrack2() {
    return track2;
  }

  public String getTrack3() {
    return track3;
  }

  public String getServiceCode() {
    return serviceCode;
  }

  public String getExpireDate() {
    return expireDate;
  }

  @Override
  public int describeContents() {
    return 0;
  }

  @Override
  public void writeToParcel(Parcel dest, int flags) {
    dest.writeString(pan);
    dest.writeString(type);
    dest.writeString(track1);
    dest.writeString(track2);
    dest.writeString(track3);
    dest.writeString(serviceCode);
    dest.writeString(expireDate);
  }
}
