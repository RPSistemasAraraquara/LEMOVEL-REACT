package sunmi.paylib.adapter.bean;

import android.os.Parcel;
import android.os.Parcelable;

import sunmi.paylib.adapter.utils.ByteUtil;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/21 2:25 下午
 */
public class SPDUKPTResult implements Parcelable {
    private static final String TAG = "SPDUKPTResult";

    private byte[] ksnSP;
    private byte[] resultSP;

    public SPDUKPTResult() {
    }

    protected SPDUKPTResult(Parcel in) {
        ksnSP = in.createByteArray();
        resultSP = in.createByteArray();
    }

    public static final Creator<SPDUKPTResult> CREATOR = new Creator<SPDUKPTResult>() {
        @Override
        public SPDUKPTResult createFromParcel(Parcel in) {
            return new SPDUKPTResult(in);
        }

        @Override
        public SPDUKPTResult[] newArray(int size) {
            return new SPDUKPTResult[size];
        }
    };

    public byte[] getKsnSP() {
        return ksnSP;
    }

    public void setKsnSP(byte[] ksnSP) {
        this.ksnSP = ksnSP;
    }

    public byte[] getResultSP() {
        return resultSP;
    }

    public void setResultSP(byte[] resultSP) {
        this.resultSP = resultSP;
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeByteArray(ksnSP);
        dest.writeByteArray(resultSP);
    }

    @Override
    public String toString() {
        return "SPDUKPTResult{" +
                "ksnSP=" + ByteUtil.bytes2HexStr(ksnSP) +
                ", resultSP=" + ByteUtil.bytes2HexStr(resultSP) +
                '}';
    }
}
