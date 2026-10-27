package studio.lunabee.nouveaurecit.ui.editedition

import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import java.util.UUID

/**
 * `EditEditionStep` (iOS feature 0049): what « Modifier l'édition » pushes over its form. Pages are a
 * state of the screen's view model rather than destinations of the tab's back stack, as « Nouveau
 * livre » does: they edit a draft that lives only as long as the form, and must never outlive it.
 */
sealed interface EditEditionPage {
    /** The search for a work to add. */
    data object WorkSearch : EditEditionPage

    /** « Modifier l'œuvre » for the work with this id. */
    data class WorkDetail(val id: UUID) : EditEditionPage

    /** The search for an author to add to the work with this id. */
    data class WorkAuthor(val id: UUID) : EditEditionPage

    /** « Données bibliographiques », in full, opened by the « ? » or the notice's « En savoir plus ». */
    data object Help : EditEditionPage

    /** One of the pages of the catalogue's properties. */
    data class Property(val step: EditionPropertyStep) : EditEditionPage
}

/**
 * `EditionPropertyStep` (iOS feature 0050): the pages a property of the catalogue pushes over the
 * edition's form — the same in « Modifier l'édition » and in the scanner's « Nouvelle édition », each
 * of which wraps them in a page of its own.
 */
sealed interface EditionPropertyStep {
    /** The entities one property names, to take some away or add one. */
    data class Values(val propertyUri: String) : EditionPropertyStep

    /** The search for an entity to add to a property. */
    data class Picker(val propertyUri: String) : EditionPropertyStep

    data object PublicationDate : EditionPropertyStep

    /** The catalogues an identifier — or the kinds of links — can be added to. */
    data class IdentifierCatalog(val group: EditionProperty.Group) : EditionPropertyStep

    /** Typing one identifier or link. */
    data class IdentifierInput(val propertyUri: String) : EditionPropertyStep

    companion object {
        /**
         * What touching [property] pushes: the date's page, or — for an entity — the list of its values,
         * or the search straight away when there are none.
         */
        fun opening(property: EditionProperty, properties: EditionProperties): EditionPropertyStep = when {
            property == EditionProperty.PublicationDateProperty -> PublicationDate
            properties.entities(property).isNotEmpty() -> Values(property.uri)
            else -> Picker(property.uri)
        }

        /** How many pages an identifier added closes: its input and the catalogue under it, back to the form. */
        const val PAGES_CLOSED_BY_IDENTIFIER: Int = 2
    }
}

/**
 * The pages pushed over a form, the form itself excluded: empty is the form. Immutable, so the view
 * model's state stays one value.
 */
data class PageStack<P>(val pages: List<P> = emptyList()) {
    val top: P? get() = pages.lastOrNull()

    val isEmpty: Boolean get() = pages.isEmpty()

    fun push(page: P): PageStack<P> = PageStack(pages + page)

    /** Closes [count] pages, never more than there are. */
    fun pop(count: Int = 1): PageStack<P> = PageStack(pages.dropLast(count.coerceIn(0, pages.size)))

    /** The top page swapped for [page]: the search for a work gives way to the new work's own page. */
    fun replaceTop(page: P): PageStack<P> = pop().push(page)
}
