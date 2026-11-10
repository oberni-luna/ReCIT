package studio.lunabee.nouveaurecit.data.user

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import kotlin.time.Duration.Companion.milliseconds

/** `RequestPacerTests`, on virtual time: the server refuses a second `PUT /api/user` within a second. */
@OptIn(ExperimentalCoroutinesApi::class)
class RequestPacerTest {
    private fun TestScope.pacer(): RequestPacer = RequestPacer(interval = 1_100.milliseconds, timeSource = testScheduler.timeSource)

    @Test
    fun theFirstCallLeavesAtOnce() = runTest {
        val pacer: RequestPacer = pacer()

        pacer.run { assertEquals(0L, currentTime) }
    }

    @Test
    fun twoCallsInARowLeaveAtLeastElevenHundredMillisecondsApart() = runTest {
        val pacer: RequestPacer = pacer()
        val starts: MutableList<Long> = mutableListOf()

        pacer.run { starts += currentTime }
        pacer.run { starts += currentTime }

        assertEquals(listOf(0L, 1_100L), starts)
    }

    @Test
    fun concurrentCallsQueueAndKeepTheirOrder() = runTest {
        val pacer: RequestPacer = pacer()
        val starts: MutableList<Pair<Int, Long>> = mutableListOf()

        (1..3).map { index -> async { pacer.run { starts += index to currentTime } } }.awaitAll()

        assertEquals(listOf(1 to 0L, 2 to 1_100L, 3 to 2_200L), starts)
    }

    @Test
    fun aSlotIsCountedFromTheStartOfTheCallBefore() = runTest {
        val pacer: RequestPacer = pacer()
        val starts: MutableList<Long> = mutableListOf()

        pacer.run {
            starts += currentTime
            delay(400)
        }
        pacer.run { starts += currentTime }
        delay(5_000)
        pacer.run { starts += currentTime }

        assertEquals(listOf(0L, 1_100L, 6_100L), starts)
    }
}
