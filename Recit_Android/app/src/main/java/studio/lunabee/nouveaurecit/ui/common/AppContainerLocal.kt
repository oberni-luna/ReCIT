package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import studio.lunabee.nouveaurecit.AppContainer

/** The composition root, as SwiftUI's `.environment(…)` hands models to every view. */
val LocalAppContainer = staticCompositionLocalOf<AppContainer> { error("No AppContainer provided") }

/**
 * A screen's `ViewModel`, built from the container. Scoped to the navigation entry (each `NavDisplay`
 * installs the view-model store decorator), so pushing the same screen twice gives two instances.
 */
@Composable
inline fun <reified VM : ViewModel> recitViewModel(
    key: String? = null,
    crossinline create: (AppContainer) -> VM,
): VM {
    val container: AppContainer = LocalAppContainer.current
    return viewModel(key = key, factory = viewModelFactory { initializer { create(container) } })
}
