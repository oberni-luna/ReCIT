package studio.lunabee.exlibris.backend.entities

import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.sendCookies
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RelayRequestRoutesTest {
    @Test
    fun `a signed-in reader's read reaches inventaire without their cookie, naming Ex-libris`() =
        InventaireStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                // `%7C`: the stub's JDK server refuses a raw `|`, which inventaire.io takes as well.
                val path = "/api/entities/by-uris?uris=wd:Q8337%7Cisbn:9782070368228&lang=fr"

                val status: HttpStatusCode =
                    client
                        .get(path) {
                            sendCookies(reader.cookies)
                            header(HttpHeaders.Authorization, "Bearer secret")
                            header(HttpHeaders.Accept, "application/json")
                            header(HttpHeaders.AcceptLanguage, "fr-FR")
                            header(HttpHeaders.IfNoneMatch, "W/\"2c1d\"")
                        }.status

                assertEquals(HttpStatusCode.OK, status)
                val received: StubRequest = stub.requests.single()
                assertEquals("GET", received.method)
                assertEquals(path, received.uri)
                assertNull(received.header(HttpHeaders.Cookie))
                assertNull(received.header(HttpHeaders.Authorization))
                assertEquals("application/json", received.header(HttpHeaders.Accept))
                assertEquals("fr-FR", received.header(HttpHeaders.AcceptLanguage))
                assertEquals("W/\"2c1d\"", received.header(HttpHeaders.IfNoneMatch))
                val userAgent: String? = received.header(HttpHeaders.UserAgent)
                assertNotNull(userAgent)
                assertTrue(exLibrisUserAgent.matches(userAgent), userAgent)
            }
        }

    @Test
    fun `every read under a relayed prefix is relayed, those the apps do not call yet included`() =
        InventaireStub().use { stub ->
            relayTest(stub) {
                val paths: List<String> =
                    listOf(
                        "/api/entities",
                        "/api/entities/author-works?uri=wd:Q42",
                        "/api/entities/reverse-claims?property=wdt:P50&value=wd:Q42",
                        "/api/entities/history?id=0123",
                        "/api/data/isbn?isbn=9782070368228",
                        "/api/data/wp-extract?lang=fr&title=Dune",
                        "/api/tasks/by-uris?uris=inv:0123&type=merge",
                        "/api/items/by-entities?uris=wd:Q8337&limit=1",
                        "/api/items/recent-public?limit=15&lang=fr",
                        "/img/entities/3af17a8d008b00047d93b00b3f77fbe00df75877",
                        "/img/remote/200x200/1234567890?href=https%3A%2F%2Fcommons.wikimedia.org%2Fx.jpg",
                    )

                paths.forEach { path ->
                    assertEquals(HttpStatusCode.OK, client.get(path).status, path)
                }

                assertEquals(paths, stub.requests.map { it.uri })
                assertTrue(stub.requests.all { exLibrisUserAgent.matches(it.header(HttpHeaders.UserAgent).orEmpty()) })
            }
        }
}
