package studio.lunabee.nouveaurecit.data.user

/** The reduced picture « Enregistrer » was to upload is no longer in the cache: nothing went to the server. */
class MissingPictureFile(path: String) : Exception("No picture at $path")
