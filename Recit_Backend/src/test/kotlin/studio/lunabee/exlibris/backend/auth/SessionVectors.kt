package studio.lunabee.exlibris.backend.auth

/** Cookie values written by Node's `cookie-session` (`Buffer.from(JSON.stringify(session)).toString('base64')`). */
object SessionVectors {
    /** `{"user":"36829e21389c27c629a3181e31c36301","timestamp":1787493340761}`, the payload ADR 0008 quotes. */
    const val USER: String =
        "eyJ1c2VyIjoiMzY4MjllMjEzODljMjdjNjI5YTMxODFlMzFjMzYzMDEiLCJ0aW1lc3RhbXAiOjE3ODc0OTMzNDA3NjF9"
    const val USER_ID: String = "36829e21389c27c629a3181e31c36301"
    const val USER_TIMESTAMP: Long = 1_787_493_340_761

    /** Its signature under `test-secret-new`, then under `test-secret-old`. */
    const val USER_SIGNATURE: String = "TJn6lEOk0Jk_yNDGdsBlku0LA2ZtDoZv8ad2FR7GqcA"
    const val USER_SIGNATURE_OLD_SECRET: String = "1OSiNFTk9x6Z_UOPVQSc_s_k0x1KjBvRWOAr3IQCnWI"

    /** `{"timestamp":1788900010063}`, the anonymous session every public call hands out. */
    const val ANONYMOUS: String = "eyJ0aW1lc3RhbXAiOjE3ODg5MDAwMTAwNjN9"
    const val ANONYMOUS_SIGNATURE: String = "Hxbu1V2H8MOEXAPWZnlVkUcqcKuPBeIAyUvpyOtm0YA"

    /** The signature of `inventaire:session=` under `test-secret-new`: what a closed session sends. */
    const val EMPTY_SIGNATURE: String = "maCXfdmpxuGM3KlXJXPJIEPEViVcarVobXWGDmUJYZ0"

    /** A payload whose base64 needs padding and has a `+`: `…,"x":"é?>"}`. */
    const val PADDED: String =
        "eyJ1c2VyIjoiMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYiLCJ0aW1lc3RhbXAiOjE3MDAwMDAwMDAwMDAsIngiOiLDqT8+In0="
}
