package studio.lunabee.nouveaurecit.ui.profile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.common.RecitLargeTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `ProfileView`: the account, « À propos d’inventaire.io » (feature 0034), signing out, the door to
 * deleting the account (feature 0017) in its own card away from signing out, and the version.
 *
 * Signing out needs no navigation: the root swaps the tabs for the welcome screen as soon as the
 * session goes, and forgets the user on the way (feature 0025). The current-transactions section and
 * the debug section of iOS are not ported.
 */
@Composable
fun ProfileScreen(navigator: Navigator) {
    val viewModel: ProfileViewModel = recitViewModel { container -> ProfileViewModel(container) }
    val user: UserEntity? by viewModel.user.collectAsStateWithLifecycle()
    val itemCount: Int by viewModel.itemCount.collectAsStateWithLifecycle()
    val isSigningOut: Boolean by viewModel.isSigningOut.collectAsStateWithLifecycle()
    val scrollBehavior: TopAppBarScrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = { RecitLargeTopBar(title = stringResource(R.string.nav_profile), scrollBehavior = scrollBehavior) },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding: PaddingValues ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(horizontal = Spacing.medium, vertical = Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.large),
        ) {
            user?.let { me: UserEntity ->
                item(key = "header") {
                    ProfileCard { UserHeader(user = me, itemCount = itemCount) }
                }
            }
            item(key = "about") {
                ProfileCard {
                    ProfileLinkRow(
                        text = stringResource(R.string.profile_about_inventaire),
                        onClick = { navigator.push(Destination.AboutInventaire) },
                    )
                }
            }
            item(key = "logout") {
                ProfileCard {
                    ProfileActionRow(
                        text = stringResource(R.string.profile_logout),
                        onClick = viewModel::signOut,
                        enabled = !isSigningOut,
                    ) {
                        if (isSigningOut) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(Spacing.medium),
                                color = RecitTheme.colors.foregroundError,
                                strokeWidth = 2.dp,
                            )
                        }
                    }
                }
            }
            item(key = "deleteAccount") {
                ProfileCard {
                    ProfileActionRow(
                        text = stringResource(R.string.profile_delete_account),
                        onClick = { navigator.push(Destination.DeleteAccount) },
                    ) {
                        DisclosureChevron()
                    }
                }
            }
            item(key = "version") {
                ProfileVersionFooter()
            }
        }
    }
}

/** One inset-grouped `Section`: a rounded card on the list background. */
@Composable
private fun ProfileCard(content: @Composable ColumnScope.() -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(CornerRadius.rounded),
        color = RecitTheme.colors.backgroundDefault,
    ) {
        Column(content = content)
    }
}

/** `UserHeaderView`: the avatar when there is one, the username, the count of my books. */
@Composable
private fun UserHeader(user: UserEntity, itemCount: Int) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        if (user.avatarUrl != null) {
            CellThumbnail(url = user.avatarUrl, size = ThumbnailSize.Large, shape = ThumbnailShape.Circle)
        }
        Text(user.username, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
        Text(
            text = pluralStringResource(R.plurals.user_item_count, itemCount, itemCount),
            style = RecitTheme.typography.content300,
            color = RecitTheme.colors.foregroundDefault,
        )
    }
}

/** A red action300 row, as the sign-out and delete-account rows read on iOS. */
@Composable
private fun ProfileActionRow(
    text: String,
    onClick: () -> Unit,
    enabled: Boolean = true,
    trailing: @Composable () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = text,
            style = RecitTheme.typography.action300,
            color = RecitTheme.colors.foregroundError,
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
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
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
 * card — what someone writing a bug report is asked for, and the one place the app says it.
 */
@Composable
private fun ProfileVersionFooter() {
    Text(
        text = stringResource(R.string.profile_version, BuildConfig.VERSION_NAME, BuildConfig.VERSION_CODE.toString()),
        style = RecitTheme.typography.footnote200,
        color = RecitTheme.colors.foregroundSecondary,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth(),
    )
}
