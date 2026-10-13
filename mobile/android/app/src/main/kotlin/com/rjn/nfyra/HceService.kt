package com.rjn.nfyra

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import java.nio.charset.StandardCharsets
import java.util.Arrays

class HceService : HostApduService() {

    companion object {
        private const val TAG = "NfyraHceService"

        // Status words
        private val STATUS_SUCCESS = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val STATUS_FAILED = byteArrayOf(0x6F.toByte(), 0x00.toByte())
        private val STATUS_FILE_NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())

        // APDU command templates
        // SELECT AID: Type 4 NDEF tag application v2.0 (D2760000850101)
        private val AID_NDEF_APPLICATION_V2 = byteArrayOf(
            0xD2.toByte(), 0x76.toByte(), 0x00.toByte(), 0x00.toByte(),
            0x85.toByte(), 0x01.toByte(), 0x01.toByte()
        )
        // SELECT AID: Type 4 NDEF tag application v1.0 (D2760000850100)
        private val AID_NDEF_APPLICATION_V1 = byteArrayOf(
            0xD2.toByte(), 0x76.toByte(), 0x00.toByte(), 0x00.toByte(),
            0x85.toByte(), 0x01.toByte(), 0x00.toByte()
        )
        // Custom Nfyra AID: F04E464354524D01
        private val AID_TRAMESSAGE = byteArrayOf(
            0xF0.toByte(), 0x4E.toByte(), 0x46.toByte(), 0x43.toByte(),
            0x54.toByte(), 0x52.toByte(), 0x4D.toByte(), 0x01.toByte()
        )

        // File IDs
        private val CC_FILE_ID = byteArrayOf(0xE1.toByte(), 0x03.toByte())
        private val NDEF_FILE_ID = byteArrayOf(0xE1.toByte(), 0x04.toByte())

        // Capability Container (CC) file (15 bytes)
        // CCLEN: 00 0F, Mapping Version: 20, MLe: 00 7F, MLc: 00 7F
        // NDEF File Control TLV: T=04, L=06, File ID: E1 04, Max size: 04 00 (1024 B), Read: 00 (granted), Write: 00 (granted)
        private val CC_FILE_BYTES = byteArrayOf(
            0x00, 0x0F,
            0x20,
            0x00, 0x7F,
            0x00, 0x7F,
            0x04, 0x06,
            0xE1.toByte(), 0x04.toByte(),
            0x04, 0x00,
            0x00,
            0x00
        )

        private const val PREFS_AUTO_SHARE = "nfyra_auto_share"
        private const val KEY_AUTO_ENABLED = "auto_share_enabled"
        private const val KEY_AUTO_TYPE = "auto_share_type"
        private const val KEY_AUTO_CONTENT = "auto_share_content"

        @Volatile
        var isAutoShareMode: Boolean = false

        // Armed state held in RAM
        @Volatile
        private var ndefFileBytes: ByteArray? = null

        @Volatile
        var onReadListener: (() -> Unit)? = null

        fun saveAutoShare(context: android.content.Context, type: String, content: String, enabled: Boolean) {
            val prefs = context.getSharedPreferences(PREFS_AUTO_SHARE, android.content.Context.MODE_PRIVATE)
            prefs.edit()
                .putBoolean(KEY_AUTO_ENABLED, enabled)
                .putString(KEY_AUTO_TYPE, type)
                .putString(KEY_AUTO_CONTENT, content)
                .apply()
            isAutoShareMode = enabled
            if (enabled && content.isNotEmpty()) {
                armPayload(type, content, "")
                Log.d(TAG, "AutoShare armed in background mode")
            } else if (!enabled) {
                disarm()
            }
        }

        fun getAutoShare(context: android.content.Context): Map<String, Any> {
            val prefs = context.getSharedPreferences(PREFS_AUTO_SHARE, android.content.Context.MODE_PRIVATE)
            return mapOf(
                "enabled" to prefs.getBoolean(KEY_AUTO_ENABLED, false),
                "type" to (prefs.getString(KEY_AUTO_TYPE, "text") ?: "text"),
                "content" to (prefs.getString(KEY_AUTO_CONTENT, "") ?: "")
            )
        }

