package studio.lunabee.exlibris.backend.groups

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import studio.lunabee.exlibris.backend.db.DocumentId

/** A [GroupRecord] written as inventaire.io's group document. */
object GroupDocuments {
    fun of(group: GroupRecord): GroupDocument =
        GroupDocument(
            id = group.id,
            rev = DocumentId.revision(group.id, group.version),
            type = "group",
            name = group.name,
            slug = group.slug,
            description = group.description,
            searchable = group.searchable,
            open = group.open,
            picture = group.picture,
            position = group.position?.let { JsonArray(it.toList().map(::JsonPrimitive)) } ?: JsonNull,
            creator = group.creator,
            created = group.created,
            admins = list(group, GroupRole.ADMIN),
            members = list(group, GroupRole.MEMBER),
            invited = list(group, GroupRole.INVITED),
            declined = list(group, GroupRole.DECLINED),
            requested = list(group, GroupRole.REQUESTED),
        )

    private fun list(
        group: GroupRecord,
        role: GroupRole,
    ): List<GroupMembershipDocument> =
        group.inRole(role).map { membership ->
            val invitor: JsonElement = membership.invitor?.let(::JsonPrimitive) ?: JsonNull
            GroupMembershipDocument(membership.userId, invitor, membership.timestamp)
        }
}
