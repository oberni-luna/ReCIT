package studio.lunabee.nouveaurecit.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.Primitive
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SecondaryButton
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `WelcomeView`: what the app is for, before asking who you are (feature 0011). The drifting wall of
 * covers (feature 0013) is not ported; the green veil it sits under is.
 */
@Composable
fun WelcomeScreen(onSignIn: () -> Unit, onCreateAccount: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Primitive.Green900)
            .background(
                Brush.verticalGradient(
                    0f to Primitive.Green800.copy(alpha = 0.6f),
                    0.58f to Primitive.Green900.copy(alpha = 0.96f),
                    1f to Primitive.Green900,
                ),
            )
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
        Text(
            text = stringResource(R.string.welcome_footnote),
            style = RecitTheme.typography.footnote200,
            color = RecitTheme.colors.foregroundSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        )
    }
}
