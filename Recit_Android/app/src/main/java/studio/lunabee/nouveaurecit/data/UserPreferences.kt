package studio.lunabee.nouveaurecit.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_preferences")

/**
 * `UserDefaults` / `@AppStorage`: small per-device answers — a dismissed notice, recent searches.
 * Keys are free-form; a feature names its own (`profile.inventaireNotice.dismissed`, …).
 */
class UserPreferences(context: Context) {
    private val store: DataStore<Preferences> = context.dataStore
    private val strings = ListSerializer(String.serializer())

    fun observeBoolean(key: String, default: Boolean = false): Flow<Boolean> =
        store.data.map { it[booleanPreferencesKey(key)] ?: default }

    suspend fun setBoolean(key: String, value: Boolean) {
        store.edit { it[booleanPreferencesKey(key)] = value }
    }

    fun observeStrings(key: String): Flow<List<String>> =
        store.data.map { preferences ->
            preferences[stringPreferencesKey(key)]?.let { runCatching { Json.decodeFromString(strings, it) }.getOrNull() }.orEmpty()
        }

    suspend fun setStrings(key: String, value: List<String>) {
        store.edit { it[stringPreferencesKey(key)] = Json.encodeToString(strings, value) }
    }
}
