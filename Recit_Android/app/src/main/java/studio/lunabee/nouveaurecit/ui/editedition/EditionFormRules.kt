package studio.lunabee.nouveaurecit.ui.editedition

import studio.lunabee.nouveaurecit.data.creation.ClaimLiteral
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EditionPropertyChoice
import studio.lunabee.nouveaurecit.data.creation.EntityEdit
import studio.lunabee.nouveaurecit.data.creation.PublicationDate
import studio.lunabee.nouveaurecit.data.creation.WorkEdit
import studio.lunabee.nouveaurecit.network.ApiService
import java.net.URI
import java.util.Locale

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

    /**
     * Whether touching a work of « Édition de » opens a page: the title and authors of one being created,
     * or the whole of « Modifier l'œuvre » for one of inventaire.io's own. A Wikidata work offers none.
     */
    fun opensWork(work: WorkEdit): Boolean = work.isNew || EntityEdit.canEdit(work.uri)

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

    /** The identifiers — or links — the entity has in [group], in its catalogue's order. */
    fun identifierEntries(group: EditionProperty.Group, properties: EditionProperties): List<IdentifierEntry> =
        properties.catalogue.inGroup(group).flatMap { property ->
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

    /** The date the date's page opens on: the one [property] holds, or this year alone. */
    fun initialDate(property: EditionProperty, properties: EditionProperties, thisYear: Int): PublicationDate =
        date(property, properties) ?: PublicationDate(year = thisYear, precision = PublicationDate.Precision.Year)

    /** The date [property] holds — an edition's publication, a person's birth —, or `null`. */
    fun date(property: EditionProperty, properties: EditionProperties): PublicationDate? =
        properties.literal(property)?.string?.let(PublicationDate::parse)

    /** The choice [property] holds; `null` when it holds none, or one the list does not hold — set on the website before the list changed. */
    fun choice(property: EditionProperty, properties: EditionProperties): EditionPropertyChoice? {
        val uri: String = properties.literal(property)?.string ?: return null
        return property.choices.firstOrNull { it.uri == uri }
    }

    /** A language's name in the reader's language, « Français »; its code when the system has none. */
    fun languageName(code: String, locale: Locale): String =
        Locale.forLanguageTag(code).getDisplayLanguage(locale).takeIf { it.isNotEmpty() && it != code }
            ?.replaceFirstChar { it.titlecase(locale) }
            ?: code

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
