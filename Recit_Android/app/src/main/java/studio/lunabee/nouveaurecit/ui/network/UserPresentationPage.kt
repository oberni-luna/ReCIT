package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FormatQuote
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/** `UserPresentationTab`: the reader's bio in one card, left-aligned and selectable — or that they wrote none. */
internal fun LazyListScope.userPresentationItems(user: UserEntity) {
    val bio: String? = user.bio?.takeIf { it.isNotBlank() }
    item(key = "presentation") {
        if (bio != null) {
            SelectionContainer(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.medium, vertical = Spacing.small)
                    .clip(RoundedCornerShape(CornerRadius.rounded))
                    .background(RecitTheme.colors.backgroundSecondary)
                    .padding(Spacing.medium),
            ) {
                Text(bio, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
            }
        } else {
            EmptyState(
                title = stringResource(R.string.network_user_presentation_empty, user.username),
                icon = Icons.Outlined.FormatQuote,
                modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
            )
        }
    }
}
