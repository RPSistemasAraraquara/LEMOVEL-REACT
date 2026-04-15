package com.sunmi.tmsmaster.aidl.networkmanager;

import android.os.Parcel;
import android.os.Parcelable;

/**
 * Created by sm2073-LiXing on 2021/11/9 2:20 下午
 * Describe: Apn Model
 */
public class ApnModel implements Parcelable {
    public String id;
    public String name;
    public String apn;

    public ApnModel(String id, String name, String apn) {
        this.id = id;
        this.name = name;
        this.apn = apn;
    }

    public ApnModel() {
    }

    protected ApnModel(Parcel in) {
        id = in.readString();
        name = in.readString();
        apn = in.readString();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(id);
        dest.writeString(name);
        dest.writeString(apn);
    }

    @Override
    public int describeContents() {
        return 0;
    }

    public static final Creator<ApnModel> CREATOR = new Creator<ApnModel>() {
        @Override
        public ApnModel createFromParcel(Parcel in) {
            return new ApnModel(in);
        }

        @Override
        public ApnModel[] newArray(int size) {
            return new ApnModel[size];
        }
    };

    @Override
    public String toString() {
        return "ApnModel{" +
                "id='" + id + '\'' +
                ", name='" + name + '\'' +
                ", apn='" + apn + '\'' +
                '}';
    }
}
