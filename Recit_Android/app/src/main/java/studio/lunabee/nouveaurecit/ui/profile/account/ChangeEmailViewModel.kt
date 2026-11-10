package studio.lunabee.nouveaurecit.ui.profile.account

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.data.user.EmailChangeFailure

/**
 * `ChangeEmailView`'s state (iOS feature 0055): the new address, its live check, and the save — server
 * first. A refusal that names the address (taken, not an address) is said under the field; any other one
 * goes to [save]'s `onFailure`. Either way the old address stays.
 */
class ChangeEmailViewModel(private val container: AppContainer) : ViewModel() {
    private val _state: MutableStateFlow<ChangeEmailUiState> =
        MutableStateFlow(ChangeEmailUiState(current = container.account.settings.value?.email))
    val state: StateFlow<ChangeEmailUiState> = _state.asStateFlow()
    private var emailCheck: Job? = null

    /**
     * The address typed, then one live check, debounced as at sign-up. The account's own address is never
     * asked about: the server would call it taken.
     */
    fun setEmail(text: String) {
        _state.update { it.copy(email = text, check = it.check.edited(text.trim())) }
        emailCheck?.cancel()
        val current: ChangeEmailUiState = _state.value
        if (current.typed.equals(current.current, ignoreCase = true)) return
        val query: String = current.check.pendingQuery ?: return
        emailCheck = viewModelScope.launch {
            delay(CHECK_DELAY_MS)
            val outcome: FieldAvailability.Outcome = container.auth.emailAvailability(query)
            _state.update { it.copy(check = it.check.apply(outcome, query)) }
        }
    }

    fun save(onFailure: (Throwable) -> Unit) {
        val current: ChangeEmailUiState = _state.value
        if (!current.canSave) return
        val address: String = current.typed
        emailCheck?.cancel()
        _state.update { it.copy(isSaving = true) }
        viewModelScope.launch {
            try {
                container.account.changeEmail(address)
                _state.update { it.copy(isSaving = false, savedAddress = address) }
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                val refusal: FieldAvailability.Outcome? = EmailChangeFailure.of(error)
                _state.update { state ->
                    state.copy(isSaving = false, check = refusal?.let { state.check.apply(it, address) } ?: state.check)
                }
                if (refusal == null) onFailure(error)
            }
        }
    }

    private companion object {
        const val CHECK_DELAY_MS: Long = 600
    }
}
