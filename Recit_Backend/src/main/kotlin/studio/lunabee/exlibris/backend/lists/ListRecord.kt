package studio.lunabee.exlibris.backend.lists

import studio.lunabee.exlibris.backend.db.DocumentId

/** A `lists` row. */
data class ListRecord(
    val id: String,
    val version: Int,
    val creator: String,
    val name: String,
    val description: String,
    val visibility: List<String>,
    val type: ListType,
    val created: Long,
    val updated: Long?,
) {
    val fields: ListFields
        get() = ListFields(name, description, visibility)

    fun document(
        elements: List<ListElementDocument>? = null,
        totalElements: Int? = null,
        imagesSample: List<String>? = null,
    ): ListDocument =
        ListDocument(
            id = id,
            rev = DocumentId.revision(id, version),
            name = name,
            description = description,
            visibility = visibility,
            creator = creator,
            created = created,
            updated = updated,
            type = type.storedName,
            elements = elements,
            totalElements = totalElements,
            imagesSample = imagesSample,
        )
}
