package studio.lunabee.nouveaurecit.ui.auth

import androidx.annotation.StringRes
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.auth.AuthRepository
import studio.lunabee.nouveaurecit.auth.model.AuthException
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.TintedTextButton
import studio.lunabee.nouveaurecit.ui.common.recitViewModel

class SignInViewModel(private val auth: AuthRepository) : ViewModel() {
    data class State(val isLoading: Boolean = false, @StringRes val error: Int? = null)

    private val _state: MutableStateFlow<State> = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    fun signIn(username: String, password: String) {
        if (_state.value.isLoading) return
        _state.value = State(isLoading = true)
        viewModelScope.launch {
            _state.value = try {
                auth.login(username.trim(), password)
                State()
            } catch (exception: AuthException) {
                State(error = exception.failure.message)
            }
        }
    }
}

/** `LoginView`. A successful sign-in flips `isAuthenticated`, and the root swaps to the tabs. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignInScreen(onBack: () -> Unit) {
    val viewModel: SignInViewModel = recitViewModel { SignInViewModel(it.auth) }
    val state: SignInViewModel.State by viewModel.state.collectAsState()
    var username: String by rememberSaveable { mutableStateOf("") }
    var password: String by rememberSaveable { mutableStateOf("") }
    var showsReset: Boolean by rememberSaveable { mutableStateOf(false) }

    AuthScaffold(
        title = stringResource(R.string.login_button_signin),
        onBack = onBack,
        bottomBar = {
            PrimaryButton(
                text = stringResource(R.string.login_button_signin),
                onClick = { viewModel.signIn(username, password) },
                enabled = username.isNotBlank(),
                isLoading = state.isLoading,
            )
        },
    ) {
        Text(stringResource(R.string.login_subtitle), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
        AuthField(label = stringResource(R.string.login_username), value = username, onValueChange = { username = it })
        AuthField(label = stringResource(R.string.login_password), value = password, onValueChange = { password = it }, isSecure = true)
        state.error?.let {
            Text(stringResource(it), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundError)
        }
        TintedTextButton(text = stringResource(R.string.login_button_forgot_password), onClick = { showsReset = true })
    }

    if (showsReset) {
        ForgotPasswordSheet(onDismiss = { showsReset = false })
    }
}
