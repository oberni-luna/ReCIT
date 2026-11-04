package studio.lunabee.nouveaurecit.data.creation

import java.util.UUID

/**
 * `WorkEdit` (iOS features 0049, 0057): one work of the edition, as « Édition de » lists it. A work that
 * exists is shown here and changed in its own « Modifier l'œuvre » ([EntityEdit]), saved alone; one still
 * to be created is described here — its title and authors — and created with them before the edition
 * names it, by the edition's save.
 *
 * Build one with [existing] or [newTitled]; change it with [copy] (`title`) and the functions below.
 */
data class WorkEdit(
    /** The row's own identity: a work being created has no uri yet. */
    val id: UUID,
    /** The work as inventaire.io holds it. `null` while still to be created. */
    val original: EditionWork?,
    val title: String,
    /** Who wrote it, as the form has them. One created gets its uri, so a retry does not create them twice. */
    val authors: List<NewBookAuthor>,
    /** The picture the row shows. */
    val imageUrl: String? = null,
) {
    val uri: String? get() = original?.uri

    val isNew: Boolean get() = original == null

    val trimmedTitle: String get() = title.trim()

    /**
     * Whether it can be saved: a work being created needs a title and an author. One created with neither
     * is the kind of orphan that has to be repaired by hand on the website.
     */
    val isComplete: Boolean get() = !isNew || (trimmedTitle.isNotEmpty() && authors.isNotEmpty())

    /** The work as a row draws it: its title, and its authors on the line under it. */
    val candidate: WorkCandidate
        get() = WorkCandidate(
            uri = uri.orEmpty(),
            title = trimmedTitle,
            authors = authors.map { it.trimmedName }.filter { it.isNotEmpty() },
            imageUrl = imageUrl,
        )

    // Changing a work being created

    /** Adds an author, unless they are on the work already. */
    fun addAuthor(author: NewBookAuthor): WorkEdit {
        if (!isNew || author.trimmedName.isEmpty() || authors.any { isSamePerson(it, author) }) return this
        return copy(authors = authors + author)
    }

    /** What a swipe on the list of authors takes away. */
    fun removeAuthors(indices: Set<Int>): WorkEdit {
        if (!isNew) return this
        return copy(authors = authors.filterIndexed { index, _ -> index !in indices })
    }

    // What landed

    /** Records the uri an author was created under. Answers this work unchanged when the author is not its own. */
    fun authorCreated(id: UUID, uri: String): WorkEdit =
        copy(authors = authors.map { if (it.id == id) it.copy(uri = uri) else it })

    /** Records the work created: it exists now, with the title and authors it was created with. */
    fun created(uri: String, titleLanguage: String): WorkEdit =
        copy(original = EditionWork(uri = uri, title = trimmedTitle, authors = authors, imageUrl = imageUrl, titleLanguage = titleLanguage))

    /** Shows an author under a new name: one just renamed in « Modifier l'auteur·ice ». */
    fun renameAuthor(uri: String, name: String): WorkEdit = copy(
        authors = authors.map { if (it.uri == uri) it.copy(name = name) else it },
        original = original?.copy(authors = original.authors.map { if (it.uri == uri) it.copy(name = name) else it }),
    )

    companion object {
        /** A work inventaire.io or Wikidata has. [id] keeps a row's identity when the work it shows is read again. */
        fun existing(original: EditionWork, id: UUID = UUID.randomUUID()): WorkEdit = WorkEdit(
            id = id,
            original = original,
            title = original.title,
            authors = original.authors,
            imageUrl = original.imageUrl,
        )

        /** A work to create, named after the search that did not find it. */
        fun newTitled(title: String): WorkEdit = WorkEdit(
            id = UUID.randomUUID(),
            original = null,
            title = NewBookDraft.capitalizingFirstLetter(title.trim()),
            authors = emptyList(),
        )

        /** The same uri, or — when one side has none, as authors picked from the search do — the same name. */
        fun isSamePerson(lhs: NewBookAuthor, rhs: NewBookAuthor): Boolean {
            if (lhs.uri != null && rhs.uri != null) return lhs.uri == rhs.uri
            return lhs.trimmedName.equals(rhs.trimmedName, ignoreCase = true)
        }
    }
}
