/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.devicerunninginfo.listener;
public interface GPSLocationListener extends android.os.IInterface
{
  /** Default implementation for GPSLocationListener. */
  public static class Default implements com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener
  {
    /**
                 * on gps location changed
                 * @param progress
                 */
    @Override public void onGPSLocationChanged(java.util.Map location) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener))) {
        return ((com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener)iin);
      }
      return new com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener.Stub.Proxy(obj);
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
        case TRANSACTION_onGPSLocationChanged:
        {
          data.enforceInterface(descriptor);
          java.util.Map _arg0;
          java.lang.ClassLoader cl = (java.lang.ClassLoader)this.getClass().getClassLoader();
          _arg0 = data.readHashMap(cl);
          this.onGPSLocationChanged(_arg0);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener
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
                   * on gps location changed
                   * @param progress
                   */
      @Override public void onGPSLocationChanged(java.util.Map location) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeMap(location);
          boolean _status = mRemote.transact(Stub.TRANSACTION_onGPSLocationChanged, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().onGPSLocationChanged(location);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener sDefaultImpl;
    }
    static final int TRANSACTION_onGPSLocationChanged = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  /**
               * on gps location changed
               * @param progress
               */
  public void onGPSLocationChanged(java.util.Map location) throws android.os.RemoteException;
}
