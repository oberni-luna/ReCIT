package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.PointerEvent
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.SuspendingPointerInputModifierNode
import androidx.compose.ui.node.DelegatingNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.PointerInputModifierNode
import androidx.compose.ui.unit.IntSize

/**
 * Calls [onTap] on a tap, while whatever lies under the element — a pager, a scrolling page — still gets
 * every touch: a drag starting on it moves what is underneath, and is no tap.
 */
internal fun Modifier.onTapSharedWithSiblings(onTap: () -> Unit): Modifier = this then TapSharedWithSiblingsElement(onTap)

private data class TapSharedWithSiblingsElement(val onTap: () -> Unit) : ModifierNodeElement<TapSharedWithSiblingsNode>() {
    override fun create(): TapSharedWithSiblingsNode = TapSharedWithSiblingsNode(onTap)

    override fun update(node: TapSharedWithSiblingsNode) {
        node.onTap = onTap
    }
}

private class TapSharedWithSiblingsNode(var onTap: () -> Unit) : DelegatingNode(), PointerInputModifierNode {
    private val taps: SuspendingPointerInputModifierNode = delegate(
        SuspendingPointerInputModifierNode { detectTapGestures { onTap() } },
    )

    override fun onPointerEvent(pointerEvent: PointerEvent, pass: PointerEventPass, bounds: IntSize) {
        taps.onPointerEvent(pointerEvent, pass, bounds)
    }

    override fun onCancelPointerInput() {
        taps.onCancelPointerInput()
    }

    override fun sharePointerInputWithSiblings(): Boolean = true
}
