package studio.lunabee.nouveaurecit.ui.network

import android.content.Context
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TintedTextButton
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

class InvitationsViewModel(container: AppContainer) : ViewModel() {
    val received: StateFlow<List<UserEntity>> = container.users.observeByRelation(UserRelation.RequestReceived)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val sent: StateFlow<List<UserEntity>> = container.users.observeByRelation(UserRelation.RequestSent)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val firstSyncProgress: StateFlow<Map<String, SyncStatus.Progress>> = container.syncStatus.firstSyncProgress

    val actions: RelationActions = RelationActions(container, viewModelScope)
}

/**
 * `InvitationsView`: both directions of the waiting on one screen — what is asked of me (« Reçues »,
 * with the two answers) and what I have asked (« Envoyées »). Everything is read from Room, so an
 * answer given on a profile redraws this screen behind it.
 */
@Composable
fun InvitationsScreen(navigator: Navigator) {
    val viewModel: InvitationsViewModel = recitViewModel { InvitationsViewModel(it) }
    val received: List<UserEntity> by viewModel.received.collectAsStateWithLifecycle()
    val sent: List<UserEntity> by viewModel.sent.collectAsStateWithLifecycle()
    val progress: Map<String, SyncStatus.Progress> by viewModel.firstSyncProgress.collectAsStateWithLifecycle()
    val messenger: Messenger = LocalMessenger.current
    val context: Context = LocalContext.current

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.network_invitations), onBack = navigator::pop) },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(bottom = Spacing.large),
        ) {
            if (received.isEmpty() && sent.isEmpty()) {
                item(key = "empty") {
                    EmptyState(
                        title = stringResource(R.string.network_invitations_empty),
                        message = stringResource(R.string.network_invitations_empty_message),
                        icon = Icons.Outlined.Email,
                        modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
                    )
                }
            }

            if (received.isNotEmpty()) {
                item(key = "received-header") {
                    SectionHeader(stringResource(R.string.network_invitations_received), Modifier.padding(horizontal = Spacing.medium))
                }
                item(key = "received") {
                    SectionCard {
                        received.forEachIndexed { index, user ->
                            if (index > 0) HorizontalDivider(color = RecitTheme.colors.borderDefault)
                            InvitationRow(
                                user = user,
                                syncState = FirstSyncState.of(user.lastInventorySync, progress[user.id]),
                                onOpen = { navigator.push(Destination.User(user.id)) },
                                onAccept = {
                                    viewModel.actions.accept(user.id)
                                    messenger.show(context.getString(R.string.network_invitation_accepted, user.username))
                                },
                                onRefuse = {
                                    viewModel.actions.refuse(user.id)
                                    messenger.show(context.getString(R.string.network_invitation_refused, user.username))
                                },
                            )
                        }
                    }
                }
            }

            if (sent.isNotEmpty()) {
                item(key = "sent-header") {
                    SectionHeader(stringResource(R.string.network_invitations_sent), Modifier.padding(horizontal = Spacing.medium))
                }
                item(key = "sent") {
                    SectionCard {
                        sent.forEachIndexed { index, user ->
                            if (index > 0) HorizontalDivider(color = RecitTheme.colors.borderDefault)
                            ReaderRow(
                                user = user,
                                syncState = FirstSyncState.of(user.lastInventorySync, progress[user.id]),
                                onOpen = { navigator.push(Destination.User(user.id)) },
                                onAdd = { viewModel.actions.request(user.id) },
                            )
                            TintedTextButton(
                                text = stringResource(R.string.network_request_cancel),
                                onClick = { viewModel.actions.cancel(user.id) },
                                color = RecitTheme.colors.foregroundError,
                                modifier = Modifier.padding(start = Spacing.small, bottom = Spacing.xSmall),
                            )
                        }
                    }
                }
            }
        }
    }
}
