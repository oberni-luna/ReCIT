package studio.lunabee.nouveaurecit.data

import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * `AppErrorReporter`: where a failed background write ends up. The shell collects [failures] once and
 * shows each as a snackbar, so a write that fails after its screen is gone is still said out loud.
 */
class ErrorReporter {
    private val _failures: MutableSharedFlow<Throwable> = MutableSharedFlow(
        extraBufferCapacity = 8,
        onBufferOverflow = BufferOverflow.DROP_OLDEST,
    )
    val failures: SharedFlow<Throwable> = _failures.asSharedFlow()

    fun report(error: Throwable) {
        _failures.tryEmit(error)
    }
}
