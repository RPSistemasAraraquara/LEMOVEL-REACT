package sunmi.paylib.adapter.spiped;

import android.os.Bundle;
import android.os.RemoteException;

import com.sunmi.pay.hardware.aidl.AidlConstants;
import com.sunmi.pay.hardware.aidl.bean.EKeyCodeSP;
import com.sunmi.pay.hardware.aidlv2.AidlConstantsV2;
import com.sunmi.pay.hardware.aidlv2.AidlErrorCodeV2;
import com.sunmi.pay.hardware.aidlv2.bean.PinPadConfigV2;
import com.sunmi.pay.hardware.aidlv2.pinpad.PinPadListenerV2;

import java.security.spec.InvalidKeySpecException;
import java.util.Arrays;

import sunmi.paylib.LogUtil;
import sunmi.paylib.SunmiPayKernel;
import sunmi.paylib.adapter.Base;
import sunmi.paylib.adapter.bean.EAesCheckModeSP;
import sunmi.paylib.adapter.bean.ECheckModeSP;
import sunmi.paylib.adapter.bean.EDUKPTDesModeSP;
import sunmi.paylib.adapter.bean.EPedKeyTypeSP;
import sunmi.paylib.adapter.bean.EPedMacModeSP;
import sunmi.paylib.adapter.bean.SPDUKPTResult;
import sunmi.paylib.adapter.bean.SPKeyInfo;
import sunmi.paylib.adapter.bean.SPRSAKeyInfo;
import sunmi.paylib.adapter.spicomm.util.COMMUtil;


/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/21 2:48 下午
 */

public class SPIPed extends Base {

    private static final String TAG = "SPIPed";

    private static final SPIPed INSTANCE = new SPIPed();
    private static PinPadConfigV2 pinPadConfigV2 = new PinPadConfigV2();
    private SPIPedInputPinListener mPedInputPinListener;

    private SPIPed() {
    }

    public static SPIPed getInstance() {
        return INSTANCE;
    }

    public void init() {
        isInit = true;
    }

    /**
     * @param groupIndex key index
     * @param keyVarType select key
     * @param iv         iv
     * @param dataIn     source data
     * @param mode       mode
     * @return result
     */

    public SPDUKPTResult calcAesDUKPTDataSP(byte groupIndex, byte keyVarType, byte[] iv, byte[] dataIn, byte mode) throws RemoteException {
        checkInit();
        boolean[] isDecrypt = new boolean[]{false};
        int[] encryptionMode = new int[1];
        int keyIndex = groupIndex;
        int keySelect;
        if (keyVarType == 0x04) {
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_DATA_RSP;
        } else {
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_DATA_BOTH;
        }
        SPIPedUtil.processType(encryptionMode, isDecrypt, mode);
        if (isDecrypt[0]) {
            return decryptDUKPT(keyIndex, keySelect, encryptionMode[0], iv, dataIn);
        } else {
            return encryptDUKPT(keyIndex, keySelect, encryptionMode[0], iv, dataIn);
        }
    }

    private SPDUKPTResult decryptDUKPT(int keyIndex, int keySelect, int encryptionMode, byte[] iv, byte[] dataIn) throws RemoteException {
        byte[] dataOut = new byte[dataIn.length];
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.dataDecryptDukptEx(keySelect, keyIndex, dataIn, encryptionMode, iv, dataOut);
        if (ret == 0) {
            SPDUKPTResult spdukptResult = new SPDUKPTResult();
            spdukptResult.setResultSP(dataOut);
            spdukptResult.setKsnSP(SPIPedUtil.getKsn());
            return spdukptResult;
        } else {
            LogUtil.e(TAG, "decryptAesDUKPT fail:" + ret + " msg:" + AidlErrorCodeV2.valueOf(ret).getMsg());
            return null;
        }
    }

    private SPDUKPTResult encryptDUKPT(int keyIndex, int keySelect, int encryptionMode, byte[] iv, byte[] dataIn) throws RemoteException {
        byte[] dataOut = new byte[dataIn.length];
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.dataEncryptDukptEx(keySelect, keyIndex, dataIn, encryptionMode, iv, dataOut);
        if (ret == 0) {
            SPDUKPTResult spdukptResult = new SPDUKPTResult();
            spdukptResult.setResultSP(dataOut);
            spdukptResult.setKsnSP(SPIPedUtil.getKsn());
            return spdukptResult;
        } else {
            LogUtil.e(TAG, "encryptAesDUKPT fail:" + ret + " msg:" + AidlErrorCodeV2.valueOf(ret).getMsg());
            return null;
        }
    }


