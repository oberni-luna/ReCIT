package studio.lunabee.nouveaurecit.data.user

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.add

/**
 * `UserAttributeUpdate`: the body of `PUT /api/user` — one attribute, one value. An absent value is sent as
 * an explicit `null`, which is how `picture` and `position` are taken away: the app's JSON leaves out a
 * Kotlin `null`, and the server would then answer « missing value ». [JsonNull] is written, never left out.
 */
@Serializable
data class UserAttributeUpdate(val attribute: String, val value: JsonElement) {
    companion object {
        fun of(attribute: String, value: String?): UserAttributeUpdate =
            UserAttributeUpdate(attribute, value?.let(::JsonPrimitive) ?: JsonNull)

        /** A switch of the account: `fediversable`, `settings.<group>.<key>`. */
        fun of(attribute: String, value: Boolean): UserAttributeUpdate = UserAttributeUpdate(attribute, JsonPrimitive(value))

        /** A number of the account: `summaryPeriodicity`, in days. */
        fun of(attribute: String, value: Int): UserAttributeUpdate = UserAttributeUpdate(attribute, JsonPrimitive(value))

        /** `position` is `[latitude, longitude]`, or `null` to take it away. */
        fun of(attribute: String, value: Coordinates?): UserAttributeUpdate = UserAttributeUpdate(
            attribute,
            value?.let { buildJsonArray { add(it.latitude); add(it.longitude) } } ?: JsonNull,
        )
    }
}
