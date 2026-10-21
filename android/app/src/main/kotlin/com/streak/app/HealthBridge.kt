package com.streak.app

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.health.connect.AggregateRecordsRequest
import android.health.connect.AggregateRecordsResponse
import android.health.connect.HealthConnectException
import android.health.connect.HealthConnectManager
import android.health.connect.HealthPermissions
import android.health.connect.TimeInstantRangeFilter
import android.health.connect.datatypes.StepsRecord
import android.os.Build
import android.os.OutcomeReceiver
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

object HealthBridge {
    const val CHANNEL = "streak/health"
    private const val REQUEST_CODE = 4271
    private var pending: MethodChannel.Result? = null

    private val supported get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE

    fun attach(activity: Activity, channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            if (!supported) {
                result.success(if (call.method == "status") "unsupported" else null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "status" -> result.success(status(activity))
                "request" -> request(activity, result)
                "openSettings" -> result.success(openSettings(activity))
                "readSteps" -> readSteps(activity, call.argument<List<List<Number>>>("ranges").orEmpty(), result)
                else -> result.notImplemented()
            }
        }
    }

    fun onPermissionResult(requestCode: Int, results: IntArray): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pending ?: return true
        pending = null
        result.success(results.isNotEmpty() && results.all { it == PackageManager.PERMISSION_GRANTED })
        return true
    }

    fun isUsageIntent(intent: Intent?): Boolean {
        if (intent?.action != Intent.ACTION_VIEW_PERMISSION_USAGE) return false
        intent.action = Intent.ACTION_MAIN
        return true
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun status(activity: Activity): String = when {
        activity.getSystemService(HealthConnectManager::class.java) == null -> "unsupported"
        activity.checkSelfPermission(HealthPermissions.READ_STEPS) == PackageManager.PERMISSION_GRANTED -> "granted"
        else -> "denied"
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun request(activity: Activity, result: MethodChannel.Result) {
        if (status(activity) == "granted") return result.success(true)
        pending?.success(false)
        pending = result
        activity.requestPermissions(arrayOf(HealthPermissions.READ_STEPS), REQUEST_CODE)
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun openSettings(activity: Activity): Boolean = try {
        activity.startActivity(
            Intent(HealthConnectManager.ACTION_MANAGE_HEALTH_PERMISSIONS)
                .putExtra(Intent.EXTRA_PACKAGE_NAME, activity.packageName),
        )
        true
    } catch (e: Exception) {
        false
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun readSteps(activity: Activity, ranges: List<List<Number>>, result: MethodChannel.Result) {
        val manager = activity.getSystemService(HealthConnectManager::class.java)
        if (manager == null || ranges.isEmpty() || status(activity) != "granted") return result.success(null)
        val counts = LongArray(ranges.size)
        val left = AtomicInteger(ranges.size)
        val failed = AtomicBoolean(false)
        fun finish() {
            if (left.decrementAndGet() == 0) result.success(if (failed.get()) null else counts.toList())
        }
        ranges.forEachIndexed { i, range ->
            val filter = TimeInstantRangeFilter.Builder()
                .setStartTime(Instant.ofEpochMilli(range[0].toLong()))
                .setEndTime(Instant.ofEpochMilli(range[1].toLong()))
                .build()
            val request = AggregateRecordsRequest.Builder<Long>(filter)
                .addAggregationType(StepsRecord.STEPS_COUNT_TOTAL)
                .build()
            try {
                manager.aggregate(
                    request,
                    activity.mainExecutor,
                    object : OutcomeReceiver<AggregateRecordsResponse<Long>, HealthConnectException> {
                        override fun onResult(response: AggregateRecordsResponse<Long>) {
                            counts[i] = response.get(StepsRecord.STEPS_COUNT_TOTAL) ?: 0L
                            finish()
                        }

                        override fun onError(error: HealthConnectException) {
                            failed.set(true)
                            finish()
                        }
                    },
                )
            } catch (e: Exception) {
                failed.set(true)
                finish()
            }
        }
    }
}