        fun checkAndLoadAutoShare(context: android.content.Context): ByteArray? {
            if (ndefFileBytes != null) return ndefFileBytes
            val prefs = context.getSharedPreferences(PREFS_AUTO_SHARE, android.content.Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean(KEY_AUTO_ENABLED, false)
            if (enabled) {
                val type = prefs.getString(KEY_AUTO_TYPE, "text") ?: "text"
                val content = prefs.getString(KEY_AUTO_CONTENT, "") ?: ""
                if (content.isNotEmpty()) {
                    isAutoShareMode = true
                    armPayload(type, content, "")
                    return ndefFileBytes
                }
            }
            return null
        }

        /**
         * Arms the HCE service with a standard universal NDEF message.
         * Works seamlessly with Android Tag Viewer, iPhone Safari, and Nfyra.
         */
        fun armPayload(type: String, content: String, rawJsonPayload: String = "") {
            val ndefMessage = buildUniversalNdefMessage(type, content)
            val len = ndefMessage.size
            val file = ByteArray(2 + len)
            file[0] = ((len shr 8) and 0xFF).toByte()
            file[1] = (len and 0xFF).toByte()
            System.arraycopy(ndefMessage, 0, file, 2, len)
            ndefFileBytes = file
            Log.d(TAG, "HCE armed with ${file.size} bytes: type=$type, content=$content")
        }

        /**
         * Disarms the HCE service and wipes payload from memory.
         */
        fun disarm() {
            isAutoShareMode = false
            ndefFileBytes?.let { Arrays.fill(it, 0.toByte()) }
            ndefFileBytes = null
            Log.d(TAG, "HCE disarmed and memory zeroed")
        }

        fun isArmed(): Boolean = ndefFileBytes != null

        /**
         * Builds a standard NFC Forum NDEF message (single record: URI or Text):
         * - For links: TNF 0x01 (Well-Known), RTD 'U' -> Native iOS & Android trigger browser!
         * - For text: TNF 0x01 (Well-Known), RTD 'T' -> Native Android Tag Viewer displays text!
         */
        private fun buildUniversalNdefMessage(type: String, content: String): ByteArray {
            if (type == "link" && content.startsWith("https://", ignoreCase = true)) {
                val uriBody = content.substring("https://".length).toByteArray(StandardCharsets.UTF_8)
                val payload = ByteArray(1 + uriBody.size)
                payload[0] = 0x04 // https:// identifier code
                System.arraycopy(uriBody, 0, payload, 1, uriBody.size)

                return createNdefRecord(
                    tnf = 0x01, // Well-Known
                    type = byteArrayOf(0x55), // 'U'
                    id = ByteArray(0),
                    payload = payload,
                    isFirst = true,
                    isLast = true
                )
            } else {
                val textBytes = content.toByteArray(StandardCharsets.UTF_8)
                val langBytes = "en".toByteArray(StandardCharsets.US_ASCII)
                val payload = ByteArray(1 + langBytes.size + textBytes.size)
                payload[0] = langBytes.size.toByte() // Status byte (lang length)
                System.arraycopy(langBytes, 0, payload, 1, langBytes.size)
                System.arraycopy(textBytes, 0, payload, 1 + langBytes.size, textBytes.size)

                return createNdefRecord(
                    tnf = 0x01, // Well-Known
                    type = byteArrayOf(0x54), // 'T'
                    id = ByteArray(0),
                    payload = payload,
                    isFirst = true,
                    isLast = true
                )
            }
        }

        private fun createNdefRecord(
            tnf: Byte,
            type: ByteArray,
            id: ByteArray,
            payload: ByteArray,
            isFirst: Boolean,
            isLast: Boolean
        ): ByteArray {
            val isShortRecord = payload.size <= 255
            var header = (tnf.toInt() and 0x07)
            if (isFirst) header = header or 0x80 // Message Begin (MB)
            if (isLast) header = header or 0x40  // Message End (ME)
            if (isShortRecord) header = header or 0x10 // Short Record (SR)
            if (id.isNotEmpty()) header = header or 0x08 // ID Length present (IL)

            val headerSize = 1 + 1 + (if (isShortRecord) 1 else 4) + (if (id.isNotEmpty()) 1 else 0)
            val recordSize = headerSize + type.size + id.size + payload.size
            val record = ByteArray(recordSize)

            var offset = 0
            record[offset++] = header.toByte()
            record[offset++] = type.size.toByte()

            if (isShortRecord) {
                record[offset++] = payload.size.toByte()
            } else {
                record[offset++] = ((payload.size shr 24) and 0xFF).toByte()
                record[offset++] = ((payload.size shr 16) and 0xFF).toByte()
                record[offset++] = ((payload.size shr 8) and 0xFF).toByte()
                record[offset++] = (payload.size and 0xFF).toByte()
            }

            if (id.isNotEmpty()) {
                record[offset++] = id.size.toByte()
            }

            System.arraycopy(type, 0, record, offset, type.size)
            offset += type.size

            if (id.isNotEmpty()) {
                System.arraycopy(id, 0, record, offset, id.size)
                offset += id.size
            }

            System.arraycopy(payload, 0, record, offset, payload.size)
            return record
        }
    }

