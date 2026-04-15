/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.systemuimanager;
public interface ISystemUIManager extends android.os.IInterface
{
  /** Default implementation for ISystemUIManager. */
  public static class Default implements com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager
  {
    //set status bar

    @Override public void enableStatusBar(boolean flag) throws android.os.RemoteException
    {
    }
    //set navigation bar(Switch home back)

    @Override public void enableNavigationBar(byte flag) throws android.os.RemoteException
    {
    }
    //app set lock screen

    @Override public void enableLockScreen(boolean flag) throws android.os.RemoteException
    {
    }
    //set notification for specify app

    @Override public void enableNotification(java.lang.String packagename, boolean flag) throws android.os.RemoteException
    {
    }
    //set power button lock screen

    @Override public void enablePoweLockScreen(boolean flag) throws android.os.RemoteException
    {
    }
    //set screenbrightness value 0-255

    @Override public void setScreenBrightness(boolean automatic, int value) throws android.os.RemoteException
    {
    }
    //show or hide battery percent

    @Override public void showBatteryPercent(boolean show) throws android.os.RemoteException
    {
    }
    // Set whether the statusBar is displayed

    @Override public void showStatusBar(boolean show) throws android.os.RemoteException
    {
    }
    // Check if navigationBar is enabled or not

    @Override public boolean isNavigationBarEnabled() throws android.os.RemoteException
    {
      return false;
    }
    // Check if the navigation key is enabled/visible (true) or disabled/invisible (false)

    @Override public boolean isNavigationKeyEnabled(int type) throws android.os.RemoteException
    {
      return false;
    }
    // Reset StatusBar to default settings

    @Override public void resetStatusBar() throws android.os.RemoteException
    {
    }
    // Check whether the statusBar is enabled

    @Override public boolean isStatusBarEnabled() throws android.os.RemoteException
    {
      return false;
    }
    // Check whether the statusBar is visible

    @Override public boolean isStatusBarVisible() throws android.os.RemoteException
    {
      return false;
    }
    // Check if the NavigationBar is visible

    @Override public boolean isNavigationBarVisible() throws android.os.RemoteException
    {
      return false;
    }
    //set apn in Settings is display or hide

