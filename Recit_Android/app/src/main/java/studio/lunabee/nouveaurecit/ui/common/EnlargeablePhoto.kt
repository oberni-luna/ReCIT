package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import studio.lunabee.nouveaurecit.R

/**
 * iOS `EnlargeablePhotoModifier` (features 0081 and 0085): a reader's, a group's or an author's [photo]
 * that opens the Plein écran of [url] on a tap, read by TalkBack as « Agrandir la photo », a button.
 * Without a url, or while not [isEnabled], the photo is left as it is: nothing to open, nothing to press.
 *
 * [photo] is handed the memory-cache key to load [url] under, so that the Plein écran opens on it rather
 * than on an empty screen. The key does not depend on [isEnabled]: turning the tap on or off loads nothing
 * again.
 */
@Composable
internal fun EnlargeablePhoto(
    url: String?,
    modifier: Modifier = Modifier,
    isEnabled: Boolean = true,
    photo: @Composable (memoryCacheKey: String?) -> Unit,
) {
    var showsFullScreen: Boolean by rememberSaveable { mutableStateOf(false) }
    val label: String = stringResource(R.string.photo_action_enlarge)
    val opens: Modifier = if (url != null && isEnabled) {
        Modifier
            .clearAndSetSemantics {
                contentDescription = label
                role = Role.Button
                onClick {
                    showsFullScreen = true
                    true
                }
            }
            .clickable(interactionSource = null, indication = null) { showsFullScreen = true }
    } else {
        Modifier
    }
    Box(modifier.then(opens)) {
        photo(url?.let(::fullScreenMemoryCacheKey))
    }
    if (showsFullScreen && url != null) {
        FullScreenCoverDialog(
            url = url,
            contentDescription = stringResource(R.string.photo_accessibility_label),
            onDismiss = { showsFullScreen = false },
        )
    }
}
