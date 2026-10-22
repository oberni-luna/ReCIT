package studio.lunabee.nouveaurecit.ui.sort

import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.toSize
import studio.lunabee.nouveaurecit.data.sorting.SortBook
import studio.lunabee.nouveaurecit.data.sorting.SortSectionId

/** Where a book can be let go: a section of the projection, or the « + Nouvelle étagère » tile. */
sealed interface SortDropKey {
    data class Section(val id: SortSectionId) : SortDropKey

    data object NewShelf : SortDropKey
}

/**
 * The drag of feature 0010, by hand: a long press on a cover lifts the book, the finger carries a
 * copy of the cover over everything, and letting go files it into the target underneath
 * ([SortDropZones.hit]). The origin does not travel with the book — the projection is the only thing
 * that knows where it sits.
 *
 * Positions are in root coordinates, so sources and targets anywhere on the surface agree.
 */
@Stable
class SortDragState {
    var dragged: SortBook? by mutableStateOf(null)
        private set

    /** The finger, in root coordinates. */
    var pointer: Offset by mutableStateOf(Offset.Zero)
        private set

    /** The lifted cover's size, as it was drawn where it was picked up. */
    var coverSize: Size by mutableStateOf(Size.Zero)
        private set

    /** Where on the cover the finger took it, so the cover does not jump under the finger. */
    var grabOffset: Offset by mutableStateOf(Offset.Zero)
        private set

    private val zones = mutableStateMapOf<SortDropKey, SortDropZone<SortDropKey>>()

    /** The target under the finger while a book is carried. */
    val hovered: SortDropKey?
        get() = if (dragged == null) null else SortDropZones.hit(zones.values, pointer)

    fun register(key: SortDropKey, coordinates: LayoutCoordinates, layer: Int) {
        zones[key] = SortDropZone(key, if (coordinates.isAttached) coordinates.boundsInRoot() else Rect.Zero, layer)
    }

    fun unregister(key: SortDropKey) {
        zones.remove(key)
    }

    internal fun start(book: SortBook, at: Offset, size: Size, grab: Offset) {
        dragged = book
        pointer = at
        coverSize = size
        grabOffset = grab
    }

    internal fun move(by: Offset) {
        pointer += by
    }

    /** The target the book was let go over, if any; the drag is over either way. */
    internal fun end(): Pair<SortBook, SortDropKey>? {
        val book: SortBook = dragged ?: return null
        val target: SortDropKey? = hovered
        dragged = null
        return target?.let { book to it }
    }

    internal fun cancel() {
        dragged = null
    }
}

val LocalSortDragState = staticCompositionLocalOf<SortDragState> { error("No SortDragState provided") }

/**
 * A drag source: the cover of [book]. Only the cover, never the card around it — the rest of a card
 * taps through to its étagère, and a carousel must still pan.
 */
@Composable
fun Modifier.sortDragSource(book: SortBook, enabled: Boolean, onDrop: (SortBook, SortDropKey) -> Unit): Modifier {
    val state: SortDragState = LocalSortDragState.current
    val currentOnDrop: (SortBook, SortDropKey) -> Unit by rememberUpdatedState(onDrop)
    val holder: CoordinatesHolder = remember { CoordinatesHolder() }
    return this
        .onGloballyPositioned { holder.coordinates = it }
        .pointerInput(book.id, enabled) {
            if (!enabled) return@pointerInput
            detectDragGesturesAfterLongPress(
                onDragStart = { local ->
                    val coordinates: LayoutCoordinates = holder.coordinates ?: return@detectDragGesturesAfterLongPress
                    state.start(book, coordinates.positionInRoot() + local, coordinates.size.toSizeOrZero(), local)
                },
                onDrag = { change, amount ->
                    change.consume()
                    state.move(amount)
                },
                onDragEnd = { state.end()?.let { (dropped, target) -> currentOnDrop(dropped, target) } },
                onDragCancel = state::cancel,
            )
        }
}

/** A drop target: its visible bounds, kept current as it lays out and forgotten as it leaves. */
@Composable
fun Modifier.sortDropTarget(key: SortDropKey, layer: Int = SortDropZone.GRID_LAYER): Modifier {
    val state: SortDragState = LocalSortDragState.current
    DisposableEffect(key) { onDispose { state.unregister(key) } }
    return onGloballyPositioned { state.register(key, it, layer) }
}

private class CoordinatesHolder {
    var coordinates: LayoutCoordinates? = null
}

private fun IntSize.toSizeOrZero(): Size = if (width == 0 || height == 0) Size.Zero else toSize()
