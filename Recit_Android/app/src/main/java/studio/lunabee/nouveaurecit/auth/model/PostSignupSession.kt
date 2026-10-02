package studio.lunabee.nouveaurecit.auth.model

/** `Model/Authentication/PostSignupSession.swift`: signing up is one more way of signing in. */
enum class PostSignupSession {
    Established,
    ChainSignIn,
    ;

    companion object {
        fun next(hasSessionCookies: Boolean): PostSignupSession = if (hasSessionCookies) Established else ChainSignIn
    }
}
