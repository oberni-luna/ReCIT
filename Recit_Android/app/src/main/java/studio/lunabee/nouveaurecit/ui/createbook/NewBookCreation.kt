package studio.lunabee.nouveaurecit.ui.createbook

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.creation.NewBookDraft
import studio.lunabee.nouveaurecit.data.creation.NewBookDrafts
import studio.lunabee.nouveaurecit.data.creation.NewBookOrigin

/**
 * « Nouveau livre » as its openers hold it: the [CreateBookSession] while the form is up, and the
 * [NewBookDrafts] it leaves behind. The scanner and Recherche each keep one in their view model's scope,
 * and only say what a created book becomes.
 */
class NewBookCreation(
    private val container: AppContainer,
    private val scope: CoroutineScope,
) {
    private val drafts: NewBookDrafts = NewBookDrafts()
    private val _session: MutableStateFlow<CreateBookSession?> = MutableStateFlow(null)

    /** The form, while it is up. */
    val session: StateFlow<CreateBookSession?> = _session.asStateFlow()

    /**
     * Opens the form on [origin], on the draft left from a previous attempt if any; nothing while one is
     * up. Once the book exists and is filed, the draft is forgotten, the form goes, and [onCreated] is told.
     */
    fun open(
        origin: NewBookOrigin,
        onCreated: (editionUri: String, draft: NewBookDraft) -> Unit,
    ) {
        if (_session.value != null) return
        _session.value = CreateBookSession(
            container = container,
            parentScope = scope,
            origin = origin,
            draft = drafts.draft(origin),
            onCreated = { uri, draft ->
                drafts.forget(origin)
                _session.value?.cancel()
                _session.value = null
                onCreated(uri, draft)
            },
        )
    }

    /** Whatever takes the form away keeps what was typed. */
    fun close() {
        val session: CreateBookSession = _session.value ?: return
        drafts.remember(session.draft, session.origin)
        session.cancel()
        _session.value = null
    }
}
