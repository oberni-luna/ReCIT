package studio.lunabee.nouveaurecit.ui.editedition

import androidx.annotation.StringRes
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.CreateBookFailure
import studio.lunabee.nouveaurecit.data.creation.EditionFormat
import studio.lunabee.nouveaurecit.data.creation.EditionProperty

/**
 * The names the form prints for the catalogue's properties and formats. `EditionProperty.labelKey` names
 * a string resource; the table turns it into its id at compile time rather than looking it up by name at
 * run time, which R8 could not see and lint discourages. `EditionPropertyLabelsTest` checks that every
 * property of the catalogue is in it.
 */
object EditionPropertyLabels {
    private val byKey: Map<String, Int> = mapOf(
        "edition_property_publisher" to R.string.edition_property_publisher,
        "edition_property_collection" to R.string.edition_property_collection,
        "edition_property_publication_date" to R.string.edition_property_publication_date,
        "edition_property_language" to R.string.edition_property_language,
        "edition_property_format" to R.string.edition_property_format,
        "edition_property_pages" to R.string.edition_property_pages,
        "edition_property_volumes" to R.string.edition_property_volumes,
        "edition_property_translator" to R.string.edition_property_translator,
        "edition_property_illustrator" to R.string.edition_property_illustrator,
        "edition_property_cover_artist" to R.string.edition_property_cover_artist,
        "edition_property_preface" to R.string.edition_property_preface,
        "edition_property_afterword" to R.string.edition_property_afterword,
        "edition_property_editor" to R.string.edition_property_editor,
        "edition_property_bnf" to R.string.edition_property_bnf,
        "edition_property_open_library" to R.string.edition_property_open_library,
        "edition_property_sudoc" to R.string.edition_property_sudoc,
        "edition_property_viaf" to R.string.edition_property_viaf,
        "edition_property_oclc" to R.string.edition_property_oclc,
        "edition_property_google_books" to R.string.edition_property_google_books,
        "edition_property_goodreads" to R.string.edition_property_goodreads,
        "edition_property_bookbrainz" to R.string.edition_property_bookbrainz,
        "edition_property_noosfere" to R.string.edition_property_noosfere,
        "edition_property_isfdb" to R.string.edition_property_isfdb,
        "edition_property_dnb" to R.string.edition_property_dnb,
        "edition_property_gnd" to R.string.edition_property_gnd,
        "edition_property_swb" to R.string.edition_property_swb,
        "edition_property_bne" to R.string.edition_property_bne,
        "edition_property_lccn" to R.string.edition_property_lccn,
        "edition_property_british_library" to R.string.edition_property_british_library,
        "edition_property_libris" to R.string.edition_property_libris,
        "edition_property_bn_argentina" to R.string.edition_property_bn_argentina,
        "edition_property_czech_national_bibliography" to R.string.edition_property_czech_national_bibliography,
        "edition_property_hathitrust" to R.string.edition_property_hathitrust,
        "edition_property_runeberg" to R.string.edition_property_runeberg,
        "edition_property_doi" to R.string.edition_property_doi,
        "edition_property_official_website" to R.string.edition_property_official_website,
        "edition_property_blog" to R.string.edition_property_blog,
        "edition_property_mastodon" to R.string.edition_property_mastodon,
        "edition_property_bluesky" to R.string.edition_property_bluesky,
        "edition_property_instagram" to R.string.edition_property_instagram,
        "edition_property_facebook" to R.string.edition_property_facebook,
        "edition_property_x" to R.string.edition_property_x,
        "edition_property_youtube" to R.string.edition_property_youtube,
        "edition_property_threads" to R.string.edition_property_threads,
        "edition_property_tiktok" to R.string.edition_property_tiktok,
    )

    /** The property's name; the format's as a fallback, which no property of the catalogue needs. */
    @StringRes
    fun label(property: EditionProperty): Int = byKey[property.labelKey] ?: R.string.edition_property_format

    fun hasLabel(property: EditionProperty): Boolean = property.labelKey in byKey

    @StringRes
    fun name(format: EditionFormat): Int = when (format) {
        EditionFormat.Paperback -> R.string.edition_format_paperback
        EditionFormat.Hardback -> R.string.edition_format_hardback
        EditionFormat.Pocket -> R.string.edition_format_pocket
        EditionFormat.ComicAlbum -> R.string.edition_format_comic_album
        EditionFormat.Ebook -> R.string.edition_format_ebook
        EditionFormat.Audiobook -> R.string.edition_format_audiobook
    }

    /** `CreateBookFailure+EditEdition`: the three failures said of a change, where nothing is created. */
    fun editTitle(failure: CreateBookFailure): Int = when (failure) {
        CreateBookFailure.NeedsAccount -> R.string.edit_edition_failure_account_title
        CreateBookFailure.Refused -> R.string.edit_edition_failure_refused_title
        CreateBookFailure.Network -> R.string.edit_edition_failure_network_title
    }

    fun editBody(failure: CreateBookFailure): Int = when (failure) {
        CreateBookFailure.NeedsAccount -> R.string.edit_edition_failure_account_body
        CreateBookFailure.Refused -> R.string.edit_edition_failure_refused_body
        CreateBookFailure.Network -> R.string.edit_edition_failure_network_body
    }
}
