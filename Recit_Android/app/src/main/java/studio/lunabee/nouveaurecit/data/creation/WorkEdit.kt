package studio.lunabee.nouveaurecit.data.creation

import java.util.UUID

/**
 * `WorkEdit` (iOS feature 0049): one work of the edition, as « Édition de » lists it and « Modifier
 * l'œuvre » changes it — its title and authors, against what inventaire.io holds. A work that exists is
 * renamed by `update-label` and given or relieved of authors by `wdt:P50` claims on it; one still to be
 * created is described here, and created with its authors before the edition names it.
 *
 * A Wikidata work is shown and not changed: its title and authors are edited on Wikidata, through an
 * account this app does not hold.
 *
 * Build one with [existing] or [newTitled]; change it with [copy] (`title`) and the functions below.
 */
data class WorkEdit(
    /** The row's own identity: a work being created has no uri yet. */
    val id: UUID,
    /** The work as inventaire.io holds it, after every change that landed. `null` while still to be created. */
    val original: EditionWork?,
    val title: String,
    /** Who wrote it, as the form has them. One created gets its uri, so a retry does not create them twice. */
    val authors: List<NewBookAuthor>,
    /** The picture the row shows. */
    val imageUrl: String? = null,
) {
    val uri: String? get() = original?.uri

    val isNew: Boolean get() = original == null

    /** One of inventaire.io's own, or one to create. A Wikidata work is changed on Wikidata. */
    val isEditable: Boolean get() = original?.isEditable ?: true

    val trimmedTitle: String get() = title.trim()

    /** The new title of a work that exists, when it was changed. */
    val renamedTitle: String?
        get() {
            val original: EditionWork = original ?: return null
            if (!isEditable || trimmedTitle.isEmpty() || trimmedTitle == original.title.trim()) return null
            return trimmedTitle
        }

    val addedAuthors: List<NewBookAuthor>
        get() {
            val original: EditionWork = original ?: return authors
            return authors.filter { author -> original.authors.none { isSamePerson(it, author) } }
        }

    val removedAuthors: List<NewBookAuthor>
        get() {
            val original: EditionWork = original ?: return emptyList()
            return original.authors.filter { author -> authors.none { isSamePerson(it, author) } }
        }

    val hasChanges: Boolean
        get() = isNew || renamedTitle != null || addedAuthors.isNotEmpty() || removedAuthors.isNotEmpty()

    /**
     * Whether it can be saved: a title, and — for a work being created — an author. One created with
     * neither is the kind of orphan that has to be repaired by hand on the website.
     */
    val isComplete: Boolean
        get() = if (trimmedTitle.isEmpty()) !isEditable else !isNew || authors.isNotEmpty()

    /** The work as a row draws it: its title, and its authors on the line under it. */
    val candidate: WorkCandidate
        get() = WorkCandidate(
            uri = uri.orEmpty(),
            title = trimmedTitle,
            authors = authors.map { it.trimmedName }.filter { it.isNotEmpty() },
            imageUrl = imageUrl,
        )

    // Changing

    /** Adds an author, unless they are on the work already. */
    fun addAuthor(author: NewBookAuthor): WorkEdit {
        if (!isEditable || author.trimmedName.isEmpty() || authors.any { isSamePerson(it, author) }) return this
        return copy(authors = authors + author)
    }

    /** What a swipe on the list of authors takes away. */
    fun removeAuthors(indices: Set<Int>): WorkEdit {
        if (!isEditable) return this
        return copy(authors = authors.filterIndexed { index, _ -> index !in indices })
    }

    // What landed

    /** Records the uri an author was created under. Answers this work unchanged when the author is not its own. */
    fun authorCreated(id: UUID, uri: String): WorkEdit =
        copy(authors = authors.map { if (it.id == id) it.copy(uri = uri) else it })

    /** Records the work created: it exists now, with the title and authors it was created with. */
    fun created(uri: String, titleLanguage: String): WorkEdit =
        copy(original = EditionWork(uri = uri, title = trimmedTitle, authors = authors, imageUrl = imageUrl, titleLanguage = titleLanguage))

    /** Records that an author claim landed on the work: [added] is on it, [removed] is not. */
    fun authorLanded(added: String?, removed: String?): WorkEdit {
        var landed: EditionWork = original ?: return this
        if (removed != null) landed = landed.copy(authors = landed.authors.filterNot { it.uri == removed })
        val author: NewBookAuthor? = added?.let { uri -> authors.firstOrNull { it.uri == uri } }
        if (author != null) landed = landed.copy(authors = landed.authors + author)
        return copy(original = landed)
    }

    /** Records that the new title landed. */
    fun titleLanded(value: String): WorkEdit = copy(original = original?.copy(title = value))

    companion object {
        /** A work inventaire.io or Wikidata has. */
        fun existing(original: EditionWork): WorkEdit = WorkEdit(
            id = UUID.randomUUID(),
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
