package studio.lunabee.nouveaurecit.ui.profile.account

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.auth.model.PasswordResetOutcome
import studio.lunabee.nouveaurecit.data.user.PasswordChangeFailure

/**
 * `ChangePasswordView`'s state (iOS feature 0055): the current password, the new one, and the save —
 * server first, a refusal said under the fields. « Mot de passe oublié ? » sends the same reset link as
 * the sign-in screen, to the account's address.
 */
class ChangePasswordViewModel(private val container: AppContainer) : ViewModel() {
    private val _state: MutableStateFlow<ChangePasswordUiState> = MutableStateFlow(ChangePasswordUiState())
    val state: StateFlow<ChangePasswordUiState> = _state.asStateFlow()

    /** The address the reset link goes to, when the account's settings are read. */
    val email: String? get() = container.account.settings.value?.email

    fun setCurrent(text: String) = _state.update { it.copy(current = text, failure = null) }

    fun setNew(text: String) = _state.update { it.copy(new = text) }

    fun save() {
        val current: ChangePasswordUiState = _state.value
        if (!current.canSave) return
        _state.update { it.copy(isSaving = true, failure = null) }
        viewModelScope.launch {
            try {
                container.account.changePassword(current = current.current, new = current.new)
                _state.update { it.copy(isSaving = false, isSaved = true) }
            } catch (failure: PasswordChangeFailure) {
                _state.update { it.copy(isSaving = false, failure = failure.reason) }
            }
        }
    }

    /** « Mot de passe oublié ? »: [onOutcome] says what was done. */
    fun requestReset(email: String, onOutcome: (PasswordResetOutcome) -> Unit) {
        if (_state.value.isRequestingReset) return
        _state.update { it.copy(isRequestingReset = true) }
        viewModelScope.launch {
            try {
                onOutcome(container.auth.requestPasswordReset(email))
            } finally {
                _state.update { it.copy(isRequestingReset = false) }
            }
        }
    }
}
