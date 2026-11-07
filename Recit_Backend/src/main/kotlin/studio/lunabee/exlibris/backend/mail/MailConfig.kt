package studio.lunabee.exlibris.backend.mail

import io.ktor.server.config.ApplicationConfig

/** The SMTP server the account e-mails leave through: Mailpit locally, the provider chosen with the hosting later. */
data class MailConfig(
    val host: String,
    val port: Int,
    val user: String?,
    val password: String?,
    val startTls: Boolean,
    val from: String,
) {
    companion object {
        fun from(config: ApplicationConfig): MailConfig =
            MailConfig(
                host = config.property("mail.host").getString(),
                port = config.property("mail.port").getString().toInt(),
                user = config.propertyOrNull("mail.user")?.getString(),
                password = config.propertyOrNull("mail.password")?.getString(),
                startTls = config.property("mail.startTls").getString().toBoolean(),
                from = config.property("mail.from").getString(),
            )
    }
}
