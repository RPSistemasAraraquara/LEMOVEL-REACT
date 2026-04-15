package sunmi.paylib.adapter.spicomm;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbManager;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.text.TextUtils;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.Collection;

import sunmi.paylib.LogUtil;
import sunmi.paylib.SunmiPayKernel;
import sunmi.paylib.adapter.bean.EConnectStatusSP;
import sunmi.paylib.adapter.bean.SPUartParam;
import sunmi.paylib.adapter.spicomm.driver.UsbSerialDriver;
import sunmi.paylib.adapter.spicomm.driver.UsbSerialPort;
import sunmi.paylib.adapter.spicomm.driver.UsbSerialProber;
import sunmi.paylib.adapter.spicomm.util.COMMUtil;
import sunmi.paylib.adapter.spicomm.util.SerialInputOutputManager;
import sunmi.paylib.adapter.spicomm.util.Singleton;
import sunmi.paylib.adapter.utils.ByteUtil;

/**
 * @Desc
 * @Author blanks
 * @Date 2022/7/29 1:52 下午
 */
public class SPIComm {

    private static final String TAG = "SPIComm";

    private UsbSerialPort usbSerialPort;
    private SerialInputOutputManager usbIoManager;
    private UsbPermission usbPermission = UsbPermission.Unknown;

    private int portNum;
    private int baudRate = 115200;
    private int dataBit = 8;
    private int stopBit = 1;
    private int parity = 0;
    private int READ_WAIT_MILLIS = 20000;
    private int WRITE_WAIT_MILLIS = 20000;
    private int CONNECT_WAIT_MILLIS = 20000;

    private int MAX_BUFF_SIZE = 4 * 1024;
    private byte[] cacheArray = new byte[MAX_BUFF_SIZE];
    private int available = 0;

    private boolean isRecv = false;

    private final int MSG_TIMEOUT = 0x01;

    private static final Object sLock = new Object();

    private static final Object tLock = new Object();


    private EConnectStatusSP eConnectStatusSP = EConnectStatusSP.DISCONNECTED;

    private SPIComm() {
    }

    public static SPIComm getInstance() {
        return Singleton.getObjectInstance(SPIComm.class);
    }

    public SPIComm init(SPUartParam param) {
        String sourceData = param.getAttrSP();
        String[] dataArray = sourceData.split(",");
        baudRate = Integer.parseInt(dataArray[0]);
        dataBit = Integer.parseInt(dataArray[1]);
        parity = processParity(dataArray[2]);
        stopBit = Integer.parseInt(dataArray[3]);
        return getInstance();
    }

    private int processParity(String s) {
        int ret = 0;
        switch (s) {
            case "n":
                ret = 0;
                break;
            case "o":
                ret = 1;
                break;
            case "e":
                ret = 2;
                break;
            case "m":
                ret = 3;
                break;
            case "s":
                ret = 4;
                break;
        }
        return ret;
    }

    /**
     * cancel receiver
     */
    public void cancelRecvSP() {
        synchronized (tLock) {
            tLock.notifyAll();
        }
        mHandler.removeCallbacksAndMessages(null);
        isRecv = false;

    }

