package studio.lunabee.nouveaurecit.network

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.serializer
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException

/**
 * `AppModels/Service/APIService.swift`: JSON in, JSON out, over one `OkHttpClient`.
 *
 * Two instances exist, exactly as on iOS (ADR 0008): one over the client that carries the
 * session, one over the client that neither sends nor stores a cookie. A call made before there is
 * a user goes through the second.
 *
 * Query values are passed as pairs and encoded by `HttpUrl` — the iOS code interpolates most of them
 * raw and lets Foundation escape `|` and `:`; encoding them here is the same request on the wire.
 */
class ApiService(
    private val client: OkHttpClient,
    val json: Json = DefaultJson,
) {
    suspend inline fun <reified T> get(
        path: String,
        vararg query: Pair<String, String>,
    ): T = execute(buildRequest(path, query.toList(), "GET", null), serializer())

    suspend inline fun <reified B, reified T> send(
        path: String,
        method: String = "POST",
        body: B,
        query: List<Pair<String, String>> = emptyList(),
    ): T {
        val payload: RequestBody = json.encodeToString(serializer<B>(), body).toRequestBody(JsonMediaType)
        return execute(buildRequest(path, query, method, payload), serializer())
    }

    /** The no-body verb — `DELETE /api/user`. No `Content-Type` either: there is nothing to type. */
    suspend inline fun <reified T> sendEmpty(path: String, method: String): T =
        execute(buildRequest(path, emptyList(), method, ByteArray(0).toRequestBody(null)), serializer())

    fun buildRequest(
        path: String,
        query: List<Pair<String, String>>,
        method: String,
        body: RequestBody?,
    ): Request {
        val url: HttpUrl = "$BASE_URL$path".toHttpUrl().newBuilder().apply {
            query.forEach { (name, value) -> addQueryParameter(name, value) }
        }.build()
        return Request.Builder().url(url).method(method, body).build()
    }

    suspend fun <T> execute(request: Request, deserializer: KSerializer<T>): T = withContext(Dispatchers.IO) {
        val responseBody: String = try {
            client.newCall(request).execute().use { response ->
                val text: String = response.body.string()
                if (!response.isSuccessful) throw NetworkError.BadStatus(response.code, text)
                text
            }
        } catch (error: IOException) {
            throw NetworkError.Transport(error)
        }
        try {
            json.decodeFromString(deserializer, responseBody)
        } catch (error: IllegalArgumentException) {
            throw NetworkError.Decoding(error)
        }
    }

    companion object {
        const val BASE_URL: String = "https://inventaire.io"
        val JsonMediaType = "application/json".toMediaType()

        val DefaultJson: Json = Json {
            ignoreUnknownKeys = true
            explicitNulls = false
            coerceInputValues = true
            isLenient = true
        }
    }
}
