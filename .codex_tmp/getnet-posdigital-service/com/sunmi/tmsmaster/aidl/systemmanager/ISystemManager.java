/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.systemmanager;
public interface ISystemManager extends android.os.IInterface
{
  /** Default implementation for ISystemManager. */
  public static class Default implements com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager
  {
    //updata system (OTA)

    @Override public void updateSystem(java.lang.String systemPath, com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener listener) throws android.os.RemoteException
    {
    }
    //set gms

    @Override public void enableGoogleMobileServices(boolean flag) throws android.os.RemoteException
    {
    }
    //Get battery usages
    //key(String):packageName，value(BigDecimal to String):battery usage(mA · h)

    @Override public java.util.Map getBatteryUsageOfEachApp() throws android.os.RemoteException
    {
      return null;
    }
    @Override public java.util.List<android.app.usage.UsageStats> queryAppUsageStats(int intervalType, long beginTime, long endTime) throws android.os.RemoteException
    {
      return null;
    }
    // Update system settings
    // boolean updateSetting(int key, String value);
    // Enable/disable update via OTA

    @Override public void enableSystemOTA(boolean enable) throws android.os.RemoteException
    {
    }
    // Check if update OTA system is enabled

    @Override public boolean isSystemOTAEnable() throws android.os.RemoteException
    {
      return false;
    }
    //Enable/disable GPS location

