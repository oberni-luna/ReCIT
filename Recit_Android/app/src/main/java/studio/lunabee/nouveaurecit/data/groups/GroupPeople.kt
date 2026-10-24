package studio.lunabee.nouveaurecit.data.groups

import studio.lunabee.nouveaurecit.network.dto.UserDto

/**
 * Where the people a group names are kept: the store's users, so every line of a group's screens
 * can carry a name and a picture. `UserRepository` is the one implementation; the tests use a
 * recording one.
 */
interface GroupPeople {
    /** Readers a `by-id` answer sends along, already shaped as users. */
    suspend fun store(users: List<UserDto>)

    /** Fetches whoever among [ids] the store does not hold yet. */
    suspend fun fetchMissing(ids: Set<String>)
}
