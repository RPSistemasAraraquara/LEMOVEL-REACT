/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.softwaremanager;
public interface OnInstallAppListener extends android.os.IInterface
{
  /** Default implementation for OnInstallAppListener. */
  public static class Default implements com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener
  {
    @Override public void onInstallFinished() throws android.os.RemoteException
    {
    }
    @Override public void onInstallError(int errorId) throws android.os.RemoteException
    {
    }
    @Override public void onInstallSuccess(java.lang.String packagename) throws android.os.RemoteException
    {
    }
    @Override public void onInstallFail(java.lang.String packagename, int errorId) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener))) {
        return ((com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener)iin);
      }
      return new com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener.Stub.Proxy(obj);
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
        case TRANSACTION_onInstallFinished:
        {
          data.enforceInterface(descriptor);
          this.onInstallFinished();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_onInstallError:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          this.onInstallError(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_onInstallSuccess:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          this.onInstallSuccess(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_onInstallFail:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          int _arg1;
          _arg1 = data.readInt();
          this.onInstallFail(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener
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
      @Override public void onInstallFinished() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_onInstallFinished, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().onInstallFinished();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void onInstallError(int errorId) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(errorId);
          boolean _status = mRemote.transact(Stub.TRANSACTION_onInstallError, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().onInstallError(errorId);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void onInstallSuccess(java.lang.String packagename) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packagename);
          boolean _status = mRemote.transact(Stub.TRANSACTION_onInstallSuccess, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().onInstallSuccess(packagename);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void onInstallFail(java.lang.String packagename, int errorId) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packagename);
          _data.writeInt(errorId);
          boolean _status = mRemote.transact(Stub.TRANSACTION_onInstallFail, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().onInstallFail(packagename, errorId);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener sDefaultImpl;
    }
    static final int TRANSACTION_onInstallFinished = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_onInstallError = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_onInstallSuccess = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_onInstallFail = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.softwaremanager.OnInstallAppListener getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  public void onInstallFinished() throws android.os.RemoteException;
  public void onInstallError(int errorId) throws android.os.RemoteException;
  public void onInstallSuccess(java.lang.String packagename) throws android.os.RemoteException;
  public void onInstallFail(java.lang.String packagename, int errorId) throws android.os.RemoteException;
}
