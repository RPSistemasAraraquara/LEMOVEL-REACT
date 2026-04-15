/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.certificatemanager;
public interface ICertificateManager extends android.os.IInterface
{
  /** Default implementation for ICertificateManager. */
  public static class Default implements com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager
  {
    @Override public int updateCertificate(java.lang.String certPath) throws android.os.RemoteException
    {
      return 0;
    }
    @Override public java.lang.String getCertificateInfo() throws android.os.RemoteException
    {
      return null;
    }
    @Override public java.lang.String getTrustedFileCertChain() throws android.os.RemoteException
    {
      return null;
    }
    // Install CA ,permission same as 'system CA'

    @Override public boolean installSystemCA(java.lang.String path) throws android.os.RemoteException
    {
      return false;
    }
    // Uninstall CA ,permission same as 'system CA'

    @Override public boolean uninstallSystemCA() throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean uninstallSystemCAbyPath(java.lang.String path) throws android.os.RemoteException
    {
      return false;
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager))) {
        return ((com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager)iin);
      }
      return new com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager.Stub.Proxy(obj);
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
        case TRANSACTION_updateCertificate:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          int _result = this.updateCertificate(_arg0);
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_getCertificateInfo:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getCertificateInfo();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getTrustedFileCertChain:
        {
          data.enforceInterface(descriptor);
          java.lang.String _result = this.getTrustedFileCertChain();
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_installSystemCA:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.installSystemCA(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_uninstallSystemCA:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.uninstallSystemCA();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_uninstallSystemCAbyPath:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.uninstallSystemCAbyPath(_arg0);
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
    private static class Proxy implements com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager
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
      @Override public int updateCertificate(java.lang.String certPath) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(certPath);
          boolean _status = mRemote.transact(Stub.TRANSACTION_updateCertificate, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().updateCertificate(certPath);
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
      @Override public java.lang.String getCertificateInfo() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getCertificateInfo, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getCertificateInfo();
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
      @Override public java.lang.String getTrustedFileCertChain() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getTrustedFileCertChain, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getTrustedFileCertChain();
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
      // Install CA ,permission same as 'system CA'

      @Override public boolean installSystemCA(java.lang.String path) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(path);
          boolean _status = mRemote.transact(Stub.TRANSACTION_installSystemCA, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().installSystemCA(path);
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
      // Uninstall CA ,permission same as 'system CA'

      @Override public boolean uninstallSystemCA() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_uninstallSystemCA, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().uninstallSystemCA();
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
      @Override public boolean uninstallSystemCAbyPath(java.lang.String path) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(path);
          boolean _status = mRemote.transact(Stub.TRANSACTION_uninstallSystemCAbyPath, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().uninstallSystemCAbyPath(path);
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
      public static com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager sDefaultImpl;
    }
    static final int TRANSACTION_updateCertificate = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_getCertificateInfo = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_getTrustedFileCertChain = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_installSystemCA = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_uninstallSystemCA = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_uninstallSystemCAbyPath = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.certificatemanager.ICertificateManager getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  public int updateCertificate(java.lang.String certPath) throws android.os.RemoteException;
  public java.lang.String getCertificateInfo() throws android.os.RemoteException;
  public java.lang.String getTrustedFileCertChain() throws android.os.RemoteException;
  // Install CA ,permission same as 'system CA'

  public boolean installSystemCA(java.lang.String path) throws android.os.RemoteException;
  // Uninstall CA ,permission same as 'system CA'

  public boolean uninstallSystemCA() throws android.os.RemoteException;
  public boolean uninstallSystemCAbyPath(java.lang.String path) throws android.os.RemoteException;
}
