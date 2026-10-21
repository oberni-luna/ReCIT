package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.network.NetworkError

/**
 * `CreateBookFailure` (feature 0020): why a book would not publish, in the terms the user needs. Every
 * case says first that **nothing was created on inventaire.io** — which is what makes retrying safe.
 */
enum class CreateBookFailure {
    /** The session is gone. Contributing to the open database is not anonymous. */
    NeedsAccount,

    /** inventaire.io refused the entry. Not something a retry fixes by itself. */
    Refused,

    /** No usable answer — no network, a timeout, an undecodable body. What a retry is for. */
    Network,
    ;

    /** A refused entry is not accepted by asking twice, and an account is not obtained from this form. */
    val isWorthRetrying: Boolean get() = this == Network

    companion object {
        fun from(error: Throwable): CreateBookFailure = when {
            error !is NetworkError.BadStatus -> Network
            error.code == 401 || error.code == 403 -> NeedsAccount
            error.code in 400..499 -> Refused
            else -> Network
        }
    }
}
