package studio.lunabee.nouveaurecit.data.groups

import kotlinx.serialization.json.JsonPrimitive

/**
 * `GroupSetting`: what an admin can change about a group, one attribute at a time — the server's
 * `updatable` list, minus `picture` and `position`, which the app does not offer yet.
 */
sealed interface GroupSetting {
    data class Name(val name: String) : GroupSetting

    data class Description(val description: String) : GroupSetting

    data class Searchable(val searchable: Boolean) : GroupSetting

    data class Open(val open: Boolean) : GroupSetting

    val attribute: String
        get() = when (this) {
            is Name -> "name"
            is Description -> "description"
            is Searchable -> "searchable"
            is Open -> "open"
        }

    /** A string or a boolean on the wire, never an object. */
    val value: JsonPrimitive
        get() = when (this) {
            is Name -> JsonPrimitive(name)
            is Description -> JsonPrimitive(description)
            is Searchable -> JsonPrimitive(searchable)
            is Open -> JsonPrimitive(open)
        }

    /** The group once the setting is written. */
    fun applied(to: ReaderGroup): ReaderGroup = when (this) {
        is Name -> to.copy(name = name)
        is Description -> to.copy(description = description)
        is Searchable -> to.copy(searchable = searchable)
        is Open -> to.copy(open = open)
    }
}
