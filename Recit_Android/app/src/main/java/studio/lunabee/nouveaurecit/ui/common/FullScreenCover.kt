package studio.lunabee.nouveaurecit.ui.common

import android.os.Build
import android.view.View
import android.view.Window
import android.view.WindowManager
import androidx.annotation.RequiresApi
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
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.geometry.isSpecified
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.layout.times
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
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
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.network.ImageUrl
import java.util.function.Consumer
import kotlin.math.abs
import kotlin.math.roundToInt

/*
 * iOS `FullScreenCoverView` + `FullScreenCoverImage` (features 0029, 0081 and 0085), the Plein écran: a
 * book's cover, or a reader's, a group's or an author's photo, alone over the screen it opened from and
 * fitted to the whole of it. That screen shows through blurred under the theme's veil, or is hidden by
 * the veil made opaque when there is no blur to be had ([FullScreenBackdrop]). Double-tap to fill the
 * screen and again to fit it, pinch to look closer, drag to move around a magnified picture, swipe a
 * fitted one down or « Fermer » to go back. The arithmetic between gestures is [CoverZoom]'s.
 */

/**
 * The memory-cache key the picture a Plein écran opens from is stored under, so that the Plein écran can
 * draw it on its first frame while the full-size image loads.
 */
internal fun fullScreenMemoryCacheKey(url: String): String = "full-screen:$url"

/** How long the veil behind the picture takes to come in, as on iOS. */
private const val BackdropFadeMillis: Int = 300

/** How far the window behind is blurred once the veil is in: about iOS's Regular material. */
private val BackdropBlurRadius: Dp = 30.dp

/** The Plein écran of [url], which TalkBack reads as [contentDescription] — « Couverture », « Photo ». */
@Composable
internal fun FullScreenCoverDialog(url: String, contentDescription: String, onDismiss: () -> Unit) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        val view: View = LocalView.current
        val window: Window? = (view.parent as? DialogWindowProvider)?.window
        val blurRadius: Int = with(LocalDensity.current) { BackdropBlurRadius.roundToPx() }
        val backdrop: FullScreenBackdrop = rememberFullScreenBackdrop(window)
        ImmersiveDialogWindow(window = window, view = view, isDark = RecitTheme.colors.isDark)
        FullScreenCover(
            url = url,
            contentDescription = contentDescription,
            backdrop = backdrop,
            onBackdropLevel = { level ->
                if (window != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    window.blurBehind(if (backdrop == FullScreenBackdrop.Blurred) (blurRadius * level).roundToInt() else 0)
                }
            },
            onClose = onDismiss,
        )
    }
}

/**
 * The dialog's window without the platform's dim — the veil fades in on its own, rather than a grey one
 * being there from the first frame — and without the status bar, as on iOS. The navigation bar's buttons
 * follow the theme, the veil being light or dark with it.
 */
@Composable
private fun ImmersiveDialogWindow(window: Window?, view: View, isDark: Boolean) {
    DisposableEffect(window, isDark) {
        if (window != null) {
            window.setDimAmount(0f)
            val controller: WindowInsetsControllerCompat = WindowCompat.getInsetsController(window, view)
            controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            controller.hide(WindowInsetsCompat.Type.statusBars())
            controller.isAppearanceLightNavigationBars = !isDark
        }
        onDispose { }
    }
}

/** Blurred while the system allows cross-window blur, which it may stop and resume while the Plein écran is open. */
@Composable
private fun rememberFullScreenBackdrop(window: Window?): FullScreenBackdrop =
    if (window != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        rememberCrossWindowBlur(window.windowManager)
    } else {
        FullScreenBackdrop.Opaque
    }

