package studio.lunabee.nouveaurecit.data.lists

/**
 * `Model/Lists/ListArrivalFocus.swift`: how a list pushed from a book screen arrives on that book — it opens
 * on its first element, moves to the book once the list holds it, then rings its cover until the halo has
 * faded or the reader picks another element. Played once; a list opened without a focus plays nothing.
 *
 * One haptic per arrival: the cover flow's own, when the selection goes from one element to another; else
 * one as the halo lights ([landingFeedbackUri]).
 */
data class ListArrivalFocus(
    val phase: Phase,
    /**
     * Whether the arrival moves the selection without the cover flow ticking for it: from no selection yet,
     * or not at all because the focused element is already selected.
     */
    private val ticksOnLanding: Boolean = false,
) {
    /** How the selection reaches the focused element. */
    sealed interface Move {
        val uri: String

        /** A scroll through the covers in between. */
        data class Scroll(override val uri: String) : Move

        /** Straight on it, with the system's animations off. */
        data class Jump(override val uri: String) : Move
    }

    sealed interface Phase {
        /** The list does not hold the focused element yet. */
        data class Waiting(val uri: String) : Phase

        data class Arriving(val move: Move) : Phase

        data class Highlighted(val uri: String) : Phase

        data object Done : Phase
    }

    val highlightedUri: String? get() = (phase as? Phase.Highlighted)?.uri

    /** The ringed element, while the halo is the arrival's only haptic. */
    val landingFeedbackUri: String? get() = highlightedUri?.takeIf { ticksOnLanding }

    /** The element a jump just started sets the selection on, straight away. */
    val jumpUri: String? get() = ((phase as? Phase.Arriving)?.move as? Move.Jump)?.uri

    /**
     * Starts the arrival the first time the list holds the focused element. A jump sets the selection
     * straight on it; a scroll starts from [selectedUri], or from the first element the list opens on.
     *
     * @param uris The list's elements, in order.
     * @param selectedUri The selection when the list comes to hold the focused element.
     * @param reducesMotion Whether the system's animations are off.
     */
    fun start(uris: List<String>, selectedUri: String?, reducesMotion: Boolean): ListArrivalFocus {
        val waiting: Phase.Waiting = phase as? Phase.Waiting ?: return this
        if (waiting.uri !in uris) return this
        val origin: String? = if (reducesMotion) selectedUri else selectedUri ?: uris.first()
        val move: Move = if (reducesMotion) Move.Jump(waiting.uri) else Move.Scroll(waiting.uri)
        return ListArrivalFocus(Phase.Arriving(move), ticksOnLanding = origin == null || origin == waiting.uri)
    }

    /** Ends the move: the halo lights if the selection, [selectedUri], stands on the focused element. */
    fun land(selectedUri: String?): ListArrivalFocus {
        val arriving: Phase.Arriving = phase as? Phase.Arriving ?: return this
        val uri: String = arriving.move.uri
        return copy(phase = if (selectedUri == uri) Phase.Highlighted(uri) else Phase.Done)
    }

    /** Puts the halo out when the reader moves the selection elsewhere, to [selectedUri]. */
    fun select(selectedUri: String?): ListArrivalFocus {
        val highlighted: Phase.Highlighted = phase as? Phase.Highlighted ?: return this
        return if (selectedUri == highlighted.uri) this else copy(phase = Phase.Done)
    }

    fun endHighlight(): ListArrivalFocus = if (phase is Phase.Highlighted) copy(phase = Phase.Done) else this

    companion object {
        /** The arrival on [focusUri]; `null` for a list opened anywhere but a book screen. */
        fun on(focusUri: String?): ListArrivalFocus = ListArrivalFocus(focusUri?.let(Phase::Waiting) ?: Phase.Done)
    }
}
