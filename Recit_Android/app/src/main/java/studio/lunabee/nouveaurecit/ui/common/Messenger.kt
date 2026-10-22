package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.runtime.staticCompositionLocalOf
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * One snackbar: a title in action300, an optional subtitle in action200 — `SnackBarView` — and an
 * optional action (« Voir ») that takes the user to what the sentence is about.
 */
data class SnackMessage(
    val title: String,
    val subtitle: String? = null,
    val isError: Boolean = false,
    val actionLabel: String? = null,
    val onAction: (() -> Unit)? = null,
)

/**
 * LBSnackBar's `snackBar.show { … }`: any screen says a sentence, the shell shows it over the tabs.
 */
class Messenger {
    private val _messages: MutableSharedFlow<SnackMessage> = MutableSharedFlow(
        extraBufferCapacity = 4,
        onBufferOverflow = BufferOverflow.DROP_OLDEST,
    )
    val messages: SharedFlow<SnackMessage> = _messages.asSharedFlow()

    fun show(title: String, subtitle: String? = null) {
        _messages.tryEmit(SnackMessage(title, subtitle))
    }

    fun show(title: String, actionLabel: String, onAction: () -> Unit) {
        _messages.tryEmit(SnackMessage(title, actionLabel = actionLabel, onAction = onAction))
    }

    fun showError(title: String, subtitle: String? = null) {
        _messages.tryEmit(SnackMessage(title, subtitle, isError = true))
    }
}

val LocalMessenger = staticCompositionLocalOf { Messenger() }
