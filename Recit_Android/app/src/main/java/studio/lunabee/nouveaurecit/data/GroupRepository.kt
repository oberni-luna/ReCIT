package studio.lunabee.nouveaurecit.data

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import studio.lunabee.nouveaurecit.data.groups.GroupPeople
import studio.lunabee.nouveaurecit.data.groups.GroupRequestLedger
import studio.lunabee.nouveaurecit.data.groups.GroupRole
import studio.lunabee.nouveaurecit.data.groups.MyGroups
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.GroupByIdDto
import studio.lunabee.nouveaurecit.network.dto.GroupsDto
import kotlin.coroutines.cancellation.CancellationException

/**
 * `GroupModel`: groups of readers on inventaire.io — the ones I belong to, the ones inviting me, the
 * ones I asked to join, and whichever one is open on screen.
 *
 * **In memory, not in Room.** Every group this launch has read is a [ReaderGroup] in [groups], by
 * id: a table would be a schema migration, which this project does not make without asking (iOS
 * made the same choice in its feature 0028). The screens stay reactive all the same — they collect
 * [groups] — and the people in a group are `UserEntity` rows of the store, looked up by id.
 *
 * [myUserId] is `UserRepository`'s: every gesture is made in that reader's name, and every role a
 * screen shows is theirs.
 */
class GroupRepository(
    private val api: ApiService,
    private val people: GroupPeople,
    private val ledger: GroupRequestLedger,
    private val myUserId: StateFlow<String?>,
) {
    private val _groups: MutableStateFlow<Map<String, ReaderGroup>> = MutableStateFlow(emptyMap())

    /** Every group known this launch, by id: mine, and the ones opened from a search. */
    val groups: StateFlow<Map<String, ReaderGroup>> = _groups.asStateFlow()

    private val _hasLoaded: MutableStateFlow<Boolean> = MutableStateFlow(false)

    /**
     * Whether [syncMyGroups] has answered once since sign-in. Until then the Groupes segment says it
     * is loading rather than that there is no group: nothing is kept across launches, so an empty
     * map means nothing before the first answer.
     */
    val hasLoaded: StateFlow<Boolean> = _hasLoaded.asStateFlow()

    /** My groups by section. */
    val myGroups: Flow<MyGroups> = combine(_groups, myUserId) { groups, me -> MyGroups.of(groups.values, me) }

    /** What the Réseau tab's badge adds to the friends' invitations. */
    val pendingCount: Flow<Int> = myGroups.map { it.pendingCount }.distinctUntilChanged()

    fun observeGroup(id: String): Flow<ReaderGroup?> = _groups.map { it[id] }.distinctUntilChanged()

    // Syncing

    /**
     * Reads `GET /api/groups`, then the groups this device asked to join, and puts a name on
     * everyone they mention.
     *
     * The answer replaces what was known of my groups: a group I left on the website, or that
     * removed me, is gone from the segment at the next sync rather than lingering. It stays readable
     * for a screen still open on it, as the server now has it — without me. A request whose read
     * failed is kept as it was: a bad connection does not erase a request.
     */
    suspend fun syncMyGroups(myUserId: String) {
        val answer: GroupsDto = api.get("/api/groups")
        val fresh: MutableMap<String, ReaderGroup> = answer.groups.associate { it.id to ReaderGroup.of(it) }.toMutableMap()

        // The requests are the one role `/api/groups` leaves out. Each is read back: still waiting,
        // it stays; accepted or refused, the ledger forgets it.
        val unread: MutableSet<String> = mutableSetOf()
        for (id in ledger.ids(myUserId).sorted()) {
            if (id in fresh) continue
            try {
                val group: ReaderGroup = readGroup(id)
                if (group.role(of = myUserId) == GroupRole.Requested) fresh[id] = group else ledger.remove(id, myUserId)
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: NetworkError.BadStatus) {
                if (error.code == 404) ledger.remove(id, myUserId) else unread += id
            } catch (_: Exception) {
                unread += id
            }
        }

        // Signed out while the answers were on their way: the next account must not get these.
        check(this.myUserId.value == myUserId) { "The account changed during the groups sync" }

        _groups.update { known ->
            val dropped: Map<String, ReaderGroup> = (known - fresh.keys).mapValues { (id, group) ->
                if (id in unread) group else dropping(myUserId, group)
            }
            dropped + fresh
        }
        _hasLoaded.value = true

        people.fetchMissing(fresh.values.flatMap { it.everyoneIds }.toSet())
    }

    /**
     * Reads one group afresh — the screen of a group, mine or not — and stores the people it names,
     * which `by-id` sends along already shaped as users.
     */
    suspend fun fetchGroup(id: String): ReaderGroup {
        val group: ReaderGroup = readGroup(id)
        _groups.update { it + (id to group) }
        return group
    }

    // Signing out

    /** Leaves nothing of the last account's groups. The ledger is keyed by account, and stays for when they come back. */
    fun reset() {
        _groups.value = emptyMap()
        _hasLoaded.value = false
    }

    // Private

    /** `GET /api/groups/by-id`, with the people it names stored on the way. */
    private suspend fun readGroup(id: String): ReaderGroup {
        val answer: GroupByIdDto = api.get("/api/groups/by-id", "id" to id)
        people.store(answer.users)
        return ReaderGroup.of(answer.group)
    }

    private companion object {
        /**
         * [group] once a sync has stopped naming it among mine: I hold none of the roles that make a
         * group mine any more. A refusal, which the sync does not read, is left as it was.
         */
        fun dropping(userId: String, group: ReaderGroup): ReaderGroup = group.copy(
            admins = group.admins.filter { it.user != userId },
            members = group.members.filter { it.user != userId },
            invited = group.invited.filter { it.user != userId },
            requested = group.requested.filter { it.user != userId },
        )
    }
}
