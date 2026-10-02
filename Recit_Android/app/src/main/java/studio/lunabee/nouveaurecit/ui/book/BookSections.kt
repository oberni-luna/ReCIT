package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExposedDropdownMenuAnchorType
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TagLabel
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.designsystem.WithLabel
import studio.lunabee.nouveaurecit.ui.common.Formatting

/** How long typing must pause before the note is saved — `BookMyCopySection.autosaveDelay`. */
private const val AutosaveDelayMillis: Long = 1_000

/** `OtherEditionsCell`: the work's cover and title, « Autres éditions » under it. */
@Composable
internal fun OtherEditionsRow(work: WorkEntity, onClick: () -> Unit) {
    EntityResultRow(title = work.title, subtitle = stringResource(R.string.book_other_editions_subtitle), imageUrl = work.image, onClick = onClick)
}

/** `UserItemCellView`: the owner, « Depuis le %s », the transaction tag, and the owner's notes. */
@Composable
internal fun CommunityItemRow(row: ItemRow, onClick: () -> Unit) {
    val owner = row.owner ?: return
    CellSurface(onClick = onClick) {
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.small), verticalAlignment = Alignment.CenterVertically) {
                CellThumbnail(url = owner.avatarUrl, size = ThumbnailSize.Medium, shape = ThumbnailShape.Circle)
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                    Text(owner.username, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
                    Row(horizontalArrangement = Arrangement.spacedBy(Spacing.small), verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            stringResource(R.string.inventory_item_since_date, Formatting.longDate(row.item.created)),
                            style = RecitTheme.typography.content300,
                            color = RecitTheme.colors.foregroundSecondary,
                        )
                        TagLabel(text = stringResource(row.item.transaction.label), painter = painterResource(row.item.transaction.icon))
                    }
                }
            }
            if (row.item.details.isNotBlank()) {
                Text(row.item.details, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
            }
        }
    }
}

/**
 * `BookMyCopySection`'s notes field: saved after a pause of a second in typing, on focus loss and on
 * leaving the screen — only when the text actually changed (the repository checks). Background syncs
 * and reverts flow back in, never over what is being typed.
 */
@Composable
internal fun MyNotesCell(row: ItemRow, onCommit: (String) -> Unit) {
    val itemId: String = row.item.id
    var draft: String by rememberSaveable(itemId) { mutableStateOf(row.item.details) }
    var focused: Boolean by remember { mutableStateOf(false) }
    val latestDraft: State<String> = rememberUpdatedState(draft)
    val commit: State<(String) -> Unit> = rememberUpdatedState(onCommit)

    LaunchedEffect(row.item.details) {
        if (!focused) draft = row.item.details
    }
    LaunchedEffect(draft) {
        if (draft == row.item.details) return@LaunchedEffect
        delay(AutosaveDelayMillis)
        commit.value(draft)
    }
    DisposableEffect(itemId) {
        onDispose { commit.value(latestDraft.value) }
    }

    CellSurface {
        WithLabel(label = stringResource(R.string.inventory_item_my_notes)) {
            TextField(
                value = draft,
                onValueChange = { draft = it },
                placeholder = { Text(stringResource(R.string.inventory_item_write_notes), style = RecitTheme.typography.content300) },
                textStyle = RecitTheme.typography.content300.copy(color = RecitTheme.colors.foregroundDefault),
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color.Transparent,
                    unfocusedContainerColor = Color.Transparent,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    cursorColor = RecitTheme.colors.foregroundTinted,
                    focusedPlaceholderColor = RecitTheme.colors.foregroundPlaceholder,
                    unfocusedPlaceholderColor = RecitTheme.colors.foregroundPlaceholder,
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .onFocusChanged { state ->
                        if (focused && !state.isFocused) commit.value(latestDraft.value)
                        focused = state.isFocused
                    },
            )
        }
    }
}

/** « Créé le %s », then the label-hidden transaction picker (`Picker` → `ExposedDropdownMenuBox`). */
@Composable
internal fun MyCopyDetailsCell(row: ItemRow, onTransaction: (TransactionType) -> Unit) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    val current: TransactionType = row.item.transaction
    val pickerDescription: String = stringResource(R.string.inventory_item_transaction_mode)
    CellSurface {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text(
                stringResource(R.string.inventory_item_created_date, Formatting.longDate(row.item.created)),
                style = RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundSecondary,
                modifier = Modifier.weight(1f),
            )
            ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }) {
                Row(
                    modifier = Modifier
                        .menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable)
                        .semantics { contentDescription = pickerDescription },
                    horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(painterResource(current.icon), contentDescription = null, tint = RecitTheme.colors.foregroundTinted, modifier = Modifier.size(16.dp))
                    Text(stringResource(current.label), style = RecitTheme.typography.action300, color = RecitTheme.colors.foregroundTinted)
                    Icon(Icons.Filled.ArrowDropDown, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
                }
                ExposedDropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false },
                    matchAnchorWidth = false,
                    containerColor = RecitTheme.colors.backgroundDefault,
                ) {
                    TransactionType.entries.forEach { type ->
                        DropdownMenuItem(
                            text = { Text(stringResource(type.label), style = RecitTheme.typography.content400, color = RecitTheme.colors.foregroundDefault) },
                            leadingIcon = { Icon(painterResource(type.icon), contentDescription = null, tint = RecitTheme.colors.foregroundDefault, modifier = Modifier.size(16.dp)) },
                            onClick = {
                                expanded = false
                                if (type != current) onTransaction(type)
                            },
                        )
                    }
                }
            }
        }
    }
}
