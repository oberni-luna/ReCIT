package studio.lunabee.nouveaurecit.data.creation

/**
 * `EditionWork` (iOS feature 0049): a work an edition is an edition of, as inventaire.io holds it — its
 * title and authors. One the edition had when the form opened, one picked from the search, or one just
 * created. What the form changes about it is a [WorkEdit].
 *
 * Its authors can be changed only when it is one of inventaire.io's own (`inv:`): a Wikidata work's are
 * edited on Wikidata, through an account this app does not hold.
 */
data class EditionWork(
    val uri: String,
    val title: String,
    /** Read from the server, each carries its uri; picked from the search, only its name. */
    val authors: List<NewBookAuthor> = emptyList(),
    /** The picture the row shows. */
    val imageUrl: String? = null,
    /** The language of the label shown as its title: the one a new title is written in. */
    val titleLanguage: String? = null,
) {
    val isEditable: Boolean get() = uri.startsWith("inv:")

    /** The work as a row draws it: its title, and its authors on the line under it. */
    val candidate: WorkCandidate
        get() = WorkCandidate(
            uri = uri,
            title = title,
            authors = authors.map { it.trimmedName }.filter { it.isNotEmpty() },
            imageUrl = imageUrl,
        )

    companion object {
        /** A work picked from the search. */
        fun of(candidate: WorkCandidate): EditionWork = EditionWork(
            uri = candidate.uri,
            title = candidate.title,
            authors = candidate.authors.map { NewBookAuthor(name = it) },
            imageUrl = candidate.imageUrl,
        )
    }
}
