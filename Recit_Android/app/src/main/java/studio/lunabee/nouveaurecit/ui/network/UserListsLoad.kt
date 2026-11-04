package studio.lunabee.nouveaurecit.ui.network

/**
 * `UserListsTab.Load`: where the profile's fetch of a reader's lists stands — what tells an empty Listes
 * page from one still waiting for its first answer.
 */
enum class UserListsLoad { Loading, Loaded, Failed }
