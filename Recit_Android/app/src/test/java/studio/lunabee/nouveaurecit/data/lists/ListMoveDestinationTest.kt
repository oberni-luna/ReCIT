package studio.lunabee.nouveaurecit.data.lists

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.data.lists.ListMoveDestination.Candidate
import studio.lunabee.nouveaurecit.data.model.EntityListType

/** `ListMoveDestinationTests`. */
class ListMoveDestinationTest {
    private val candidates: List<Candidate> = listOf(
        Candidate("here", "Ici", EntityListType.Work, setOf("wd:A")),
        Candidate("z", "Zola et les autres", EntityListType.Work, emptySet()),
        Candidate("e", "Été", EntityListType.Work, setOf("wd:A")),
        Candidate("authors", "Auteurs", EntityListType.Author, emptySet()),
        Candidate("b", "à lire", EntityListType.Work, emptySet()),
    )

    @Test
    fun the_other_lists_of_the_type_sorted_by_name() {
        val destinations: List<ListMoveDestination> = ListMoveDestination.destinations("wd:A", "here", EntityListType.Work, candidates)
        assertEquals(listOf("b", "e", "z"), destinations.map { it.id })
    }

    @Test
    fun a_list_already_holding_the_element_is_greyed() {
        val destinations: List<ListMoveDestination> = ListMoveDestination.destinations("wd:A", "here", EntityListType.Work, candidates)
        assertEquals(listOf(false, true, false), destinations.map { it.alreadyHolds })
    }

    @Test
    fun no_other_list_of_the_type_means_nowhere_to_go() {
        assertEquals(emptyList<ListMoveDestination>(), ListMoveDestination.destinations("wd:B", "authors", EntityListType.Author, candidates))
    }
}
