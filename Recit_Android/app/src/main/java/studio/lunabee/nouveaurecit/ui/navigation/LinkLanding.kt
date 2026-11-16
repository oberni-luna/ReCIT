package studio.lunabee.nouveaurecit.ui.navigation

/**
 * Where [TabRouter.openLink] sends an Ex-libris link's [LinkTarget], when the shell has something to do with it
 * (`LinkSheetContent` on iOS, issue 143).
 */
sealed interface LinkLanding {
    /** Nothing covers the tabs: [destination] alone above the root of [tab], which is now selected. */
    data class OnTab(val tab: AppTab, val destination: Destination) : LinkLanding

    /** An overlay covers the tabs: [target] in the link dialog over it, the overlay left as it was. */
    data class InDialog(val target: LinkTarget) : LinkLanding
}
