package studio.lunabee.nouveaurecit.ui.profile.account

import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.user.AccountSettings
import studio.lunabee.nouveaurecit.data.user.NotificationSetting
import studio.lunabee.nouveaurecit.designsystem.DISABLED_ALPHA
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SwitchRow
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.editedition.EditionPropertyRow
import studio.lunabee.nouveaurecit.ui.editedition.FormDivider
import studio.lunabee.nouveaurecit.ui.editedition.FormSection
import studio.lunabee.nouveaurecit.ui.editedition.PropertyRowTrailing
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `NotificationSettingsView` (iOS feature 0055): « Notifications par e-mail » — which e-mails inventaire.io
 * sends, one switch per key of `settings.notifications`, and how often the activity summary comes. Every
 * switch writes itself, optimistic, and goes back with a snackbar if the server refuses; the general one,
 * off, greys the others — they keep their value, but nothing is sent.
 */
@Composable
fun NotificationSettingsScreen(navigator: Navigator) {
    val viewModel: NotificationSettingsViewModel = recitViewModel { NotificationSettingsViewModel(it) }
    val settings: AccountSettings? by viewModel.settings.collectAsStateWithLifecycle()

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.notifications_title), onBack = navigator::pop) },
        containerColor = RecitTheme.colors.backgroundForm,
    ) { padding: PaddingValues ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            val account: AccountSettings? = settings
            if (account == null) {
                CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary, modifier = Modifier.align(Alignment.Center))
            } else {
                NotificationSettingsForm(account = account, viewModel = viewModel)
            }
        }
    }
}

@Composable
private fun NotificationSettingsForm(account: AccountSettings, viewModel: NotificationSettingsViewModel) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = Spacing.small, bottom = Spacing.large),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        item(key = "global") {
            FormSection(header = null, footer = null) {
                NotificationSwitch(NotificationSetting.Global, account, viewModel, detail = R.string.notifications_global_detail)
            }
        }
        item(key = "summary") {
            FormSection(header = stringResource(R.string.notifications_summary_header), footer = null) {
                NotificationSwitch(
                    NotificationSetting.InventoriesActivitySummary,
                    account,
                    viewModel,
                    detail = R.string.notifications_summary_detail,
                )
                FormDivider()
                PeriodicityRow(
                    days = account.summaryPeriodicity,
                    enabled = account.canEditSummaryPeriodicity,
                    onPick = viewModel::setSummaryPeriodicity,
                )
            }
        }
        NOTIFICATION_GROUPS.forEach { group: NotificationGroup ->
            item(key = group.key) {
                FormSection(header = stringResource(group.header), footer = null) {
                    group.settings.forEachIndexed { index: Int, setting: NotificationSetting ->
                        if (index > 0) FormDivider()
                        NotificationSwitch(setting, account, viewModel)
                    }
                }
            }
        }
    }
}

@Composable
private fun NotificationSwitch(
    setting: NotificationSetting,
    account: AccountSettings,
    viewModel: NotificationSettingsViewModel,
    @StringRes detail: Int? = null,
) {
    SwitchRow(
        title = stringResource(setting.title),
        detail = detail?.let { stringResource(it) },
        checked = account.isEnabled(setting),
        onCheckedChange = { isOn: Boolean -> viewModel.setNotification(setting, isOn) },
        enabled = account.canEdit(setting),
        modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.sMedium).testTag("e2e.notifications.${setting.key}"),
    )
}

/** « Fréquence »: the days between two summaries, from a menu; greyed while the summary is not sent. */
@Composable
private fun PeriodicityRow(days: Int, enabled: Boolean, onPick: (Int) -> Unit) {
    var expanded: Boolean by rememberSaveable { mutableStateOf(false) }
    Box(Modifier.alpha(if (enabled) 1f else DISABLED_ALPHA)) {
        EditionPropertyRow(
            label = stringResource(R.string.notifications_summary_periodicity),
            value = periodicityLabel(days),
            placeholder = "",
            trailing = PropertyRowTrailing.Menu,
            onClick = if (enabled) ({ expanded = true }) else null,
            modifier = Modifier.testTag("e2e.notifications.periodicity"),
        )
        DropdownMenu(
            expanded = expanded && enabled,
            onDismissRequest = { expanded = false },
            containerColor = RecitTheme.colors.backgroundRaised,
        ) {
            NotificationSettingsViewModel.periodicities(including = days).forEach { option: Int ->
                DropdownMenuItem(
                    text = { Text(text = periodicityLabel(option), style = RecitTheme.typography.content300) },
                    trailingIcon = {
                        if (option == days) Icon(Icons.Default.Check, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
                    },
                    onClick = {
                        expanded = false
                        onPick(option)
                    },
                )
            }
        }
    }
}

/** « Tous les jours », else « Tous les N jours »: French has no singular past one day here. */
@Composable
private fun periodicityLabel(days: Int): String =
    if (days == 1) stringResource(R.string.notifications_summary_daily) else stringResource(R.string.notifications_summary_every, days)

/** A section of switches under its header: friends, groups and exchanges, as iOS orders them. */
private class NotificationGroup(val key: String, @StringRes val header: Int, val settings: List<NotificationSetting>)

private val NOTIFICATION_GROUPS: List<NotificationGroup> = listOf(
    NotificationGroup(
        key = "friends",
        header = R.string.notifications_friends_header,
        settings = listOf(NotificationSetting.FriendshipRequest, NotificationSetting.FriendAcceptedRequest),
    ),
    NotificationGroup(
        key = "groups",
        header = R.string.notifications_groups_header,
        settings = listOf(NotificationSetting.GroupInvite, NotificationSetting.GroupAcceptRequest, NotificationSetting.GroupJoinRequest),
    ),
    NotificationGroup(
        key = "transactions",
        header = R.string.notifications_transactions_header,
        settings = listOf(
            NotificationSetting.YourItemWasRequested,
            NotificationSetting.UpdateOnYourItem,
            NotificationSetting.UpdateOnItemYouRequested,
        ),
    ),
)

@get:StringRes
private val NotificationSetting.title: Int
    get() = when (this) {
        NotificationSetting.Global -> R.string.notifications_global
        NotificationSetting.InventoriesActivitySummary -> R.string.notifications_summary
        NotificationSetting.FriendshipRequest -> R.string.notifications_friendship_request
        NotificationSetting.FriendAcceptedRequest -> R.string.notifications_friend_accepted_request
        NotificationSetting.GroupInvite -> R.string.notifications_group_invite
        NotificationSetting.GroupAcceptRequest -> R.string.notifications_group_accept_request
        NotificationSetting.GroupJoinRequest -> R.string.notifications_group_join_request
        NotificationSetting.YourItemWasRequested -> R.string.notifications_your_item_was_requested
        NotificationSetting.UpdateOnYourItem -> R.string.notifications_update_on_your_item
        NotificationSetting.UpdateOnItemYouRequested -> R.string.notifications_update_on_item_you_requested
    }
