package studio.lunabee.nouveaurecit.ui.editedition

import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import java.util.UUID

/**
 * `EditEditionStep` (iOS features 0049, 0057): what « Modifier l'édition » pushes over its form — and, for
 * a work or a person inventaire.io has, « Modifier l'œuvre » and « Modifier l'auteur·ice » with the pages
 * of their own properties. Pages are a state of the screen's view model rather than destinations of the
 * tab's back stack, as « Nouveau livre » does: they edit drafts that live only as long as the form, and
 * must never outlive it.
 */
sealed interface EditEditionPage {
    /** The search for a work to add. */
    data object WorkSearch : EditEditionPage

    /** The title and authors of the work being created with this id. */
    data class WorkDetail(val id: UUID) : EditEditionPage

    /** The search for an author to add to the work with this id. */
    data class WorkAuthor(val id: UUID) : EditEditionPage

    /** « Données bibliographiques », in full, opened by the « ? » or the notice's « En savoir plus ». */
    data object Help : EditEditionPage

    /** One of the pages of the catalogue's properties. */
    data class Property(val step: EditionPropertyStep) : EditEditionPage

    /** « Modifier l'œuvre » or « Modifier l'auteur·ice » for the entity with this uri. */
    data class Entity(val uri: String) : EditEditionPage

    /** One of the pages of the properties of the entity with this uri. */
    data class EntityProperty(val uri: String, val step: EditionPropertyStep) : EditEditionPage
}

/**
 * `EditionPropertyStep` (iOS features 0050, 0057): the pages a property of the catalogue pushes over the
 * edition's form — the same in « Modifier l'édition » and in the scanner's « Nouvelle édition », each
 * of which wraps them in a page of its own — and over « Modifier l'œuvre » and « Modifier l'auteur·ice ».
 * A step names its property by uri: the page looks it up in the catalogue of the values it writes into.
 */
sealed interface EditionPropertyStep {
    /** The entities one property names, to take some away or add one. */
    data class Values(val propertyUri: String) : EditionPropertyStep

    /** The search for an entity to add to a property. */
    data class Picker(val propertyUri: String) : EditionPropertyStep

    /** The date of a property whose value is one: an edition's publication, a person's birth. */
    data class Date(val propertyUri: String) : EditionPropertyStep

    /** The list a property's value is chosen in, when it is too long for a menu: a work's form. */
    data class Choice(val propertyUri: String) : EditionPropertyStep

    /** The catalogues an identifier — or the kinds of links — can be added to. */
    data class IdentifierCatalog(val group: EditionProperty.Group) : EditionPropertyStep

    /** Typing one identifier or link. */
    data class IdentifierInput(val propertyUri: String) : EditionPropertyStep

    companion object {
        /**
         * What touching [property] pushes: the date's page, the list of choices, or — for an entity — the
         * list of its values, or the search straight away when there are none.
         */
        fun opening(property: EditionProperty, properties: EditionProperties): EditionPropertyStep = when {
            property.kind == EditionProperty.Kind.Date -> Date(property.uri)
            property.choices.isNotEmpty() -> Choice(property.uri)
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

    /** Closes the last [page] on the stack and every page above it; nothing when it is not there. */
    fun popTo(page: P): PageStack<P> {
        val index: Int = pages.lastIndexOf(page)
        return if (index < 0) this else PageStack(pages.take(index))
    }
}
