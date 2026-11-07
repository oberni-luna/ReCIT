package studio.lunabee.exlibris.backend.lists

import kotlin.test.Test
import kotlin.test.assertEquals

class LexicographicOrdinalsTest {
    @Test
    fun `a list's elements are numbered as inventaire numbers them, from 11`() {
        val ordinals: List<String> =
            generateSequence(
                LexicographicOrdinals.next(LexicographicOrdinals.EMPTY_LIST),
            ) { LexicographicOrdinals.next(it) }
                .take(5)
                .toList()

        assertEquals(listOf("11", "111", "1111", "1112", "1113"), ordinals)
    }

    @Test
    fun `a full figure carries, a full length grows, a long ordinal starts the next range`() {
        assertEquals("1120", LexicographicOrdinals.next("111z"))
        assertEquals("zzzz1", LexicographicOrdinals.next("zzzz"))
        assertEquals("2", LexicographicOrdinals.next("1111111"))
        assertEquals("zzzzzzzz1", LexicographicOrdinals.next("zzzzzzzz"))
    }

    @Test
    fun `ordinals grow in byte order`() {
        val ordinals: List<String> =
            generateSequence("11") { LexicographicOrdinals.next(it) }.take(2_000).toList()

        assertEquals(ordinals.sorted(), ordinals)
    }
}
