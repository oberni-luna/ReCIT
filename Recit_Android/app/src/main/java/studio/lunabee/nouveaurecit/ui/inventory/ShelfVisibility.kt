package studio.lunabee.nouveaurecit.ui.inventory

import androidx.annotation.StringRes
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.model.Visibility

/** `FormVisibility` of `ShelfFormView`: Privé / Amis / Public, sent as `[]`, `["friends"]`, `["public"]`. */
enum class ShelfVisibility(@StringRes val label: Int, val raw: List<Visibility>) {
    Private(R.string.shelf_form_visibility_private, emptyList()),
    Friends(R.string.shelf_form_visibility_friends, listOf(Visibility.Friends)),
    Public(R.string.shelf_form_visibility_public, listOf(Visibility.Public)),
    ;

    companion object {
        fun from(raw: List<Visibility>): ShelfVisibility = when {
            Visibility.Public in raw -> Public
            Visibility.Friends in raw -> Friends
            else -> Private
        }
    }
}
