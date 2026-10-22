package studio.lunabee.nouveaurecit.ui.profile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.BuildConfig
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.common.RecitLargeTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.LocalTabRouter
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.navigation.TabRouter

/**
 * `ProfileView`: the account, « À propos d’inventaire.io » (feature 0034), signing out, the door to
 * deleting the account (feature 0017) under signing out, and the version. Rows run full width on
 * the sheet's raised background, as the rest of the Android app does.
 *
 * It lives in the profile sheet (feature 0038), closed by « Fermer » at the top left. Signing out
 * needs no navigation: the root swaps the tabs, sheet included, for the welcome screen as soon as the
 * session goes, and forgets the user on the way (feature 0025). The current-transactions section and
 * the debug section of iOS are not ported.
 */
@Composable
fun ProfileScreen(navigator: Navigator) {
    val viewModel: ProfileViewModel = recitViewModel { container -> ProfileViewModel(container) }
    val user: UserEntity? by viewModel.user.collectAsStateWithLifecycle()
    val itemCount: Int by viewModel.itemCount.collectAsStateWithLifecycle()
    val shelfCount: Int by viewModel.shelfCount.collectAsStateWithLifecycle()
    val listCount: Int by viewModel.listCount.collectAsStateWithLifecycle()
    val isSigningOut: Boolean by viewModel.isSigningOut.collectAsStateWithLifecycle()
    val scrollBehavior: TopAppBarScrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    val router: TabRouter = LocalTabRouter.current

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            RecitLargeTopBar(
                title = stringResource(R.string.nav_profile),
                scrollBehavior = scrollBehavior,
                navigationIcon = {
                    IconButton(onClick = router::closeProfile) {
                        Icon(Icons.Default.Close, contentDescription = stringResource(R.string.action_close))
                    }
                },
                containerColor = RecitTheme.colors.backgroundRaised,
            )
        },
        containerColor = RecitTheme.colors.backgroundRaised,
    ) { padding: PaddingValues ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(vertical = Spacing.medium),
        ) {
            user?.let { me: UserEntity ->
                item(key = "header") {
                    UserHeader(user = me, itemCount = itemCount, shelfCount = shelfCount, listCount = listCount)
                }
            }
            item(key = "about") {
                ProfileLinkRow(
                    text = stringResource(R.string.profile_about_inventaire),
                    onClick = { navigator.push(Destination.AboutInventaire) },
                )
            }
            item(key = "account-header") { SectionHeader(title = stringResource(R.string.profile_account_section)) }
            item(key = "logout") {
                ProfileActionRow(
                    text = stringResource(R.string.profile_logout),
                    onClick = viewModel::signOut,
                    enabled = !isSigningOut,
                    color = RecitTheme.colors.foregroundDefault,
                ) {
                    if (isSigningOut) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(Spacing.medium),
                            color = RecitTheme.colors.foregroundSecondary,
                            strokeWidth = 2.dp,
                        )
                    }
                }
                HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
            }
            item(key = "deleteAccount") {
                ProfileActionRow(
                    text = stringResource(R.string.profile_delete_account),
                    onClick = { navigator.push(Destination.DeleteAccount) },
                    color = RecitTheme.colors.foregroundError,
                ) {
                    DisclosureChevron()
                }
            }
            item(key = "version") {
                ProfileVersionFooter()
            }
        }
    }
}

/** `UserHeaderView`: the portrait (or initials), the username, then what the account holds. */
@Composable
private fun UserHeader(user: UserEntity, itemCount: Int, shelfCount: Int, listCount: Int) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.small),
        horizontalArrangement = Arrangement.spacedBy(Spacing.medium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CellThumbnail(url = user.avatarUrl, size = ThumbnailSize.Large, shape = ThumbnailShape.Circle, fallbackName = user.username)
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall)) {
            Text(user.username, style = RecitTheme.typography.title50, color = RecitTheme.colors.foregroundDefault)
            Text(
                text = listOf(
                    pluralStringResource(R.plurals.user_item_count, itemCount, itemCount),
                    pluralStringResource(R.plurals.profile_shelf_count, shelfCount, shelfCount),
                    pluralStringResource(R.plurals.profile_list_count, listCount, listCount),
                ).joinToString(" · "),
                style = RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundSecondary,
            )
        }
    }
}

/** An action row: red only when it destroys, as the sign-out row no longer does. */
@Composable
private fun ProfileActionRow(
    text: String,
    onClick: () -> Unit,
    color: Color,
    enabled: Boolean = true,
    trailing: @Composable () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.medium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = text,
            style = RecitTheme.typography.action300,
            color = color,
            modifier = Modifier.weight(1f),
        )
        trailing()
    }
}

/** A row that pushes a screen: its title in the default ink, and the chevron. */
@Composable
private fun ProfileLinkRow(text: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.medium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = text,
            style = RecitTheme.typography.content300,
            color = RecitTheme.colors.foregroundDefault,
            modifier = Modifier.weight(1f),
        )
        DisclosureChevron()
    }
}

@Composable
private fun DisclosureChevron() {
    Icon(
        imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
        contentDescription = null,
        tint = RecitTheme.colors.foregroundSecondary,
    )
}

/**
 * `ProfileVersionFooter`: « Ex-libris · Version 0.1.0 (1) », small, grey and centred under the last
 * row — what someone writing a bug report is asked for, and the one place the app says it.
 */
@Composable
private fun ProfileVersionFooter() {
    Text(
        text = stringResource(R.string.profile_version, BuildConfig.VERSION_NAME, BuildConfig.VERSION_CODE.toString()),
        style = RecitTheme.typography.footnote200,
        color = RecitTheme.colors.foregroundSecondary,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth().padding(top = Spacing.xLarge),
    )
}
