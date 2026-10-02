package studio.lunabee.nouveaurecit.data.model

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import studio.lunabee.nouveaurecit.R

/** `Model/UserData/TransactionType.swift` — what an owner offers a copy for. */
enum class TransactionType(val raw: String, @StringRes val label: Int, @DrawableRes val icon: Int) {
    Lending("lending", R.string.transaction_type_lending, R.drawable.ic_lending),
    Inventorying("inventorying", R.string.transaction_type_inventorying, R.drawable.ic_inventorying),
    Selling("selling", R.string.transaction_type_selling, R.drawable.ic_selling),
    Giving("giving", R.string.transaction_type_giving, R.drawable.ic_giving),
    ;

    companion object {
        fun from(raw: String?): TransactionType? = entries.firstOrNull { it.raw == raw }
    }
}

/** `Model/UserData/VisibilityAttributes.swift`. */
enum class Visibility(val raw: String) {
    Public("public"),
    Friends("friends"),
    Groups("groups"),
    ;

    companion object {
        fun from(raw: String): Visibility? = entries.firstOrNull { it.raw == raw }
    }
}

/** `Model/UserData/UserRelation.swift`. */
enum class UserRelation {
    None,
    Friend,
    RequestSent,
    RequestReceived,
}

/** `Model/UserData/EntityList.swift` — `EntityListType`. */
enum class EntityListType(val raw: String, @StringRes val label: Int) {
    Work("work", R.string.list_type_work),
    Author("author", R.string.list_type_author),
    Publisher("publisher", R.string.list_type_publisher),
    ;

    companion object {
        fun from(raw: String?): EntityListType = entries.firstOrNull { it.raw == raw } ?: Work
    }
}
