package studio.lunabee.nouveaurecit.network

/** `AppModels/Service/NetworkError.swift`. */
sealed class NetworkError(message: String?, cause: Throwable? = null) : Exception(message, cause) {
    class BadStatus(val code: Int, val body: String) : NetworkError("HTTP $code")
    class BadResponse : NetworkError("Bad response")
    class Transport(cause: Throwable) : NetworkError(cause.message, cause)
    class Decoding(cause: Throwable) : NetworkError(cause.message, cause)
}
