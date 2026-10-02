package studio.lunabee.nouveaurecit.ui.navigation

import androidx.navigation3.runtime.NavBackStack
import androidx.navigation3.runtime.NavKey

/**
 * What a screen is handed to move: the `path: Binding<NavigationPath>` threaded through every iOS
 * detail view. It acts on the back stack of the tab the screen lives in.
 */
class Navigator(private val backStack: NavBackStack<NavKey>) {
    fun push(destination: Destination) {
        backStack.add(destination)
    }

    fun pop() {
        if (backStack.size > 1) backStack.removeAt(backStack.lastIndex)
    }

    fun popToRoot() {
        while (backStack.size > 1) backStack.removeAt(backStack.lastIndex)
    }
}
