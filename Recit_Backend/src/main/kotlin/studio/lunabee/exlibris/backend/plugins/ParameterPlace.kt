package studio.lunabee.exlibris.backend.plugins

/** Where a parameter was looked for, as inventaire.io names it in its errors. */
enum class ParameterPlace(
    val label: String,
) {
    BODY("body"),
    QUERY("query"),
}
