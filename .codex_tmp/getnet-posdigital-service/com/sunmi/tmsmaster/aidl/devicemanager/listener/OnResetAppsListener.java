/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.devicemanager.listener;
public interface OnResetAppsListener extends android.os.IInterface
{
  /** Default implementation for OnResetAppsListener. */
  public static class Default implements com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener
  {
    /**
                 * uninstall apps progress
                 * @param progress
                 */
    @Override public void progress(int progress) throws android.os.RemoteException
    {
    }
    /**
                 *  reset an app fail
                 * @param info
                 */
    @Override public void resetAppFail(java.lang.String packageName, int returnCode) throws android.os.RemoteException
    {
    }
    /**
                 * reset an app success
                 * @param info
                 */
    @Override public void resetAppSuccess(java.lang.String packageName, int returnCode) throws android.os.RemoteException
    {
    }
    /**
                *  reset an app fail
                * @param info
                */
    @Override public void resetAppNoPermission() throws android.os.RemoteException
    {
    }
    /**
                *  reset on apps
                *
                */
    @Override public void resetNoApps() throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener))) {
        return ((com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener)iin);
      }
      return new com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener.Stub.Proxy(obj);
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
        case TRANSACTION_progress:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          this.progress(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_resetAppFail:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          int _arg1;
          _arg1 = data.readInt();
          this.resetAppFail(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_resetAppSuccess:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          int _arg1;
          _arg1 = data.readInt();
          this.resetAppSuccess(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_resetAppNoPermission:
        {
          data.enforceInterface(descriptor);
          this.resetAppNoPermission();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_resetNoApps:
        {
          data.enforceInterface(descriptor);
          this.resetNoApps();
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener
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
      /**
                   * uninstall apps progress
                   * @param progress
                   */
      @Override public void progress(int progress) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(progress);
          boolean _status = mRemote.transact(Stub.TRANSACTION_progress, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().progress(progress);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      /**
                   *  reset an app fail
                   * @param info
                   */
      @Override public void resetAppFail(java.lang.String packageName, int returnCode) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeInt(returnCode);
          boolean _status = mRemote.transact(Stub.TRANSACTION_resetAppFail, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().resetAppFail(packageName, returnCode);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      /**
                   * reset an app success
                   * @param info
                   */
      @Override public void resetAppSuccess(java.lang.String packageName, int returnCode) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeInt(returnCode);
          boolean _status = mRemote.transact(Stub.TRANSACTION_resetAppSuccess, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().resetAppSuccess(packageName, returnCode);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      /**
                  *  reset an app fail
                  * @param info
                  */
      @Override public void resetAppNoPermission() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_resetAppNoPermission, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().resetAppNoPermission();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      /**
                  *  reset on apps
                  *
                  */
      @Override public void resetNoApps() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_resetNoApps, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().resetNoApps();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener sDefaultImpl;
    }
    static final int TRANSACTION_progress = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_resetAppFail = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_resetAppSuccess = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_resetAppNoPermission = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_resetNoApps = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  /**
               * uninstall apps progress
               * @param progress
               */
  public void progress(int progress) throws android.os.RemoteException;
  /**
               *  reset an app fail
               * @param info
               */
  public void resetAppFail(java.lang.String packageName, int returnCode) throws android.os.RemoteException;
  /**
               * reset an app success
               * @param info
               */
  public void resetAppSuccess(java.lang.String packageName, int returnCode) throws android.os.RemoteException;
  /**
              *  reset an app fail
              * @param info
              */
  public void resetAppNoPermission() throws android.os.RemoteException;
  /**
              *  reset on apps
              *
              */
  public void resetNoApps() throws android.os.RemoteException;
}
