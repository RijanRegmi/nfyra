package com.rjn.nfyra

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.nio.charset.StandardCharsets
import java.util.Arrays

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL_HCE = "com.tramessage/hce"
        private const val CHANNEL_KEYSTORE = "com.tramessage/keystore"
        private const val CHANNEL_NFC_GATE = "com.tramessage/nfc_gate"
        private const val CHANNEL_NFC_RECEIVE = "com.tramessage/nfc_receive"
        private const val TRAMESSAGE_MIME = "application/vnd.tramessage.msg"
    }

    private lateinit var keystoreManager: KeystoreManager
    private lateinit var nfcManager: NfcManager

    private var eventSink: EventChannel.EventSink? = null
    private var pendingPayload: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enforce FLAG_SECURE: block screenshots and screen recorders
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

        keystoreManager = KeystoreManager()
        nfcManager = NfcManager(this)

        // Handle cold-start intent
        intent?.let { handleNfcIntent(it) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Handle warm-start intent
        handleNfcIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. HCE Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_HCE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "armHce" -> {
                        val payloadArg = call.argument<Any>("payload")
                        if (payloadArg is Map<*, *>) {
                            @Suppress("UNCHECKED_CAST")
                            val map = payloadArg as Map<String, Any?>
                            val type = map["type"] as? String ?: "text"
                            val content = map["content"] as? String ?: ""
                            val jsonString = JSONObject(map).toString()
                            HceService.armPayload(type, content, jsonString)
                            result.success(null)
                        } else if (payloadArg is String) {
                            val json = JSONObject(payloadArg)
                            val type = json.optString("type", "text")
                            val content = json.optString("content", "")
                            HceService.armPayload(type, content, payloadArg)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARG", "Payload is null or invalid", null)
                        }
                    }
                    "disarmHce" -> {
                        HceService.disarm()
                        result.success(null)
                    }
                    "isArmed" -> {
                        result.success(HceService.isArmed())
                    }
                    "setAutoShare" -> {
                        val type = call.argument<String>("type") ?: "text"
                        val content = call.argument<String>("content") ?: ""
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        HceService.saveAutoShare(this, type, content, enabled)
                        result.success(null)
                    }
                    "getAutoShare" -> {
                        result.success(HceService.getAutoShare(this))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                            if (powerManager != null && !powerManager.isIgnoringBatteryOptimizations(packageName)) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = Uri.parse("package:$packageName")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("BATTERY_OPT_ERROR", e.message, null)
                        }
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                        val isIgnoring = powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
                        result.success(isIgnoring)
                    }
                    else -> result.notImplemented()
                }
            }

        // 2. Keystore Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_KEYSTORE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getOrCreatePublicKey" -> {
                        try {
                            result.success(keystoreManager.getOrCreatePublicKey())
                        } catch (e: Exception) {
                            result.error("KEYSTORE_ERROR", e.message, null)
                        }
                    }
                    "getKeyId" -> {
                        try {
                            result.success(keystoreManager.getKeyId())
                        } catch (e: Exception) {
                            result.error("KEYSTORE_ERROR", e.message, null)
                        }
                    }
                    "sign" -> {
                        try {
                            val data = call.argument<String>("data") ?: ""
                            result.success(keystoreManager.sign(data))
                        } catch (e: Exception) {
                            result.error("SIGN_ERROR", e.message, null)
                        }
                    }
                    "verify" -> {
                        try {
                            val publicKey = call.argument<String>("publicKey") ?: ""
                            val data = call.argument<String>("data") ?: ""
                            val signature = call.argument<String>("signature") ?: ""
                            val verified = keystoreManager.verify(publicKey, data, signature)
                            result.success(verified)
                        } catch (e: Exception) {
                            result.error("VERIFY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // 3. NFC Gate Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NFC_GATE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkStatus", "checkNfcStatus" -> {
                        result.success(nfcManager.checkStatus())
                    }
                    "openNfcSettings" -> {
                        nfcManager.openNfcSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // 4. NFC Receive EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NFC_RECEIVE)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    pendingPayload?.let {
                        eventSink?.success(it)
                        pendingPayload = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun handleNfcIntent(intent: Intent) {
        val action = intent.action ?: return
        if (action == NfcAdapter.ACTION_NDEF_DISCOVERED || action == NfcAdapter.ACTION_TAG_DISCOVERED) {
            val rawMessages = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
            if (rawMessages != null && rawMessages.isNotEmpty()) {
                val ndefMessage = rawMessages[0] as? NdefMessage ?: return
                val parsed = parseNdefMessage(ndefMessage)
                if (parsed != null) {
                    if (eventSink != null) {
                        eventSink?.success(parsed)
                    } else {
                        pendingPayload = parsed
                    }
                }
            }
        }
    }

    /**
     * Parses NDEF records: prefers the verified Tramessage MIME record,
     * or parses standard Text/URI record if sent from standard devices.
     */
    private fun parseNdefMessage(message: NdefMessage): Map<String, Any?>? {
        var tramessagePayload: Map<String, Any?>? = null
        var fallbackText: String? = null
        var fallbackUri: String? = null

        for (record in message.records) {
            // Check for Tramessage MIME record
            if (record.tnf == NdefRecord.TNF_MIME_MEDIA) {
                val mimeType = String(record.type, StandardCharsets.US_ASCII)
                if (mimeType == TRAMESSAGE_MIME) {
                    try {
                        val jsonStr = String(record.payload, StandardCharsets.UTF_8)
                        val json = JSONObject(jsonStr)
                        val map = mutableMapOf<String, Any?>()
                        val keys = json.keys()
                        while (keys.hasNext()) {
                            val key = keys.next()
                            map[key] = json.get(key)
                        }
                        tramessagePayload = map
                        break
                    } catch (_: Exception) {}
                }
            }

            // Check for standard URI record
            if (record.tnf == NdefRecord.TNF_WELL_KNOWN && Arrays.equals(record.type, NdefRecord.RTD_URI)) {
                val payload = record.payload
                if (payload.isNotEmpty()) {
                    val prefixCode = payload[0].toInt()
                    val prefix = when (prefixCode) {
                        0x01 -> "http://www."
                        0x02 -> "https://www."
                        0x03 -> "http://"
                        0x04 -> "https://"
                        else -> ""
                    }
                    val rest = String(payload, 1, payload.size - 1, StandardCharsets.UTF_8)
                    fallbackUri = prefix + rest
                }
            }

            // Check for standard Text record
            if (record.tnf == NdefRecord.TNF_WELL_KNOWN && Arrays.equals(record.type, NdefRecord.RTD_TEXT)) {
                val payload = record.payload
                if (payload.isNotEmpty()) {
                    val status = payload[0].toInt()
                    val langLen = status and 0x3F
                    if (payload.size > 1 + langLen) {
                        fallbackText = String(payload, 1 + langLen, payload.size - 1 - langLen, StandardCharsets.UTF_8)
                    }
                }
            }
        }

        if (tramessagePayload != null) {
            return tramessagePayload
        }

        if (fallbackUri != null) {
            return mapOf(
                "v" to 1,
                "type" to "link",
                "content" to fallbackUri,
                "createdAt" to java.time.Instant.now().toString(),
                "expiresAt" to java.time.Instant.now().plusSeconds(60).toString(),
                "nonce" to java.util.UUID.randomUUID().toString(),
                "senderKeyId" to "StandardNfcTag",
                "signature" to ""
            )
        }

        if (fallbackText != null) {
            return mapOf(
                "v" to 1,
                "type" to "text",
                "content" to fallbackText,
                "createdAt" to java.time.Instant.now().toString(),
                "expiresAt" to java.time.Instant.now().plusSeconds(60).toString(),
                "nonce" to java.util.UUID.randomUUID().toString(),
                "senderKeyId" to "StandardNfcTag",
                "signature" to ""
            )
        }

        return null
    }
}
