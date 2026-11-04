package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FormatQuote
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.style.TextDecoration
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.WithLabel
import studio.lunabee.nouveaurecit.ui.common.Formatting
import studio.lunabee.nouveaurecit.ui.common.WebLinks

/**
 * `ListPresentationPage` (iOS feature 0073): a list's description, whole, in one card — the list's own words,
 * selectable, an address in it opening — then a card of what the list is: its type, who may see it, the day
 * it was made and the day it last changed. The same for a friend's list as for mine; editing stays behind the
 * bar's pencil. Its own scroll, as the other page keeps its own.
 */
@Composable
internal fun ListPresentationPage(list: EntityListEntity, modifier: Modifier = Modifier) {
    val linkColor: Color = RecitTheme.colors.foregroundTinted
    val description: AnnotatedString? = remember(list.explanation, linkColor) {
        list.explanation.takeIf { it.isNotBlank() }?.let {
            WebLinks.annotate(it, TextLinkStyles(SpanStyle(color = linkColor, textDecoration = TextDecoration.Underline)))
        }
    }
    val facts: List<Pair<String, String>> = listOfNotNull(
        stringResource(R.string.list_info_type) to stringResource(list.type.label),
        stringResource(R.string.list_info_visibility) to stringResource(ListVisibility.from(list.visibility).label),
        list.created.takeIf { it > 0 }?.let { stringResource(R.string.list_info_created) to Formatting.longDate(it) },
        list.updated?.takeIf { it > list.created }?.let { stringResource(R.string.list_info_updated) to Formatting.longDate(it) },
    )
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = Spacing.small),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        item(key = "description") {
            if (description != null) {
                ListCard {
                    SelectionContainer {
                        Text(
                            text = description,
                            style = RecitTheme.typography.content300,
                            color = RecitTheme.colors.foregroundDefault,
                            modifier = Modifier.fillMaxWidth(),
                        )
                    }
                }
            } else {
                EmptyState(
                    title = stringResource(R.string.list_presentation_empty),
                    icon = Icons.Outlined.FormatQuote,
                    modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
                )
            }
        }
        item(key = "facts") {
            ListCard {
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.sMedium)) {
                    facts.forEachIndexed { index, (label, value) ->
                        if (index > 0) HorizontalDivider(color = RecitTheme.colors.borderDefault)
                        WithLabel(label = label) {
                            Text(value, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
                        }
                    }
                }
            }
        }
    }
}
