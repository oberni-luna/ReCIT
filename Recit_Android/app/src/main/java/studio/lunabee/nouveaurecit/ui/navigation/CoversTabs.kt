package studio.lunabee.nouveaurecit.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect

/**
 * Says to the [TabRouter], for as long as it is composed, that the overlay it sits in or beside — « Ranger mes
 * livres », a bottom sheet, a full-screen dialog — covers the tabs: an Ex-libris link opened meanwhile goes in a dialog over it (issue 143).
 */
@Composable
fun CoversTabs() {
    val router: TabRouter = LocalTabRouter.current
    DisposableEffect(router) {
        router.overlayShown()
        onDispose { router.overlayHidden() }
    }
}