    /**
     * @param keyIndex
     * @param iv
     * @param dataIn
     * @param mode
     * @return
     * @throws RemoteException
     */
    public byte[] calcDesSP(byte keyIndex, byte[] iv, byte[] dataIn, byte mode) throws RemoteException {
        checkInit();
        boolean[] isDecrypt = new boolean[]{false};
        int[] encryptionMode = new int[1];
        SPIPedUtil.processType(encryptionMode, isDecrypt, mode);
        byte[] outData = new byte[dataIn.length];
        int ret;
        if (isDecrypt[0]) {
            ret = SunmiPayKernel.getInstance().mSecurityOptV2.dataDecrypt(keyIndex, dataIn, encryptionMode[0], iv, outData);
        } else {
            ret = SunmiPayKernel.getInstance().mSecurityOptV2.dataEncrypt(keyIndex, dataIn, encryptionMode[0], iv, outData);
        }
        if (ret == 0) {
            return outData;
        } else {
            return null;
        }
    }

    /**
     * @param groupIndex
     * @param keyVarType
     * @param iv
     * @param dataIn
     * @param mode
     * @return
     */
    public SPDUKPTResult calcDUKPTDataSP(byte groupIndex, byte keyVarType, byte[] iv, byte[] dataIn, byte mode) throws RemoteException {
        checkInit();
        boolean[] isDecrypt = new boolean[]{false};
        boolean[] isAes = new boolean[]{false};
        int[] encryptionMode = new int[1];
        int[] keyIndex = new int[]{groupIndex};
        int keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_DATA_BOTH;
        if (keyVarType==0){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
        }else if (keyVarType==1){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_DATA_BOTH;
        }else if (keyVarType==2){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_PIN;
        }else if (keyVarType==3){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_RSP;
        }else if (keyVarType==4){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_DATA_RSP;
        }
        SPIPedUtil.processAesOrDesType(encryptionMode, isDecrypt, isAes, keyIndex, mode);
        if (isDecrypt[0]) {
            return decryptDUKPT(keyIndex[0], keySelect, encryptionMode[0], iv, dataIn);
        } else {
            return encryptDUKPT(keyIndex[0], keySelect, encryptionMode[0], iv, dataIn);

        }
    }

    /**
     * @param groupIndex
     * @param keyVarType
     * @param iv
     * @param dataIn
     * @param mode
     * @return
     * @throws RemoteException
     */
    public SPDUKPTResult calcDUKPTDesSP(byte groupIndex, byte keyVarType, byte[] iv, byte[] dataIn, EDUKPTDesModeSP mode) throws RemoteException {
        checkInit();
        boolean[] isDecrypt = new boolean[]{false};
        boolean[] isAes = new boolean[]{false};
        int[] encryptionMode = new int[1];
        int[] keyIndex = new int[]{groupIndex};
        int keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_DATA_BOTH;
        if (keyVarType==0){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_BOTH;
        }else if (keyVarType==1){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_DATA_BOTH;
        }else if (keyVarType==2){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_PIN;
        }else if (keyVarType==3){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_MAC_RSP;
        }else if (keyVarType==4){
            keySelect = AidlConstants.Security.DUKPT_KEY_SELECT_KEY_DATA_RSP;
        }
        SPIPedUtil.processAesOrDesType(encryptionMode, isDecrypt, isAes, keyIndex, mode.ordinal());
        if (isDecrypt[0]) {
            return decryptDUKPT(keyIndex[0], keySelect, encryptionMode[0], iv, dataIn);
        } else {
            return encryptDUKPT(keyIndex[0], keySelect, encryptionMode[0], iv, dataIn);

        }
    }


    /**
     * @param groupIndex
     * @param dataIn
     * @param mode
     * @return
     */
    public SPDUKPTResult getAesDUKPTMacSP(byte groupIndex, byte[] dataIn,  byte mode) throws RemoteException {
        checkInit();
        return MacCalc.getInstance().dukptCalcMac(groupIndex, dataIn, mode);
    }


    /**
     * @param groupIndex
     * @param dataIn
     * @param mode
     * @return
     */
    public SPDUKPTResult getDUKPTMacSP(byte groupIndex, byte[] dataIn, byte mode) throws RemoteException {
        checkInit();
        return MacCalc.getInstance().dukptCalcMac(groupIndex, dataIn, mode);
    }


    /**
     * @param keyIndex
     * @param dataIn
     * @param mode
     * @return
     */
    public byte[] getMacSP(byte keyIndex, byte[] dataIn, EPedMacModeSP mode) throws RemoteException {
        checkInit();
        return MacCalc.getInstance().calcMac(keyIndex, dataIn, mode);
    }

    /**
     * 国密计算MAC
     *
     * @param keyIndex
     * @param initVector
     * @param input
     * @param mode
     * @return
     */
    public byte[] getMacSMSP(byte keyIndex, byte[] initVector, byte[] input, byte mode) {
        checkInit();
        return null;
    }


