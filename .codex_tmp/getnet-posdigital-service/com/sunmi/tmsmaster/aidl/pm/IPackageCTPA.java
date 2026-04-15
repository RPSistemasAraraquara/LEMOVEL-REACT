/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.pm;
// Declare any non-default types here with import statements

public interface IPackageCTPA extends android.os.IInterface
{
  /** Default implementation for IPackageCTPA. */
  public static class Default implements com.sunmi.tmsmaster.aidl.pm.IPackageCTPA
  {
    @Override public java.lang.String getSystemAllPackageInfo() throws android.os.RemoteException
    {
      return null;
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.pm.IPackageCTPA
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.pm.IPackageCTPA";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.pm.IPackageCTPA interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.pm.IPackageCTPA asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.pm.IPackageCTPA))) {
        return ((com.sunmi.tmsmaster.aidl.pm.IPackageCTPA)iin);
      }
      return new com.sunmi.tmsmaster.aidl.pm.IPackageCTPA.Stub.Proxy(obj);
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
        case TRANSACTION_getSystemAllPackageInfo:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getSystemAllPackageInfo();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.pm.IPackageCTPA
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
      @Override public java.lang.String getSystemAllPackageInfo() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getSystemAllPackageInfo, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getSystemAllPackageInfo();
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
      public static com.sunmi.tmsmaster.aidl.pm.IPackageCTPA sDefaultImpl;
    }
    static final int TRANSACTION_getSystemAllPackageInfo = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.pm.IPackageCTPA impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.pm.IPackageCTPA getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  public java.lang.String getSystemAllPackageInfo() throws android.os.RemoteException;
}
