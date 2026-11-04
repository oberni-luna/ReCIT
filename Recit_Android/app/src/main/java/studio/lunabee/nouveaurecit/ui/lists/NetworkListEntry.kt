package studio.lunabee.nouveaurecit.ui.lists

import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.db.UserEntity

/** One row of « Dans mon réseau » in the Lists tab: a friend's list, and the friend whose picture and name head it. */
data class NetworkListEntry(val list: ListWithElements, val owner: UserEntity)
