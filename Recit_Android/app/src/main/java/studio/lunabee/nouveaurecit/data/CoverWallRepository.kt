package studio.lunabee.nouveaurecit.data

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.RecentPublicItemsDto
import studio.lunabee.nouveaurecit.ui.auth.coverwall.CoverWallCatalog

/**
 * `AppModels/CoverWall/CoverWallModel.swift`: the covers of the books last published on
 * inventaire.io, for the welcome wall. The only call made before there is a user, so it goes
 * through the public client, raises nothing, reports nothing, and never empties the wall: the
 * last good answer is kept in preferences and read back before any network.
 */
class CoverWallRepository(
    private val publicApi: ApiService,
    private val preferences: UserPreferences,
) {
    private val _paths: MutableStateFlow<List<String>> = MutableStateFlow(emptyList())
    val paths: StateFlow<List<String>> = _paths.asStateFlow()

    suspend fun refresh() {
        if (_paths.value.isEmpty()) {
            val cached: List<String> = runCatching { preferences.observeStringsOnce(CACHE_KEY) }.getOrDefault(emptyList())
            if (cached.isNotEmpty()) _paths.value = CoverWallCatalog.coverPaths(cached)
        }
        val fresh: List<String> = try {
            val dto: RecentPublicItemsDto = publicApi.get("/api/items/recent-public", "limit" to CoverWallCatalog.COVER_LIMIT.toString())
            CoverWallCatalog.coverPaths(dto.items.map { it.snapshot?.image })
        } catch (_: Exception) {
            return
        }
        if (fresh.isEmpty()) return
        _paths.value = fresh
        runCatching { preferences.setStrings(CACHE_KEY, fresh) }
    }

    private companion object {
        const val CACHE_KEY: String = "coverWall.recentPublicPaths"
    }
}
