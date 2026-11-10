package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.data.search.IsbnQuery

/**
 * `Model/Creation/NewBookOrigin.swift` (iOS feature 0087): where « Nouveau livre » was opened from, which
 * decides what it opens on and whether its ISBN can be typed. Also the identity of a draft in
 * [NewBookDrafts]: the same barcode, or the same query, reopens it.
 */
sealed interface NewBookOrigin {
    /** The ISBN the reader came with: the barcode, or a query that was one. `null` for a text query. */
    val isbn: String?

    /** Whether the edition's form lets the ISBN be typed. */
    val isIsbnEditable: Boolean

    /**
     * What the work search opens on: a text query, as typed in Recherche. Empty after a scan, or after a
     * query that was an ISBN, which says nothing about the work.
     */
    val workQuery: String

    /** The draft the form starts from when there is none to resume. */
    val blankDraft: NewBookDraft get() = NewBookDraft(isbn = isbn.orEmpty())

    /** A barcode the scanner read and inventaire.io did not know. Its ISBN is never edited. */
    data class Scan(override val isbn: String) : NewBookOrigin {
        override val isIsbnEditable: Boolean get() = false

        override val workQuery: String get() = ""
    }

    /** A query Recherche found nothing for on inventaire.io. The ISBN is a field to fill in, or not. */
    data class Search(val query: String) : NewBookOrigin {
        override val isbn: String? get() = IsbnQuery.isbn(query)

        override val isIsbnEditable: Boolean get() = true

        override val workQuery: String get() = if (isbn == null) query.trim() else ""
    }
}
