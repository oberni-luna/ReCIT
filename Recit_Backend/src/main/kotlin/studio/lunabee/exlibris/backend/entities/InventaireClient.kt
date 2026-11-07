package studio.lunabee.exlibris.backend.entities

import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.UserAgent
import io.ktor.client.plugins.timeout
import io.ktor.client.request.header
import io.ktor.client.request.prepareGet
import io.ktor.client.statement.HttpResponse
import io.ktor.http.HttpStatusCode
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.io.IOException
import java.nio.channels.UnresolvedAddressException
import kotlin.time.Duration

/**
 * The backend's only way to inventaire.io, for the relay (#76) and for #73's snapshots and #74's type checks:
 * anonymous — no cookie jar, nothing but the headers a caller hands in — and named by [InventaireConfig.userAgent].
 *
 * Every request shares the backend's one IP, so every `429` inventaire.io answers is logged with its path
 * (#76 decision 5): those lines are what would justify a cache.
 */
class InventaireClient(
    private val config: InventaireConfig,
) : AutoCloseable {
    private val http: HttpClient =
        HttpClient(CIO) {
            expectSuccess = false
            install(HttpTimeout)
            install(UserAgent) { agent = config.userAgent }
        }

    /**
     * GETs [pathAndQuery], as the app sent it, with [headers], and hands the answer to [read] while its body is still
     * open, so that it can be streamed. inventaire.io refusing the connection, or silent for [timeout], answers
     * `502` (#76 decision 4); a failure once [read] has the answer is [read]'s own.
     */
    suspend fun <T> get(
        pathAndQuery: String,
        headers: Map<String, String>,
        timeout: Duration,
        read: suspend (HttpResponse) -> T,
    ): T {
        var isAnswered = false
        return try {
            http
                .prepareGet(config.baseUrl + pathAndQuery) {
                    headers.forEach { (name, value) -> header(name, value) }
                    timeout {
                        connectTimeoutMillis = timeout.inWholeMilliseconds
                        requestTimeoutMillis = timeout.inWholeMilliseconds
                    }
                }.execute { response ->
                    isAnswered = true
                    if (response.status == HttpStatusCode.TooManyRequests) {
                        logger.warn("inventaire.io answered 429 to {}", pathAndQuery.substringBefore('?'))
                    }
                    read(response)
                }
        } catch (cause: IOException) {
            throw if (isAnswered) cause else unreachable(pathAndQuery, cause)
        } catch (cause: UnresolvedAddressException) {
            throw unreachable(pathAndQuery, cause)
        }
    }

    override fun close() {
        http.close()
    }

    private fun unreachable(
        pathAndQuery: String,
        cause: Exception,
    ): ApiException {
        logger.warn("inventaire.io unreachable for {}: {}", pathAndQuery.substringBefore('?'), cause.toString())
        return ApiException.badGateway(cause)
    }

    private companion object {
        val logger: Logger = LoggerFactory.getLogger(InventaireClient::class.java)
    }
}
