package studio.lunabee.nouveaurecit.ui.navigation

/** Where an Ex-libris link ([DeepLink]) lands: a screen alone above a tab's root, or the Profil sheet for my own name. */
sealed interface LinkTarget {
    data class Screen(val tab: AppTab, val destination: Destination) : LinkTarget

    data object Profile : LinkTarget
}
