package studio.lunabee.nouveaurecit.data

import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.TransactionRequestDto
import studio.lunabee.nouveaurecit.network.dto.TransactionRequestResponseDto

/**
 * The request half of `TransactionModel`: asking a friend for one of their copies. The rest of the
 * transactions — the list, the thread, the state changes — is not ported, so nothing is stored: the
 * transaction lives on inventaire.io only, and the owner answers from the web or the iOS app.
 */
class TransactionRepository(private val api: ApiService) {
    /**
     * `POST /api/transactions/request` with `{ item, message }`, server-first like every create
     * (ADR 0001). Answers the new transaction's id. The canonical path, not the legacy
     * `POST /api/transactions` + `action=request` that iOS still sends.
     */
    suspend fun request(itemId: String, message: String): String {
        val payload = TransactionRequestDto(item = itemId, message = message.trim())
        val response: TransactionRequestResponseDto = api.send(REQUEST_PATH, body = payload)
        return response.transaction.id
    }

    companion object {
        const val REQUEST_PATH: String = "/api/transactions/request"
    }
}