    @Override public void enableGPSLocation(boolean enabled) throws android.os.RemoteException
    {
    }
    @Override public void setGooglePlayEnabled(boolean enabled) throws android.os.RemoteException
    {
    }
    @Override public void setGoogleMapEnabled(boolean enabled) throws android.os.RemoteException
    {
    }
    @Override public void setGMSEnabled(boolean enabled) throws android.os.RemoteException
    {
    }
    @Override public void setGmailEnabled(boolean enabled) throws android.os.RemoteException
    {
    }
    @Override public java.util.Map getGmsAppEnabled() throws android.os.RemoteException
    {
      return null;
    }
    @Override public void setSettingsNeedPassword(java.lang.String packageName, java.lang.String password) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager))) {
        return ((com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager)iin);
      }
      return new com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager.Stub.Proxy(obj);
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
        case TRANSACTION_updateSystem:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener _arg1;
          _arg1 = com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener.Stub.asInterface(data.readStrongBinder());
          this.updateSystem(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_enableGoogleMobileServices:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableGoogleMobileServices(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_getBatteryUsageOfEachApp:
        {
          data.enforceInterface(descriptor);
          java.util.Map _result = this.getBatteryUsageOfEachApp();
          reply.writeNoException();
          reply.writeMap(_result);
          return true;
        }
        case TRANSACTION_queryAppUsageStats:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          long _arg1;
          _arg1 = data.readLong();
          long _arg2;
          _arg2 = data.readLong();
          java.util.List<android.app.usage.UsageStats> _result = this.queryAppUsageStats(_arg0, _arg1, _arg2);
          reply.writeNoException();
          reply.writeTypedList(_result);
          return true;
        }
        case TRANSACTION_enableSystemOTA:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableSystemOTA(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_isSystemOTAEnable:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.isSystemOTAEnable();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_enableGPSLocation:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableGPSLocation(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setGooglePlayEnabled:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.setGooglePlayEnabled(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setGoogleMapEnabled:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.setGoogleMapEnabled(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setGMSEnabled:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.setGMSEnabled(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setGmailEnabled:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.setGmailEnabled(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_getGmsAppEnabled:
        {
          data.enforceInterface(descriptor);
          java.util.Map _result = this.getGmsAppEnabled();
          reply.writeNoException();
          reply.writeMap(_result);
          return true;
        }
        case TRANSACTION_setSettingsNeedPassword:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          java.lang.String _arg1;
          _arg1 = data.readString();
          this.setSettingsNeedPassword(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager
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
      //updata system (OTA)

      @Override public void updateSystem(java.lang.String systemPath, com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener listener) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(systemPath);
          _data.writeStrongBinder((((listener!=null))?(listener.asBinder()):(null)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_updateSystem, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().updateSystem(systemPath, listener);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //set gms

      @Override public void enableGoogleMobileServices(boolean flag) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((flag)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableGoogleMobileServices, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableGoogleMobileServices(flag);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //Get battery usages
      //key(String):packageName，value(BigDecimal to String):battery usage(mA · h)

      @Override public java.util.Map getBatteryUsageOfEachApp() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.Map _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getBatteryUsageOfEachApp, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getBatteryUsageOfEachApp();
          }
          _reply.readException();
          java.lang.ClassLoader cl = (java.lang.ClassLoader)this.getClass().getClassLoader();
          _result = _reply.readHashMap(cl);
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public java.util.List<android.app.usage.UsageStats> queryAppUsageStats(int intervalType, long beginTime, long endTime) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.List<android.app.usage.UsageStats> _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(intervalType);
          _data.writeLong(beginTime);
          _data.writeLong(endTime);
          boolean _status = mRemote.transact(Stub.TRANSACTION_queryAppUsageStats, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().queryAppUsageStats(intervalType, beginTime, endTime);
          }
          _reply.readException();
          _result = _reply.createTypedArrayList(android.app.usage.UsageStats.CREATOR);
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // Update system settings
      // boolean updateSetting(int key, String value);
      // Enable/disable update via OTA

      @Override public void enableSystemOTA(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableSystemOTA, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableSystemOTA(enable);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Check if update OTA system is enabled

      @Override public boolean isSystemOTAEnable() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_isSystemOTAEnable, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().isSystemOTAEnable();
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
      //Enable/disable GPS location

      @Override public void enableGPSLocation(boolean enabled) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enabled)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableGPSLocation, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableGPSLocation(enabled);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void setGooglePlayEnabled(boolean enabled) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enabled)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_setGooglePlayEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setGooglePlayEnabled(enabled);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void setGoogleMapEnabled(boolean enabled) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enabled)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_setGoogleMapEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setGoogleMapEnabled(enabled);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void setGMSEnabled(boolean enabled) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enabled)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_setGMSEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setGMSEnabled(enabled);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void setGmailEnabled(boolean enabled) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enabled)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_setGmailEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setGmailEnabled(enabled);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public java.util.Map getGmsAppEnabled() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.Map _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getGmsAppEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getGmsAppEnabled();
          }
          _reply.readException();
          java.lang.ClassLoader cl = (java.lang.ClassLoader)this.getClass().getClassLoader();
          _result = _reply.readHashMap(cl);
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public void setSettingsNeedPassword(java.lang.String packageName, java.lang.String password) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeString(password);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setSettingsNeedPassword, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setSettingsNeedPassword(packageName, password);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager sDefaultImpl;
    }
    static final int TRANSACTION_updateSystem = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_enableGoogleMobileServices = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_getBatteryUsageOfEachApp = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_queryAppUsageStats = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_enableSystemOTA = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_isSystemOTAEnable = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    static final int TRANSACTION_enableGPSLocation = (android.os.IBinder.FIRST_CALL_TRANSACTION + 6);
    static final int TRANSACTION_setGooglePlayEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 7);
    static final int TRANSACTION_setGoogleMapEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 8);
    static final int TRANSACTION_setGMSEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 9);
    static final int TRANSACTION_setGmailEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 10);
    static final int TRANSACTION_getGmsAppEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 11);
    static final int TRANSACTION_setSettingsNeedPassword = (android.os.IBinder.FIRST_CALL_TRANSACTION + 12);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  //updata system (OTA)

  public void updateSystem(java.lang.String systemPath, com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener listener) throws android.os.RemoteException;
  //set gms

  public void enableGoogleMobileServices(boolean flag) throws android.os.RemoteException;
  //Get battery usages
  //key(String):packageName，value(BigDecimal to String):battery usage(mA · h)

  public java.util.Map getBatteryUsageOfEachApp() throws android.os.RemoteException;
  public java.util.List<android.app.usage.UsageStats> queryAppUsageStats(int intervalType, long beginTime, long endTime) throws android.os.RemoteException;
  // Update system settings
  // boolean updateSetting(int key, String value);
  // Enable/disable update via OTA

  public void enableSystemOTA(boolean enable) throws android.os.RemoteException;
  // Check if update OTA system is enabled

  public boolean isSystemOTAEnable() throws android.os.RemoteException;
  //Enable/disable GPS location

  public void enableGPSLocation(boolean enabled) throws android.os.RemoteException;
  public void setGooglePlayEnabled(boolean enabled) throws android.os.RemoteException;
  public void setGoogleMapEnabled(boolean enabled) throws android.os.RemoteException;
  public void setGMSEnabled(boolean enabled) throws android.os.RemoteException;
  public void setGmailEnabled(boolean enabled) throws android.os.RemoteException;
  public java.util.Map getGmsAppEnabled() throws android.os.RemoteException;
  public void setSettingsNeedPassword(java.lang.String packageName, java.lang.String password) throws android.os.RemoteException;
}
