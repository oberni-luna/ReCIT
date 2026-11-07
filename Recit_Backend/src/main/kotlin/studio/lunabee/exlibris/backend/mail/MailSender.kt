package studio.lunabee.exlibris.backend.mail

import jakarta.mail.Authenticator
import jakarta.mail.Message
import jakarta.mail.PasswordAuthentication
import jakarta.mail.Session
import jakarta.mail.Transport
import jakarta.mail.internet.InternetAddress
import jakarta.mail.internet.MimeMessage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Properties

/** Sends over SMTP, off the event loop. Throws `MessagingException` when the server refuses or cannot be reached. */
class MailSender(
    private val config: MailConfig,
) {
    private val session: Session =
        Session.getInstance(
            Properties().apply {
                put("mail.smtp.host", config.host)
                put("mail.smtp.port", config.port.toString())
                put("mail.smtp.auth", (config.user != null).toString())
                put("mail.smtp.starttls.enable", config.startTls.toString())
                put("mail.smtp.connectiontimeout", TIMEOUT_MILLIS.toString())
                put("mail.smtp.timeout", TIMEOUT_MILLIS.toString())
            },
            config.user?.let { user ->
                object : Authenticator() {
                    override fun getPasswordAuthentication(): PasswordAuthentication =
                        PasswordAuthentication(user, config.password.orEmpty())
                }
            },
        )

    suspend fun send(message: MailMessage) {
        withContext(Dispatchers.IO) {
            val mime =
                MimeMessage(session).apply {
                    setFrom(InternetAddress(config.from))
                    setRecipients(Message.RecipientType.TO, InternetAddress.parse(message.to))
                    setSubject(message.subject, Charsets.UTF_8.name())
                    setText(message.text, Charsets.UTF_8.name())
                }
            Transport.send(mime)
        }
    }

    private companion object {
        const val TIMEOUT_MILLIS: Int = 10_000
    }
}
