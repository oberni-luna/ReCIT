package studio.lunabee.nouveaurecit.ui.profile.edit

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardCapitalization
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.user.ProfileDraft
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.editedition.FormTextRow

/**
 * `ProfileBioField` (iOS feature 0055): the bio, typed over several lines, with what it weighs against the
 * server's 1 000 characters under it. Past the limit the count turns red and « Enregistrer » greys out: the
 * server would refuse it anyway.
 */
@Composable
fun ProfileBioField(bio: String, isTooLong: Boolean, onBioChange: (String) -> Unit, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth(), horizontalAlignment = Alignment.End) {
        FormTextRow(
            label = stringResource(R.string.edit_profile_bio),
            value = bio,
            onValueChange = onBioChange,
            placeholder = stringResource(R.string.edit_profile_bio_placeholder),
            singleLine = false,
            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
        )
        Text(
            text = stringResource(R.string.edit_profile_bio_count, bio.length, ProfileDraft.BIO_LIMIT),
            style = RecitTheme.typography.footnote200,
            color = if (isTooLong) RecitTheme.colors.foregroundError else RecitTheme.colors.foregroundSecondary,
            modifier = Modifier.padding(start = Spacing.medium, end = Spacing.medium, bottom = Spacing.sMedium),
        )
    }
}
