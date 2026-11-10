package studio.lunabee.nouveaurecit.ui.profile.account

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.user.AccountSettings

/**
 * `AccountSettingsView`'s state (iOS feature 0055): the account's settings as `AccountRepository` holds
 * them, and the writes. The language and the switches are optimistic: the screen redraws from [settings]
 * at once, and a refusal puts the one value back and speaks through the shared snackbar.
 */
class AccountSettingsViewModel(private val container: AppContainer) : ViewModel() {
    val settings: StateFlow<AccountSettings?> = container.account.settings

    private val _isResending: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val isResending: StateFlow<Boolean> = _isResending.asStateFlow()

    private val _loadFailed: MutableStateFlow<Boolean> = MutableStateFlow(false)

    /** The settings could not be read: the screen offers « Réessayer » rather than waiting for them. */
    val loadFailed: StateFlow<Boolean> = _loadFailed.asStateFlow()

    init {
        if (settings.value == null) load()
    }

    fun load() {
        _loadFailed.value = false
        viewModelScope.launch {
            try {
                container.session.syncAccount()
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (_: Exception) {
                _loadFailed.value = settings.value == null
            }
        }
    }

    fun setLanguage(code: String) {
        viewModelScope.launch { container.account.setLanguage(code) }
    }

    fun setFediversable(isOn: Boolean) {
        viewModelScope.launch { container.account.setFediversable(isOn) }
    }

    fun setAnonymizesContributions(isOn: Boolean) {
        viewModelScope.launch { container.account.setAnonymizesContributions(isOn) }
    }

    /** « Renvoyer l’e-mail »: [onSent] or [onFailure] say how it went. */
    fun resendConfirmation(onSent: () -> Unit, onFailure: (Throwable) -> Unit) {
        if (_isResending.value) return
        _isResending.value = true
        viewModelScope.launch {
            try {
                container.account.resendEmailConfirmation()
                onSent()
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                onFailure(error)
            } finally {
                _isResending.value = false
            }
        }
    }
}
