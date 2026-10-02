package studio.lunabee.nouveaurecit.auth.model

import studio.lunabee.nouveaurecit.network.NetworkError

/** `Model/Authentication/SessionExpiry.swift`: a `401` and nothing else means the session is gone. */
object SessionExpiry {
    fun isSessionGone(error: Throwable): Boolean = (error as? NetworkError.BadStatus)?.code == 401
}
