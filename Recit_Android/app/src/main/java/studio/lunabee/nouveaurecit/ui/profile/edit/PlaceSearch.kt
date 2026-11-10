package studio.lunabee.nouveaurecit.ui.profile.edit

import android.content.Context
import android.location.Address
import android.location.Geocoder
import android.os.Build
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import studio.lunabee.nouveaurecit.data.user.Coordinates
import java.io.IOException
import kotlin.coroutines.resume

/**
 * `MKLocalSearch` in « Position » (iOS feature 0055): a town or an address, to move the map to. Android's
 * [Geocoder] needs a backend the phone may not have — none on a phone without Google services — so
 * [isAvailable] says whether to offer the search at all.
 */
class PlaceSearch(context: Context) {
    private val geocoder: Geocoder? = if (Geocoder.isPresent()) Geocoder(context) else null

    val isAvailable: Boolean get() = geocoder != null

    /** The first places matching [query]; none when the geocoder fails or has no answer. */
    suspend fun search(query: String): List<FoundPlace> {
        val geocoder: Geocoder = geocoder ?: return emptyList()
        val text: String = query.trim()
        if (text.isEmpty()) return emptyList()
        val addresses: List<Address> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            suspendCancellableCoroutine { continuation ->
                geocoder.getFromLocationName(
                    text,
                    MAX_RESULTS,
                    object : Geocoder.GeocodeListener {
                        override fun onGeocode(addresses: MutableList<Address>) = continuation.resume(addresses)

                        override fun onError(errorMessage: String?) = continuation.resume(emptyList())
                    },
                )
            }
        } else {
            withContext(Dispatchers.IO) {
                try {
                    @Suppress("DEPRECATION")
                    geocoder.getFromLocationName(text, MAX_RESULTS).orEmpty()
                } catch (_: IOException) {
                    emptyList()
                }
            }
        }
        return addresses
            .filter { it.hasLatitude() && it.hasLongitude() }
            .map { FoundPlace(name = name(it), coordinates = Coordinates(it.latitude, it.longitude)) }
    }

    private fun name(address: Address): String =
        address.getAddressLine(0) ?: listOfNotNull(address.featureName, address.locality, address.countryName).distinct().joinToString(", ")

    private companion object {
        /** As many as iOS lists. */
        const val MAX_RESULTS: Int = 5
    }
}
