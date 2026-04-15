/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.softwaremanager;
public interface ISoftwareManager extends android.os.IInterface
{
  /** Default implementation for ISoftwareManager. */
  public static class Default implements com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager
  {
    //app install

    @Override public void installApp(java.lang.String appFilePath, com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener listener) throws android.os.RemoteException
    {
    }
    //app uninstall

    @Override public void uninstallApp(java.lang.String packageName, com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener listener) throws android.os.RemoteException
    {
    }
    //prohibit uninstall package

    @Override public void prohibitUninstall(java.lang.String packageName, boolean allowUninstall) throws android.os.RemoteException
    {
    }
    // Get the foreground app

    @Override public java.lang.String getForegroundPackage() throws android.os.RemoteException
    {
      return null;
    }
    // Whether the application is currently foreground or background

    @Override public boolean isForeground(java.lang.String packageName) throws android.os.RemoteException
    {
      return false;
    }
    //Enable/disable application

    @Override public boolean switchAppEnable(java.lang.String packageName, boolean enable) throws android.os.RemoteException
    {
      return false;
    }
    //Get Undeletable application list

    @Override public java.util.List<java.lang.String> getUndeletableAppList() throws android.os.RemoteException
    {
      return null;
    }
    //Set Launcher application
    //packageName: application package name activityName: application launcher activity
    //0 if set success

    @Override public int setLauncherApp(java.lang.String packageName, java.lang.String activityName) throws android.os.RemoteException
    {
      return 0;
    }
    // Batch uninstall non-system applications (Synchronous blocking functions)

