package sunmi.paylib.adapter.spicomm;

import android.os.RemoteException;
import android.text.TextUtils;

import com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo;
import com.sunmi.tmsmaster.aidl.networkmanager.ApnModel;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import sunmi.paylib.SunmiPayKernel;
import sunmi.paylib.adapter.bean.EUartPortSP;
import sunmi.paylib.adapter.bean.SPUartParam;
import sunmi.paylib.adapter.spicomm.apn.SPApnInfo;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/29 1:48 下午
 */
public class SPICommManager {
    private static final String TAG = "SPICommManager";

    private static SPICommManager INSTANCE = new SPICommManager();

    private SPICommManager() {
    }

    public static SPICommManager getInstance() {
        return INSTANCE;
    }

    public SPIComm createUartCommSP(SPUartParam param) {

        return SPIComm.getInstance().init(param);


    }

    public List<SPApnInfo> getApnListSP() {
        try {
            int slotIdx = 0;
            String result = SunmiPayKernel.getInstance().mINetworkManager.getApnList_V2(slotIdx);
            if (TextUtils.isEmpty(result)) {
                return null;
            }

            List<SPApnInfo> spApnInfoList = new ArrayList<>();
            JSONArray jsonArray = new JSONArray(result);

            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject apnJSON = (JSONObject) jsonArray.get(i);
                SPApnInfo spApnInfo = new SPApnInfo();

                spApnInfo.setApnCarrierSP(apnJSON.getString("name"));
                spApnInfo.setApnSP(apnJSON.getString("apn"));
                spApnInfo.setAuthtypeSP(apnJSON.getInt("authtype"));
                spApnInfo.setMccSP(apnJSON.getString("mcc"));
                spApnInfo.setMmscSP(apnJSON.getString("mmsc"));
                spApnInfo.setMmsportSP(apnJSON.getString("mmsport"));
                spApnInfo.setMmsProxySP(apnJSON.getString("mmsproxy"));
                spApnInfo.setMncSP(apnJSON.getString("mnc"));
                spApnInfo.setPasswordSP(apnJSON.getString("password"));
                spApnInfo.setPortSP(apnJSON.getString("port"));
                spApnInfo.setProtocolSP(apnJSON.getString("protocol"));
                spApnInfo.setProxySP(apnJSON.getString("proxy"));
                spApnInfo.setRoamingProtocolSP(apnJSON.getString("roaming_protocol"));
                spApnInfo.setServerSP(apnJSON.getString("server"));
                spApnInfo.setTypeSP(apnJSON.getString("type"));
                spApnInfo.setUserSP(apnJSON.getString("user"));
                spApnInfo.setApnIdSP(apnJSON.getString("_id"));
                spApnInfoList.add(spApnInfo);
            }
            return spApnInfoList;
        } catch (RemoteException e) {
            e.printStackTrace();
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean removeApnSP(String apnID) {
        try {
            if (TextUtils.isEmpty(apnID)) {
                return false;
            }
            List<ApnModel> apnModelList = SunmiPayKernel.getInstance().mINetworkManager.getApnList();
            if (apnModelList == null || apnModelList.isEmpty()) {
                return false;
            }

            for (ApnModel apnModel : apnModelList) {
                if (apnID.equals(apnModel.id)) {
                    return SunmiPayKernel.getInstance().mINetworkManager.removeAPN(apnModel.name);
                }
            }
            return false;
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return false;
    }

    public int switchAPNSP(String name, String apn, String user,
                           String password, int authType) {
        int _id = checkApn(name, apn);
        int result = -1;
        if (_id != -1) {
            result = setApn(_id);
        } else {
            APNConfigInfo apnConfigInfo = new APNConfigInfo();
            apnConfigInfo.setName(name);
            apnConfigInfo.setApn(apn);
            apnConfigInfo.setUser(user);
            apnConfigInfo.setPassword(password);
            apnConfigInfo.setAuthtype(String.valueOf(authType));
            try {
                result = SunmiPayKernel.getInstance().mINetworkManager.addAPN(apnConfigInfo) ? 1 : -1;
            } catch (RemoteException e) {
                e.printStackTrace();
            }
            if (result == 1) {
                _id = checkApn(name, apn);
                if (_id != -1) {
                    result = setApn(_id);
                } else {
                    result = _id;
                }

            }
        }
        return result;
    }

    private int setApn(int id) {
        try {
            boolean result = SunmiPayKernel.getInstance().mINetworkManager.setAPN(id);
            if (result) {
                return 1;
            } else
                return -1;
        } catch (RemoteException e) {
            e.printStackTrace();
            return -1;
        }
    }

    private int checkApn(String name, String apn) {
        int _id = -1;
        try {
            List<ApnModel> data = SunmiPayKernel.getInstance().mINetworkManager.getApnList();
            if (data != null && data.size() > 0) {
                for (ApnModel apnModel : data) {
                    if (apnModel.name.equals(name) && apnModel.apn.equals(apn)) {
                        return Integer.parseInt(apnModel.id);
                    }
                }
            }
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        return _id;
    }

    public SPIComm getUartCommSP(SPUartParam param) {
        return SPIComm.getInstance().init(param);
    }


    public List<EUartPortSP> getUartPortListSP() {
        List<EUartPortSP> data = new ArrayList<>();
        data.add(EUartPortSP.COM1);
        return data;
    }


}