    public void onRecycle() {
        isInit = false;
    }


    /**
     * The process of entering the PIN and saving the PIN inside the PED. EPedType.INTERNAL only is supported.
     * 输入PIN并将PIN保存在PED内的过程
     * @param expPinLen - Enumeration of 0,4-12.The enter password string with legal length.
     *                  Application enumerates of all possible lengths of PIN.
     *                  "," will be used to separate each number of length.
     *                  If no PIN,or 4 or 6 digits of PIN are allowed, the string will be set as "0,4,6".
     *                  0 means that no PIN is required,
     *                  and pressing "Enter" will return(For special purposes only, subsequent PIN operations will return a failure)
     *                  枚举 0，4-12。 输入合法长度的密码字符串。应用程序枚举所有可能的PIN长度。"，"用于分割每个长度数。
     *                  如果没有PIN，或者有4位，或者有6位密码，都是允许的。这个字符串将被设为0、4、6。
     *                  0意味着不需要PIN，
     *                  (仅出于特殊目的，后续PIN操作将返回故障)
     * @param timeoutMs - The timeout of PIN entry [unit:ms] Maximum is 300000ms.0: No timeout time, not doing timeout control for PED.
     * @param mode - Reserved for extension, currently 0x00.
     *             保留用于扩展，当前为0x00
     */
    public void inputPinSP(String expPinLen, long timeoutMs, byte mode) throws RemoteException {
        checkInit();
        Bundle bundle = new Bundle();
        bundle.putString("expLen", expPinLen);
        bundle.putInt("timeout", (int) timeoutMs);
        bundle.putInt("pinType", (int) mode);

        SunmiPayKernel.getInstance().mPinPadOptV2.startInputPin(bundle, new PinPadListenerV2.Stub() {
            @Override
            public void onPinLength(int length) throws RemoteException {
                LogUtil.e(TAG, "onPinLength:" + length);
                if (mPedInputPinListener != null) {
                    if (length == 0) {
                        mPedInputPinListener.onKeyEventSP(EKeyCodeSP.KEY_CLEAR);
                    }
                }
            }

            @Override
            public void onConfirm(int type, byte[] pinBlock) throws RemoteException {
                LogUtil.e(TAG, "onConfirm:" + type);
                if (mPedInputPinListener != null) {
                    mPedInputPinListener.onKeyEventSP(EKeyCodeSP.KEY_ENTER);
                }
            }

            @Override
            public void onCancel() throws RemoteException {
                if (mPedInputPinListener != null) {
                    mPedInputPinListener.onKeyEventSP(EKeyCodeSP.KEY_CANCEL);
                }
            }

            @Override
            public void onError(int errorCode) throws RemoteException {
                LogUtil.e(TAG, "onError:" + errorCode);
                mPedInputPinListener.onKeyEventSP(EKeyCodeSP.KEY_CANCEL);

            }
        });
    }


    /**
     * @param listener
     */
    public void setInputPinListenerSP(SPIPedInputPinListener listener) {
        this.mPedInputPinListener = listener;
    }

    /**
     * Set keyboard display mode, fixed sequence or random sequence (default). EPedType.INTERNAL only is supported.
     *
     * @param random - true:random | false:fixed sequence
     */
    public void setKeyboardRandomSP(boolean random) throws RemoteException {
        checkInit();
        pinPadConfigV2.setOrderNumKey(random);
    }


