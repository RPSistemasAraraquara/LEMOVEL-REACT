/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.softwaremanager;
public interface OnUninstallAppListener extends android.os.IInterface
{
  /** Default implementation for OnUninstallAppListener. */
  public static class Default implements com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener
  {
    @Override public void onUnInstallFinished() throws android.os.RemoteException
    {
    }
    @Override public void onUnInstallError(int errorId) throws android.os.RemoteException
    {
    }
    @Override public void onUnInstallSuccess(java.lang.String packagename) throws android.os.RemoteException
    {
    }
    @Override public void onUnInstallFail(java.lang.String packagename, int errorId) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener))) {
        return ((com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener)iin);
      }
      return new com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener.Stub.Proxy(obj);
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
        case TRANSACTION_onUnInstallFinished:
        {
          data.enforceInterface(descriptor);
          this.onUnInstallFinished();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_onUnInstallError:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          this.onUnInstallError(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_onUnInstallSuccess:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          this.onUnInstallSuccess(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_onUnInstallFail:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          int _arg1;
          _arg1 = data.readInt();
          this.onUnInstallFail(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener
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
      @Override public void onUnInstallFinished() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_onUnInstallFinished, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().onUnInstallFinished();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void onUnInstallError(int errorId) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(errorId);
          boolean _status = mRemote.transact(Stub.TRANSACTION_onUnInstallError, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().onUnInstallError(errorId);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void onUnInstallSuccess(java.lang.String packagename) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packagename);
          boolean _status = mRemote.transact(Stub.TRANSACTION_onUnInstallSuccess, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().onUnInstallSuccess(packagename);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void onUnInstallFail(java.lang.String packagename, int errorId) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packagename);
          _data.writeInt(errorId);
          boolean _status = mRemote.transact(Stub.TRANSACTION_onUnInstallFail, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().onUnInstallFail(packagename, errorId);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener sDefaultImpl;
    }
    static final int TRANSACTION_onUnInstallFinished = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_onUnInstallError = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_onUnInstallSuccess = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_onUnInstallFail = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.softwaremanager.OnUninstallAppListener getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  public void onUnInstallFinished() throws android.os.RemoteException;
  public void onUnInstallError(int errorId) throws android.os.RemoteException;
  public void onUnInstallSuccess(java.lang.String packagename) throws android.os.RemoteException;
  public void onUnInstallFail(java.lang.String packagename, int errorId) throws android.os.RemoteException;
}
