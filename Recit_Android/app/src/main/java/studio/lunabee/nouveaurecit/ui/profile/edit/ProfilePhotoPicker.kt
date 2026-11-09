package studio.lunabee.nouveaurecit.ui.profile.edit

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.user.ProfileDraft
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.createbook.CoverPhoto
import studio.lunabee.nouveaurecit.ui.editedition.CoverSources
import studio.lunabee.nouveaurecit.ui.editedition.MenuLine
import studio.lunabee.nouveaurecit.ui.editedition.rememberCoverSources
import java.io.File

/**
 * `ProfilePhotoPicker` (iOS feature 0055): the picture at the head of « Modifier le profil », and the menu it
 * opens — the camera, the gallery, the account's Gravatar, and, once there is a picture, taking it away.
 *
 * It only changes the draft. Nothing is uploaded until « Enregistrer », so a picture chosen then replaced
 * costs nothing, and the preview is the file that will leave the phone. The Gravatar is downloaded here
 * and reduced like a photograph; when the address has none, a snackbar says so.
 */
@Composable
fun ProfilePhotoPicker(
    picture: ProfileDraft.Picture,
    savedPictureUrl: String?,
    showsPicture: Boolean,
    onPicture: (String) -> Unit,
    onRemove: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val container: AppContainer = LocalAppContainer.current
    val messenger: Messenger = LocalMessenger.current
    val context: Context = LocalContext.current
    val scope: CoroutineScope = rememberCoroutineScope()
    val sources: CoverSources = rememberCoverSources(onCover = onPicture)
    var expanded: Boolean by remember { mutableStateOf(false) }
    var isLoadingGravatar: Boolean by remember { mutableStateOf(false) }
    val label: String = stringResource(R.string.edit_profile_photo_change)
    val noGravatar: String = stringResource(R.string.edit_profile_photo_no_gravatar)
    val genericError: String = stringResource(R.string.error_generic)

    val loadGravatar: () -> Unit = {
        scope.launch {
            isLoadingGravatar = true
            try {
                val path: String? = container.profile.gravatarImage()?.let { CoverPhoto.reduce(context, it) }
                if (path != null) onPicture(path) else messenger.show(noGravatar)
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                messenger.showError(genericError, error.localizedMessage)
            } finally {
                isLoadingGravatar = false
            }
        }
    }

    Box(modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        Column(
            modifier = Modifier
                .clickable(enabled = !isLoadingGravatar, onClickLabel = label, role = Role.Button) { expanded = true }
                .padding(Spacing.small),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.small),
        ) {
            ProfilePhotoPreview(picture = picture, savedPictureUrl = savedPictureUrl, isLoading = isLoadingGravatar)
            Text(text = label, style = RecitTheme.typography.action300, color = RecitTheme.colors.foregroundTinted)
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }, containerColor = RecitTheme.colors.backgroundRaised) {
            if (showsPicture) {
                MenuLine(stringResource(R.string.edit_profile_photo_remove), Icons.Outlined.Delete, RecitTheme.colors.foregroundError) {
                    expanded = false
                    onRemove()
                }
                HorizontalDivider(color = RecitTheme.colors.borderDefault)
            }
            MenuLine(stringResource(R.string.edit_profile_photo_camera), Icons.Outlined.PhotoCamera) {
                expanded = false
                sources.camera()
            }
            MenuLine(stringResource(R.string.edit_profile_photo_gallery), Icons.Outlined.PhotoLibrary) {
                expanded = false
                sources.photos()
            }
            MenuLine(stringResource(R.string.edit_profile_photo_gravatar), Icons.Outlined.AccountCircle) {
                expanded = false
                loadGravatar()
            }
        }
    }
}

/**
 * The round picture itself: the file the draft holds, the server's picture, or the person glyph — with the
 * camera badge that says it can be changed.
 */
@Composable
private fun ProfilePhotoPreview(picture: ProfileDraft.Picture, savedPictureUrl: String?, isLoading: Boolean) {
    val model: Any? = when (picture) {
        is ProfileDraft.Picture.Replaced -> File(picture.path)
        ProfileDraft.Picture.Removed -> null
        ProfileDraft.Picture.Unchanged -> savedPictureUrl
    }
    Box {
        Box(
            modifier = Modifier.size(PhotoDiameter).clip(CircleShape).background(RecitTheme.colors.backgroundDisable),
            contentAlignment = Alignment.Center,
        ) {
            if (model != null) {
                AsyncImage(model = model, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
            } else {
                Icon(Icons.Outlined.Person, contentDescription = null, tint = RecitTheme.colors.foregroundSecondary, modifier = Modifier.size(GlyphSize))
            }
            if (isLoading) CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary)
        }
        Box(
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .size(BadgeDiameter)
                .clip(CircleShape)
                .background(RecitTheme.colors.backgroundTintedInverse)
                .border(BadgeBorder, RecitTheme.colors.backgroundForm, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.PhotoCamera, contentDescription = null, tint = RecitTheme.colors.foregroundInverse, modifier = Modifier.size(BadgeIconSize))
        }
    }
}

private val PhotoDiameter: Dp = 104.dp
private val GlyphSize: Dp = 48.dp
private val BadgeDiameter: Dp = 34.dp
private val BadgeIconSize: Dp = 18.dp
private val BadgeBorder: Dp = 3.dp
