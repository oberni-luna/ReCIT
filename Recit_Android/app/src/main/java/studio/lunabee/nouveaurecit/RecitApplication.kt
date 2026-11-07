package studio.lunabee.nouveaurecit

import android.app.Application
import coil3.ImageLoader
import coil3.PlatformContext
import coil3.SingletonImageLoader

class RecitApplication : Application(), SingletonImageLoader.Factory {
    /** Built on first use, `MainActivity`'s, once `BackendOverride` has read the launch intent. */
    val container: AppContainer by lazy { AppContainer(this) }

    override fun newImageLoader(context: PlatformContext): ImageLoader = container.imageLoader(context)
}
