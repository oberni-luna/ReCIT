package studio.lunabee.nouveaurecit.ui.common

import android.content.Context
import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext

/**
 * `accessibilityReduceMotion`: whether the system's « Supprimer les animations » is on — an animator
 * duration scale of 0. Read once, as the screen first composes.
 */
@Composable
fun rememberReducesMotion(): Boolean {
    val context: Context = LocalContext.current
    return remember {
        Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    }
}