@RequiresApi(Build.VERSION_CODES.S)
@Composable
private fun rememberCrossWindowBlur(windowManager: WindowManager): FullScreenBackdrop {
    var isEnabled: Boolean by remember(windowManager) { mutableStateOf(windowManager.isCrossWindowBlurEnabled) }
    DisposableEffect(windowManager) {
        val listener: Consumer<Boolean> = Consumer { isEnabled = it }
        windowManager.addCrossWindowBlurEnabledListener(listener)
        onDispose { windowManager.removeCrossWindowBlurEnabledListener(listener) }
    }
    return FullScreenBackdrop.of(Build.VERSION.SDK_INT, isEnabled)
}

/** Blurs whatever lies behind the window by [radius] pixels, or stops blurring it at 0. */
@RequiresApi(Build.VERSION_CODES.S)
private fun Window.blurBehind(radius: Int) {
    if (attributes.blurBehindRadius == radius) return
    if (radius > 0) {
        addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND)
    } else {
        clearFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND)
    }
    attributes = attributes.apply { blurBehindRadius = radius }
}

/**
 * The picture over the veil. [onBackdropLevel] is told how far in the veil is, from 0 to 1, each time
 * that changes — fading in, then out with a swipe down —, for the blur behind to follow it.
 */
@Composable
private fun FullScreenCover(
    url: String,
    contentDescription: String,
    backdrop: FullScreenBackdrop,
    onBackdropLevel: (Float) -> Unit,
    onClose: () -> Unit,
) {
    val close: () -> Unit by rememberUpdatedState(onClose)
    val blurBehind: (Float) -> Unit by rememberUpdatedState(onBackdropLevel)
    // What the previous gestures left, and the gesture in flight on top of it.
    var zoom: CoverZoom by remember { mutableStateOf(CoverZoom()) }
    var pinch: Float by remember { mutableFloatStateOf(1f) }
    var pan: Offset by remember { mutableStateOf(Offset.Zero) }
    // How far a fitted picture has been swiped down, towards closing.
    var swipe: Float by remember { mutableFloatStateOf(0f) }
    var gesturing: Boolean by remember { mutableStateOf(false) }
    var screen: Size by remember { mutableStateOf(Size.Zero) }
    var intrinsic: Size by remember { mutableStateOf(Size.Unspecified) }
    var loading: Boolean by remember { mutableStateOf(true) }
    val fade: Animatable<Float, *> = remember { Animatable(0f) }

    LaunchedEffect(Unit) {
        fade.animateTo(1f, tween(BackdropFadeMillis, easing = LinearOutSlowInEasing))
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
    // Read where it is drawn, and by the blur behind, so the fade and the swipe redraw and recompose nothing.
    val backdropLevel: () -> Float = {
        val swipeFade: Float = if (screen.height > 0f) (swiped / screen.height * 2f).coerceIn(0f, 1f) else 0f
        fade.value * (1f - swipeFade)
    }

    LaunchedEffect(backdrop) {
        snapshotFlow(backdropLevel).collect { blurBehind(it) }
    }

    val context = LocalContext.current
    val request: ImageRequest = remember(url) {
        ImageRequest.Builder(context)
            .data(ImageUrl.fullScreen(url))
            .placeholderMemoryCacheKey(fullScreenMemoryCacheKey(url))
            .size(coil3.size.Size.ORIGINAL)
            .crossfade(true)
            .build()
    }

    Box(Modifier.fillMaxSize()) {
        Box(
            Modifier
                .fillMaxSize()
                .graphicsLayer { alpha = backdropLevel() }
                .background(backdrop.veil(RecitTheme.colors)),
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
                contentDescription = contentDescription,
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
                CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary)
            }
        }
        Box(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing), contentAlignment = Alignment.TopEnd) {
            // Light on the light veil, dark on the dark one: legible over either, and over the picture.
            FilledIconButton(
                onClick = close,
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = RecitTheme.colors.backgroundSecondary,
                    contentColor = RecitTheme.colors.foregroundDefault,
                ),
                modifier = Modifier.padding(Spacing.medium),
            ) {
                Icon(Icons.Default.Close, contentDescription = stringResource(R.string.action_close))
            }
        }
    }
}
