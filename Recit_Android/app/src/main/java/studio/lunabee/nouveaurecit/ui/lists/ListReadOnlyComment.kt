package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/** `ListReadOnlyCommentRow`: someone else's comment on the element facing the reader, as text. */
@Composable
internal fun ListReadOnlyComment(comment: String, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
        Text(stringResource(R.string.list_detail_comment_other), style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundSecondary)
        SelectionContainer {
            Text(comment, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
        }
    }
}
