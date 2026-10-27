package studio.lunabee.nouveaurecit.ui.editedition

import studio.lunabee.nouveaurecit.data.creation.ClaimLiteral
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.PublicationDate
import studio.lunabee.nouveaurecit.data.creation.WorkEdit
import studio.lunabee.nouveaurecit.network.ApiService
import java.net.URI

/**
 * The few decisions the edition form's pages make on their own — which sentence a section ends on,
 * whether « Créer » is offered, how names and counts are written — kept out of the composables so they
 * are tested without Compose.
 */
object EditionFormRules {
    /** What « Édition de » says under its works (`EditionWorksSection.footer`). */
    enum class WorksFooter { Empty, NewWorkNeedsAuthor, Default }

    fun worksFooter(works: List<WorkEdit>): WorksFooter = when {
        works.isEmpty() -> WorksFooter.Empty
        works.any { it.isNew && it.authors.isEmpty() } -> WorksFooter.NewWorkNeedsAuthor
        else -> WorksFooter.Default
    }

    /** What « Modifier l'œuvre » says under the work (`EditWorkView.footer`). */
    enum class WorkFooter { Wikidata, New, Default }

    fun workFooter(work: WorkEdit): WorkFooter = when {
        !work.isEditable -> WorkFooter.Wikidata
        work.isNew -> WorkFooter.New
        else -> WorkFooter.Default
    }

    /** Whether the picker offers to create what was typed: a language is chosen, never created. */
    fun offersCreation(property: EditionProperty, query: String): Boolean = property.allowsCreation && query.isNotBlank()

    /**
     * Whether « Créer » can be pressed: a collection is created under its publisher, so not while the
     * edition names none — the row then says to choose the publisher first.
     */
    fun canCreate(property: EditionProperty, hasPublisher: Boolean): Boolean =
        property.allowsCreation && (property != EditionProperty.Collection || hasPublisher)

    /** Names as a sentence lists them: « A », « A et B », « A, B et C ». */
    fun joinedNames(names: List<String>, and: String): String = when (names.size) {
        0 -> ""
        1 -> names.first()
        else -> names.dropLast(1).joinToString(", ") + " $and " + names.last()
    }

    /** A count as typed: anything but digits is dropped, and what is left is the claim — or none. */
    fun countLiteral(property: EditionProperty, typed: String): ClaimLiteral? = property.literal(typed.filter(Char::isDigit))

    /** One identifier or link of a group, as a row: the property it is of, and its value. */
    data class IdentifierEntry(val property: EditionProperty, val value: ClaimLiteral)

    /** The identifiers — or links — the edition has in [group], in the catalogue's order. */
    fun identifierEntries(group: EditionProperty.Group, properties: EditionProperties): List<IdentifierEntry> =
        EditionProperty.inGroup(group).flatMap { property ->
            properties.values(property).mapNotNull { it.claim }.map { IdentifierEntry(property, it) }
        }

    /** [properties] without [entry]: what a swipe on an identifier or a link takes away. */
    fun removing(entry: IdentifierEntry, properties: EditionProperties): EditionProperties {
        val index: Int = properties.values(entry.property).indexOfFirst { it.claim == entry.value }
        return if (index < 0) properties else properties.remove(setOf(index), entry.property)
    }

    /** What the field of an identifier says under it while it is typed. */
    sealed interface IdentifierStatus {
        data object Empty : IdentifierStatus

        data class Example(val example: String) : IdentifierStatus

        data object Invalid : IdentifierStatus
    }

    fun identifierStatus(property: EditionProperty, text: String): IdentifierStatus = when {
        text.isNotEmpty() && property.literal(text) == null -> IdentifierStatus.Invalid
        else -> property.example?.let { IdentifierStatus.Example(it) } ?: IdentifierStatus.Empty
    }

    /** The date the date's page opens on: the edition's, or this year alone. */
    fun initialDate(properties: EditionProperties, thisYear: Int): PublicationDate =
        properties.literal(EditionProperty.PublicationDateProperty)?.string?.let(PublicationDate::parse)
            ?: PublicationDate(year = thisYear, precision = PublicationDate.Precision.Year)

    /** A year as typed: digits only, four at most; `null` keeps the year it had. */
    fun typedYear(text: String): Int? = text.filter(Char::isDigit).take(4).toIntOrNull()?.takeIf { it > 0 }
}

/** `BibliographicDataLinks`: where the help sends a contributor further. */
object BibliographicDataLinks {
    /** The wiki page about entities and where their data comes from. */
    const val WIKI: String = "https://wiki.inventaire.io/wiki/Entities_data"

    /** The project's Matrix room about bibliographic data. */
    const val CHAT: String = "https://app.element.io/#/room/#inventaire_entities:matrix.org"

    /** The reader's contributions to inventaire.io's own database, on the website; the name escaped as a path. */
    fun contributions(username: String, baseUrl: String = ApiService.BASE_URL): String? = runCatching {
        val base = URI(baseUrl)
        URI(base.scheme, base.host, "/users/$username/contributions", null).toASCIIString()
    }.getOrNull()
}
