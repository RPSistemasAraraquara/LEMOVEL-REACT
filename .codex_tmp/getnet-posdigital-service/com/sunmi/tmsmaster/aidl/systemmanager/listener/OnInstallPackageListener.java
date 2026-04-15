/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.systemmanager.listener;
public interface OnInstallPackageListener extends android.os.IInterface
{
  /** Default implementation for OnInstallPackageListener. */
  public static class Default implements com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener
  {
    @Override public void fail(java.lang.String info) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener))) {
        return ((com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener)iin);
      }
      return new com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener.Stub.Proxy(obj);
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
    private static class Proxy implements com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener
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
      public static com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener sDefaultImpl;
    }
    static final int TRANSACTION_fail = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.systemmanager.listener.OnInstallPackageListener getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  public void fail(java.lang.String info) throws android.os.RemoteException;
}
