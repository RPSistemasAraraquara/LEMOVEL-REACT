package br.com.sistemalechef.cardapiotablet

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.os.Build
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class TabletKioskModule(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
  override fun getName(): String = "TabletKiosk"

  @ReactMethod
  fun getKioskStatus(promise: Promise) {
    try {
      val packageName = reactContext.packageName
      val devicePolicyManager = reactContext.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
      val activityManager = reactContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
      val isDeviceOwner = devicePolicyManager.isDeviceOwnerApp(packageName)
      val isProfileOwner = devicePolicyManager.isProfileOwnerApp(packageName)
      val isManagedOwner = isDeviceOwner || isProfileOwner
      val isLockTaskPermitted =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
          devicePolicyManager.isLockTaskPermitted(packageName)
        } else {
          false
        }
      val lockTaskMode = getLockTaskMode(activityManager)
      val secureKiosk = isManagedOwner && isLockTaskPermitted && lockTaskMode == "locked"

      val status = Arguments.createMap()
      status.putBoolean("secureKiosk", secureKiosk)
      status.putBoolean("deviceOwner", isDeviceOwner)
      status.putBoolean("profileOwner", isProfileOwner)
      status.putBoolean("managedOwner", isManagedOwner)
      status.putBoolean("lockTaskPermitted", isLockTaskPermitted)
      status.putString("lockTaskMode", lockTaskMode)
      promise.resolve(status)
    } catch (error: Exception) {
      promise.reject("KIOSK_STATUS_FAILED", error)
    }
  }

  @ReactMethod
  fun exitApp(promise: Promise) {
    val activity = reactContext.currentActivity
    if (activity == null) {
      promise.reject("NO_ACTIVITY", "Activity nao disponivel para fechar o app.")
      return
    }

    activity.runOnUiThread {
      try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
          try {
            activity.stopLockTask()
          } catch (_: Exception) {
            // Android throws when the app is not currently pinned/locked.
          }
        }

        promise.resolve(true)
        activity.finishAndRemoveTask()
      } catch (error: Exception) {
        promise.reject("EXIT_FAILED", error)
      }
    }
  }

  private fun getLockTaskMode(activityManager: ActivityManager): String {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return "unsupported"

    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      when (activityManager.lockTaskModeState) {
        ActivityManager.LOCK_TASK_MODE_LOCKED -> "locked"
        ActivityManager.LOCK_TASK_MODE_PINNED -> "pinned"
        ActivityManager.LOCK_TASK_MODE_NONE -> "none"
        else -> "unknown"
      }
    } else {
      @Suppress("DEPRECATION")
      if (activityManager.isInLockTaskMode) "active" else "none"
    }
  }
}
