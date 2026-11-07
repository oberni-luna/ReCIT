package studio.lunabee.exlibris.backend.db

import io.ktor.server.config.ApplicationConfig

data class PostgresConfig(
    val url: String,
    val user: String,
    val password: String,
) {
    companion object {
        fun from(config: ApplicationConfig): PostgresConfig =
            PostgresConfig(
                url = config.property("database.url").getString(),
                user = config.property("database.user").getString(),
                password = config.property("database.password").getString(),
            )
    }
}
