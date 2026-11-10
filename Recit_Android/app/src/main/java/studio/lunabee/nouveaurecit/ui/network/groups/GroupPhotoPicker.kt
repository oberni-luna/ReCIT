package studio.lunabee.nouveaurecit.ui.network.groups

import android.net.Uri
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.groups.GroupPictureEdit
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.editedition.CoverSources
import studio.lunabee.nouveaurecit.ui.editedition.ImageSourceMenu
import studio.lunabee.nouveaurecit.ui.editedition.rememberCoverSources
import java.io.File

/**
 * `GroupPhotoPicker`: the first section of « Réglages du groupe » — the group's photo in its rounded
 * square, or the empty square inviting one, and the menu of where a new one can come from, as for
 * an edition's cover. It only changes [picture]: nothing is uploaded before « Enregistrer ».
 *
 * @param savedPictureUrl The photo on the server, shown while [picture] has not touched it.
 */
@Composable
fun GroupPhotoPicker(
    picture: GroupPictureEdit,
    savedPictureUrl: String?,
    onPictureChange: (GroupPictureEdit) -> Unit,
    modifier: Modifier = Modifier,
) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    val sources: CoverSources = rememberCoverSources { path -> onPictureChange(GroupPictureEdit.Replaced(path)) }
    val shownUrl: String? = when (picture) {
        GroupPictureEdit.Unchanged -> savedPictureUrl
        is GroupPictureEdit.Replaced -> Uri.fromFile(File(picture.path)).toString()
        GroupPictureEdit.Removed -> null
    }
    val showsPicture: Boolean = shownUrl != null

    Box(modifier = modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        // Anchors the menu under the photo rather than at the sheet's edge.
        Box {
            PhotoSlot(
                url = shownUrl,
                label = stringResource(if (showsPicture) R.string.groups_form_picture_change else R.string.groups_form_picture_add),
                onClick = { expanded = true },
            )
            ImageSourceMenu(
                expanded = expanded,
                removeLabel = stringResource(R.string.groups_form_picture_remove),
                showsRemove = showsPicture,
                sources = sources,
                onRemove = { onPictureChange(GroupPictureEdit.Removed) },
                onDismiss = { expanded = false },
            )
        }
    }
}

/** The photo, or the empty square, with what a touch on it does underneath. */
@Composable
private fun PhotoSlot(url: String?, label: String, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .clickable(onClickLabel = label, role = Role.Button, onClick = onClick)
            .padding(Spacing.small),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        GroupThumbnail(url = url, size = ThumbnailSize.XLarge)
        Text(label, style = RecitTheme.typography.action300, color = RecitTheme.colors.foregroundTinted)
    }
}
