package studio.lunabee.nouveaurecit.ui.profile.account

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.user.AccountLanguage
import studio.lunabee.nouveaurecit.data.user.AccountSettings
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SwitchRow
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.editedition.EditionPropertyRow
import studio.lunabee.nouveaurecit.ui.editedition.FormDivider
import studio.lunabee.nouveaurecit.ui.editedition.FormSection
import studio.lunabee.nouveaurecit.ui.editedition.PropertyRowTrailing
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `AccountSettingsView` (iOS feature 0055): « Compte et connexion » — the address and the password, each
 * behind a screen of its own, then the language of the account and two switches about who sees what.
 * No « Enregistrer »: the menu and the switches write themselves, optimistic, and go back with a snackbar
 * if the server refuses. While the address is not confirmed, [EmailConfirmationNotice] heads the screen.
 *
 * iOS's Wikidata section (feature 0070) is not ported.
 */
@Composable
fun AccountSettingsScreen(navigator: Navigator) {
    val viewModel: AccountSettingsViewModel = recitViewModel { AccountSettingsViewModel(it) }
    val settings: AccountSettings? by viewModel.settings.collectAsStateWithLifecycle()
    val loadFailed: Boolean by viewModel.loadFailed.collectAsStateWithLifecycle()

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.account_title), onBack = navigator::pop) },
        containerColor = RecitTheme.colors.backgroundForm,
    ) { padding: PaddingValues ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            val account: AccountSettings? = settings
            when {
                account != null -> AccountSettingsForm(account = account, viewModel = viewModel, navigator = navigator)
                loadFailed -> EmptyState(
                    title = stringResource(R.string.account_load_failed),
                    message = stringResource(R.string.account_load_failed_message),
                    icon = Icons.Filled.ErrorOutline,
                    actionTitle = stringResource(R.string.action_retry),
                    onAction = viewModel::load,
                    modifier = Modifier.align(Alignment.Center),
                )
                else -> CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary, modifier = Modifier.align(Alignment.Center))
            }
        }
    }
}

@Composable
private fun AccountSettingsForm(account: AccountSettings, viewModel: AccountSettingsViewModel, navigator: Navigator) {
    val messenger: Messenger = LocalMessenger.current
    val isResending: Boolean by viewModel.isResending.collectAsStateWithLifecycle()
    val genericError: String = stringResource(R.string.error_generic)
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = Spacing.small, bottom = Spacing.large),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        val unconfirmed: String? = account.email.takeUnless { account.isEmailValidated }
        if (unconfirmed != null) {
            item(key = "unconfirmed") {
                val sent: String = stringResource(R.string.account_unconfirmed_sent, unconfirmed)
                EmailConfirmationNotice(
                    email = unconfirmed,
                    isResending = isResending,
                    onResend = {
                        viewModel.resendConfirmation(
                            onSent = { messenger.show(sent) },
                            onFailure = { error: Throwable -> messenger.showError(genericError, error.localizedMessage) },
                        )
                    },
                )
            }
        }
        item(key = "signIn") {
            FormSection(header = stringResource(R.string.account_sign_in_header), footer = null) {
                EditionPropertyRow(
                    label = stringResource(R.string.account_email),
                    value = account.email,
                    placeholder = "",
                    onClick = { navigator.push(Destination.ChangeEmail) },
                    modifier = Modifier.testTag("e2e.account.email"),
                )
                FormDivider()
                EditionPropertyRow(
                    label = stringResource(R.string.account_password),
                    value = PASSWORD_MASK,
                    placeholder = "",
                    onClick = { navigator.push(Destination.ChangePassword) },
                    modifier = Modifier.testTag("e2e.account.password"),
                )
            }
        }
        item(key = "language") {
            FormSection(
                header = stringResource(R.string.account_language_header),
                footer = stringResource(R.string.account_language_footer),
            ) {
                LanguageRow(code = account.language, onPick = viewModel::setLanguage)
            }
        }
        item(key = "visibility") {
            FormSection(header = stringResource(R.string.account_visibility_header), footer = null) {
                SwitchRow(
                    title = stringResource(R.string.account_fediverse),
                    detail = stringResource(R.string.account_fediverse_detail),
                    checked = account.isFediversable,
                    onCheckedChange = viewModel::setFediversable,
                    modifier = Modifier.testTag("e2e.account.fediverse"),
                    contentPadding = PaddingValues(horizontal = Spacing.medium, vertical = Spacing.sMedium),
                )
                FormDivider()
                SwitchRow(
                    title = stringResource(R.string.account_anonymize),
                    detail = stringResource(R.string.account_anonymize_detail),
                    checked = account.anonymizesContributions,
                    onCheckedChange = viewModel::setAnonymizesContributions,
                    modifier = Modifier.testTag("e2e.account.anonymize"),
                    contentPadding = PaddingValues(horizontal = Spacing.medium, vertical = Spacing.sMedium),
                )
            }
        }
    }
}

/** The account's language, and the menu of the 29 inventaire.io writes in, named in the phone's language. */
@Composable
private fun LanguageRow(code: String?, onPick: (String) -> Unit) {
    var expanded: Boolean by rememberSaveable { mutableStateOf(false) }
    val languages: List<AccountLanguage> = remember { AccountLanguage.all() }
    Box {
        EditionPropertyRow(
            label = stringResource(R.string.account_language),
            value = code?.let { AccountLanguage.name(it) },
            placeholder = "",
            trailing = PropertyRowTrailing.Menu,
            onClick = { expanded = true },
            modifier = Modifier.testTag("e2e.account.language"),
        )
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            containerColor = RecitTheme.colors.backgroundRaised,
        ) {
            languages.forEach { language: AccountLanguage ->
                DropdownMenuItem(
                    text = { Text(text = language.name, style = RecitTheme.typography.content300) },
                    trailingIcon = {
                        if (language.code == code) Icon(Icons.Default.Check, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
                    },
                    onClick = {
                        expanded = false
                        onPick(language.code)
                    },
                )
            }
        }
    }
}

/** The password is never read back: ten dots say there is one, as on iOS. */
private const val PASSWORD_MASK: String = "••••••••••"
