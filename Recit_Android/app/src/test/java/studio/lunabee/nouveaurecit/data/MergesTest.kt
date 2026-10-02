package studio.lunabee.nouveaurecit.data

import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.network.dto.EntityImageDto
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import studio.lunabee.nouveaurecit.network.dto.EntitySnapshotDto
import studio.lunabee.nouveaurecit.network.dto.ItemCountDto
import studio.lunabee.nouveaurecit.network.dto.ItemDto
import studio.lunabee.nouveaurecit.network.dto.UserDto
import studio.lunabee.nouveaurecit.network.dto.UserNetworkDto

class MergesTest {
    @Test
    fun a_sparse_edition_payload_keeps_what_the_store_had() {
        val stored = EditionEntity(uri = "inv:1", title = "Dune", subtitle = "roman", lang = "fr", image = "https://img", numberOfPages = 412)
        val sparse = EntityResultDto(uri = "inv:1")
        assertEquals(stored, Merges.edition(stored, sparse))
    }

    @Test
    fun an_edition_title_comes_from_claims_labels_first() {
        val dto = EntityResultDto(
            uri = "inv:1",
            labels = mapOf("mul" to "Mul", "fromclaims" to "From claims"),
            claims = mapOf("wdt:P1476" to listOf(JsonPrimitive("Claim")), "wdt:P1104" to listOf(JsonPrimitive(312))),
            image = EntityImageDto(url = "/img/entities/abc"),
        )
        val edition: EditionEntity = Merges.edition(null, dto)
        assertEquals("From claims", edition.title)
        assertEquals(312, edition.numberOfPages)
        assertEquals("https://inventaire.io/img/entities/abc", edition.image)
        assertEquals("Claim", Merges.editionTitle(emptyMap(), "Claim"))
    }

    @Test
    fun a_work_reads_its_date_off_p577() {
        val dto = EntityResultDto(
            uri = "wd:Q1",
            labels = mapOf("en" to "Dune"),
            claims = mapOf("wdt:P577" to listOf(JsonPrimitive("1965-08-01")), "wdt:P570" to listOf(JsonPrimitive("1986-02-11"))),
        )
        assertEquals("1965-08-01", Merges.work(null, dto).publicationDate)
        assertEquals("Dune", Merges.work(null, dto).title)
    }

    @Test
    fun a_user_counts_its_items_and_prefixes_its_avatar() {
        val dto = UserDto(
            id = "u1",
            username = "olive",
            picture = "/img/users/1",
            snapshot = mapOf("public" to ItemCountDto(3, 10.0), "private" to ItemCountDto(7, 20.0)),
        )
        val user = Merges.user(null, dto, "https://inventaire.io")
        assertEquals(7, user.itemCount)
        assertEquals(20.0, user.lastItemAdded, 0.0)
        assertEquals("https://inventaire.io/img/users/1", user.avatarUrl)
        val merged = Merges.user(user.copy(email = "kept@x"), dto.copy(picture = null), "https://inventaire.io")
        assertEquals("kept@x", merged.email)
        assertEquals("https://inventaire.io/img/users/1", merged.avatarUrl)
    }

    @Test
    fun an_item_keeps_its_details_when_the_payload_has_none() {
        val dto = ItemDto(
            id = "i1",
            rev = "1",
            entity = "isbn:1",
            transaction = "lending",
            owner = "u1",
            created = 1.0,
            snapshot = EntitySnapshotDto(title = "Les Misérables", authors = "Victor Hugo"),
            details = "Superbe",
        )
        val item = Merges.item(null, dto, "olive")
        assertEquals(TransactionType.Lending, item.transaction)
        assertEquals("olive victor hugo les miserables", item.searchIndex)
        assertEquals("Superbe", Merges.item(item, dto.copy(details = null), "olive").details)
    }

    @Test
    fun a_snapshot_edition_splits_its_authors() {
        val edition = Merges.edition("isbn:1", EntitySnapshotDto(title = "T", authors = "A, B", image = "x.jpg"))
        assertEquals(listOf("A", "B"), edition.authorNames)
        assertEquals("https://commons.wikimedia.org/wiki/Special:FilePath/x.jpg?width=512", edition.image)
    }

    @Test
    fun a_friendship_wins_over_a_pending_request() {
        val states = UserRepository.relationsById(
            UserNetworkDto(friends = listOf("a"), userRequested = listOf("a", "b"), otherRequested = listOf("c")),
        )
        assertEquals(UserRelation.Friend, states["a"])
        assertEquals(UserRelation.RequestSent, states["b"])
        assertEquals(UserRelation.RequestReceived, states["c"])
    }

    @Test
    fun folding_drops_case_and_diacritics() {
        assertEquals("ecole elementaire", Merges.fold("  École Élémentaire "))
    }
}
