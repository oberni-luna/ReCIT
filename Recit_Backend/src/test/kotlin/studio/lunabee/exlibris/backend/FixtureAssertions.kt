package studio.lunabee.exlibris.backend

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.longOrNull
import kotlin.test.assertEquals

/**
 * Compares an answer with a fixture of inventaire.io's (`src/test/resources/fixtures/inventaire/`, README there):
 * the same keys with the same JSON types, and the same values for the keys the apps match on. inventaire.io's
 * `context` is debugging data the apps never read, and `status_verbose` is the skeleton's own (#69): neither is
 * compared.
 */
object FixtureAssertions {
    private val ignoredKeys: Set<String> = setOf("context", "status_verbose")
    private val matchedKeys: Set<String> = setOf("status", "message", "error_type", "error_name", "ok")

    fun assertMatchesFixture(
        fixture: String,
        actual: String,
    ) {
        assertMatchesShape(fixture(fixture), Json.parseToJsonElement(actual).jsonObject, fixture)
    }

    /**
     * The same comparison for one object inside an answer — a user of `by-ids`, a hit of a search — against the
     * matching object inside a fixture, which [fixture] reads.
     */
    fun assertMatchesShape(
        expected: JsonObject,
        answer: JsonObject,
        label: String,
    ) {
        assertEquals(expected.keys - ignoredKeys, answer.keys - ignoredKeys, "keys of $label")
        (expected.keys - ignoredKeys).forEach { key ->
            val expectedValue: JsonElement = expected.getValue(key)
            val answerValue: JsonElement = answer.getValue(key)
            assertEquals(typeOf(expectedValue), typeOf(answerValue), "type of $key in $label")
            if (key in matchedKeys) assertEquals(expectedValue, answerValue, "value of $key in $label")
        }
    }

    fun fixture(fixture: String): JsonObject = Json.parseToJsonElement(read(fixture)).jsonObject

    private fun read(fixture: String): String =
        requireNotNull(
            FixtureAssertions::class.java.getResource("/fixtures/inventaire/$fixture"),
        ) { "no fixture $fixture" }
            .readText()

    private fun typeOf(element: JsonElement): String =
        when (element) {
            is JsonObject -> {
                "object"
            }

            is JsonArray -> {
                "array"
            }

            JsonNull -> {
                "null"
            }

            is JsonPrimitive -> {
                when {
                    element.isString -> "string"
                    element.booleanOrNull != null -> "boolean"
                    element.longOrNull != null -> "integer"
                    else -> "number"
                }
            }
        }
}
