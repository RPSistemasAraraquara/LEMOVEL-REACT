/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.systemmanager.listener;
public interface OnVerifyPackageListener extends android.os.IInterface
{
  /** Default implementation for OnVerifyPackageListener. */
  public static class Default implements com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener
  {
    @Override public void progress(int progress) throws android.os.RemoteException
    {
    }
    @Override public void fail(java.lang.String info) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener))) {
        return ((com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener)iin);
      }
      return new com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener.Stub.Proxy(obj);
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
        case TRANSACTION_fail:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          this.fail(_arg0);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener
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
      @Override public void fail(java.lang.String info) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(info);
          boolean _status = mRemote.transact(Stub.TRANSACTION_fail, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().fail(info);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener sDefaultImpl;
    }
    static final int TRANSACTION_progress = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_fail = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.systemmanager.listener.OnVerifyPackageListener getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  public void progress(int progress) throws android.os.RemoteException;
  public void fail(java.lang.String info) throws android.os.RemoteException;
}
