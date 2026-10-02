package studio.lunabee.nouveaurecit.ui.profile

import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.material.icons.automirrored.outlined.LibraryBooks
import androidx.compose.material.icons.outlined.Cancel
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.UriHandler
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.ShelfPalette
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.designsystem.shelfPaper
import studio.lunabee.nouveaurecit.ui.common.RecitLargeTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `ProfileView`: the account, the inventaire.io notice (feature 0026), signing out, and the door to
 * deleting the account (feature 0017), in its own card away from signing out.
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
    val isNoticeDismissed: Boolean? by viewModel.isNoticeDismissed.collectAsStateWithLifecycle()
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
            item(key = "notice") {
                AnimatedVisibility(visible = isNoticeDismissed == false) {
                    InventaireNoticeTag(
                        onDismiss = viewModel::dismissNotice,
                        modifier = Modifier.padding(horizontal = Spacing.small),
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
                        Icon(
                            imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                            contentDescription = null,
                            tint = RecitTheme.colors.foregroundSecondary,
                        )
                    }
                }
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

/**
 * `InventaireNoticeTag`: the paper tag saying the app is inventaire.io underneath. Inked with
 * `ShelfPalette` — the paper stays white in dark mode, where the tinted tokens would vanish on it.
 */
@Composable
private fun InventaireNoticeTag(onDismiss: () -> Unit, modifier: Modifier = Modifier) {
    val title: String = stringResource(R.string.profile_inventaire_title)
    val uriHandler: UriHandler = LocalUriHandler.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shelfPaper(seed = title)
            .padding(start = Spacing.medium, end = Spacing.xSmall, top = Spacing.xSmall, bottom = Spacing.sMedium),
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.small)) {
            Icon(
                imageVector = Icons.AutoMirrored.Outlined.LibraryBooks,
                contentDescription = null,
                tint = ShelfPalette.LabelInk,
            )
            Text(
                text = title,
                style = RecitTheme.typography.content400Bold,
                color = ShelfPalette.LabelInk,
                modifier = Modifier.weight(1f).semantics { heading() },
            )
            IconButton(onClick = onDismiss) {
                Icon(
                    imageVector = Icons.Outlined.Cancel,
                    contentDescription = stringResource(R.string.profile_inventaire_dismiss),
                    tint = ShelfPalette.LabelInk,
                )
            }
        }
        NoticeParagraph(stringResource(R.string.profile_inventaire_commons))
        NoticeLink(stringResource(R.string.profile_inventaire_commons_link)) { uriHandler.openUri(INVENTAIRE_URL) }
        NoticeParagraph(stringResource(R.string.profile_inventaire_data))
        NoticeLink(stringResource(R.string.profile_inventaire_data_link)) { uriHandler.openUri(DATA_URL) }
    }
}

@Composable
private fun NoticeParagraph(source: String) {
    val text: AnnotatedString = remember(source) { boldAnnotated(source) }
    Text(text = text, style = RecitTheme.typography.content300, color = ShelfPalette.LabelInk)
}

/** `InventaireNoticeLink`: underlined, in the paper's own green; only the words answer a tap. */
@Composable
private fun NoticeLink(text: String, onClick: () -> Unit) {
    Text(
        text = text,
        style = RecitTheme.typography.action300.copy(textDecoration = TextDecoration.Underline),
        color = ShelfPalette.LabelLink,
        modifier = Modifier.clickable(onClick = onClick),
    )
}

private fun boldAnnotated(source: String): AnnotatedString = buildAnnotatedString {
    BoldMarkup.parse(source).forEach { run: BoldMarkup.Run ->
        if (run.isBold) withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(run.text) } else append(run.text)
    }
}

private const val INVENTAIRE_URL: String = "https://inventaire.io"
private const val DATA_URL: String = "https://data.inventaire.io"
