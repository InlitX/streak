package com.streak.app

import android.content.BroadcastReceiver
import android.content.Intent
import androidx.core.app.CoreComponentFactory
import com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver

class StreakComponentFactory : CoreComponentFactory() {

    override fun instantiateReceiver(cl: ClassLoader, className: String, intent: Intent?): BroadcastReceiver =
        if (className == ScheduledNotificationReceiver::class.java.name) {
            ReminderReceiver()
        } else {
            super.instantiateReceiver(cl, className, intent)
        }
}
