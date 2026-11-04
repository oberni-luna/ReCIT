package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.data.creation.EditionProperty.Group
import studio.lunabee.nouveaurecit.data.creation.EditionProperty.Kind

/**
 * `EditionProperty+Work` (iOS feature 0057): what inventaire.io accepts on a work, read on 2026-10-28 from
 * `GET /api/data/properties` (the `subjectTypes` that hold `work`), `GET /api/data/property-values` (the
 * values allowed for its type and its form) and `properties_values_constraints.ts` (the identifiers'
 * patterns, a work's own where they differ from an edition's). « Modifier l'œuvre ».
 *
 * Left out, as the website leaves them out: `invp:P1` and `invp:P3`. A work's title is not a claim but a
 * label per language, and its picture is its editions'.
 */
object WorkProperties {
    // L'œuvre

    val Type: EditionProperty = EditionProperty(
        uri = "wdt:P31",
        kind = Kind.Choice(
            listOf(
            EditionPropertyChoice("wd:Q7725634", "work_type_literary_work"),
            EditionPropertyChoice("wd:Q47461344", "work_type_written_work"),
            EditionPropertyChoice("wd:Q1004", "work_type_comic"),
            EditionPropertyChoice("wd:Q725377", "work_type_graphic_novel"),
            EditionPropertyChoice("wd:Q8274", "work_type_manga"),
            EditionPropertyChoice("wd:Q562214", "work_type_manhwa"),
            ),
        ),
        group = Group.General,
        isMultivalued = false,
        labelKey = "entity_property_work_type",
    )

    val Form: EditionProperty = EditionProperty(
        uri = "wdt:P7937",
        kind = Kind.Choice(
            listOf(
            EditionPropertyChoice("wd:Q8261", "work_form_novel"),
            EditionPropertyChoice("wd:Q149537", "work_form_novella"),
            EditionPropertyChoice("wd:Q49084", "work_form_short_story"),
            EditionPropertyChoice("wd:Q472808", "work_form_novelette"),
            EditionPropertyChoice("wd:Q25379", "work_form_play"),
            EditionPropertyChoice("wd:Q5185279", "work_form_poem"),
            EditionPropertyChoice("wd:Q35760", "work_form_essay"),
            EditionPropertyChoice("wd:Q384515", "work_form_treatise"),
            EditionPropertyChoice("wd:Q193495", "work_form_monograph"),
            EditionPropertyChoice("wd:Q1266946", "work_form_thesis"),
            EditionPropertyChoice("wd:Q49850", "work_form_journal"),
            EditionPropertyChoice("wd:Q185598", "work_form_diary"),
            EditionPropertyChoice("wd:Q1279564", "work_form_short_story_collection"),
            EditionPropertyChoice("wd:Q12106333", "work_form_poetry_collection"),
            EditionPropertyChoice("wd:Q27560760", "work_form_fairy_tale_collection"),
            EditionPropertyChoice("wd:Q65085460", "work_form_letter_collection"),
            EditionPropertyChoice("wd:Q133500522", "work_form_novel_collection"),
            EditionPropertyChoice("wd:Q20024995", "work_form_novella_collection"),
            EditionPropertyChoice("wd:Q111180384", "work_form_novelette_collection"),
            EditionPropertyChoice("wd:Q105420", "work_form_anthology"),
            EditionPropertyChoice("wd:Q125544547", "work_form_short_story_anthology"),
            EditionPropertyChoice("wd:Q19357149", "work_form_poetry_anthology"),
            EditionPropertyChoice("wd:Q5456296", "work_form_fix_up"),
            EditionPropertyChoice("wd:Q725377", "work_form_graphic_novel"),
            EditionPropertyChoice("wd:Q642946", "work_form_gamebook"),
            EditionPropertyChoice("wd:Q23622", "work_form_dictionary"),
            EditionPropertyChoice("wd:Q5292", "work_form_encyclopedia"),
            EditionPropertyChoice("wd:Q83790", "work_form_textbook"),
            EditionPropertyChoice("wd:Q2352616", "work_form_catalog"),
            EditionPropertyChoice("wd:Q780605", "work_form_exhibition_catalogue"),
            EditionPropertyChoice("wd:Q1143604", "work_form_conference_proceedings"),
            ),
        ),
        group = Group.General,
        isMultivalued = false,
        labelKey = "entity_property_work_form",
    )

    val OriginalLanguage: EditionProperty =
        EditionProperty("wdt:P407", Kind.Entity(EntitySearchType.Languages), Group.General, true, "entity_property_original_language")
    val FirstPublicationDate: EditionProperty =
        EditionProperty("wdt:P577", Kind.Date, Group.General, false, "entity_property_first_publication_date")

    // Who made it

    val Author: EditionProperty = EditionProperty.person("wdt:P50", "entity_property_author", Group.Authors)

    val roles: List<EditionProperty> = listOf(
        EditionProperty.person("wdt:P58", "entity_property_scenarist", Group.Roles),
        EditionProperty.person("wdt:P110", "edition_property_illustrator", Group.Roles),
        EditionProperty.person("wdt:P98", "edition_property_editor", Group.Roles),
    )

