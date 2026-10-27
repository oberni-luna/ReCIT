package studio.lunabee.nouveaurecit.ui.createbook

import studio.lunabee.nouveaurecit.data.creation.NewBookDraft
import studio.lunabee.nouveaurecit.data.creation.WorkCandidate
import studio.lunabee.nouveaurecit.data.creation.WorkEdit
import studio.lunabee.nouveaurecit.ui.editedition.EditionPropertyStep
import studio.lunabee.nouveaurecit.ui.editedition.PageStack
import java.util.UUID

/**
 * `NewBookStep` (iOS features 0047, 0050): what the scanner's « Nouveau livre » pushes over the work
 * search, which is always its root — an empty [PageStack] is the search. What is pushed follows from the
 * answer: a work picked, or one to describe, and on the way to creating it the work inventaire.io
 * recognised after all.
 */
sealed interface CreateBookPage {
    /** « Nouvelle édition »: the edition's form, every property of it. */
    data object Edition : CreateBookPage

    /** « Nouvelle œuvre »: the work being described, its title and authors. */
    data object NewWork : CreateBookPage

    /** The search for an author of the work being described. */
    data object NewWorkAuthor : CreateBookPage

    /** « Œuvre déjà connue »: the dry run recognised the work being created. */
    data class RecognisedWork(val uri: String) : CreateBookPage

    /** « Données bibliographiques », in full. */
    data object Help : CreateBookPage

    /** One of the pages of the catalogue's properties. */
    data class Property(val step: EditionPropertyStep) : CreateBookPage

    companion object {
        /**
         * Where a draft left from an earlier attempt reopens: on the form it was being written in, rather
         * than on a search the user has already answered.
         */
        fun resuming(draft: NewBookDraft): PageStack<CreateBookPage> = if (draft.hasWork) PageStack(listOf(Edition)) else PageStack()

        /** A work inventaire.io has was picked: only the edition is left to describe. */
        val afterChoosingWork: PageStack<CreateBookPage> = PageStack(listOf(Edition))

        /** None of the works fits: the edition's form, with the work's own page over it — it needs an author. */
        val afterStartingNewWork: PageStack<CreateBookPage> = PageStack(listOf(Edition, NewWork))
    }
}

/** The few decisions « Nouvelle édition » makes on its own, kept out of the composables so they are tested. */
object CreateBookRules {
    /** What « Édition de » says under the work (`NewEditionWorkSection.footer`). */
    enum class WorkFooter { Chosen, NewWork, None }

    fun workFooter(draft: NewBookDraft): WorkFooter = when {
        draft.chosenWork != null -> WorkFooter.Chosen
        draft.hasWork -> WorkFooter.NewWork
        else -> WorkFooter.None
    }

    /** The work being described, as its row draws it. */
    fun newWorkCandidate(draft: NewBookDraft): WorkCandidate = WorkCandidate(
        uri = "",
        title = draft.trimmedWorkTitle,
        authors = draft.namedAuthors.map { it.trimmedName },
    )

    /** The work being described, in the shape « Modifier l'œuvre » edits — the page « Nouvelle œuvre » reuses. */
    fun newWork(draft: NewBookDraft): WorkEdit = WorkEdit(id = NEW_WORK_ID, original = null, title = draft.workTitle, authors = draft.authors)

    /** The draft describes one work at most: its page needs no identity of its own. */
    private val NEW_WORK_ID: UUID = UUID(0, 0)
}
