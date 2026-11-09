package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.groups.GroupNameRule
import studio.lunabee.nouveaurecit.data.groups.GroupPictureEdit
import studio.lunabee.nouveaurecit.data.groups.GroupSetting
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SheetHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer

/**
 * `GroupSettingsView`: what an admin can change about a group, as a sheet like « Modifier
 * l'étagère ».
 *
 * `PUT /api/groups/update-settings` takes one attribute at a time, and the form follows it: a switch
 * is written the moment it moves, optimistically, and the two texts go together on « Enregistrer »,
 * one call each for whichever changed. [group] is live, so a switch shows what was written — or put
 * back. The place is not offered yet.
 *
 * The photo (feature 0082) goes with the texts on « Enregistrer », server first: the sheet closes,
 * then `GroupRepository.updatePicture` uploads it in the application scope, which outlives the
 * sheet, and the group shows it once the server has agreed. Closing the sheet sends nothing.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupSettingsSheet(
    group: ReaderGroup,
    onUpdate: (GroupSetting) -> Unit,
    onDismiss: () -> Unit,
) {
    val container: AppContainer = LocalAppContainer.current
    val sheetState: SheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var name: String by rememberSaveable { mutableStateOf(group.name) }
    var description: String by rememberSaveable { mutableStateOf(group.description) }
    var picture: GroupPictureEdit by rememberSaveable { mutableStateOf<GroupPictureEdit>(GroupPictureEdit.Unchanged) }
    val textChanged: Boolean = name != group.name || description != group.description
    val pictureChanged: Boolean = picture.isChange(from = group.pictureUrl)

    fun save() {
        val trimmedName: String = name.trim()
        if (trimmedName != group.name) onUpdate(GroupSetting.Name(trimmedName))
        val trimmedDescription: String = description.trim()
        if (trimmedDescription != group.description) onUpdate(GroupSetting.Description(trimmedDescription))
        if (pictureChanged) {
            val edit: GroupPictureEdit = picture
            container.applicationScope.launch { container.groups.updatePicture(edit, group.id) }
        }
        onDismiss()
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = RecitTheme.colors.backgroundRaised,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .imePadding()
                .padding(horizontal = Spacing.medium)
                .padding(bottom = Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            SheetHeader(
                title = stringResource(R.string.groups_settings),
                closeLabel = stringResource(R.string.action_close),
                onClose = onDismiss,
            )
            GroupPhotoPicker(
                picture = picture,
                savedPictureUrl = group.pictureUrl,
                onPictureChange = { picture = it },
            )
            GroupTextFields(
                name = name,
                onNameChange = { name = it },
                description = description,
                onDescriptionChange = { description = it },
            )
            val slug: String? = group.slug
            if (slug != null && !GroupNameRule.isTooLong(name)) {
                GroupNote(stringResource(R.string.groups_form_address, slug))
            }
            GroupAccessSection(
                searchable = group.searchable,
                onSearchableChange = { onUpdate(GroupSetting.Searchable(it)) },
                open = group.open,
                onOpenChange = { onUpdate(GroupSetting.Open(it)) },
            )
            PrimaryButton(
                text = stringResource(R.string.action_save),
                onClick = ::save,
                enabled = (textChanged || pictureChanged) && GroupNameRule.accepts(name),
            )
        }
    }
}
