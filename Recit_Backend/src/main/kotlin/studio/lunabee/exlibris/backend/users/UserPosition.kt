package studio.lunabee.exlibris.backend.users

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

        private fun round(degrees: Double): Double = (degrees * DECIMALS_FACTOR).roundToLong() / DECIMALS_FACTOR
    }
}
