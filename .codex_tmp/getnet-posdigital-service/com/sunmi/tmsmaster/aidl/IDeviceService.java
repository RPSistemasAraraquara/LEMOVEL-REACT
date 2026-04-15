/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl;
public interface IDeviceService extends android.os.IInterface
{
  /** Default implementation for IDeviceService. */
  public static class Default implements com.sunmi.tmsmaster.aidl.IDeviceService
  {
    @Override public com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo getDeviceInfoBinder() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager getDeviceManagerBinder() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager getSoftwareManagerBinder() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager getSystemManagerBinder() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager getSystemUIManagerBinder() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager getKioskManagerBinder() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo getDeviceRunningInfoBinder() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager getCertificateManagerBinder() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager getNetworkManagerBinder() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.pm.IPackageCTPA getAllPackageInfo() throws android.os.RemoteException
    {
      return null;
    }
    @Override public com.sunmi.tmsmaster.aidl.pm.IServicePreference getPreference() throws android.os.RemoteException
    {
      return null;
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.IDeviceService
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.IDeviceService";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.IDeviceService interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.IDeviceService asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.IDeviceService))) {
        return ((com.sunmi.tmsmaster.aidl.IDeviceService)iin);
      }
      return new com.sunmi.tmsmaster.aidl.IDeviceService.Stub.Proxy(obj);
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
        case TRANSACTION_getDeviceInfoBinder:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo _result = this.getDeviceInfoBinder();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getDeviceManagerBinder:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager _result = this.getDeviceManagerBinder();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getSoftwareManagerBinder:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager _result = this.getSoftwareManagerBinder();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getSystemManagerBinder:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager _result = this.getSystemManagerBinder();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getSystemUIManagerBinder:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager _result = this.getSystemUIManagerBinder();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getKioskManagerBinder:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager _result = this.getKioskManagerBinder();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getDeviceRunningInfoBinder:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo _result = this.getDeviceRunningInfoBinder();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getCertificateManagerBinder:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager _result = this.getCertificateManagerBinder();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getNetworkManagerBinder:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager _result = this.getNetworkManagerBinder();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getAllPackageInfo:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.pm.IPackageCTPA _result = this.getAllPackageInfo();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        case TRANSACTION_getPreference:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.pm.IServicePreference _result = this.getPreference();
          reply.writeNoException();
          reply.writeStrongBinder((((_result!=null))?(_result.asBinder()):(null)));
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.IDeviceService
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
      @Override public com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo getDeviceInfoBinder() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getDeviceInfoBinder, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getDeviceInfoBinder();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager getDeviceManagerBinder() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getDeviceManagerBinder, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getDeviceManagerBinder();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager getSoftwareManagerBinder() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getSoftwareManagerBinder, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getSoftwareManagerBinder();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager getSystemManagerBinder() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getSystemManagerBinder, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getSystemManagerBinder();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager getSystemUIManagerBinder() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getSystemUIManagerBinder, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getSystemUIManagerBinder();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager getKioskManagerBinder() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getKioskManagerBinder, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getKioskManagerBinder();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo getDeviceRunningInfoBinder() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getDeviceRunningInfoBinder, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getDeviceRunningInfoBinder();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager getCertificateManagerBinder() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getCertificateManagerBinder, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getCertificateManagerBinder();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager getNetworkManagerBinder() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getNetworkManagerBinder, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getNetworkManagerBinder();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.pm.IPackageCTPA getAllPackageInfo() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.pm.IPackageCTPA _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getAllPackageInfo, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getAllPackageInfo();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.pm.IPackageCTPA.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public com.sunmi.tmsmaster.aidl.pm.IServicePreference getPreference() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.sunmi.tmsmaster.aidl.pm.IServicePreference _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getPreference, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getPreference();
          }
          _reply.readException();
          _result = com.sunmi.tmsmaster.aidl.pm.IServicePreference.Stub.asInterface(_reply.readStrongBinder());
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      public static com.sunmi.tmsmaster.aidl.IDeviceService sDefaultImpl;
    }
    static final int TRANSACTION_getDeviceInfoBinder = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_getDeviceManagerBinder = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_getSoftwareManagerBinder = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_getSystemManagerBinder = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_getSystemUIManagerBinder = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_getKioskManagerBinder = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    static final int TRANSACTION_getDeviceRunningInfoBinder = (android.os.IBinder.FIRST_CALL_TRANSACTION + 6);
    static final int TRANSACTION_getCertificateManagerBinder = (android.os.IBinder.FIRST_CALL_TRANSACTION + 7);
    static final int TRANSACTION_getNetworkManagerBinder = (android.os.IBinder.FIRST_CALL_TRANSACTION + 8);
    static final int TRANSACTION_getAllPackageInfo = (android.os.IBinder.FIRST_CALL_TRANSACTION + 9);
    static final int TRANSACTION_getPreference = (android.os.IBinder.FIRST_CALL_TRANSACTION + 10);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.IDeviceService impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.IDeviceService getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  public com.sunmi.tmsmaster.aidl.deviceinfo.IDeviceInfo getDeviceInfoBinder() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager getDeviceManagerBinder() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.softwaremanager.ISoftwareManager getSoftwareManagerBinder() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.systemmanager.ISystemManager getSystemManagerBinder() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.systemuimanager.ISystemUIManager getSystemUIManagerBinder() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.kioskmanager.IKioskManager getKioskManagerBinder() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.devicerunninginfo.IDeviceRunningInfo getDeviceRunningInfoBinder() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager getCertificateManagerBinder() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager getNetworkManagerBinder() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.pm.IPackageCTPA getAllPackageInfo() throws android.os.RemoteException;
  public com.sunmi.tmsmaster.aidl.pm.IServicePreference getPreference() throws android.os.RemoteException;
}
