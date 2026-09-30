package ly.masroufi.masroufi_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import org.json.JSONArray
import org.json.JSONObject

class SmsReceiver : BroadcastReceiver() {

    companion object {
        var listener: ((sender: String, body: String, timestamp: Long) -> Unit)? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) return

            val sender = messages[0].originatingAddress ?: "Unknown"
            val bodyBuilder = StringBuilder()
            var timestamp = System.currentTimeMillis()

            for (sms in messages) {
                bodyBuilder.append(sms.messageBody)
                timestamp = sms.timestampMillis
            }

            val fullBody = bodyBuilder.toString()

            // 1. If Flutter is active and listening, deliver immediately
            val activeListener = listener
            if (activeListener != null) {
                activeListener.invoke(sender, fullBody, timestamp)
            } else {
                // 2. Otherwise, save to local pending storage so it is processed upon opening the app
                try {
                    val prefs = context.getSharedPreferences("masroufi_native_sms", Context.MODE_PRIVATE)
                    val existing = prefs.getString("pending_sms", "[]") ?: "[]"
                    val jsonArray = JSONArray(existing)
                    val obj = JSONObject().apply {
                        put("sender", sender)
                        put("body", fullBody)
                        put("timestamp", timestamp)
                    }
                    jsonArray.put(obj)
                    prefs.edit().putString("pending_sms", jsonArray.toString()).apply()
                } catch (_: Exception) {}
            }
        }
    }
}
