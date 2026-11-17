package studio.lunabee.nouveaurecit.ui.common

import android.content.Context
import android.content.Intent
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.navigation.DeepLink

/**
 * iOS `DeepLinkShareLink`: « Partager » opens the system chooser with the Ex-libris link to what the screen shows,
 * and its name — the book's title, the reader's, the group's, the list's or the étagère's — as subject. A link that
 * cannot be built ([DeepLink.url] is `null`) offers nothing, so a screen never shares a link that would not open.
 */
fun Context.shareLink(url: String, subject: String) {
    val send: Intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, url)
        putExtra(Intent.EXTRA_SUBJECT, subject)
    }
    startActivity(Intent.createChooser(send, null))
}

/** The share icon of a top bar, beside what is already there. */
@Composable
fun ShareLinkButton(link: DeepLink, subject: String) {
    val url: String = link.url ?: return
    val context: Context = LocalContext.current
    IconButton(onClick = { context.shareLink(url, subject) }) {
        Icon(Icons.Filled.Share, contentDescription = stringResource(R.string.action_share))
    }
}

/** « Partager » as the line of a « … » menu; [onClick] closes the menu. */
@Composable
fun ShareLinkMenuItem(link: DeepLink, subject: String, onClick: () -> Unit) {
    val url: String = link.url ?: return
    val context: Context = LocalContext.current
    DropdownMenuItem(
        text = { Text(stringResource(R.string.action_share), color = RecitTheme.colors.foregroundDefault) },
        leadingIcon = { Icon(Icons.Filled.Share, contentDescription = null, tint = RecitTheme.colors.foregroundDefault) },
        onClick = {
            onClick()
            context.shareLink(url, subject)
        },
    )
}
