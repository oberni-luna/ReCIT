package studio.lunabee.nouveaurecit.ui.scan

import android.content.Context
import androidx.annotation.OptIn
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.common.util.concurrent.ListenableFuture
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * `CodeScannerView` in continuous mode: the back camera's feed, and every EAN-13 it reads handed to
 * [onCode] on the main thread, for as long as it stays in frame. Which sightings count is
 * `BatchScanStateMachine`'s business, not this view's.
 *
 * CameraX binds to the screen's lifecycle and is released when the view leaves the composition, so
 * the bilan and a pushed book screen do not keep the lens.
 */
@Composable
fun BarcodeCameraPreview(onCode: (String) -> Unit, modifier: Modifier = Modifier) {
    val context: Context = LocalContext.current
    val lifecycleOwner: LifecycleOwner = LocalLifecycleOwner.current
    val currentOnCode: (String) -> Unit by rememberUpdatedState(onCode)
    val previewView: PreviewView = remember { PreviewView(context).apply { scaleType = PreviewView.ScaleType.FILL_CENTER } }

    DisposableEffect(lifecycleOwner) {
        val executor: ExecutorService = Executors.newSingleThreadExecutor()
        val scanner: BarcodeScanner = BarcodeScanning.getClient(
            BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_EAN_13).build(),
        )
        val future: ListenableFuture<ProcessCameraProvider> = ProcessCameraProvider.getInstance(context)
        var provider: ProcessCameraProvider? = null
        var disposed = false

        future.addListener(
            {
                if (disposed) return@addListener
                val cameraProvider: ProcessCameraProvider = runCatching { future.get() }.getOrNull() ?: return@addListener
                provider = cameraProvider
                val preview: Preview = Preview.Builder().build().also { it.surfaceProvider = previewView.surfaceProvider }
                val analysis: ImageAnalysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                analysis.setAnalyzer(executor, BarcodeAnalyzer(scanner) { code -> currentOnCode(code) })
                // No back camera, or the camera held elsewhere: the feed stays dark rather than crashing.
                runCatching {
                    cameraProvider.unbindAll()
                    cameraProvider.bindToLifecycle(lifecycleOwner, CameraSelector.DEFAULT_BACK_CAMERA, preview, analysis)
                }
            },
            ContextCompat.getMainExecutor(context),
        )

        onDispose {
            disposed = true
            provider?.unbindAll()
            scanner.close()
            executor.shutdown()
        }
    }

    AndroidView(factory = { previewView }, modifier = modifier)
}

/** One frame at a time (`STRATEGY_KEEP_ONLY_LATEST`); ML Kit answers on the main thread. */
private class BarcodeAnalyzer(
    private val scanner: BarcodeScanner,
    private val onCode: (String) -> Unit,
) : ImageAnalysis.Analyzer {
    @OptIn(ExperimentalGetImage::class)
    override fun analyze(image: ImageProxy) {
        val media = image.image
        if (media == null) {
            image.close()
            return
        }
        scanner.process(InputImage.fromMediaImage(media, image.imageInfo.rotationDegrees))
            .addOnSuccessListener { barcodes -> barcodes.firstNotNullOfOrNull { it.rawValue }?.let(onCode) }
            .addOnCompleteListener { image.close() }
    }
}
