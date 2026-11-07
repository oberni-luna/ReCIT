package studio.lunabee.exlibris.backend.entities

import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors

/**
 * inventaire.io's stand-in, on a free local port: answers what [answer] says and keeps every request it received, so
 * that a test sees what the relay sent. The relay's tests never reach inventaire.io itself.
 */
class InventaireStub : AutoCloseable {
    @Volatile
    var answer: (StubRequest) -> StubAnswer = { StubAnswer.json("{}") }

    private val received: MutableList<StubRequest> = CopyOnWriteArrayList()

    private val server: HttpServer =
        HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0).apply {
            executor = Executors.newCachedThreadPool { runnable -> Thread(runnable).apply { isDaemon = true } }
            createContext("/") { exchange -> exchange.use { handle(it) } }
            start()
        }

    val baseUrl: String = "http://127.0.0.1:${server.address.port}"

    val requests: List<StubRequest>
        get() = received.toList()

    override fun close() {
        server.stop(0)
    }

    private fun handle(exchange: HttpExchange) {
        val request =
            StubRequest(
                method = exchange.requestMethod,
                uri = exchange.requestURI.rawPath + (exchange.requestURI.rawQuery?.let { "?$it" } ?: ""),
                headers = exchange.requestHeaders.mapKeys { it.key.lowercase() },
            )
        received += request
        val stubAnswer: StubAnswer = answer(request)
        Thread.sleep(stubAnswer.delayMillis)
        stubAnswer.headers.forEach { (name, value) -> exchange.responseHeaders.add(name, value) }
        val length: Long = if (stubAnswer.body.isEmpty()) NO_BODY else stubAnswer.body.size.toLong()
        exchange.sendResponseHeaders(stubAnswer.status, length)
        if (stubAnswer.body.isNotEmpty()) exchange.responseBody.write(stubAnswer.body)
    }

    private companion object {
        const val NO_BODY: Long = -1
    }
}
