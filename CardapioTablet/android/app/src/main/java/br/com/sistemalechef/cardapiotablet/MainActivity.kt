package br.com.sistemalechef.cardapiotablet

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager

import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.fabricEnabled
import com.facebook.react.defaults.DefaultReactActivityDelegate

import expo.modules.ReactActivityDelegateWrapper

class MainActivity : ReactActivity() {
  companion object {
    private const val TAG = "CardapioTabletKiosk"
  }

  private val immersiveHandler = Handler(Looper.getMainLooper())

  override fun onCreate(savedInstanceState: Bundle?) {
    // Set the theme to AppTheme BEFORE onCreate to support
    // coloring the background, status bar, and navigation bar.
    // This is required for expo-splash-screen.
    setTheme(R.style.AppTheme);
    super.onCreate(null)
    enterKioskMode()
  }

  override fun onResume() {
    super.onResume()
    enterKioskMode()
  }

  override fun onWindowFocusChanged(hasFocus: Boolean) {
    super.onWindowFocusChanged(hasFocus)
    if (hasFocus) {
      enterKioskMode()
    }
  }

  override fun onUserInteraction() {
    super.onUserInteraction()
    scheduleImmersiveMode()
  }

  private fun enterKioskMode() {
    enterImmersiveMode()
    startLockTaskSafely()
  }

  private fun scheduleImmersiveMode() {
    immersiveHandler.removeCallbacksAndMessages(null)
    immersiveHandler.postDelayed({ enterKioskMode() }, 350)
  }

  private fun startLockTaskSafely() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return

    val managedLockTaskReady = allowManagedLockTask()
    if (!managedLockTaskReady) {
      Log.w(TAG, "Tablet sem Device Owner; lock task fixado nao sera iniciado para nao expor atalho de saida.")
      return
    }

    if (isLockTaskActive()) {
      if (isPinnedLockTaskActive()) {
        try {
          stopLockTask()
        } catch (error: Exception) {
          Log.w(TAG, "Nao foi possivel trocar lock task fixado para gerenciado.", error)
          return
        }
      } else {
        return
      }
    }

    try {
      startLockTask()
    } catch (error: Exception) {
      // Full kiosk requires Android screen pinning or an MDM/device-owner allowlist.
      Log.w(TAG, "Nao foi possivel iniciar lock task.", error)
    }
  }

  private fun allowManagedLockTask(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return false

    val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    val adminComponent = ComponentName(this, TabletDeviceAdminReceiver::class.java)
    val canManageLockTask =
      devicePolicyManager.isDeviceOwnerApp(packageName) || devicePolicyManager.isProfileOwnerApp(packageName)

    if (!canManageLockTask) return false

    return try {
      devicePolicyManager.setLockTaskPackages(adminComponent, arrayOf(packageName))
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        devicePolicyManager.setLockTaskFeatures(adminComponent, DevicePolicyManager.LOCK_TASK_FEATURE_NONE)
      }
      true
    } catch (error: SecurityException) {
      Log.w(TAG, "Sem permissao para configurar lock task gerenciado.", error)
      false
    } catch (error: IllegalArgumentException) {
      Log.w(TAG, "Administrador do tablet nao esta ativo para lock task.", error)
      false
    }
  }

  private fun isLockTaskActive(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return false

    val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      val modeState = activityManager.lockTaskModeState
      modeState == ActivityManager.LOCK_TASK_MODE_LOCKED || modeState == ActivityManager.LOCK_TASK_MODE_PINNED
    } else {
      @Suppress("DEPRECATION")
      activityManager.isInLockTaskMode
    }
  }

  private fun isPinnedLockTaskActive(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false

    val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
    return activityManager.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_PINNED
  }

  private fun enterImmersiveMode() {
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      window.setDecorFitsSystemWindows(false)
      window.insetsController?.let { controller ->
        controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
        controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
      }
      return
    }

    @Suppress("DEPRECATION")
    window.decorView.systemUiVisibility =
      View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
        View.SYSTEM_UI_FLAG_FULLSCREEN or
        View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
        View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
        View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
        View.SYSTEM_UI_FLAG_LAYOUT_STABLE
  }

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  override fun getMainComponentName(): String = "main"

  /**
   * Returns the instance of the [ReactActivityDelegate]. We use [DefaultReactActivityDelegate]
   * which allows you to enable New Architecture with a single boolean flags [fabricEnabled]
   */
  override fun createReactActivityDelegate(): ReactActivityDelegate {
    return ReactActivityDelegateWrapper(
          this,
          BuildConfig.IS_NEW_ARCHITECTURE_ENABLED,
          object : DefaultReactActivityDelegate(
              this,
              mainComponentName,
              fabricEnabled
          ){})
  }

  /**
    * Align the back button behavior with Android S
    * where moving root activities to background instead of finishing activities.
    * @see <a href="https://developer.android.com/reference/android/app/Activity#onBackPressed()">onBackPressed</a>
    */
  override fun invokeDefaultOnBackPressed() {
      enterKioskMode()
  }
}
