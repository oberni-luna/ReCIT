package studio.lunabee.nouveaurecit.data.images

/**
 * Where `POST /api/images/upload` files a picture: the `container` it is sent into, the form field it
 * travels in — the server keys its answer by that name, so it is also the key read back — and the
 * name the file is given.
 */
enum class ImageContainer(val value: String, val fieldName: String, val fileName: String) {
    /** An edition's cover, filed as `/img/entities/<hash>`. */
    Entities(value = "entities", fieldName = "cover", fileName = "cover.jpg"),

    /** A group's photo, filed as `/img/groups/<hash>`. */
    Groups(value = "groups", fieldName = "picture", fileName = "group.jpg"),
}
