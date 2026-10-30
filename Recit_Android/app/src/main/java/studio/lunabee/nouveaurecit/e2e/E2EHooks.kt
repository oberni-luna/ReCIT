package studio.lunabee.nouveaurecit.e2e

import android.content.Intent
import studio.lunabee.nouveaurecit.BuildConfig

/**
 * `UITestHooks`: the seams the end-to-end scenario (`Recit_Android/e2e/`, feature 0065) needs in the
 * app, inert unless the activity is started with [EXTRA_BARCODES], and inert in a release build
 * whatever it is started with.
 *
 * The emulator's camera films a virtual room, not a book, so the scanner cannot read a barcode there.
 * Under the scenario it reads the ones it was handed instead, one after the other — see
 * [E2EBarcodeFeed].
 */
object E2EHooks {
    const val EXTRA_BARCODES: String = "e2e.barcodes"

    /** The barcodes the scanner « sees », in order. Empty outside the scenario. */
    var barcodes: List<String> = emptyList()
        private set

    val isScanningScripted: Boolean get() = barcodes.isNotEmpty()

    fun read(intent: Intent?) {
        if (!BuildConfig.DEBUG) return
        val codes: String = intent?.getStringExtra(EXTRA_BARCODES) ?: return
        barcodes = codes.split(',').map(String::trim).filter(String::isNotEmpty)
    }
}
