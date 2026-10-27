package studio.lunabee.nouveaurecit.data.creation

import java.util.UUID

/**
 * `NewBookDraft` (features 0020, iOS 0047 and 0050): what the user has told us about a book inventaire.io
 * does not have yet. The form fills it, [ResolveRequestBuilder] turns it into a request, and nothing else
 * reads it.
 *
 * Two shapes, decided by the work search: a work inventaire.io already has — [workUri] names it, and only
 * the edition is described; or a work of the user's own — its title and authors are described too, and
 * created with the edition. The ISBN comes from the camera and is never edited. Everything else
 * inventaire.io accepts on an edition is [properties], the same value « Modifier l'édition » holds.
 *
 * The scanner's form of feature 0043 asks for no work title: the work being created is then named after
 * the edition ([workLabel]), as it always was.
 */
data class NewBookDraft(
    /** The barcode, as the camera read it; [normalizedIsbn] is what goes on the wire. */
    val isbn: String,
    /** The title printed on *this* edition's cover, which is not necessarily the work's. */
    val title: String = "",
    /** The subtitle printed on this edition, if any. */
    val subtitle: String = "",
    /** The publisher, collection, date, language, format, contributors, identifiers and links. */
    val properties: EditionProperties = EditionProperties(),
    /** The title of the work being created, when none of the works found was the book. */
    val workTitle: String = "",
    /** Who wrote the work being created — each one inventaire.io already has, or one created with the book. */
    val authors: List<NewBookAuthor> = emptyList(),
    /** The cover photographed, as a local JPEG file, before it has been sent anywhere. */
    val coverImagePath: String? = null,
    /** Where that photograph ended up once uploaded, absolute; `null` without one, or when the upload failed. */
    val coverImageUrl: String? = null,
    /** A work inventaire.io already has — picked from the search, or recognised by the dry run. */
    val workUri: String? = null,
    /** The work picked from the search, kept to show it back at the head of « Nouvelle édition ». */
    val chosenWork: WorkCandidate? = null,
    /** Asked at most once per draft: « no, it is another book » is not asked again on the retry. */
    val hasAnsweredWorkQuestion: Boolean = false,
    /** What the ISBN says about the language, once asked; `null` for good if the call fails. */
    val language: EditionLanguage? = null,
) {
    /** The ISBN without separators, as inventaire.io keys editions. `X`, an ISBN-10 check digit, survives. */
    val normalizedIsbn: String get() = normalizeIsbn(isbn)

    val trimmedTitle: String get() = title.trim()

    val trimmedSubtitle: String get() = subtitle.trim()

    val trimmedWorkTitle: String get() = workTitle.trim()

    /** The label of the work being created: its own title, or the edition's when none was asked for. */
    val workLabel: String get() = trimmedWorkTitle.ifEmpty { trimmedTitle }

    /** The authors worth sending: a row left without a name is no author. */
    val namedAuthors: List<NewBookAuthor> get() = authors.filter { it.trimmedName.isNotEmpty() }

    /** The language the labels of what is created are written in: the ISBN's, or the reader's. */
    val labelLanguage: String get() = language?.code ?: ResolveRequestBuilder.defaultLabelLanguage

    /**
     * Whether there is enough to publish. An edition with no title is unreadable in every list. A work
     * being created needs an author too — one with none is an orphan someone has to repair by hand — while
     * a work that exists brings its own. A collection is created under its publisher.
     */
    val isPublishable: Boolean
        get() = trimmedTitle.isNotEmpty() &&
            !properties.hasOrphanCollection &&
            (workUri != null || (workLabel.isNotEmpty() && namedAuthors.isNotEmpty()))

    /** Whether the draft names a work: one inventaire.io has, or one being described. */
    val hasWork: Boolean get() = workUri != null || trimmedWorkTitle.isNotEmpty()

    /** Whether the edition's title is still the one this draft gave it — empty, or copied from a work. */
    private val titleFollowsWork: Boolean
        get() = trimmedTitle.isEmpty() || title == workTitle || title == chosenWork?.title

    /**
     * What the ISBN says becomes the edition's language, unless one was chosen: the form shows it, and
     * the user can change it there.
     */
    fun withLanguage(language: EditionLanguage): NewBookDraft {
        val properties: EditionProperties = if (properties.entities(EditionProperty.Language).isEmpty()) {
            properties.add(EditionEntityValue(uri = language.uri, label = language.displayName() ?: language.code), EditionProperty.Language)
        } else {
            properties
        }
        return copy(language = language, properties = properties)
    }

    /** What a swipe on « Détacher » takes away: the work, picked or being described. */
    fun detachWork(): NewBookDraft = copy(
        chosenWork = null,
        workUri = null,
        workTitle = "",
        authors = emptyList(),
        hasAnsweredWorkQuestion = false,
    )

    /** Attaches the edition to a work inventaire.io has; its title starts as the work's. */
    fun choose(work: WorkCandidate): NewBookDraft = copy(
        title = if (titleFollowsWork) work.title else title,
        chosenWork = work,
        workUri = work.uri,
        // Picked by the user: there is nothing left for the dry run to ask.
        hasAnsweredWorkQuestion = true,
    )

    /** Leaves the works the search proposed, to describe one of the user's own, named after the search. */
    fun startNewWork(query: String): NewBookDraft {
        val named: String = capitalizingFirstLetter(query.trim())
        return copy(
            title = if (titleFollowsWork) named else title,
            workTitle = named,
            chosenWork = null,
            workUri = null,
            hasAnsweredWorkQuestion = false,
        )
    }

    /** Renames the work being created, carrying the edition's title along while the user has not made it theirs. */
    fun renameWork(newTitle: String): NewBookDraft =
        copy(title = if (titleFollowsWork) newTitle else title, workTitle = newTitle)

    /** Records the uri a publisher, a collection or a person the edition names was created under. */
    fun entityCreated(id: UUID, uri: String): NewBookDraft = copy(properties = properties.entityCreated(id, uri))

    companion object {
        fun normalizeIsbn(isbn: String): String = isbn.uppercase().filter { it.isDigit() || it == 'X' }

        /**
         * A title as a search is typed — « étincelles écosocialistes » — made into one as a cover prints it.
         * Only the first letter: the rest of a title's capitals follow rules of its language.
         */
        fun capitalizingFirstLetter(text: String): String = text.replaceFirstChar { it.uppercase() }
    }
}
