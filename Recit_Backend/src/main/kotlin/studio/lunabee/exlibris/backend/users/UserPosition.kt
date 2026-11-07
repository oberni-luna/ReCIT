package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import kotlin.math.roundToLong

/** Where a reader says they are, in degrees; inventaire.io sends it as `[latitude, longitude]`. */
data class UserPosition(
    val latitude: Double,
    val longitude: Double,
) {
    fun toList(): List<Double> = listOf(latitude, longitude)

    companion object {
        private const val DECIMALS_FACTOR: Double = 100_000.0

        /** inventaire.io's `truncateLatLng`: five decimals, a metre or so, are all it keeps. */
        fun truncated(
            latitude: Double,
            longitude: Double,
        ): UserPosition = UserPosition(round(latitude), round(longitude))

        /** Two numbers, `[latitude, longitude]`, truncated: inventaire.io checks nothing more. `null` otherwise. */
        fun fromJson(value: JsonElement): UserPosition? {
            val degrees: List<Double?> =
                (value as? JsonArray)
                    ?.map { (it as? JsonPrimitive)?.takeIf { degree -> !degree.isString }?.doubleOrNull }
                    .orEmpty()
            val latitude: Double? = degrees.firstOrNull()
            val longitude: Double? = degrees.lastOrNull()
            return if (degrees.size == 2 && latitude != null && longitude != null) {
                truncated(latitude, longitude)
            } else {
                null
            }
        }

        private fun round(degrees: Double): Double = (degrees * DECIMALS_FACTOR).roundToLong() / DECIMALS_FACTOR
    }
}
