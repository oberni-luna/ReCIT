package studio.lunabee.exlibris.backend.auth

import com.password4j.Argon2Function
import com.password4j.Password
import com.password4j.types.Argon2
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * argon2id with OWASP's minimum (19 MiB, two passes, one lane), off the event loop. A hash carries its own
 * parameters, so raising them later leaves every existing password verifiable.
 */
class PasswordHasher {
    private val argon2: Argon2Function =
        Argon2Function.getInstance(MEMORY_KIB, ITERATIONS, PARALLELISM, HASH_BYTES, Argon2.ID)

    suspend fun hash(password: String): String =
        withContext(Dispatchers.Default) {
            Password
                .hash(password)
                .addRandomSalt(SALT_BYTES)
                .with(argon2)
                .result
        }

    suspend fun verify(
        password: String,
        hash: String,
    ): Boolean =
        withContext(Dispatchers.Default) {
            Password.check(password, hash).with(Argon2Function.getInstanceFromHash(hash))
        }

    private companion object {
        const val MEMORY_KIB: Int = 19_456
        const val ITERATIONS: Int = 2
        const val PARALLELISM: Int = 1
        const val HASH_BYTES: Int = 32
        const val SALT_BYTES: Int = 16
    }
}
