package studio.lunabee.nouveaurecit.ui.scan

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.scan.BatchScanState
import studio.lunabee.nouveaurecit.data.scan.ScannedBook
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.createbook.CreateBookScreen
import studio.lunabee.nouveaurecit.ui.createbook.CreateBookSession

/**
 * `BatchScanCameraView` (feature 0007): the live feed, and the one book rising over it that is
 * waiting to be filed. With nothing recognised, the same slot says what to aim at. The feed is gated
 * on the camera permission: the whole screen *is* the feed, so a refusal without a gate would be a
 * black screen with a floating button.
 *
 * « Terminer » — or the back gesture — ends the session: [onFinished] is told how many books it
 * added and whether the bilan is due.
 *
 * « Nouveau livre » (feature 0020) takes the feed's place while it is up: the camera is released, which
 * the cover photograph needs, and no barcode counts until the form goes.
 */
@Composable
fun ScanCameraScreen(onOpenBook: (ScannedBook) -> Unit, onFinished: (addedBookCount: Int, presentsTally: Boolean) -> Unit) {
    val viewModel: ScanViewModel = recitViewModel { ScanViewModel(it) }
    val state: BatchScanState by viewModel.state.collectAsStateWithLifecycle()
    val creation: CreateBookSession? by viewModel.creation.collectAsStateWithLifecycle()
    val cameraAccess: CameraAccessState = rememberCameraAccess()
    val haptics: HapticFeedback = LocalHapticFeedback.current
    val messenger: Messenger = LocalMessenger.current
    val scope: CoroutineScope = rememberCoroutineScope()
    val genericError: String = stringResource(R.string.error_generic)

    LaunchedEffect(viewModel) {
        viewModel.feedback.collect { feedback ->
            when (feedback) {
                ScanFeedback.Accepted -> haptics.performHapticFeedback(HapticFeedbackType.SegmentTick)
                ScanFeedback.Added -> haptics.performHapticFeedback(HapticFeedbackType.Confirm)
                ScanFeedback.Warning, ScanFeedback.Failed -> haptics.performHapticFeedback(HapticFeedbackType.Reject)
                is ScanFeedback.AddFailed -> {
                    haptics.performHapticFeedback(HapticFeedbackType.Reject)
                    messenger.showError(genericError, feedback.error.localizedMessage)
                }
            }
        }
    }

    val finish: () -> Unit = {
        scope.launch {
            viewModel.cancelPending()
            onFinished(viewModel.addedBookCount, viewModel.presentsTally())
        }
    }
    BackHandler(onBack = finish)

    creation?.let { session ->
        CreateBookScreen(session = session, onClose = viewModel::closeCreation)
        return
    }

    Box(Modifier.fillMaxSize().background(ScanOverlayPalette.Ground)) {
        when (cameraAccess.access) {
            CameraAccess.Granted -> {
                BarcodeCameraPreview(onCode = viewModel::codeSeen, modifier = Modifier.fillMaxSize())
                ResultSlot(
                    state = state,
                    onOpen = onOpenBook,
                    onAdd = viewModel::addPendingBook,
                    onCreate = viewModel::openCreation,
                    modifier = Modifier.align(Alignment.BottomCenter),
                )
            }
            CameraAccess.Denied, CameraAccess.DeniedForGood -> ScannerPermissionContent(
                access = cameraAccess.access,
                onAllow = cameraAccess::request,
            )
            CameraAccess.Unknown -> Unit
        }
        TextButton(
            onClick = finish,
            modifier = Modifier.align(Alignment.TopEnd).statusBarsPadding().padding(end = Spacing.small),
        ) {
            Text(stringResource(R.string.scan_finish), style = RecitTheme.typography.action300, color = ScanOverlayPalette.Tint)
        }
    }
}

/**
 * One slot at the foot of the feed, and two things that can occupy it: the book recognised, or the
 * hint. The scrim belongs to the slot, so a book arriving swaps one block for another instead of
 * fading a veil in behind it.
 */
@Composable
private fun ResultSlot(
    state: BatchScanState,
    onOpen: (ScannedBook) -> Unit,
    onAdd: () -> Unit,
    onCreate: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(ScanOverlayPalette.Scrim)
            .padding(top = Spacing.xxLarge)
            .navigationBarsPadding()
            .padding(bottom = Spacing.medium),
    ) {
        AnimatedContent(
            targetState = state,
            contentKey = { it.showsRow },
            transitionSpec = { (slideInVertically { it / 2 } + fadeIn()) togetherWith fadeOut() },
            label = "scan.slot",
        ) { target ->
            if (target.showsRow) {
                ScanResultRow(state = target, onOpen = onOpen, onAdd = onAdd, onCreate = onCreate)
            } else {
                ScanHint()
            }
        }
    }
}
