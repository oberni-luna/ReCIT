package studio.lunabee.exlibris.backend.images

/** One file of a `multipart/form-data` upload. [fieldName] is what inventaire.io indexes its answer by. */
class UploadedFile(
    val fieldName: String,
    val bytes: ByteArray,
)
