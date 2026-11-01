package studio.lunabee.nouveaurecit.data.transactions

import androidx.annotation.StringRes
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.model.TransactionType

/**
 * How the request is worded, by what the owner offers the copy for. One verb per type — emprunter,
 * acheter, récupérer (a gift is « récupéré », not « reçu ») — carried through the menu line, the
 * form's title, the sentence that replaces iOS's « Type » picker, the message's hint and the button.
 *
 * The sentence is iOS's `transaction.desc.requester.*`, the owner's name in bold. There is no
 * wording for [TransactionType.Inventorying]: that copy cannot be asked for.
 */
enum class TransactionRequestWording(
    val type: TransactionType,
    /** « Emprunter à %1$s » — the owner. */
    @StringRes val menu: Int,
    /** « Emprunter %1$s à %2$s » — the title, then the owner. */
    @StringRes val title: Int,
    /** « Vous souhaitez l'emprunter à %1$s » — the owner, drawn in bold. */
    @StringRes val sentence: Int,
    @StringRes val messageHint: Int,
    @StringRes val submit: Int,
) {
    Lending(
        type = TransactionType.Lending,
        menu = R.string.transaction_request_menu_lending,
        title = R.string.transaction_request_title_lending,
        sentence = R.string.transaction_desc_requester_lending,
        messageHint = R.string.transaction_request_hint_lending,
        submit = R.string.transaction_request_submit_lending,
    ),
    Selling(
        type = TransactionType.Selling,
        menu = R.string.transaction_request_menu_selling,
        title = R.string.transaction_request_title_selling,
        sentence = R.string.transaction_desc_requester_selling,
        messageHint = R.string.transaction_request_hint_selling,
        submit = R.string.transaction_request_submit_selling,
    ),
    Giving(
        type = TransactionType.Giving,
        menu = R.string.transaction_request_menu_giving,
        title = R.string.transaction_request_title_giving,
        sentence = R.string.transaction_desc_requester_giving,
        messageHint = R.string.transaction_request_hint_giving,
        submit = R.string.transaction_request_submit_giving,
    ),
    ;

    companion object {
        /** `null` for an inventoried copy: nothing to ask. */
        fun of(type: TransactionType): TransactionRequestWording? = entries.firstOrNull { it.type == type }

        /** The message is required, as on iOS: the owner learns from it who asks and why. */
        fun canSubmit(message: String): Boolean = message.isNotBlank()
    }
}
