package sunmi.paylib.adapter.spiped;

import android.os.RemoteException;

import com.sunmi.pay.hardware.aidl.AidlConstants;

import java.util.Arrays;

import sunmi.paylib.LogUtil;
import sunmi.paylib.SunmiPayKernel;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/21 3:13 下午
 */
public class SPIPedUtil {
    private static final String TAG = "SPIPedUtil";

    /**
     * Aes dukpt密钥偏移计算
     *
     * @param sourceIndex
     * @return
     */
//    public static int aesDukptIndex(byte sourceIndex) {
//        return 2100 + sourceIndex;
//    }

    /**
     * Des dukpt密钥偏移计算
     *
     * @param
     * @return
     */
//    public static int desDukptIndex(byte sourceIndex) {
//        return 1100 + sourceIndex;
//    }
    public static void processType(int[] encryptionMode, boolean[] isDecrypt, int mode) {
        switch (mode) {
            case 0:
                isDecrypt[0] = true;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_ECB;
                break;
            case 1:
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_ECB;
                break;
            case 2:
                isDecrypt[0] = true;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_CBC;
                break;
            case 3:
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_CBC;
                break;
            case 4:
                isDecrypt[0] = true;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_OFB;
                break;
            case 5:
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_OFB;
                break;
            case 6:
                isDecrypt[0] = true;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_CFB;
                break;
            case 7:
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_CFB;
                break;
            default:
                throw new IllegalStateException("Unexpected value: " + mode);
        }

    }

    public static void processAesOrDesType(int[] encryptionMode, boolean[] isDecrypt, boolean[] isAes, int[] keyIndex, int mode) {
        switch (mode) {
            case 0:
                isDecrypt[0] = true;
                isAes[0] = false;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_ECB;
                break;
            case 1:
                isAes[0] = false;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_ECB;
                break;
            case 2:
                isDecrypt[0] = true;
                isAes[0] = false;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_CBC;
                break;
            case 3:
                isAes[0] = false;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_CBC;
                break;
            case 0x10:
                isDecrypt[0] = true;
                isAes[0] = true;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_ECB;
                break;
            case 0x11:
                isAes[0] = true;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_ECB;
                break;
            case 0x12:
                isDecrypt[0] = true;
                isAes[0] = true;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_CBC;
                break;
            case 0x13:
                isAes[0] = true;
                encryptionMode[0] = AidlConstants.Security.DATA_MODE_CBC;
                break;
            default:
                throw new IllegalStateException("unknown mode: " + mode);
        }

    }

    static byte[] getKsn() throws RemoteException {
        byte[] out = new byte[512];
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.dukptGetInitKSN(out);
        if (ret > 0) {
            return Arrays.copyOf(out, ret);
        } else {
            return null;
        }
    }

    static void dukptIncreaseKSN(int index) {
        int ret = 0;
        try {
            ret = SunmiPayKernel.getInstance().mSecurityOptV2.dukptIncreaseKSN(index);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        LogUtil.e(TAG, "dukptIncreaseKSN：" + ret);
    }
}
