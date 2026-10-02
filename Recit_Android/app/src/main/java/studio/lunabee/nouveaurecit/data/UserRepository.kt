package studio.lunabee.nouveaurecit.data

import androidx.room.withTransaction
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import studio.lunabee.nouveaurecit.data.db.AppDatabase
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.OkStatusDto
import studio.lunabee.nouveaurecit.network.dto.RelationActionPayload
import studio.lunabee.nouveaurecit.network.dto.UserDto
import studio.lunabee.nouveaurecit.network.dto.UserNetworkDto
import studio.lunabee.nouveaurecit.network.dto.UserSearchResultsDto
import studio.lunabee.nouveaurecit.network.dto.UsersDto

/** `UserModel`: me, the readers I know, the relations between us, and the account itself. */
class UserRepository(
    private val api: ApiService,
    private val db: AppDatabase,
    private val runner: OptimisticRunner,
) {
    private val dao = db.userDao()

    private val _myUserId: MutableStateFlow<String?> = MutableStateFlow(null)

    /** `myUser`'s id, once `GET /api/user` has answered since launch. */
    val myUserId: StateFlow<String?> = _myUserId.asStateFlow()

    val myUser: Flow<UserEntity?> = _myUserId.flatMapLatest { id -> id?.let(dao::observe) ?: flowOf(null) }

    fun observeUser(id: String): Flow<UserEntity?> = dao.observe(id)

    fun observeByRelation(relation: UserRelation): Flow<List<UserEntity>> =
        _myUserId.flatMapLatest { id -> dao.observeByRelation(id.orEmpty(), relation) }

    /** What the Réseau tab's badge counts: the invitations waiting on an answer from me. */
    val receivedRequestCount: Flow<Int> = _myUserId.flatMapLatest { id -> dao.observeReceivedRequestCount(id.orEmpty()) }

    suspend fun myUser(): UserEntity? = _myUserId.value?.let { dao.get(it) }

    suspend fun syncMyUser() {
        val dto: UserDto = api.get("/api/user")
        dao.upsert(listOf(Merges.user(dao.get(dto.id), dto, ApiService.BASE_URL)))
        _myUserId.value = dto.id
    }

    suspend fun getOrFetchUsers(ids: List<String>): List<UserEntity> {
        if (ids.isEmpty()) return emptyList()
        val dtos: Collection<UserDto> = ids.distinct().chunked(50).flatMap { batch ->
            api.get<UsersDto>("/api/users/by-ids", "ids" to batch.joinToString("|")).users.values
        }
        val existing: Map<String, UserEntity> = dao.get(dtos.map { it.id }).associateBy { it.id }
        val merged: List<UserEntity> = dtos.map { Merges.user(existing[it.id], it, ApiService.BASE_URL) }
        dao.upsert(merged)
        return merged
    }

    suspend fun syncRelations() {
        val myId: String = _myUserId.value ?: return
        val network: UserNetworkDto = api.get("/api/relations")
        val states: Map<String, UserRelation> = relationsById(network)
        val ids: List<String> = (network.network + states.keys).distinct().filter { it != myId }
        getOrFetchUsers(ids)
        db.withTransaction {
            for (user in dao.all()) {
                dao.setRelation(user.id, if (user.id == myId) UserRelation.None else states[user.id] ?: UserRelation.None)
            }
        }
    }

    /** `/api/search?types=users`, best match first, me left out, returned in the server's order. */
    suspend fun searchReaders(query: String, limit: Int = 15): List<UserEntity> {
        val trimmed: String = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        val response: UserSearchResultsDto = api.get("/api/search", "types" to "users", "search" to trimmed, "limit" to "$limit")
        val ids: List<String> = response.results
            .sortedByDescending { it.score ?: 0.0 }
            .map { it.id }
            .filter { it != _myUserId.value }
        val byId: Map<String, UserEntity> = getOrFetchUsers(ids).associateBy { it.id }
        return ids.mapNotNull(byId::get)
    }

    suspend fun requestRelation(userId: String) = changeRelation(userId, UserRelation.RequestSent, "request")

    suspend fun cancelRelation(userId: String) = changeRelation(userId, UserRelation.None, "cancel")

    suspend fun acceptRelation(userId: String, onAccepted: suspend () -> Unit = {}) =
        changeRelation(userId, UserRelation.Friend, "accept", onAccepted)

    suspend fun discardRelation(userId: String) = changeRelation(userId, UserRelation.None, "discard")

    suspend fun unfriend(userId: String) = changeRelation(userId, UserRelation.None, "unfriend") {
        db.withTransaction {
            db.inventoryDao().deleteOwnedBy(userId)
            db.shelfDao().deleteOwnedBy(userId)
            dao.setLastInventorySync(userId, null)
        }
    }

    private suspend fun changeRelation(
        userId: String,
        to: UserRelation,
        action: String,
        reconcile: suspend () -> Unit = {},
    ) {
        val previous: UserRelation = dao.get(userId)?.relation ?: UserRelation.None
        runner.run(
            apply = { dao.setRelation(userId, to) },
            revert = { dao.setRelation(userId, previous) },
            request = { api.send<RelationActionPayload, OkStatusDto>("/api/relations/$action", body = RelationActionPayload(userId)) },
            reconcile = reconcile,
            stillThere = { dao.get(userId) != null },
        )
    }

    suspend fun friends(): List<UserEntity> {
        val myId: String? = _myUserId.value
        return dao.all().filter { it.id != myId && it.relation == UserRelation.Friend }
    }

    suspend fun setLastInventorySync(userId: String, value: Double?) = dao.setLastInventorySync(userId, value)

    /** `DELETE /api/user`, then the whole local store — only once the server has said `ok`. */
    suspend fun deleteAccount() {
        val response: OkStatusDto = api.sendEmpty("/api/user", "DELETE")
        if (!response.ok) throw NetworkError.BadResponse()
        wipeLocalStore(includingEntities = true)
    }

    /** Signing out forgets the user and keeps the books (feature 0025). */
    suspend fun wipeUserData() = wipeLocalStore(includingEntities = false)

    private suspend fun wipeLocalStore(includingEntities: Boolean) {
        _myUserId.value = null
        db.withTransaction {
            db.inventoryDao().deleteAll()
            db.shelfDao().deleteAll()
            db.listDao().deleteAll()
            dao.deleteAll()
            if (includingEntities) {
                with(db.entityDao()) {
                    deleteExtracts()
                    deleteEditionWorks()
                    deleteWorkAuthors()
                    deleteEditions()
                    deleteWorks()
                    deleteAuthors()
                }
            }
        }
    }

    companion object {
        /** `UserRelation.byUserID`: requests first, and a friendship wins over both. */
        fun relationsById(dto: UserNetworkDto): Map<String, UserRelation> = buildMap {
            dto.userRequested.forEach { put(it, UserRelation.RequestSent) }
            dto.otherRequested.forEach { put(it, UserRelation.RequestReceived) }
            dto.friends.forEach { put(it, UserRelation.Friend) }
        }
    }
}
