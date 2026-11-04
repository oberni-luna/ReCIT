package studio.lunabee.nouveaurecit.ui.editedition

import androidx.annotation.StringRes
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.CreateBookFailure
import studio.lunabee.nouveaurecit.data.creation.EditionFormat
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EditionPropertyChoice

/**
 * The names the forms print for the properties of every catalogue — an edition's, a work's, a person's —,
 * for the choices of a work's type and form, and for formats. `EditionProperty.labelKey` and
 * `EditionPropertyChoice.labelKey` name a string resource; the table turns it into its id at compile time
 * rather than looking it up by name at run time, which R8 could not see and lint discourages.
 * `EditionPropertyLabelsTest` checks that every property and choice is in it.
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
        "entity_property_anime_news_network" to R.string.entity_property_anime_news_network,
        "entity_property_author" to R.string.entity_property_author,
        "entity_property_babelio" to R.string.entity_property_babelio,
        "entity_property_based_on" to R.string.entity_property_based_on,
        "entity_property_bd_gest" to R.string.entity_property_bd_gest,
        "entity_property_birth_date" to R.string.entity_property_birth_date,
        "entity_property_bnb" to R.string.entity_property_bnb,
        "entity_property_cairn" to R.string.entity_property_cairn,
        "entity_property_colorist" to R.string.entity_property_colorist,
        "entity_property_death_date" to R.string.entity_property_death_date,
        "entity_property_different_from" to R.string.entity_property_different_from,
        "entity_property_first_publication_date" to R.string.entity_property_first_publication_date,
        "entity_property_genre" to R.string.entity_property_genre,
        "entity_property_google_scholar" to R.string.entity_property_google_scholar,
        "entity_property_grand_comics_database" to R.string.entity_property_grand_comics_database,
        "entity_property_idref" to R.string.entity_property_idref,
        "entity_property_influenced_by" to R.string.entity_property_influenced_by,
        "entity_property_inker" to R.string.entity_property_inker,
        "entity_property_inspired_by" to R.string.entity_property_inspired_by,
        "entity_property_isni" to R.string.entity_property_isni,
        "entity_property_letterer" to R.string.entity_property_letterer,
        "entity_property_library_of_congress" to R.string.entity_property_library_of_congress,
        "entity_property_librarything" to R.string.entity_property_librarything,
        "entity_property_linkedin" to R.string.entity_property_linkedin,
        "entity_property_main_subject" to R.string.entity_property_main_subject,
        "entity_property_movement" to R.string.entity_property_movement,
        "entity_property_myanimelist" to R.string.entity_property_myanimelist,
        "entity_property_ndl" to R.string.entity_property_ndl,
        "entity_property_noosfere_story" to R.string.entity_property_noosfere_story,
        "entity_property_nta" to R.string.entity_property_nta,
        "entity_property_oclc_work" to R.string.entity_property_oclc_work,
        "entity_property_orcid" to R.string.entity_property_orcid,
        "entity_property_original_language" to R.string.entity_property_original_language,
        "entity_property_penciller" to R.string.entity_property_penciller,
        "entity_property_pseudonym" to R.string.entity_property_pseudonym,
        "entity_property_published_in" to R.string.entity_property_published_in,
        "entity_property_reply_to" to R.string.entity_property_reply_to,
        "entity_property_scenarist" to R.string.entity_property_scenarist,
        "entity_property_selibr" to R.string.entity_property_selibr,
        "entity_property_senscritique" to R.string.entity_property_senscritique,
        "entity_property_series" to R.string.entity_property_series,
        "entity_property_series_ordinal" to R.string.entity_property_series_ordinal,
        "entity_property_storygraph" to R.string.entity_property_storygraph,
        "entity_property_theses_fr" to R.string.entity_property_theses_fr,
        "entity_property_work_form" to R.string.entity_property_work_form,
        "entity_property_work_type" to R.string.entity_property_work_type,
        "entity_property_writing_languages" to R.string.entity_property_writing_languages,
        "work_type_comic" to R.string.work_type_comic,
        "work_type_graphic_novel" to R.string.work_type_graphic_novel,
        "work_type_literary_work" to R.string.work_type_literary_work,
        "work_type_manga" to R.string.work_type_manga,
        "work_type_manhwa" to R.string.work_type_manhwa,
        "work_type_written_work" to R.string.work_type_written_work,
        "work_form_anthology" to R.string.work_form_anthology,
        "work_form_catalog" to R.string.work_form_catalog,
        "work_form_conference_proceedings" to R.string.work_form_conference_proceedings,
        "work_form_diary" to R.string.work_form_diary,
        "work_form_dictionary" to R.string.work_form_dictionary,
        "work_form_encyclopedia" to R.string.work_form_encyclopedia,
        "work_form_essay" to R.string.work_form_essay,
        "work_form_exhibition_catalogue" to R.string.work_form_exhibition_catalogue,
        "work_form_fairy_tale_collection" to R.string.work_form_fairy_tale_collection,
        "work_form_fix_up" to R.string.work_form_fix_up,
        "work_form_gamebook" to R.string.work_form_gamebook,
        "work_form_graphic_novel" to R.string.work_form_graphic_novel,
        "work_form_journal" to R.string.work_form_journal,
        "work_form_letter_collection" to R.string.work_form_letter_collection,
        "work_form_monograph" to R.string.work_form_monograph,
        "work_form_novel" to R.string.work_form_novel,
        "work_form_novel_collection" to R.string.work_form_novel_collection,
        "work_form_novelette" to R.string.work_form_novelette,
        "work_form_novelette_collection" to R.string.work_form_novelette_collection,
        "work_form_novella" to R.string.work_form_novella,
        "work_form_novella_collection" to R.string.work_form_novella_collection,
        "work_form_play" to R.string.work_form_play,
        "work_form_poem" to R.string.work_form_poem,
        "work_form_poetry_anthology" to R.string.work_form_poetry_anthology,
        "work_form_poetry_collection" to R.string.work_form_poetry_collection,
        "work_form_short_story" to R.string.work_form_short_story,
        "work_form_short_story_anthology" to R.string.work_form_short_story_anthology,
        "work_form_short_story_collection" to R.string.work_form_short_story_collection,
        "work_form_textbook" to R.string.work_form_textbook,
        "work_form_thesis" to R.string.work_form_thesis,
        "work_form_treatise" to R.string.work_form_treatise,
    )

    /** The property's name; the format's as a fallback, which no property of the catalogue needs. */
    @StringRes
    fun label(property: EditionProperty): Int = byKey[property.labelKey] ?: R.string.edition_property_format

    fun hasLabel(property: EditionProperty): Boolean = property.labelKey in byKey

    /** A choice's name. Every choice of the catalogues has one (`EditionPropertyLabelsTest`). */
    @StringRes
    fun label(choice: EditionPropertyChoice): Int = byKey[choice.labelKey] ?: R.string.edition_choice_none

    fun hasLabel(choice: EditionPropertyChoice): Boolean = choice.labelKey in byKey

    /** `CreateBookFailure+EditEntity`: a refusal said of a work or a person, the rest as of an edition. */
    fun entityEditBody(failure: CreateBookFailure): Int = when (failure) {
        CreateBookFailure.Refused -> R.string.edit_entity_failure_refused_body
        else -> editBody(failure)
    }

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
