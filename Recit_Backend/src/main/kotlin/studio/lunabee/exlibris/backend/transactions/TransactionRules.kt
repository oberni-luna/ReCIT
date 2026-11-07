package studio.lunabee.exlibris.backend.transactions

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.ParameterPlace

/** The transaction routes' parameters, read with inventaire.io's sanitizer's errors, and the refusals they share. */
object TransactionRules {
    /** inventaire.io's comment validation: under 5000 characters. */
    private const val MESSAGE_LENGTH_LIMIT: Int = 5000

    /** A transaction's `id`, sent as [value] — or as the deprecated `transaction` inventaire.io renames to `id`. */
    fun id(
        value: String?,
        place: ParameterPlace,
    ): String {
        val id: String = value ?: throw ApiException.missingParameter(place, "id")
        if (!DocumentId.isValid(id)) throw ApiException.invalidParameter("id", id)
        return id
    }

    /** The book asked for: `item`, a document id. */
    fun itemId(body: JsonBody): String {
        val id: String = body.string("item")
        if (!DocumentId.isValid(id)) throw ApiException.invalidParameter("item", id)
        return id
    }

    fun id(body: JsonBody): String =
        id(body.optionalString("id") ?: body.optionalString("transaction"), ParameterPlace.BODY)

    /** `message`, trimmed: never empty, under [MESSAGE_LENGTH_LIMIT] characters. */
    fun message(body: JsonBody): String {
        val message: String = body.string("message").trim()
        if (message.isEmpty()) throw ApiException(HttpStatusCode.BadRequest, "invalid message: message cannot be empty")
        if (message.length >= MESSAGE_LENGTH_LIMIT) throw ApiException.invalidParameter("message", message)
        return message
    }

    /** `state`, one of [TransactionState]'s, or inventaire.io's allowlist error naming them. */
    fun state(body: JsonBody): TransactionState {
        val name: String = body.string("state")
        return TransactionState.of(name)
            ?: throw ApiException(
                HttpStatusCode.BadRequest,
                "invalid state: $name (possible values: ${TransactionState.entries.joinToString { it.storedName }})",
            )
    }

    /** inventaire.io's `verifyRightToInteractWithTransaction`, `verifyIsOwner` and `verifyIsRequester`. */
    fun wrongUser(): ApiException = ApiException(HttpStatusCode.Forbidden, "wrong user")

    /** An accepted Échange, or a loan confirmed, holds the book: nobody may ask for it or accept another. */
    fun itemBusy(): ApiException = ApiException(HttpStatusCode.Forbidden, "item already busy")
}
