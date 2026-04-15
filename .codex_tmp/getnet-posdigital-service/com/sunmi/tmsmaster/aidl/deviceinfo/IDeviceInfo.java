/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.deviceinfo;
public interface IDeviceInfo extends android.os.IInterface
{
  /** Default implementation for IDeviceInfo. */
  public static class Default implements com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo
  {
    //get device serial no

    @Override public java.lang.String getSerialNo() throws android.os.RemoteException
    {
      return null;
    }
    //get device IMSI

    @Override public java.lang.String getIMSI() throws android.os.RemoteException
    {
      return null;
    }
    //get device IMEI

    @Override public java.lang.String getIMEI() throws android.os.RemoteException
    {
      return null;
    }
    //get device ICCID

    @Override public java.lang.String getICCID() throws android.os.RemoteException
    {
      return null;
    }
    //get device vendor

    @Override public java.lang.String getManufacture() throws android.os.RemoteException
    {
      return null;
    }
    //get device model

    @Override public java.lang.String getModel() throws android.os.RemoteException
    {
      return null;
    }
    //get android system version

    @Override public java.lang.String getAndroidOSVersion() throws android.os.RemoteException
    {
      return null;
    }
    // get android kernel version

    @Override public java.lang.String getAndroidKernelVersion() throws android.os.RemoteException
    {
      return null;
    }
    // get rom version

    @Override public java.lang.String getROMVersion() throws android.os.RemoteException
    {
      return null;
    }
    //get firware version

    @Override public java.lang.String getFirmwareVersion() throws android.os.RemoteException
    {
      return null;
    }
    //get hardware version

    @Override public java.lang.String getHardwareVersion() throws android.os.RemoteException
    {
      return null;
    }
    //get android sdk version

    @Override public java.lang.String getSDKVersion() throws android.os.RemoteException
    {
      return null;
    }
    //get system memory occupation

    @Override public long getMemoryOccupation() throws android.os.RemoteException
    {
      return 0L;
    }
    //get device mac

    @Override public java.lang.String getMac() throws android.os.RemoteException
    {
      return null;
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo))) {
        return ((com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo)iin);
      }
      return new com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo.Stub.Proxy(obj);
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
        case TRANSACTION_getSerialNo:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getSerialNo();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getIMSI:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getIMSI();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getIMEI:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getIMEI();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getICCID:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getICCID();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getManufacture:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getManufacture();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getModel:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getModel();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getAndroidOSVersion:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getAndroidOSVersion();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getAndroidKernelVersion:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getAndroidKernelVersion();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getROMVersion:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getROMVersion();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getFirmwareVersion:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getFirmwareVersion();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getHardwareVersion:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getHardwareVersion();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getSDKVersion:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getSDKVersion();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getMemoryOccupation:
        {
          data.enforceInterface(descriptor);
          long _result = this.getMemoryOccupation();
          reply.writeNoException();
          reply.writeLong(_result);
          return true;
        }
        case TRANSACTION_getMac:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getMac();
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
    private static class Proxy implements com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo
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
      //get device serial no

      @Override public java.lang.String getSerialNo() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getSerialNo, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getSerialNo();
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
      //get device IMSI

      @Override public java.lang.String getIMSI() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getIMSI, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getIMSI();
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
      //get device IMEI

      @Override public java.lang.String getIMEI() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getIMEI, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getIMEI();
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
      //get device ICCID

      @Override public java.lang.String getICCID() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getICCID, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getICCID();
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
      //get device vendor

      @Override public java.lang.String getManufacture() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getManufacture, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getManufacture();
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
      //get device model

      @Override public java.lang.String getModel() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getModel, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getModel();
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
      //get android system version

      @Override public java.lang.String getAndroidOSVersion() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getAndroidOSVersion, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getAndroidOSVersion();
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
      // get android kernel version

      @Override public java.lang.String getAndroidKernelVersion() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getAndroidKernelVersion, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getAndroidKernelVersion();
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
      // get rom version

      @Override public java.lang.String getROMVersion() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getROMVersion, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getROMVersion();
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
      //get firware version

      @Override public java.lang.String getFirmwareVersion() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getFirmwareVersion, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getFirmwareVersion();
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
      //get hardware version

      @Override public java.lang.String getHardwareVersion() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getHardwareVersion, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getHardwareVersion();
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
      //get android sdk version

      @Override public java.lang.String getSDKVersion() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getSDKVersion, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getSDKVersion();
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
      //get system memory occupation

      @Override public long getMemoryOccupation() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        long _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getMemoryOccupation, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getMemoryOccupation();
          }
          _reply.readException();
          _result = _reply.readLong();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      //get device mac

      @Override public java.lang.String getMac() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getMac, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getMac();
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
      public static com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo sDefaultImpl;
    }
    static final int TRANSACTION_getSerialNo = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_getIMSI = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_getIMEI = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_getICCID = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_getManufacture = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_getModel = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    static final int TRANSACTION_getAndroidOSVersion = (android.os.IBinder.FIRST_CALL_TRANSACTION + 6);
    static final int TRANSACTION_getAndroidKernelVersion = (android.os.IBinder.FIRST_CALL_TRANSACTION + 7);
    static final int TRANSACTION_getROMVersion = (android.os.IBinder.FIRST_CALL_TRANSACTION + 8);
    static final int TRANSACTION_getFirmwareVersion = (android.os.IBinder.FIRST_CALL_TRANSACTION + 9);
    static final int TRANSACTION_getHardwareVersion = (android.os.IBinder.FIRST_CALL_TRANSACTION + 10);
    static final int TRANSACTION_getSDKVersion = (android.os.IBinder.FIRST_CALL_TRANSACTION + 11);
    static final int TRANSACTION_getMemoryOccupation = (android.os.IBinder.FIRST_CALL_TRANSACTION + 12);
    static final int TRANSACTION_getMac = (android.os.IBinder.FIRST_CALL_TRANSACTION + 13);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  //get device serial no

  public java.lang.String getSerialNo() throws android.os.RemoteException;
  //get device IMSI

  public java.lang.String getIMSI() throws android.os.RemoteException;
  //get device IMEI

  public java.lang.String getIMEI() throws android.os.RemoteException;
  //get device ICCID

  public java.lang.String getICCID() throws android.os.RemoteException;
  //get device vendor

  public java.lang.String getManufacture() throws android.os.RemoteException;
  //get device model

  public java.lang.String getModel() throws android.os.RemoteException;
  //get android system version

  public java.lang.String getAndroidOSVersion() throws android.os.RemoteException;
  // get android kernel version

  public java.lang.String getAndroidKernelVersion() throws android.os.RemoteException;
  // get rom version

  public java.lang.String getROMVersion() throws android.os.RemoteException;
  //get firware version

  public java.lang.String getFirmwareVersion() throws android.os.RemoteException;
  //get hardware version

  public java.lang.String getHardwareVersion() throws android.os.RemoteException;
  //get android sdk version

  public java.lang.String getSDKVersion() throws android.os.RemoteException;
  //get system memory occupation

  public long getMemoryOccupation() throws android.os.RemoteException;
  //get device mac

  public java.lang.String getMac() throws android.os.RemoteException;
}
