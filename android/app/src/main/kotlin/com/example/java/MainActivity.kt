package com.c4.applistview
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.drawable.Drawable
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app_list_flutter/apps"
    private val scope = CoroutineScope(Dispatchers.IO)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    scope.launch {
                        val apps = getInstalledApps(this@MainActivity) // تمرير context هنا
                        result.success(apps)
                    }
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        openApp(packageName)
                        result.success(true)
                    } else {
                        result.error("ERROR", "Package name is null", null)
                    }
                }
                "uninstallApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        uninstallApp(packageName)
                        result.success(true)
                    } else {
                        result.error("ERROR", "Package name is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(context: Context): List<Map<String, Any>> {
        val packageManager = context.packageManager
        val packages: List<PackageInfo> = packageManager.getInstalledPackages(PackageManager.GET_META_DATA or PackageManager.GET_PERMISSIONS)
    
        return packages.mapNotNull { packageInfo ->
            val applicationInfo = packageInfo.applicationInfo
    
            if ((applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
                return@mapNotNull null
            }
    
            val apkSize = File(applicationInfo.sourceDir).length()
            val dataSize = getFolderSize(context.getDir("data", Context.MODE_PRIVATE))
            val cacheSize = getFolderSize(context.cacheDir)
            val totalSize = apkSize + dataSize + cacheSize
    
            val appIcon = applicationInfo.loadIcon(packageManager).toBitmap()
    
            mapOf(
                "appName" to packageManager.getApplicationLabel(applicationInfo).toString(),
                "packageName" to packageInfo.packageName,
                "versionName" to (packageInfo.versionName ?: "Unknown"),
                "installDate" to packageInfo.firstInstallTime,
                "appSize" to totalSize,
                "appIcon" to appIcon
            )
        }
    }
    private fun getFolderSize(folder: File): Long {
        var length: Long = 0
        if (folder.exists()) {
            val files = folder.listFiles()
            if (files != null) {
                for (file in files) {
                    length += if (file.isDirectory) {
                        getFolderSize(file) // حساب حجم المجلدات الفرعية
                    } else {
                        file.length() // حساب حجم الملف
                    }
                }
            }
        }
        return length
    }
    private fun openApp(packageName: String) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.let { startActivity(it) }
    }

    private fun uninstallApp(packageName: String) {
        val intent = Intent(Intent.ACTION_DELETE).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
    }

    private fun Drawable.toBitmap(): ByteArray {
        val bitmap = when (this) {
            is android.graphics.drawable.BitmapDrawable -> this.bitmap
            is android.graphics.drawable.AdaptiveIconDrawable -> {
                val bitmap = android.graphics.Bitmap.createBitmap(
                    this.intrinsicWidth,
                    this.intrinsicHeight,
                    android.graphics.Bitmap.Config.ARGB_8888
                )
                val canvas = android.graphics.Canvas(bitmap)
                this.setBounds(0, 0, canvas.width, canvas.height)
                this.draw(canvas)
                bitmap
            }
            else -> {
                val bitmap = android.graphics.Bitmap.createBitmap(
                    this.intrinsicWidth,
                    this.intrinsicHeight,
                    android.graphics.Bitmap.Config.ARGB_8888
                )
                val canvas = android.graphics.Canvas(bitmap)
                this.setBounds(0, 0, canvas.width, canvas.height)
                this.draw(canvas)
                bitmap
            }
        }

        val stream = java.io.ByteArrayOutputStream()
        bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    
}