    val comicRoles: List<EditionProperty> = listOf(
        EditionProperty.person("wdt:P10837", "entity_property_penciller", Group.Comics),
        EditionProperty.person("wdt:P10836", "entity_property_inker", Group.Comics),
        EditionProperty.person("wdt:P6338", "entity_property_colorist", Group.Comics),
        EditionProperty.person("wdt:P9191", "entity_property_letterer", Group.Comics),
    )

    // Series, genre, relations

    val Series: EditionProperty = EditionProperty("wdt:P179", Kind.Entity(EntitySearchType.Series), Group.Series, true, "entity_property_series")
    val SeriesOrdinal: EditionProperty = EditionProperty("wdt:P1545", Kind.Ordinal, Group.Series, false, "entity_property_series_ordinal")

    val Genre: EditionProperty = EditionProperty("wdt:P136", Kind.Entity(EntitySearchType.Genres), Group.Subjects, true, "entity_property_genre")

    /** Any entity on the server; `/api/search` has no type for a subject, so the search looks among those a subject usually is. */
    val MainSubject: EditionProperty = EditionProperty(
        uri = "wdt:P921",
        kind = Kind.AnyEntity(listOf(EntitySearchType.Genres, EntitySearchType.Movements, EntitySearchType.Humans, EntitySearchType.Works)),
        group = Group.Subjects,
        isMultivalued = true,
        labelKey = "entity_property_main_subject",
    )

    val relations: List<EditionProperty> = listOf(
        relation("wdt:P144", Kind.AnyEntity(worksOrSeries), "entity_property_based_on"),
        relation("wdt:P941", Kind.AnyEntity(worksOrSeries), "entity_property_inspired_by"),
        relation("wdt:P1433", Kind.Entity(EntitySearchType.Works), "entity_property_published_in"),
        relation("wdt:P2675", Kind.AnyEntity(worksOrSeries), "entity_property_reply_to"),
    )

    // Databases, links, misc

    val databases: List<EditionProperty> = listOf(
EditionProperty.database("wdt:P268", "edition_property_bnf", """^\d{8}[0-9bcdfghjkmnpqrstvwxz]$""", "123735831"),
EditionProperty.database("wdt:P269", "entity_property_idref", """^\d{8}[\dX]$""", "026927608"),
EditionProperty.database("wdt:P3631", "entity_property_babelio", """^\d+$""", "3874"),
EditionProperty.database("wdt:P648", "edition_property_open_library", """^OL[1-9]\d{0,7}W$""", "OL36858W"),
EditionProperty.database("wdt:P8383", "edition_property_goodreads", """^[1-9]\d*$""", "556821"),
EditionProperty.database("wdt:P10100", "entity_property_senscritique", """^[1-9]\d*$""", "26922520"),
EditionProperty.database("wdt:P214", "edition_property_viaf", """^[1-9]\d(\d{0,7}|\d{17,20})$""", "120062731"),
EditionProperty.database("wdt:P227", "edition_property_gnd", """^1[01]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]$""", "4079154-3"),
EditionProperty.database("wdt:P243", "edition_property_oclc", """^0*[1-9]\d*$""", "57722711"),
EditionProperty.database("wdt:P5331", "entity_property_oclc_work", """^[1-9]\d*$""", "203314739"),
EditionProperty.database("wdt:P244", "entity_property_library_of_congress", """^(gf|n|nb|nr|no|ns|sh|sj)([4-9][0-9]|00|20[0-2][0-9])[0-9]{6}$""", "n79022935"),
EditionProperty.database("wdt:P950", "edition_property_bne", """^XX\d{4,7}$""", "XX1718747"),
EditionProperty.database("wdt:P1085", "entity_property_librarything", """^\d{1,8}$""", "337646"),
EditionProperty.database("wdt:P1274", "edition_property_isfdb", """^[1-9]\d{0,6}$""", "68494"),
EditionProperty.database("wdt:P5571", "edition_property_noosfere", """^[1-9]\d*$""", "4638"),
EditionProperty.database("wdt:P6221", "entity_property_noosfere_story", """^[1-9]\d*$""", "3640"),
EditionProperty.database("wdt:P7823", "edition_property_bookbrainz", """[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}""", "9e631014-cc9a-4ae9-8abb-90b49424db11"),
EditionProperty.database("wdt:P1984", "entity_property_anime_news_network", """^[1-9]\d*$""", "2440"),
EditionProperty.database("wdt:P4087", "entity_property_myanimelist", """^\d+$""", "46024"),
EditionProperty.database("wdt:P11308", "entity_property_grand_comics_database", """^[1-9]\d*$""", "52303"),
    )

    val DifferentFrom: EditionProperty =
        EditionProperty("wdt:P1889", Kind.AnyEntity(worksOrSeries), Group.Misc, true, "entity_property_different_from")

    /** Every property of a work, in the order « Modifier l'œuvre » shows them. A work's links are an edition's ten. */
    val all: List<EditionProperty> =
        listOf(Type, Form, OriginalLanguage, FirstPublicationDate, Author) + roles + comicRoles +
            listOf(Series, SeriesOrdinal, Genre, MainSubject) + relations + databases + EditionProperty.links + DifferentFrom

    private val worksOrSeries: List<EntitySearchType>
        get() = listOf(EntitySearchType.Works, EntitySearchType.Series)

    private fun relation(uri: String, kind: Kind, labelKey: String): EditionProperty =
        EditionProperty(uri, kind, Group.Relations, true, labelKey)
}
