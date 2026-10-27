package studio.lunabee.nouveaurecit.ui.book

import android.view.View
import android.view.Window
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.AnimationSpec
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.animateOffsetAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculateCentroidSize
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.geometry.isSpecified
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.layout.times
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.toSize
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.window.DialogWindowProvider
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import coil3.compose.AsyncImage
import coil3.compose.AsyncImagePainter
import coil3.request.ImageRequest
import coil3.request.crossfade
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.network.ImageUrl
import kotlin.math.abs

/*
 * iOS `FullScreenCoverView` + `FullScreenCoverImage` (feature 0029): a book's cover alone on
 * black, fitted to the whole screen. Double-tap to fill the screen and again to fit it, pinch to
 * look closer, drag to move around a magnified cover, swipe a fitted cover down or « Fermer » to go
 * back. The arithmetic between gestures is [CoverZoom]'s.
 */

/**
 * The memory-cache key the header's cover is stored under, so that the full-screen cover can draw
 * it on its first frame while the full-size image loads.
 */
internal fun coverMemoryCacheKey(url: String): String = "entity-cover:$url"

/** How long the black behind the cover takes to come in, as on iOS. */
private const val BackdropFadeMillis: Int = 300

/** The « Fermer » button's veil, white over the black: this screen is dark whatever the theme. */
private const val CloseContainerAlpha: Float = 0.2f

@Composable
internal fun FullScreenCoverDialog(url: String, onDismiss: () -> Unit) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        ImmersiveDialogWindow()
        FullScreenCover(url = url, onClose = onDismiss)
    }
}

/**
 * The dialog's window without the platform's dim — the black fades in on its own, rather than a
 * grey veil being there from the first frame — and without the status bar, as on iOS.
 */
@Composable
private fun ImmersiveDialogWindow() {
    val view: View = LocalView.current
    val window: Window? = (view.parent as? DialogWindowProvider)?.window
    DisposableEffect(window) {
        if (window != null) {
            window.setDimAmount(0f)
            val controller: WindowInsetsControllerCompat = WindowCompat.getInsetsController(window, view)
            controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            controller.hide(WindowInsetsCompat.Type.statusBars())
        }
        onDispose { }
    }
}

