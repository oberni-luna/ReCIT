package studio.lunabee.nouveaurecit.network

import org.junit.Assert.assertEquals
import org.junit.Test

/** iOS `FullScreenImageURLTests`: the address of a cover at the size worth showing on a whole screen. */
class FullScreenImageUrlTest {
    @Test
    fun aWikimediaFileAskedAt512Or1024IsAskedAtFullScreenWidth() {
        assertEquals(
            "https://commons.wikimedia.org/wiki/Special:FilePath/Victor%20Hugo.jpg?width=2048",
            ImageUrl.fullScreen("https://commons.wikimedia.org/wiki/Special:FilePath/Victor%20Hugo.jpg?width=1024"),
        )
    }

    @Test
    fun aWikimediaFileAskedAtNoWidthIsGivenOne() {
        assertEquals(
            "https://commons.wikimedia.org/wiki/Special:FilePath/Cover.jpg?width=2048",
            ImageUrl.fullScreen("https://commons.wikimedia.org/wiki/Special:FilePath/Cover.jpg"),
        )
    }

    @Test
    fun otherQueryItemsAreKept() {
        assertEquals(
            "https://commons.wikimedia.org/wiki/Special:FilePath/Cover.jpg?lang=fr&width=2048",
            ImageUrl.fullScreen("https://commons.wikimedia.org/wiki/Special:FilePath/Cover.jpg?width=512&lang=fr"),
        )
    }

    @Test
    fun theAppsOwnCommonsUrlIsRaised() {
        val header: String? = ImageUrl.absolute("Cover.jpg")

        assertEquals(
            "https://commons.wikimedia.org/wiki/Special:FilePath/Cover.jpg?width=2048",
            ImageUrl.fullScreen(requireNotNull(header)),
        )
    }

    @Test
    fun anInventaireImageAlreadyNamesItsOriginalAndIsLeftAlone() {
        val url = "https://inventaire.io/img/entities/63b88ac1290ce52588b4a39d59f3679853394c49"

        assertEquals(url, ImageUrl.fullScreen(url))
    }

    @Test
    fun aWidthOnAnotherHostIsLeftAlone() {
        val url = "https://example.org/wiki/Special:FilePath/Cover.jpg?width=512"

        assertEquals(url, ImageUrl.fullScreen(url))
    }
}
