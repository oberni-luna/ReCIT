package studio.lunabee.nouveaurecit.ui.lists

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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.CoroutineScope
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.lists.ListAdditionPlan
import studio.lunabee.nouveaurecit.data.scan.BatchScanState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.scan.BarcodeCameraPreview
import studio.lunabee.nouveaurecit.ui.scan.CameraAccess
import studio.lunabee.nouveaurecit.ui.scan.CameraAccessState
import studio.lunabee.nouveaurecit.ui.scan.ScanHint
import studio.lunabee.nouveaurecit.ui.scan.ScanOverlayPalette
import studio.lunabee.nouveaurecit.ui.scan.ScanResultRow
import studio.lunabee.nouveaurecit.ui.scan.ScannerPermissionContent
import studio.lunabee.nouveaurecit.ui.scan.rememberCameraAccess

/**
 * `ListScanView` (iOS feature 0060): « Scanner » over a list — the camera full screen, the recognised book
 * rising with its cover and the batch scanner's round « + », which adds the edition's work to the list
 * and closes. A collection asks which of its works, « Toutes les œuvres » last. A book the list already
 * holds raises « Ce livre est déjà dans « … » » — « Le voir » lands on it, « Continuer » scans another.
 * An unknown edition, or one without a work, is said on the row and nothing more: no « Nouveau livre »
 * from here, it would file the book into the inventory as well.
 */
@Composable
internal fun ListScanScreen(
    listName: String,
    existingUris: Set<String>,
    onAdd: (List<String>) -> Unit,
    onShow: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        val container: AppContainer = LocalAppContainer.current
        val scope: CoroutineScope = rememberCoroutineScope()
        val session: ListScanSession = remember { ListScanSession(container, scope) }
        val state: BatchScanState by session.state.collectAsStateWithLifecycle()
        val cameraAccess: CameraAccessState = rememberCameraAccess()
        val haptics: HapticFeedback = LocalHapticFeedback.current
        var choice: List<ListWorkOption>? by remember { mutableStateOf(null) }
        var duplicate: String? by remember { mutableStateOf(null) }

        fun finish(uris: List<String>) {
            when (val plan: ListAdditionPlan = ListAdditionPlan.plan(uris, existingUris)) {
                is ListAdditionPlan.Add -> {
                    haptics.performHapticFeedback(HapticFeedbackType.Confirm)
                    onAdd(plan.uris)
                    onDismiss()
                }
                is ListAdditionPlan.AlreadyInList -> {
                    haptics.performHapticFeedback(HapticFeedbackType.Reject)
                    duplicate = plan.uri
                }
                ListAdditionPlan.Nothing -> Unit
            }
        }

        Box(Modifier.fillMaxSize().background(ScanOverlayPalette.Ground)) {
            when (cameraAccess.access) {
                CameraAccess.Granted -> {
                    BarcodeCameraPreview(
                        onCode = { code -> if (session.codeSeen(code)) haptics.performHapticFeedback(HapticFeedbackType.SegmentTick) },
                        modifier = Modifier.fillMaxSize(),
                    )
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
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
                            label = "list.scan.slot",
                        ) { target ->
                            if (target.showsRow) {
                                ScanResultRow(
                                    state = target,
                                    onOpen = {},
                                    onAdd = {
                                        val works: List<ListWorkOption> = session.works
                                        if (works.size > 1) choice = works else finish(works.map { it.uri })
                                    },
                                    onCreate = null,
                                    addLabel = stringResource(R.string.list_add_action),
                                )
                            } else {
                                ScanHint()
                            }
                        }
                    }
                }
                CameraAccess.Denied, CameraAccess.DeniedForGood -> ScannerPermissionContent(
                    access = cameraAccess.access,
                    onAllow = cameraAccess::request,
                )
                CameraAccess.Unknown -> Unit
            }
            TextButton(
                onClick = onDismiss,
                modifier = Modifier.align(Alignment.TopEnd).statusBarsPadding().padding(end = Spacing.small),
            ) {
                Text(stringResource(R.string.action_close), style = RecitTheme.typography.action300, color = ScanOverlayPalette.Tint)
            }
        }

        choice?.let { works ->
            ListWorkChoiceDialog(
                listName = listName,
                works = works,
                onChoose = { uris ->
                    choice = null
                    finish(uris)
                },
                onDismiss = { choice = null },
            )
        }

        duplicate?.let { uri ->
            AlertDialog(
                onDismissRequest = {
                    duplicate = null
                    session.clear()
                },
                title = { Text(stringResource(R.string.list_add_duplicate_title, listName)) },
                text = { Text(stringResource(R.string.list_add_duplicate_message)) },
                confirmButton = {
                    TextButton(
                        onClick = {
                            duplicate = null
                            onShow(uri)
                            onDismiss()
                        },
                    ) { Text(stringResource(R.string.list_add_duplicate_show)) }
                },
                dismissButton = {
                    TextButton(
                        onClick = {
                            duplicate = null
                            session.clear()
                        },
                    ) { Text(stringResource(R.string.list_add_duplicate_continue)) }
                },
                containerColor = RecitTheme.colors.backgroundRaised,
            )
        }
    }
}
