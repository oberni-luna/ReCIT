package studio.lunabee.nouveaurecit.ui.profile.edit

import android.annotation.SuppressLint
import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Place
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.compose.LocalLifecycleOwner
import org.osmdroid.events.MapListener
import org.osmdroid.events.ScrollEvent
import org.osmdroid.events.ZoomEvent
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.CustomZoomButtonsController
import org.osmdroid.views.MapView
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.user.Coordinates
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * The map of « Position » (iOS feature 0055), drawn by osmdroid from OpenStreetMap's tiles — no key, no
 * Google services, so it shows on every phone. The pin stays at the centre and the map moves under it;
 * [onCenterChange] hears where the centre went. [target] and [zoom] move the map whenever they change —
 * a place found by the search.
 *
 * Still when not [interactive]: the form's preview of the position, which only shows where it is.
 */
@Composable
fun PositionMap(
    target: Coordinates,
    zoom: Double,
    interactive: Boolean,
    modifier: Modifier = Modifier,
    onCenterChange: (Coordinates) -> Unit = {},
) {
    val context: Context = LocalContext.current
    val mapView: MapView = remember { newMapView(context, interactive) }
    val lifecycleOwner: LifecycleOwner = LocalLifecycleOwner.current
    val currentOnCenterChange: (Coordinates) -> Unit by rememberUpdatedState(onCenterChange)
    val description: String = stringResource(R.string.profile_position_map)

    DisposableEffect(lifecycleOwner, mapView) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> mapView.onResume()
                Lifecycle.Event.ON_PAUSE -> mapView.onPause()
                else -> Unit
            }
        }
        val listener: MapListener = object : MapListener {
            override fun onScroll(event: ScrollEvent?): Boolean = reportCenter()

            override fun onZoom(event: ZoomEvent?): Boolean = reportCenter()

            private fun reportCenter(): Boolean {
                currentOnCenterChange(Coordinates(mapView.mapCenter.latitude, mapView.mapCenter.longitude))
                return false
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        mapView.addMapListener(listener)
        onDispose {
            mapView.removeMapListener(listener)
            lifecycleOwner.lifecycle.removeObserver(observer)
            mapView.onDetach()
        }
    }

    LaunchedEffect(mapView, target, zoom) {
        mapView.controller.setZoom(zoom)
        mapView.controller.setCenter(GeoPoint(target.latitude, target.longitude))
    }

    Box(modifier.semantics { contentDescription = description }) {
        AndroidView(factory = { mapView }, modifier = Modifier.fillMaxSize())
        Icon(
            imageVector = Icons.Filled.Place,
            contentDescription = null,
            tint = RecitTheme.colors.backgroundTintedInverse,
            // The pin's point, not its middle, is the centre of the map.
            modifier = Modifier.align(Alignment.Center).size(PinSize).offset(y = -PinSize / 2),
        )
        Text(
            text = stringResource(R.string.profile_position_attribution),
            style = RecitTheme.typography.caption200,
            color = RecitTheme.colors.foregroundSecondary,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(Spacing.xSmall)
                .clip(RoundedCornerShape(CornerRadius.minimal))
                .background(RecitTheme.colors.backgroundDefault.copy(alpha = ATTRIBUTION_BACKGROUND_ALPHA))
                .padding(horizontal = Spacing.xSmall),
        )
    }
}

/** A map on OpenStreetMap's standard tiles, without zoom buttons; a still one swallows every touch. */
@SuppressLint("ClickableViewAccessibility")
private fun newMapView(context: Context, interactive: Boolean): MapView {
    OsmConfiguration.apply(context)
    return MapView(context).apply {
        setTileSource(TileSourceFactory.MAPNIK)
        setMultiTouchControls(interactive)
        zoomController.setVisibility(CustomZoomButtonsController.Visibility.NEVER)
        isTilesScaledToDpi = true
        if (!interactive) setOnTouchListener { _, _ -> true }
    }
}

private val PinSize: Dp = 40.dp

/** Enough for the line to read over any tile, not so much that it hides the map. */
private const val ATTRIBUTION_BACKGROUND_ALPHA: Float = 0.8f
