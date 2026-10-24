package studio.lunabee.nouveaurecit.data

import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import studio.lunabee.nouveaurecit.data.groups.GroupAction
import studio.lunabee.nouveaurecit.data.groups.GroupPeople
import studio.lunabee.nouveaurecit.data.groups.GroupRequestLedger
import studio.lunabee.nouveaurecit.data.groups.GroupRole
import studio.lunabee.nouveaurecit.data.groups.GroupSearchResult
import studio.lunabee.nouveaurecit.data.groups.GroupSetting
import studio.lunabee.nouveaurecit.data.groups.GroupTransitionError
import studio.lunabee.nouveaurecit.data.groups.MyGroups
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.ImageUrl
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.GroupActionPayload
import studio.lunabee.nouveaurecit.network.dto.GroupByIdDto
import studio.lunabee.nouveaurecit.network.dto.GroupCreationPayload
import studio.lunabee.nouveaurecit.network.dto.GroupDto
import studio.lunabee.nouveaurecit.network.dto.GroupSearchResultsDto
import studio.lunabee.nouveaurecit.network.dto.GroupSettingPayload
import studio.lunabee.nouveaurecit.network.dto.GroupsDto
import studio.lunabee.nouveaurecit.network.dto.OkStatusDto
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
 * **Writes are optimistic** (ADR 0001): a gesture is applied to the group first, through the same
 * transition the server runs ([ReaderGroup.applying]), then sent by the [runner]; a refusal puts the
 * previous value back and speaks through the snackbar. Creating a group is the exception — see
 * [createGroup].
 *
 * [myUserId] is `UserRepository`'s: every gesture is made in that reader's name, and every role a
 * screen shows is theirs.
 */
class GroupRepository(
    private val api: ApiService,
    private val people: GroupPeople,
    private val ledger: GroupRequestLedger,
    private val runner: OptimisticRunner,
    private val errorReporter: ErrorReporter,
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

    /** Groups whose name or description matches, best match first. Only the searchable ones: the server leaves the others out. */
    suspend fun searchGroups(query: String, limit: Int = 20): List<GroupSearchResult> {
        val trimmed: String = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        val answer: GroupSearchResultsDto = api.get("/api/search", "types" to "groups", "search" to trimmed, "limit" to "$limit")
        return answer.results
            .sortedByDescending { it.score ?: 0.0 }
            .map { GroupSearchResult(id = it.id, name = it.label, description = it.description, pictureUrl = ImageUrl.absolute(it.image)) }
    }

    // Membership writes

    /**
     * Makes one membership gesture, in my name, optimistically. [target] is the other person, for the
     * gestures about someone else.
     *
     * The gesture is checked against the group as it stands before anything moves: one the server
     * would refuse — inviting someone who declined, leaving as the last admin — is reported and goes
     * no further, instead of flashing a state that will be taken back.
     *
     * @return The request's job, for the tests; `null` when nothing was sent.
     */
    suspend fun perform(action: GroupAction, groupId: String, target: String? = null): Job? {
        val me: String = myUserId.value ?: return null
        val current: ReaderGroup = _groups.value[groupId] ?: return null
        val next: ReaderGroup = try {
            current.applying(action, by = me, on = target)
        } catch (error: GroupTransitionError) {
            errorReporter.report(error)
            return null
        }
        return runner.run(
            apply = { _groups.update { it + (groupId to next) } },
            revert = { _groups.update { it + (groupId to current) } },
            request = {
                api.send<GroupActionPayload, OkStatusDto>(
                    path = "/api/groups/${action.path}",
                    method = "PUT",
                    body = GroupActionPayload(group = groupId, user = target.takeIf { action.targetsAnotherUser }),
                )
            },
            reconcile = {
                // Only a request that is still waiting needs remembering: a request to an open group
                // let me straight in, and `/api/groups` will name it from now on.
                if (action == GroupAction.Request && next.role(of = me) == GroupRole.Requested) {
                    ledger.add(groupId, me)
                } else if (action == GroupAction.CancelRequest) {
                    ledger.remove(groupId, me)
                }
            },
            // Signed out meanwhile: the groups are someone else's, or nobody's.
            stillThere = { myUserId.value == me && groupId in _groups.value },
        )
    }

    // Creating and settings

    /**
     * Starts a group, with me as its only admin, and answers it once the server has.
     *
     * **Not optimistic**, unlike every other write here. The server limits creations, runs a spam
     * check on the name and the description, and makes up the slug; a placeholder shown at once
     * would too often have to be taken back, and the screen the form leads to needs the id the
     * server gives.
     */
    suspend fun createGroup(name: String, description: String, searchable: Boolean, open: Boolean): ReaderGroup {
        val dto: GroupDto = api.send(
            path = "/api/groups",
            body = GroupCreationPayload(name = name.trim(), description = description.trim(), searchable = searchable, open = open),
        )
        val group: ReaderGroup = ReaderGroup.of(dto)
        _groups.update { it + (group.id to group) }
        return group
    }

    /**
     * Writes one setting, optimistically. `update-settings` takes one attribute per call, so a form
     * that changed two sends two.
     *
     * @return The request's job, for the tests; `null` when nothing changed.
     */
    suspend fun update(setting: GroupSetting, groupId: String): Job? {
        val current: ReaderGroup = _groups.value[groupId] ?: return null
        val next: ReaderGroup = setting.applied(to = current)
        if (next == current) return null
        return runner.run(
            apply = { _groups.update { it + (groupId to next) } },
            revert = { _groups.update { it + (groupId to current) } },
            request = {
                api.send<GroupSettingPayload, OkStatusDto>(
                    path = "/api/groups/update-settings",
                    method = "PUT",
                    body = GroupSettingPayload(group = groupId, attribute = setting.attribute, value = setting.value),
                )
            },
            stillThere = { groupId in _groups.value },
        )
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
