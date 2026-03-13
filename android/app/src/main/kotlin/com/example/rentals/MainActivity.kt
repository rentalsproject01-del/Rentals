package com.example.rentals

import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "rentals/google_maps_api"
        ).setMethodCallHandler { call, result ->
            if (call.method != "getApiKey") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val appInfo = packageManager.getApplicationInfo(
                    packageName,
                    PackageManager.GET_META_DATA
                )
                val apiKey = appInfo.metaData?.getString("com.google.android.geo.API_KEY")
                result.success(apiKey)
            } catch (exception: Exception) {
                result.error(
                    "GOOGLE_MAPS_API_KEY_UNAVAILABLE",
                    exception.message,
                    null
                )
            }
        }
    }
}
