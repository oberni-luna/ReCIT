package studio.lunabee.nouveaurecit.auth

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Where the session is recorded — the keychain's role in ADR 0008. Bytes in, bytes out, under one
 * key. An interface so that `AuthService` can be tested without a device keystore.
 */
interface SessionVault {
    fun load(): ByteArray?
    fun save(data: ByteArray): Boolean
    fun delete()
}

/**
 * The cookie pair, AES-GCM encrypted under a key that lives in the Android Keystore and never
 * leaves the device, stored in a private `SharedPreferences` file.
 *
 * `SharedPreferences` rather than DataStore because `isLoggedIn()` is read once and synchronously
 * at launch, before the first frame decides between the welcome screen and the tabs.
 *
 * Unlike the iOS keychain, this does not outlive an uninstall: Android has no store that does, and
 * the file is excluded from backup so that a restored device does not inherit somebody's session.
 */
class KeystoreSessionVault(
    context: Context,
    private val name: String,
) : SessionVault {
    private val preferences: SharedPreferences = context.getSharedPreferences(name, Context.MODE_PRIVATE)
    private val keyAlias: String = "$name.key"

    override fun load(): ByteArray? {
        val stored: String = preferences.getString(VALUE, null) ?: return null
        return try {
            val bytes: ByteArray = Base64.getDecoder().decode(stored)
            val iv: ByteArray = bytes.copyOfRange(0, IV_LENGTH)
            val cipher: Cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(TAG_LENGTH, iv))
            cipher.doFinal(bytes.copyOfRange(IV_LENGTH, bytes.size))
        } catch (_: Exception) {
            // An entry that cannot be read is deleted rather than failing again at every launch.
            delete()
            null
        }
    }

    override fun save(data: ByteArray): Boolean = try {
        val cipher: Cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted: ByteArray = cipher.iv + cipher.doFinal(data)
        preferences.edit().putString(VALUE, Base64.getEncoder().encodeToString(encrypted)).commit()
    } catch (_: Exception) {
        false
    }

    override fun delete() {
        preferences.edit().remove(VALUE).commit()
    }

    private fun key(): SecretKey {
        val keyStore: KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (keyStore.getKey(keyAlias, null) as? SecretKey)?.let { return it }
        val generator: KeyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(keyAlias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build(),
        )
        return generator.generateKey()
    }

    private companion object {
        const val ANDROID_KEYSTORE: String = "AndroidKeyStore"
        const val TRANSFORMATION: String = "AES/GCM/NoPadding"
        const val VALUE: String = "cookies"
        const val IV_LENGTH: Int = 12
        const val TAG_LENGTH: Int = 128
    }
}
