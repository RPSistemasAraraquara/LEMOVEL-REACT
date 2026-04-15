package sunmi.paylib;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Binder;
import android.os.Handler;
import android.os.IBinder;
import android.os.IInterface;
import android.os.Looper;
import android.util.Log;
import android.view.Window;

import com.sunmi.pay.hardware.aidl.DeviceProvide;
import com.sunmi.pay.hardware.aidl.emv.EMVOpt;
import com.sunmi.pay.hardware.aidl.pinpad.PinPadOpt;
import com.sunmi.pay.hardware.aidl.print.PrinterOpt;
import com.sunmi.pay.hardware.aidl.readcard.ReadCardOpt;
import com.sunmi.pay.hardware.aidl.security.SecurityOpt;
import com.sunmi.pay.hardware.aidl.system.BasicOpt;
import com.sunmi.pay.hardware.aidl.tax.TaxOpt;
import com.sunmi.pay.hardware.aidlv2.emv.EMVOptV2;
import com.sunmi.pay.hardware.aidlv2.etc.ETCOptV2;
import com.sunmi.pay.hardware.aidlv2.pinpad.PinPadOptV2;
import com.sunmi.pay.hardware.aidlv2.print.PrinterOptV2;
import com.sunmi.pay.hardware.aidlv2.readcard.ReadCardOptV2;
import com.sunmi.pay.hardware.aidlv2.security.SecurityOptV2;
import com.sunmi.pay.hardware.aidlv2.system.BasicOptV2;
import com.sunmi.pay.hardware.aidlv2.tax.TaxOptV2;
import com.sunmi.tmsmaster.aidl.IDeviceService;
import com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager;
import com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo;
import com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager;
import com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo;
import com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager;
import com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager;
import com.sunmi.tmsmaster.aidl.pm.IServicePreference;
import com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager;
import com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager;
import com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager;

import java.lang.reflect.Method;
import java.util.List;

import sunmi.paylib.adapter.spicomm.SPIComm;
import sunmi.paylib.adapter.spicomm.SPICommManager;
import sunmi.paylib.adapter.spiped.SPIPed;
import sunmi.paylib.adapter.spiphonemanager.SPIPhoneManager;

/** 连接SDK ADIL服务 */
public class SunmiPayKernel {
    private static final String TAG = "SunmiPayKernel";
    private static final int BIND_FLAG_PAY_SDK = 1 << 0;
    private static final int BIND_FLAG_TMS = 1 << 1;

    /** 基础操作模块 */
    public BasicOpt mBasicOpt;
    /** 读卡模块 */
    public ReadCardOpt mReadCardOpt;
    /** PinPad操作模块 */
    public PinPadOpt mPinPadOpt;
    /** EMV操作模块 */
    public EMVOpt mEMVOpt;
    /** 安全加密模块 */
    public SecurityOpt mSecurityOpt;
    /** 打印模块 */
    public PrinterOpt mPrinterOpt;
    /** 税控模块 */
    public TaxOpt mTaxOpt;

    /** 基础操作模块(V2版本) */
    public BasicOptV2 mBasicOptV2;
    /** 读卡模块(V2版本) */
    public ReadCardOptV2 mReadCardOptV2;
    /** PinPad操作模块(V2版本) */
    public PinPadOptV2 mPinPadOptV2;
    /** EMV操作模块(V2版本) */
    public EMVOptV2 mEMVOptV2;
    /**
     * 安全加密模块(V2版本)
     */
    public SecurityOptV2 mSecurityOptV2;
    /**
     * 打印模块(V2版本)
     */
    public PrinterOptV2 mPrinterOptV2;
    /**
     * 税控模块(V2版本)
     */
    public TaxOptV2 mTaxOptV2;
    /**
     * ETC模块(V2版本)
     */
    public ETCOptV2 mETCOptV2;

