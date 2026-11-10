package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.data.search.IsbnQuery
import java.util.UUID

/**
 * `NewBookDraft` (features 0020, iOS 0047 and 0050): what the user has told us about a book inventaire.io
 * does not have yet. The form fills it, [ResolveRequestBuilder] turns it into a request, and nothing else
 * reads it.
 *
 * Two shapes, decided by the work search: a work inventaire.io already has — [workUri] names it, and only
 * the edition is described; or a work of the user's own — its title and authors are described too, and
 * created with the edition. The ISBN comes from the camera and is never edited there; from Recherche it is
 * typed, or left empty (iOS feature 0087). Everything else inventaire.io accepts on an edition is
 * [properties], the same value « Modifier l'édition » holds.
 *
 * The scanner's form of feature 0043 asks for no work title: the work being created is then named after
 * the edition ([workLabel]), as it always was.
 */
data class NewBookDraft(
    /** The barcode as the camera read it, or what was typed — possibly nothing; [normalizedIsbn] is what goes on the wire. */
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
    /** The [checkedIsbn] [language] was deduced from. */
    val languageIsbn: String? = null,
) {
    /**
     * The ISBN without separators, as inventaire.io keys editions: [checkedIsbn] once the check digit is
     * right, so a valid ISBN-10 goes out as thirteen digits. Otherwise `X`, an ISBN-10 check digit, survives.
     */
    val normalizedIsbn: String get() = checkedIsbn ?: normalizeIsbn(isbn)

    /** The ISBN as thirteen digits, an ISBN-10 converted, once its check digit is right. `null` while empty, or wrong. */
    val checkedIsbn: String? get() = IsbnQuery.isbn(isbn)

    /** Whether the ISBN can be published: none at all, or one whose check digit is right. */
    val isIsbnValid: Boolean get() = isbn.isBlank() || checkedIsbn != null

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

    /**
     * [isPublishable], and a valid ISBN when it was typed: a scanned ISBN never blocks publishing, a typed
     * one with a wrong check digit does.
     */
    fun isPublishable(isIsbnEditable: Boolean): Boolean = isPublishable && (!isIsbnEditable || isIsbnValid)

    /** Whether the draft names a work: one inventaire.io has, or one being described. */
    val hasWork: Boolean get() = workUri != null || trimmedWorkTitle.isNotEmpty()

    /** Whether the edition's title is still the one this draft gave it — empty, or copied from a work. */
    private val titleFollowsWork: Boolean
        get() = trimmedTitle.isEmpty() || title == workTitle || title == chosenWork?.title

    /**
     * What the ISBN says becomes the edition's language, unless one was chosen: the form shows it, and
     * the user can change it there. What an earlier ISBN said goes first; [isbn] is the one that said it.
     */
    fun withLanguage(language: EditionLanguage, isbn: String? = checkedIsbn): NewBookDraft {
        val draft: NewBookDraft = withoutLanguage()
        val properties: EditionProperties = if (draft.properties.entities(EditionProperty.Language).isEmpty()) {
            draft.properties.add(EditionEntityValue(uri = language.uri, label = language.displayName() ?: language.code), EditionProperty.Language)
        } else {
            draft.properties
        }
        return draft.copy(language = language, languageIsbn = isbn, properties = properties)
    }

    /**
     * What the lookup of [isbn] answered: a language replaces what an earlier ISBN said, and no answer
     * keeps what this same ISBN said before — an ISBN that is gone, or another one, says nothing any more.
     * An answer about an ISBN the draft no longer holds changes nothing.
     */
    fun answeringLanguage(language: EditionLanguage?, isbn: String?): NewBookDraft = when {
        isbn != checkedIsbn -> this
        language != null -> withLanguage(language, isbn)
        isbn != null && isbn == languageIsbn -> this
        else -> withoutLanguage()
    }

    /** Forgets what the ISBN said, and the edition's language with it while it is still the one deduced. */
    fun withoutLanguage(): NewBookDraft {
        val deduced: EditionLanguage = language ?: return this
        val indices: Set<Int> = properties.values(EditionProperty.Language)
            .withIndex()
            .filter { it.value.entityValue?.uri == deduced.uri }
            .map { it.index }
            .toSet()
        return copy(language = null, languageIsbn = null, properties = properties.remove(indices, EditionProperty.Language))
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

    /** An author added to the work being created, unless they are on it already. */
    fun addAuthor(author: NewBookAuthor): NewBookDraft {
        if (author.trimmedName.isEmpty() || authors.any { WorkEdit.isSamePerson(it, author) }) return this
        return copy(authors = authors + author)
    }

    /** What a swipe on one of the work's authors takes away. */
    fun removeAuthor(index: Int): NewBookDraft = copy(authors = authors.filterIndexed { position, _ -> position != index })

    /**
     * Whether « Publier » asks the dry run first: only for a work being created, and once — a work picked
     * from the search is named in `resolve`, and « no, another work » is not asked again on a retry.
     */
    val asksWhichWork: Boolean get() = workUri == null && !hasAnsweredWorkQuestion

    /** The dry run recognised [uri]: the safe answer is the default, one more edition of the work that exists. */
    fun recognised(uri: String): NewBookDraft = copy(workUri = uri, hasAnsweredWorkQuestion = true)

    /**
     * Back from « Œuvre déjà connue » without publishing: the question goes with the page, so the work being
     * described is the user's own again, and the next publication asks anew. A work picked stays picked.
     */
    fun leavingRecognised(uri: String): NewBookDraft =
        if (workUri == uri && chosenWork == null) copy(workUri = null, hasAnsweredWorkQuestion = false) else this

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
