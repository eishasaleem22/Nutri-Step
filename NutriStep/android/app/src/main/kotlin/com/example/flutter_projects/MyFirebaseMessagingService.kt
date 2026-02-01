package com.example.flutter_projects

// ↑ Make sure this line exactly matches your Gradle “applicationId”
//    and the folder path (e.g., com/example/flutter_projects).

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onCreate() {
        super.onCreate()
        createHighImportanceChannel()
    }

    private fun createHighImportanceChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "high_importance_channel",
                "High Importance Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Used for meal, water, exercise reminders, etc."
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        // Build a simple notification from the payload:
        val title = message.notification?.title ?: "NutriStep"
        val body = message.notification?.body ?: "You have a new reminder."
        val builder = NotificationCompat.Builder(this, "high_importance_channel")
            .setSmallIcon(R.mipmap.launcher)  // match your launcher icon
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)

        NotificationManagerCompat.from(this).notify(0, builder.build())
    }
}