package sunmi.paylib.adapter.spiicc;

import android.os.Bundle;
import android.os.RemoteException;

import com.sunmi.pay.hardware.aidl.AidlConstants;
import com.sunmi.pay.hardware.aidlv2.readcard.CheckCardCallbackV2;

import java.util.Arrays;
import java.util.concurrent.SynchronousQueue;

import sunmi.paylib.SunmiPayKernel;
import sunmi.paylib.adapter.exception.SPICCException;

public class SPIICC {
    private static final String TAG = SPIICC.class.getSimpleName();

    private static final SPIICC INSTANCE = new SPIICC();

    private SPIICC() {
        queue = new SynchronousQueue<>();
    }

    public static SPIICC getInstance() {
        return INSTANCE;
    }

    private SynchronousQueue<String> queue;

    public boolean detectSP(byte slot) throws SPICCException {
        int[] result = parseSlot(slot);
        int cardType = result[0];
        int ctrCode = result[1];

        if (cardType == 0) {
            return false;
        }

        try {
            SunmiPayKernel.getInstance().mReadCardOptV2.checkCardEx(cardType, ctrCode, 0, checkCardCallbackV2, 60);
            if ("success".equals(queue.take())) {
                return true;
            } else {
                return false;
            }
        } catch (RemoteException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        return false;
    }

    public byte[] isoCommandSP(byte slot, byte[] apduSend) throws SPICCException {
        if (apduSend == null || apduSend.length == 0) {
            return null;
        }
        int[] result = parseSlot(slot);
        int cardType = result[0];

        if (cardType == 0) {
            return null;
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

    public void closeSP(byte slot) throws SPICCException {
        int[] result = parseSlot(slot);
        int cardType = result[0];

        if (cardType == 0) {
            return;
        }

        try {
            SunmiPayKernel.getInstance().mReadCardOptV2.cancelCheckCard();
            SunmiPayKernel.getInstance().mReadCardOptV2.cardOff(cardType);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    private CheckCardCallbackV2 checkCardCallbackV2 = new CheckCardCallbackV2.Stub() {
        @Override
        public void findMagCard(Bundle info) throws RemoteException {

        }

        @Override
        public void findICCard(String atr) throws RemoteException {
            try {
                queue.put("success");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        @Override
        public void findRFCard(String uuid) throws RemoteException {

        }

        @Override
        public void onError(int code, String message) throws RemoteException {
            try {
                queue.put("failed");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        @Override
        public void findICCardEx(Bundle info) throws RemoteException {

        }

        @Override
        public void findRFCardEx(Bundle info) throws RemoteException {

        }

        @Override
        public void onErrorEx(Bundle info) throws RemoteException {

        }
    };

    private int[] parseSlot(byte slot) {
        StringBuffer stringBuffer = new StringBuffer();
        String str = Integer.toBinaryString(slot);
        stringBuffer.append(str);
        for (int i = 0; i < 8 - str.length(); i++) {
            stringBuffer.insert(0, "0");
        }
        String slotStr = stringBuffer.toString();

        int ctrCode = 0;
        int cardType = 0;
        if ("0".equals(slotStr.substring(0, 1))) {
            ctrCode = ctrCode + (1 << 4);
        }

        if ("1".equals(slotStr.substring(1, 2))) {
            ctrCode = ctrCode + (1 << 2);
        }

        if ("1".equals(slotStr.substring(2, 3))) {
            ctrCode = ctrCode + (1 << 3);
        }

        if ("00".equals(slotStr.substring(3, 5))) {
            ctrCode = ctrCode + 2;
        } else if ("01".equals(slotStr.substring(3, 5))) {
            ctrCode = ctrCode + 1;
        } else if ("10".equals(slotStr.substring(3, 5))) {
            ctrCode = ctrCode + 0;
        } else if ("11".equals(slotStr.substring(3, 5))) {
            ctrCode = ctrCode + 2;
        }

        switch (Integer.parseInt(slotStr.substring(5, 8))) {
            case 0:
                cardType = AidlConstants.CardType.IC.getValue();
                break;
            case 1:
                cardType = AidlConstants.CardType.PSAM0.getValue();
                break;
            case 2:
                cardType = AidlConstants.CardType.SAM1.getValue();
                break;
            case 3:
                cardType = AidlConstants.CardType.SAM3.getValue();
                break;
            case 4:
                break;
            case 5:
                break;
        }

        int[] result = new int[2];
        result[0] = cardType;
        result[1] = ctrCode;
        return result;
    }
}