@Composable
private fun FullScreenCover(url: String, onClose: () -> Unit) {
    val close: () -> Unit by rememberUpdatedState(onClose)
    // What the previous gestures left, and the gesture in flight on top of it.
    var zoom: CoverZoom by remember { mutableStateOf(CoverZoom()) }
    var pinch: Float by remember { mutableFloatStateOf(1f) }
    var pan: Offset by remember { mutableStateOf(Offset.Zero) }
    // How far a fitted cover has been swiped down, towards closing.
    var swipe: Float by remember { mutableFloatStateOf(0f) }
    var gesturing: Boolean by remember { mutableStateOf(false) }
    var screen: Size by remember { mutableStateOf(Size.Zero) }
    var intrinsic: Size by remember { mutableStateOf(Size.Unspecified) }
    var loading: Boolean by remember { mutableStateOf(true) }
    val backdrop: Animatable<Float, *> = remember { Animatable(0f) }

    LaunchedEffect(Unit) {
        backdrop.animateTo(1f, tween(BackdropFadeMillis, easing = LinearOutSlowInEasing))
    }
    LaunchedEffect(intrinsic, screen) {
        if (intrinsic.isSpecified && intrinsic.minDimension > 0f && screen.minDimension > 0f) {
            val fitted: Size = intrinsic.times(ContentScale.Fit.computeScaleFactor(intrinsic, screen))
            zoom = zoom.measure(fitted = fitted, screen = screen)
        }
    }

    // Followed at once under a finger, eased when a gesture ends or a double tap toggles.
    val shown: CoverZoom = zoom.pinching(pinch).panning(pan)
    val floatSpec: AnimationSpec<Float> = if (gesturing) snap() else spring(stiffness = Spring.StiffnessMediumLow)
    val offsetSpec: AnimationSpec<Offset> = if (gesturing) snap() else spring(stiffness = Spring.StiffnessMediumLow)
    val scale: Float by animateFloatAsState(shown.scale, floatSpec, label = "coverScale")
    val offset: Offset by animateOffsetAsState(shown.offset, offsetSpec, label = "coverOffset")
    val swiped: Float by animateFloatAsState(swipe, floatSpec, label = "coverSwipe")
    val swipeFade: Float = if (screen.height > 0f) (swiped / screen.height * 2f).coerceIn(0f, 1f) else 0f

    val context = LocalContext.current
    val request: ImageRequest = remember(url) {
        ImageRequest.Builder(context)
            .data(ImageUrl.fullScreen(url))
            .placeholderMemoryCacheKey(coverMemoryCacheKey(url))
            .size(coil3.size.Size.ORIGINAL)
            .crossfade(true)
            .build()
    }

    Box(Modifier.fillMaxSize()) {
        Box(
            Modifier
                .fillMaxSize()
                .graphicsLayer { alpha = backdrop.value * (1f - swipeFade) }
                .background(Color.Black),
        )
        Box(
            Modifier
                .fillMaxSize()
                .onSizeChanged { screen = it.toSize() }
                .pointerInput(Unit) {
                    detectTapGestures(onDoubleTap = { zoom = zoom.toggle() })
                }
                .pointerInput(Unit) {
                    awaitEachGesture {
                        awaitFirstDown(requireUnconsumed = false)
                        var pastSlop = false
                        var slopZoom = 1f
                        var slopPan: Offset = Offset.Zero
                        // A second finger makes it a pinch, never a swipe to close.
                        var pinches = false
                        do {
                            val event = awaitPointerEvent()
                            val cancelled: Boolean = event.changes.any { it.isConsumed }
                            if (!cancelled) {
                                val zoomChange: Float = event.calculateZoom()
                                val panChange: Offset = event.calculatePan()
                                if (event.changes.count { it.pressed } > 1 && !pinches) {
                                    pinches = true
                                    swipe = 0f
                                }
                                if (!pastSlop) {
                                    slopZoom *= zoomChange
                                    slopPan += panChange
                                    val zoomMotion: Float = abs(1f - slopZoom) * event.calculateCentroidSize(useCurrent = false)
                                    pastSlop = zoomMotion > viewConfiguration.touchSlop || slopPan.getDistance() > viewConfiguration.touchSlop
                                    gesturing = pastSlop
                                }
                                if (pastSlop) {
                                    if (pinches || zoom.isZoomed) {
                                        pinch *= zoomChange
                                        pan += panChange
                                    } else {
                                        swipe = (swipe + panChange.y).coerceAtLeast(0f)
                                    }
                                    event.changes.forEach { if (it.positionChanged()) it.consume() }
                                }
                            }
                        } while (!cancelled && event.changes.any { it.pressed })

                        if (pastSlop) {
                            if (pinches || zoom.isZoomed) {
                                zoom = zoom.endPinch(pinch).endPan(pan)
                            } else if (CoverZoom.closesOnRelease(swipe, screen.height)) {
                                close()
                            }
                        }
                        pinch = 1f
                        pan = Offset.Zero
                        swipe = 0f
                        gesturing = false
                    }
                },
            contentAlignment = Alignment.Center,
        ) {
            AsyncImage(
                model = request,
                contentDescription = stringResource(R.string.entity_cover),
                contentScale = ContentScale.Fit,
                onState = { state ->
                    state.painter?.intrinsicSize?.takeIf { it.isSpecified }?.let { intrinsic = it }
                    loading = state is AsyncImagePainter.State.Loading && state.painter == null
                },
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer {
                        scaleX = scale
                        scaleY = scale
                        translationX = offset.x
                        translationY = offset.y + swiped
                    },
            )
            if (loading) {
                CircularProgressIndicator(color = Color.White)
            }
        }
        Box(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing), contentAlignment = Alignment.TopEnd) {
            FilledIconButton(
                onClick = close,
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = Color.White.copy(alpha = CloseContainerAlpha),
                    contentColor = Color.White,
                ),
                modifier = Modifier.padding(Spacing.medium),
            ) {
                Icon(Icons.Default.Close, contentDescription = stringResource(R.string.action_close))
            }
        }
    }
}