    /**
     * 设备信息模块
     */
    public IDeviceInfo mIDeviceInfo;
    /**
     * 设备管理模块
     */
    public IDeviceManager mIDeviceManager;
    /**
     * 软件管理模块
     */
    public ISoftwareManager mISoftwareManager;
    /**
     * 系统管理模块
     */
    public ISystemManager mISystemManager;
    /**
     * 系统UI管理模块
     */
    public ISystemUIManager mISystemUIManager;
    /**
     * Kiosk管理模块
     */
    public IKioskManager mIKioskManager;
    /**
     * 设备运行信息模块
     */
    public IDeviceRunningInfo mIDeviceRunningInfo;
    /**
     * 证书管理模块
     */
    public ICertificateManager mICertificateManager;
    /**
     * 网络管理模块
     */
    public INetworkManager mINetworkManager;
    /**
     * 资源包管理模块
     */
    public IServicePreference mIServicePreference;

    /**
     * Sunmi系统api
     */
    public SunmiCustomApi mSunmiCustomApi;

    /**
     * CommManager 模块
     */
    public SPICommManager mSPICommManager;

    /**
     * SPIPed 模块
     */
    public SPIPed mSPIPed;

    /**
     * SPIPhoneManager 模块
     */
    public SPIPhoneManager mSPIPhoneManager;

    /**
     * SDK连接回调
     */
    private ConnCallback mConnCallback;
    /**
     * SDK连接回调(V2版本)
     */
    private ConnectCallback mConnCallbackV2;

    private Context appContext;
    private int bindCount;
    private int bindFlags;
    @SuppressLint("StaticFieldLeak")
    private static final SunmiPayKernel INSTANCE = new SunmiPayKernel();

    private SunmiPayKernel() {
    }

    public static SunmiPayKernel getInstance() {
        return INSTANCE;
    }

    /** Get ApplicationContext */
    public Context getAppContext() {
        return appContext;
    }

    /** Set ApplicationContext */
    public void setAppContext(Context appContext) {
        this.appContext = appContext;
    }

    /** Get this PayLib version */
    public String getPayLibVersion() {
        return "1.4.48";
    }

    /**
     * Get pay sdk version which matched this PayLib,
     * for backward compatibility, the installed sdk version
     * should great or equal this method returned value
     */
    public String getMatchedPaySDKVersion() {
        return "v3.3.98";
    }

    /**
     * 绑定支付SDK
     *
     * @param context      Context对象
     * @param connCallback 绑定操作回调对象
     */
    @Deprecated
    public void connectPayService(Context context, ConnCallback connCallback) {
        mConnCallback = connCallback;
        Intent intent = new Intent("sunmi.intent.action.PAY_HARDWARE");
        intent.setPackage("com.sunmi.pay.hardware_v3");
        appContext = context.getApplicationContext();
        PackageManager pkgManager = appContext.getPackageManager();
        List<ResolveInfo> infos = pkgManager.queryIntentServices(intent, 0);
        if (infos != null && !infos.isEmpty()) {
            bindCount++;
            appContext.startService(intent);
            appContext.bindService(intent, mPaySDKServiceConnection, Context.BIND_NOT_FOREGROUND);
        } else {
            Log.e(TAG, "bind PayHardwareService failed: service not found");
        }
    }