    private var selectedFile: ByteArray? = null

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null || commandApdu.size < 4) {
            return STATUS_FAILED
        }

        val cla = commandApdu[0]
        val ins = commandApdu[1]
        val p1 = commandApdu[2]
        val p2 = commandApdu[3]

        // 1. SELECT command (INS = A4)
        if (ins == 0xA4.toByte()) {
            if (p1 == 0x04.toByte()) {
                // SELECT BY AID
                val lc = if (commandApdu.size > 4) commandApdu[4].toInt() and 0xFF else 0
                if (commandApdu.size >= 5 + lc) {
                    val aid = ByteArray(lc)
                    System.arraycopy(commandApdu, 5, aid, 0, lc)
                    if (aid.contentEquals(AID_NDEF_APPLICATION_V2) ||
                        aid.contentEquals(AID_NDEF_APPLICATION_V1) ||
                        aid.contentEquals(AID_TRAMESSAGE)) {
                        Log.d(TAG, "Application selected: success")
                        selectedFile = null
                        return STATUS_SUCCESS
                    }
                }
            } else if (p1 == 0x00.toByte()) {
                // SELECT FILE
                val lc = if (commandApdu.size > 4) commandApdu[4].toInt() and 0xFF else 0
                if (commandApdu.size >= 5 + lc && lc == 2) {
                    val fileId = ByteArray(2)
                    System.arraycopy(commandApdu, 5, fileId, 0, 2)
                    if (fileId.contentEquals(CC_FILE_ID)) {
                        Log.d(TAG, "CC file selected")
                        selectedFile = CC_FILE_BYTES
                        return STATUS_SUCCESS
                    } else if (fileId.contentEquals(NDEF_FILE_ID)) {
                        Log.d(TAG, "NDEF file selected")
                        checkAndLoadAutoShare(this)
                        selectedFile = ndefFileBytes
                        return STATUS_SUCCESS
                    }
                }
            }
            return STATUS_FILE_NOT_FOUND
        }

        // 2. READ BINARY command (INS = B0)
        if (ins == 0xB0.toByte()) {
            val offset = ((p1.toInt() and 0xFF) shl 8) or (p2.toInt() and 0xFF)
            val le = if (commandApdu.size > 4) commandApdu[4].toInt() and 0xFF else 0

            val currentFile = selectedFile
            if (currentFile == null) {
                return STATUS_FILE_NOT_FOUND
            }

            if (offset >= currentFile.size) {
                return STATUS_FAILED
            }

            var length = if (le == 0) currentFile.size - offset else le
            if (offset + length > currentFile.size) {
                length = currentFile.size - offset
            }

            val response = ByteArray(length + 2)
            System.arraycopy(currentFile, offset, response, 0, length)
            response[length] = 0x90.toByte()
            response[length + 1] = 0x00.toByte()

            // If reading the NDEF file was completed, notify listener & auto-disarm if NOT persistent auto-share
            if (currentFile == ndefFileBytes && (offset + length >= currentFile.size)) {
                Log.d(TAG, "NDEF transfer complete, notifying reader")
                if (!isAutoShareMode) {
                    onReadListener?.invoke()
                }
            }

            return response
        }

        return STATUS_FAILED
    }

    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "HCE deactivated: reason $reason")
        selectedFile = null
    }
}

