package studio.lunabee.nouveaurecit.ui.flow

import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf

/** `SortFlowStart` (ADR 0007): where the scan-and-sort flow opens. */
enum class SortFlowStart { Scanning }

/**
 * `SortFlowPresentation` (ADR 0007): one flag for the whole app, raised by every entry point, and
 * read by the one place that draws the flow — `MainScaffold`, above its tabs and its navigation bar.
 * Idempotent, like iOS: a second door does not stack a second flow.
 */
@Stable
class SortFlowPresentation(initial: SortFlowStart? = null) {
    var start: SortFlowStart? by mutableStateOf(initial)
        private set

    fun presentScanning() {
        if (start == null) start = SortFlowStart.Scanning
    }

    fun dismiss() {
        start = null
    }
}

val LocalSortFlow = staticCompositionLocalOf<SortFlowPresentation> { error("No SortFlowPresentation provided") }
