package studio.lunabee.nouveaurecit.data.lists

/**
 * `ListModel.creatorsPerRequest`: how « Dans mon réseau » asks `/api/lists/by-creators` for every friend's
 * lists — one request per batch of friends rather than one per profile. Ids are 32 characters: fifty of
 * them keep the address well under any server's limit. No friend, no request.
 */
object ListCreatorBatches {
    const val PER_REQUEST: Int = 50

    fun of(creatorIds: List<String>): List<Set<String>> = creatorIds.distinct().chunked(PER_REQUEST).map { it.toSet() }
}
