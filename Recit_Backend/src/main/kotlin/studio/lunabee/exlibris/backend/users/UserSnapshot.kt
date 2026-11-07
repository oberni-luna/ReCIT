package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * inventaire.io's `snapshot`, its books counted by visibility. The owner reads every section, their network
 * `network` and `public`, anyone else `public` alone (`omitPrivateData`). Every count is zero until the books
 * arrive (#73).
 */
@Serializable
data class UserSnapshot(
    @SerialName("private")
    val ownerOnly: ItemCount? = null,
    val network: ItemCount? = null,
    val public: ItemCount = ItemCount(),
) {
    companion object {
        fun forOwner(): UserSnapshot = UserSnapshot(ownerOnly = ItemCount(), network = ItemCount())

        fun forViewer(isInNetwork: Boolean): UserSnapshot =
            if (isInNetwork) UserSnapshot(network = ItemCount()) else UserSnapshot()
    }
}
