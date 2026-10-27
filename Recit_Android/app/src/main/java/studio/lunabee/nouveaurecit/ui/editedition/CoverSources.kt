package studio.lunabee.nouveaurecit.ui.editedition

import android.content.ActivityNotFoundException
import android.content.Context
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.ui.createbook.CoverPhoto
import java.io.File

/** Where a cover can come from, as the cover's menu lists them: the camera app, or the gallery. */
class CoverSources(val camera: () -> Unit, val photos: () -> Unit)

/**
 * The cover menu's two ways in (`CreateBookCoverRow.sources`): the camera app, writing into the cache
 * through the FileProvider — the gallery when no camera app answers —, or the system's photo picker.
 * Either way the picture is reduced ([CoverPhoto]) before [onCover] is handed its path.
 */
@Composable
fun rememberCoverSources(onCover: (String) -> Unit): CoverSources {
    val context: Context = LocalContext.current
    val scope: CoroutineScope = rememberCoroutineScope()
    var capturePath: String? by rememberSaveable { mutableStateOf(null) }
    val reduce: (Uri) -> Unit = { uri -> scope.launch { CoverPhoto.reduce(context, uri)?.let(onCover) } }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri -> uri?.let(reduce) }
    val camera = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { saved ->
        val path: String? = capturePath
        if (saved && path != null) reduce(Uri.fromFile(File(path)))
    }
    val photos: () -> Unit = { picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }
    return CoverSources(
        camera = {
            try {
                val file: File = CoverPhoto.newCaptureFile(context)
                capturePath = file.absolutePath
                camera.launch(CoverPhoto.shareableUri(context, file))
            } catch (_: ActivityNotFoundException) {
                photos()
            } catch (_: SecurityException) {
                photos()
            }
        },
        photos = photos,
    )
}
