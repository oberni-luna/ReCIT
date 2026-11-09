package studio.lunabee.nouveaurecit.data.groups

import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import studio.lunabee.nouveaurecit.network.ImageUrl

/**
 * `GroupSetting`: what an admin can change about a group, one attribute at a time — the server's
 * `updatable` list, minus `position`, which the app does not offer yet.
 */
sealed interface GroupSetting {
    data class Name(val name: String) : GroupSetting

    data class Description(val description: String) : GroupSetting

    data class Searchable(val searchable: Boolean) : GroupSetting

    data class Open(val open: Boolean) : GroupSetting

    /**
     * The path the server filed the picture under, `/img/groups/<hash>` — the only shape it accepts.
     * `null` takes the picture away.
     */
    data class Picture(val path: String?) : GroupSetting

    val attribute: String
        get() = when (this) {
            is Name -> "name"
            is Description -> "description"
            is Searchable -> "searchable"
            is Open -> "open"
            is Picture -> "picture"
        }

    /** A string, a boolean or `null` on the wire, never an object. */
    val value: JsonPrimitive
        get() = when (this) {
            is Name -> JsonPrimitive(name)
            is Description -> JsonPrimitive(description)
            is Searchable -> JsonPrimitive(searchable)
            is Open -> JsonPrimitive(open)
            is Picture -> path?.let(::JsonPrimitive) ?: JsonNull
        }

    /** The group once the setting is written. A picture is kept as the address it is fetched at, the server keeps its path. */
    fun applied(to: ReaderGroup): ReaderGroup = when (this) {
        is Name -> to.copy(name = name)
        is Description -> to.copy(description = description)
        is Searchable -> to.copy(searchable = searchable)
        is Open -> to.copy(open = open)
        is Picture -> to.copy(pictureUrl = ImageUrl.absolute(path))
    }

    /**
     * [on] with this setting's attribute as [from] held it, every other attribute as it stands —
     * `GroupSetting.held(by:)`: what a refusal puts back, so that it never undoes another write that
     * landed during the round trip.
     */
    fun restored(on: ReaderGroup, from: ReaderGroup): ReaderGroup = when (this) {
        is Name -> on.copy(name = from.name)
        is Description -> on.copy(description = from.description)
        is Searchable -> on.copy(searchable = from.searchable)
        is Open -> on.copy(open = from.open)
        is Picture -> on.copy(pictureUrl = from.pictureUrl)
    }
}
