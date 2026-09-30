package ly.masroufi.masroufi_mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterFragmentActivity() {

    private val METHOD_CHANNEL = "ly.masroufi.sms/channel"
    private val EVENT_CHANNEL = "ly.masroufi.sms/stream"
    private val PERMISSION_REQUEST_CODE = 101

    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. MethodChannel for checking, requesting SMS permission, reading inbox, and opening app settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestSmsPermission" -> {
                    val receiveGranted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    val readGranted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    if (receiveGranted && readGranted) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECEIVE_SMS, Manifest.permission.READ_SMS),
                            PERMISSION_REQUEST_CODE
                        )
                    }
                }
                "checkSmsPermission" -> {
                    val receiveGranted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    val readGranted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    result.success(receiveGranted && readGranted)
                }
                "readSmsInbox" -> {
                    val readGranted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    if (!readGranted) {
                        result.success(emptyList<Map<String, Any>>())
                        return@setMethodCallHandler
                    }

                    try {
                        val messagesList = mutableListOf<Map<String, Any>>()
                        val uri = Telephony.Sms.Inbox.CONTENT_URI
                        val projection = arrayOf(
                            Telephony.Sms.Inbox.ADDRESS,
                            Telephony.Sms.Inbox.BODY,
                            Telephony.Sms.Inbox.DATE
                        )

                        val minTimestampArg = call.argument<Number>("minTimestamp")?.toLong() ?: 0L
                        val selection = if (minTimestampArg > 0L) "${Telephony.Sms.Inbox.DATE} >= ?" else null
                        val selectionArgs = if (minTimestampArg > 0L) arrayOf(minTimestampArg.toString()) else null

                        val cursor = contentResolver.query(
                            uri,
                            projection,
                            selection,
                            selectionArgs,
                            "${Telephony.Sms.Inbox.DATE} DESC LIMIT 250"
                        )

                        cursor?.use {
                            val addressCol = it.getColumnIndex(Telephony.Sms.Inbox.ADDRESS)
                            val bodyCol = it.getColumnIndex(Telephony.Sms.Inbox.BODY)
                            val dateCol = it.getColumnIndex(Telephony.Sms.Inbox.DATE)

                            while (it.moveToNext()) {
                                val address = if (addressCol != -1) it.getString(addressCol) ?: "" else ""
                                val body = if (bodyCol != -1) it.getString(bodyCol) ?: "" else ""
                                val date = if (dateCol != -1) it.getLong(dateCol) else System.currentTimeMillis()

                                messagesList.add(
                                    mapOf(
                                        "sender" to address,
                                        "body" to body,
                                        "timestamp" to date
                                    )
                                )
                            }
                        }
                        result.success(messagesList)
                    } catch (e: Exception) {
                        result.error("INBOX_ERROR", e.message, null)
                    }
                }
                "getPendingSms" -> {
                    try {
                        val prefs = getSharedPreferences("masroufi_native_sms", Context.MODE_PRIVATE)
                        val pendingJson = prefs.getString("pending_sms", "[]") ?: "[]"
                        prefs.edit().remove("pending_sms").apply()

                        val jsonArray = JSONArray(pendingJson)
                        val list = mutableListOf<Map<String, Any>>()
                        for (i in 0 until jsonArray.length()) {
                            val obj = jsonArray.getJSONObject(i)
                            list.add(
                                mapOf(
                                    "sender" to obj.optString("sender", ""),
                                    "body" to obj.optString("body", ""),
                                    "timestamp" to obj.optLong("timestamp", System.currentTimeMillis())
                                )
                            )
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.success(emptyList<Map<String, Any>>())
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url") ?: ""
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("URL_ERROR", e.message, null)
                    }
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. EventChannel for streaming new live incoming SMS to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    SmsReceiver.listener = { sender, body, timestamp ->
                        val data = mapOf(
                            "sender" to sender,
                            "body" to body,
                            "timestamp" to timestamp
                        )
                        runOnUiThread {
                            eventSink?.success(data)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    SmsReceiver.listener = null
                }
            }
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }
}
