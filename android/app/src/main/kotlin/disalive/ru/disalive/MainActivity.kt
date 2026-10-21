package disalive.ru.disalive

import android.app.PictureInPictureParams
import android.app.AppOpsManager
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Rational
import android.view.WindowInsets
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pipChannel: MethodChannel? = null
    private var callActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.disalive/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canInstallPackages" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                            packageManager.canRequestPackageInstalls()
                    )
                    "openInstallSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                    data = Uri.parse("package:$packageName")
                                })
                            }
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("INSTALL_SETTINGS", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.disalive/system_insets")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "navigationBarBottom" -> result.success(navigationBarBottomInset())
                    else -> result.notImplemented()
                }
            }
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.disalive/pip")
        pipChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPipSupported" -> result.success(isPipSupported())
                "isPipAllowed" -> result.success(isPipAllowed())
                "openPipSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        })
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("PIP_SETTINGS", error.message, null)
                    }
                }
                "setCallActive" -> {
                    callActive = call.arguments == true
                    updatePipParams()
                    result.success(null)
                }
                "enterPiP" -> result.success(enterCallPip())
                "startCallService" -> {
                    try {
                        val intent = Intent(this, CallForegroundService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("CALL_SERVICE", error.message, null)
                    }
                }
                "stopCallService" -> {
                    stopService(Intent(this, CallForegroundService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun navigationBarBottomInset(): Double {
        val insets = window.decorView.rootWindowInsets
        val reportedPixels = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            insets?.getInsetsIgnoringVisibility(WindowInsets.Type.navigationBars())?.bottom ?: 0
        } else {
            @Suppress("DEPRECATION")
            insets?.stableInsetBottom ?: 0
        }
        val pixels = if (
            reportedPixels > 0 ||
            resources.configuration.orientation != Configuration.ORIENTATION_PORTRAIT
        ) {
            reportedPixels
        } else {
            val id = resources.getIdentifier("navigation_bar_height", "dimen", "android")
            if (id != 0) resources.getDimensionPixelSize(id) else 0
        }
        return pixels / resources.displayMetrics.density.toDouble()
    }

    private fun isPipSupported(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)

    private fun isPipAllowed(): Boolean {
        if (!isPipSupported()) return false
        val appOps = getSystemService(AppOpsManager::class.java)
        return appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_PICTURE_IN_PICTURE,
            Process.myUid(),
            packageName
        ) == AppOpsManager.MODE_ALLOWED
    }

    private fun updatePipParams() {
        if (!isPipSupported()) return
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(16, 9))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(callActive && isPipAllowed())
        }
        setPictureInPictureParams(builder.build())
    }

    private fun enterCallPip(): Boolean {
        if (!callActive || !isPipAllowed() || isInPictureInPictureMode) return false
        return enterPictureInPictureMode(
            PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9)).build()
        )
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) enterCallPip()
    }

    override fun onResume() {
        super.onResume()
        if (callActive) updatePipParams()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPiPModeChanged", isInPictureInPictureMode)
    }

    override fun onDestroy() {
        if (isFinishing && !isChangingConfigurations) {
            stopService(Intent(this, CallForegroundService::class.java))
        }
        super.onDestroy()
    }
}
