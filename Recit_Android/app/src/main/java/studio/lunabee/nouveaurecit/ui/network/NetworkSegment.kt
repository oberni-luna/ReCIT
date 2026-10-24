package studio.lunabee.nouveaurecit.ui.network

import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `NetworkSegment`: the parts of the Réseau tab — the readers I am close to one by one, and the
 * groups I share books with. iOS has a third, « Tout », the network as a graph, compiled in `DEBUG`
 * only; it is not ported.
 */
enum class NetworkSegment(@StringRes val title: Int) {
    Friends(R.string.network_segment_friends),
    Groups(R.string.network_segment_groups),
    ;

    companion object {
        /** The preference the last segment chosen is kept under, so the tab reopens on it. */
        const val STORAGE_KEY: String = "network.lastSegment"

        /** Nothing stored, or a value this build does not know, opens on Amis — the list the tab opened on before groups. */
        fun restored(stored: String?): NetworkSegment = entries.firstOrNull { it.name == stored } ?: Friends
    }
}

/**
 * `NetworkSegmentBand`: the segmented control in a band of its own under the large title, fixed
 * above both segments, so it stays where the finger left it when the segment changes. Its ground
 * follows the bar's, which takes the secondary tone as the title folds — [collapsedFraction].
 */
@Composable
fun NetworkSegmentBand(
    selected: NetworkSegment,
    onSelect: (NetworkSegment) -> Unit,
    collapsedFraction: Float,
    containerColor: Color = RecitTheme.colors.backgroundDefault,
) {
    SingleChoiceSegmentedButtonRow(
        modifier = Modifier
            .fillMaxWidth()
            .background(lerp(containerColor, RecitTheme.colors.backgroundSecondary, collapsedFraction))
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
    ) {
        NetworkSegment.entries.forEachIndexed { index, segment ->
            SegmentedButton(
                selected = segment == selected,
                onClick = { onSelect(segment) },
                shape = SegmentedButtonDefaults.itemShape(index = index, count = NetworkSegment.entries.size),
                colors = SegmentedButtonDefaults.colors(
                    activeContainerColor = RecitTheme.colors.backgroundTinted,
                    activeContentColor = RecitTheme.colors.foregroundTinted,
                    inactiveContainerColor = Color.Transparent,
                ),
            ) {
                Text(stringResource(segment.title), style = RecitTheme.typography.action200)
            }
        }
    }
}
