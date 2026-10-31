package com.streak.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle

class LinkActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val uri = intent?.data
        if (uri != null && enabled(this)) handle(uri)
        finish()
    }

    private fun handle(uri: Uri) {
        val habitId = uri.getQueryParameter("habit") ?: return
        when (uri.host) {
            "done", "undo", "add", "relapse" -> {
                val link = uri.toString()
                MainActivity.deliverLink(link) {
                    WidgetActionWorker.enqueue(applicationContext, link)
                }
            }
            "open" -> launch(WidgetActionReceiver.EXTRA_OPEN_HABIT, habitId)
            "focus" -> launch(WidgetActionReceiver.EXTRA_START_FOCUS, habitId)
        }
    }

    private fun launch(extra: String, habitId: String) {
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(extra, habitId)
            }
        )
    }

    companion object {
        private const val PREFS = "HomeWidgetPreferences"
        private const val KEY_ENABLED = "links_enabled"

        fun enabled(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_ENABLED, false)
    }
}
