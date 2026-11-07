package studio.lunabee.nouveaurecit.network

import android.content.Intent
import studio.lunabee.nouveaurecit.BuildConfig

/**
 * iOS `Env`'s `-ExLibrisBackend`: a debug build started with `-e exLibrisBackend http://10.0.2.2:8080`
 * talks to that backend instead of inventaire.io, under a session store of its own so neither session
 * overwrites the other. Inert in a release build whatever it is started with.
 *
 * Read by `MainActivity` before the container is built. Only the process's first launch counts: the
 * container is built once, so `adb shell am start -S …` to switch.
 */
object BackendOverride {
    const val EXTRA: String = "exLibrisBackend"
    private const val INVENTAIRE_URL: String = "https://inventaire.io"
    private const val SESSION_STORE_SUFFIX: String = ".exlibris"

    private var override: String? = null
    private var hasRead: Boolean = false

    val baseUrl: String get() = baseUrlFor(override)

    fun sessionStoreName(name: String): String = sessionStoreNameFor(name, override)

    fun read(intent: Intent?) {
        if (hasRead || !BuildConfig.DEBUG) return
        hasRead = true
        override = intent?.getStringExtra(EXTRA)?.takeIf(String::isNotBlank)
    }

    internal fun baseUrlFor(override: String?): String = override ?: INVENTAIRE_URL

    internal fun sessionStoreNameFor(name: String, override: String?): String =
        if (override == null) name else "$name$SESSION_STORE_SUFFIX"
}
