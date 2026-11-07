package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V4__groups.sql`: one row per reader and group. Read by `groups` and `relations`. */
object GroupMembershipsTable : Table("group_memberships") {
    val groupId: Column<String> = char("group_id", DocumentId.LENGTH)
    val userId: Column<String> = char("user_id", DocumentId.LENGTH)
    val role: Column<String> = text("role")
    val invitor: Column<String?> = char("invitor", DocumentId.LENGTH).nullable()
    val timestamp: Column<Long> = long("timestamp")
    val moved: Column<Long> = long("moved")

    override val primaryKey: PrimaryKey = PrimaryKey(groupId, userId)
}
