package studio.lunabee.nouveaurecit.data.groups

import studio.lunabee.nouveaurecit.data.UserPreferences

/**
 * `GroupRequestLedger`: the groups I have asked to join, remembered on the device.
 *
 * `GET /api/groups` answers with the groups where I am admin, member or invited — never those where
 * I am `requested`. Without a note of them, a request sent today would vanish from the Groupes
 * segment at the next launch while it still waits on an admin. The ledger keeps their ids, per
 * account, and the sync reads each one back with `by-id` to see where it stands.
 *
 * Ids only, and only what this device sent: a request made on the website is not known here until
 * it is answered.
 */
interface GroupRequestLedger {
    suspend fun ids(userId: String): Set<String>

    suspend fun add(groupId: String, userId: String)

    suspend fun remove(groupId: String, userId: String)
}

/** The ledger in the user's preferences, under `groups.requested.<user id>`. */
class PreferencesGroupRequestLedger(private val preferences: UserPreferences) : GroupRequestLedger {
    override suspend fun ids(userId: String): Set<String> = preferences.observeStringsOnce(key(userId)).toSet()

    override suspend fun add(groupId: String, userId: String) = write(ids(userId) + groupId, userId)

    override suspend fun remove(groupId: String, userId: String) = write(ids(userId) - groupId, userId)

    private suspend fun write(ids: Set<String>, userId: String) {
        preferences.setStrings(key(userId), ids.sorted())
    }

    private fun key(userId: String): String = "groups.requested.$userId"
}
