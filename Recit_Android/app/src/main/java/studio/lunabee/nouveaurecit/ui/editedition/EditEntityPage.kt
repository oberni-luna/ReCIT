package studio.lunabee.nouveaurecit.ui.editedition

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.CreateBookFailure
import studio.lunabee.nouveaurecit.data.creation.EditionPropertyCatalogue
import studio.lunabee.nouveaurecit.data.creation.EntityEdit
import studio.lunabee.nouveaurecit.designsystem.ConfirmDialog
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `EditEntityView` (iOS feature 0057): « Modifier l'œuvre » or « Modifier l'auteur·ice », pushed over
 * « Modifier l'édition » — the work or the person read fresh from inventaire.io, its form, and its own
 * « Enregistrer » pinned at the foot. Saving sends this entity alone, then goes back one page; what was
 * being changed beneath stays as it was, the saved values shown in it.
 *
 * Going back over changes not saved asks « Quitter sans enregistrer ? », as « Ranger mes livres » does:
 * what is dropped was never sent, so the answer is « Quitter », not styled destructive.
 *
 * [edit] is `null` until the entity is read; [isUnreadable] once reading it failed.
 */
@Composable
fun EditEntityPage(
    edit: EntityEdit?,
    isUnreadable: Boolean,
    failure: CreateBookFailure?,
    isSaving: Boolean,
    isConfirmingLeave: Boolean,
    actions: EntityFormActions,
    onSave: () -> Unit,
    onRetryLoad: () -> Unit,
    onBack: () -> Unit,
    onLeave: () -> Unit,
    onStay: () -> Unit,
    onHelp: () -> Unit,
) {
    val isPerson: Boolean = edit?.catalogue == EditionPropertyCatalogue.Human
    Box(Modifier.fillMaxSize()) {
        FormPageScaffold(
            title = stringResource(if (isPerson) R.string.edit_author_title else R.string.edit_work_title),
            onBack = onBack,
            actions = { BibliographicDataHelpButton(onHelp) },
            bottomBar = {
                if (edit != null) {
                    FormActionBar(
                        text = stringResource(if (failure?.isWorthRetrying == true) R.string.create_book_retry else R.string.action_save),
                        onClick = onSave,
                        enabled = edit.isSaveable,
                        isLoading = isSaving,
                    )
                }
            },
        ) {
            when {
                edit != null -> {
                    failure?.let {
                        item(key = "failure") {
                            FormFailureBanner(
                                title = stringResource(EditionPropertyLabels.editTitle(it)),
                                body = stringResource(EditionPropertyLabels.entityEditBody(it)),
                                modifier = Modifier.padding(top = Spacing.small),
                            )
                        }
                    }
                    when (edit.catalogue) {
                        EditionPropertyCatalogue.Work -> editWorkForm(edit, actions)
                        EditionPropertyCatalogue.Human -> editAuthorForm(edit, actions)
                        EditionPropertyCatalogue.Edition -> Unit
                    }
                }
                isUnreadable -> item(key = "unreadable") {
                    EmptyState(
                        title = stringResource(R.string.book_resolve_error_title),
                        message = stringResource(R.string.book_resolve_error_message),
                        icon = Icons.Filled.ErrorOutline,
                        actionTitle = stringResource(R.string.action_retry),
                        onAction = onRetryLoad,
                        modifier = Modifier.padding(vertical = Spacing.xLarge),
                    )
                }
                else -> item(key = "loading") {
                    Box(Modifier.fillMaxSize().padding(vertical = Spacing.xLarge), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary)
                    }
                }
            }
        }
        if (isSaving) SavingShield()
    }
    if (isConfirmingLeave) {
        ConfirmDialog(
            title = stringResource(R.string.sort_leave_confirm_title),
            message = stringResource(R.string.edit_entity_leave_message),
            confirmLabel = stringResource(R.string.sort_leave_confirm_action),
            cancelLabel = stringResource(R.string.action_cancel),
            onConfirm = onLeave,
            onDismiss = onStay,
            isDestructive = false,
        )
    }
}
