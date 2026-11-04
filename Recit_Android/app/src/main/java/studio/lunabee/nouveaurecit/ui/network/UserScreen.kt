package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.designsystem.ConfirmDialog
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SecondaryButton
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `UserDetailView`: who a reader is, and — for a friend, or me — their étagères and books, lists and
 * presentation ([UserProfile]). For anyone else the books stay closed, and the screen offers what can be
 * done about the relation (`RelationActionsView`). Unfriending sits behind the « … » and a confirmation:
 * it is the one gesture of the flow that loses something.
 */
@Composable
fun UserScreen(destination: Destination.User, navigator: Navigator) {
    val viewModel: UserViewModel = recitViewModel(key = destination.id) { UserViewModel(it, destination.id) }
    val user: UserEntity? by viewModel.user.collectAsStateWithLifecycle()
    val myUserId: String? by viewModel.myUserId.collectAsStateWithLifecycle()
    var isConfirmingRemoval: Boolean by rememberSaveable { mutableStateOf(false) }
    var isConfirmingRequest: Boolean by rememberSaveable { mutableStateOf(false) }

    val current: UserEntity? = user
    val isMe: Boolean = destination.id == myUserId

    Scaffold(containerColor = RecitTheme.colors.backgroundDefault) { padding ->
        Box(Modifier.fillMaxSize()) {
            if (current == null) {
                CircularProgressIndicator(color = RecitTheme.colors.foregroundTinted, modifier = Modifier.align(Alignment.Center))
            } else {
                UserProfile(
                    user = current,
                    isMe = isMe,
                    showsTabs = showsInventory(current.id, myUserId, current.relation),
                    viewModel = viewModel,
                    navigator = navigator,
                    onAskToAdd = { isConfirmingRequest = true },
                    bottomPadding = padding.calculateBottomPadding(),
                )
            }
            // No title: the header names the reader, and folds into the bar's row.
            RecitTopBar(
                title = "",
                onBack = navigator::pop,
                containerColor = Color.Transparent,
                actions = {
                    if (current != null && !isMe && current.relation == UserRelation.Friend) {
                        UserMenu(onRemove = { isConfirmingRemoval = true })
                    }
                },
            )
        }
    }

    if (isConfirmingRemoval && current != null) {
        ConfirmDialog(
            title = null,
            message = stringResource(R.string.network_remove_confirm, current.username),
            confirmLabel = stringResource(R.string.network_remove),
            cancelLabel = stringResource(R.string.action_cancel),
            onConfirm = {
                isConfirmingRemoval = false
                viewModel.actions.unfriend(current.id)
            },
            onDismiss = { isConfirmingRemoval = false },
        )
    }

    if (isConfirmingRequest && current != null) {
        RelationRequestSheet(
            user = current,
            onSend = {
                isConfirmingRequest = false
                viewModel.actions.request(current.id)
            },
            onDismiss = { isConfirmingRequest = false },
        )
    }
}

@Composable
private fun UserMenu(onRemove: () -> Unit) {
    var expanded: Boolean by rememberSaveable { mutableStateOf(false) }
    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(painterResource(R.drawable.ic_more), contentDescription = stringResource(R.string.action_more))
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            containerColor = RecitTheme.colors.backgroundDefault,
        ) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.network_remove), color = RecitTheme.colors.foregroundDefault) },
                leadingIcon = {
                    Icon(Icons.AutoMirrored.Outlined.Logout, contentDescription = null, tint = RecitTheme.colors.foregroundDefault)
                },
                onClick = {
                    expanded = false
                    onRemove()
                },
            )
        }
    }
}

/**
 * `RelationRequestSheet`: it only confirms — `POST /api/relations/request` takes a user id and
 * nothing else, so there is no message to type.
 */
@Composable
private fun RelationRequestSheet(user: UserEntity, onSend: () -> Unit, onDismiss: () -> Unit) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = RecitTheme.colors.backgroundRaised,
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium).padding(bottom = Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            Text(
                text = stringResource(R.string.network_request_title),
                style = RecitTheme.typography.title50,
                color = RecitTheme.colors.foregroundDefault,
                modifier = Modifier.align(Alignment.CenterHorizontally),
            )
            ReaderCell(user = user, syncState = FirstSyncState.Synced)
            Text(
                text = stringResource(R.string.network_request_explanation, user.username),
                style = RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundSecondary,
            )
            PrimaryButton(text = stringResource(R.string.network_request_send), onClick = onSend)
            SecondaryButton(
                text = stringResource(R.string.action_cancel),
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

