/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.tmsmaster.aidl.devicemanager;
public interface IDeviceManager extends android.os.IInterface
{
  /** Default implementation for IDeviceManager. */
  public static class Default implements com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager
  {
    // set system time

    @Override public void setSystemTime(int second, int minute, int hour, int day, int month, int year) throws android.os.RemoteException
    {
    }
    // reboot

    @Override public void powerReboot() throws android.os.RemoteException
    {
    }
    //shutdown

    @Override public void shutdown() throws android.os.RemoteException
    {
    }
    //set timezone

    @Override public void setTimeZone(java.lang.String timeZone) throws android.os.RemoteException
    {
    }
    //Restore Factory

    @Override public void factoryReset() throws android.os.RemoteException
    {
    }
    //Reset apps

    @Override public void resetApps(com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener listener) throws android.os.RemoteException
    {
    }
    //to sleep

    @Override public void toSleep() throws android.os.RemoteException
    {
    }
    //to wake up

    @Override public void toWakeUp() throws android.os.RemoteException
    {
    }
    //Switch device enable or disable

    @Override public boolean switchDeviceEnable(boolean enable) throws android.os.RemoteException
    {
      return false;
    }
    // switch BT enable/disable

    @Override public boolean switchBTModuleEnable(boolean enable) throws android.os.RemoteException
    {
      return false;
    }
    // Get BT enable state

    @Override public boolean isBTModuleEnabled() throws android.os.RemoteException
    {
      return false;
    }
    // Setting the screen brightness

    @Override public boolean setBrightness(int value) throws android.os.RemoteException
    {
      return false;
    }
    // Set screen timeout

    @Override public boolean setScreenTimeout(int timeout) throws android.os.RemoteException
    {
      return false;
    }
    // Set system language (language e.g. "zh_CN")

    @Override public boolean setSystemLanguage(java.lang.String language) throws android.os.RemoteException
    {
      return false;
    }
    // Disable/enable auto time

    @Override public boolean enableAutoTime(boolean enable) throws android.os.RemoteException
    {
      return false;
    }
    // Disable/enable auto time zone

    @Override public boolean enableAutoTimeZone(boolean enable) throws android.os.RemoteException
    {
      return false;
    }
    // Disable/enable physical keys

    @Override public void enableKeyEvent(boolean enable) throws android.os.RemoteException
    {
    }
    // Disable/enable Location(GPS) without asking the user for permission

    @Override public void enableLocation(boolean enable) throws android.os.RemoteException
    {
    }
    // Disable/enable time format (24 hour or 12 Hour) of the terminal

    @Override public void set24Hour(boolean is24Hour) throws android.os.RemoteException
    {
    }
    // Disable/enable power key

    @Override public void enablePowerKey(boolean enable) throws android.os.RemoteException
    {
    }
    // Check if power key is Disable/enable

    @Override public boolean isPowerKeyEnabled() throws android.os.RemoteException
    {
      return false;
    }
    // Disable/enable power button lock screen

    @Override public void enableShortPressPowerKey(boolean enable) throws android.os.RemoteException
    {
    }
    // Set Boot Animation

    @Override public void setBootAnimation(java.lang.String filePath) throws android.os.RemoteException
    {
    }
    // Disable/enable permission request when USB is connected. (To allow or not allow ADB for example)

    @Override public void enableUsbPermissionDialog(boolean enable) throws android.os.RemoteException
    {
    }
    // Get screen timeout

    @Override public int getScreenTimeout() throws android.os.RemoteException
    {
      return 0;
    }
    // Set screen saver display time

    @Override public int setScreenSaverTime(int millisecond) throws android.os.RemoteException
    {
      return 0;
    }
    // Set auto time type

    @Override public void setAutoTimeType(int type) throws android.os.RemoteException
    {
    }
    // Set the mode of battery work. 0:Battery intelligent mode 1:Long battery life mode 2:Battery long life mode

