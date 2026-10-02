package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import studio.lunabee.nouveaurecit.designsystem.RecitTheme

/** A screen not built yet — replaced feature by feature. */
@Composable
fun PlaceholderScreen(title: String, onBack: (() -> Unit)?) {
    Scaffold(
        topBar = { RecitTopBar(title = title, onBack = onBack) },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
            Text(title, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary)
        }
    }
}
