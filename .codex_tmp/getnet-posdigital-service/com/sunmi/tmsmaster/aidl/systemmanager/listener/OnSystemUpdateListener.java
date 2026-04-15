/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.systemmanager.listener;
public interface OnSystemUpdateListener extends android.os.IInterface
{
  /** Default implementation for OnSystemUpdateListener. */
  public static class Default implements com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener
  {
    /**
             * verify package progress
             * @param progress
             */
    @Override public void progress(int progress) throws android.os.RemoteException
    {
    }
    /**
             *  verify package fail
             * @param info
             */
    @Override public void verifyPackageFail(java.lang.String info) throws android.os.RemoteException
    {
    }
    /**
             * update system fail
             * @param info
             */
    @Override public void updateSystemFail(java.lang.String info) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener))) {
        return ((com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener)iin);
      }
      return new com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener.Stub.Proxy(obj);
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
        case TRANSACTION_verifyPackageFail:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          this.verifyPackageFail(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_updateSystemFail:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          this.updateSystemFail(_arg0);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener
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
               * verify package progress
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
               *  verify package fail
               * @param info
               */
      @Override public void verifyPackageFail(java.lang.String info) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(info);
          boolean _status = mRemote.transact(Stub.TRANSACTION_verifyPackageFail, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().verifyPackageFail(info);
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
               * update system fail
               * @param info
               */
      @Override public void updateSystemFail(java.lang.String info) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(info);
          boolean _status = mRemote.transact(Stub.TRANSACTION_updateSystemFail, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().updateSystemFail(info);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener sDefaultImpl;
    }
    static final int TRANSACTION_progress = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_verifyPackageFail = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_updateSystemFail = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.systemmanager.listener.OnSystemUpdateListener getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  /**
           * verify package progress
           * @param progress
           */
  public void progress(int progress) throws android.os.RemoteException;
  /**
           *  verify package fail
           * @param info
           */
  public void verifyPackageFail(java.lang.String info) throws android.os.RemoteException;
  /**
           * update system fail
           * @param info
           */
  public void updateSystemFail(java.lang.String info) throws android.os.RemoteException;
}