    /**
     * Bind to payment SDK
     *
     * @param context  Context
     * @param callback callback of binding
     * @return 绑定Service是否成功，true-成功，false-失败
     */
    public boolean initPaySDK(Context context, ConnectCallback callback) {
        boolean hasBind = false;
        bindCount = 0;
//        bindFlags = 0;
        mConnCallbackV2 = callback;
        appContext = context.getApplicationContext();
        hasBind = bindSunmiPayHardwareService();
        hasBind |= bindSunmiTMSService();
        if (bindCount == 0 && bindFlags == (BIND_FLAG_PAY_SDK | BIND_FLAG_TMS)) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mConnCallbackV2.onConnectPaySDK();
                }
            });
        }
        SunmiCustomApi.getInstance().init(context);
        SPIPhoneManager.getInstance().init(context);
        return hasBind;
    }

    private final Handler mHandler = new Handler(Looper.getMainLooper());

    /**
     * unbind payment SDK
     *
     * @param context Context
     */
    @Deprecated
    public void unbindPayService(Context context) {
        Context appCtx = context.getApplicationContext();
        if ((bindFlags & BIND_FLAG_PAY_SDK) != 0) {
            appCtx.unbindService(mPaySDKServiceConnection);
            bindFlags &= ~BIND_FLAG_PAY_SDK;
        }
        if ((bindFlags & BIND_FLAG_TMS) != 0) {
            appCtx.unbindService(mTMSServiceConnection);
            bindFlags &= ~BIND_FLAG_TMS;
        }
    }

    /** Unbind payment SDK */
    public void destroyPaySDK() {
        unbindPayService(appContext);
    }

    /** Bind to SunmiPayHardwareService */
    private boolean bindSunmiPayHardwareService() {
        if ((bindFlags & BIND_FLAG_PAY_SDK) != 0) {
            return true;
        }
        Intent intent = new Intent("sunmi.intent.action.PAY_HARDWARE");
        intent.setPackage("com.sunmi.pay.hardware_v3");
        PackageManager pkgManager = appContext.getPackageManager();
        List<ResolveInfo> infos = pkgManager.queryIntentServices(intent, 0);
        if (infos != null && !infos.isEmpty()) {
            bindCount++;
            appContext.startService(intent);
            return appContext.bindService(intent, mPaySDKServiceConnection, Context.BIND_NOT_FOREGROUND);
        } else {
            Log.e(TAG, "bind PayHardwareService failed: service not found");
        }
        return false;
    }

    /** Bind to SunmiTMSService */
    private boolean bindSunmiTMSService() {
        if ((bindFlags & BIND_FLAG_TMS) != 0) {
            return true;
        }
        Intent intent = new Intent("com.sunmi.tms_service");
        intent.setPackage("com.sunmi.tmservice");
        PackageManager pkgManager = appContext.getPackageManager();
        List<ResolveInfo> infos = pkgManager.queryIntentServices(intent, 0);
        if (infos != null && !infos.isEmpty()) {
            bindCount++;
            appContext.startService(intent);
            return appContext.bindService(intent, mTMSServiceConnection, Context.BIND_NOT_FOREGROUND);
        } else {
            Log.e(TAG, "bind TMSService failed: service not found");
        }
        return false;
    }

    /** Callback of binding payment SDK Service */
    private final ServiceConnection mPaySDKServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            try {
                DeviceProvide provider = DeviceProvide.Stub.asInterface(service);
                if (!setBinder(provider)) {
                    return;
                }
                Method[] methods = DeviceProvide.class.getDeclaredMethods();
                mBasicOpt = getOptBinder(provider, methods, BasicOpt.class);
                mReadCardOpt = getOptBinder(provider, methods, ReadCardOpt.class);
                mPinPadOpt = getOptBinder(provider, methods, PinPadOpt.class);
                mEMVOpt = getOptBinder(provider, methods, EMVOpt.class);
                mSecurityOpt = getOptBinder(provider, methods, SecurityOpt.class);
                mPrinterOpt = getOptBinder(provider, methods, PrinterOpt.class);
                mTaxOpt = getOptBinder(provider, methods, TaxOpt.class);
                mBasicOptV2 = getOptBinder(provider, methods, BasicOptV2.class);
                mReadCardOptV2 = getOptBinder(provider, methods, ReadCardOptV2.class);
                mPinPadOptV2 = getOptBinder(provider, methods, PinPadOptV2.class);
                mEMVOptV2 = getOptBinder(provider, methods, EMVOptV2.class);
                mSecurityOptV2 = getOptBinder(provider, methods, SecurityOptV2.class);
                mPrinterOptV2 = getOptBinder(provider, methods, PrinterOptV2.class);
                mTaxOptV2 = getOptBinder(provider, methods, TaxOptV2.class);
                mETCOptV2 = getOptBinder(provider, methods, ETCOptV2.class);
                mSunmiCustomApi = SunmiCustomApi.getInstance();
                mSPICommManager = SPICommManager.getInstance();
                mSPIPed = SPIPed.getInstance();
                mSPIPhoneManager = SPIPhoneManager.getInstance();
                mSPIPed.init();
                bindFlags |= BIND_FLAG_PAY_SDK;
                bindCount--;
                if (bindCount == 0 && mConnCallback != null) {
                    mConnCallback.onServiceConnected();
                }
                if (bindCount == 0 && mConnCallbackV2 != null) {
                    mConnCallbackV2.onConnectPaySDK();
                }
                SPIComm.getInstance().registerReceiver();
            } catch (Exception e) {
                e.printStackTrace();
                Log.e(TAG, "bind SunmiPayHardwareService exception:" + e);
            }
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            bindFlags &= ~BIND_FLAG_PAY_SDK;
            SPIComm.getInstance().unregisterReceiver();
            mSPIPed.onRecycle();
            if (mConnCallback != null) {
                mConnCallback.onServiceDisconnected();
            }
            if (mConnCallbackV2 != null) {
                mConnCallbackV2.onDisconnectPaySDK();
            }
        }

        /** 设置Binder，Service端根据此Binder监测client端进程是否死掉 */
        private boolean setBinder(DeviceProvide provider) {
            try {
                return provider.setBinder(new Binder()) >= 0;
            } catch (Exception e) {
                e.printStackTrace();
            }
            return false;
        }
    };

    /** Callback of binding TMS Service */
    private final ServiceConnection mTMSServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            IDeviceService provider = IDeviceService.Stub.asInterface(service);
            try {
                Method[] methods = IDeviceService.class.getDeclaredMethods();
                mIDeviceInfo = getOptBinder(provider, methods, IDeviceInfo.class);
                mIDeviceManager = getOptBinder(provider, methods, IDeviceManager.class);
                mISoftwareManager = getOptBinder(provider, methods, ISoftwareManager.class);
                mISystemManager = getOptBinder(provider, methods, ISystemManager.class);
                mISystemUIManager = getOptBinder(provider, methods, ISystemUIManager.class);
                mIKioskManager = getOptBinder(provider, methods, IKioskManager.class);
                mIDeviceRunningInfo = getOptBinder(provider, methods, IDeviceRunningInfo.class);
                mICertificateManager = getOptBinder(provider, methods, ICertificateManager.class);
                mINetworkManager = getOptBinder(provider, methods, INetworkManager.class);
                mIServicePreference = getOptBinder(provider, methods, IServicePreference.class);
                bindFlags |= BIND_FLAG_TMS;
                bindCount--;
                if (bindCount == 0 && mConnCallback != null) {
                    mConnCallback.onServiceConnected();
                }
                if (bindCount == 0 && mConnCallbackV2 != null) {
                    mConnCallbackV2.onConnectPaySDK();
                }
            } catch (Exception e) {
                e.printStackTrace();
                Log.e(TAG, "bind SunmiTMSService exception:" + e);
            }
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            bindFlags &= ~BIND_FLAG_TMS;
            if (mConnCallback != null) {
                mConnCallback.onServiceDisconnected();
            }
            if (mConnCallbackV2 != null) {
                mConnCallbackV2.onDisconnectPaySDK();
            }
        }
    };

    @SuppressWarnings("unchecked")
    private <T> T getOptBinder(IInterface provider, Method[] methods, Class<T> optClass) {
        try {
            for (Method method : methods) {
                Class<?> retType = method.getReturnType();
                if (retType == optClass) {
                    return (T) method.invoke(provider);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * 屏幕独占 禁用底部导航栏和SystemUI下拉框、保持屏幕高亮，不锁屏、禁用音量键
     */
    public static void screenMonopoly(Window window) {
        UIUtils.screenMonopoly(window);
    }

    /**
     * dialog弹出时调用此函数可实现屏幕独占
     * 禁用底部导航栏和SystemUI下拉框、保持屏幕高亮，不锁屏、禁用音量键
     */
    public static void screenMonopoly(Dialog dialog) {
        UIUtils.screenMonopoly(dialog);
    }

    /** 支付SDK绑定结果回调 */
    @Deprecated
    public interface ConnCallback {
        /** 连接成功 */
        void onServiceConnected();

        /** 连接断开 */
        void onServiceDisconnected();
    }

    /** 连接支付SDK回调接口 */
    public interface ConnectCallback {
        /** 连接成功 */
        void onConnectPaySDK();

        /** 连接断开 */
        void onDisconnectPaySDK();
    }
}
