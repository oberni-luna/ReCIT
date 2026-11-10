package studio.lunabee.exlibris.backend.plugins

import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.plugins.forwardedheaders.XForwardedHeaders

/**
 * The client's address and scheme as the hosting's nginx forwards them (#93), so `origin.remoteHost` names the
 * client rather than Docker's gateway. The last `X-Forwarded-For` value is the one nginx appends itself; the ones
 * before come from the client and are never trusted. The backend listens on loopback only, behind that nginx.
 */
fun Application.installForwardedHeaders() {
    install(XForwardedHeaders) {
        useLastProxy()
    }
}
