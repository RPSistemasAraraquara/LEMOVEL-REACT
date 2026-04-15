package sunmi.paylib;

import android.os.Parcel;
import android.os.Parcelable;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/20 10:25
 */
public enum ScreenOffTime implements Parcelable {

    NEVER(0),//Never off screen
    TIMEOUT_15S(15000),//15 seconds off screen
    TIMEOUT_30S(30000),//30 seconds off screen
    TIMEOUT_60S(60000),//1 minute screen off
    TIMEOUT_120S(120000),//2 minute screen off
    TIMEOUT_300S(300000),//5 minute screen off
    TIMEOUT_600S(600000),//10 minute screen off
    TIMEOUT_1800S(1800000);//30 minute screen off

    private long value;

    ScreenOffTime(long time) {
        value = time;
    }


    public static final Creator<ScreenOffTime> CREATOR = new Creator<ScreenOffTime>() {
        @Override
        public ScreenOffTime createFromParcel(Parcel in) {
            return ScreenOffTime.values()[in.readInt()];
        }

        @Override
        public ScreenOffTime[] newArray(int size) {
            return new ScreenOffTime[size];
        }
    };

    public long value() {
        return value;
    }


    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(ordinal());
    }
}
