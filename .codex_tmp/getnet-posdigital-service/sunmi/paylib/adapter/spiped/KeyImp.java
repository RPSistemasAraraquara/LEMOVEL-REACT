package sunmi.paylib.adapter.spiped;

import android.os.Bundle;
import android.os.RemoteException;

import com.sunmi.pay.hardware.aidl.AidlConstants;
import com.sunmi.pay.hardware.aidlv2.AidlConstantsV2;

import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;

import sunmi.paylib.LogUtil;
import sunmi.paylib.SunmiPayKernel;
import sunmi.paylib.adapter.bean.ECheckModeSP;
import sunmi.paylib.adapter.bean.EPedKeyTypeSP;
import sunmi.paylib.adapter.bean.SPKeyInfo;
import sunmi.paylib.adapter.bean.SPRSAKeyInfo;
import sunmi.paylib.adapter.utils.ByteUtil;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/25 2:52 下午
 */
public class KeyImp {

    private static final String TAG = "KeyImp";


    static KeyImp INSTANCE;

    static {
        try {
            INSTANCE = new KeyImp();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
    }

    KeyFactory keyFactory = KeyFactory.getInstance("RSA");


    private KeyImp() throws NoSuchAlgorithmException {
    }


    static KeyImp getInstance() {
        return INSTANCE;
    }

    public void writeKey() {
    }

    SPRSAKeyInfo readRSAKeySP(byte rsaKeyIndex) throws RemoteException {
        Bundle outBundle = new Bundle();
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.readRSAKey(rsaKeyIndex, outBundle);
        LogUtil.e(TAG, "readRSAKey Result:" + ret);
        if (ret == 0) {
            SPRSAKeyInfo sprsaKeyInfo = new SPRSAKeyInfo();
            sprsaKeyInfo.setModulusSP(outBundle.getByteArray("modulus"));
            sprsaKeyInfo.setExponentSP(outBundle.getByteArray("exponent"));
            sprsaKeyInfo.setModulusLenSP(sprsaKeyInfo.getModulusSP().length);
            sprsaKeyInfo.setExponentLenSP(sprsaKeyInfo.getExponentSP().length);
            return sprsaKeyInfo;
        } else {
            return null;
        }
    }

    void writeRSAKeySP(byte rsaKeyIndex, SPRSAKeyInfo info) throws InvalidKeySpecException, RemoteException {
        BigInteger module = new BigInteger(info.getModulusSP());
        BigInteger exponent = new BigInteger(info.getExponentSP());
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.injectRSAKey(rsaKeyIndex, 1024, ByteUtil.bytes2HexStr(info.getModulusSP()), ByteUtil.bytes2HexStr(info.getExponentSP()));
        LogUtil.e(TAG, "saveRSAKey result:" + ret);
    }

    byte[] getKcvSP(EPedKeyTypeSP type, byte keyIndex, byte checkMode, byte[] checkBuf) throws RemoteException {
        Bundle bundle = new Bundle();
        int keySystem = AidlConstants.Security.SEC_MKSK;
        int kcvMode = AidlConstants.Security.KCV_MODE_CHK_BUF;
        if (type == EPedKeyTypeSP.TIK || type == EPedKeyTypeSP.AES_TIK) {
            keySystem = AidlConstants.Security.SEC_DUKPT;
        }
        if (checkMode == 0x03) {
            kcvMode = AidlConstants.Security.KCV_MODE_CHKCMAC_BUF;
        }
        bundle.putInt("keySystem", keySystem);
        bundle.putInt("keyIndex", keyIndex);
        bundle.putInt("kcvMode", kcvMode);
        bundle.putByteArray("kcvInData", checkBuf);
        byte[] outData = new byte[4];
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.getKeyCheckValueEx(bundle, outData);
        LogUtil.e(TAG, "getKeyCheckValueEx result:" + ret);
        if (ret == 0) {
            return outData;
        } else {
            return null;
        }
    }

    SPKeyInfo querySPKeyInfoSP(byte keyType, byte keyIndex) throws RemoteException {
        SPKeyInfo spKeyInfo = new SPKeyInfo();
        spKeyInfo.setKeyTypeSP(keyType);
        spKeyInfo.setKeyIndexSP(keyIndex);
        int keySystem = AidlConstants.Security.SEC_MKSK;
        if (keyType == 0x07) {
            keySystem = AidlConstants.Security.SEC_DUKPT;
            byte[] outKsn = new byte[10];
            int ret = SunmiPayKernel.getInstance().mSecurityOptV2.dukptCurrentKSN(keyIndex, outKsn);
            LogUtil.e(TAG, "dukptCurrentKSN result:" + ret);
            if (ret == 0) {
                spKeyInfo.setKsnSP(outKsn);
            } else {
                return null;
            }
        }
        byte[] outData = new byte[4];
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.getKeyCheckValue(keySystem, keyIndex, outData);
        LogUtil.e(TAG, "getKeyCheckValue result:" + ret);
        if (ret == 0) {
            spKeyInfo.setKcvSP(outData);
        } else {
            return null;
        }
        ret = SunmiPayKernel.getInstance().mSecurityOptV2.getKeyLength(keySystem, keyIndex);
        LogUtil.e(TAG, "getKeyLength result:" + ret);
        if (ret > 0) {
            spKeyInfo.setKeyLenSP((short) ret);
        } else {
            return null;
        }
        return spKeyInfo;
    }

    public void writeCipherKeySP(byte srcKeyType, byte srcKeyIndex, byte[] keyInfo, byte[] keyBlock, byte mode) {



    }

    void writeKeyVarSP(EPedKeyTypeSP type, byte srcKeyIndex, byte destKeyIndex, byte[] xorData, ECheckModeSP checkMode, byte[] checkBuf) throws RemoteException {
        Bundle bundle = new Bundle();
        int keyType = AidlConstants.Security.KEY_TYPE_REC;
        int keyAlgType = 1;
        switch (type) {
            case TMK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_TMK;
                break;
            case TLK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_KEK;
                break;
            case TDK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_REC;
                break;
            case TAK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_MAK;
                break;
            case TPK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_PIK;
                break;
            case TAESK:
            case AES_TCHDK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_REC;
                break;
            case AES_TMK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_TMK;
                break;
            case AES_TLK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_KEK;
                break;
            case AES_TAK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_MAK;
                break;
            case AES_TPK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_PIK;
        }
        bundle.putInt("keyType", keyType);
        bundle.putInt("keyAlgType", keyAlgType);
        bundle.putInt("srcKeyIndex", srcKeyIndex);
        bundle.putInt("destKeyIndex", destKeyIndex);
        bundle.putByteArray("xorData", xorData);
        bundle.putInt("kcvMode", AidlConstants.Security.KCV_MODE_NOCHK);

        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.writeKeyVariable(bundle);
        LogUtil.e(TAG, "writeKeyVariable result:" + ret);
    }


    void writeKeySP(EPedKeyTypeSP srcKeyType, byte srcKeyIndex, EPedKeyTypeSP destKeyType, byte destkeyIndex, byte[] destKeyValue, ECheckModeSP checkMode, byte[] checkBuf) throws RemoteException {

        int keyType = AidlConstants.Security.KEY_TYPE_REC;
        int keyAlgType = 1;
        switch (destKeyType) {
            case TMK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_TMK;
                break;
            case TLK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_KEK;
                break;
            case TDK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_REC;
                break;
            case TAK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_MAK;
                break;
            case TPK:
                keyAlgType = 1;
                keyType = AidlConstants.Security.KEY_TYPE_PIK;
                break;
            case TAESK:
            case AES_TCHDK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_REC;
                break;
            case AES_TMK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_TMK;
                break;
            case AES_TLK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_KEK;
                break;
            case AES_TAK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_MAK;
                break;
            case AES_TPK:
                keyAlgType = 2;
                keyType = AidlConstants.Security.KEY_TYPE_PIK;
        }
        if (srcKeyIndex == 0) {//明文密钥存储
            int ret = SunmiPayKernel.getInstance().mSecurityOptV2.savePlaintextKey(keyType, destKeyValue, new byte[0], keyAlgType, destkeyIndex);
            LogUtil.e(TAG, "savePlaintextKey result:" + ret);
        } else {
            Bundle bundle = new Bundle();
            bundle.putInt("keyType", keyType);
            bundle.putInt("keyAlgType", keyAlgType);
            bundle.putInt("encryptIndex", srcKeyIndex);
            bundle.putInt("keyIndex", destkeyIndex);
            bundle.putByteArray("keyValue",destKeyValue);
            switch (checkMode) {
                case KCV_NONE:
                    bundle.putInt("kcvMode", AidlConstants.Security.KCV_MODE_NOCHK);
                    break;
                case KCV_ENCRYPT_0:
                    bundle.putByteArray("checkValue", checkBuf);
                    bundle.putInt("kcvMode", AidlConstants.Security.KCV_MODE_CHK0);
                    break;
                case KCV_ENCRYPT_FIX_DATA:
                    bundle.putByteArray("checkValue", checkBuf);
                    bundle.putInt("kcvMode", AidlConstants.Security.KCV_MODE_CHKFIX_16);
                    break;
                case KCV_MAC_INPUT_DATA:
                    bundle.putInt("kcvMode", AidlConstants.Security.KCV_MODE_CHKMAC);
                    if (checkBuf[0] + 3 > checkBuf.length) {
                        throw new RuntimeException("unsupport the type");
                    } else {
                        int kcvDataLength = checkBuf[0];//kcvData length
                        byte[] inpuData = new byte[kcvDataLength];
                        System.arraycopy(checkBuf, 1, inpuData, 0, kcvDataLength);
                        int macMode = checkBuf[1 + kcvDataLength];
                        int kcvLength = checkBuf[2 + kcvDataLength];
                        byte[] checkValue = new byte[kcvLength];
                        if (kcvLength >= checkBuf.length - 2 - kcvDataLength) {
                            throw new RuntimeException("unsupport the type");
                        }
                        System.arraycopy(checkBuf, 3 + kcvDataLength, checkValue, 0, kcvLength);

                        bundle.putByteArray("checkValue", checkValue);
                        bundle.putByteArray("kcvInData", inpuData);

                        if (macMode == 0x00) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL);
                        } else if (macMode == 0x01) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_FAST_MODE);
                        } else if (macMode == 0x02) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_X9_19);
                        } else if (macMode == 0x03) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_CMAC);
                        } else if (macMode == 0x05) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_HMAC_SHA256);
                        } else if (macMode == 0x20) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL);
                        } else if (macMode == 0x21) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_FAST_MODE);
                        } else if (macMode == 0x22) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_X9_19);
                        } else if (macMode == 0x23) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_CMAC);
                        } else if (macMode == 0x25) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_HMAC_SHA256);
                        } else if (macMode == 0x40) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL);
                        } else if (macMode == 0x41) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_FAST_MODE);
                        } else if (macMode == 0x42) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_X9_19);
                        } else if (macMode == 0x43) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_CMAC);
                        } else if (macMode == 0x45) {
                            bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_HMAC_SHA256);
                        }
                    }
                    break;
            }

            int ret = SunmiPayKernel.getInstance().mSecurityOptV2.saveKeyEx(bundle);
            LogUtil.e(TAG, "saveKeyEx result:" + ret);

        }

    }


}
