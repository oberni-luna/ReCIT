package studio.lunabee.exlibris.backend.images

import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.PartData
import io.ktor.http.content.forEachPart
import io.ktor.server.application.ApplicationCall
import io.ktor.server.request.contentType
import io.ktor.server.request.receiveMultipart
import io.ktor.server.response.header
import io.ktor.server.response.respond
import io.ktor.server.response.respondBytes
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.utils.io.readRemaining
import kotlinx.io.readByteArray
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.queryParameter
import studio.lunabee.exlibris.backend.plugins.requireSessionUser

/** A photograph from the camera, as the apps reduce it, fits many times over. */
private const val MAX_FILE_BYTES: Long = 10L * 1024 * 1024

/** `<width>x<height>`, the resized variant inventaire.io serves; the original is served for any size here. */
private val dimensionsPattern: Regex = Regex("""^\d{1,4}x\d{1,4}$""")

fun Route.imagesRoutes(service: ImagesService) {
    post("/api/images/upload") {
        val userId: String = call.requireSessionUser()
        val container: String = call.queryParameter("container")
        if (!call.request.contentType().match(ContentType.MultiPart.FormData)) {
            throw ApiException(HttpStatusCode.BadRequest, "invalid content-type")
        }
        call.respond(service.upload(userId, container, call.receiveFiles()))
    }
    get("/api/images/gravatar") {
        call.respond(service.gravatarUrl(call.requireSessionUser()))
    }
    ImageContainer.entries.forEach { container ->
        get("/img/${container.parameter}/{hash}") {
            call.respondImage(service, container, call.parameters["hash"], dimensions = null)
        }
        get("/img/${container.parameter}/{dimensions}/{hash}") {
            call.respondImage(service, container, call.parameters["hash"], call.parameters["dimensions"])
        }
    }
}

private suspend fun ApplicationCall.receiveFiles(): List<UploadedFile> {
    val files: MutableList<UploadedFile> = mutableListOf()
    receiveMultipart().forEachPart { part ->
        try {
            if (part is PartData.FileItem) {
                val bytes: ByteArray = part.provider().readRemaining(MAX_FILE_BYTES + 1).readByteArray()
                if (bytes.size > MAX_FILE_BYTES) throw ApiException(HttpStatusCode.PayloadTooLarge, "image too large")
                files += UploadedFile(part.name.orEmpty(), bytes)
            }
        } finally {
            part.dispose()
        }
    }
    return files
}

/** Immutable for a year, as inventaire.io: a path names its bytes by their hash, so they never change. */
private suspend fun ApplicationCall.respondImage(
    service: ImagesService,
    container: ImageContainer,
    hash: String?,
    dimensions: String?,
) {
    val isValidPath: Boolean =
        hash != null &&
            ImagesService.HASH_PATTERN.matches(hash) &&
            (dimensions == null || dimensionsPattern.matches(dimensions))
    val image: StoredImage =
        if (isValidPath) {
            service.image(container, requireNotNull(hash))
                ?: throw ApiException(HttpStatusCode.NotFound, "not found")
        } else {
            throw ApiException(HttpStatusCode.BadRequest, "invalid image path")
        }
    response.header(HttpHeaders.CacheControl, "public, max-age=31536000, immutable")
    response.header("X-Content-Type-Options", "nosniff")
    respondBytes(image.bytes, image.contentType)
}
