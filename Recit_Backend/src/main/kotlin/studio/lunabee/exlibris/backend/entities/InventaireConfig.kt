package studio.lunabee.exlibris.backend.entities

import io.ktor.server.config.ApplicationConfig
import java.util.Properties

/** Where inventaire.io is reached, and how the backend names itself there (#76 decision 2). */
data class InventaireConfig(
    /** Without a trailing slash: a relayed path is appended as the app sent it. */
    val baseUrl: String,
    /** `Ex-libris/<version> (+<contact URL>)`: one IP answers for every reader, so inventaire.io knows whom to ask. */
    val userAgent: String,
) {
    companion object {
        private const val CONTACT_URL: String = "https://github.com/oberni-luna/ReCIT"

        fun from(config: ApplicationConfig): InventaireConfig =
            InventaireConfig(
                baseUrl = config.property("inventaire.baseUrl").getString().trimEnd('/'),
                userAgent = "Ex-libris/${backendVersion()} (+$CONTACT_URL)",
            )

        /** The build's version, written into `version.properties` by Gradle's `processResources`. */
        private fun backendVersion(): String {
            val properties = Properties()
            InventaireConfig::class.java.getResourceAsStream("/version.properties").use { stream ->
                properties.load(requireNotNull(stream) { "version.properties is missing from the classpath" })
            }
            return properties.getProperty("version")
        }
    }
}
