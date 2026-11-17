package studio.lunabee.nouveaurecit.ui.navigation

import kotlinx.serialization.Serializable

/**
 * Where an Ex-libris link ([DeepLink]) lands: a screen alone above a tab's root, or the Profil sheet for my own name.
 * `@Serializable` so the link dialog showing one survives a configuration change.
 */
@Serializable
sealed interface LinkTarget {
    @Serializable data class Screen(val tab: AppTab, val destination: Destination) : LinkTarget

    @Serializable data object Profile : LinkTarget
}