    /**
     * connect serial port
     */
    public void connectSP() {
        if (eConnectStatusSP == EConnectStatusSP.CONNECTED || eConnectStatusSP == EConnectStatusSP.CONNECTING)
            return;
        eConnectStatusSP = EConnectStatusSP.CONNECTING;
        UsbDevice device = null;
        UsbSerialProber usbCustomProbe = RS232CustomProbe.getCustomProbe();
        UsbSerialProber usbDefaultProbe = UsbSerialProber.getDefaultProber();
        UsbManager usbManager = (UsbManager) SunmiPayKernel.getInstance().getAppContext().getSystemService(Context.USB_SERVICE);
        Collection<UsbDevice> usbDeviceList = usbManager.getDeviceList().values();
        // 优先查找PL2303芯片的
        for (UsbDevice item : usbDeviceList) {
            int productId = item.getProductId();
            String productIdString = String.format("%04X", productId);
            LogUtil.e(TAG, "productId: " + productIdString);
            boolean bool = TextUtils.equals("2303", productIdString) || TextUtils.equals("23C3", productIdString);
            if (bool) {
                UsbSerialDriver driver = usbDefaultProbe.probeDevice(item);
                if (driver == null) {
                    driver = usbCustomProbe.probeDevice(item);
                }
                if (driver != null) {
                    for (int port = 0; port < driver.getPorts().size(); port++) {
                        LogUtil.e(TAG, "The RS232 port: " + port + " driver: " + driver);
                        portNum = port;
                    }
                    device = item;
                    LogUtil.e(TAG, "The RS232 device: " + device);
                    break;
                }
            }
        }
        if (device == null) {
            for (UsbDevice item : usbDeviceList) {
                int vendorId = item.getVendorId();
                int productId = item.getProductId();
                String text = String.format("Vendor %04X, Product %04X", vendorId, productId);
                LogUtil.e(TAG, text);
                UsbSerialDriver driver = usbDefaultProbe.probeDevice(item);
                if (driver == null) {
                    driver = usbCustomProbe.probeDevice(item);
                }
                if (driver != null) {
                    for (int port = 0; port < driver.getPorts().size(); port++) {
                        LogUtil.e(TAG, "The RS232 port: " + port + " driver: " + driver);
                        portNum = port;
                    }
                    device = item;
                    LogUtil.e(TAG, "The RS232 device: " + device);
                    break;
                }
            }
        }
        if (device == null) {
            String message = "The connection failed: device not found";
            LogUtil.e(TAG, message);
            eConnectStatusSP = EConnectStatusSP.DISCONNECTED;
            return;
        }
        UsbSerialDriver driver = UsbSerialProber.getDefaultProber().probeDevice(device);
        if (driver == null) {
            driver = RS232CustomProbe.getCustomProbe().probeDevice(device);
        }
        if (driver == null) {
            String message = "The connection failed: no driver for device";
            LogUtil.e(TAG, message);
            eConnectStatusSP = EConnectStatusSP.DISCONNECTED;
            return;
        }
        if (driver.getPorts().size() < portNum) {
            String message = "The connection failed: not enough ports at device";
            LogUtil.e(TAG, message);
            eConnectStatusSP = EConnectStatusSP.DISCONNECTED;
            return;
        }
        UsbDeviceConnection usbConnection = null;
        usbSerialPort = driver.getPorts().get(portNum);
        try {
            UsbDevice driverDevice = driver.getDevice();
            usbConnection = usbManager.openDevice(driverDevice);
            boolean hasPermission = usbManager.hasPermission(driverDevice);
            if (usbConnection == null && !hasPermission) {
                grantUsbDevicePermission(usbManager, driverDevice);
            }
            if (usbConnection == null && usbPermission == UsbPermission.Unknown && !hasPermission) {
                usbPermission = UsbPermission.Requested;
                Intent intent = new Intent(ACTION_RS232_USB_PERMISSION);
                PendingIntent pendingIntent = PendingIntent.getBroadcast(SunmiPayKernel.getInstance().getAppContext(), 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);
                usbManager.requestPermission(driver.getDevice(), pendingIntent);
                eConnectStatusSP = EConnectStatusSP.DISCONNECTED;
                return;
            }
            if (usbConnection == null) {
                driverDevice = driver.getDevice();
                hasPermission = usbManager.hasPermission(driverDevice);
                String message;
                if (hasPermission) {
                    message = "The connection failed: open failed";
                } else {
                    message = "The connection failed: permission denied";
                }
                LogUtil.e(TAG, message);
                eConnectStatusSP = EConnectStatusSP.DISCONNECTED;
                return;
            }
        } catch (Exception e) {
            e.printStackTrace();
            eConnectStatusSP = EConnectStatusSP.DISCONNECTED;
        }
        try {
            usbSerialPort.open(usbConnection);
            usbSerialPort.setParameters(baudRate, dataBit, stopBit, parity);
            usbIoManager = new SerialInputOutputManager(usbSerialPort, serialInputOutputListener);
            usbIoManager.setReadTimeout(2000);
            usbIoManager.setWriteTimeout(2000);
            usbIoManager.start();
            LogUtil.e(TAG, "The connection success");
            eConnectStatusSP = EConnectStatusSP.CONNECTED;
        } catch (Exception e) {
            e.printStackTrace();
            String message = "The connection failed: " + e.getMessage();
            LogUtil.e(TAG, message);
            disconnect();
        }
    }

