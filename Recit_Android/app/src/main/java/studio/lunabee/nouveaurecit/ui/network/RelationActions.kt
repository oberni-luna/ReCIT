package studio.lunabee.nouveaurecit.ui.network

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer

/**
 * The relation writes every Réseau screen offers, and `InvitationAnswer`: each one optimistic
 * (the row moves at once, a failure reverts it and speaks through the shared snackbar), and an
 * accepted invitation pulls the new friend's shelves and books in straight away.
 */
class RelationActions(
    private val container: AppContainer,
    private val scope: CoroutineScope,
) {
    fun request(userId: String) {
        scope.launch { container.users.requestRelation(userId) }
    }

    fun cancel(userId: String) {
        scope.launch { container.users.cancelRelation(userId) }
    }

    fun accept(userId: String) {
        scope.launch { container.users.acceptRelation(userId) { container.session.syncFriend(userId).join() } }
    }

    fun refuse(userId: String) {
        scope.launch { container.users.discardRelation(userId) }
    }

    fun unfriend(userId: String) {
        scope.launch { container.users.unfriend(userId) }
    }
}
