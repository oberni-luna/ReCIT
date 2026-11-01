package studio.lunabee.nouveaurecit.ui.lists

import androidx.annotation.StringRes
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.model.Visibility

/**
 * `ListVisibility` of iOS: the five answers to « Visible par » in the list form, read from
 * inventaire.io's keys and written back as them. Five where [studio.lunabee.nouveaurecit.ui.inventory.ShelfVisibility]
 * has three, because a list can be shown to my groups. `public` wins over the rest. A `group:<id>`
 * key is already dropped when a list is stored, so it is neither offered nor kept.
 */
enum class ListVisibility(@StringRes val label: Int, val raw: List<Visibility>) {
    Private(R.string.list_visibility_private, emptyList()),
    Friends(R.string.list_visibility_friends, listOf(Visibility.Friends)),
    Groups(R.string.list_visibility_groups, listOf(Visibility.Groups)),
    FriendsAndGroups(R.string.list_visibility_friends_and_groups, listOf(Visibility.Friends, Visibility.Groups)),
    Public(R.string.list_visibility_public, listOf(Visibility.Public)),
    ;

    companion object {
        fun from(raw: List<Visibility>): ListVisibility = when {
            Visibility.Public in raw -> Public
            Visibility.Friends in raw && Visibility.Groups in raw -> FriendsAndGroups
            Visibility.Friends in raw -> Friends
            Visibility.Groups in raw -> Groups
            else -> Private
        }
    }
}
