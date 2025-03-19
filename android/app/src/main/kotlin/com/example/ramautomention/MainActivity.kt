package com.example.flauto

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            "channel_id",
            "Event Schedule",
            NotificationManager.IMPORTANCE_HIGH
        )
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }
}
