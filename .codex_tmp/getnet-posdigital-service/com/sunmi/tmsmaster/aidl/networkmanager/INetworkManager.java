/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.networkmanager;
// Declare any non-default types here with import statements

public interface INetworkManager extends android.os.IInterface
{
  /** Default implementation for INetworkManager. */
  public static class Default implements com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager
  {
    //slotIdx : slot index
    //enable : enable == true, turn on ; enable == false, turn off

    @Override public void enableMobileNetwork(int slotIdx, boolean enable) throws android.os.RemoteException
    {
    }
    //apnInfo format name,apn for example SUNMI,cmnet

    @Override public boolean checkAPN(java.lang.String apnInfo) throws android.os.RemoteException
    {
      return false;
    }
    //

    @Override public boolean setAPN(int apnId) throws android.os.RemoteException
    {
      return false;
    }
    //

    @Override public boolean addAPN(com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo configInfo) throws android.os.RemoteException
    {
      return false;
    }
    //get apn list info

    @Override public java.lang.String getAPNList(java.lang.String[] projection, java.lang.String selection, java.lang.String[] selectionArgs, java.lang.String sortOrder) throws android.os.RemoteException
    {
      return null;
    }
    //get current apn info

    @Override public java.lang.String getCurrentAPN(int slotIdx) throws android.os.RemoteException
    {
      return null;
    }
    // get apn list info

    @Override public java.util.List<com.sunmi.tmsmaster.aidl.networkmanager.ApnModel> getApnList() throws android.os.RemoteException
    {
      return null;
    }
    // Forget all connected WiFi networks

    @Override public void forgetSavedWifi() throws android.os.RemoteException
    {
    }
    // Get the number of active SIM cards

    @Override public int getActiveSimCardCount() throws android.os.RemoteException
    {
      return 0;
    }
    // V2 version of the interface for getting the current APN list

    @Override public java.lang.String getApnList_V2(int slotIdx) throws android.os.RemoteException
    {
      return null;
    }
    // Get total data traffic

    @Override public long getTrafficTotal(int networkType, long startTime, long endTime) throws android.os.RemoteException
    {
      return 0L;
    }
    // Get data traffic of each app

    @Override public java.util.Map getTrafficOfEachApp(int networkType, long startTime, long endTime) throws android.os.RemoteException
    {
      return null;
    }
    // Get current network slots

    @Override public int getCurrentNetworkSlot() throws android.os.RemoteException
    {
      return 0;
    }
    // Turn on/off hotspot

    @Override public boolean switchPortableHotspot(boolean enable) throws android.os.RemoteException
    {
      return false;
    }
    // Add a system forbidden access IP

    @Override public boolean deny(java.lang.String ip) throws android.os.RemoteException
    {
      return false;
    }
    // Delete a system forbidden access IP

    @Override public boolean clearDenial(java.lang.String ip) throws android.os.RemoteException
    {
      return false;
    }
    // Delete all system forbidden access IPs

    @Override public boolean clearAllDenial() throws android.os.RemoteException
    {
      return false;
    }
    // Get all forbidden access IPs

    @Override public java.util.List<java.lang.String> getDenialList() throws android.os.RemoteException
    {
      return null;
    }
    // Add to network access to white list

    @Override public boolean addToWhiteList(java.lang.String ip) throws android.os.RemoteException
    {
      return false;
    }
    // Remove from network access white list

    @Override public boolean removeFromWhiteList(java.lang.String ip) throws android.os.RemoteException
    {
      return false;
    }
    // Get network access white list

    @Override public java.util.List<java.lang.String> getWhiteList() throws android.os.RemoteException
    {
      return null;
    }
    // Clear DNS cache

    @Override public boolean clearDnsCache() throws android.os.RemoteException
    {
      return false;
    }
    // Set data warning policy (value The value to be set of data warning (MB))

    @Override public boolean setDataWarningPolicy(java.lang.String value) throws android.os.RemoteException
    {
      return false;
    }
    // Reset network settings. Including: Wi-Fi, mobile data, Bluetooth.

