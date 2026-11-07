package studio.lunabee.exlibris.backend.entities

/** What [InventaireStub] answers, after [delayMillis]: a silent inventaire.io when it outlasts the relay's timeout. */
class StubAnswer(
    val status: Int,
    val body: ByteArray = ByteArray(0),
    val headers: Map<String, String> = emptyMap(),
    val delayMillis: Long = 0,
) {
    companion object {
        fun json(
            body: String,
            status: Int = 200,
            headers: Map<String, String> = emptyMap(),
        ): StubAnswer =
            StubAnswer(
                status = status,
                body = body.encodeToByteArray(),
                headers = mapOf("Content-Type" to "application/json; charset=utf-8") + headers,
            )
    }
}
