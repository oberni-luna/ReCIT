package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.UnfoldMore
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.book.EditionLanguageFilter
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import java.util.Locale

/**
 * `EditionLanguageMenu` (iOS feature 0058): at the right of « Éditions de … », the language shown, in
 * green, and a menu of « Toutes les langues », each language by number of editions, then « Langue non
 * renseignée » — three groups split by a rule, a check on the one shown. Choosing filters the list in
 * place, without fetching anything.
 */
@Composable
internal fun EditionLanguageMenu(
    language: EditionLanguageFilter,
    options: List<EditionLanguageFilter.Option>,
    onChoose: (EditionLanguageFilter) -> Unit,
) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    val locale: Locale = LocalConfiguration.current.locales[0]
    val label: String = languageLabel(language, locale)
    val spoken: String = stringResource(R.string.editions_language_menu, label)

    Box {
        Row(
            modifier = Modifier
                .clickable { expanded = true }
                .padding(horizontal = Spacing.small, vertical = Spacing.xSmall)
                .semantics(mergeDescendants = true) { contentDescription = spoken },
            horizontalArrangement = Arrangement.spacedBy(Spacing.xxSmall),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(label, style = RecitTheme.typography.action200, color = RecitTheme.colors.foregroundTinted, maxLines = 1)
            Icon(Icons.Default.UnfoldMore, contentDescription = null, tint = RecitTheme.colors.foregroundTinted, modifier = Modifier.size(16.dp))
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            containerColor = RecitTheme.colors.backgroundRaised,
        ) {
            options.forEachIndexed { index, option ->
                val previous: EditionLanguageFilter? = options.getOrNull(index - 1)?.language
                val startsGroup: Boolean = index == 1 || (option.language == EditionLanguageFilter.Unspecified && previous != EditionLanguageFilter.All)
                if (startsGroup) HorizontalDivider(color = RecitTheme.colors.borderDefault)
                DropdownMenuItem(
                    text = {
                        Column {
                            Text(languageLabel(option.language, locale), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
                            Text(
                                pluralStringResource(R.plurals.editions_language_count, option.count, option.count),
                                style = RecitTheme.typography.footnote200,
                                color = RecitTheme.colors.foregroundSecondary,
                            )
                        }
                    },
                    trailingIcon = if (option.language == language) {
                        { Icon(Icons.Default.Check, contentDescription = null, tint = RecitTheme.colors.foregroundTinted) }
                    } else {
                        null
                    },
                    onClick = {
                        expanded = false
                        onChoose(option.language)
                    },
                )
            }
        }
    }
}

@Composable
private fun languageLabel(language: EditionLanguageFilter, locale: Locale): String = when (language) {
    EditionLanguageFilter.All -> stringResource(R.string.editions_language_all)
    EditionLanguageFilter.Unspecified -> stringResource(R.string.editions_language_unspecified)
    is EditionLanguageFilter.Code -> EditionLanguageFilter.name(language.code, locale)
}
