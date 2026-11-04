package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.designsystem.DestructiveButton
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SecondaryButton
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger

/**
 * The single page of a reader whose books are closed to me: no tabs, so their bio heads it, centred,
 * then what can be done about the relation, then « Inventaire privé ».
 */
internal fun LazyListScope.userClosedItems(
    user: UserEntity,
    actions: RelationActions,
    onAskToAdd: () -> Unit,
) {
    user.bio?.takeIf { it.isNotBlank() }?.let { bio ->
        item(key = "bio") {
            SelectionContainer(Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.small)) {
                Text(
                    text = bio,
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundDefault,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
    item(key = "relation-actions") {
        val messenger: Messenger = LocalMessenger.current
        val acceptedMessage: String = stringResource(R.string.network_invitation_accepted, user.username)
        val refusedMessage: String = stringResource(R.string.network_invitation_refused, user.username)
        RelationActionsPanel(
            user = user,
            onAskToAdd = onAskToAdd,
            onCancel = { actions.cancel(user.id) },
            onAccept = {
                actions.accept(user.id)
                messenger.show(acceptedMessage)
            },
            onRefuse = {
                actions.refuse(user.id)
                messenger.show(refusedMessage)
            },
        )
    }
    item(key = "private") {
        EmptyState(
            title = stringResource(R.string.network_private_inventory_title),
            message = stringResource(R.string.network_private_inventory_message, user.username),
            icon = Icons.Outlined.Person,
            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
        )
    }
}

/**
 * `RelationActionsView`: what can be done about a reader one is not (yet) close to — ask, take the
 * asking back, or answer — each with the sentence saying what the gesture costs.
 */
@Composable
private fun RelationActionsPanel(
    user: UserEntity,
    onAskToAdd: () -> Unit,
    onCancel: () -> Unit,
    onAccept: () -> Unit,
    onRefuse: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        when (user.relation) {
            UserRelation.None -> {
                PrimaryButton(text = stringResource(R.string.network_add_to_network), onClick = onAskToAdd)
                Note(stringResource(R.string.network_reciprocal))
            }
            UserRelation.RequestSent -> {
                SecondaryButton(
                    text = stringResource(R.string.network_request_awaiting),
                    onClick = {},
                    enabled = false,
                    modifier = Modifier.fillMaxWidth(),
                )
                DestructiveButton(text = stringResource(R.string.network_request_cancel), onClick = onCancel)
                Note(stringResource(R.string.network_request_no_notification, user.username))
            }
            UserRelation.RequestReceived -> {
                PrimaryButton(text = stringResource(R.string.network_invitation_accept_request), onClick = onAccept)
                SecondaryButton(
                    text = stringResource(R.string.network_invitation_refuse),
                    onClick = onRefuse,
                    modifier = Modifier.fillMaxWidth(),
                )
                Note(stringResource(R.string.network_invitation_explanation, user.username))
            }
            UserRelation.Friend -> Unit
        }
    }
}

@Composable
private fun Note(text: String) {
    Text(
        text = text,
        style = RecitTheme.typography.footnote200,
        color = RecitTheme.colors.foregroundSecondary,
        modifier = Modifier.fillMaxWidth(),
    )
}
