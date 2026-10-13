package com.rjn.nfyra

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.nio.charset.StandardCharsets
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PublicKey
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.security.spec.X509EncodedKeySpec

class KeystoreManager {

    companion object {
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val KEY_ALIAS = "nfyra_identity_key"
        private const val SIGNATURE_ALGORITHM = "SHA256withECDSA"
    }

    private val keyStore: KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply {
        load(null)
    }

    fun getOrCreatePublicKey(): String {
        var entry = keyStore.getCertificate(KEY_ALIAS)
        if (entry == null) {
            generateKeyPair()
            entry = keyStore.getCertificate(KEY_ALIAS)
        }
        val publicKey = entry.publicKey
        return Base64.encodeToString(publicKey.encoded, Base64.NO_WRAP)
    }

    fun getKeyId(): String {
        return getOrCreatePublicKey()
    }

    private fun generateKeyPair() {
        val keyPairGenerator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            ANDROID_KEYSTORE
        )

        var builder = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)

        // Attempt StrongBox if available on Android 9+ (API 28+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                val strongBoxBuilder = builder.setIsStrongBoxBacked(true)
                keyPairGenerator.initialize(strongBoxBuilder.build())
                keyPairGenerator.generateKeyPair()
                return
            } catch (e: Exception) {
                // StrongBox not supported on this device; fall back to standard TEE
                builder = KeyGenParameterSpec.Builder(
                    KEY_ALIAS,
                    KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
                )
                    .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                    .setDigests(KeyProperties.DIGEST_SHA256)
            }
        }

        keyPairGenerator.initialize(builder.build())
        keyPairGenerator.generateKeyPair()
    }

    fun sign(data: String): String {
        val privateKeyEntry = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry
            ?: throw IllegalStateException("Key alias not found in Keystore")

        val signer = Signature.getInstance(SIGNATURE_ALGORITHM)
        signer.initSign(privateKeyEntry.privateKey)
        signer.update(data.toByteArray(StandardCharsets.UTF_8))
        val signatureBytes = signer.sign()
        return Base64.encodeToString(signatureBytes, Base64.NO_WRAP)
    }

    fun verify(publicKeyBase64: String, data: String, signatureBase64: String): Boolean {
        return try {
            val keyBytes = Base64.decode(publicKeyBase64, Base64.NO_WRAP)
            val keySpec = X509EncodedKeySpec(keyBytes)
            val keyFactory = KeyFactory.getInstance(KeyProperties.KEY_ALGORITHM_EC)
            val pubKey: PublicKey = keyFactory.generatePublic(keySpec)

            val verifier = Signature.getInstance(SIGNATURE_ALGORITHM)
            verifier.initVerify(pubKey)
            verifier.update(data.toByteArray(StandardCharsets.UTF_8))
            val sigBytes = Base64.decode(signatureBase64, Base64.NO_WRAP)
            verifier.verify(sigBytes)
        } catch (e: Exception) {
            false
        }
    }
}

