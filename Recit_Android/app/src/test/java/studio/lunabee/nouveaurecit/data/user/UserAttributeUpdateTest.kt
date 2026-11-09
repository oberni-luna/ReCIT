package studio.lunabee.nouveaurecit.data.user

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService

/** The body of `PUT /api/user`, encoded by the app's own JSON — which leaves a Kotlin `null` out. */
class UserAttributeUpdateTest {
    private fun encoded(update: UserAttributeUpdate): String =
        ApiService.DefaultJson.encodeToString(UserAttributeUpdate.serializer(), update)

    @Test
    fun anAbsentValueIsSentAsAnExplicitNull() {
        assertEquals("""{"attribute":"picture","value":null}""", encoded(UserAttributeUpdate.of("picture", null as String?)))
        assertEquals("""{"attribute":"position","value":null}""", encoded(UserAttributeUpdate.of("position", null as Coordinates?)))
    }

    @Test
    fun aPositionIsLatitudeThenLongitude() {
        assertEquals("""{"attribute":"position","value":[45.75,4.83]}""", encoded(UserAttributeUpdate.of("position", Coordinates(45.75, 4.83))))
    }

    @Test
    fun textIsSentAsAString() {
        assertEquals("""{"attribute":"bio","value":"Polars"}""", encoded(UserAttributeUpdate.of("bio", "Polars")))
    }
}
