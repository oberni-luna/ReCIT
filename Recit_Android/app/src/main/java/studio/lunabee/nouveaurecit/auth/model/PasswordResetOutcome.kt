package studio.lunabee.nouveaurecit.auth.model

/**
 * `Model/Authentication/PasswordResetOutcome.swift`. Every server answer collapses onto one
 * confirmation: passing it along would answer "does this account exist?" for any address.
 */
enum class PasswordResetOutcome {
    Submitted,
    Unreachable,
    ;

    val failure: AuthFailure? get() = if (this == Unreachable) AuthFailure.Network else null

    companion object {
        @Suppress("UNUSED_PARAMETER")
        fun fromServer(status: Int, serverMessage: String?): PasswordResetOutcome = Submitted

        val transportFailure: PasswordResetOutcome get() = Unreachable
    }
}
