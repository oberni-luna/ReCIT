package studio.lunabee.nouveaurecit.data.user

/**
 * `ProfileChange`: one public attribute of the account about to be written, with the value it is written
 * with. `PUT /api/user` takes a single attribute per request, so a profile is saved as a list of these.
 */
sealed interface ProfileChange {
    val kind: Kind

    /** A new picture, the path of its reduced JPEG, to be uploaded first; `null` takes the picture away. */
    data class Picture(val path: String?) : ProfileChange {
        override val kind: Kind get() = Kind.Picture
    }

    data class Username(val value: String) : ProfileChange {
        override val kind: Kind get() = Kind.Username
    }

    data class Bio(val value: String) : ProfileChange {
        override val kind: Kind get() = Kind.Bio
    }

    /** `null` takes the position away. */
    data class Position(val coordinates: Coordinates?) : ProfileChange {
        override val kind: Kind get() = Kind.Position
    }

    enum class Kind { Picture, Username, Bio, Position }
}
