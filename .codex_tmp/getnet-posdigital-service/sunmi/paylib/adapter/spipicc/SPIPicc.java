package sunmi.paylib.adapter.spipicc;

import android.os.Bundle;
import android.os.RemoteException;

import com.sunmi.pay.hardware.aidl.AidlConstants;
import com.sunmi.pay.hardware.aidlv2.AidlConstantsV2;
import com.sunmi.pay.hardware.aidlv2.readcard.CheckCardCallbackV2;

import java.util.Arrays;
import java.util.concurrent.SynchronousQueue;

import sunmi.paylib.SunmiPayKernel;
import sunmi.paylib.adapter.exception.SPPiccException;
import sunmi.paylib.adapter.spipicc.enums.EPiccRemoveModeSP;
import sunmi.paylib.adapter.utils.ByteUtil;

public class SPIPicc {
    private static final String TAG = SPIPicc.class.getSimpleName();

    private static final SPIPicc INSTANCE = new SPIPicc();

    private SPIPicc() {
        queue = new SynchronousQueue<>();
    }

    public static SPIPicc getInstance() {
        return INSTANCE;
    }

    private SynchronousQueue<SPPiccCardInfo> queue;

    public SPPiccCardInfo detectSP(byte mode) throws SPPiccException {
        int cardType = AidlConstants.CardType.NFC.getValue();
        if (mode == 'M' || mode == 'm') {
            cardType = AidlConstants.CardType.MIFARE.getValue();
        }

        try {
            SunmiPayKernel.getInstance().mReadCardOptV2.checkCard(cardType, checkCardCallbackV2, 60);
            SPPiccCardInfo spPiccCardInfo = queue.take();
            if (spPiccCardInfo.getSerialInfoSP() != null && spPiccCardInfo.getSerialInfoSP().length != 0) {
                return spPiccCardInfo;
            } else {
                return null;
            }
        } catch (RemoteException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        return null;
    }

    public SPPiccCardInfo detectSP(byte mode, byte[] other) throws SPPiccException {
        if (other == null || other.length == 0) {
            return null;
        }

        int cardType = AidlConstants.CardType.NFC.getValue();
        if (mode == 'M' || mode == 'm') {
            cardType = AidlConstants.CardType.MIFARE.getValue();
        }
        try {
            SunmiPayKernel.getInstance().mReadCardOptV2.checkCard(cardType, checkCardCallbackV2, 60);
            SPPiccCardInfo spPiccCardInfo = queue.take();
            if (spPiccCardInfo.getSerialInfoSP() != null && spPiccCardInfo.getSerialInfoSP().length != 0) {
                return spPiccCardInfo;
            } else {
                return null;
            }
        } catch (RemoteException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        return null;
    }

    public byte[] isoCommandSP(byte cid, byte[] apduSend) throws SPPiccException {
        if (apduSend == null || apduSend.length == 0) {
            return null;
        }

        int cardType = AidlConstants.CardType.NFC.getValue();
        if (cid == 1) {
            cardType = AidlConstants.CardType.MIFARE.getValue();
        }

        byte[] recvBuff = new byte[256];
        int len = -1;
        try {
            len = SunmiPayKernel.getInstance().mReadCardOptV2.transmitApdu(cardType, apduSend, recvBuff);
            if (len < 0) {
                return null;
            }
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return Arrays.copyOf(recvBuff, len);
    }

    public void closeSP() throws SPPiccException {
        try {
            SunmiPayKernel.getInstance().mReadCardOptV2.cancelCheckCard();
            SunmiPayKernel.getInstance().mReadCardOptV2.cardOff(AidlConstantsV2.CardType.NFC.getValue());
            SunmiPayKernel.getInstance().mReadCardOptV2.cardOff(AidlConstantsV2.CardType.MIFARE.getValue());
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    public void removeSP(EPiccRemoveModeSP mode, byte cid) throws SPPiccException {
        closeSP();
    }

    public void resetCarrierSP() throws SPPiccException {
        closeSP();
    }


    private CheckCardCallbackV2 checkCardCallbackV2 = new CheckCardCallbackV2.Stub() {
        @Override
        public void findMagCard(Bundle info) throws RemoteException {

        }

        @Override
        public void findICCard(String atr) throws RemoteException {

        }

        @Override
        public void findRFCard(String uuid) throws RemoteException {

        }

        @Override
        public void onError(int code, String message) throws RemoteException {
            try {
                queue.put(new SPPiccCardInfo());
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        @Override
        public void findICCardEx(Bundle info) throws RemoteException {

        }

        @Override
        public void findRFCardEx(Bundle info) throws RemoteException {
            SPPiccCardInfo spPiccCardInfo = new SPPiccCardInfo();
            try {
                if (info.getInt("cardType") == AidlConstants.CardType.MIFARE.getValue()) {
                    spPiccCardInfo.setCardTypeSP((byte) 'M');
                    spPiccCardInfo.setCidSP((byte) 1);
                } else {
                    spPiccCardInfo.setCardTypeSP((byte) info.getInt("cardCategory"));
                    spPiccCardInfo.setCidSP((byte) 0);
                }

                spPiccCardInfo.setSerialInfoSP(ByteUtil.hexStr2Bytes(info.getString("uuid")));

                byte[] atqa = info.getByteArray("atqa");
                byte[] ats = ByteUtil.hexStr2Bytes(info.getString("ats"));
                int len = 2 + atqa.length + 1 + ats.length;

                byte[] otherSP = new byte[1 + len];
                otherSP[0] = (byte) len;
                System.arraycopy(atqa, 0, otherSP, 3, 2);
                otherSP[5] = (byte) info.getInt("sak");
                System.arraycopy(ats, 0, otherSP, 6, ats.length);
                spPiccCardInfo.setOtherSP(otherSP);
                queue.put(spPiccCardInfo);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        @Override
        public void onErrorEx(Bundle info) throws RemoteException {

        }
    };
}
