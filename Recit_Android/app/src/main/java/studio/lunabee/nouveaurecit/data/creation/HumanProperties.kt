package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.data.creation.EditionProperty.Group
import studio.lunabee.nouveaurecit.data.creation.EditionProperty.Kind

/**
 * `EditionProperty+Human` (iOS feature 0057): what inventaire.io accepts on a person, read on 2026-10-28
 * from `GET /api/data/properties` (the `subjectTypes` that hold `human`) and
 * `properties_values_constraints.ts`. « Modifier l'auteur·ice ».
 *
 * Left out: `wdt:P31`, whose one allowed value is « être humain », `invp:P1` and `invp:P3`. A person's name
 * is a label per language, and their portrait comes from Wikidata — `invp:P2` is an edition's alone.
 */
object HumanProperties {
    // L'auteur·ice

    val Pseudonym: EditionProperty = EditionProperty("wdt:P742", Kind.Text, Group.General, true, "entity_property_pseudonym")
    val WritingLanguages: EditionProperty =
        EditionProperty("wdt:P1412", Kind.Entity(EntitySearchType.Languages), Group.General, true, "entity_property_writing_languages")
    val BirthDate: EditionProperty = EditionProperty("wdt:P569", Kind.Date, Group.General, false, "entity_property_birth_date")
    val DeathDate: EditionProperty = EditionProperty("wdt:P570", Kind.Date, Group.General, false, "entity_property_death_date")

    // Courant et influences

    val Movement: EditionProperty =
        EditionProperty("wdt:P135", Kind.Entity(EntitySearchType.Movements), Group.Influences, true, "entity_property_movement")
    val InfluencedBy: EditionProperty = EditionProperty.person("wdt:P737", "entity_property_influenced_by", Group.Influences)

    // Databases, links, misc

    val databases: List<EditionProperty> = listOf(
EditionProperty.database("wdt:P213", "entity_property_isni", """^[0]{7}[0-9]{8}[0-9X]$""", "0000000122974701"),
EditionProperty.database("wdt:P268", "edition_property_bnf", """^\d{8}[0-9bcdfghjkmnpqrstvwxz]$""", "123735831"),
EditionProperty.database("wdt:P269", "entity_property_idref", """^\d{8}[\dX]$""", "026927608"),
EditionProperty.database("wdt:P3630", "entity_property_babelio", """^\d+$""", "2615"),
EditionProperty.database("wdt:P648", "edition_property_open_library", """^OL[1-9]\d{0,7}A$""", "OL396182A"),
EditionProperty.database("wdt:P2963", "edition_property_goodreads", """^[1-9]\d*$""", "428754"),
EditionProperty.database("wdt:P14412", "entity_property_senscritique", """^[1-9]\d*$""", "1140742"),
EditionProperty.database("wdt:P214", "edition_property_viaf", """^[1-9]\d(\d{0,7}|\d{17,20})$""", "120062731"),
EditionProperty.database("wdt:P227", "edition_property_gnd", """^1[01]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]$""", "4079154-3"),
EditionProperty.database("wdt:P243", "edition_property_oclc", """^0*[1-9]\d*$""", "57722711"),
EditionProperty.database("wdt:P244", "entity_property_library_of_congress", """^(gf|n|nb|nr|no|ns|sh|sj)([4-9][0-9]|00|20[0-2][0-9])[0-9]{6}$""", "n79022935"),
EditionProperty.database("wdt:P496", "entity_property_orcid", """^\d{4}-\d{4}-\d{4}-\d{3}[\dX]$""", "0000-0002-1003-5675"),
EditionProperty.database("wdt:P4285", "entity_property_theses_fr", """^\d{8}[\dX]$""", "026779528"),
EditionProperty.database("wdt:P4369", "entity_property_cairn", """^[1-9]\d{0,5}$""", "6930"),
EditionProperty.database("wdt:P1960", "entity_property_google_scholar", """^[\w-]{12}$""", "CUO0vDcAAAAJ"),
EditionProperty.database("wdt:P950", "edition_property_bne", """^XX\d{4,7}$""", "XX1718747"),
EditionProperty.database("wdt:P5361", "entity_property_bnb", """^[^ ?.=]{2,80}$""", "ShakespeareWilliam1564-1616"),
EditionProperty.database("wdt:P349", "entity_property_ndl", """^(a1|s)?[0-9]?\d{8}$""", "00564222"),
EditionProperty.database("wdt:P906", "entity_property_selibr", """^[1-9]\d{4,5}$""", "207435"),
EditionProperty.database("wdt:P1006", "entity_property_nta", """^\d{8}(\d|X)$""", "069071632"),
EditionProperty.database("wdt:P7400", "entity_property_librarything", """^[^\s/]+$""", "longemmajde"),
EditionProperty.database("wdt:P1233", "edition_property_isfdb", """^[1-9]\d{0,5}$""", "5"),
EditionProperty.database("wdt:P5570", "edition_property_noosfere", """^-?[1-9]\d*$""", "16"),
EditionProperty.database("wdt:P5491", "entity_property_bd_gest", """^[1-9]\d*$""", "11154"),
EditionProperty.database("wdt:P2607", "edition_property_bookbrainz", """[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}""", "5291de51-0ec8-473e-98a3-baf5a7500ef3"),
EditionProperty.database("wdt:P12430", "entity_property_storygraph", """[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}""", "9652222f-c517-42c7-bbe6-06e45afaac19"),
EditionProperty.database("wdt:P1982", "entity_property_anime_news_network", """^[1-9]\d{0,5}$""", "15"),
EditionProperty.database("wdt:P4084", "entity_property_myanimelist", """^\d+$""", "1870"),
EditionProperty.database("wdt:P9707", "entity_property_grand_comics_database", """^[1-9]\d*$""", "16448"),
    )

    /** An edition's ten links, and a LinkedIn profile. */
    val links: List<EditionProperty> = EditionProperty.links +
        EditionProperty.link("wdt:P6634", "entity_property_linkedin", """^[\p{L}0-9\-&_'’.]+$""", "jbkempf")

    val DifferentFrom: EditionProperty = EditionProperty.person("wdt:P1889", "entity_property_different_from", Group.Misc)

    /** Every property of a person, in the order « Modifier l'auteur·ice » shows them. */
    val all: List<EditionProperty> =
        listOf(Pseudonym, WritingLanguages, BirthDate, DeathDate, Movement, InfluencedBy) + databases + links + DifferentFrom
}
