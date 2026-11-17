package studio.lunabee.nouveaurecit.ui.navigation

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** The links the shell opens: each once, only once my user id is known, the newest of those received meanwhile. */
@OptIn(ExperimentalCoroutinesApi::class)
class IncomingLinksTest {
    private val book: String = "https://link.exlibris.lunabee.ovh/entity/isbn:9782070360024"
    private val list: String = "https://link.exlibris.lunabee.ovh/list/l1"

    @Test
    fun a_link_waits_until_my_user_id_is_known() = runTest {
        val links: IncomingLinks = IncomingLinks()
        val myUserId: MutableStateFlow<String?> = MutableStateFlow(null)
        val opened: MutableList<String> = mutableListOf()
        backgroundScope.launch { links.toOpen(myUserId).collect { opened += it } }

        links.receive(book)
        runCurrent()
        assertEquals(emptyList<String>(), opened)
        assertEquals(book, links.waiting.value)

        myUserId.value = "me"
        runCurrent()
        assertEquals(listOf(book), opened)
    }

    @Test
    fun a_newer_link_replaces_one_still_waiting() = runTest {
        val links: IncomingLinks = IncomingLinks()
        val myUserId: MutableStateFlow<String?> = MutableStateFlow(null)
        val opened: MutableList<String> = mutableListOf()
        backgroundScope.launch { links.toOpen(myUserId).collect { opened += it } }

        links.receive(book)
        runCurrent()
        links.receive(list)
        runCurrent()
        myUserId.value = "me"
        runCurrent()

        assertEquals(listOf(list), opened)
    }

    @Test
    fun a_link_taken_is_cleared_and_opened_once() = runTest {
        val links: IncomingLinks = IncomingLinks()
        val myUserId: MutableStateFlow<String?> = MutableStateFlow("me")
        val opened: MutableList<String> = mutableListOf()
        backgroundScope.launch { links.toOpen(myUserId).collect { opened += it } }

        links.receive(book)
        runCurrent()
        assertNull(links.waiting.value)

        val openedByAnotherShell: MutableList<String> = mutableListOf()
        backgroundScope.launch { links.toOpen(myUserId).collect { openedByAnotherShell += it } }
        runCurrent()

        assertEquals(listOf(book), opened)
        assertEquals(emptyList<String>(), openedByAnotherShell)
    }
}
