package com.streak.app

import android.content.Context

object NotificationStore {

    private const val STORE = "scheduled_notifications"
    private const val STAMP = "streak_notification_store"
    private const val STAMP_KEY = "builtFor"

    fun repairFor(context: Context, version: Long) {
        val stamp = context.getSharedPreferences(STAMP, Context.MODE_PRIVATE)
        if (stamp.getLong(STAMP_KEY, -1L) == version) return

        context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            .edit()
            .remove(STORE)
            .apply()
        stamp.edit().putLong(STAMP_KEY, version).apply()
    }
}
