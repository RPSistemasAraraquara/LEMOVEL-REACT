/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.kioskmanager;
public interface IKioskManager extends android.os.IInterface
{
  /** Default implementation for IKioskManager. */
  public static class Default implements com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager
  {
    //set kiosk mode for the whole system

    @Override public void enableKioskMode(boolean flag) throws android.os.RemoteException
    {
    }
    //set kiosk accounts

    @Override public void setKioskAccounts(java.lang.String key, java.lang.String password) throws android.os.RemoteException
    {
    }
    //get kiosk accounts

    @Override public java.util.Map getKioskAccounts() throws android.os.RemoteException
    {
      return null;
    }
    //set kiosk mode for some specific apps  (Not yet available)

    @Override public void setKioskMode(java.lang.String packageName, boolean flag) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager))) {
        return ((com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager)iin);
      }
      return new com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager.Stub.Proxy(obj);
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
        case TRANSACTION_enableKioskMode:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableKioskMode(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setKioskAccounts:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          java.lang.String _arg1;
          _arg1 = data.readString();
          this.setKioskAccounts(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_getKioskAccounts:
        {
          data.enforceInterface(descriptor);
          java.util.Map _result = this.getKioskAccounts();
          reply.writeNoException();
          reply.writeMap(_result);
          return true;
        }
        case TRANSACTION_setKioskMode:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _arg1;
          _arg1 = (0!=data.readInt());
          this.setKioskMode(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager
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
      //set kiosk mode for the whole system

      @Override public void enableKioskMode(boolean flag) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((flag)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableKioskMode, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableKioskMode(flag);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //set kiosk accounts

      @Override public void setKioskAccounts(java.lang.String key, java.lang.String password) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(key);
          _data.writeString(password);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setKioskAccounts, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setKioskAccounts(key, password);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //get kiosk accounts

      @Override public java.util.Map getKioskAccounts() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.Map _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getKioskAccounts, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getKioskAccounts();
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
      //set kiosk mode for some specific apps  (Not yet available)

      @Override public void setKioskMode(java.lang.String packageName, boolean flag) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          _data.writeInt(((flag)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_setKioskMode, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setKioskMode(packageName, flag);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager sDefaultImpl;
    }
    static final int TRANSACTION_enableKioskMode = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_setKioskAccounts = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_getKioskAccounts = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_setKioskMode = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  //set kiosk mode for the whole system

  public void enableKioskMode(boolean flag) throws android.os.RemoteException;
  //set kiosk accounts

  public void setKioskAccounts(java.lang.String key, java.lang.String password) throws android.os.RemoteException;
  //get kiosk accounts

  public java.util.Map getKioskAccounts() throws android.os.RemoteException;
  //set kiosk mode for some specific apps  (Not yet available)

  public void setKioskMode(java.lang.String packageName, boolean flag) throws android.os.RemoteException;
}
