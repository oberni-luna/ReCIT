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
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.style.TextDecoration
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.WithLabel
import studio.lunabee.nouveaurecit.ui.common.WebLinks

/**
 * A « Présentation » page (iOS features 0073 and 0089): a description, whole, in one card — the owner's own
 * words, selectable, an address in it opening — or [emptyTitle] when there is none; then a card of [facts],
 * one label over its value each. Its own scroll, as the other page keeps its own.
 */
@Composable
internal fun PresentationPage(
    description: String,
    emptyTitle: String,
    facts: List<Pair<String, String>>,
    modifier: Modifier = Modifier,
) {
    val linkColor: Color = RecitTheme.colors.foregroundTinted
    val linked: AnnotatedString? = remember(description, linkColor) {
        description.takeIf { it.isNotBlank() }?.let {
            WebLinks.annotate(it, TextLinkStyles(SpanStyle(color = linkColor, textDecoration = TextDecoration.Underline)))
        }
    }
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = Spacing.small),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        item(key = "description") {
            if (linked != null) {
                ListCard {
                    SelectionContainer {
                        Text(
                            text = linked,
                            style = RecitTheme.typography.content300,
                            color = RecitTheme.colors.foregroundDefault,
                            modifier = Modifier.fillMaxWidth(),
                        )
                    }
                }
            } else {
                EmptyState(
                    title = emptyTitle,
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
