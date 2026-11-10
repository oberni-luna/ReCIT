package studio.lunabee.nouveaurecit.data.db

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File

/**
 * The exported schemas `AutoMigration(2, 3)` is derived from: version 3 only adds `inventory_items.notes`,
 * a `NOT NULL` column with a default, so a database of version 2 upgrades without losing a row. No
 * `MigrationTestHelper` here — it needs an instrumented test, which the project does not run.
 */
class AppDatabaseSchemaTest {
    private fun tables(version: Int): Map<String, JsonObject> {
        val file: File = File("schemas/studio.lunabee.nouveaurecit.data.db.AppDatabase/$version.json")
        val database: JsonObject = Json.parseToJsonElement(file.readText()).jsonObject.getValue("database").jsonObject
        return database.getValue("entities").jsonArray.associate { entity ->
            entity.jsonObject.getValue("tableName").jsonPrimitive.content to entity.jsonObject
        }
    }

    private fun fields(table: JsonObject): Map<String, JsonObject> =
        (table.getValue("fields") as JsonArray).associate { it.jsonObject.getValue("columnName").jsonPrimitive.content to it.jsonObject }

    @Test
    fun version_3_only_adds_the_items_notes_with_a_default() {
        val before: Map<String, JsonObject> = tables(2)
        val after: Map<String, JsonObject> = tables(3)
        assertEquals(before.keys, after.keys)
        before.keys.filter { it != "inventory_items" }.forEach { name ->
            assertEquals(name, before.getValue(name), after.getValue(name))
        }

        val itemsBefore: Map<String, JsonObject> = fields(before.getValue("inventory_items"))
        val itemsAfter: Map<String, JsonObject> = fields(after.getValue("inventory_items"))
        assertEquals(itemsBefore, itemsAfter - "notes")
        val notes: JsonObject = itemsAfter.getValue("notes")
        assertEquals("true", notes.getValue("notNull").jsonPrimitive.content)
        assertEquals("''", notes.getValue("defaultValue").jsonPrimitive.content)
    }
}
