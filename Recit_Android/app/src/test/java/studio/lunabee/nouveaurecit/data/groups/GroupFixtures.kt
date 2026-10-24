package studio.lunabee.nouveaurecit.data.groups

import studio.lunabee.nouveaurecit.network.dto.UserDto

/** A group in the shape the tests need: every role list given by ids, nobody invited by anyone. */
fun group(
    id: String = "g1",
    name: String = "Club",
    open: Boolean = false,
    admins: List<String> = listOf("admin"),
    members: List<String> = emptyList(),
    invited: List<String> = emptyList(),
    declined: List<String> = emptyList(),
    requested: List<String> = emptyList(),
): ReaderGroup {
    fun list(ids: List<String>): List<GroupMembership> = ids.map { GroupMembership(user = it, invitor = null, timestamp = 0.0) }
    return ReaderGroup(
        id = id,
        name = name,
        open = open,
        admins = list(admins),
        members = list(members),
        invited = list(invited),
        declined = list(declined),
        requested = list(requested),
    )
}

/** `GroupRequestLedger` in memory. */
class InMemoryGroupRequestLedger : GroupRequestLedger {
    val idsByUser: MutableMap<String, Set<String>> = mutableMapOf()

    override suspend fun ids(userId: String): Set<String> = idsByUser[userId].orEmpty()

    override suspend fun add(groupId: String, userId: String) {
        idsByUser[userId] = ids(userId) + groupId
    }

    override suspend fun remove(groupId: String, userId: String) {
        idsByUser[userId] = ids(userId) - groupId
    }
}

/** `GroupPeople` that remembers what it was asked. */
class RecordingGroupPeople : GroupPeople {
    val stored: MutableList<UserDto> = mutableListOf()
    val fetched: MutableSet<String> = mutableSetOf()

    override suspend fun store(users: List<UserDto>) {
        stored += users
    }

    override suspend fun fetchMissing(ids: Set<String>) {
        fetched += ids
    }
}
