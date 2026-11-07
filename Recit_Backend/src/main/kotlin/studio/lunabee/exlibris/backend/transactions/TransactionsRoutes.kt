package studio.lunabee.exlibris.backend.transactions

import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.ParameterPlace
import studio.lunabee.exlibris.backend.plugins.action
import studio.lunabee.exlibris.backend.plugins.receiveJsonBody
import studio.lunabee.exlibris.backend.plugins.requireSessionUser

private const val TRANSACTIONS: String = "/api/transactions"

/**
 * inventaire.io's `controllers/transactions/transactions.ts`, for the five calls the apps make, each at its path and in
 * the deprecated `?action=` form, with its legacy names (`get-messages`, `message`). iOS still posts its requests to
 * `/api/transactions` with the action in the body, which inventaire.io reads there too. `by-item` and `mark-as-read`,
 * which neither app calls, are not served.
 */
fun Route.transactionsRoutes(
    transactions: TransactionsService,
    messages: TransactionMessagesService,
) {
    get(TRANSACTIONS) {
        call.respond(transactions.mine(call.requireSessionUser()))
    }
    listOf("messages", "get-messages").forEach { name ->
        action(TRANSACTIONS, name, listOf(HttpMethod.Get)) {
            val userId: String = call.requireSessionUser()
            val query = call.request.queryParameters
            val transactionId: String = TransactionRules.id(query["id"] ?: query["transaction"], ParameterPlace.QUERY)
            call.respond(messages.messages(userId, transactionId))
        }
    }
    action(TRANSACTIONS, "request", listOf(HttpMethod.Post)) {
        call.respond(transactions.request(call.requireSessionUser(), call.receiveJsonBody()))
    }
    listOf("messages", "message").forEach { name ->
        action(TRANSACTIONS, name, listOf(HttpMethod.Post)) {
            call.respond(messages.post(call.requireSessionUser(), call.receiveJsonBody()))
        }
    }
    post(TRANSACTIONS) {
        val userId: String = call.requireSessionUser()
        val body: JsonBody = call.receiveJsonBody()
        when (body.optionalString("action")) {
            "request" -> call.respond(transactions.request(userId, body))
            "messages", "message" -> call.respond(messages.post(userId, body))
            else -> throw ApiException(HttpStatusCode.BadRequest, "unknown action")
        }
    }
    action(TRANSACTIONS, "update-state", listOf(HttpMethod.Put)) {
        call.respond(transactions.updateState(call.requireSessionUser(), call.receiveJsonBody()))
    }
}
