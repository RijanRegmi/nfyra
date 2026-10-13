package com.rjn.nfyra

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.provider.Settings

class NfcManager(private val context: Context) {

    fun checkStatus(): Map<String, Boolean> {
        val adapter = NfcAdapter.getDefaultAdapter(context)
        val hasHardware = adapter != null
        val isEnabled = adapter?.isEnabled == true
        val hasHce = context.packageManager.hasSystemFeature(
            PackageManager.FEATURE_NFC_HOST_CARD_EMULATION
        )

        return mapOf(
            "hasHardware" to hasHardware,
            "isEnabled" to isEnabled,
            "hasHce" to hasHce
        )
    }

    fun openNfcSettings() {
        val intent = Intent(Settings.ACTION_NFC_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        if (intent.resolveActivity(context.packageManager) != null) {
            context.startActivity(intent)
        } else {
            // Fall back to wireless settings
            val fallbackIntent = Intent(Settings.ACTION_WIRELESS_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(fallbackIntent)
        }
    }
}
