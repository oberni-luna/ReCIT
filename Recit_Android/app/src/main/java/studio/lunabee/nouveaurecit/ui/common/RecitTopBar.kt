package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.layout.RowScope
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme

/**
 * `.navigationTitle` + `.navigationBarTitleDisplayMode`:
 * - [RecitLargeTopBar] is `.large` — a tab root's title, collapsing as the content scrolls
 *   (pass [scrollBehavior] and `Modifier.nestedScroll(scrollBehavior.nestedScrollConnection)`);
 * - [RecitTopBar] is `.inline` — a pushed screen, centred, with the `Back` chevron.
 *
 * `actions` is the toolbar: `.primaryAction` / `.confirmationAction` items go there.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecitLargeTopBar(
    title: String,
    scrollBehavior: TopAppBarScrollBehavior,
    onBack: (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {},
) {
    LargeTopAppBar(
        title = {
            Text(text = title, maxLines = 1, overflow = TextOverflow.Ellipsis)
        },
        navigationIcon = { if (onBack != null) BackButton(onBack) },
        actions = actions,
        scrollBehavior = scrollBehavior,
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = RecitTheme.colors.backgroundSecondary,
            scrolledContainerColor = RecitTheme.colors.backgroundSecondary,
            titleContentColor = RecitTheme.colors.foregroundDefault,
            actionIconContentColor = RecitTheme.colors.foregroundTinted,
            navigationIconContentColor = RecitTheme.colors.foregroundDefault,
        ),
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecitTopBar(
    title: String,
    onBack: (() -> Unit)?,
    actions: @Composable RowScope.() -> Unit = {},
    scrollBehavior: TopAppBarScrollBehavior? = null,
) {
    CenterAlignedTopAppBar(
        title = {
            Text(text = title, style = RecitTheme.typography.title50, maxLines = 1, overflow = TextOverflow.Ellipsis)
        },
        navigationIcon = { if (onBack != null) BackButton(onBack) },
        actions = actions,
        scrollBehavior = scrollBehavior,
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = RecitTheme.colors.backgroundSecondary,
            scrolledContainerColor = RecitTheme.colors.backgroundSecondary,
            titleContentColor = RecitTheme.colors.foregroundDefault,
            actionIconContentColor = RecitTheme.colors.foregroundTinted,
            navigationIconContentColor = RecitTheme.colors.foregroundDefault,
        ),
    )
}

@Composable
fun BackButton(onBack: () -> Unit) {
    IconButton(onClick = onBack) {
        Icon(painter = painterResource(R.drawable.ic_back), contentDescription = stringResource(R.string.action_back))
    }
}
