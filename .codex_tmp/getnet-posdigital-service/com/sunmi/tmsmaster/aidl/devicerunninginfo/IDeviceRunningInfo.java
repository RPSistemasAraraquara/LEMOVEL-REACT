/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.devicerunninginfo;
public interface IDeviceRunningInfo extends android.os.IInterface
{
  /** Default implementation for IDeviceRunningInfo. */
  public static class Default implements com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo
  {
    //get network connection info

    @Override public java.util.Map getConnectionInfo() throws android.os.RemoteException
    {
      return null;
    }
    //get location( if GPS)

    @Override public java.util.Map getGPSLocation() throws android.os.RemoteException
    {
      return null;
    }
    //get device status

    @Override public byte getDeviceStatus() throws android.os.RemoteException
    {
      return 0;
    }
    //get device using data

    @Override public java.util.Map getDeviceUsingData() throws android.os.RemoteException
    {
      return null;
    }
    @Override public java.lang.String getBatteryCapacity() throws android.os.RemoteException
    {
      return null;
    }
    @Override public float getCpuUsage() throws android.os.RemoteException
    {
      return 0.0f;
    }
    //get location( if GPS)

    @Override public void getGPSLocationWithTimeout(com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener listener, long timeout) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo))) {
        return ((com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo)iin);
      }
      return new com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo.Stub.Proxy(obj);
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
        case TRANSACTION_getConnectionInfo:
        {
          data.enforceInterface(descriptor);
          java.util.Map _result = this.getConnectionInfo();
          reply.writeNoException();
          reply.writeMap(_result);
          return true;
        }
        case TRANSACTION_getGPSLocation:
        {
          data.enforceInterface(descriptor);
          java.util.Map _result = this.getGPSLocation();
          reply.writeNoException();
          reply.writeMap(_result);
          return true;
        }
        case TRANSACTION_getDeviceStatus:
        {
          data.enforceInterface(descriptor);
          byte _result = this.getDeviceStatus();
          reply.writeNoException();
          reply.writeByte(_result);
          return true;
        }
        case TRANSACTION_getDeviceUsingData:
        {
          data.enforceInterface(descriptor);
          java.util.Map _result = this.getDeviceUsingData();
          reply.writeNoException();
          reply.writeMap(_result);
          return true;
        }
        case TRANSACTION_getBatteryCapacity:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getBatteryCapacity();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getCpuUsage:
        {
          data.enforceInterface(descriptor);
          float _result = this.getCpuUsage();
          reply.writeNoException();
          reply.writeFloat(_result);
          return true;
        }
        case TRANSACTION_getGPSLocationWithTimeout:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener _arg0;
          _arg0 = com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener.Stub.asInterface(data.readStrongBinder());
          long _arg1;
          _arg1 = data.readLong();
          this.getGPSLocationWithTimeout(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo
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
      //get network connection info

      @Override public java.util.Map getConnectionInfo() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.Map _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getConnectionInfo, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getConnectionInfo();
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
      //get location( if GPS)

      @Override public java.util.Map getGPSLocation() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.Map _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getGPSLocation, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getGPSLocation();
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
      //get device status

      @Override public byte getDeviceStatus() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        byte _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getDeviceStatus, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getDeviceStatus();
          }
          _reply.readException();
          _result = _reply.readByte();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      //get device using data

      @Override public java.util.Map getDeviceUsingData() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.Map _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getDeviceUsingData, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getDeviceUsingData();
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
      @Override public java.lang.String getBatteryCapacity() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getBatteryCapacity, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getBatteryCapacity();
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
      @Override public float getCpuUsage() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        float _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getCpuUsage, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getCpuUsage();
          }
          _reply.readException();
          _result = _reply.readFloat();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      //get location( if GPS)

      @Override public void getGPSLocationWithTimeout(com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener listener, long timeout) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder((((listener!=null))?(listener.asBinder()):(null)));
          _data.writeLong(timeout);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getGPSLocationWithTimeout, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().getGPSLocationWithTimeout(listener, timeout);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo sDefaultImpl;
    }
    static final int TRANSACTION_getConnectionInfo = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_getGPSLocation = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_getDeviceStatus = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_getDeviceUsingData = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_getBatteryCapacity = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_getCpuUsage = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    static final int TRANSACTION_getGPSLocationWithTimeout = (android.os.IBinder.FIRST_CALL_TRANSACTION + 6);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  //get network connection info

  public java.util.Map getConnectionInfo() throws android.os.RemoteException;
  //get location( if GPS)

  public java.util.Map getGPSLocation() throws android.os.RemoteException;
  //get device status

  public byte getDeviceStatus() throws android.os.RemoteException;
  //get device using data

  public java.util.Map getDeviceUsingData() throws android.os.RemoteException;
  public java.lang.String getBatteryCapacity() throws android.os.RemoteException;
  public float getCpuUsage() throws android.os.RemoteException;
  //get location( if GPS)

  public void getGPSLocationWithTimeout(com.sunmi.tmsmaster.aidl.devicerunninginfo.listener.GPSLocationListener listener, long timeout) throws android.os.RemoteException;
}
