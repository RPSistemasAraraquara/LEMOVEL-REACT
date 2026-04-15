package sunmi.paylib.adapter.spiphonemanager;

import android.app.sunmi.SunmiCustomerManager;
import android.content.Context;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/9/5 11:06 上午
 */
public class SPIPhoneManager {
    private static final String TAG = "SPIPhoneManager";

    private Context mContext;

    private SunmiCustomerManager mSunmiCustomerManager;


    private static final SPIPhoneManager INSTANCE = new SPIPhoneManager();

    private SPIPhoneManager() {
    }

    public static SPIPhoneManager getInstance() {
        return INSTANCE;
    }

    public void init(Context context) {
        mContext = context.getApplicationContext();
        mSunmiCustomerManager = (SunmiCustomerManager) mContext.getSystemService("sunmi_customer");
    }

    public void setDefaultDataSubIdSP(int subId) {
        mSunmiCustomerManager.setDefaultDataSubIdSP(subId);
    }

}
