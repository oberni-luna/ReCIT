package studio.lunabee.nouveaurecit.ui.auth

import androidx.annotation.StringRes
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.auth.AuthRepository
import studio.lunabee.nouveaurecit.auth.model.AuthException
import studio.lunabee.nouveaurecit.auth.model.AuthFailure
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.common.recitViewModel

/** The two live checks, debounced 600 ms, and the sign-up itself. */
class CreateAccountViewModel(private val auth: AuthRepository) : ViewModel() {
    data class State(
        val username: FieldAvailability = FieldAvailability(FieldAvailability.Field.Username),
        val email: FieldAvailability = FieldAvailability(FieldAvailability.Field.Email),
        val password: String = "",
        val isLoading: Boolean = false,
        val failure: AuthFailure? = null,
    ) {
        val canSubmit: Boolean get() = username.isAvailable && email.isAvailable && password.isNotEmpty()

        @get:StringRes
        val generalError: Int? get() = failure?.takeIf { it.signupField == null || it.signupField == AuthFailure.SignupField.Password }?.message
    }

    private val _state: MutableStateFlow<State> = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()
    private var usernameCheck: Job? = null
    private var emailCheck: Job? = null

    fun onUsername(text: String) {
        _state.update { it.copy(username = it.username.edited(text), failure = null) }
        usernameCheck?.cancel()
        val query: String = _state.value.username.pendingQuery ?: return
        usernameCheck = viewModelScope.launch {
            delay(DEBOUNCE_MS)
            val outcome: FieldAvailability.Outcome = auth.usernameAvailability(query)
            _state.update { it.copy(username = it.username.apply(outcome, query)) }
        }
    }

    fun onEmail(text: String) {
        _state.update { it.copy(email = it.email.edited(text), failure = null) }
        emailCheck?.cancel()
        val query: String = _state.value.email.pendingQuery ?: return
        emailCheck = viewModelScope.launch {
            delay(DEBOUNCE_MS)
            val outcome: FieldAvailability.Outcome = auth.emailAvailability(query)
            _state.update { it.copy(email = it.email.apply(outcome, query)) }
        }
    }

    fun onPassword(text: String) {
        _state.update { it.copy(password = text, failure = null) }
    }

    fun submit() {
        val current: State = _state.value
        if (!current.canSubmit || current.isLoading) return
        _state.update { it.copy(isLoading = true, failure = null) }
        viewModelScope.launch {
            try {
                auth.signUp(current.username.text.trim(), current.email.text.trim(), current.password)
                _state.update { it.copy(isLoading = false) }
            } catch (exception: AuthException) {
                _state.update { it.copy(isLoading = false, failure = exception.failure) }
            }
        }
    }

    private companion object {
        const val DEBOUNCE_MS: Long = 600
    }
}

/** `CreateAccountView`: signing up is one more way of signing in. */
@Composable
fun CreateAccountScreen(onBack: () -> Unit) {
    val viewModel: CreateAccountViewModel = recitViewModel { CreateAccountViewModel(it.auth) }
    val state: CreateAccountViewModel.State by viewModel.state.collectAsState()
    val fieldError: (AuthFailure.SignupField, FieldAvailability) -> Int? = { field, availability ->
        state.failure?.takeIf { it.signupField == field }?.message ?: availability.failure?.message
    }

    AuthScaffold(
        title = stringResource(R.string.login_button_create_account),
        onBack = onBack,
        bottomBar = {
            PrimaryButton(
                text = stringResource(R.string.signup_button_create),
                onClick = viewModel::submit,
                enabled = state.canSubmit,
                isLoading = state.isLoading,
            )
            Text(
                stringResource(R.string.signup_footnote),
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundSecondary,
                textAlign = TextAlign.Center,
            )
        },
    ) {
        Text(stringResource(R.string.signup_subtitle), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
        AuthField(
            label = stringResource(R.string.login_username),
            value = state.username.text,
            onValueChange = viewModel::onUsername,
            checking = state.username.state == FieldAvailability.State.Checking,
            error = fieldError(AuthFailure.SignupField.Username, state.username)?.let { stringResource(it) },
        )
        AuthField(
            label = stringResource(R.string.signup_email),
            value = state.email.text,
            onValueChange = viewModel::onEmail,
            keyboardType = KeyboardType.Email,
            checking = state.email.state == FieldAvailability.State.Checking,
            error = fieldError(AuthFailure.SignupField.Email, state.email)?.let { stringResource(it) },
        )
        AuthField(
            label = stringResource(R.string.login_password),
            value = state.password,
            onValueChange = viewModel::onPassword,
            isSecure = true,
        )
        state.generalError?.let {
            Text(stringResource(it), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundError)
        }
    }
}
