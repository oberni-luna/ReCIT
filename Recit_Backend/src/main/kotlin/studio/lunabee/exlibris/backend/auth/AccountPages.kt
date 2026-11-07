package studio.lunabee.exlibris.backend.auth

import kotlinx.html.BODY
import kotlinx.html.FormMethod
import kotlinx.html.HTML
import kotlinx.html.body
import kotlinx.html.button
import kotlinx.html.form
import kotlinx.html.h1
import kotlinx.html.head
import kotlinx.html.hiddenInput
import kotlinx.html.id
import kotlinx.html.label
import kotlinx.html.lang
import kotlinx.html.meta
import kotlinx.html.p
import kotlinx.html.passwordInput
import kotlinx.html.style
import kotlinx.html.title
import kotlinx.html.unsafe

private const val STYLE: String =
    "body{font-family:-apple-system,system-ui,sans-serif;max-width:28rem;margin:4rem auto;padding:0 1.5rem;" +
        "line-height:1.5;color:#222}" +
        "input{display:block;width:100%;box-sizing:border-box;font-size:1rem;padding:.5rem;margin:.25rem 0 1rem}" +
        "button{font-size:1rem;padding:.6rem 1.2rem}.problem{color:#b00020}"

/** One of the pages an e-mailed link opens, plain HTML in the account's language. */
fun HTML.accountPage(
    language: AccountLanguage,
    page: AccountPage,
) {
    val texts: PageTexts = PageTexts.of(language)
    lang = if (language == AccountLanguage.FRENCH) "fr" else "en"
    head {
        meta(charset = "utf-8")
        meta(name = "viewport", content = "width=device-width, initial-scale=1")
        title("Ex-libris")
        style { unsafe { +STYLE } }
    }
    body {
        when (page) {
            AccountPage.EmailConfirmed -> message(texts.emailConfirmed, texts.backToApp)
            AccountPage.ConfirmationLinkInvalid -> message(texts.linkInvalid, texts.askConfirmationAgain)
            AccountPage.PasswordChanged -> message(texts.passwordChanged, texts.signInAgain)
            AccountPage.ResetLinkInvalid -> message(texts.linkInvalid, texts.askResetAgain)
            is AccountPage.ResetForm -> resetForm(texts, page)
        }
    }
}

private fun BODY.message(
    title: String,
    text: String,
) {
    h1 { +title }
    p { +text }
}

private fun BODY.resetForm(
    texts: PageTexts,
    page: AccountPage.ResetForm,
) {
    h1 { +texts.newPassword }
    form(action = "/reset-password", method = FormMethod.post) {
        hiddenInput(name = "token") { value = page.token }
        label {
            htmlFor = "password"
            +texts.password
        }
        passwordInput(name = "password") {
            id = "password"
            required = true
            attributes["autocomplete"] = "new-password"
        }
        label {
            htmlFor = "confirmation"
            +texts.confirmation
        }
        passwordInput(name = "confirmation") {
            id = "confirmation"
            required = true
            attributes["autocomplete"] = "new-password"
        }
        when (page.problem) {
            PasswordReset.MISMATCH -> p(classes = "problem") { +texts.mismatch }
            PasswordReset.INVALID_PASSWORD -> p(classes = "problem") { +texts.passwordLength }
            PasswordReset.DONE, PasswordReset.INVALID_LINK, null -> Unit
        }
        button { +texts.save }
    }
}

/** French with `tu`, the voice the apps are moving to (docs/conventions/wording.md). */
private data class PageTexts(
    val emailConfirmed: String,
    val backToApp: String,
    val linkInvalid: String,
    val askConfirmationAgain: String,
    val askResetAgain: String,
    val newPassword: String,
    val password: String,
    val confirmation: String,
    val save: String,
    val mismatch: String,
    val passwordLength: String,
    val passwordChanged: String,
    val signInAgain: String,
) {
    companion object {
        fun of(language: AccountLanguage): PageTexts =
            when (language) {
                AccountLanguage.FRENCH -> FRENCH
                AccountLanguage.ENGLISH -> ENGLISH
            }

        private val FRENCH: PageTexts =
            PageTexts(
                emailConfirmed = "Adresse confirmée.",
                backToApp = "Tu peux revenir dans Ex-libris.",
                linkInvalid = "Ce lien n'est plus valable.",
                askConfirmationAgain = "Demande un nouvel e-mail de confirmation depuis Ex-libris.",
                askResetAgain = "Demande un nouveau lien depuis Ex-libris.",
                newPassword = "Nouveau mot de passe",
                password = "Mot de passe",
                confirmation = "Confirmation",
                save = "Enregistrer",
                mismatch = "Les deux mots de passe sont différents.",
                passwordLength = "Il faut entre 8 et 256 caractères.",
                passwordChanged = "Mot de passe modifié.",
                signInAgain = "Tu peux te connecter dans Ex-libris.",
            )

        private val ENGLISH: PageTexts =
            PageTexts(
                emailConfirmed = "Address confirmed.",
                backToApp = "You can go back to Ex-libris.",
                linkInvalid = "This link no longer works.",
                askConfirmationAgain = "Ask Ex-libris for a new confirmation e-mail.",
                askResetAgain = "Ask Ex-libris for a new link.",
                newPassword = "New password",
                password = "Password",
                confirmation = "Confirm",
                save = "Save",
                mismatch = "The two passwords are different.",
                passwordLength = "Use 8 to 256 characters.",
                passwordChanged = "Password changed.",
                signInAgain = "You can sign in to Ex-libris.",
            )
    }
}
