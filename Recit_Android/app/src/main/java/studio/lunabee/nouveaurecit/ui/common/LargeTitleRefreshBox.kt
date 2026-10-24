package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll

/**
 * The pull-to-refresh of a tab root under a [RecitLargeTopBar], with the bar's nested-scroll
 * connection hooked inside it, between the refresh and the list — not on the `Scaffold`.
 *
 * The order is the point. A pull down past the top of the list reaches the nearest connection
 * first: here the bar's, so the large title opens before anything else, and the refresh only gets
 * what is left once it is fully open. Going back up, the farthest connection is asked first: the
 * refresh's indicator goes away before the title folds. Hooked on the `Scaffold`, outside the
 * refresh, the refresh took every pull and a folded title never came back.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LargeTitleRefreshBox(
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
    scrollBehavior: TopAppBarScrollBehavior,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit,
) {
    PullToRefreshBox(isRefreshing = isRefreshing, onRefresh = onRefresh, modifier = modifier) {
        Box(Modifier.fillMaxSize().nestedScroll(scrollBehavior.nestedScrollConnection), content = content)
    }
}
