package studio.lunabee.nouveaurecit.data.creation

/**
 * `EditionPropertyChoice` (iOS feature 0057): one value a property allows among a fixed few — the entity
 * uri the claim sends, and the name of the string resource the form prints for it. The lists are the
 * server's own (`GET /api/data/property-values`), read on 2026-10-28: anything else is refused.
 */
data class EditionPropertyChoice(
    val uri: String,
    /** The string resource of its name: iOS's catalogue key with its `.` turned into `_` (`work_type_comic`). */
    val labelKey: String,
)
