package com.remindra.birthdayreminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * BootReceiver restores scheduled birthday notifications after the device
 * restarts. Android cancels all AlarmManager alarms on reboot, so we
 * launch the app's Flutter engine in the background to let
 * flutter_local_notifications re-register them.
 *
 * The actual rescheduling happens inside Dart (main.dart → BirthdayNotificationManager.initialize
 * + Home.initState → rescheduleAll). This receiver just starts the activity
 * so Flutter gets a chance to run.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            // Launch the main activity in the background so Flutter can
            // reschedule all alarms via BirthdayNotificationManager.rescheduleAll()
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("from_boot_receiver", true)
            }
            context.startActivity(launchIntent)
        }
    }
}
