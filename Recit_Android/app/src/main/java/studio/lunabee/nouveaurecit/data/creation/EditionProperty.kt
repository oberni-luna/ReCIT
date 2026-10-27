package studio.lunabee.nouveaurecit.data.creation

import java.net.URI

/**
 * `EditionProperty` (iOS feature 0050): the properties of an edition « Modifier l'édition » shows beyond
 * its title, subtitle, cover and works — everything inventaire.io accepts on an edition, read on
 * 2026-10-25 from `GET /api/data/properties` and from `properties_per_type.ts` in inventaire-client,
 * which says which ones the website shows and in what order.
 *
 * Left out, as the website leaves them out: `wdt:P31`, `invp:P1` and `invp:P3`. Left out here alone:
 * `wdt:P1889` (« différent de »), which names another edition that `/api/search` cannot find. The ISBNs
 * are not in the catalogue either: shown, never sent — only an admin may change `wdt:P212`, and the
 * server infers `wdt:P957` from it.
 *
 * An identifier's pattern is the server's own (`properties_values_constraints.ts`), so a value refused
 * here would have been refused there, with a less useful message.
 */
data class EditionProperty(
    val uri: String,
    val kind: Kind,
    val group: Group,
    val isMultivalued: Boolean,
    /**
     * The name of the string resource the form prints above the value — iOS's catalogue key with its
     * `.` turned into `_` (`edition_property_publisher`).
     */
    val labelKey: String,
) {
    sealed interface Kind {
        /** `YYYY`, `YYYY-MM` or `YYYY-MM-DD`: a date only as precise as the book is. */
        data object Date : Kind

        /** A positive whole number, sent as a JSON number. */
        data object Integer : Kind

        /** One of [EditionFormat]'s six uris. */
        data object Format : Kind

        /** An entity found by `/api/search` with this type, or created. */
        data class Entity(val type: EntitySearchType) : Kind

        /** An identifier in a catalogue, checked against the server's pattern. */
        data class Identifier(val pattern: String, val example: String) : Kind

        /** A web address. */
        data object Url : Kind
    }

    /** The section of the form a property is shown in. */
    enum class Group { Publication, Format, Contributors, Databases, Links }

    /** The type to search for, for a property whose values are entities. */
    val searchType: EntitySearchType? get() = (kind as? Kind.Entity)?.type

    /** Whether an entity nobody has entered can be created from the form: a person, a publisher, a collection. */
    val allowsCreation: Boolean
        get() = searchType == EntitySearchType.Humans ||
            searchType == EntitySearchType.Publishers ||
            searchType == EntitySearchType.Collections

    /** What the user typed, made into the value that goes on the wire — or `null` when the server would refuse it. */
    fun literal(text: String): ClaimLiteral? {
        val trimmed: String = text.trim()
        if (trimmed.isEmpty()) return null
        return when (kind) {
            Kind.Integer -> trimmed.toIntOrNull()?.takeIf { it > 0 }?.let { ClaimLiteral.Integer(it) }
            Kind.Date -> PublicationDate.parse(trimmed)?.let { ClaimLiteral.Text(it.claim) }
            is Kind.Identifier -> normalize(trimmed).takeIf { Regex(kind.pattern).containsMatchIn(it) }?.let { ClaimLiteral.Text(it) }
            Kind.Url -> trimmed.takeIf(::isWebAddress)?.let { ClaimLiteral.Text(it) }
            Kind.Format, is Kind.Entity -> ClaimLiteral.Text(trimmed)
        }
    }

    /** The example the server gives for an identifier, shown under the field. */
    val example: String?
        get() = when (kind) {
            is Kind.Identifier -> kind.example
            Kind.Url -> "https://"
            else -> null
        }

    /** The small rewrites the server makes before it validates: the BnF's `cb` prefix, a Mastodon handle's `@`. */
    private fun normalize(value: String): String = when (uri) {
        "wdt:P268" -> value.removePrefix("cb")
        "wdt:P4033" -> value.removePrefix("@")
        else -> value
    }

    private fun isWebAddress(text: String): Boolean {
        val parsed: URI = runCatching { URI(text) }.getOrNull() ?: return false
        val scheme: String = parsed.scheme?.lowercase() ?: return false
        return (scheme == "http" || scheme == "https") && !parsed.host.isNullOrEmpty()
    }

    companion object {
        val Publisher: EditionProperty = EditionProperty(
            "wdt:P123",
            Kind.Entity(EntitySearchType.Publishers),
            Group.Publication,
            true,
            "edition_property_publisher",
        )
        val Collection: EditionProperty = EditionProperty(
            "wdt:P195",
            Kind.Entity(EntitySearchType.Collections),
            Group.Publication,
            true,
            "edition_property_collection",
        )
        val PublicationDateProperty: EditionProperty = EditionProperty(
            "wdt:P577",
            Kind.Date,
            Group.Publication,
            false,
            "edition_property_publication_date",
        )
        val Language: EditionProperty = EditionProperty(
            "wdt:P407",
            Kind.Entity(EntitySearchType.Languages),
            Group.Publication,
            true,
            "edition_property_language",
        )

        val Format: EditionProperty = EditionProperty("wdt:P437", Kind.Format, Group.Format, false, "edition_property_format")
        val NumberOfPages: EditionProperty = EditionProperty("wdt:P1104", Kind.Integer, Group.Format, false, "edition_property_pages")
        val NumberOfVolumes: EditionProperty = EditionProperty("wdt:P2635", Kind.Integer, Group.Format, false, "edition_property_volumes")

        val contributors: List<EditionProperty> = listOf(
            person("wdt:P655", "edition_property_translator"),
            person("wdt:P110", "edition_property_illustrator"),
            person("wdt:P736", "edition_property_cover_artist"),
            person("wdt:P2679", "edition_property_preface"),
            person("wdt:P2680", "edition_property_afterword"),
            person("wdt:P98", "edition_property_editor"),
        )

        val databases: List<EditionProperty> = listOf(
            database("wdt:P268", "edition_property_bnf", """^\d{8}[0-9bcdfghjkmnpqrstvwxz]$""", "123735831"),
            database("wdt:P648", "edition_property_open_library", """^OL[1-9]\d{0,7}M$""", "OL61173905M"),
            database("wdt:P1025", "edition_property_sudoc", """^\d{8}[\dX]$""", "082962995"),
            database("wdt:P214", "edition_property_viaf", """^[1-9]\d(\d{0,7}|\d{17,20})$""", "120062731"),
            database("wdt:P243", "edition_property_oclc", """^0*[1-9]\d*$""", "57722711"),
            database("wdt:P675", "edition_property_google_books", """^[\w-]{12}$""", "7r14FzJdSuAC"),
            database("wdt:P2969", "edition_property_goodreads", """^[1-9]\d*$""", "821987"),
            database(
                "wdt:P12351",
                "edition_property_bookbrainz",
                """[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}""",
                "e16ac0da-d056-4af1-ab71-f749b035a92e",
            ),
            database("wdt:P6901", "edition_property_noosfere", """^-?[1-9]\d*$""", "-322323"),
            database("wdt:P1234", "edition_property_isfdb", """^[1-9]\d*$""", "62137"),
            database("wdt:P1292", "edition_property_dnb", """^\d{8,9}[X\d]?$""", "450155102"),
            database(
                "wdt:P227",
                "edition_property_gnd",
                """^1[01]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]$""",
                "4079154-3",
            ),
            database("wdt:P1044", "edition_property_swb", """^\d{8}[0-9X]$""", "000619612"),
            database("wdt:P950", "edition_property_bne", """^(bima|bimo|bipa)\d{10}$""", "bimo0000459277"),
            database("wdt:P1144", "edition_property_lccn", """^[a-z]{0,3}\d{6,10}$""", "11025047"),
            database("wdt:P5199", "edition_property_british_library", """^\d{9}$""", "000033859"),
            database("wdt:P1182", "edition_property_libris", """^[1-9]\d*$""", "11400617"),
            database("wdt:P1143", "edition_property_bn_argentina", """^\d{9}$""", "000188710"),
            database("wdt:P3184", "edition_property_czech_national_bibliography", """^cnb[0-9]{9}$""", "cnb000567876"),
            database("wdt:P1844", "edition_property_hathitrust", """^\d{9}$""", "012508885"),
            database("wdt:P3155", "edition_property_runeberg", """^[a-z0-9/.-]+$""", "aanden"),
            database("wdt:P356", "edition_property_doi", """(?i)^10.\d{4,9}/[^\s]+$""", "10.1371/JOURNAL.PONE.0029797"),
        )

        val links: List<EditionProperty> = listOf(
            EditionProperty("wdt:P856", Kind.Url, Group.Links, true, "edition_property_official_website"),
            EditionProperty("wdt:P1581", Kind.Url, Group.Links, true, "edition_property_blog"),
            link("wdt:P4033", "edition_property_mastodon", """^\w+@[a-z0-9.-]+[a-z0-9]+$""", "jz@mamot.fr"),
            link("wdt:P12361", "edition_property_bluesky", """^[\w\-.]+$""", "astrokatie.com"),
            link("wdt:P2003", "edition_property_instagram", """^(?!.*\.\.)(?!.*\.$)[^\W][\w.]{0,29}$""", "tienstiens.bd"),
            link("wdt:P2013", "edition_property_facebook", """^(\d+|[.\w]+)$""", "billt"),
            link("wdt:P2002", "edition_property_x", """^\w{1,15}$""", "EFF"),
            link("wdt:P2397", "edition_property_youtube", """^UC[\w-]{21}[AQgw]$""", "UCEbFsO2sM_wjTn44YAgSrrg"),
            link("wdt:P11892", "edition_property_threads", """^_{0,2}[a-z\d]+((\.|_{1,4}|\._)[a-z\d]+)*_{0,2}$""", "laradionova"),
            link("wdt:P7085", "edition_property_tiktok", """^[\w.]{1,24}$""", "jannat_zubair29"),
        )

        /** Every property of the catalogue, in the order the form shows them. */
        val all: List<EditionProperty> =
            listOf(Publisher, Collection, PublicationDateProperty, Language, Format, NumberOfPages, NumberOfVolumes) +
                contributors + databases + links

        fun named(uri: String): EditionProperty? = all.firstOrNull { it.uri == uri }

        fun inGroup(group: Group): List<EditionProperty> = all.filter { it.group == group }

        private fun person(uri: String, labelKey: String): EditionProperty =
            EditionProperty(uri, Kind.Entity(EntitySearchType.Humans), Group.Contributors, true, labelKey)

        private fun database(uri: String, labelKey: String, pattern: String, example: String): EditionProperty =
            EditionProperty(uri, Kind.Identifier(pattern, example), Group.Databases, true, labelKey)

        private fun link(uri: String, labelKey: String, pattern: String, example: String): EditionProperty =
            EditionProperty(uri, Kind.Identifier(pattern, example), Group.Links, true, labelKey)
    }
}
