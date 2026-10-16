package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortDraftNameRule`: whether a name typed into the create form may become a new étagère.
 *
 * **The refusal happens at the form, not at apply time.** A draft named like an étagère the user
 * already has — or like another draft made five seconds ago — never reaches the change stack, so
 * applying can never produce two étagères the user reads as the same.
 *
 * The comparison is [SortName.key] — trimmed, case- and diacritic-insensitive: « Romans », « romans »,
 * « ROMANS », « Rômans » and « Romans  » are one étagère to a reader.
 *
 * It reads the **sections**, the projection: exactly the names the user can see, existing étagères and
 * drafts alike, in one walk over one list rather than two rules that could drift apart.
 */
class SortDraftNameRule(sections: List<SortSection>) {
    /** Why a name cannot become an étagère. `null` — the absence of one — is the acceptance. */
    sealed interface Refusal {
        /** Nothing but whitespace was typed. */
        data object Blank : Refusal

        /**
         * A section already reads under this name. Carries **that section's** spelling rather than what
         * was typed: someone refused for typing « romans » has to be pointed at « Romans ».
         */
        data class AlreadyUsed(val name: String) : Refusal
    }

    /** Comparison key → the name as the screen spells it. First occurrence wins, in reading order. */
    private val namesByKey: Map<String, String> = buildMap {
        for (section in sections) {
            val name: String = section.name ?: continue
            val key: String = SortName.key(name) ?: continue
            putIfAbsent(key, name)
        }
    }

    /** What is wrong with this name, or `null` when nothing is. */
    fun refusal(raw: String): Refusal? {
        val key: String = SortName.key(raw) ?: return Refusal.Blank
        val taken: String = namesByKey[key] ?: return null
        return Refusal.AlreadyUsed(taken)
    }

    /** Whether the name may be created: the form's submit rule and the session's guard, one question. */
    fun accepts(raw: String): Boolean = refusal(raw) == null
}
