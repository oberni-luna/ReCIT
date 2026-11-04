package studio.lunabee.nouveaurecit.data.lists

import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.network.dto.ListDto

/**
 * `ListModel.syncLists(createdBy:claimsUnstamped:)`: what an answer of `/api/lists/by-creators` does to
 * the lists of the store. The store holds my lists and my friends', so **the deletion is scoped to the
 * creators asked for**: without it, opening a friend's profile would delete every list of mine.
 *
 * Only my own sync passes [claimsUnstamped]: a list stored before `creatorId` existed is mine, and may be
 * pruned by mine alone. Asked about one reader, a list the answer does not stamp is stamped with them;
 * asked about several, a list that does not say whose it is is left out — stored unstamped, it would pass
 * for mine.
 */
data class ListSyncPlan(
    /** The answer's lists, merged into the rows the store had. */
    val upserts: List<EntityListEntity>,
    /** The answer's lists, as kept — the ones whose elements the sync merges. */
    val synced: List<ListDto>,
    /** The ids of the lists in scope the answer no longer holds. */
    val deletions: List<String>,
) {
    companion object {
        fun plan(
            existing: List<EntityListEntity>,
            answer: List<ListDto>,
            creatorIds: Set<String>,
            claimsUnstamped: Boolean,
        ): ListSyncPlan {
            val soleCreator: String? = creatorIds.singleOrNull()
            val synced: List<ListDto> = if (soleCreator != null) answer else answer.filter { it.creator in creatorIds }
            val byId: Map<String, EntityListEntity> = existing.associateBy { it.id }
            val upserts: List<EntityListEntity> = synced.map { dto ->
                val merged: EntityListEntity = Merges.list(byId[dto.id], dto)
                if (merged.creatorId == null) merged.copy(creatorId = soleCreator) else merged
            }
            val kept: Set<String> = synced.map { it.id }.toSet()
            val deletions: List<String> = existing
                .filter { list -> list.creatorId?.let { it in creatorIds } ?: claimsUnstamped }
                .map { it.id }
                .filter { it !in kept }
            return ListSyncPlan(upserts = upserts, synced = synced, deletions = deletions)
        }
    }
}
