package studio.lunabee.exlibris.backend.plugins

import io.ktor.http.HttpStatusCode

/**
 * Thrown by a service to answer [status] with [verbose] as `message` and `status_verbose`, plus inventaire.io's
 * `error_type` / `error_name` when it sends them; see [installStatusPages].
 */
class ApiException(
    val status: HttpStatusCode,
    val verbose: String,
    val errorType: String? = null,
    val errorName: String? = null,
    cause: Throwable? = null,
) : RuntimeException(verbose, cause) {
    companion object {
        /** What inventaire.io answers a call that needs a session and has none (`newUnauthorizedApiAccessError`). */
        fun unauthorized(): ApiException = ApiException(HttpStatusCode.Unauthorized, "unauthorized api access")

        /** A limit reached: the `429` the apps already tell apart (feature 0083). */
        fun tooManyRequests(): ApiException = ApiException(HttpStatusCode.TooManyRequests, "too many requests")

        /** A bibliographic write, refused until the backend signs them (#76 decision 6, #77). */
        fun notImplemented(): ApiException = ApiException(HttpStatusCode.NotImplemented, "not implemented")

        /**
         * inventaire.io refused the connection, kept silent past the relay's timeout (#76 decision 4), or answered
         * something the backend cannot read.
         */
        fun badGateway(cause: Throwable? = null): ApiException =
            ApiException(HttpStatusCode.BadGateway, "bad gateway", cause = cause)

        /** A CouchDB `get` of a document that is not there, as inventaire.io lets it through. */
        fun missingDocument(): ApiException = ApiException(HttpStatusCode.NotFound, "not_found: missing")

        /** inventaire.io's `newMissingError`: `missing parameter in body: email`, `missing_email`. */
        fun missingParameter(
            place: ParameterPlace,
            name: String,
        ): ApiException =
            ApiException(
                status = HttpStatusCode.BadRequest,
                verbose = "missing parameter in ${place.label}: $name",
                errorType = "missing_parameter",
                errorName = "missing_$name",
            )

        /**
         * inventaire.io's `newInvalidError`: `invalid email: not-an-email`, `invalid_email`. [value] is left out
         * for a secret, which inventaire.io would echo.
         */
        fun invalidParameter(
            name: String,
            value: String? = null,
        ): ApiException =
            ApiException(
                status = HttpStatusCode.BadRequest,
                verbose = if (value == null) "invalid $name" else "invalid $name: $value",
                errorType = "invalid_parameter",
                errorName = "invalid_$name",
            )
    }
}
