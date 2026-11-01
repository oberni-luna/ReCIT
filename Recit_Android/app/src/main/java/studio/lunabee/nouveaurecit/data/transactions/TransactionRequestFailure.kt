package studio.lunabee.nouveaurecit.data.transactions

import androidx.annotation.StringRes
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.network.NetworkError

/**
 * Why inventaire.io refused a request, read from `rights_verification.ts` and `models/transaction.ts`:
 * a `403` when I already asked for this copy or someone else's request holds it, a `400` when its
 * owner made it inventoried in the meantime. Anything else is said as a generic failure.
 */
enum class TransactionRequestFailure(@StringRes val message: Int?) {
    AlreadyRequested(R.string.transaction_request_error_already_requested),
    ItemBusy(R.string.transaction_request_error_busy),
    NotRequestable(R.string.transaction_request_error_not_requestable),
    Other(null),
    ;

    companion object {
        fun from(error: Throwable): TransactionRequestFailure {
            val status: NetworkError.BadStatus = error as? NetworkError.BadStatus ?: return Other
            return when {
                status.code == 403 && "already made a request" in status.body -> AlreadyRequested
                status.code == 403 && "already busy" in status.body -> ItemBusy
                status.code == 400 && "can't be requested" in status.body -> NotRequestable
                else -> Other
            }
        }
    }
}
