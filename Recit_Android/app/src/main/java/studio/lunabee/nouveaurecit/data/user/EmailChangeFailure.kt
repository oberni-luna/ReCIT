package studio.lunabee.nouveaurecit.data.user

import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.ErrorBodyDto

/**
 * What `PUT /api/user` says of an address it refuses, read as the sign-up's live check reads the same
 * server: taken (`this email is already used`) or not an address (`invalid_email`). Any other refusal is not
 * about the address, and is `null`.
 */
object EmailChangeFailure {
    fun of(error: Throwable): FieldAvailability.Outcome? {
        if (error !is NetworkError.BadStatus) return null
        val body: ErrorBodyDto? = try {
            ApiService.DefaultJson.decodeFromString(ErrorBodyDto.serializer(), error.body)
        } catch (_: IllegalArgumentException) {
            null
        }
        val outcome: FieldAvailability.Outcome = FieldAvailability.Outcome.from(error.code, body?.errorName, body?.message ?: error.body)
        return when (outcome) {
            FieldAvailability.Outcome.Taken, FieldAvailability.Outcome.Invalid -> outcome
            FieldAvailability.Outcome.Available, FieldAvailability.Outcome.Undetermined -> null
        }
    }
}
