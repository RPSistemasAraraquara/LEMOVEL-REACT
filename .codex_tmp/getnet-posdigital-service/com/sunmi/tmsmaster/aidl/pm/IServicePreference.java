/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.pm;
public interface IServicePreference extends android.os.IInterface
{
  /** Default implementation for IServicePreference. */
  public static class Default implements com.sunmi.tmsmaster.aidl.pm.IServicePreference
  {
    //update res pack

    @Override public int updateResPack(java.lang.String ResPackPath) throws android.os.RemoteException
    {
      return 0;
    }
    //get res ver

    @Override public java.lang.String getResVer() throws android.os.RemoteException
    {
      return null;
    }
    // switch Tms Domain Flag

    @Override public boolean switchTmsDomainFlag(java.lang.String switchFlag) throws android.os.RemoteException
    {
      return false;
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.pm.IServicePreference
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.pm.IServicePreference";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.pm.IServicePreference interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.pm.IServicePreference asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.pm.IServicePreference))) {
        return ((com.sunmi.tmsmaster.aidl.pm.IServicePreference)iin);
      }
      return new com.sunmi.tmsmaster.aidl.pm.IServicePreference.Stub.Proxy(obj);
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
        case TRANSACTION_updateResPack:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          int _result = this.updateResPack(_arg0);
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_getResVer:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getResVer();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_switchTmsDomainFlag:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.switchTmsDomainFlag(_arg0);
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
    private static class Proxy implements com.sunmi.tmsmaster.aidl.pm.IServicePreference
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
      //update res pack

      @Override public int updateResPack(java.lang.String ResPackPath) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(ResPackPath);
          boolean _status = mRemote.transact(Stub.TRANSACTION_updateResPack, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().updateResPack(ResPackPath);
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
      //get res ver

      @Override public java.lang.String getResVer() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getResVer, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getResVer();
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
      // switch Tms Domain Flag

      @Override public boolean switchTmsDomainFlag(java.lang.String switchFlag) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(switchFlag);
          boolean _status = mRemote.transact(Stub.TRANSACTION_switchTmsDomainFlag, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().switchTmsDomainFlag(switchFlag);
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
      public static com.sunmi.tmsmaster.aidl.pm.IServicePreference sDefaultImpl;
    }
    static final int TRANSACTION_updateResPack = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_getResVer = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_switchTmsDomainFlag = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.pm.IServicePreference impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.pm.IServicePreference getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  //update res pack

  public int updateResPack(java.lang.String ResPackPath) throws android.os.RemoteException;
  //get res ver

  public java.lang.String getResVer() throws android.os.RemoteException;
  // switch Tms Domain Flag

  public boolean switchTmsDomainFlag(java.lang.String switchFlag) throws android.os.RemoteException;
}
