package sunmi.paylib;

import android.annotation.SuppressLint;
import android.app.sunmi.NTPServerParam;
import android.app.sunmi.PosMenu;
import android.app.sunmi.SunmiCustomerManager;
import android.content.Context;
import android.os.IBinder;
import android.os.RemoteException;
import android.provider.Settings;
import android.util.Log;

import com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/6/8 11:25 上午
 */
public class SunmiCustomApi {
    private static final String TAG = "SunmiCustomApi";

    private Context mContext;

    private SunmiCustomerManager mSunmiCustomerManager;

    private static final SunmiCustomApi INSTANCE = new SunmiCustomApi();

    private SunmiCustomApi() {
    }

    static SunmiCustomApi getInstance() {
        return INSTANCE;
    }


    @SuppressLint("WrongConstant")
    public void init(Context context) {
        mContext = context.getApplicationContext();
        mSunmiCustomerManager = (SunmiCustomerManager) mContext.getSystemService("sunmi_customer");
    }

    /**
     * Add a service to ServiceManager
     *
     * @param name
     * @param service
     */
    public void addService(String name, IBinder service) {
        LogUtil.e(TAG, "service name:" + name);
        mSunmiCustomerManager.addService(name, service);
    }

    /**
     * The number(0,1) refers to PosMenu.SETTING_MENU
     * 0:true;1:false
     *
     * @param settingMenu
     */
    public void disablePosMenu(PosMenu.SETTING_MENU settingMenu, boolean enabled) {
        PosMenu posMenu = new PosMenu();
        posMenu.initSettingMenu();
        posMenu.setSettingMenu(settingMenu, enabled);
        LogUtil.e(TAG, "disablePosMenu param:" + posMenu.getSettingMenu());
        mSunmiCustomerManager.disablePosMenu(posMenu.getSettingMenu());
    }

    /**
     * When the power button is pressed, Android systems usually show a screen to confirm
     * whether to turn it off or not.We need a way to enable and disable this confirmation
     *
     * @param enabled true: show dialog; false: not show dialog
     */
    public void enableShutdownConfirm(boolean enabled) {
        LogUtil.e(TAG, "enableShutdownConfirm:" + enabled);
        mSunmiCustomerManager.enableShutdownConfirm(enabled);
    }

    /**
     * Check if volumeKey is enabled or not
     *
     * @return
     */
    public boolean isVolumeKeyEnabled() {
        LogUtil.e(TAG, "isVolumeKeyEnabled");
        return mSunmiCustomerManager.isVolumeKeyEnabled();
    }


    /**
     * Turn Off Wifi Hotspot
     */
    public void turnOffWifiHotspot() {
        mSunmiCustomerManager.turnOffWifiHotspot();
    }

    /**
     * Turn on WifiHotspot with hotspot name
     *
     * @param ssid
     * @param preShareKey
     * @param keyManagement
     */
    public void turnOnWifiHotspot(String ssid, String preShareKey, int keyManagement) {
        mSunmiCustomerManager.turnOnWifiHotspot(ssid, preShareKey, keyManagement);
    }

    /**
     * Check if hotspot is enabled
     *
     * @return
     */
    public boolean isWifiHotspotEnable() {
        return mSunmiCustomerManager.isWifiHotspotEnable();
    }


    /**
     * set Boot logo
     *
     * @param filePath
     * @return
     */
    public boolean setBootLogo(String filePath) {

        return saveBootLogoToLocal(filePath);
    }