    private final SerialInputOutputManager.Listener serialInputOutputListener = new SerialInputOutputManager.Listener() {

        @Override
        public void onNewData(byte[] bytes) {
            if (bytes != null) {
                synchronized (sLock) {
                    if (MAX_BUFF_SIZE - available < bytes.length) {
                        available = 0;
                    }
                    System.arraycopy(bytes, 0, cacheArray, available, bytes.length);
                    available += bytes.length;
                    LogUtil.e(TAG, "The RS232 receive: " + ByteUtil.bytes2HexStr(bytes));
                }
            }
        }

        @Override
        public void onRunError(Exception e) {
            e.printStackTrace();
            LogUtil.e(TAG, "onRunError()");
            disconnect();
        }

    };


    private static final String ACTION_RS232_USB_PERMISSION = COMMUtil.getAppProcessName(SunmiPayKernel.getInstance().getAppContext()) + ".ACTION_RS232_USB_PERMISSION";


    /**
     * disconnect serial port
     */
    public void disconnectSP() {
        disconnect();
    }

    private void disconnect() {
        eConnectStatusSP = EConnectStatusSP.DISCONNECTED;
        if (usbIoManager != null) {
            usbIoManager.setListener(null);
            usbIoManager.stop();
        }
        try {
            if (usbSerialPort != null) {
                usbSerialPort.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        usbIoManager = null;
        usbSerialPort = null;
        usbPermission = UsbPermission.Unknown;
        if (eConnectStatusSP == EConnectStatusSP.CONNECTED) {
            synchronized (sLock) {
                available = 0;
                Arrays.fill(cacheArray, (byte) 0x00);
            }
        }
        if (isRecv) {
            synchronized (tLock) {
                notifyAll();
            }
        }
    }


    /**
     * get connect status
     *
     * @return {@link EConnectStatusSP}
     */
    public EConnectStatusSP getConnectStatusSP() {
        return eConnectStatusSP;
    }

    /**
     * get connect timeout(not support)
     *
     * @return millis
     */
    public int getConnectTimeoutSP() {
        return CONNECT_WAIT_MILLIS;
    }

    /**
     * get receiver timeout
     *
     * @return timeout millis
     */
    public int getRecvTimeoutSP() {
        return READ_WAIT_MILLIS;
    }

    /**
     * get send timeout
     *
     * @return timeout millis
     */
    public int getSendTimeoutSP() {
        return WRITE_WAIT_MILLIS;
    }

    /**
     * receiver data(Blocking)
     *
     * @param expLen length of data expected to receive "if expLen == -1, the interface is to detect the available data length of the serial buffer, and the return value is an int-converted 4-byte array.
     *               timeout = 0: Whether or not the serial port cache has data, the interface returns the result immediately.
     *               timeout > 0: If the cached data is detected within the timeout time, it will be returned immediately; if there is no data in the cache, keep the detection waiting until it returns after the timeout.
     *               timeout < 0: You can wait indefinitely until you have a serial port to cache data"
     * @return receiver data
     */
    public byte[] recvSP(int expLen) {
        if (expLen == -1) {
            synchronized (sLock) {
                byte[] b = new byte[4];
                for (int i = 0; i < 4; i++) {
                    b[i] = (byte) (available >> (24 - i * 8));
                }
                return b;
            }
        } else {
            if (READ_WAIT_MILLIS == 0) {
                synchronized (sLock) {
                    byte[] returnArray;
                    if (available > 0) {
                        returnArray = Arrays.copyOf(cacheArray, available);
                    } else {
                        returnArray = new byte[0];
                    }
                    available = 0;
                    return returnArray;
                }
            } else {
                isRecv = true;
                recvTask.start();
                if (READ_WAIT_MILLIS < 0) {//无限制等待模式，直到有数据返回
                    synchronized (tLock) {
                        try {
                            tLock.wait();
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                } else {
                    mHandler.sendEmptyMessageDelayed(MSG_TIMEOUT, READ_WAIT_MILLIS);
                    synchronized (tLock) {
                        try {
                            tLock.wait(READ_WAIT_MILLIS);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                }
                synchronized (sLock) {
                    byte[] returnArray;
                    if (available > 0) {
                        returnArray = Arrays.copyOf(cacheArray, available);
                    } else {
                        returnArray = new byte[0];
                    }
                    available = 0;
                    return returnArray;
                }
            }
        }
    }

    private Thread recvTask = new Thread(new Runnable() {
        @Override
        public void run() {
            while (isRecv) {
                try {
                    Thread.sleep(200);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                if (available > 0) {
                    isRecv = false;
                    mHandler.removeCallbacksAndMessages(null);
                    synchronized (tLock) {
                        tLock.notifyAll();
                    }
                }
            }
        }
    });


    private Handler mHandler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MSG_TIMEOUT:
                    isRecv = false;
                    synchronized (tLock) {
                        tLock.notifyAll();
                    }
                    break;
            }
        }
    };

    /**
     * receiver nonblocking
     *
     * @return receiver data
     */
    public byte[] recvNonBlockingSP() {
        synchronized (sLock) {
            byte[] returnArray;
            if (available > 0) {
                returnArray = Arrays.copyOf(cacheArray, available);
            } else {
                returnArray = new byte[0];
            }
            available = 0;
            return returnArray;
        }
    }

    /**
     * reset module(clean cache buff，if receiving data,cancel receiving)
     */
    public void resetSP() {
        isRecv = false;
        mHandler.removeCallbacksAndMessages(null);
        synchronized (sLock) {
            available = 0;
        }
        if (isRecv) {
            synchronized (tLock) {
                notifyAll();
            }
        }
    }

    /**
     * set connect timeout(no support)
     * @param timeoutMs
     */
    public void setConnectTimeoutSP(int timeoutMs) {
        CONNECT_WAIT_MILLIS = timeoutMs;
    }

    /**
     * set receiver timeout
     * @param timeoutMs
     */
    public void setRecvTimeoutSP(int timeoutMs) {
        READ_WAIT_MILLIS = timeoutMs;
    }

    /**
     * set send timeout
     * @param timeoutMs
     */
    public void setSendTimeoutSP(int timeoutMs) {
        WRITE_WAIT_MILLIS = timeoutMs;
    }

    /**
     * send data
     * @param data send data
     */
    public void sendSP(byte[] data){
        usbIoManager.writeAsync(data);
    }

    private enum UsbPermission {
        Unknown, Requested, Granted, Denied
    }

    public void registerReceiver() {
        IntentFilter intentFilter = new IntentFilter(ACTION_RS232_USB_PERMISSION);
        SunmiPayKernel.getInstance().getAppContext().registerReceiver(broadcastReceiver, intentFilter);
    }

    public void unregisterReceiver() {
        SunmiPayKernel.getInstance().getAppContext().unregisterReceiver(broadcastReceiver);
    }

    private final BroadcastReceiver broadcastReceiver = new BroadcastReceiver() {

        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent == null) return;
            String action = intent.getAction();
            if (action == null) return;
            boolean bool = TextUtils.equals(ACTION_RS232_USB_PERMISSION, action);
            if (bool) {
                boolean hasPermission = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false);
                LogUtil.e(TAG, "The RS232 receiver: " + hasPermission);
                usbPermission = hasPermission ? UsbPermission.Granted : UsbPermission.Denied;
                connectSP();
            }
        }
    };

    private void grantUsbDevicePermission(UsbManager usbManager, UsbDevice device) {
        try {
            Class<?> clazz = Class.forName("android.hardware.usb.UsbManager");
            Method method = clazz.getDeclaredMethod("grantPermission", UsbDevice.class, String.class);
            method.invoke(usbManager, device, COMMUtil.getAppProcessName(SunmiPayKernel.getInstance().getAppContext()));
            boolean hasPermission = usbManager.hasPermission(device);
            if (hasPermission) {
                usbPermission = UsbPermission.Granted;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
