package studio.lunabee.exlibris.backend

import io.ktor.server.config.ApplicationConfig
import studio.lunabee.exlibris.backend.auth.SessionConfig
import studio.lunabee.exlibris.backend.db.PostgresConfig
import studio.lunabee.exlibris.backend.entities.InventaireConfig
import studio.lunabee.exlibris.backend.images.ImagesConfig
import studio.lunabee.exlibris.backend.mail.MailConfig

/** Everything `application.conf` sets, read once by [module]. */
data class AppConfig(
    val postgres: PostgresConfig,
    val session: SessionConfig,
    val mail: MailConfig,
    val images: ImagesConfig,
    val inventaire: InventaireConfig,
    /** What the e-mails' links open. */
    val publicBaseUrl: String,
) {
    companion object {
        fun from(config: ApplicationConfig): AppConfig =
            AppConfig(
                postgres = PostgresConfig.from(config),
                session = SessionConfig.from(config),
                mail = MailConfig.from(config),
                images = ImagesConfig.from(config),
                inventaire = InventaireConfig.from(config),
                publicBaseUrl = config.property("public.baseUrl").getString(),
            )
    }
}
