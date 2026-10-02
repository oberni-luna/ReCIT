package studio.lunabee.nouveaurecit.auth.model

import androidx.annotation.StringRes
import studio.lunabee.nouveaurecit.R

/**
 * `Model/Authentication/AuthFailure.swift`: every way signing in or up can fail, each owning the
 * sentence the user reads. The server's English prose is carried for the log and never rendered.
 */
sealed interface AuthFailure {
    data object InvalidCredentials : AuthFailure
    data object Network : AuthFailure
    data object NoSessionCookies : AuthFailure
    data object Storage : AuthFailure
    data object UsernameTaken : AuthFailure
    data object UsernameInvalid : AuthFailure
    data object EmailTaken : AuthFailure
    data object EmailInvalid : AuthFailure
    data object PasswordRejected : AuthFailure
    data class Server(val status: Int, val serverMessage: String?) : AuthFailure

    enum class SignupField { Username, Email, Password }

    val signupField: SignupField?
        get() = when (this) {
            UsernameTaken, UsernameInvalid -> SignupField.Username
            EmailTaken, EmailInvalid -> SignupField.Email
            PasswordRejected -> SignupField.Password
            else -> null
        }

    @get:StringRes
    val message: Int
        get() = when (this) {
            InvalidCredentials -> R.string.auth_error_invalid_credentials
            Network -> R.string.auth_error_network
            UsernameTaken -> R.string.signup_error_username_taken
            UsernameInvalid -> R.string.signup_error_username_invalid
            EmailTaken -> R.string.signup_error_email_taken
            EmailInvalid -> R.string.signup_error_email_invalid
            PasswordRejected -> R.string.signup_error_password_rejected
            NoSessionCookies, Storage, is Server -> R.string.auth_error_generic
        }

    companion object {
        fun classify(status: Int, serverMessage: String?): AuthFailure? {
            if (status in 200..299) return null
            if (status == 401 || status == 403) return InvalidCredentials
            return Server(status, serverMessage)
        }

        fun classifySignup(status: Int, errorName: String?, serverMessage: String?): AuthFailure? {
            if (status in 200..299) return null
            if (status != 400) return classify(status, serverMessage)
            when (errorName) {
                "invalid_username" -> return UsernameInvalid
                "invalid_email" -> return EmailInvalid
                "invalid_password" -> return PasswordRejected
            }
            if (serverMessage != null) {
                if ("username is already used" in serverMessage) return UsernameTaken
                if ("email is already used" in serverMessage) return EmailTaken
                if ("reserved word" in serverMessage) return UsernameInvalid
            }
            return Server(status, serverMessage)
        }
    }
}

class AuthException(val failure: AuthFailure) : Exception(failure.toString())
