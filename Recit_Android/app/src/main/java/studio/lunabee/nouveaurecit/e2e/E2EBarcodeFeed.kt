package studio.lunabee.nouveaurecit.e2e

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import kotlinx.coroutines.delay

/**
 * What the scanner shows in place of the camera under the scenario: a black feed, and
 * [E2EHooks.barcodes] « held in front of it » one at a time. A tap on the feed brings the next book;
 * like a real barcode, it is then reported again and again until the next tap. The scenario decides
 * when — after it has read the row the last one brought up, which a three-second notice would
 * otherwise take away from under it on a slow emulator.
 */
@Composable
fun E2EBarcodeFeed(onCode: (String) -> Unit, modifier: Modifier = Modifier) {
    // -1: nothing in front of the camera yet.
    var index: Int by rememberSaveable { mutableIntStateOf(-1) }
    val currentOnCode: (String) -> Unit by rememberUpdatedState(onCode)
    val current: String? = E2EHooks.barcodes.getOrNull(index)

    LaunchedEffect(current) {
        current ?: return@LaunchedEffect
        while (true) {
            currentOnCode(current)
            delay(FRAME_INTERVAL_MILLIS)
        }
    }
    Box(
        modifier
            .background(Color.Black)
            .clickable { index += 1 }
            .testTag("e2e.scan.feed"),
    )
}

private const val FRAME_INTERVAL_MILLIS: Long = 700