    /**
     * To write Aes key to PED, and use KCV to check the key correction.For HIT. EPedType.INTERNAL only is supported.
     * 将Aes密钥写入PED，并使用KCV检查密钥更正。对于HIT。EPedType。仅支持内部。
     * @param srcKeyType  - Source Key Type. 0x01:TLK. 0x02:TMK. 0x22:AES_TMK. 源密钥类型
     * @param srcKeyIndex  - Source Key Index when srcKeyType=TLK, srcKeyIndex=1 when srcKeyType=TMK, srcKeyIndex=[1~100] when srcKeyType=AES_TMK, srcKeyIndex=[1~100]
     * when srcKeyIndex = 0ï¼ŒThe key will be written to PED in clear text.  解密密钥索引 源密钥索引
     * @param destKeyType  - Destination Key Type. 0x20:TAESK. 0x22:AES_TMK. 0x23:AES_TPK. 0x24:AES_TAK.  目标密钥类型，keyType
     * @param destKeyIndex  - Destination Key Index[1-100]  目标密钥索引，keyIndex
     * @param destKeyValue  - Cryptograph or Plaintext,16/24/32bytes  密码或明文
     * @param checkMode  - EAesCheckMode Check Mode When checkMode=KCV_NONE -No Check
     *                   When checkMode=KCV_ENCRYPT_0 -Perform AES ECB mode encryption on 16 bytes 0x00, and use first 4 bytes as KCV.
     *                   When checkMode=KCV_ENCRYPT_FIX_DATA -Perform parity check first,
     *                   then perform AES ECB mode encryption on 16 bytesâ€•\x12\x34\x56\x78\x90\x12\x34\x56\x12\x34\x56\x78\x90\x12\x34\x56â€–,
     *                   and use first 4 bytes as KCV.
     *                   When checkMode=KCV_MAC_INPUT_DATA -Send in data KcvData,
     *                   use source key to perform specified mode of MAC on [aucDesKeyValue(ciphertext) +KcvData],
     *                   and use the 8 bytes result as KCV.
     *
     *                   当checkMode=KCV_NONE，No Check
     *                   当checkMode=KCV_ENCRYPT_0，在16字节0x00上执行AES ECB模式加密，并将前4个字节用作KCV
     *                   当checkMode=KCV_ENCRYPT_FIX_DATA，先执行奇偶校验，然后对16个字节执行AES ECB模式加密，并将前4个字节用作KCV。
     *                   当checkMode=KCV_MAC_INPUT_DATA，发送数据KcvData，
     *                   使用源密钥在[aucDesKeyValue(ciphertext) +KcvData]上执行指定的MAC模式
     *                   并将8个字节的结果用作KCV
     *
     * @param checkBuf  - When checkMode=KCV_NONE -PED won't check KCV, this data is no meaning.
     *                  When checkMode=KCV_ENCRYPT_0 -4 bytes key check value
     *                  When checkMode=KCV_ENCRYPT_FIX_DATA -4 bytes key check value
     *                  When checkMode=KCV_MAC_INPUT_DATA -
     *                  checkBuf as follows:
     *                  checkBuf[0] = length of KcvData checkBuf+1: kcvData checkBuf[1+kcvDataLen]: MAC computation mode getMac(byte, byte[], EPedMacMode)
     *                  checkBuf[2+kcvDataLen]:KCV length checkBuf[3+kcvDataLen]:KCV Value
     *
     *                  当checkMode=KCV_NONE -PED 时不会检查KCV，此数据没有意义
     *                  当checkMode=KCV_ENCRYPT_0 -4
     *                  当checkMode=KCV_ENCRYPT_FIX_DATA -4
     *                  当checkMode=KCV_MAC_INPUT_DATA
     *                  checkBuf如下所示：
     *                  checkBuf[0] = length of KcvData
     *                  checkBuf的长度+1: kcvData
     *                  checkBuf[1+kcvDataLen]:MAC计算模式getMac(byte, byte[], EPedMacMode)
     *                  checkBuf[2+kcvDataLen]:KCV长度
     *                  checkBuf[3+kcvDataLen]：KCV值
     */
    public void writeAesKeySP(byte srcKeyType, byte srcKeyIndex, byte destKeyType, byte destKeyIndex, byte[] destKeyValue, EAesCheckModeSP checkMode, byte[] checkBuf ) throws RemoteException{
        checkInit();
        Bundle bundle = new Bundle();
        bundle.putInt("encryptIndex",srcKeyIndex);
        bundle.putInt("keyIndex",destKeyIndex);
        bundle.putByteArray("keyValue",destKeyValue);
        if((destKeyType & 0xff) == 0x20){//TAESK
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_REC);
            bundle.putInt("keyAlgType",2);
        }else if((destKeyType & 0xff) == 0x22){//AES_TMK
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_TMK);
            bundle.putInt("keyAlgType",2);
        }else if((destKeyType & 0xff) == 0x23){//AES_TPK
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_PIK);
            bundle.putInt("keyAlgType",2);
        }else if((destKeyType & 0xff) == 0x24){//AES_TAK
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_MAK);
            bundle.putInt("keyAlgType",2);
        }
        int code;
        switch (checkMode){
            case KCV_NONE:
                bundle.putInt("kcvMode",AidlConstants.Security.KCV_MODE_NOCHK);
                code = SunmiPayKernel.getInstance().mSecurityOptV2.saveKeyEx(bundle);
                LogUtil.e(TAG,"saveKeyEx:"+code);
                break;
            case KCV_ENCRYPT_0:
                bundle.putByteArray("checkValue",checkBuf);
                bundle.putInt("kcvMode",AidlConstants.Security.KCV_MODE_CHK0);
                code = SunmiPayKernel.getInstance().mSecurityOptV2.saveKeyEx(bundle);
                LogUtil.e(TAG,"saveKeyEx:"+code);
                break;
            case KCV_ENCRYPT_FIX_DATA:
                bundle.putByteArray("checkValue",checkBuf);
                bundle.putInt("kcvMode",AidlConstants.Security.KCV_MODE_CHKFIX_16);
                code = SunmiPayKernel.getInstance().mSecurityOptV2.saveKeyEx(bundle);
                LogUtil.e(TAG,"saveKeyEx:"+code);
                break;
            case KCV_MAC_INPUT_DATA:////传macType
                bundle.putInt("kcvMode",AidlConstants.Security.KCV_MODE_CHKMAC);

                if(checkBuf[0]+3 > checkBuf.length){
                    throw new RuntimeException("unsupport the type");
                }else {
                    int kcvDataLength = checkBuf[0];//kcvData length
                    byte[] inpuData = new byte[kcvDataLength];
                    System.arraycopy(checkBuf,1,inpuData,0,kcvDataLength);
                    int macMode = checkBuf[1+kcvDataLength];
                    int kcvLength = checkBuf[2+kcvDataLength];
                    byte[] checkValue = new byte[kcvLength];
                    if(kcvLength >= checkBuf.length-2-kcvDataLength){
                        throw new RuntimeException("unsupport the type");
                    }
                    System.arraycopy(checkBuf,3+kcvDataLength,checkValue,0,kcvLength);

                    bundle.putByteArray("checkValue",checkValue);
                    bundle.putByteArray("kcvInData",inpuData);

                    if(macMode == 0x00){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL);
                    }else if(macMode == 0x01){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_FAST_MODE);
                    }else if(macMode == 0x02){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_X9_19);
                    }else if(macMode == 0x03){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CMAC);
                    }else if(macMode == 0x05){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_HMAC_SHA256);
                    }else if(macMode == 0x20){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL);
                    }else if(macMode == 0x21){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_FAST_MODE);
                    }else if(macMode == 0x22){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_X9_19);
                    }else if(macMode == 0x23){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CMAC);
                    }else if(macMode == 0x25){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_HMAC_SHA256);
                    }else if(macMode == 0x40){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL);
                    }else if(macMode == 0x41){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_FAST_MODE);
                    }else if(macMode == 0x42){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_X9_19);
                    }else if(macMode == 0x43){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CMAC);
                    }else if(macMode == 0x45){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_HMAC_SHA256);
                    }
                }

                code = SunmiPayKernel.getInstance().mSecurityOptV2.saveKeyEx(bundle);
                LogUtil.e(TAG,"saveKeyEx:"+code);
                break;
        }
    }


    /**
     * Set keyboard display mode, fixed sequence or random sequence (default). EPedType.INTERNAL only is supported.
     * @param srcKeyType  -
     * @param srcKeyIndex  - Source Key Index
     *                     when srcKeyType=TLK, srcKeyIndex=1 when srcKeyType=TMK, srcKeyIndex=[1~100]
     *                     when srcKeyIndex = 0ï¼ŒThe key will be written to PED in clear text.
     * @param destkeyIndex  - Destination Key Index[1-40]
     * @param destKeyValue  - Cryptograph or Plaintext,32bytes
     * @param checkMode  - EAesCheckMode
     *                   When checkMode=KCV_NONE -No Check
     *                   When checkMode=KCV_ENCRYPT_0 -Perform AES ECB mode encryption on 16 bytes 0x00,and use first 4 bytes as KCV.
     *                   When checkMode=KCV_ENCRYPT_FIX_DATA -Perform parity check first,
     *                   then perform AES ECB mode encryption on 16 bytesâ€•\x12\x34\x56\x78\x90\x12\x34\x56\x12\x34\x56\x78\x90\x12\x34\x56â€–,
     *                   and use first 4 bytes as KCV.
     *                   When checkMode=KCV_MAC_INPUT_DATA -Send in data KcvData,
     *                   use source key to perform specified mode of MAC on [aucDesKeyValue(ciphertext) +KcvData],
     *                   and use the 8 bytes result as KCV.
     *
     *                   当checkMode=KCV_NONE， -No Check
     *                   当checkMode=KCV_ENCRYPT_0，在16字节0x00上执行AES ECB模式加密，并将前4个字节用作KCV。
     *                   当checkMode=KCV_ENCRYPT_FIX_DATA，首先执行奇偶校验，然后对16个字节执行AES ECB模式加密，并将前4个字节用作KCV。
     *                   当checkMode=KCV_MAC_INPUT_DATA，发送数据KcvData，使用源密钥在[aucDesKeyValue(ciphertext) +KcvData]上执行指定的mac模式，
     *                   并将8个字节的结果用作KCV
     *
     * @param checkBuf  - When checkMode=KCV_NONE -PED won't check KCV, this data is no meaning.
     *                  When checkMode=KCV_ENCRYPT_0 -4 bytes key check value
     *                  When checkMode=KCV_ENCRYPT_FIX_DATA -4 bytes key check value
     *                  When iCheckMode=KCV_MAC_INPUT_DATA - checkBuf as follows: checkBuf[0] = length of KcvData checkBuf+1: kcvData checkBuf[1+kcvDataLen]: MAC computation mode getMac(byte, byte[], EPedMacMode) checkBuf[2+kcvDataLen]:KCV length checkBuf[3+kcvDataLen]:KCV Value
     *
     *                  当checkMode=KCV_NONE -PED，不会检查KCV，此数据没意义
     *                  当checkMode=KCV_ENCRYPT_0，4字节密钥检查值
     *                  当checkMode=KCV_ENCRYPT_FIX_DATA，4字节密钥检查值
     *                  当CheckMode=KCV_MAC_INPUT_DATA，checkBuf如下所示：
     *                  checkBuf[0] = length of KcvData checkBuf+1: kcvData checkBuf[1+kcvDataLen]: MAC computation mode getMac(byte, byte[], EPedMacMode) checkBuf[2+kcvDataLen]:KCV length checkBuf[3+kcvDataLen]:KCV Value
     */
    public void writeAesKeySP(EPedKeyTypeSP srcKeyType, byte srcKeyIndex, byte destkeyIndex, byte[] destKeyValue, EAesCheckModeSP checkMode, byte[] checkBuf) throws RemoteException{
        checkInit();
        Bundle bundle = new Bundle();
        bundle.putByteArray("keyValue",destKeyValue);
        bundle.putInt("encryptIndex",srcKeyIndex);
        bundle.putInt("keyIndex",destkeyIndex);

        if (srcKeyType == EPedKeyTypeSP.AES_TAK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_MAK);
            bundle.putInt("keyAlgType", 2);
//          int code = SunmiPayKernel.getInstance().mSecurityOptV2.injectCiphertextKeyEx(bundle);

        } else if (srcKeyType == EPedKeyTypeSP.AES_TCHDK) {
            throw new RuntimeException("unsupport the type");
//          bundle.putInt("keyAlgType",2);

        } else if (srcKeyType == EPedKeyTypeSP.AES_TIK) {
            throw new RuntimeException("unsupport the type");
//          bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_DUPKT_BDK);
//          bundle.putInt("keyAlgType",2);

        } else if (srcKeyType == EPedKeyTypeSP.AES_TLK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_KEK);
            bundle.putInt("keyAlgType", 2);
        } else if (srcKeyType == EPedKeyTypeSP.AES_TMK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_TMK);
            bundle.putInt("keyAlgType", 2);
        } else if (srcKeyType == EPedKeyTypeSP.AES_TPK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_PIK);
            bundle.putInt("keyAlgType", 2);
        } else if (srcKeyType == EPedKeyTypeSP.PPAD_TPK) {////
            throw new RuntimeException("unsupport the type");
//          bundle.putInt("keyAlgType",1);
        } else if (srcKeyType == EPedKeyTypeSP.TAESK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_REC);
            bundle.putInt("keyAlgType", 2);
        } else if (srcKeyType == EPedKeyTypeSP.TAK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_MAK);
            bundle.putInt("keyAlgType", 1);
        } else if (srcKeyType == EPedKeyTypeSP.TDK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_REC);
            bundle.putInt("keyAlgType", 1);
        } else if (srcKeyType == EPedKeyTypeSP.TIK) {
            throw new RuntimeException("unsupport the type");
//          bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_DUPKT_BDK);
//          bundle.putInt("keyAlgType",1);
        } else if (srcKeyType == EPedKeyTypeSP.TLK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_TMK);
            bundle.putInt("keyAlgType", 1);
        } else if (srcKeyType == EPedKeyTypeSP.TMK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_TMK);
            bundle.putInt("keyAlgType", 1);
        } else if (srcKeyType == EPedKeyTypeSP.TPK) {
            bundle.putInt("keyType", AidlConstantsV2.Security.KEY_TYPE_PIK);
            bundle.putInt("keyAlgType", 1);
        }
        int code;

        switch (checkMode){
            case KCV_NONE:
                bundle.putInt("kcvMode",AidlConstants.Security.KCV_MODE_NOCHK);
                code = SunmiPayKernel.getInstance().mSecurityOptV2.saveKeyEx(bundle);
                LogUtil.e(TAG,"saveKeyEx:"+code);
                break;
            case KCV_ENCRYPT_0:
                bundle.putByteArray("checkValue",checkBuf);
                bundle.putInt("kcvMode",AidlConstants.Security.KCV_MODE_CHK0);
                code = SunmiPayKernel.getInstance().mSecurityOptV2.saveKeyEx(bundle);
                LogUtil.e(TAG,"saveKeyEx:"+code);
                break;
            case KCV_ENCRYPT_FIX_DATA:
                bundle.putByteArray("checkValue",checkBuf);
                bundle.putInt("kcvMode",AidlConstants.Security.KCV_MODE_CHKFIX_16);
                code = SunmiPayKernel.getInstance().mSecurityOptV2.saveKeyEx(bundle);
                LogUtil.e(TAG,"saveKeyEx:"+code);
                break;
            case KCV_MAC_INPUT_DATA:
                bundle.putInt("kcvMode",AidlConstants.Security.KCV_MODE_CHKMAC);

                if(checkBuf[0]+3 > checkBuf.length){
                    throw new RuntimeException("unsupport the type");
                }else {
                    int kcvDataLength = checkBuf[0];//kcvData length
                    byte[] inpuData = new byte[kcvDataLength];
                    System.arraycopy(checkBuf,1,inpuData,0,kcvDataLength);
                    int macMode = checkBuf[1+kcvDataLength];
                    int kcvLength = checkBuf[2+kcvDataLength];
                    byte[] checkValue = new byte[kcvLength];
                    if(kcvLength >= checkBuf.length-2-kcvDataLength){
                        throw new RuntimeException("unsupport the type");
                    }
                    System.arraycopy(checkBuf,3+kcvDataLength,checkValue,0,kcvLength);

                    bundle.putByteArray("checkValue",checkValue);
                    bundle.putByteArray("kcvInData",inpuData);

                    if(macMode == 0x00){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL);
                    }else if(macMode == 0x01){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_FAST_MODE);
                    }else if(macMode == 0x02){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_X9_19);
                    }else if(macMode == 0x03){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CMAC);
                    }else if(macMode == 0x05){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_HMAC_SHA256);
                    }else if(macMode == 0x20){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL);
                    }else if(macMode == 0x21){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_FAST_MODE);
                    }else if(macMode == 0x22){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_X9_19);
                    }else if(macMode == 0x23){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CMAC);
                    }else if(macMode == 0x25){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_HMAC_SHA256);
                    }else if(macMode == 0x40){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CBC_INTERNATIONAL);
                    }else if(macMode == 0x41){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_FAST_MODE);
                    }else if(macMode == 0x42){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_X9_19);
                    }else if(macMode == 0x43){
                        bundle.putInt("kcvMacType",AidlConstantsV2.Security.MAC_ALG_CMAC);
                    }else if(macMode == 0x45){
                        bundle.putInt("kcvMacType", AidlConstantsV2.Security.MAC_ALG_HMAC_SHA256);
                    }
                }
                code = SunmiPayKernel.getInstance().mSecurityOptV2.saveKeyEx(bundle);
                LogUtil.e(TAG, "saveKeyEx:" + code);
                break;
        }
    }

    /**
     * @param keyIndex
     * @param dataIn
     * @param mode
     * @return
     * @throws RemoteException
     */
    public byte[] calcHMACSP(int keyIndex, byte[] dataIn, int mode) throws RemoteException {
        return MacCalc.getInstance().calcMac((byte) keyIndex, dataIn, mode);
    }

    /**
     * @param type
     * @param keyIndex
     * @param checkMode
     * @param checkBuf
     * @return
     * @throws RemoteException
     */
    public byte[] getKcvSP(EPedKeyTypeSP type, byte keyIndex, byte checkMode, byte[] checkBuf) throws RemoteException {
        return KeyImp.getInstance().getKcvSP(type, keyIndex, checkMode, checkBuf);
    }

    /**
     * @return
     * @throws RemoteException
     */
    public String getVersionSP() throws RemoteException {
        return SunmiPayKernel.getInstance().mBasicOptV2.getSysParam(AidlConstants.SysParam.HARDWARE_VERSION);
    }

    /**
     *
     * @param groupIndex
     * @param srcKeyIndex
     * @param keyValue
     * @param ksn
     * @param checkMode
     * @param checkBuf
     * @throws RemoteException
     */
    public void writeAesDUKPTTIKSP(byte groupIndex, byte srcKeyIndex, byte[] keyValue, byte[] ksn, byte checkMode, byte[] checkBuf) throws RemoteException {
        checkInit();
        Bundle bundle = new Bundle();
        bundle.putByteArray("keyValue", keyValue);
        bundle.putInt("encryptIndex", srcKeyIndex);
        bundle.putInt("keyIndex", groupIndex);
        bundle.putString("targetAppPkgName", COMMUtil.getAppProcessName(SunmiPayKernel.getInstance().getAppContext()));
        bundle.putBoolean("isEncrypt", false);
        bundle.putInt("keyLength", keyValue.length);
        bundle.putInt("keyAlgType", 2);
        if (checkMode == 0x00) {
            bundle.putByteArray("checkValue", new byte[0]);
        } else {
            bundle.putByteArray("checkValue", Arrays.copyOfRange(checkBuf, 1, checkBuf[0] + 1));
        }
        bundle.putByteArray("ksn", ksn);
        int ret = SunmiPayKernel.getInstance().mSecurityOptV2.injectKeyDukptEx(bundle);
        LogUtil.e(TAG, "code:" + ret + " message:" + AidlErrorCodeV2.valueOf(ret).getMsg());
    }


    /**
     * @param type
     * @param srcKeyIndex
     * @param destKeyIndex
     * @param xorData
     * @param checkMode
     * @param checkBuf
     */
    public void writeKeyVarSP(EPedKeyTypeSP type, byte srcKeyIndex, byte destKeyIndex, byte[] xorData, ECheckModeSP checkMode, byte[] checkBuf) throws RemoteException {
        KeyImp.getInstance().writeKeyVarSP(type, srcKeyIndex, destKeyIndex, xorData, checkMode, checkBuf);
    }

    /**
     * @param rsaKeyIndex
     * @return
     * @throws RemoteException
     */
    public SPRSAKeyInfo readRSAKeySP(byte rsaKeyIndex) throws RemoteException {
        return KeyImp.getInstance().readRSAKeySP(rsaKeyIndex);
    }

    /**
     * @param language
     * @throws RemoteException
     */
    public void setDoubleTapKeyboardLanguageSP(byte language) throws RemoteException {
        Bundle bundle = new Bundle();
        int ret = SunmiPayKernel.getInstance().mPinPadOptV2.getVisualImpairmentModeParam(bundle);
        LogUtil.e(TAG, "getVisualImpairmentModeParam Result:" + ret);
        if (ret == 0) {
            if (language == 0x00) {
                bundle.putInt("ttsLanguage", 1);
            } else if (language == 0x0A) {
                bundle.putInt("ttsLanguage", 2);
            } else if (language == 0x0B) {
                bundle.putInt("ttsLanguage", 3);
            } else {
                bundle.putInt("ttsLanguage", 0);
            }
            ret = SunmiPayKernel.getInstance().mPinPadOptV2.setVisualImpairmentModeParam(bundle);
            LogUtil.e(TAG, "setVisualImpairmentModeParam Result:" + ret);
        }
    }

    /**
     * @param slot
     * @param expPinLen
     * @param mode
     * @param timeoutMs
     * @return
     */
    public byte[] verifyPlainPinSP(byte slot, String expPinLen, byte mode, int timeoutMs) throws RemoteException {
        Bundle paramIn = new Bundle();
        Bundle paramOut = new Bundle();
        paramIn.putInt("offlineType", 0);
        int ret = SunmiPayKernel.getInstance().mPinPadOptV2.offlinePinVerify(paramIn, paramOut);
        if (ret == 0) {
            return new byte[]{(byte) paramOut.getInt("SW1"), (byte) paramOut.getInt("SW2")};
        }
        return new byte[]{0x69, 0x00};
    }

    /**
     * @param rsaKeyIndex
     * @param info
     * @throws InvalidKeySpecException
     * @throws RemoteException
     */
    public void writeRSAKeySP(byte rsaKeyIndex, SPRSAKeyInfo info) throws InvalidKeySpecException, RemoteException {
        KeyImp.getInstance().writeRSAKeySP(rsaKeyIndex, info);
    }

    /**
     * @param keyType
     * @param keyIndex
     * @return
     * @throws RemoteException
     */
    public SPKeyInfo querySPKeyInfoSP(byte keyType, byte keyIndex) throws RemoteException {
        return KeyImp.getInstance().querySPKeyInfoSP(keyType, keyIndex);
    }


    /**
     * @param srcKeyType
     * @param srcKeyIndex
     * @param destKeyType
     * @param destkeyIndex
     * @param destKeyValue
     * @param checkMode
     * @param checkBuf
     */
    public void writeKeySP(EPedKeyTypeSP srcKeyType, byte srcKeyIndex, EPedKeyTypeSP destKeyType, byte destkeyIndex, byte[] destKeyValue, ECheckModeSP checkMode, byte[] checkBuf) throws RemoteException {
        KeyImp.getInstance().writeKeySP(srcKeyType, srcKeyIndex, destKeyType, destkeyIndex, destKeyValue, checkMode, checkBuf);
    }

    /**
     * @param srcKeyType
     * @param srcKeyIndex
     * @param keyInfo
     * @param keyBlock
     * @param mode
     */
    public void writeCipherKeySP(byte srcKeyType, byte srcKeyIndex, byte[] keyInfo, byte[] keyBlock, byte mode) {
    }

    /**
     *
     * @return
     */
    public int getKeyBoardTypeSP(){
        return 2;
    }

}
