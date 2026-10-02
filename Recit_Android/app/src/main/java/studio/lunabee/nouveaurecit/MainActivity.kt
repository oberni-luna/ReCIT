package studio.lunabee.nouveaurecit

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.root.RootScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val container: AppContainer = (application as RecitApplication).container
        setContent {
            val messenger: Messenger = remember { Messenger() }
            CompositionLocalProvider(
                LocalAppContainer provides container,
                LocalMessenger provides messenger,
            ) {
                RootScreen()
            }
        }
    }
}
