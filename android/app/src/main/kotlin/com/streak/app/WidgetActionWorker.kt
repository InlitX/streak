package com.streak.app

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

class WidgetActionWorker(
    private val context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val forced = inputData.getBoolean(KEY_FORCED, false)
        if (!forced && WidgetActionQueue.isEmpty(context)) return Result.success()

        var engine: FlutterEngine? = null
        return try {
            val done = CompletableDeferred<Unit>()
            engine = withContext(Dispatchers.Main) {
                FlutterEngine(context).also { created ->
                    MethodChannel(created.dartExecutor.binaryMessenger, CHANNEL)
                        .setMethodCallHandler { call, result ->
                            if (call.method == "done") done.complete(Unit)
                            result.success(null)
                        }
                    created.dartExecutor.executeDartEntrypoint(
                        DartExecutor.DartEntrypoint(
                            FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                            ENTRYPOINT,
                        )
                    )
                }
            }
            if (withTimeoutOrNull(TIMEOUT_MS) { done.await() } != null) {
                HeatmapRenderer.refreshContent(context)
                GlanceWidgets.updateAll(context)
                Result.success()
            } else {
                Result.retry()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Widget action run failed", e)
            Result.retry()
        } finally {
            val target = engine
            if (target != null) withContext(Dispatchers.Main) { target.destroy() }
        }
    }

    companion object {
        private const val TAG = "StreakWidgetAction"
        private const val CHANNEL = "streak/widget_action"
        private const val ENTRYPOINT = "widgetActionEntrypoint"
        private const val TIMEOUT_MS = 20_000L
        private const val UNIQUE_NAME = "streak_widget_actions"
        private const val KEY_FORCED = "forced"

        fun enqueue(context: Context, uri: String) {
            WidgetActionQueue.push(context, uri)
            run(context, forced = false)
        }

        fun refresh(context: Context) = run(context, forced = true)

        private fun run(context: Context, forced: Boolean) {
            try {
                WorkManager.getInstance(context).enqueueUniqueWork(
                    UNIQUE_NAME,
                    ExistingWorkPolicy.APPEND_OR_REPLACE,
                    OneTimeWorkRequestBuilder<WidgetActionWorker>()
                        .setInputData(Data.Builder().putBoolean(KEY_FORCED, forced).build())
                        .build(),
                )
            } catch (e: Exception) {
                return
            }
        }
    }
}
