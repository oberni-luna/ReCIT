package studio.lunabee.nouveaurecit.ui.profile.edit

import android.content.Context
import org.osmdroid.config.Configuration
import studio.lunabee.nouveaurecit.BuildConfig
import java.io.File

/**
 * osmdroid's settings, applied once before the first map. OpenStreetMap's tile usage policy asks every
 * app to name itself: the user agent is the app's id. Tiles are cached in the app's cache, never on
 * shared storage.
 */
object OsmConfiguration {
    private var isApplied: Boolean = false

    fun apply(context: Context) {
        if (isApplied) return
        val appContext: Context = context.applicationContext
        Configuration.getInstance().apply {
            load(appContext, appContext.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE))
            userAgentValue = BuildConfig.APPLICATION_ID
            osmdroidBasePath = File(appContext.cacheDir, BASE_DIRECTORY)
            osmdroidTileCache = File(osmdroidBasePath, TILE_DIRECTORY)
        }
        isApplied = true
    }

    private const val PREFERENCES_NAME: String = "osmdroid"
    private const val BASE_DIRECTORY: String = "osmdroid"
    private const val TILE_DIRECTORY: String = "tiles"
}
