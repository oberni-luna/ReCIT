package studio.lunabee.exlibris.backend.groups

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.images.ImagesService
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.users.UserDocumentsService
import java.time.Clock

/** Reading groups, creating one and changing its settings, as inventaire.io's `controllers/groups`. */
class GroupsService(
    private val repository: GroupsRepository,
    private val documents: UserDocumentsService,
    private val images: ImagesService,
    private val clock: Clock,
) {
    /** `GET /api/groups`. */
    suspend fun userGroups(userId: String): UserGroups {
        requireAccount(userId)
        val roles: Set<GroupRole> = setOf(GroupRole.ADMIN, GroupRole.MEMBER, GroupRole.INVITED)
        return UserGroups(repository.groupsOf(userId, roles).map(GroupDocuments::of))
    }

    /** `GET /api/groups/by-id?id=…`, public. */
    suspend fun byId(
        groupId: String,
        viewerId: String?,
    ): GroupById {
        if (!DocumentId.isValid(groupId)) throw ApiException.invalidParameter("id", groupId)
        val group: GroupRecord = repository.findById(groupId) ?: throw GroupMembershipService.notFound()
        return GroupById(GroupDocuments.of(group), documents.documents(group.memberIds, viewerId).values.toList())
    }

    /** `POST /api/groups`: the group, its creator its only admin, answered as `by-id` would show it. */
    suspend fun create(
        userId: String,
        body: JsonBody,
    ): GroupDocument {
        val creation: GroupCreation = GroupCreation.from(body)
        requireAccount(userId)
        val now: Long = clock.millis()
        val group: GroupRecord =
            withFreeSlug(creation.name, groupId = null) { slug ->
                GroupRecord(
                    id = DocumentId.new(),
                    version = 1,
                    name = creation.name,
                    slug = slug,
                    description = creation.description,
                    searchable = creation.searchable,
                    open = creation.open,
                    picture = null,
                    position = creation.position,
                    creator = userId,
                    created = now,
                    memberships = listOf(GroupMembership(userId, GroupRole.ADMIN, invitor = null, timestamp = now)),
                ).takeIf { repository.insert(it) }
            }
        return GroupDocuments.of(group)
    }

    /**
     * `PUT /api/groups/update-settings` with `{group, attribute, value}`, an admin's: checked in inventaire.io's
     * order — the parameters, the right, then the value. A new name moves the slug; a replaced picture is released.
     */
    suspend fun updateSettings(
        userId: String,
        body: JsonBody,
    ): GroupSettingsUpdate {
        val request: GroupSettingsRequest = GroupSettingsRequest.from(body)
        val groupId: String = request.groupId
        requireAccount(userId)
        val group: GroupRecord = repository.findById(groupId) ?: throw GroupMembershipService.notFound()
        MembershipRights.requireAdmin(group.roleOf(userId))
        val setting: GroupSetting = GroupSettingReader.read(request.attribute, request.value)
        val update: Map<String, String> =
            if (setting is GroupSetting.Name) {
                withFreeSlug(setting.value, groupId) { slug ->
                    mapOf("slug" to slug).takeIf { repository.write(groupId, setting, slug) }
                }
            } else {
                repository.write(groupId, setting, slug = null)
                emptyMap()
            }
        if (setting is GroupSetting.Picture && group.picture != setting.path) {
            group.picture?.let { images.releasePicture(it) }
        }
        return GroupSettingsUpdate(update = update)
    }

    private suspend fun requireAccount(userId: String) {
        if (!repository.userExists(userId)) throw ApiException.unauthorized()
    }

    /**
     * Runs [write] with the first slug of [name] no other group holds, as inventaire.io's `addSlug`, again when
     * another group took it meanwhile ([write] answering `null`).
     */
    private suspend fun <T : Any> withFreeSlug(
        name: String,
        groupId: String?,
        write: suspend (String) -> T?,
    ): T {
        repeat(SLUG_ATTEMPTS) {
            val slug: String = GroupSlug.candidates(name).first { !repository.isSlugTaken(it, groupId) }
            write(slug)?.let { return it }
        }
        throw ApiException(HttpStatusCode.Conflict, "slug conflict")
    }

    private companion object {
        const val SLUG_ATTEMPTS: Int = 3
    }
}