    private boolean saveBootLogoToLocal(String path) {
        String bootLogoDir = "/sunmi/ckd/etc/";
        try {
            InputStream is = new FileInputStream(new File(path));
            File newFile = new File(bootLogoDir + "logo.bmp");
            if (newFile.exists()) {
                newFile.delete();
            }
            FileOutputStream out = new FileOutputStream(newFile);
            try {
                byte[] buffer = new byte[4096];
                int bytesRead;
                while ((bytesRead = is.read(buffer)) >= 0) {
                    out.write(buffer, 0, bytesRead);
                }
            } finally {
                out.flush();
                try {
                    out.getFD().sync();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                out.close();
            }
            Log.d(TAG, "copy end");
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }

        return true;
    }


    /**
     * Enable/disable Wifi DHCP
     *
     * @param enable
     */
    public void enableWifiDHCP(boolean enable) {
        mSunmiCustomerManager.enableWifiDHCP(enable);
    }

    /**
     * Set object NTP. This object has the getter and setter of NTPServerName(String)
     * and server(String)
     *
     * @return
     */
    public NTPServerParam getNTPServerParam() {
        return mSunmiCustomerManager.getNTPServerParam();
    }

    /**
     * Set object NTP. This object has the getter and setter of NTPServerName(String)
     * and server(String)
     *
     * @param param
     */
    public void setNTPServerParam(NTPServerParam param) {
        mSunmiCustomerManager.setNTPServerParam(param);
    }

    /**
     * Clears the list of recently used programs. (if null exlude all programs)
     *
     * @param excludePackageNames
     */
    public void removeRecentTasks(List<String> excludePackageNames) {
        mSunmiCustomerManager.removeRecentTasks(excludePackageNames);
    }

    /**
     * Enable/disable password prompt to access Settings.
     * (Default password should be "Sunmi123@")
     *
     * @param pkgName
     * @param password
     */
    public void setSettingsNeedPassword(String pkgName, String password) {
        mSunmiCustomerManager.setSettingsNeedPassword(pkgName, password);
    }

    /**
     * Set wifi static IP. Wifi network must be connected.
     *
     * @param ipAddr
     * @param gateway
     * @param networkPrefixLength
     * @param dns1
     * @param dns2
     * @param reconnect
     */
    public void setWifiStaticIp(String ipAddr, String gateway, int networkPrefixLength, String dns1, String dns2, boolean reconnect) {
        mSunmiCustomerManager.setWifiStaticIp(ipAddr, gateway, networkPrefixLength, dns1, dns2, reconnect);
    }


    public void setChargeLimit(boolean limit) {
        mSunmiCustomerManager.setChargeLimit(limit);
    }

    public boolean enableEthernetTether(boolean enable) {
        return false;
    }

    public void setSearchAllWifi(boolean searchAllWifi) {
        mSunmiCustomerManager.setSearchAllWifi(searchAllWifi);
    }

    /**
     * Get the total length of Printer.
     *
     * @return The total length of Printer(Unit:mm)
     */
    public int getPrinterTotalLength() {
        return mSunmiCustomerManager.getPrinterTotalLength();
    }

    /**
     * Reset the total length of Printer
     */
    public void resetPrinterTotalLength() {
        mSunmiCustomerManager.resetPrinterTotalLength();
    }

    /**
     * Set the visibility for HeaderQsPanel in SystemUI
     *
     * @param visible true: show the panel of QS;
     *                false: hide the panel of QS;
     */
    public void setHeaderQsPanelVisible(boolean visible) {
        mSunmiCustomerManager.setHeaderQsPanelVisible(visible);
    }

    /**
     *
     * @param ssid ssid
     * @param password password
     * @param type security type,1-None,2-WEP,3-WPA/WPA2-Personal
     * @param callback connect callback
     * @throws RemoteException
     */
    public void connectToWifiNetwork(final String ssid, String password, int type, final onConnectWifiCallback callback) throws RemoteException {
        if (SunmiPayKernel.getInstance().mINetworkManager != null) {
            SunmiPayKernel.getInstance().mINetworkManager.addWifiSsid(ssid, password, type, new IUnifiedCallback.Stub() {
                @Override
                public void onCall(String result) throws RemoteException {
                    try {
                        JSONObject jsonObject = new JSONObject(result);
                        int code = jsonObject.getInt("resultCode");
                        if (code == 0) {
                            SunmiPayKernel.getInstance().mINetworkManager.connectWifiSsid(ssid, new IUnifiedCallback.Stub() {
                                @Override
                                public void onCall(String result) {
                                    try {
                                        JSONObject jsonObject = new JSONObject(result);
                                        int code = jsonObject.getInt("resultCode");
                                        if (code == 0) {
                                            callback.success();
                                        } else {
                                            callback.failure();
                                        }
                                    } catch (JSONException e) {
                                        e.printStackTrace();
                                        callback.failure();
                                    }
                                }
                            });
                        } else {
                            callback.failure();
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        callback.failure();
                    }
                }
            });
        } else {
            throw new RuntimeException("SDK not init");
        }
    }

    public interface onConnectWifiCallback {
        void success();

        void failure();
    }


}