    @Override public boolean setAPNVisible(boolean enable) throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean setNavigationBarButtonLocation(int left, int center, int right) throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean setSettingsUiInstallWifiCertificate(int value) throws android.os.RemoteException
    {
      return false;
    }
    @Override public int getSettingsUiInstallWifiCertificate() throws android.os.RemoteException
    {
      return 0;
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager))) {
        return ((com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager)iin);
      }
      return new com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager.Stub.Proxy(obj);
    }
    @Override public android.os.IBinder asBinder()
    {
      return this;
    }
    @Override public boolean onTransact(int code, android.os.Parcel data, android.os.Parcel reply, int flags) throws android.os.RemoteException
    {
      java.lang.String descriptor = DESCRIPTOR;
      switch (code)
      {
        case INTERFACE_TRANSACTION:
        {
          reply.writeString(descriptor);
          return true;
        }
        case TRANSACTION_enableStatusBar:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableStatusBar(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_enableNavigationBar:
        {
          data.enforceInterface(descriptor);
          byte _arg0;
          _arg0 = data.readByte();
          this.enableNavigationBar(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_enableLockScreen:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableLockScreen(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_enableNotification:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _arg1;
          _arg1 = (0!=data.readInt());
          this.enableNotification(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_enablePoweLockScreen:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enablePoweLockScreen(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setScreenBrightness:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          int _arg1;
          _arg1 = data.readInt();
          this.setScreenBrightness(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_showBatteryPercent:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.showBatteryPercent(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_showStatusBar:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.showStatusBar(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_isNavigationBarEnabled:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.isNavigationBarEnabled();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_isNavigationKeyEnabled:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          boolean _result = this.isNavigationKeyEnabled(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_resetStatusBar:
        {
          data.enforceInterface(descriptor);
          this.resetStatusBar();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_isStatusBarEnabled:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.isStatusBarEnabled();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_isStatusBarVisible:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.isStatusBarVisible();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_isNavigationBarVisible:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.isNavigationBarVisible();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setAPNVisible:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          boolean _result = this.setAPNVisible(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setNavigationBarButtonLocation:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          int _arg1;
          _arg1 = data.readInt();
          int _arg2;
          _arg2 = data.readInt();
          boolean _result = this.setNavigationBarButtonLocation(_arg0, _arg1, _arg2);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setSettingsUiInstallWifiCertificate:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          boolean _result = this.setSettingsUiInstallWifiCertificate(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_getSettingsUiInstallWifiCertificate:
        {
          data.enforceInterface(descriptor);
          int _result = this.getSettingsUiInstallWifiCertificate();
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager
    {
      private android.os.IBinder mRemote;
      Proxy(android.os.IBinder remote)
      {
        mRemote = remote;
      }
      @Override public android.os.IBinder asBinder()
      {
        return mRemote;
      }
      public java.lang.String getInterfaceDescriptor()
      {
        return DESCRIPTOR;
      }
      //set status bar

      @Override public void enableStatusBar(boolean flag) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((flag)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableStatusBar, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableStatusBar(flag);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //set navigation bar(Switch home back)

      @Override public void enableNavigationBar(byte flag) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeByte(flag);
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableNavigationBar, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableNavigationBar(flag);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //app set lock screen

      @Override public void enableLockScreen(boolean flag) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((flag)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableLockScreen, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableLockScreen(flag);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //set notification for specify app

      @Override public void enableNotification(java.lang.String packagename, boolean flag) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packagename);
          _data.writeInt(((flag)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableNotification, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableNotification(packagename, flag);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //set power button lock screen

      @Override public void enablePoweLockScreen(boolean flag) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((flag)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enablePoweLockScreen, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enablePoweLockScreen(flag);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //set screenbrightness value 0-255

      @Override public void setScreenBrightness(boolean automatic, int value) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((automatic)?(1):(0)));
          _data.writeInt(value);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setScreenBrightness, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setScreenBrightness(automatic, value);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //show or hide battery percent

      @Override public void showBatteryPercent(boolean show) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((show)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_showBatteryPercent, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().showBatteryPercent(show);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Set whether the statusBar is displayed

      @Override public void showStatusBar(boolean show) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((show)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_showStatusBar, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().showStatusBar(show);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Check if navigationBar is enabled or not

      @Override public boolean isNavigationBarEnabled() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_isNavigationBarEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().isNavigationBarEnabled();
          }
          _reply.readException();
          _result = (0!=_reply.readInt());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // Check if the navigation key is enabled/visible (true) or disabled/invisible (false)

      @Override public boolean isNavigationKeyEnabled(int type) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(type);
          boolean _status = mRemote.transact(Stub.TRANSACTION_isNavigationKeyEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().isNavigationKeyEnabled(type);
          }
          _reply.readException();
          _result = (0!=_reply.readInt());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // Reset StatusBar to default settings

      @Override public void resetStatusBar() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_resetStatusBar, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().resetStatusBar();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Check whether the statusBar is enabled

      @Override public boolean isStatusBarEnabled() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_isStatusBarEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().isStatusBarEnabled();
          }
          _reply.readException();
          _result = (0!=_reply.readInt());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // Check whether the statusBar is visible

      @Override public boolean isStatusBarVisible() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_isStatusBarVisible, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().isStatusBarVisible();
          }
          _reply.readException();
          _result = (0!=_reply.readInt());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // Check if the NavigationBar is visible

      @Override public boolean isNavigationBarVisible() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_isNavigationBarVisible, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().isNavigationBarVisible();
          }
          _reply.readException();
          _result = (0!=_reply.readInt());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      //set apn in Settings is display or hide

      @Override public boolean setAPNVisible(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_setAPNVisible, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setAPNVisible(enable);
          }
          _reply.readException();
          _result = (0!=_reply.readInt());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public boolean setNavigationBarButtonLocation(int left, int center, int right) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(left);
          _data.writeInt(center);
          _data.writeInt(right);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setNavigationBarButtonLocation, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setNavigationBarButtonLocation(left, center, right);
          }
          _reply.readException();
          _result = (0!=_reply.readInt());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public boolean setSettingsUiInstallWifiCertificate(int value) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(value);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setSettingsUiInstallWifiCertificate, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setSettingsUiInstallWifiCertificate(value);
          }
          _reply.readException();
          _result = (0!=_reply.readInt());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public int getSettingsUiInstallWifiCertificate() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getSettingsUiInstallWifiCertificate, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getSettingsUiInstallWifiCertificate();
          }
          _reply.readException();
          _result = _reply.readInt();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      public static com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager sDefaultImpl;
    }
    static final int TRANSACTION_enableStatusBar = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_enableNavigationBar = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_enableLockScreen = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_enableNotification = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_enablePoweLockScreen = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_setScreenBrightness = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    static final int TRANSACTION_showBatteryPercent = (android.os.IBinder.FIRST_CALL_TRANSACTION + 6);
    static final int TRANSACTION_showStatusBar = (android.os.IBinder.FIRST_CALL_TRANSACTION + 7);
    static final int TRANSACTION_isNavigationBarEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 8);
    static final int TRANSACTION_isNavigationKeyEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 9);
    static final int TRANSACTION_resetStatusBar = (android.os.IBinder.FIRST_CALL_TRANSACTION + 10);
    static final int TRANSACTION_isStatusBarEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 11);
    static final int TRANSACTION_isStatusBarVisible = (android.os.IBinder.FIRST_CALL_TRANSACTION + 12);
    static final int TRANSACTION_isNavigationBarVisible = (android.os.IBinder.FIRST_CALL_TRANSACTION + 13);
    static final int TRANSACTION_setAPNVisible = (android.os.IBinder.FIRST_CALL_TRANSACTION + 14);
    static final int TRANSACTION_setNavigationBarButtonLocation = (android.os.IBinder.FIRST_CALL_TRANSACTION + 15);
    static final int TRANSACTION_setSettingsUiInstallWifiCertificate = (android.os.IBinder.FIRST_CALL_TRANSACTION + 16);
    static final int TRANSACTION_getSettingsUiInstallWifiCertificate = (android.os.IBinder.FIRST_CALL_TRANSACTION + 17);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  //set status bar

  public void enableStatusBar(boolean flag) throws android.os.RemoteException;
  //set navigation bar(Switch home back)

  public void enableNavigationBar(byte flag) throws android.os.RemoteException;
  //app set lock screen

  public void enableLockScreen(boolean flag) throws android.os.RemoteException;
  //set notification for specify app

  public void enableNotification(java.lang.String packagename, boolean flag) throws android.os.RemoteException;
  //set power button lock screen

  public void enablePoweLockScreen(boolean flag) throws android.os.RemoteException;
  //set screenbrightness value 0-255

  public void setScreenBrightness(boolean automatic, int value) throws android.os.RemoteException;
  //show or hide battery percent

  public void showBatteryPercent(boolean show) throws android.os.RemoteException;
  // Set whether the statusBar is displayed

  public void showStatusBar(boolean show) throws android.os.RemoteException;
  // Check if navigationBar is enabled or not

  public boolean isNavigationBarEnabled() throws android.os.RemoteException;
  // Check if the navigation key is enabled/visible (true) or disabled/invisible (false)

  public boolean isNavigationKeyEnabled(int type) throws android.os.RemoteException;
  // Reset StatusBar to default settings

  public void resetStatusBar() throws android.os.RemoteException;
  // Check whether the statusBar is enabled

  public boolean isStatusBarEnabled() throws android.os.RemoteException;
  // Check whether the statusBar is visible

  public boolean isStatusBarVisible() throws android.os.RemoteException;
  // Check if the NavigationBar is visible

  public boolean isNavigationBarVisible() throws android.os.RemoteException;
  //set apn in Settings is display or hide

  public boolean setAPNVisible(boolean enable) throws android.os.RemoteException;
  public boolean setNavigationBarButtonLocation(int left, int center, int right) throws android.os.RemoteException;
  public boolean setSettingsUiInstallWifiCertificate(int value) throws android.os.RemoteException;
  public int getSettingsUiInstallWifiCertificate() throws android.os.RemoteException;
}
