package studio.lunabee.nouveaurecit.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.CoverWallRepository
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.Primitive
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SecondaryButton
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.auth.coverwall.CoverWall
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.navigation.DeepLink

/**
 * `WelcomeView`: what the app is for, before asking who you are (feature 0011). The covers of the
 * books last published on inventaire.io drift behind a green veil (feature 0013); the text sits on
 * the bottom of the screen, where the veil closes. An Ex-libris link opened signed out waits for the session, and
 * one line under the buttons says so, in the screen's « vous » (issue 143).
 */
@Composable
fun WelcomeScreen(onSignIn: () -> Unit, onCreateAccount: () -> Unit) {
    val container: AppContainer = LocalAppContainer.current
    val coverWall: CoverWallRepository = container.coverWall
    val paths: List<String> by coverWall.paths.collectAsStateWithLifecycle()
    val incomingLink: String? by container.incomingLinks.collectAsStateWithLifecycle()
    val isLinkWaiting: Boolean = incomingLink?.let { DeepLink.parse(it) } != null
    LaunchedEffect(Unit) { coverWall.refresh() }

    Box(Modifier.fillMaxSize()) {
        CoverWall(paths = paths)
        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        0f to Primitive.Green900.copy(alpha = 0.55f),
                        0.12f to Primitive.Green900.copy(alpha = 0.35f),
                        0.45f to Primitive.Green900.copy(alpha = 0.75f),
                        0.62f to Primitive.Green900.copy(alpha = 0.96f),
                        1f to Primitive.Green900,
                    ),
                ),
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .safeDrawingPadding()
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(Spacing.large, Alignment.Bottom),
        ) {
            Column(
                modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
            ) {
                Text(stringResource(R.string.welcome_app_name), style = RecitTheme.typography.title200, color = RecitTheme.colors.foregroundDefault)
                Text(stringResource(R.string.welcome_tagline), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundTinted)
                Text(
                    stringResource(R.string.welcome_pitch),
                    style = RecitTheme.typography.content400,
                    color = RecitTheme.colors.foregroundDefault,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(top = Spacing.sMedium, start = Spacing.small, end = Spacing.small),
                )
            }
            Column(modifier = Modifier.padding(horizontal = Spacing.medium), horizontalAlignment = Alignment.CenterHorizontally) {
                PrimaryButton(text = stringResource(R.string.login_button_signin), onClick = onSignIn)
                SecondaryButton(text = stringResource(R.string.login_button_create_account), onClick = onCreateAccount)
            }
            if (isLinkWaiting) {
                Text(
                    text = stringResource(R.string.welcome_link_waiting),
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundDefault,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium).testTag("e2e.welcome.linkWaiting"),
                )
            }
            Text(
                text = stringResource(R.string.welcome_footnote),
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
            )
        }
    }
}
