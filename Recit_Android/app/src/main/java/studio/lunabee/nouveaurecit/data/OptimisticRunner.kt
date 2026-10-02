package studio.lunabee.nouveaurecit.data

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import java.util.UUID

/**
 * `OptimisticMutating.optimistic(_:apply:revert:request:reconcile:)` (ADR 0001, invariant 3).
 *
 * [apply] writes the store at once — the screen redraws from its `Flow` — then [request] runs in the
 * application scope, so it survives the screen. On success [reconcile] aligns the store with the
 * server; on failure [revert] puts it back and the error goes to the [ErrorReporter].
 *
 * [stillThere] is the `subjects` check: when the rows the closures write to have left the store
 * meanwhile (a sync, a deletion), neither reconcile nor revert runs — there is nothing to put back.
 */
class OptimisticRunner(
    private val scope: CoroutineScope,
    private val errorReporter: ErrorReporter,
) {
    suspend fun run(
        apply: suspend () -> Unit,
        revert: suspend () -> Unit,
        request: suspend () -> Unit,
        reconcile: suspend () -> Unit = {},
        stillThere: suspend () -> Boolean = { true },
    ): Job {
        apply()
        return scope.launch {
            try {
                request()
                if (stillThere()) reconcile()
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                if (stillThere()) revert()
                errorReporter.report(error)
            }
        }
    }

    companion object {
        const val PREFIX: String = "optimistic:"

        fun makeId(): String = "$PREFIX${UUID.randomUUID()}"

        fun isOptimistic(id: String): Boolean = id.startsWith(PREFIX)
    }
}
