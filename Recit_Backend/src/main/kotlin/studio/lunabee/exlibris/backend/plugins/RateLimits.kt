package studio.lunabee.exlibris.backend.plugins

import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.plugins.origin
import io.ktor.server.plugins.ratelimit.RateLimit
import io.ktor.server.plugins.ratelimit.RateLimitName
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes

private const val LOGINS_PER_MINUTE: Int = 10
private const val SIGNUPS_PER_HOUR: Int = 5

/** The per-IP limits a route wraps itself in, `rateLimit(RateLimits.LOGIN) { … }`. */
object RateLimits {
    val LOGIN: RateLimitName = RateLimitName("login")
    val SIGNUP: RateLimitName = RateLimitName("signup")
}

/**
 * The per-IP limits of #70 decision 9, in memory: one instance of the backend. Their `429` is what the apps
 * already show (feature 0083). The IP is the client's, from nginx's `X-Forwarded-For` (`installForwardedHeaders`).
 */
fun Application.installRateLimits() {
    install(RateLimit) {
        register(RateLimits.LOGIN) {
            rateLimiter(limit = LOGINS_PER_MINUTE, refillPeriod = 1.minutes)
            requestKey { call -> call.request.origin.remoteHost }
        }
        register(RateLimits.SIGNUP) {
            rateLimiter(limit = SIGNUPS_PER_HOUR, refillPeriod = 1.hours)
            requestKey { call -> call.request.origin.remoteHost }
        }
    }
}
