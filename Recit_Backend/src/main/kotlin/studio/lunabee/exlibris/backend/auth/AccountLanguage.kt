package studio.lunabee.exlibris.backend.auth

/** The two languages the account e-mails and pages are written in; any other reads English. */
enum class AccountLanguage {
    FRENCH,
    ENGLISH,
    ;

    companion object {
        fun of(tag: String?): AccountLanguage =
            if (tag?.trim()?.lowercase()?.startsWith("fr") ==
                true
            ) {
                FRENCH
            } else {
                ENGLISH
            }
    }
}
