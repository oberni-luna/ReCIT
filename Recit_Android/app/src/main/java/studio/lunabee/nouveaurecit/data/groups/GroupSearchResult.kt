package studio.lunabee.nouveaurecit.data.groups

/** A group found by name. Only what the search says: enough for a row, not for the screen. */
data class GroupSearchResult(
    val id: String,
    val name: String,
    val description: String?,
    val pictureUrl: String?,
)
