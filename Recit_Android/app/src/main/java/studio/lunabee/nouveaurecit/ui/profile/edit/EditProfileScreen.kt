package studio.lunabee.nouveaurecit.ui.profile.edit

import androidx.activity.compose.BackHandler
import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.auth.model.AuthFailure
import studio.lunabee.nouveaurecit.data.user.ProfileChange
import studio.lunabee.nouveaurecit.data.user.ProfileDraft
import studio.lunabee.nouveaurecit.data.user.ProfileSaveFailure
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.editedition.FormActionBar
import studio.lunabee.nouveaurecit.ui.editedition.FormDivider
import studio.lunabee.nouveaurecit.ui.editedition.FormFailureBanner
import studio.lunabee.nouveaurecit.ui.editedition.FormFootnote
import studio.lunabee.nouveaurecit.ui.editedition.FormSection
import studio.lunabee.nouveaurecit.ui.editedition.FormTextRow
import studio.lunabee.nouveaurecit.ui.editedition.SavingShield
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `EditProfileView` (iOS feature 0055): « Modifier le profil », pushed from the Profil — the picture, the
 * name, the bio and the position, what every reader sees of the account.
 *
 * « Enregistrer » is pinned at the foot, greyed while nothing changed, while the name typed is refused by
 * the live check, or while the bio is too long. It waits for the server; while it does, nothing can be
 * left or changed. A refusal part of the way shows a banner naming what was refused, and the button says
 * « Réessayer ».
 */
@Composable
fun EditProfileScreen(navigator: Navigator) {
    val viewModel: EditProfileViewModel = recitViewModel { EditProfileViewModel(it) }
    val state: EditProfileUiState by viewModel.state.collectAsStateWithLifecycle()
    val draft: ProfileDraft? = state.draft

    LaunchedEffect(state.isSaved) { if (state.isSaved) navigator.pop() }
    BackHandler(enabled = state.isSaving || state.isPlacingPosition) { viewModel.closePosition() }

    if (state.isPlacingPosition && draft != null) {
        ProfilePositionScreen(
            position = draft.position,
            onConfirm = viewModel::placePosition,
            onRemove = { viewModel.placePosition(null) },
            onBack = viewModel::closePosition,
        )
        return
    }

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.edit_profile_title), onBack = { if (!state.isSaving) navigator.pop() }) },
        bottomBar = {
            if (draft != null) {
                FormActionBar(
                    text = stringResource(if (state.failure == null) R.string.action_save else R.string.create_book_retry),
                    onClick = viewModel::save,
                    enabled = state.canSave,
                    isLoading = state.isSaving,
                )
            }
        },
        containerColor = RecitTheme.colors.backgroundForm,
    ) { padding: PaddingValues ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            if (draft == null) {
                CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary, modifier = Modifier.align(Alignment.Center))
            } else {
                EditProfileForm(state = state, draft = draft, viewModel = viewModel)
            }
            if (state.isSaving) SavingShield()
        }
    }
}

@Composable
private fun EditProfileForm(state: EditProfileUiState, draft: ProfileDraft, viewModel: EditProfileViewModel) {
    LazyColumn(
        modifier = Modifier.fillMaxSize().imePadding(),
        contentPadding = PaddingValues(top = Spacing.small, bottom = Spacing.large),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        item(key = "photo") {
            ProfilePhotoPicker(
                picture = draft.picture,
                savedPictureUrl = state.savedPictureUrl,
                showsPicture = draft.showsPicture,
                onPicture = viewModel::setPicture,
                onRemove = viewModel::removePicture,
            )
        }
        state.failure?.let { failure: ProfileSaveFailure ->
            item(key = "failure") {
                FormFailureBanner(title = stringResource(R.string.edit_profile_failure_title), body = stringResource(failureBody(failure)))
            }
        }
        item(key = "public") {
            PublicSection(draft = draft, usernameFailure = state.usernameFailure, viewModel = viewModel)
        }
        item(key = "position") {
            ProfilePositionSection(
                position = draft.position,
                onEdit = viewModel::openPosition,
                onRemove = { viewModel.placePosition(null) },
            )
        }
    }
}

/** The name and the bio on one card, then what the live check says of the name, then who sees them. */
@Composable
private fun PublicSection(draft: ProfileDraft, usernameFailure: AuthFailure?, viewModel: EditProfileViewModel) {
    Column {
        FormSection(header = null, footer = null) {
            FormTextRow(
                label = stringResource(R.string.edit_profile_username),
                value = draft.username,
                onValueChange = viewModel::setUsername,
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.None, autoCorrectEnabled = false),
            )
            FormDivider()
            ProfileBioField(bio = draft.bio, isTooLong = draft.isBioTooLong, onBioChange = viewModel::setBio)
        }
        Column(
            modifier = Modifier.padding(horizontal = Spacing.large, vertical = Spacing.small),
            verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
        ) {
            usernameFailure?.let { FormFootnote(text = stringResource(it.message), color = RecitTheme.colors.foregroundError) }
            FormFootnote(text = stringResource(R.string.edit_profile_public_footer))
        }
    }
}

/** `ProfileSaveFailure.explanation`: what was refused, and what the next « Enregistrer » does. */
@StringRes
private fun failureBody(failure: ProfileSaveFailure): Int = when {
    failure.isUsernameTaken -> R.string.edit_profile_failure_username_taken
    else -> when (failure.refused) {
        ProfileChange.Kind.Picture -> R.string.edit_profile_failure_picture
        ProfileChange.Kind.Username -> R.string.edit_profile_failure_username
        ProfileChange.Kind.Bio -> R.string.edit_profile_failure_bio
        ProfileChange.Kind.Position -> R.string.edit_profile_failure_position
    }
}
