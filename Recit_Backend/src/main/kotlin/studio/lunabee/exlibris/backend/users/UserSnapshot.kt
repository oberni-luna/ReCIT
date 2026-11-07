package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import studio.lunabee.exlibris.backend.db.Visibility

/**
 * inventaire.io's `snapshot`, a reader's books counted by visibility (`getVisibilitySummaryKey`): `private` those
 * seen by the owner alone, `public` those anyone sees, `network` the others. The owner reads every section, their
 * network `network` and `public`, anyone else `public` alone (`omitPrivateData`).
 */
@Serializable
data class UserSnapshot(
    @SerialName("private")
    val ownerOnly: ItemCount? = null,
    val network: ItemCount? = null,
    val public: ItemCount = ItemCount(),
) {
    /** What someone else than the owner reads of it. */
    fun forViewer(isInNetwork: Boolean): UserSnapshot =
        UserSnapshot(network = network.takeIf { isInNetwork }, public = public)

    companion object {
        /** A reader without a book: every section at zero. */
        val EMPTY: UserSnapshot = UserSnapshot(ownerOnly = ItemCount(), network = ItemCount(), public = ItemCount())

        /** The sections, from the books' counts by visibility as sent. */
        fun of(countsByVisibility: Map<List<String>, ItemCount>): UserSnapshot {
            val bySection: Map<String, ItemCount> =
                countsByVisibility.entries
                    .groupBy({ (visibility, _) -> section(visibility) }, { it.value })
                    .mapValues { (_, counts) -> counts.reduce(ItemCount::plus) }
            return UserSnapshot(
                ownerOnly = bySection[PRIVATE] ?: ItemCount(),
                network = bySection[NETWORK] ?: ItemCount(),
                public = bySection[Visibility.PUBLIC] ?: ItemCount(),
            )
        }

        private const val PRIVATE: String = "private"
        private const val NETWORK: String = "network"

        private fun section(visibility: List<String>): String =
            when {
                visibility.isEmpty() -> PRIVATE
                Visibility.PUBLIC in visibility -> Visibility.PUBLIC
                else -> NETWORK
            }
    }
}
