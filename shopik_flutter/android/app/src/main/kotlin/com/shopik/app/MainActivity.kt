package com.shopik.app

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.media.RingtoneManager
import android.os.Build
import android.provider.ContactsContract
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.shopik.app/heads_up_notifications"
    private val NOTIFICATION_CHANNEL_ID = "shopik_heads_up_channel"
    private val NOTIFICATION_CHANNEL_NAME = "إشعارات شبيك الفورية (Heads-up)"
    private var contactPickerResult: MethodChannel.Result? = null
    private val PICK_CONTACT_REQUEST = 2001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createChannel" -> {
                    createNotificationChannel()
                    result.success(true)
                }
                "showHeadsUpNotification" -> {
                    val title = call.argument<String>("title") ?: "تطبيق شبيك"
                    val body = call.argument<String>("body") ?: ""
                    val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                    showHeadsUpNotification(title, body, id)
                    result.success(true)
                }
                "pickContact" -> {
                    try {
                        contactPickerResult = result
                        val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
                        startActivityForResult(intent, PICK_CONTACT_REQUEST)
                    } catch (e: Exception) {
                        result.error("CONTACT_PICKER_ERROR", e.message, null)
                        contactPickerResult = null
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_CONTACT_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val contactUri = data.data!!
                val projection = arrayOf(
                    ContactsContract.CommonDataKinds.Phone.NUMBER,
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME
                )
                try {
                    contentResolver.query(contactUri, projection, null, null, null)?.use { cursor ->
                        if (cursor.moveToFirst()) {
                            val numberIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                            val nameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                            val number = if (numberIndex != -1) cursor.getString(numberIndex) else ""
                            val name = if (nameIndex != -1) cursor.getString(nameIndex) else ""
                            val resMap = hashMapOf("phone" to number, "name" to name)
                            contactPickerResult?.success(resMap)
                            contactPickerResult = null
                            return
                        }
                    }
                } catch (e: Exception) {
                    contactPickerResult?.error("READ_FAILED", e.message, null)
                    contactPickerResult = null
                    return
                }
            }
            contactPickerResult?.success(null)
            contactPickerResult = null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                importance
            ).apply {
                description = "قناة إشعارات العمليات والطلبات العاجلة بنظام الإشعار العائم (Heads-up)"
                enableLights(true)
                lightColor = Color.parseColor("#8B1D3B")
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 200, 300)
                setShowBadge(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showHeadsUpNotification(title: String, body: String, notificationId: Int) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, notificationId, intent, flags)

        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        // Strict Android Heads-up Requirements:
        // 1. Channel with IMPORTANCE_HIGH (API 26+)
        // 2. PRIORITY_MAX or PRIORITY_HIGH
        // 3. Sound or Vibration specified
        // 4. CATEGORY_MESSAGE or CATEGORY_EVENT
        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_notify_chat)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(soundUri)
            .setVibrate(longArrayOf(0, 350, 150, 350))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setColor(Color.parseColor("#8B1D3B"))
            .setFullScreenIntent(pendingIntent, false)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, builder.build())
    }
}

