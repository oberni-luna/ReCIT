package studio.lunabee.nouveaurecit.auth

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.auth.model.PasswordResetOutcome

/**
 * `AuthModel`: holds `isAuthenticated`, read once at launch from the service and moved only by a
 * login, a sign-up or a sign-out. Nothing else in the app decides who is signed in.
 */
class AuthRepository(private val service: AuthService) {
    private val _isAuthenticated: MutableStateFlow<Boolean> = MutableStateFlow(service.isLoggedIn())
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    /** Throws `AuthException`. */
    suspend fun login(username: String, password: String) {
        service.login(username, password)
        _isAuthenticated.value = true
    }

    /** Throws `AuthException`. */
    suspend fun signUp(username: String, email: String, password: String) {
        service.signUp(username, email, password)
        _isAuthenticated.value = true
    }

    suspend fun usernameAvailability(username: String): FieldAvailability.Outcome = service.usernameAvailability(username)

    suspend fun emailAvailability(email: String): FieldAvailability.Outcome = service.emailAvailability(email)

    suspend fun requestPasswordReset(email: String): PasswordResetOutcome = service.requestPasswordReset(email)

    suspend fun logout() {
        service.logout()
        _isAuthenticated.value = false
    }

    /** After the account is deleted: the server has already closed the session. */
    fun forgetSession() {
        service.forgetSession()
        _isAuthenticated.value = false
    }
}
