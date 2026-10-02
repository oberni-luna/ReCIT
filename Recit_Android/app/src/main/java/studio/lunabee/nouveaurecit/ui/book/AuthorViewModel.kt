package studio.lunabee.nouveaurecit.ui.book

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.data.db.WorkEntity

data class AuthorUiState(
    val author: AuthorEntity? = null,
    val works: List<WorkEntity> = emptyList(),
    val worksLoading: Boolean = true,
    /** Set when the author could not be loaded and none was cached. */
    val error: String? = null,
)

/** `AuthorDetailView.load()`: the cached author at once, then `refreshAuthor`, then `author-works`. */
class AuthorViewModel(
    private val container: AppContainer,
    private val authorUri: String,
) : ViewModel() {
    private val status: MutableStateFlow<AuthorUiState> = MutableStateFlow(AuthorUiState())

    val state: StateFlow<AuthorUiState> = combine(
        status,
        container.entities.observeAuthor(authorUri),
        container.entities.entities.observeWorksOfAuthor(authorUri),
    ) { current, author, works ->
        current.copy(author = author, works = works.filter { it.title.isNotEmpty() })
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), AuthorUiState())

    init {
        viewModelScope.launch {
            try {
                val author: AuthorEntity? = container.entities.refreshAuthor(authorUri)
                status.value = status.value.copy(error = if (author == null) "" else null)
                if (author != null) container.entities.syncAuthorWorks(authorUri)
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                val cached: Boolean = container.entities.entities.author(authorUri) != null
                status.value = status.value.copy(error = if (cached) null else error.localizedMessage.orEmpty())
            } finally {
                status.value = status.value.copy(worksLoading = false)
            }
        }
    }
}
