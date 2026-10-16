package studio.lunabee.nouveaurecit.ui.scan

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.LocalActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.VideocamOff
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LifecycleResumeEffect
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `CameraAccess`, Android's way: there is no « restricted » here, but there are two refusals — one
 * the system will still ask about, and one it will not ([DeniedForGood]), which only the app's
 * settings page can undo.
 */
enum class CameraAccess { Unknown, Granted, Denied, DeniedForGood }

/** The access, asked for as the flow opens and re-read on every return to the screen. */
class CameraAccessState(
    private val current: MutableState<CameraAccess>,
    private val launcher: ActivityResultLauncher<String>,
) {
    val access: CameraAccess get() = current.value

    fun request() {
        launcher.launch(Manifest.permission.CAMERA)
    }
}

@Composable
fun rememberCameraAccess(): CameraAccessState {
    val context: Context = LocalContext.current
    val activity: Activity? = LocalActivity.current
    val current: MutableState<CameraAccess> = remember {
        mutableStateOf(if (isGranted(context)) CameraAccess.Granted else CameraAccess.Unknown)
    }
    val launcher: ActivityResultLauncher<String> = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        current.value = when {
            granted -> CameraAccess.Granted
            activity != null && ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.CAMERA) -> CameraAccess.Denied
            else -> CameraAccess.DeniedForGood
        }
    }
    val state: CameraAccessState = remember(launcher) { CameraAccessState(current, launcher) }

    // Asked when the flow opens rather than on the first barcode: someone who has already refused
    // meets the explanation as the screen appears, not after pointing the phone at a book.
    LaunchedEffect(state) {
        if (state.access == CameraAccess.Unknown) state.request()
    }
    // Granting access in the settings sends the app through the background on the way back.
    LifecycleResumeEffect(state) {
        if (isGranted(context)) current.value = CameraAccess.Granted
        onPauseOrDispose {}
    }
    return state
}

private fun isGranted(context: Context): Boolean =
    ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED

/** `ScannerPermissionView`, on the camera's black ground. */
@Composable
fun ScannerPermissionContent(access: CameraAccess, onAllow: () -> Unit, modifier: Modifier = Modifier) {
    val context: Context = LocalContext.current
    Column(
        modifier = modifier.fillMaxSize().padding(horizontal = Spacing.xLarge),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.medium, Alignment.CenterVertically),
    ) {
        Icon(Icons.Default.VideocamOff, contentDescription = null, tint = ScanOverlayPalette.Tint, modifier = Modifier.size(40.dp))
        Text(
            text = stringResource(R.string.scan_permission_title),
            style = RecitTheme.typography.content400Bold,
            color = ScanOverlayPalette.Ink,
            textAlign = TextAlign.Center,
        )
        Text(
            text = stringResource(
                if (access == CameraAccess.DeniedForGood) R.string.scan_permission_denied_message else R.string.scan_permission_ask_message,
            ),
            style = RecitTheme.typography.content300,
            color = ScanOverlayPalette.Ink,
            textAlign = TextAlign.Center,
        )
        if (access == CameraAccess.DeniedForGood) {
            PrimaryButton(text = stringResource(R.string.scan_permission_open_settings), onClick = { openAppSettings(context) })
        } else {
            PrimaryButton(text = stringResource(R.string.scan_permission_allow), onClick = onAllow)
        }
    }
}

private fun openAppSettings(context: Context) {
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null))
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    context.startActivity(intent)
}
