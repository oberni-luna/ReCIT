package studio.lunabee.nouveaurecit.data.groups

/**
 * `GroupNameRule`: what inventaire.io accepts as a group name (`server/models/validations/group.ts`) —
 * 1 to 80 characters once trimmed. Checked as the name is typed, so a form never sends one the server
 * will refuse.
 */
object GroupNameRule {
    const val MAXIMUM_LENGTH: Int = 80

    fun accepts(name: String): Boolean {
        val trimmed: String = name.trim()
        return trimmed.isNotEmpty() && trimmed.length <= MAXIMUM_LENGTH
    }

    /** Whether the form should say the name is too long — as typed, the way iOS counts it. */
    fun isTooLong(name: String): Boolean = name.length > MAXIMUM_LENGTH
}
