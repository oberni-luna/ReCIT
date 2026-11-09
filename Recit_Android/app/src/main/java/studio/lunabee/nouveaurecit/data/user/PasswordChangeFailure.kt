package studio.lunabee.nouveaurecit.data.user

import androidx.annotation.StringRes
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.network.NetworkError

/**
 * `PasswordChangeFailure` (iOS feature 0055): why `PUT /api/auth/password` refused. The one refusal worth
 * its own sentence is a current password that does not match: the server answers `400 invalid
 * old-password`, and the field to fix is the first one, not the second. A new password the server finds
 * invalid (`invalid new-password`, outside 8…256 characters) cannot leave the screen, which counts it first.
 */
class PasswordChangeFailure(val reason: Reason, cause: Throwable) : Exception(cause) {
    enum class Reason(@StringRes val sentence: Int) {
        WrongCurrentPassword(R.string.change_password_failure_current),
        Other(R.string.change_password_failure_other),
    }

    companion object {
        fun of(error: Throwable): PasswordChangeFailure {
            val isWrongCurrent: Boolean = error is NetworkError.BadStatus && error.code == 400 && "old-password" in error.body
            return PasswordChangeFailure(if (isWrongCurrent) Reason.WrongCurrentPassword else Reason.Other, error)
        }
    }
}
