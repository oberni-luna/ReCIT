package studio.lunabee.nouveaurecit.ui.navigation

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow

/**
 * The Ex-libris links the system hands the app ([DeepLink]), until the shell opens them — `TabRouter.waitingLink`
 * on iOS (issue 143). In memory only: a link that dies with the app is opened again from where it was.
 *
 * A link waits until my user id is known: signed out, until signed in or up; on a launch, until the last session's
 * is put back or the first sync reads it — without it my own name and étagères would be a stranger's. A newer link
 * replaces one still waiting.
 */
class IncomingLinks {
    private val latest: MutableStateFlow<String?> = MutableStateFlow(null)

    /** The link not opened yet, if any: the welcome screen says one waits. */
    val waiting: StateFlow<String?> = latest.asStateFlow()

    /** A link the system hands the app, replacing one still waiting. */
    fun receive(url: String) {
        latest.value = url
    }

    /** Each link, once [myUserId] is known, cleared as it is emitted so it is opened once. */
    fun toOpen(myUserId: Flow<String?>): Flow<String> = flow {
        latest.filterNotNull().collect { url: String ->
            myUserId.filterNotNull().first()
            if (latest.compareAndSet(url, null)) emit(url)
        }
    }
}
