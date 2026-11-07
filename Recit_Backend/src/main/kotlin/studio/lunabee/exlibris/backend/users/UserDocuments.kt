package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import studio.lunabee.exlibris.backend.db.DocumentId

/** A [UserRecord] written as one of inventaire.io's user documents. */
object UserDocuments {
    fun owner(
        user: UserRecord,
        snapshot: UserSnapshot,
    ): OwnerUserDocument =
        OwnerUserDocument(
            id = user.id,
            rev = DocumentId.revision(user.id, user.version),
            username = user.username,
            created = user.created,
            bio = user.bio,
            email = user.email,
            fediversable = user.fediversable,
            language = user.language,
            picture = user.picture,
            position = user.position?.toList(),
            validEmail = user.isEmailValidated,
            settings = settings(user.settings),
            snapshot = snapshot,
            summaryPeriodicity = user.summaryPeriodicity,
        )

    fun public(
        user: UserRecord,
        isInNetwork: Boolean,
        snapshot: UserSnapshot,
    ): PublicUserDocument =
        PublicUserDocument(
            id = user.id,
            username = user.username,
            bio = user.bio,
            created = user.created,
            fediversable = user.fediversable,
            picture = user.picture,
            position = user.position?.toList(),
            snapshot = snapshot.forViewer(isInNetwork),
        )

    /** `{"notifications":{…}}` always, as `ownerSafeData` fills it in; each other category once it holds a switch. */
    private fun settings(switches: Map<String, Boolean>): JsonObject {
        val byCategory: Map<String, Map<String, Boolean>> =
            switches.entries
                .groupBy({ it.key.substringBefore('.') }, { it.key.substringAfter('.') to it.value })
                .mapValues { (_, pairs) -> pairs.toMap() }
        return buildJsonObject {
            (listOf(UserSettingNames.NOTIFICATIONS) + byCategory.keys).distinct().forEach { category ->
                put(
                    category,
                    buildJsonObject { byCategory[category].orEmpty().forEach { (name, isOn) -> put(name, isOn) } },
                )
            }
        }
    }
}
