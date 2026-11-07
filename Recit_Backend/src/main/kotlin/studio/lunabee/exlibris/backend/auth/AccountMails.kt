package studio.lunabee.exlibris.backend.auth

import studio.lunabee.exlibris.backend.mail.MailMessage
import studio.lunabee.exlibris.backend.mail.MailSender
import java.net.URLEncoder

/**
 * The two account e-mails, in the account's language. Their links open the pages `authRoutes` serves under
 * [publicBaseUrl]; deep links into the apps can replace them later (#65).
 */
class AccountMails(
    private val sender: MailSender,
    private val publicBaseUrl: String,
) {
    suspend fun sendConfirmation(
        account: Account,
        token: String,
    ) {
        val link: String = link("/confirm-email", token)
        val message: MailMessage =
            when (AccountLanguage.of(account.language)) {
                AccountLanguage.FRENCH -> {
                    MailMessage(
                        to = account.email,
                        subject = "Confirme ton adresse e-mail",
                        text =
                            "Bonjour ${account.username},\n\n" +
                                "Ouvre ce lien pour confirmer ton adresse\u202F:\n$link\n\n" +
                                "Il reste valable 24\u00A0heures.\n\nEx-libris\n",
                    )
                }

                AccountLanguage.ENGLISH -> {
                    MailMessage(
                        to = account.email,
                        subject = "Confirm your e-mail address",
                        text =
                            "Hi ${account.username},\n\n" +
                                "Open this link to confirm your address:\n$link\n\n" +
                                "It works for 24 hours.\n\nEx-libris\n",
                    )
                }
            }
        sender.send(message)
    }

    suspend fun sendPasswordReset(
        account: Account,
        token: String,
    ) {
        val link: String = link("/reset-password", token)
        val message: MailMessage =
            when (AccountLanguage.of(account.language)) {
                AccountLanguage.FRENCH -> {
                    MailMessage(
                        to = account.email,
                        subject = "Choisis un nouveau mot de passe",
                        text =
                            "Bonjour ${account.username},\n\n" +
                                "Ouvre ce lien pour choisir un nouveau mot de passe\u202F:\n$link\n\n" +
                                "Il reste valable une heure. Si tu n'as rien demandé, ignore cet e-mail\u202F: " +
                                "ton mot de passe ne change pas.\n\nEx-libris\n",
                    )
                }

                AccountLanguage.ENGLISH -> {
                    MailMessage(
                        to = account.email,
                        subject = "Choose a new password",
                        text =
                            "Hi ${account.username},\n\n" +
                                "Open this link to choose a new password:\n$link\n\n" +
                                "It works for one hour. If you didn't ask for it, ignore this e-mail: " +
                                "your password stays the same.\n\nEx-libris\n",
                    )
                }
            }
        sender.send(message)
    }

    private fun link(
        path: String,
        token: String,
    ): String = "${publicBaseUrl.trimEnd('/')}$path?token=${URLEncoder.encode(token, Charsets.UTF_8)}"
}
