package studio.lunabee.nouveaurecit

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import studio.lunabee.nouveaurecit.e2e.E2EHooks
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.root.RootScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val container: AppContainer = (application as RecitApplication).container
        E2EHooks.read(intent)
        // Not on a re-creation: the link that launched the activity has been opened already.
        if (savedInstanceState == null) container.incomingLinks.value = intent?.dataString
        setContent {
            val messenger: Messenger = remember { Messenger() }
            CompositionLocalProvider(
                LocalAppContainer provides container,
                LocalMessenger provides messenger,
            ) {
                // UI Automator sees a `testTag` only as a resource id; the end-to-end scenario finds its `e2e.*` that way.
                Box(Modifier.semantics { testTagsAsResourceId = true }) {
                    RootScreen()
                }
            }
        }
    }

    /** A link opened while the app runs: `singleTask` hands it to this activity rather than starting another. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        (application as RecitApplication).container.incomingLinks.value = intent.dataString
    }
}