    @Override public void resetNetworkSettings() throws android.os.RemoteException
    {
    }
    @Override public boolean removeAPN(java.lang.String apnName) throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean updateAPN(com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo configInfo) throws android.os.RemoteException
    {
      return false;
    }
    @Override public void setDnsWhiteName(java.lang.String dnsServerName) throws android.os.RemoteException
    {
    }
    @Override public void clearDnsWhiteNameList() throws android.os.RemoteException
    {
    }
    @Override public void setDnsWhiteNameEnable(boolean enable) throws android.os.RemoteException
    {
    }
    @Override public boolean installWlanCertificate(java.lang.String name, byte[] certData, java.lang.String password) throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean enableWifi(boolean enable) throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean setAppRestrictMobile(boolean restrict, java.lang.String packageName) throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean setAppRestrictWlan(boolean restrict, java.lang.String packageName) throws android.os.RemoteException
    {
      return false;
    }
    @Override public java.util.List<java.lang.String> getAppRestrictMobile() throws android.os.RemoteException
    {
      return null;
    }
    @Override public java.util.List<java.lang.String> getAppRestrictWlan() throws android.os.RemoteException
    {
      return null;
    }
    @Override public int getPackageRestrictStatus(java.lang.String packageName) throws android.os.RemoteException
    {
      return 0;
    }
    @Override public void addWifiSsid(java.lang.String ssid, java.lang.String password, int type, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callBack) throws android.os.RemoteException
    {
    }
    @Override public void connectWifiSsid(java.lang.String ssid, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callBack) throws android.os.RemoteException
    {
    }
    @Override public void removeWifiSsid(java.lang.String ssid, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callBack) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager))) {
        return ((com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager)iin);
      }
      return new com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager.Stub.Proxy(obj);
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
        case TRANSACTION_enableMobileNetwork:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          boolean _arg1;
          _arg1 = (0!=data.readInt());
          this.enableMobileNetwork(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_checkAPN:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.checkAPN(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setAPN:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          boolean _result = this.setAPN(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_addAPN:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo _arg0;
          if ((0!=data.readInt())) {
            _arg0 = com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo.CREATOR.createFromParcel(data);
          }
          else {
            _arg0 = null;
          }
          boolean _result = this.addAPN(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_getAPNList:
        {
          data.enforceInterface(descriptor);
          java.lang.String[] _arg0;
          _arg0 = data.createStringArray();
          java.lang.String _arg1;
          _arg1 = data.readString();
          java.lang.String[] _arg2;
          _arg2 = data.createStringArray();
          java.lang.String _arg3;
          _arg3 = data.readString();
          java.lang.String _result = this.getAPNList(_arg0, _arg1, _arg2, _arg3);
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getCurrentAPN:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          java.lang.String _result = this.getCurrentAPN(_arg0);
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getApnList:
        {
          data.enforceInterface(descriptor);
          java.util.List<com.sunmi.tmsmaster.aidl.networkmanager.ApnModel> _result = this.getApnList();
          reply.writeNoException();
          reply.writeTypedList(_result);
          return true;
        }
        case TRANSACTION_forgetSavedWifi:
        {
          data.enforceInterface(descriptor);
          this.forgetSavedWifi();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_getActiveSimCardCount:
        {
          data.enforceInterface(descriptor);
          int _result = this.getActiveSimCardCount();
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_getApnList_V2:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          java.lang.String _result = this.getApnList_V2(_arg0);
          reply.writeNoException();
          reply.writeString(_result);
          return true;
        }
        case TRANSACTION_getTrafficTotal:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          long _arg1;
          _arg1 = data.readLong();
          long _arg2;
          _arg2 = data.readLong();
          long _result = this.getTrafficTotal(_arg0, _arg1, _arg2);
          reply.writeNoException();
          reply.writeLong(_result);
          return true;
        }
        case TRANSACTION_getTrafficOfEachApp:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          long _arg1;
          _arg1 = data.readLong();
          long _arg2;
          _arg2 = data.readLong();
          java.util.Map _result = this.getTrafficOfEachApp(_arg0, _arg1, _arg2);
          reply.writeNoException();
          reply.writeMap(_result);
          return true;
        }
        case TRANSACTION_getCurrentNetworkSlot:
        {
          data.enforceInterface(descriptor);
          int _result = this.getCurrentNetworkSlot();
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_switchPortableHotspot:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          boolean _result = this.switchPortableHotspot(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_deny:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.deny(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_clearDenial:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.clearDenial(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_clearAllDenial:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.clearAllDenial();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_getDenialList:
        {
          data.enforceInterface(descriptor);
          java.util.List<java.lang.String> _result = this.getDenialList();
          reply.writeNoException();
          reply.writeStringList(_result);
          return true;
        }
        case TRANSACTION_addToWhiteList:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.addToWhiteList(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_removeFromWhiteList:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.removeFromWhiteList(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_getWhiteList:
        {
          data.enforceInterface(descriptor);
          java.util.List<java.lang.String> _result = this.getWhiteList();
          reply.writeNoException();
          reply.writeStringList(_result);
          return true;
        }
        case TRANSACTION_clearDnsCache:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.clearDnsCache();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setDataWarningPolicy:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.setDataWarningPolicy(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_resetNetworkSettings:
        {
          data.enforceInterface(descriptor);
          this.resetNetworkSettings();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_removeAPN:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.removeAPN(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_updateAPN:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo _arg0;
          if ((0!=data.readInt())) {
            _arg0 = com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo.CREATOR.createFromParcel(data);
          }
          else {
            _arg0 = null;
          }
          boolean _result = this.updateAPN(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setDnsWhiteName:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          this.setDnsWhiteName(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_clearDnsWhiteNameList:
        {
          data.enforceInterface(descriptor);
          this.clearDnsWhiteNameList();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setDnsWhiteNameEnable:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.setDnsWhiteNameEnable(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_installWlanCertificate:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          byte[] _arg1;
          _arg1 = data.createByteArray();
          java.lang.String _arg2;
          _arg2 = data.readString();
          boolean _result = this.installWlanCertificate(_arg0, _arg1, _arg2);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_enableWifi:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          boolean _result = this.enableWifi(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setAppRestrictMobile:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          java.lang.String _arg1;
          _arg1 = data.readString();
          boolean _result = this.setAppRestrictMobile(_arg0, _arg1);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setAppRestrictWlan:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          java.lang.String _arg1;
          _arg1 = data.readString();
          boolean _result = this.setAppRestrictWlan(_arg0, _arg1);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_getAppRestrictMobile:
        {
          data.enforceInterface(descriptor);
          java.util.List<java.lang.String> _result = this.getAppRestrictMobile();
          reply.writeNoException();
          reply.writeStringList(_result);
          return true;
        }
        case TRANSACTION_getAppRestrictWlan:
        {
          data.enforceInterface(descriptor);
          java.util.List<java.lang.String> _result = this.getAppRestrictWlan();
          reply.writeNoException();
          reply.writeStringList(_result);
          return true;
        }
        case TRANSACTION_getPackageRestrictStatus:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          int _result = this.getPackageRestrictStatus(_arg0);
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_addWifiSsid:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          java.lang.String _arg1;
          _arg1 = data.readString();
          int _arg2;
          _arg2 = data.readInt();
          com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback _arg3;
          _arg3 = com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback.Stub.asInterface(data.readStrongBinder());
          this.addWifiSsid(_arg0, _arg1, _arg2, _arg3);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_connectWifiSsid:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback _arg1;
          _arg1 = com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback.Stub.asInterface(data.readStrongBinder());
          this.connectWifiSsid(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_removeWifiSsid:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback _arg1;
          _arg1 = com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback.Stub.asInterface(data.readStrongBinder());
          this.removeWifiSsid(_arg0, _arg1);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager
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
      //slotIdx : slot index
      //enable : enable == true, turn on ; enable == false, turn off

      @Override public void enableMobileNetwork(int slotIdx, boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(slotIdx);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableMobileNetwork, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableMobileNetwork(slotIdx, enable);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //apnInfo format name,apn for example SUNMI,cmnet

      @Override public boolean checkAPN(java.lang.String apnInfo) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(apnInfo);
          boolean _status = mRemote.transact(Stub.TRANSACTION_checkAPN, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().checkAPN(apnInfo);
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
      //

      @Override public boolean setAPN(int apnId) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(apnId);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setAPN, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setAPN(apnId);
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
      //

      @Override public boolean addAPN(com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo configInfo) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          if ((configInfo!=null)) {
            _data.writeInt(1);
            configInfo.writeToParcel(_data, 0);
          }
          else {
            _data.writeInt(0);
          }
          boolean _status = mRemote.transact(Stub.TRANSACTION_addAPN, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().addAPN(configInfo);
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
      //get apn list info

      @Override public java.lang.String getAPNList(java.lang.String[] projection, java.lang.String selection, java.lang.String[] selectionArgs, java.lang.String sortOrder) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStringArray(projection);
          _data.writeString(selection);
          _data.writeStringArray(selectionArgs);
          _data.writeString(sortOrder);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getAPNList, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getAPNList(projection, selection, selectionArgs, sortOrder);
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
      //get current apn info

      @Override public java.lang.String getCurrentAPN(int slotIdx) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(slotIdx);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getCurrentAPN, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getCurrentAPN(slotIdx);
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
      // get apn list info

      @Override public java.util.List<com.sunmi.tmsmaster.aidl.networkmanager.ApnModel> getApnList() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.List<com.sunmi.tmsmaster.aidl.networkmanager.ApnModel> _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getApnList, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getApnList();
          }
          _reply.readException();
          _result = _reply.createTypedArrayList(com.sunmi.tmsmaster.aidl.networkmanager.ApnModel.CREATOR);
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // Forget all connected WiFi networks

      @Override public void forgetSavedWifi() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_forgetSavedWifi, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().forgetSavedWifi();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Get the number of active SIM cards

      @Override public int getActiveSimCardCount() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getActiveSimCardCount, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getActiveSimCardCount();
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
      // V2 version of the interface for getting the current APN list

      @Override public java.lang.String getApnList_V2(int slotIdx) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.lang.String _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(slotIdx);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getApnList_V2, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getApnList_V2(slotIdx);
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
      // Get total data traffic

      @Override public long getTrafficTotal(int networkType, long startTime, long endTime) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        long _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(networkType);
          _data.writeLong(startTime);
          _data.writeLong(endTime);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getTrafficTotal, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getTrafficTotal(networkType, startTime, endTime);
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
      // Get data traffic of each app

      @Override public java.util.Map getTrafficOfEachApp(int networkType, long startTime, long endTime) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.Map _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(networkType);
          _data.writeLong(startTime);
          _data.writeLong(endTime);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getTrafficOfEachApp, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getTrafficOfEachApp(networkType, startTime, endTime);
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
      // Get current network slots

      @Override public int getCurrentNetworkSlot() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getCurrentNetworkSlot, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getCurrentNetworkSlot();
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
      // Turn on/off hotspot

      @Override public boolean switchPortableHotspot(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_switchPortableHotspot, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().switchPortableHotspot(enable);
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
      // Add a system forbidden access IP

      @Override public boolean deny(java.lang.String ip) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(ip);
          boolean _status = mRemote.transact(Stub.TRANSACTION_deny, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().deny(ip);
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
      // Delete a system forbidden access IP

      @Override public boolean clearDenial(java.lang.String ip) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(ip);
          boolean _status = mRemote.transact(Stub.TRANSACTION_clearDenial, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().clearDenial(ip);
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
      // Delete all system forbidden access IPs

      @Override public boolean clearAllDenial() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_clearAllDenial, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().clearAllDenial();
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
      // Get all forbidden access IPs

      @Override public java.util.List<java.lang.String> getDenialList() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.List<java.lang.String> _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getDenialList, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getDenialList();
          }
          _reply.readException();
          _result = _reply.createStringArrayList();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // Add to network access to white list

      @Override public boolean addToWhiteList(java.lang.String ip) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(ip);
          boolean _status = mRemote.transact(Stub.TRANSACTION_addToWhiteList, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().addToWhiteList(ip);
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
      // Remove from network access white list

      @Override public boolean removeFromWhiteList(java.lang.String ip) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(ip);
          boolean _status = mRemote.transact(Stub.TRANSACTION_removeFromWhiteList, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().removeFromWhiteList(ip);
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
      // Get network access white list

      @Override public java.util.List<java.lang.String> getWhiteList() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.List<java.lang.String> _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getWhiteList, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getWhiteList();
          }
          _reply.readException();
          _result = _reply.createStringArrayList();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // Clear DNS cache

      @Override public boolean clearDnsCache() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_clearDnsCache, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().clearDnsCache();
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
      // Set data warning policy (value The value to be set of data warning (MB))

      @Override public boolean setDataWarningPolicy(java.lang.String value) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(value);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setDataWarningPolicy, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setDataWarningPolicy(value);
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
      // Reset network settings. Including: Wi-Fi, mobile data, Bluetooth.

      @Override public void resetNetworkSettings() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_resetNetworkSettings, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().resetNetworkSettings();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public boolean removeAPN(java.lang.String apnName) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(apnName);
          boolean _status = mRemote.transact(Stub.TRANSACTION_removeAPN, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().removeAPN(apnName);
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
      @Override public boolean updateAPN(com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo configInfo) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          if ((configInfo!=null)) {
            _data.writeInt(1);
            configInfo.writeToParcel(_data, 0);
          }
          else {
            _data.writeInt(0);
          }
          boolean _status = mRemote.transact(Stub.TRANSACTION_updateAPN, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().updateAPN(configInfo);
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
      @Override public void setDnsWhiteName(java.lang.String dnsServerName) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(dnsServerName);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setDnsWhiteName, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setDnsWhiteName(dnsServerName);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void clearDnsWhiteNameList() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_clearDnsWhiteNameList, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().clearDnsWhiteNameList();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void setDnsWhiteNameEnable(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_setDnsWhiteNameEnable, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setDnsWhiteNameEnable(enable);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public boolean installWlanCertificate(java.lang.String name, byte[] certData, java.lang.String password) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(name);
          _data.writeByteArray(certData);
          _data.writeString(password);
          boolean _status = mRemote.transact(Stub.TRANSACTION_installWlanCertificate, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().installWlanCertificate(name, certData, password);
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
      @Override public boolean enableWifi(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableWifi, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().enableWifi(enable);
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
      @Override public boolean setAppRestrictMobile(boolean restrict, java.lang.String packageName) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((restrict)?(1):(0)));
          _data.writeString(packageName);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setAppRestrictMobile, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setAppRestrictMobile(restrict, packageName);
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
      @Override public boolean setAppRestrictWlan(boolean restrict, java.lang.String packageName) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((restrict)?(1):(0)));
          _data.writeString(packageName);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setAppRestrictWlan, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setAppRestrictWlan(restrict, packageName);
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
      @Override public java.util.List<java.lang.String> getAppRestrictMobile() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.List<java.lang.String> _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getAppRestrictMobile, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getAppRestrictMobile();
          }
          _reply.readException();
          _result = _reply.createStringArrayList();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public java.util.List<java.lang.String> getAppRestrictWlan() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        java.util.List<java.lang.String> _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getAppRestrictWlan, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getAppRestrictWlan();
          }
          _reply.readException();
          _result = _reply.createStringArrayList();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public int getPackageRestrictStatus(java.lang.String packageName) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packageName);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getPackageRestrictStatus, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getPackageRestrictStatus(packageName);
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
      @Override public void addWifiSsid(java.lang.String ssid, java.lang.String password, int type, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callBack) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(ssid);
          _data.writeString(password);
          _data.writeInt(type);
          _data.writeStrongBinder((((callBack!=null))?(callBack.asBinder()):(null)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_addWifiSsid, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().addWifiSsid(ssid, password, type, callBack);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void connectWifiSsid(java.lang.String ssid, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callBack) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(ssid);
          _data.writeStrongBinder((((callBack!=null))?(callBack.asBinder()):(null)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_connectWifiSsid, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().connectWifiSsid(ssid, callBack);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void removeWifiSsid(java.lang.String ssid, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callBack) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(ssid);
          _data.writeStrongBinder((((callBack!=null))?(callBack.asBinder()):(null)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_removeWifiSsid, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().removeWifiSsid(ssid, callBack);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager sDefaultImpl;
    }
    static final int TRANSACTION_enableMobileNetwork = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_checkAPN = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_setAPN = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_addAPN = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_getAPNList = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_getCurrentAPN = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    static final int TRANSACTION_getApnList = (android.os.IBinder.FIRST_CALL_TRANSACTION + 6);
    static final int TRANSACTION_forgetSavedWifi = (android.os.IBinder.FIRST_CALL_TRANSACTION + 7);
    static final int TRANSACTION_getActiveSimCardCount = (android.os.IBinder.FIRST_CALL_TRANSACTION + 8);
    static final int TRANSACTION_getApnList_V2 = (android.os.IBinder.FIRST_CALL_TRANSACTION + 9);
    static final int TRANSACTION_getTrafficTotal = (android.os.IBinder.FIRST_CALL_TRANSACTION + 10);
    static final int TRANSACTION_getTrafficOfEachApp = (android.os.IBinder.FIRST_CALL_TRANSACTION + 11);
    static final int TRANSACTION_getCurrentNetworkSlot = (android.os.IBinder.FIRST_CALL_TRANSACTION + 12);
    static final int TRANSACTION_switchPortableHotspot = (android.os.IBinder.FIRST_CALL_TRANSACTION + 13);
    static final int TRANSACTION_deny = (android.os.IBinder.FIRST_CALL_TRANSACTION + 14);
    static final int TRANSACTION_clearDenial = (android.os.IBinder.FIRST_CALL_TRANSACTION + 15);
    static final int TRANSACTION_clearAllDenial = (android.os.IBinder.FIRST_CALL_TRANSACTION + 16);
    static final int TRANSACTION_getDenialList = (android.os.IBinder.FIRST_CALL_TRANSACTION + 17);
    static final int TRANSACTION_addToWhiteList = (android.os.IBinder.FIRST_CALL_TRANSACTION + 18);
    static final int TRANSACTION_removeFromWhiteList = (android.os.IBinder.FIRST_CALL_TRANSACTION + 19);
    static final int TRANSACTION_getWhiteList = (android.os.IBinder.FIRST_CALL_TRANSACTION + 20);
    static final int TRANSACTION_clearDnsCache = (android.os.IBinder.FIRST_CALL_TRANSACTION + 21);
    static final int TRANSACTION_setDataWarningPolicy = (android.os.IBinder.FIRST_CALL_TRANSACTION + 22);
    static final int TRANSACTION_resetNetworkSettings = (android.os.IBinder.FIRST_CALL_TRANSACTION + 23);
    static final int TRANSACTION_removeAPN = (android.os.IBinder.FIRST_CALL_TRANSACTION + 24);
    static final int TRANSACTION_updateAPN = (android.os.IBinder.FIRST_CALL_TRANSACTION + 25);
    static final int TRANSACTION_setDnsWhiteName = (android.os.IBinder.FIRST_CALL_TRANSACTION + 26);
    static final int TRANSACTION_clearDnsWhiteNameList = (android.os.IBinder.FIRST_CALL_TRANSACTION + 27);
    static final int TRANSACTION_setDnsWhiteNameEnable = (android.os.IBinder.FIRST_CALL_TRANSACTION + 28);
    static final int TRANSACTION_installWlanCertificate = (android.os.IBinder.FIRST_CALL_TRANSACTION + 29);
    static final int TRANSACTION_enableWifi = (android.os.IBinder.FIRST_CALL_TRANSACTION + 30);
    static final int TRANSACTION_setAppRestrictMobile = (android.os.IBinder.FIRST_CALL_TRANSACTION + 31);
    static final int TRANSACTION_setAppRestrictWlan = (android.os.IBinder.FIRST_CALL_TRANSACTION + 32);
    static final int TRANSACTION_getAppRestrictMobile = (android.os.IBinder.FIRST_CALL_TRANSACTION + 33);
    static final int TRANSACTION_getAppRestrictWlan = (android.os.IBinder.FIRST_CALL_TRANSACTION + 34);
    static final int TRANSACTION_getPackageRestrictStatus = (android.os.IBinder.FIRST_CALL_TRANSACTION + 35);
    static final int TRANSACTION_addWifiSsid = (android.os.IBinder.FIRST_CALL_TRANSACTION + 36);
    static final int TRANSACTION_connectWifiSsid = (android.os.IBinder.FIRST_CALL_TRANSACTION + 37);
    static final int TRANSACTION_removeWifiSsid = (android.os.IBinder.FIRST_CALL_TRANSACTION + 38);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.networkmanager.INetworkManager getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  //slotIdx : slot index
  //enable : enable == true, turn on ; enable == false, turn off

  public void enableMobileNetwork(int slotIdx, boolean enable) throws android.os.RemoteException;
  //apnInfo format name,apn for example SUNMI,cmnet

  public boolean checkAPN(java.lang.String apnInfo) throws android.os.RemoteException;
  //

  public boolean setAPN(int apnId) throws android.os.RemoteException;
  //

  public boolean addAPN(com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo configInfo) throws android.os.RemoteException;
  //get apn list info

  public java.lang.String getAPNList(java.lang.String[] projection, java.lang.String selection, java.lang.String[] selectionArgs, java.lang.String sortOrder) throws android.os.RemoteException;
  //get current apn info

  public java.lang.String getCurrentAPN(int slotIdx) throws android.os.RemoteException;
  // get apn list info

  public java.util.List<com.sunmi.tmsmaster.aidl.networkmanager.ApnModel> getApnList() throws android.os.RemoteException;
  // Forget all connected WiFi networks

  public void forgetSavedWifi() throws android.os.RemoteException;
  // Get the number of active SIM cards

  public int getActiveSimCardCount() throws android.os.RemoteException;
  // V2 version of the interface for getting the current APN list

  public java.lang.String getApnList_V2(int slotIdx) throws android.os.RemoteException;
  // Get total data traffic

  public long getTrafficTotal(int networkType, long startTime, long endTime) throws android.os.RemoteException;
  // Get data traffic of each app

  public java.util.Map getTrafficOfEachApp(int networkType, long startTime, long endTime) throws android.os.RemoteException;
  // Get current network slots

  public int getCurrentNetworkSlot() throws android.os.RemoteException;
  // Turn on/off hotspot

  public boolean switchPortableHotspot(boolean enable) throws android.os.RemoteException;
  // Add a system forbidden access IP

  public boolean deny(java.lang.String ip) throws android.os.RemoteException;
  // Delete a system forbidden access IP

  public boolean clearDenial(java.lang.String ip) throws android.os.RemoteException;
  // Delete all system forbidden access IPs

  public boolean clearAllDenial() throws android.os.RemoteException;
  // Get all forbidden access IPs

  public java.util.List<java.lang.String> getDenialList() throws android.os.RemoteException;
  // Add to network access to white list

  public boolean addToWhiteList(java.lang.String ip) throws android.os.RemoteException;
  // Remove from network access white list

  public boolean removeFromWhiteList(java.lang.String ip) throws android.os.RemoteException;
  // Get network access white list

  public java.util.List<java.lang.String> getWhiteList() throws android.os.RemoteException;
  // Clear DNS cache

  public boolean clearDnsCache() throws android.os.RemoteException;
  // Set data warning policy (value The value to be set of data warning (MB))

  public boolean setDataWarningPolicy(java.lang.String value) throws android.os.RemoteException;
  // Reset network settings. Including: Wi-Fi, mobile data, Bluetooth.

  public void resetNetworkSettings() throws android.os.RemoteException;
  public boolean removeAPN(java.lang.String apnName) throws android.os.RemoteException;
  public boolean updateAPN(com.sunmi.tmsmaster.aidl.networkmanager.APNConfigInfo configInfo) throws android.os.RemoteException;
  public void setDnsWhiteName(java.lang.String dnsServerName) throws android.os.RemoteException;
  public void clearDnsWhiteNameList() throws android.os.RemoteException;
  public void setDnsWhiteNameEnable(boolean enable) throws android.os.RemoteException;
  public boolean installWlanCertificate(java.lang.String name, byte[] certData, java.lang.String password) throws android.os.RemoteException;
  public boolean enableWifi(boolean enable) throws android.os.RemoteException;
  public boolean setAppRestrictMobile(boolean restrict, java.lang.String packageName) throws android.os.RemoteException;
  public boolean setAppRestrictWlan(boolean restrict, java.lang.String packageName) throws android.os.RemoteException;
  public java.util.List<java.lang.String> getAppRestrictMobile() throws android.os.RemoteException;
  public java.util.List<java.lang.String> getAppRestrictWlan() throws android.os.RemoteException;
  public int getPackageRestrictStatus(java.lang.String packageName) throws android.os.RemoteException;
  public void addWifiSsid(java.lang.String ssid, java.lang.String password, int type, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callBack) throws android.os.RemoteException;
  public void connectWifiSsid(java.lang.String ssid, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callBack) throws android.os.RemoteException;
  public void removeWifiSsid(java.lang.String ssid, com.sunmi.tmsmaster.aidl.networkmanager.IUnifiedCallback callBack) throws android.os.RemoteException;
}
