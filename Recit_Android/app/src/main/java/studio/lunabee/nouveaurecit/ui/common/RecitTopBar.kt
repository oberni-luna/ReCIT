package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.layout.RowScope
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarColors
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme

/**
 * `.navigationTitle` + `.navigationBarTitleDisplayMode`:
 * - [RecitLargeTopBar] is `.large` — a tab root's title, collapsing as the content scrolls
 *   (pass [scrollBehavior] and `Modifier.nestedScroll(scrollBehavior.nestedScrollConnection)`; with
 *   a pull-to-refresh, [LargeTitleRefreshBox] hooks the connection instead, inside the refresh);
 * - [RecitTopBar] is `.inline` — a pushed screen, centred, with the `Back` chevron.
 *
 * `actions` is the toolbar: `.primaryAction` / `.confirmationAction` items go there;
 * `navigationIcon` is `.topBarLeading`, shown when there is no back button — on a pushed screen it
 * stands in for the chevron where there is another way out, a flow's close cross.
 *
 * Both bars wear the screen's own background, so a screen is one surface; the bar only takes the
 * secondary tone once content scrolls under it. [containerColor] and [contentColor] let a screen
 * that paints under its bar (the book header, the green account screens) make it transparent.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecitLargeTopBar(
    title: String,
    scrollBehavior: TopAppBarScrollBehavior,
    onBack: (() -> Unit)? = null,
    navigationIcon: @Composable () -> Unit = {},
    containerColor: Color = RecitTheme.colors.backgroundDefault,
    actions: @Composable RowScope.() -> Unit = {},
) {
    LargeTopAppBar(
        title = {
            Text(text = title, maxLines = 1, overflow = TextOverflow.Ellipsis)
        },
        navigationIcon = { if (onBack != null) BackButton(onBack) else navigationIcon() },
        actions = actions,
        scrollBehavior = scrollBehavior,
        colors = recitTopBarColors(containerColor, RecitTheme.colors.foregroundDefault),
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecitTopBar(
    title: String,
    onBack: (() -> Unit)?,
    actions: @Composable RowScope.() -> Unit = {},
    navigationIcon: @Composable () -> Unit = {},
    scrollBehavior: TopAppBarScrollBehavior? = null,
    containerColor: Color = RecitTheme.colors.backgroundDefault,
    contentColor: Color = RecitTheme.colors.foregroundDefault,
) {
    CenterAlignedTopAppBar(
        title = {
            Text(text = title, style = RecitTheme.typography.title50, maxLines = 1, overflow = TextOverflow.Ellipsis)
        },
        navigationIcon = { if (onBack != null) BackButton(onBack) else navigationIcon() },
        actions = actions,
        scrollBehavior = scrollBehavior,
        colors = recitTopBarColors(containerColor, contentColor),
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun recitTopBarColors(containerColor: Color, contentColor: Color): TopAppBarColors = TopAppBarDefaults.topAppBarColors(
    containerColor = containerColor,
    scrolledContainerColor = if (containerColor == Color.Transparent) containerColor else RecitTheme.colors.backgroundSecondary,
    titleContentColor = contentColor,
    actionIconContentColor = if (contentColor == RecitTheme.colors.foregroundDefault) RecitTheme.colors.foregroundTinted else contentColor,
    navigationIconContentColor = contentColor,
)

@Composable
fun BackButton(onBack: () -> Unit) {
    IconButton(onClick = onBack) {
        Icon(painter = painterResource(R.drawable.ic_back), contentDescription = stringResource(R.string.action_back))
    }
}