    @Override public boolean setBatteryWorkMode(int mode) throws android.os.RemoteException
    {
      return false;
    }
    // Get the mode of battery work

    @Override public int getBatteryWorkMode() throws android.os.RemoteException
    {
      return 0;
    }
    /**
         * set QSPanel icon enable
         * @param hide true:display false:hide
         * @return true:success false:fail
         */
    @Override public boolean enableQSPanelIcon(java.lang.String icon, boolean enable) throws android.os.RemoteException
    {
      return false;
    }
    /**
         * set devices owner
         * @param packName owner app package name
         * @param classFullPathName class full path name,This class must extends from BroadcastReceiver
         * @return true:success false:fail
         */
    @Override public boolean setDeviceOwner(java.lang.String packName, java.lang.String classFullPathName) throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean setAirplaneMode(boolean open) throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean clearDeviceOwner() throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean enableBootOrShutdownRegularly(int type, int hour, int minutes, int repeatMode) throws android.os.RemoteException
    {
      return false;
    }
    @Override public boolean disableBootOrShutdownRegularly(int type) throws android.os.RemoteException
    {
      return false;
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager))) {
        return ((com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager)iin);
      }
      return new com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager.Stub.Proxy(obj);
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
        case TRANSACTION_setSystemTime:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          int _arg1;
          _arg1 = data.readInt();
          int _arg2;
          _arg2 = data.readInt();
          int _arg3;
          _arg3 = data.readInt();
          int _arg4;
          _arg4 = data.readInt();
          int _arg5;
          _arg5 = data.readInt();
          this.setSystemTime(_arg0, _arg1, _arg2, _arg3, _arg4, _arg5);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_powerReboot:
        {
          data.enforceInterface(descriptor);
          this.powerReboot();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_shutdown:
        {
          data.enforceInterface(descriptor);
          this.shutdown();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setTimeZone:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          this.setTimeZone(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_factoryReset:
        {
          data.enforceInterface(descriptor);
          this.factoryReset();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_resetApps:
        {
          data.enforceInterface(descriptor);
          com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener _arg0;
          _arg0 = com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener.Stub.asInterface(data.readStrongBinder());
          this.resetApps(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_toSleep:
        {
          data.enforceInterface(descriptor);
          this.toSleep();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_toWakeUp:
        {
          data.enforceInterface(descriptor);
          this.toWakeUp();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_switchDeviceEnable:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          boolean _result = this.switchDeviceEnable(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_switchBTModuleEnable:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          boolean _result = this.switchBTModuleEnable(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_isBTModuleEnabled:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.isBTModuleEnabled();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setBrightness:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          boolean _result = this.setBrightness(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setScreenTimeout:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          boolean _result = this.setScreenTimeout(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setSystemLanguage:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _result = this.setSystemLanguage(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_enableAutoTime:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          boolean _result = this.enableAutoTime(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_enableAutoTimeZone:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          boolean _result = this.enableAutoTimeZone(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_enableKeyEvent:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableKeyEvent(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_enableLocation:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableLocation(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_set24Hour:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.set24Hour(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_enablePowerKey:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enablePowerKey(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_isPowerKeyEnabled:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.isPowerKeyEnabled();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_enableShortPressPowerKey:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableShortPressPowerKey(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setBootAnimation:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          this.setBootAnimation(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_enableUsbPermissionDialog:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          this.enableUsbPermissionDialog(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_getScreenTimeout:
        {
          data.enforceInterface(descriptor);
          int _result = this.getScreenTimeout();
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_setScreenSaverTime:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          int _result = this.setScreenSaverTime(_arg0);
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_setAutoTimeType:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          this.setAutoTimeType(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_setBatteryWorkMode:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          boolean _result = this.setBatteryWorkMode(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_getBatteryWorkMode:
        {
          data.enforceInterface(descriptor);
          int _result = this.getBatteryWorkMode();
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_enableQSPanelIcon:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          boolean _arg1;
          _arg1 = (0!=data.readInt());
          boolean _result = this.enableQSPanelIcon(_arg0, _arg1);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setDeviceOwner:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          java.lang.String _arg1;
          _arg1 = data.readString();
          boolean _result = this.setDeviceOwner(_arg0, _arg1);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_setAirplaneMode:
        {
          data.enforceInterface(descriptor);
          boolean _arg0;
          _arg0 = (0!=data.readInt());
          boolean _result = this.setAirplaneMode(_arg0);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_clearDeviceOwner:
        {
          data.enforceInterface(descriptor);
          boolean _result = this.clearDeviceOwner();
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_enableBootOrShutdownRegularly:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          int _arg1;
          _arg1 = data.readInt();
          int _arg2;
          _arg2 = data.readInt();
          int _arg3;
          _arg3 = data.readInt();
          boolean _result = this.enableBootOrShutdownRegularly(_arg0, _arg1, _arg2, _arg3);
          reply.writeNoException();
          reply.writeInt(((_result)?(1):(0)));
          return true;
        }
        case TRANSACTION_disableBootOrShutdownRegularly:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          boolean _result = this.disableBootOrShutdownRegularly(_arg0);
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
    private static class Proxy implements com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager
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
      // set system time

      @Override public void setSystemTime(int second, int minute, int hour, int day, int month, int year) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(second);
          _data.writeInt(minute);
          _data.writeInt(hour);
          _data.writeInt(day);
          _data.writeInt(month);
          _data.writeInt(year);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setSystemTime, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setSystemTime(second, minute, hour, day, month, year);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // reboot

      @Override public void powerReboot() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_powerReboot, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().powerReboot();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //shutdown

      @Override public void shutdown() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_shutdown, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().shutdown();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //set timezone

      @Override public void setTimeZone(java.lang.String timeZone) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(timeZone);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setTimeZone, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setTimeZone(timeZone);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //Restore Factory

      @Override public void factoryReset() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_factoryReset, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().factoryReset();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //Reset apps

      @Override public void resetApps(com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener listener) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder((((listener!=null))?(listener.asBinder()):(null)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_resetApps, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().resetApps(listener);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //to sleep

      @Override public void toSleep() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_toSleep, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().toSleep();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //to wake up

      @Override public void toWakeUp() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_toWakeUp, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().toWakeUp();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      //Switch device enable or disable

      @Override public boolean switchDeviceEnable(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_switchDeviceEnable, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().switchDeviceEnable(enable);
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
      // switch BT enable/disable

      @Override public boolean switchBTModuleEnable(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_switchBTModuleEnable, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().switchBTModuleEnable(enable);
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
      // Get BT enable state

      @Override public boolean isBTModuleEnabled() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_isBTModuleEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().isBTModuleEnabled();
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
      // Setting the screen brightness

      @Override public boolean setBrightness(int value) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(value);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setBrightness, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setBrightness(value);
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
      // Set screen timeout

      @Override public boolean setScreenTimeout(int timeout) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(timeout);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setScreenTimeout, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setScreenTimeout(timeout);
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
      // Set system language (language e.g. "zh_CN")

      @Override public boolean setSystemLanguage(java.lang.String language) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(language);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setSystemLanguage, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setSystemLanguage(language);
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
      // Disable/enable auto time

      @Override public boolean enableAutoTime(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableAutoTime, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().enableAutoTime(enable);
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
      // Disable/enable auto time zone

      @Override public boolean enableAutoTimeZone(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableAutoTimeZone, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().enableAutoTimeZone(enable);
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
      // Disable/enable physical keys

      @Override public void enableKeyEvent(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableKeyEvent, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableKeyEvent(enable);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Disable/enable Location(GPS) without asking the user for permission

      @Override public void enableLocation(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableLocation, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableLocation(enable);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Disable/enable time format (24 hour or 12 Hour) of the terminal

      @Override public void set24Hour(boolean is24Hour) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((is24Hour)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_set24Hour, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().set24Hour(is24Hour);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Disable/enable power key

      @Override public void enablePowerKey(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enablePowerKey, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enablePowerKey(enable);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Check if power key is Disable/enable

      @Override public boolean isPowerKeyEnabled() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_isPowerKeyEnabled, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().isPowerKeyEnabled();
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
      // Disable/enable power button lock screen

      @Override public void enableShortPressPowerKey(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableShortPressPowerKey, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableShortPressPowerKey(enable);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Set Boot Animation

      @Override public void setBootAnimation(java.lang.String filePath) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(filePath);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setBootAnimation, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setBootAnimation(filePath);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Disable/enable permission request when USB is connected. (To allow or not allow ADB for example)

      @Override public void enableUsbPermissionDialog(boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableUsbPermissionDialog, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().enableUsbPermissionDialog(enable);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Get screen timeout

      @Override public int getScreenTimeout() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getScreenTimeout, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getScreenTimeout();
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
      // Set screen saver display time

      @Override public int setScreenSaverTime(int millisecond) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(millisecond);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setScreenSaverTime, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setScreenSaverTime(millisecond);
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
      // Set auto time type

      @Override public void setAutoTimeType(int type) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(type);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setAutoTimeType, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setAutoTimeType(type);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      // Set the mode of battery work. 0:Battery intelligent mode 1:Long battery life mode 2:Battery long life mode

      @Override public boolean setBatteryWorkMode(int mode) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(mode);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setBatteryWorkMode, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setBatteryWorkMode(mode);
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
      // Get the mode of battery work

      @Override public int getBatteryWorkMode() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getBatteryWorkMode, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getBatteryWorkMode();
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
      /**
           * set QSPanel icon enable
           * @param hide true:display false:hide
           * @return true:success false:fail
           */
      @Override public boolean enableQSPanelIcon(java.lang.String icon, boolean enable) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(icon);
          _data.writeInt(((enable)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableQSPanelIcon, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().enableQSPanelIcon(icon, enable);
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
      /**
           * set devices owner
           * @param packName owner app package name
           * @param classFullPathName class full path name,This class must extends from BroadcastReceiver
           * @return true:success false:fail
           */
      @Override public boolean setDeviceOwner(java.lang.String packName, java.lang.String classFullPathName) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(packName);
          _data.writeString(classFullPathName);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setDeviceOwner, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setDeviceOwner(packName, classFullPathName);
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
      @Override public boolean setAirplaneMode(boolean open) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(((open)?(1):(0)));
          boolean _status = mRemote.transact(Stub.TRANSACTION_setAirplaneMode, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().setAirplaneMode(open);
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
      @Override public boolean clearDeviceOwner() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_clearDeviceOwner, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().clearDeviceOwner();
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
      @Override public boolean enableBootOrShutdownRegularly(int type, int hour, int minutes, int repeatMode) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(type);
          _data.writeInt(hour);
          _data.writeInt(minutes);
          _data.writeInt(repeatMode);
          boolean _status = mRemote.transact(Stub.TRANSACTION_enableBootOrShutdownRegularly, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().enableBootOrShutdownRegularly(type, hour, minutes, repeatMode);
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
      @Override public boolean disableBootOrShutdownRegularly(int type) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        boolean _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(type);
          boolean _status = mRemote.transact(Stub.TRANSACTION_disableBootOrShutdownRegularly, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().disableBootOrShutdownRegularly(type);
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
      public static com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager sDefaultImpl;
    }
    static final int TRANSACTION_setSystemTime = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_powerReboot = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_shutdown = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_setTimeZone = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_factoryReset = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_resetApps = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    static final int TRANSACTION_toSleep = (android.os.IBinder.FIRST_CALL_TRANSACTION + 6);
    static final int TRANSACTION_toWakeUp = (android.os.IBinder.FIRST_CALL_TRANSACTION + 7);
    static final int TRANSACTION_switchDeviceEnable = (android.os.IBinder.FIRST_CALL_TRANSACTION + 8);
    static final int TRANSACTION_switchBTModuleEnable = (android.os.IBinder.FIRST_CALL_TRANSACTION + 9);
    static final int TRANSACTION_isBTModuleEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 10);
    static final int TRANSACTION_setBrightness = (android.os.IBinder.FIRST_CALL_TRANSACTION + 11);
    static final int TRANSACTION_setScreenTimeout = (android.os.IBinder.FIRST_CALL_TRANSACTION + 12);
    static final int TRANSACTION_setSystemLanguage = (android.os.IBinder.FIRST_CALL_TRANSACTION + 13);
    static final int TRANSACTION_enableAutoTime = (android.os.IBinder.FIRST_CALL_TRANSACTION + 14);
    static final int TRANSACTION_enableAutoTimeZone = (android.os.IBinder.FIRST_CALL_TRANSACTION + 15);
    static final int TRANSACTION_enableKeyEvent = (android.os.IBinder.FIRST_CALL_TRANSACTION + 16);
    static final int TRANSACTION_enableLocation = (android.os.IBinder.FIRST_CALL_TRANSACTION + 17);
    static final int TRANSACTION_set24Hour = (android.os.IBinder.FIRST_CALL_TRANSACTION + 18);
    static final int TRANSACTION_enablePowerKey = (android.os.IBinder.FIRST_CALL_TRANSACTION + 19);
    static final int TRANSACTION_isPowerKeyEnabled = (android.os.IBinder.FIRST_CALL_TRANSACTION + 20);
    static final int TRANSACTION_enableShortPressPowerKey = (android.os.IBinder.FIRST_CALL_TRANSACTION + 21);
    static final int TRANSACTION_setBootAnimation = (android.os.IBinder.FIRST_CALL_TRANSACTION + 22);
    static final int TRANSACTION_enableUsbPermissionDialog = (android.os.IBinder.FIRST_CALL_TRANSACTION + 23);
    static final int TRANSACTION_getScreenTimeout = (android.os.IBinder.FIRST_CALL_TRANSACTION + 24);
    static final int TRANSACTION_setScreenSaverTime = (android.os.IBinder.FIRST_CALL_TRANSACTION + 25);
    static final int TRANSACTION_setAutoTimeType = (android.os.IBinder.FIRST_CALL_TRANSACTION + 26);
    static final int TRANSACTION_setBatteryWorkMode = (android.os.IBinder.FIRST_CALL_TRANSACTION + 27);
    static final int TRANSACTION_getBatteryWorkMode = (android.os.IBinder.FIRST_CALL_TRANSACTION + 28);
    static final int TRANSACTION_enableQSPanelIcon = (android.os.IBinder.FIRST_CALL_TRANSACTION + 29);
    static final int TRANSACTION_setDeviceOwner = (android.os.IBinder.FIRST_CALL_TRANSACTION + 30);
    static final int TRANSACTION_setAirplaneMode = (android.os.IBinder.FIRST_CALL_TRANSACTION + 31);
    static final int TRANSACTION_clearDeviceOwner = (android.os.IBinder.FIRST_CALL_TRANSACTION + 32);
    static final int TRANSACTION_enableBootOrShutdownRegularly = (android.os.IBinder.FIRST_CALL_TRANSACTION + 33);
    static final int TRANSACTION_disableBootOrShutdownRegularly = (android.os.IBinder.FIRST_CALL_TRANSACTION + 34);
    public static boolean setDefaultImpl(com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager impl) {
      if (Stub.Proxy.sDefaultImpl == null && impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.tmsmaster.aidl.devicemanager.IDeviceManager getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  // set system time

  public void setSystemTime(int second, int minute, int hour, int day, int month, int year) throws android.os.RemoteException;
  // reboot

  public void powerReboot() throws android.os.RemoteException;
  //shutdown

  public void shutdown() throws android.os.RemoteException;
  //set timezone

  public void setTimeZone(java.lang.String timeZone) throws android.os.RemoteException;
  //Restore Factory

  public void factoryReset() throws android.os.RemoteException;
  //Reset apps

  public void resetApps(com.sunmi.tmsmaster.aidl.devicemanager.listener.OnResetAppsListener listener) throws android.os.RemoteException;
  //to sleep

  public void toSleep() throws android.os.RemoteException;
  //to wake up

  public void toWakeUp() throws android.os.RemoteException;
  //Switch device enable or disable

  public boolean switchDeviceEnable(boolean enable) throws android.os.RemoteException;
  // switch BT enable/disable

  public boolean switchBTModuleEnable(boolean enable) throws android.os.RemoteException;
  // Get BT enable state

  public boolean isBTModuleEnabled() throws android.os.RemoteException;
  // Setting the screen brightness

  public boolean setBrightness(int value) throws android.os.RemoteException;
  // Set screen timeout

  public boolean setScreenTimeout(int timeout) throws android.os.RemoteException;
  // Set system language (language e.g. "zh_CN")

  public boolean setSystemLanguage(java.lang.String language) throws android.os.RemoteException;
  // Disable/enable auto time

  public boolean enableAutoTime(boolean enable) throws android.os.RemoteException;
  // Disable/enable auto time zone

  public boolean enableAutoTimeZone(boolean enable) throws android.os.RemoteException;
  // Disable/enable physical keys

  public void enableKeyEvent(boolean enable) throws android.os.RemoteException;
  // Disable/enable Location(GPS) without asking the user for permission

  public void enableLocation(boolean enable) throws android.os.RemoteException;
  // Disable/enable time format (24 hour or 12 Hour) of the terminal

  public void set24Hour(boolean is24Hour) throws android.os.RemoteException;
  // Disable/enable power key

  public void enablePowerKey(boolean enable) throws android.os.RemoteException;
  // Check if power key is Disable/enable

  public boolean isPowerKeyEnabled() throws android.os.RemoteException;
  // Disable/enable power button lock screen

  public void enableShortPressPowerKey(boolean enable) throws android.os.RemoteException;
  // Set Boot Animation

  public void setBootAnimation(java.lang.String filePath) throws android.os.RemoteException;
  // Disable/enable permission request when USB is connected. (To allow or not allow ADB for example)

  public void enableUsbPermissionDialog(boolean enable) throws android.os.RemoteException;
  // Get screen timeout

  public int getScreenTimeout() throws android.os.RemoteException;
  // Set screen saver display time

  public int setScreenSaverTime(int millisecond) throws android.os.RemoteException;
  // Set auto time type

  public void setAutoTimeType(int type) throws android.os.RemoteException;
  // Set the mode of battery work. 0:Battery intelligent mode 1:Long battery life mode 2:Battery long life mode

  public boolean setBatteryWorkMode(int mode) throws android.os.RemoteException;
  // Get the mode of battery work

  public int getBatteryWorkMode() throws android.os.RemoteException;
  /**
       * set QSPanel icon enable
       * @param hide true:display false:hide
       * @return true:success false:fail
       */
  public boolean enableQSPanelIcon(java.lang.String icon, boolean enable) throws android.os.RemoteException;
  /**
       * set devices owner
       * @param packName owner app package name
       * @param classFullPathName class full path name,This class must extends from BroadcastReceiver
       * @return true:success false:fail
       */
  public boolean setDeviceOwner(java.lang.String packName, java.lang.String classFullPathName) throws android.os.RemoteException;
  public boolean setAirplaneMode(boolean open) throws android.os.RemoteException;
  public boolean clearDeviceOwner() throws android.os.RemoteException;
  public boolean enableBootOrShutdownRegularly(int type, int hour, int minutes, int repeatMode) throws android.os.RemoteException;
  public boolean disableBootOrShutdownRegularly(int type) throws android.os.RemoteException;
}
