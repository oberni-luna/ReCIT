package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.runtime.compositionLocalOf

/**
 * Set on the root screen of a stack shown in a dialog — the Ex-libris link dialog (issue 143): its top bar
 * wears « Fermer », which closes the dialog, instead of the chevron, which would have nothing to pop.
 */
val LocalStackClose = compositionLocalOf<(() -> Unit)?> { null }
