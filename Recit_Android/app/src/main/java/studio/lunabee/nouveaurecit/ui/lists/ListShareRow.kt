package studio.lunabee.nouveaurecit.ui.lists

import android.content.Context
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.common.ListCard
import studio.lunabee.nouveaurecit.ui.common.shareLink

/**
 * iOS `ListShareRow`: « Partager » on the selected element, under « Déplacer dans une autre liste » — [url] opens the
 * list on this element, [subject] is the element's title. The screen leaves it out on a list visible to its creator
 * alone, and for an element the server has not created yet.
 */
@Composable
internal fun ListShareRow(url: String, subject: String) {
    val context: Context = LocalContext.current
    ListCard(onClick = { context.shareLink(url, subject) }) {
        Text(
            stringResource(R.string.action_share),
            style = RecitTheme.typography.action300,
            color = RecitTheme.colors.foregroundTinted,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}