    @Override public int restoreFactorySettings() throws android.os.RemoteException
    {
      return 0;
    }
    @Override public void clearApplicationUserData(java.lang.String packageName, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callback) throws android.os.RemoteException
    {
    }
    @Override public void deleteApplicationCacheFiles(java.lang.String packageName, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callback) throws android.os.RemoteException
    {
    }
    @Override public boolean grantAppPermissions(java.lang.String packageName, java.lang.String permissions) throws android.os.RemoteException
    {
      return false;
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager))) {
        return ((com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager)iin);
      }
      return new com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager.Stub.Proxy(obj);
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
        case TRANSACTION_installApp:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener _arg1;
          _arg1 = com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener.Stub.asInterface(data.readStrongBinder());
          this.installApp(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_uninstallApp:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener _arg1;
          _arg1 = com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener.Stub.asInterface(data.readStrongBinder());
          this.uninstallApp(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_prohibitUninstall:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _arg1;
          _arg1 = (0!=data.readInt());
          this.prohibitUninstall(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_getForegroundPackage:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getForegroundPackage();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_isForeground:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.isForeground(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_switchAppEnable:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _arg1;
          _arg1 = (0!=data.readInt());
          boolean _result = this.switchAppEnable(_arg0, _arg1);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_getUndeletableAppList:
        {
          data.enforceInterface(descriptor);
          java.util.List<java.lang.String> _result = this.getUndeletableAppList();
          reply.writeNoException();
          reply.writeStringList(_result);
          return true;
        }
        case TRANSACTION_setLauncherApp:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          java.lang.String _arg1;
          _arg1 = data.readString();
          int _result = this.setLauncherApp(_arg0, _arg1);
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_restoreFactorySettings:
        {
          data.enforceInterface(descriptor);
          int _result = this.restoreFactorySettings();
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_clearApplicationUserData:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback _arg1;
          _arg1 = com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback.Stub.asInterface(data.readStrongBinder());
          this.clearApplicationUserData(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_deleteApplicationCacheFiles:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback _arg1;
          _arg1 = com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback.Stub.asInterface(data.readStrongBinder());
          this.deleteApplicationCacheFiles(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_grantAppPermissions:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          java.lang.String _arg1;
          _arg1 = data.readString();
          boolean _result = this.grantAppPermissions(_arg0, _arg1);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager
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
      //app install

      @Override public void installApp(java.lang.String appFilePath, com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener listener) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(appFilePath);
          _data.writeStrongBinder((((listener!=null))?(listener.asBinder()):(null)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_installApp, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().installApp(appFilePath, listener);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //app uninstall

      @Override public void uninstallApp(java.lang.String packageName, com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener listener) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeStrongBinder((((listener!=null))?(listener.asBinder()):(null)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_uninstallApp, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().uninstallApp(packageName, listener);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //prohibit uninstall package

      @Override public void prohibitUninstall(java.lang.String packageName, boolean allowUninstall) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeInt(((allowUninstall)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_prohibitUninstall, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().prohibitUninstall(packageName, allowUninstall);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Get the foreground app

      @Override public java.lang.String getForegroundPackage() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getForegroundPackage, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getForegroundPackage();
          }
          _reply.readException();
          _result = _reply.readString();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // Whether the application is currently foreground or background

      @Override public boolean isForeground(java.lang.String packageName) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          boolean _status = mRemote.transact(Stub.TRANSACTION_isForeground, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().isForeground(packageName);
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
      //Enable/disable application

      @Override public boolean switchAppEnable(java.lang.String packageName, boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_switchAppEnable, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().switchAppEnable(packageName, enable);
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
      //Get Undeletable application list

      @Override public java.util.List<java.lang.String> getUndeletableAppList() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.List<java.lang.String> _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getUndeletableAppList, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getUndeletableAppList();
          }
          _reply.readException();
          _result = _reply.createStringArrayList();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      //Set Launcher application
      //packageName: application package name activityName: application launcher activity
      //0 if set success

      @Override public int setLauncherApp(java.lang.String packageName, java.lang.String activityName) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeString(activityName);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setLauncherApp, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setLauncherApp(packageName, activityName);
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
      // Batch uninstall non-system applications (Synchronous blocking functions)

      @Override public int restoreFactorySettings() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_restoreFactorySettings, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().restoreFactorySettings();
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
      @Override public void clearApplicationUserData(java.lang.String packageName, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callback) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeStrongBinder((((callback!=null))?(callback.asBinder()):(null)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_clearApplicationUserData, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().clearApplicationUserData(packageName, callback);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void deleteApplicationCacheFiles(java.lang.String packageName, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callback) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeStrongBinder((((callback!=null))?(callback.asBinder()):(null)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_deleteApplicationCacheFiles, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().deleteApplicationCacheFiles(packageName, callback);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public boolean grantAppPermissions(java.lang.String packageName, java.lang.String permissions) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeString(permissions);
          boolean _status = mRemote.transact(Stub.TRANSACTION_grantAppPermissions, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().grantAppPermissions(packageName, permissions);
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
      public static com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager sDefaultImpl;
    }
    static final int TRANSACTION_installApp = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_uninstallApp = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_prohibitUninstall = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_getForegroundPackage = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_isForeground = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_switchAppEnable = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    static final int TRANSACTION_getUndeletableAppList = (android.os.IBinder.FIRST_CALL_TRANSACTION + 6);
    static final int TRANSACTION_setLauncherApp = (android.os.IBinder.FIRST_CALL_TRANSACTION + 7);
    static final int TRANSACTION_restoreFactorySettings = (android.os.IBinder.FIRST_CALL_TRANSACTION + 8);
    static final int TRANSACTION_clearApplicationUserData = (android.os.IBinder.FIRST_CALL_TRANSACTION + 9);
    static final int TRANSACTION_deleteApplicationCacheFiles = (android.os.IBinder.FIRST_CALL_TRANSACTION + 10);
    static final int TRANSACTION_grantAppPermissions = (android.os.IBinder.FIRST_CALL_TRANSACTION + 11);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  //app install

  public void installApp(java.lang.String appFilePath, com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener listener) throws android.os.RemoteException;
  //app uninstall

  public void uninstallApp(java.lang.String packageName, com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener listener) throws android.os.RemoteException;
  //prohibit uninstall package

  public void prohibitUninstall(java.lang.String packageName, boolean allowUninstall) throws android.os.RemoteException;
  // Get the foreground app

  public java.lang.String getForegroundPackage() throws android.os.RemoteException;
  // Whether the application is currently foreground or background

  public boolean isForeground(java.lang.String packageName) throws android.os.RemoteException;
  //Enable/disable application

  public boolean switchAppEnable(java.lang.String packageName, boolean enable) throws android.os.RemoteException;
  //Get Undeletable application list

  public java.util.List<java.lang.String> getUndeletableAppList() throws android.os.RemoteException;
  //Set Launcher application
  //packageName: application package name activityName: application launcher activity
  //0 if set success

  public int setLauncherApp(java.lang.String packageName, java.lang.String activityName) throws android.os.RemoteException;
  // Batch uninstall non-system applications (Synchronous blocking functions)

  public int restoreFactorySettings() throws android.os.RemoteException;
  public void clearApplicationUserData(java.lang.String packageName, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callback) throws android.os.RemoteException;
  public void deleteApplicationCacheFiles(java.lang.String packageName, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callback) throws android.os.RemoteException;
  public boolean grantAppPermissions(java.lang.String packageName, java.lang.String permissions) throws android.os.RemoteException;
}
