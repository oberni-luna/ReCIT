package studio.lunabee.nouveaurecit.ui.profile.account

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.MarkEmailUnread
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `EmailConfirmationNotice` (iOS feature 0055): the card at the head of « Compte et connexion » while the
 * address is not confirmed (`Form / Notice`) — which address the link went to, and « Renvoyer l’e-mail ».
 */
@Composable
fun EmailConfirmationNotice(email: String, isResending: Boolean, onResend: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .padding(horizontal = Spacing.medium)
            .fillMaxWidth()
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(RecitTheme.colors.backgroundTinted)
            .padding(Spacing.sMedium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Icon(Icons.Outlined.MarkEmailUnread, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Text(
                text = stringResource(R.string.account_unconfirmed_title),
                style = RecitTheme.typography.content400Bold,
                color = RecitTheme.colors.foregroundDefault,
            )
            Text(
                text = stringResource(R.string.account_unconfirmed_body, email),
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundDefault,
            )
            Row(
                modifier = Modifier
                    .clickable(enabled = !isResending, role = Role.Button, onClick = onResend)
                    .testTag("e2e.account.resendConfirmation"),
                horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = stringResource(R.string.account_unconfirmed_resend),
                    style = RecitTheme.typography.action200,
                    color = if (isResending) RecitTheme.colors.foregroundDisable else RecitTheme.colors.foregroundTinted,
                )
                if (isResending) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(Spacing.sMedium),
                        color = RecitTheme.colors.foregroundSecondary,
                        strokeWidth = 2.dp,
                    )
                }
            }
        }
    }
}
