package studio.lunabee.nouveaurecit.data.user

import studio.lunabee.nouveaurecit.data.db.UserEntity

/** Where an attribute of my account is written once the server has taken it: my row in the store. */
fun interface MyProfileStore {
    /** Applies [transform] to my user; nothing when there is no user signed in. */
    suspend fun updateMyUser(transform: (UserEntity) -> UserEntity)
}
