package sunmi.paylib.adapter.bean;

import android.os.Parcel;
import android.os.Parcelable;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/21 2:33 下午
 */
public enum EAlgorithmTypeSP implements Parcelable {
    _2TDEA_,
    _3TDEA_,
    _AES128_,
    _AES192_,
    _AES256_,
    _HMAC128_,
    _HMAC192_,
    _HMAC256_;


    public static final Creator<EAlgorithmTypeSP> CREATOR = new Creator<EAlgorithmTypeSP>() {
        @Override
        public EAlgorithmTypeSP createFromParcel(Parcel in) {
            return EAlgorithmTypeSP.values()[in.readInt()];
        }

        @Override
        public EAlgorithmTypeSP[] newArray(int size) {
            return new EAlgorithmTypeSP[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(ordinal());
    }
}
