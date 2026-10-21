package studio.lunabee.nouveaurecit.data.creation

/**
 * `NewBookDraft` (feature 0020): what the user has told us about a book inventaire.io does not have yet.
 * The form fills it, [ResolveRequestBuilder] turns it into a request, and nothing else reads it.
 *
 * Only the title and the author are asked for — the two things the barcode cannot answer. The ISBN
 * comes from the camera and is never edited.
 */
data class NewBookDraft(
    /** The barcode, as the camera read it; [normalizedIsbn] is what goes on the wire. */
    val isbn: String,
    /** The title printed on *this* edition's cover, which is not necessarily the work's. */
    val title: String = "",
    /** The author's name as chosen or typed. A label on a new author, or only a display once [authorUri] is set. */
    val authorName: String = "",
    /** An author inventaire.io already has. `null` means the author is created, described by label. */
    val authorUri: String? = null,
    /** What told this author apart from a namesake, kept to show it back in the form. */
    val authorDescription: String? = null,
    /** The cover photographed, as a local JPEG file, before it has been sent anywhere. */
    val coverImagePath: String? = null,
    /** Where that photograph ended up once uploaded; `null` without one, or when the upload failed. */
    val coverImageUrl: String? = null,
    /** A work inventaire.io already has, once the user agreed this book is one more edition of it. */
    val workUri: String? = null,
    /** Asked at most once per draft: « no, it is another book » is not asked again on the retry. */
    val hasAnsweredWorkQuestion: Boolean = false,
    /** What the ISBN says about the language, once asked; `null` for good if the call fails. */
    val language: EditionLanguage? = null,
) {
    /** The ISBN without separators, as inventaire.io keys editions. `X`, an ISBN-10 check digit, survives. */
    val normalizedIsbn: String get() = normalizeIsbn(isbn)

    val trimmedTitle: String get() = title.trim()

    val trimmedAuthorName: String get() = authorName.trim()

    /**
     * Both answers are required: an edition with no title is unreadable in every list, and a work with
     * no author is an orphan someone has to repair by hand on the website.
     */
    val isPublishable: Boolean get() = trimmedTitle.isNotEmpty() && trimmedAuthorName.isNotEmpty()

    companion object {
        fun normalizeIsbn(isbn: String): String = isbn.uppercase().filter { it.isDigit() || it == 'X' }
    }
}
