package studio.lunabee.exlibris.backend.auth

/** The two fields an account must not share with another, and their parameter's name. */
enum class AccountField(
    val parameter: String,
) {
    USERNAME("username"),
    EMAIL("email"),
}
