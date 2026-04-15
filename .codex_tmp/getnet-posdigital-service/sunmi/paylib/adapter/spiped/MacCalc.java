package sunmi.paylib.adapter.spiped;

import android.os.Bundle;
import android.os.RemoteException;

import com.sunmi.pay.hardware.aidl.AidlConstants;
import com.sunmi.pay.hardware.aidlv2.AidlConstantsV2;

import sunmi.paylib.LogUtil;
import sunmi.paylib.SunmiPayKernel;
import sunmi.paylib.adapter.bean.EPedMacModeSP;
import sunmi.paylib.adapter.bean.SPDUKPTResult;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/25 2:52 下午
 */
public class MacCalc {

    private static final String TAG = "MacCalc";


    public static MacCalc INSTANCE = new MacCalc();

    private MacCalc() {
    }


    static MacCalc getInstance() {
        return INSTANCE;
    }


    SPDUKPTResult dukptCalcMac(byte groupIndex, byte[] dataIn, byte mode) throws RemoteException {
        dataIn = paddingMultipleBy8(dataIn);
        int[] macMode = new int[1];
        int[] keyLength = new int[1];
        byte[] outData = new byte[8];
        int[] keySelect = new int[1];
        processAesMacType(groupIndex, mode, macMode, keyLength, keySelect);
        Bundle bundle = new Bundle();
        bundle.putInt("keySelect", keySelect[0]);
        bundle.putInt("keyIndex", groupIndex);
        bundle.putInt("keyLength", keyLength[0]);
        bundle.putInt("macType", macMode[0]);
        bundle.putByteArray("dataIn", dataIn);

        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.calcMacDukptExtended(bundle, outData);
        LogUtil.e(TAG, "计算MAC结果:" + ret);
        if (ret == 0) {
            SPDUKPTResult spdukptResult = new SPDUKPTResult();
            spdukptResult.setResultSP(outData);
            spdukptResult.setKsnSP(SPIPedUtil.getKsn());
            return spdukptResult;
        }
        return null;

    }

    private void processAesMacType(int index, int mode, int[] macMode, int[] keyLength,int[] keySelect) {
        switch (mode) {
            case 0x00:
                macMode[0] = AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL;
                SPIPedUtil.dukptIncreaseKSN(index);
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                break;
            case 0x01:
                macMode[0] = AidlConstantsV2.Security.MAC_ALG_FAST_MODE;
                SPIPedUtil.dukptIncreaseKSN(index);
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                break;
            case 0x02:
                macMode[0] = AidlConstantsV2.Security.MAC_ALG_X9_19;
                SPIPedUtil.dukptIncreaseKSN(index);
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                keyLength[0] = 8;
                break;
            case 0x03://CMAC
                macMode[0] = AidlConstants.Security.MAC_ALG_CMAC;
                SPIPedUtil.dukptIncreaseKSN(index);
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                break;
            case 0x05://HMAC
                macMode[0] = AidlConstants.Security.MAC_ALG_HMAC_SHA256;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                SPIPedUtil.dukptIncreaseKSN(index);
                break;
            case 0x20:
                macMode[0] = AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                break;
            case 0x21:
                macMode[0] = AidlConstantsV2.Security.MAC_ALG_FAST_MODE;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                break;
            case 0x22:
                macMode[0] = AidlConstantsV2.Security.MAC_ALG_X9_19;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                keyLength[0] = 8;
                break;
            case 0x23://CMAC
                macMode[0] = AidlConstants.Security.MAC_ALG_CMAC;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                break;
            case 0x25://HMAC
                macMode[0] = AidlConstants.Security.MAC_ALG_HMAC_SHA256;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
                break;
            case 0x40:
                macMode[0] = AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_RSP;
                break;
            case 0x41:
                macMode[0] = AidlConstantsV2.Security.MAC_ALG_FAST_MODE;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_RSP;
                break;
            case 0x42:
                macMode[0] = AidlConstantsV2.Security.MAC_ALG_X9_19;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_RSP;
                keyLength[0] = 8;
                break;
            case 0x43://CMAC
                macMode[0] = AidlConstants.Security.MAC_ALG_CMAC;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_RSP;
                break;
            case 0x45://HMAC
                macMode[0] = AidlConstants.Security.MAC_ALG_HMAC_SHA256;
                keySelect[0] = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_RSP;
                break;

        }
    }

    byte[] calcMac(byte keyIndex, byte[] dataIn, EPedMacModeSP mode) throws RemoteException {
        dataIn = paddingMultipleBy8(dataIn);
        byte[] outData = new byte[8];
        int macMode = AidlConstants.Security.MAC_ALG_FAST_MODE;
        int keyLength = 0;
        switch (mode) {
            case MODE_00://X9.9
                macMode = AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL;
                break;
            case MODE_01://fastMode
                macMode = AidlConstantsV2.Security.MAC_ALG_FAST_MODE;
                break;
            case MODE_02://ANSIX9.19
                macMode = AidlConstants.Security.MAC_ALG_X9_19;
                keyLength = 8;
                break;
            case MODE_03://CMAC
                macMode = AidlConstants.Security.MAC_ALG_CMAC;
                break;
            case MODE_05://HMAC
                macMode = AidlConstants.Security.MAC_ALG_HMAC_SHA256;
                break;
        }
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.calcMacEx(keyIndex, keyLength, macMode, null, dataIn, outData);
        if (ret == 0) {
            return outData;
        } else {
            return null;
        }
    }

    byte[] calcMac(byte keyIndex, byte[] dataIn, int mode) throws RemoteException {
        dataIn = paddingMultipleBy8(dataIn);
        byte[] outData = new byte[8];
        int macMode = AidlConstants.Security.MAC_ALG_FAST_MODE;
        int keyLength = 0;
        switch (mode) {
            case 0x01:
                macMode = AidlConstants.Security.MAC_ALG_HMAC_SHA256;
                break;
            case 0x02:
                macMode = AidlConstantsV2.Security.MAC_ALG_HMAC_SHA1;
                break;
        }
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.calcMacEx(keyIndex, keyLength, macMode, null, dataIn, outData);
        if (ret == 0) {
            return outData;
        } else {
            return null;
        }
    }


    private byte[] paddingMultipleBy8(byte[] dataIn) {
        int remainder = dataIn.length % 8;
        if (remainder != 0) {
            byte[] newArray = new byte[dataIn.length + remainder];
            System.arraycopy(dataIn, 0, newArray, 0, dataIn.length);
            return newArray;
        } else {
            return dataIn;
        }

    }


}
