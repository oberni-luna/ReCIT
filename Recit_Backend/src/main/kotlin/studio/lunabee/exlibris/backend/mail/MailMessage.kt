package studio.lunabee.exlibris.backend.mail

/** A plain-text e-mail to one address. */
data class MailMessage(
    val to: String,
    val subject: String,
    val text: String,
)
