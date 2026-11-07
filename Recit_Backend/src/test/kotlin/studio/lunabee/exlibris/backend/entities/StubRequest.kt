package studio.lunabee.exlibris.backend.entities

/** One request [InventaireStub] received, headers by lower-case name. */
data class StubRequest(
    val method: String,
    val uri: String,
    val headers: Map<String, List<String>>,
) {
    fun header(name: String): String? = headers[name.lowercase()]?.firstOrNull()
}
