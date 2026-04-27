package com.app.ilactakibim

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.app.ilactakibim/battery"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                        ).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.app.ilactakibim/alarm"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    val id        = call.argument<Int>("id")!!
                    val triggerMs = call.argument<Long>("triggerMs")!!
                    val title     = call.argument<String>("title")!!
                    val body      = call.argument<String>("body")!!

                    val intent = Intent(this, AlarmReceiver::class.java).apply {
                        putExtra("id", id)
                        putExtra("title", title)
                        putExtra("body", body)
                    }
                    val pi = PendingIntent.getBroadcast(
                        this, id, intent,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                    )
                    val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    am.setAlarmClock(AlarmManager.AlarmClockInfo(triggerMs, pi), pi)
                    result.success(null)
                }
                "cancel" -> {
                    val id = call.argument<Int>("id")!!
                    val intent = Intent(this, AlarmReceiver::class.java)
                    val pi = PendingIntent.getBroadcast(
                        this, id, intent,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
                    )
                    if (pi != null) {
                        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        am.cancel(pi)
                        pi.cancel()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
