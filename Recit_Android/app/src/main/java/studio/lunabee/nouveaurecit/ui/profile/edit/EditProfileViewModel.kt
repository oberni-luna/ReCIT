package studio.lunabee.nouveaurecit.ui.profile.edit

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.user.Coordinates
import studio.lunabee.nouveaurecit.data.user.ProfileDraft
import studio.lunabee.nouveaurecit.data.user.ProfileSaveFailure

/**
 * `EditProfileView`'s state (iOS feature 0055): the draft, the live check of the name, and the save.
 *
 * One « Enregistrer », server first: `PUT /api/user` takes a single attribute per request, so
 * [ProfileDraft] lists what changed and the repository sends it in order. A refusal part of the way keeps
 * what went through, says what did not, and the next « Enregistrer » sends only the rest. The screen
 * closes once everything has landed.
 *
 * The position is placed on a page of this view model rather than a destination of the stack, as
 * « Modifier l'édition » does with its pages: it edits the draft, which must never outlive the form.
 */
class EditProfileViewModel(private val container: AppContainer) : ViewModel() {
    private val _state: MutableStateFlow<EditProfileUiState> = MutableStateFlow(EditProfileUiState())
    val state: StateFlow<EditProfileUiState> = _state.asStateFlow()
    private var usernameCheck: Job? = null

    init {
        // The draft starts from my user once; the picture shown follows the store, which takes each
        // picture as it lands.
        viewModelScope.launch {
            container.users.myUser.filterNotNull().collect { me: UserEntity ->
                _state.update { it.copy(draft = it.draft ?: ProfileDraft.of(me), savedPictureUrl = me.avatarUrl) }
            }
        }
    }

    fun setPicture(path: String) = updateDraft { it.copy(picture = ProfileDraft.Picture.Replaced(path)) }

    fun removePicture() = updateDraft { it.copy(picture = ProfileDraft.Picture.Removed) }

    fun setBio(text: String) = updateDraft { it.copy(bio = text) }

    /**
     * The name typed, then one live check, debounced as at sign-up — the availability endpoint answers
     * `429` to a request a keystroke. The account's own name, in any case, is never asked about: the
     * server would call it taken.
     */
    fun setUsername(text: String) {
        updateDraft { it.copy(username = text) }
        usernameCheck?.cancel()
        if (_state.value.draft?.usernameNeedsCheck != true) return
        _state.update { it.copy(usernameCheck = it.usernameCheck.edited(text.trim())) }
        val query: String = _state.value.usernameCheck.pendingQuery ?: return
        usernameCheck = viewModelScope.launch {
            delay(CHECK_DELAY_MS)
            val outcome: FieldAvailability.Outcome = container.auth.usernameAvailability(query)
            _state.update { it.copy(usernameCheck = it.usernameCheck.apply(outcome, query)) }
        }
    }

    fun openPosition() = _state.update { it.copy(isPlacingPosition = true) }

    fun closePosition() = _state.update { it.copy(isPlacingPosition = false) }

    /** The position's page hands back the centre of the map, or `null` to take the position away. */
    fun placePosition(coordinates: Coordinates?) {
        _state.update { it.copy(draft = it.draft?.placed(coordinates), isPlacingPosition = false) }
    }

    fun save() {
        val current: EditProfileUiState = _state.value
        val draft: ProfileDraft = current.draft ?: return
        if (!current.canSave) return
        _state.update { it.copy(isSaving = true) }
        viewModelScope.launch {
            try {
                container.profile.saveProfile(draft.changes)
                _state.update { it.copy(isSaving = false, failure = null, isSaved = true) }
            } catch (failure: ProfileSaveFailure) {
                _state.update { it.copy(isSaving = false, failure = failure, draft = it.draft?.markLanded(failure.landed)) }
            }
        }
    }

    private fun updateDraft(transform: (ProfileDraft) -> ProfileDraft) {
        _state.update { state -> state.copy(draft = state.draft?.let(transform)) }
    }

    private companion object {
        const val CHECK_DELAY_MS: Long = 600
    }
}
