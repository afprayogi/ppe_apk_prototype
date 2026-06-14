package com.example.vivatpass

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CRASH_CHANNEL = "com.vivatpass/crash"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CrashHandler.init(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CRASH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLastCrash" -> result.success(CrashHandler.readAndClear(applicationContext))
                    else           -> result.notImplemented()
                }
            }
    }
}
